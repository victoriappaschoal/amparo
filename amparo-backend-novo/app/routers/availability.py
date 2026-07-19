"""
Horários de atendimento do profissional.

O profissional cadastra janelas (dia da semana + intervalo); a paciente
consulta as janelas do SEU profissional; e o agendamento de consultas
passa a validar contra elas (em consultations.py). Sem janelas
cadastradas, qualquer horário é aceito.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_patient, get_current_verified_doctor
from app.models import AvailabilityWindow, DoctorProfile, PatientProfile
from app.schemas import AvailabilityCreate, AvailabilityOut

router = APIRouter(prefix="/availability", tags=["Horários de atendimento"])


@router.get("/my", response_model=list[AvailabilityOut])
def minhas_janelas(
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    return (
        db.query(AvailabilityWindow)
        .filter(AvailabilityWindow.doctor_id == doctor.id)
        .order_by(AvailabilityWindow.weekday, AvailabilityWindow.start_minute)
        .all()
    )


@router.post("/my", response_model=AvailabilityOut, status_code=status.HTTP_201_CREATED)
def criar_janela(
    payload: AvailabilityCreate,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    janela = AvailabilityWindow(
        doctor_id=doctor.id,
        weekday=payload.weekday,
        start_minute=payload.start_minute,
        end_minute=payload.end_minute,
    )
    db.add(janela)
    db.commit()
    db.refresh(janela)
    return janela


@router.delete("/my/{window_id}", status_code=status.HTTP_204_NO_CONTENT)
def remover_janela(
    window_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    janela = (
        db.query(AvailabilityWindow)
        .filter(
            AvailabilityWindow.id == window_id,
            AvailabilityWindow.doctor_id == doctor.id,
        )
        .first()
    )
    if not janela:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Janela não encontrada")
    db.delete(janela)
    db.commit()


@router.get("/my-doctor", response_model=list[AvailabilityOut])
def janelas_do_meu_profissional(
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Janelas do profissional vinculado, para a paciente ver ao marcar."""
    if patient.doctor_id is None:
        return []
    return (
        db.query(AvailabilityWindow)
        .filter(AvailabilityWindow.doctor_id == patient.doctor_id)
        .order_by(AvailabilityWindow.weekday, AvailabilityWindow.start_minute)
        .all()
    )
