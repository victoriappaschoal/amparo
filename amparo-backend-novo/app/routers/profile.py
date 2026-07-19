from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_patient, get_current_doctor
from app.models import PatientProfile, DoctorProfile
from app.schemas import (
    PatientProfileOut, PatientProfileUpdate,
    DoctorProfileOut, DoctorProfileUpdate, LinkByCodeRequest,
)

router = APIRouter(prefix="/profile", tags=["Perfil"])


@router.get("/patient/me", response_model=PatientProfileOut)
def get_my_patient_profile(patient: PatientProfile = Depends(get_current_patient)):
    return patient


@router.put("/patient/me", response_model=PatientProfileOut)
def update_my_patient_profile(
    payload: PatientProfileUpdate,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    data = payload.model_dump(exclude_unset=True)

    if "full_name" in data:
        patient.user.full_name = data.pop("full_name")

    for field, value in data.items():
        setattr(patient, field, value)

    db.commit()
    db.refresh(patient)
    return patient


@router.get("/professional/me", response_model=DoctorProfileOut)
def get_my_doctor_profile(doctor: DoctorProfile = Depends(get_current_doctor)):
    return doctor


@router.put("/professional/me", response_model=DoctorProfileOut)
def update_my_doctor_profile(
    payload: DoctorProfileUpdate,
    doctor: DoctorProfile = Depends(get_current_doctor),
    db: Session = Depends(get_db),
):
    data = payload.model_dump(exclude_unset=True)

    if "full_name" in data:
        doctor.user.full_name = data.pop("full_name")

    for field, value in data.items():
        setattr(doctor, field, value)

    db.commit()
    db.refresh(doctor)
    return doctor


@router.post("/patient/link-doctor", response_model=PatientProfileOut)
def link_doctor_by_code(
    payload: LinkByCodeRequest,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """
    Vínculo por código: a paciente digita o código que o profissional
    compartilhou com ela (ex.: na consulta). Regras:
    - o código precisa existir;
    - o profissional precisa estar VERIFICADO pelo admin (senão 400);
    - se a paciente já tem profissional, o vínculo é substituído
      (útil para troca de acompanhamento; o admin segue como retaguarda).
    """
    codigo = payload.code.strip().upper()
    doctor = (
        db.query(DoctorProfile).filter(DoctorProfile.link_code == codigo).first()
    )
    if not doctor:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Código não encontrado. Confira com o profissional e tente de novo.",
        )
    if not doctor.is_verified:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Este profissional ainda não teve o registro verificado pela administração.",
        )

    patient.doctor_id = doctor.id
    db.commit()
    db.refresh(patient)
    return patient

