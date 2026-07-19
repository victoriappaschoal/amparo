"""
Visão do MÉDICO sobre suas pacientes.

Era o principal buraco do backend: as rotas de sintomas/EPDS/consultas
já aceitavam um patient_id, mas o médico não tinha como descobrir quais
pacientes estão vinculadas a ele. Este router fecha esse ciclo:

  GET /patients                     -> lista de pacientes vinculadas
  GET /patients/{id}                -> detalhe de uma paciente vinculada
  GET /patients/{id}/summary        -> resumo clínico p/ dashboard

Regras de segurança (mesmas do resto do projeto):
- Somente médicos VERIFICADOS (is_verified=True) acessam.
- Somente pacientes com doctor_id == médico logado aparecem.
- Humor (mood) NÃO entra em nenhuma resposta: pela matriz de permissões
  do projeto, o calendário de humor é privado da paciente.
"""
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.deps import get_current_verified_doctor, ensure_patient_belongs_to_doctor
from app.models import (
    PatientProfile, DoctorProfile, EPDSResponse, SymptomDiaryEntry,
    Consultation, ConsultationStatus, MoodEntry,
)
from app.schemas import PatientListItem, PatientDetailForDoctor, PatientSummaryForDoctor, SymptomEntryOut, EPDSDoctorView

router = APIRouter(prefix="/patients", tags=["Pacientes (visão do médico)"])


def _get_linked_patient_or_404(patient_id: str, doctor: DoctorProfile, db: Session) -> PatientProfile:
    patient = (
        db.query(PatientProfile)
        .options(joinedload(PatientProfile.user))
        .filter(PatientProfile.id == patient_id)
        .first()
    )
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)
    return patient


@router.get("", response_model=list[PatientListItem])
def list_my_patients(
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Tela 'Meus pacientes' do app do médico."""
    patients = (
        db.query(PatientProfile)
        .options(joinedload(PatientProfile.user))
        .filter(PatientProfile.doctor_id == doctor.id)
        .all()
    )
    return [
        PatientListItem(
            id=p.id,
            full_name=p.user.full_name,
            baby_birth_date=p.baby_birth_date,
            delivery_type=p.delivery_type.value if p.delivery_type else None,
            phone=p.phone,
            emergency_contact_name=p.emergency_contact_name,
            emergency_contact_phone=p.emergency_contact_phone,
            emergency_contact_relationship=p.emergency_contact_relationship,
        )
        for p in patients
    ]


@router.get("/{patient_id}", response_model=PatientDetailForDoctor)
def get_patient_detail(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    p = _get_linked_patient_or_404(patient_id, doctor, db)
    return PatientDetailForDoctor(
        id=p.id,
        full_name=p.user.full_name,
        email=p.user.email,
        phone=p.phone,
        birth_date=p.birth_date,
        baby_birth_date=p.baby_birth_date,
        baby_name=p.baby_name,
        delivery_type=p.delivery_type.value if p.delivery_type else None,
        is_breastfeeding=p.is_breastfeeding,
    )


@router.get("/{patient_id}/summary", response_model=PatientSummaryForDoctor)
def get_patient_summary(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """
    Resumo para o card da paciente no dashboard do médico:
    último EPDS (data + risco), volume de registros de sintomas nos
    últimos 30 dias e próxima consulta agendada.
    """
    p = _get_linked_patient_or_404(patient_id, doctor, db)

    last_epds = (
        db.query(EPDSResponse)
        .filter(EPDSResponse.patient_id == p.id)
        .order_by(EPDSResponse.entry_date.desc(), EPDSResponse.created_at.desc())
        .first()
    )

    cutoff = date.today() - timedelta(days=30)
    symptom_count = (
        db.query(SymptomDiaryEntry)
        .filter(
            SymptomDiaryEntry.patient_id == p.id,
            SymptomDiaryEntry.entry_date >= cutoff,
        )
        .count()
    )

    # Último registro DIÁRIO (humor ou sintomas) para o alerta de inatividade
    ultimo_humor = (
        db.query(MoodEntry.entry_date)
        .filter(MoodEntry.patient_id == p.id)
        .order_by(MoodEntry.entry_date.desc())
        .first()
    )
    ultimo_sintoma = (
        db.query(SymptomDiaryEntry.entry_date)
        .filter(SymptomDiaryEntry.patient_id == p.id)
        .order_by(SymptomDiaryEntry.entry_date.desc())
        .first()
    )
    datas = [d[0] for d in (ultimo_humor, ultimo_sintoma) if d is not None]
    ultimo_registro = max(datas) if datas else None
    if ultimo_registro is not None:
        dias_sem_registro = max(0, (date.today() - ultimo_registro).days)
    else:
        # Nunca registrou: conta desde o cadastro
        dias_sem_registro = max(0, (date.today() - p.user.created_at.date()).days)

    next_consultation = (
        db.query(Consultation)
        .filter(
            Consultation.patient_id == p.id,
            Consultation.status == ConsultationStatus.scheduled,
        )
        .order_by(Consultation.scheduled_at.asc())
        .first()
    )

    return PatientSummaryForDoctor(
        patient_id=p.id,
        last_epds_date=last_epds.entry_date if last_epds else None,
        last_epds_risk_level=last_epds.risk_level if last_epds else None,
        symptom_entries_last_30_days=symptom_count,
        next_consultation_at=next_consultation.scheduled_at if next_consultation else None,
        last_daily_entry_date=ultimo_registro,
        days_without_daily_entry=dias_sem_registro,
    )

@router.get("/{patient_id}/symptoms", response_model=list[SymptomEntryOut])
def patient_symptoms(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Diário de sintomas da paciente para o prontuário (mais recentes primeiro)."""
    p = _get_linked_patient_or_404(patient_id, doctor, db)
    return (
        db.query(SymptomDiaryEntry)
        .filter(SymptomDiaryEntry.patient_id == p.id)
        .order_by(SymptomDiaryEntry.entry_date.desc())
        .limit(60)
        .all()
    )


@router.get("/{patient_id}/epds", response_model=list[EPDSDoctorView])
def patient_epds_history(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """
    Histórico do EPDS COM pontuação e risco — visível apenas para o
    profissional vinculado (a paciente nunca recebe o score pela API).
    """
    p = _get_linked_patient_or_404(patient_id, doctor, db)
    return (
        db.query(EPDSResponse)
        .filter(EPDSResponse.patient_id == p.id)
        .order_by(EPDSResponse.entry_date.desc())
        .all()
    )

