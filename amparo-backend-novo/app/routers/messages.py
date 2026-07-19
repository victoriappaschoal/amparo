"""
Chat básico entre a paciente e o profissional vinculado a ela.

Sem tempo real (websockets): o aplicativo consulta mensagens novas a cada
poucos segundos (polling), o que é suficiente para o escopo do projeto.

Regras:
- A paciente só conversa com o SEU profissional (exige vínculo).
- O profissional precisa estar verificado e só conversa com pacientes
  vinculadas a ele.
- O conteúdo é gravado criptografado (EncryptedString no modelo).
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import (
    get_current_patient, get_current_verified_doctor,
    ensure_patient_belongs_to_doctor,
)
from app.models import Message, PatientProfile, DoctorProfile
from app.schemas import MessageCreate, MessageOut

router = APIRouter(prefix="/messages", tags=["Chat"])

_LIMITE_HISTORICO = 200  # mensagens mais recentes retornadas por conversa


def _historico(db: Session, patient_id: str, doctor_id: str):
    mensagens = (
        db.query(Message)
        .filter(Message.patient_id == patient_id, Message.doctor_id == doctor_id)
        .order_by(Message.created_at.desc())
        .limit(_LIMITE_HISTORICO)
        .all()
    )
    return list(reversed(mensagens))  # mais antigas primeiro, p/ exibição


# ---------- Paciente ----------

@router.get("", response_model=list[MessageOut])
def minhas_mensagens(
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Conversa da paciente com o profissional vinculado atual."""
    if patient.doctor_id is None:
        return []
    return _historico(db, patient.id, patient.doctor_id)


@router.post("", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def enviar_mensagem(
    payload: MessageCreate,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    if patient.doctor_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Você ainda não está vinculada a um profissional. Fale com a recepção.",
        )
    mensagem = Message(
        patient_id=patient.id,
        doctor_id=patient.doctor_id,
        sender_role="patient",
        content=payload.content.strip(),
        attachment_id=payload.attachment_id,
    )
    db.add(mensagem)
    db.commit()
    db.refresh(mensagem)
    return mensagem


# ---------- Profissional ----------

@router.get("/patient/{patient_id}", response_model=list[MessageOut])
def mensagens_da_paciente(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)
    return _historico(db, patient.id, doctor.id)


@router.post(
    "/patient/{patient_id}",
    response_model=MessageOut,
    status_code=status.HTTP_201_CREATED,
)
def responder_paciente(
    patient_id: str,
    payload: MessageCreate,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)

    mensagem = Message(
        patient_id=patient.id,
        doctor_id=doctor.id,
        sender_role="doctor",
        content=payload.content.strip(),
        attachment_id=payload.attachment_id,
    )
    db.add(mensagem)
    db.commit()
    db.refresh(mensagem)
    return mensagem
