"""
Dependências reutilizáveis pelos routers: quem é o usuário logado,
e checagens de papel (paciente / médico) e de posse do recurso.

A regra central de segurança do app mora aqui:
- Paciente só enxerga os próprios dados.
- Médico só enxerga dados de pacientes vinculados a ele (doctor_id).
- Resultado do EPDS nunca passa pela dependência "get_current_patient"
  em rotas de leitura de score — isso é reforçado no próprio router.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, UserRole, PatientProfile, DoctorProfile
from app.security import decode_token

# HTTPBearer faz o botão "Authorize" do Swagger virar um campo simples
# de colar o access_token (obtido no POST /auth/login).
bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Não foi possível validar as credenciais",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is None:
        raise credentials_exception
    token = credentials.credentials
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise credentials_exception
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(User).filter(User.id == user_id).first()
    if user is None or not user.is_active:
        raise credentials_exception
    return user


def get_current_patient(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> PatientProfile:
    if user.role != UserRole.patient:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Acesso restrito a pacientes")
    profile = db.query(PatientProfile).filter(PatientProfile.user_id == user.id).first()
    if not profile:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Perfil de paciente não encontrado")
    return profile


def get_current_doctor(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> DoctorProfile:
    if user.role != UserRole.doctor:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Acesso restrito a médicos")
    profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == user.id).first()
    if not profile:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Perfil de médico não encontrado")
    return profile


def get_current_verified_doctor(doctor: DoctorProfile = Depends(get_current_doctor)) -> DoctorProfile:
    """
    Igual a get_current_doctor, mas exige que o registro profissional (CRM/CRP)
    já tenha sido validado pelo admin. Usada em TODA rota que expõe dados de
    pacientes — um profissional recém-cadastrado (is_verified=False) consegue
    ver/editar o próprio perfil, mas não acessa dado de saúde de ninguém.
    """
    if not doctor.is_verified:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Seu registro profissional ainda não foi verificado pela administração",
        )
    return doctor


def get_current_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Acesso restrito a administradores")
    return user


def ensure_patient_belongs_to_doctor(patient: PatientProfile, doctor: DoctorProfile):
    """Um médico só pode ver detalhes de pacientes vinculados a ele."""
    if patient.doctor_id != doctor.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Este paciente não está vinculado a você")
