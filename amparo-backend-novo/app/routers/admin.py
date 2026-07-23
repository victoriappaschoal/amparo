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
import secrets
import uuid
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.deps import get_current_admin
from app.models import (
    PatientProfile, DoctorProfile, User, _LINK_CODE_ALFABETO,
    Message, Consultation, MoodEntry, SymptomDiaryEntry, EPDSResponse,
    AvailabilityWindow, StoredFile,
)
from app.schemas import (
    DoctorAssignRequest, AdminPatientListItem, DoctorProfileOut, PatientProfileOut,
    AdminResetCodeOut,
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

@router.post("/users/{username}/reset-code", response_model=AdminResetCodeOut)
def gerar_codigo_redefinicao(username: str, db: Session = Depends(get_db)):
    """
    Gera um código temporário (30 min) para o usuário trocar a própria senha
    em "Esqueci minha senha". O código é mostrado UMA vez ao admin, que o
    repassa à pessoa por um canal seguro; no banco fica apenas o hash.
    """
    from app.security import hash_password

    user = db.query(User).filter(User.username == username).first()
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Usuário não encontrado")

    codigo = "".join(secrets.choice(_LINK_CODE_ALFABETO) for _ in range(8))
    user.reset_code_hash = hash_password(codigo)
    user.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=30)
    db.commit()

    return AdminResetCodeOut(code=codigo, expires_at=user.reset_code_expires_at)

def _apagar_arquivos_do_usuario(user: User, db: Session) -> None:
    """Remove a foto de perfil e os arquivos enviados pelo usuário."""
    user.profile_photo_id = None
    db.flush()
    db.query(StoredFile).filter(StoredFile.owner_user_id == user.id).delete()


@router.delete("/patients/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def excluir_paciente(patient_id: str, db: Session = Depends(get_db)):
    """
    Exclui a paciente e TODOS os seus dados (registros, consultas, mensagens
    e arquivos). Ação irreversível — o aplicativo pede confirmação dupla.
    """
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")

    user = patient.user
    db.query(Message).filter(Message.patient_id == patient.id).delete()
    db.query(Consultation).filter(Consultation.patient_id == patient.id).delete()
    db.query(MoodEntry).filter(MoodEntry.patient_id == patient.id).delete()
    db.query(SymptomDiaryEntry).filter(SymptomDiaryEntry.patient_id == patient.id).delete()
    db.query(EPDSResponse).filter(EPDSResponse.patient_id == patient.id).delete()
    _apagar_arquivos_do_usuario(user, db)
    db.delete(patient)
    db.delete(user)
    db.commit()


@router.delete("/professionals/{doctor_id}", status_code=status.HTTP_204_NO_CONTENT)
def excluir_profissional(doctor_id: str, db: Session = Depends(get_db)):
    """
    Exclui o profissional. As pacientes vinculadas são DESVINCULADAS
    (não são excluídas) e podem ser vinculadas a outro profissional.
    Mensagens e consultas dele são removidas.
    """
    doctor = db.query(DoctorProfile).filter(DoctorProfile.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Profissional não encontrado")

    user = doctor.user
    db.query(PatientProfile).filter(PatientProfile.doctor_id == doctor.id).update(
        {PatientProfile.doctor_id: None}
    )
    db.query(Message).filter(Message.doctor_id == doctor.id).delete()
    db.query(Consultation).filter(Consultation.doctor_id == doctor.id).delete()
    db.query(AvailabilityWindow).filter(AvailabilityWindow.doctor_id == doctor.id).delete()
    _apagar_arquivos_do_usuario(user, db)
    db.delete(doctor)
    db.delete(user)
    db.commit()

