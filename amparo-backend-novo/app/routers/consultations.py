from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import (
    get_current_patient, get_current_verified_doctor, ensure_patient_belongs_to_doctor,
)
from app.models import Consultation, ConsultationStatus, PatientProfile, DoctorProfile
from app.schemas import (
    ConsultationCreate, ConsultationOut, ConsultationDoctorView, ConsultationNoteUpdate
)

router = APIRouter(prefix="/consultations", tags=["Consultas"])


# ---------- Paciente ----------

@router.post("", response_model=ConsultationOut, status_code=status.HTTP_201_CREATED)
def schedule_consultation(
    payload: ConsultationCreate,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    # Sem vínculo com um médico não há com quem marcar — antes disso o
    # sistema criava uma consulta "órfã" (doctor_id NULL) que ninguém veria.
    if patient.doctor_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Você ainda não está vinculada a um profissional. Fale com a recepção.",
        )
    if payload.scheduled_at <= datetime.utcnow():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "A consulta deve ser marcada para uma data futura")

    consultation = Consultation(
        patient_id=patient.id,
        doctor_id=patient.doctor_id,
        scheduled_at=payload.scheduled_at,
    )
    db.add(consultation)
    db.commit()
    db.refresh(consultation)
    return consultation


@router.get("", response_model=list[ConsultationOut])
def list_my_consultations(
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    return db.query(Consultation).filter(
        Consultation.patient_id == patient.id
    ).order_by(Consultation.scheduled_at.desc()).all()


@router.patch("/{consultation_id}/cancel", response_model=ConsultationOut)
def cancel_my_consultation(
    consultation_id: str,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Paciente cancela uma consulta própria que ainda esteja agendada."""
    consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    if not consultation or consultation.patient_id != patient.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta não encontrada")
    if consultation.status != ConsultationStatus.scheduled:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Só é possível cancelar consultas agendadas")

    consultation.status = ConsultationStatus.cancelled
    db.commit()
    db.refresh(consultation)
    return consultation


# ---------- Médico ----------

@router.get("/my-schedule", response_model=list[ConsultationDoctorView])
def my_schedule(
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Agenda completa do médico logado (todas as pacientes), mais próximas primeiro."""
    return db.query(Consultation).filter(
        Consultation.doctor_id == doctor.id
    ).order_by(Consultation.scheduled_at.asc()).all()


@router.get("/patient/{patient_id}", response_model=list[ConsultationDoctorView])
def list_patient_consultations_for_doctor(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)

    return db.query(Consultation).filter(
        Consultation.patient_id == patient_id
    ).order_by(Consultation.scheduled_at.desc()).all()


@router.patch("/{consultation_id}/notes", response_model=ConsultationDoctorView)
def add_doctor_notes(
    consultation_id: str,
    payload: ConsultationNoteUpdate,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Só o médico grava/edita notas clínicas da consulta."""
    consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    if not consultation:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Consulta não encontrada")
    if consultation.doctor_id != doctor.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Esta consulta não é sua")

    consultation.doctor_notes = payload.doctor_notes
    if payload.status:
        consultation.status = payload.status
    db.commit()
    db.refresh(consultation)
    return consultation
