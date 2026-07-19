"""
Rotas administrativas (role == admin). Cobrem os dois fluxos que o
README apontava como pendentes:

1. Vínculo paciente ↔ médico (feito pela recepção/admin, não no cadastro):
     PUT /admin/patients/{patient_id}/doctor   body: {"doctor_id": "..."} (ou null p/ desvincular)

2. Verificação do registro profissional (CRM/CRP) antes de liberar o
   acesso do médico aos dados de pacientes:
     PATCH /admin/professionals/{doctor_id}/verify

Mais listagens de apoio para a operação:
     GET /admin/patients
     GET /admin/professionals?verified=false

O admin em si é criado pelo script scripts/create_admin.py (não existe
cadastro público de admin, de propósito).
"""
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.deps import get_current_admin
from app.models import PatientProfile, DoctorProfile, User
from app.schemas import (
    DoctorAssignRequest, AdminPatientListItem, DoctorProfileOut, PatientProfileOut,
)

def _uuid_ou_404(valor: Optional[str], recurso: str) -> Optional[str]:
    """Valida o formato do ID antes de consultar o banco.

    Sem isso, colar um valor que não é UUID (ex.: um token por engano)
    derrubava a rota com erro 500; agora responde 404 com mensagem clara.
    """
    if valor is None:
        return None
    try:
        return str(uuid.UUID(str(valor)))
    except (ValueError, AttributeError, TypeError):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, f"{recurso} não encontrado (id inválido)"
        )


router = APIRouter(
    prefix="/admin",
    tags=["Administração"],
    dependencies=[Depends(get_current_admin)],
)


@router.get("/patients", response_model=list[AdminPatientListItem])
def list_all_patients(db: Session = Depends(get_db)):
    patients = (
        db.query(PatientProfile)
        .options(joinedload(PatientProfile.user))
        .all()
    )
    return [
        AdminPatientListItem(
            id=p.id,
            full_name=p.user.full_name,
            email=p.user.email,
            doctor_id=p.doctor_id,
        )
        for p in patients
    ]


@router.get("/professionals", response_model=list[DoctorProfileOut])
def list_professionals(
    verified: Optional[bool] = None,
    db: Session = Depends(get_db),
):
    """Com ?verified=false lista só os pendentes de validação de CRM/CRP."""
    query = db.query(DoctorProfile).options(joinedload(DoctorProfile.user))
    if verified is not None:
        query = query.filter(DoctorProfile.is_verified == verified)
    return query.all()


@router.patch("/professionals/{doctor_id}/verify", response_model=DoctorProfileOut)
def verify_professional(doctor_id: str, db: Session = Depends(get_db)):
    """Marca o registro profissional como conferido, liberando acesso a pacientes."""
    doctor_id = _uuid_ou_404(doctor_id, "Profissional")
    doctor = db.query(DoctorProfile).filter(DoctorProfile.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profissional não encontrado")

    doctor.is_verified = True
    db.commit()
    db.refresh(doctor)
    return doctor


@router.put("/patients/{patient_id}/doctor", response_model=PatientProfileOut)
def assign_doctor_to_patient(
    patient_id: str,
    payload: DoctorAssignRequest,
    db: Session = Depends(get_db),
):
    """
    Vincula (ou desvincula, com doctor_id=null) a paciente a um profissional.
    Só aceita profissionais já verificados — evita vincular alguém cujo
    CRM/CRP ainda não foi conferido.
    """
    patient_id = _uuid_ou_404(patient_id, "Paciente")
    payload.doctor_id = _uuid_ou_404(payload.doctor_id, "Profissional")

    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")

    if payload.doctor_id is None:
        patient.doctor_id = None
    else:
        doctor = db.query(DoctorProfile).filter(DoctorProfile.id == payload.doctor_id).first()
        if not doctor:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Profissional não encontrado")
        if not doctor.is_verified:
            raise HTTPException(
                status.HTTP_400_BAD_REQUEST,
                "Este profissional ainda não teve o registro verificado",
            )
        patient.doctor_id = doctor.id

    db.commit()
    db.refresh(patient)
    return patient
