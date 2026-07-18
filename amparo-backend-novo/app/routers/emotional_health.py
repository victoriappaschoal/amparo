"""
Aba de saúde emocional: aplicação da Escala de Edimburgo (EPDS).

REGRA DE NEGÓCIO (não negociável): o paciente pode RESPONDER o
questionário, mas nunca pode LER a pontuação nem o nível de risco.
Por isso existem dois response_models diferentes:
  - EPDSPatientAck  -> o que o paciente recebe (sem score)
  - EPDSDoctorView  -> o que o médico recebe (score completo)
Não existe endpoint GET de EPDS acessível pelo papel "patient".
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_patient, get_current_verified_doctor, ensure_patient_belongs_to_doctor
from app.models import EPDSResponse, PatientProfile, DoctorProfile
from app.schemas import EPDSSubmit, EPDSPatientAck, EPDSDoctorView
from app.epds_logic import score_epds

router = APIRouter(prefix="/emotional-health", tags=["Saúde emocional (EPDS)"])


@router.post("/epds", response_model=EPDSPatientAck, status_code=status.HTTP_201_CREATED)
def submit_epds(
    payload: EPDSSubmit,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    score, risk_level = score_epds(payload.answers)

    entry = EPDSResponse(
        patient_id=patient.id,
        entry_date=payload.entry_date,
        answers=payload.answers,
        score=score,
        risk_level=risk_level,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)

    # Importante: mesmo aqui no backend, a resposta HTTP para o paciente
    # NUNCA inclui `score` nem `risk_level`.
    return entry


@router.get("/epds/patient/{patient_id}", response_model=list[EPDSDoctorView])
def list_epds_for_doctor(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Único jeito de ler score/risco do EPDS: sendo o médico vinculado ao paciente."""
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)

    return db.query(EPDSResponse).filter(
        EPDSResponse.patient_id == patient_id
    ).order_by(EPDSResponse.entry_date.desc()).all()
