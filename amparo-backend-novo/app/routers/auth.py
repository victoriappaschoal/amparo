from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from slowapi import Limiter
from slowapi.util import get_remote_address
from jose import JWTError

from app.database import get_db
from app.models import User, UserRole, PatientProfile, DoctorProfile, gerar_link_code
from datetime import datetime

from app.schemas import (
    ResetPasswordRequest,
    PatientRegister, ProfessionalRegister, UserLogin,
    TokenPair, RefreshRequest, UserOut,
)
from app.security import hash_password, verify_password, create_token, decode_token

router = APIRouter(prefix="/auth", tags=["Autenticação"])
limiter = Limiter(key_func=get_remote_address)


def _check_email_and_username_free(db: Session, email: str, username: str):
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Este e-mail já está cadastrado")
    if db.query(User).filter(User.username == username).first():
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Este usuário já está em uso")


@router.post("/register/patient", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register_patient(payload: PatientRegister, db: Session = Depends(get_db)):
    """Corresponde à tela 'Cadastro de paciente' (fluxo 'Sou paciente')."""
    _check_email_and_username_free(db, payload.email, payload.username)

    user = User(
        email=payload.email,
        username=payload.username,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role=UserRole.patient,
    )
    db.add(user)
    db.flush()

    profile = PatientProfile(
        user_id=user.id,
        birth_date=payload.birth_date,
        baby_birth_date=payload.baby_birth_date,
        delivery_type=payload.delivery_type,
        baby_name=payload.baby_name,
        is_breastfeeding=payload.is_breastfeeding,
        phone=payload.phone,
        emergency_contact_name=payload.emergency_contact_name,
        emergency_contact_phone=payload.emergency_contact_phone,
        emergency_contact_relationship=payload.emergency_contact_relationship,
        # doctor_id fica em branco de propósito: vínculo é feito depois
        # pela recepção/admin, não no momento do cadastro.
    )
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user


@router.post("/register/professional", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register_professional(payload: ProfessionalRegister, db: Session = Depends(get_db)):
    """Corresponde à tela 'Cadastro profissional' (fluxo 'Sou profissional')."""
    _check_email_and_username_free(db, payload.email, payload.username)

    user = User(
        email=payload.email,
        username=payload.username,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        role=UserRole.doctor,
    )
    db.add(user)
    db.flush()

    profile = DoctorProfile(
        user_id=user.id,
        professional_type=payload.professional_type,
        registration_number=payload.registration_number,
        registration_state=payload.registration_state,
        specialty=payload.specialty,
        offers_teleconsultation=payload.offers_teleconsultation,
        phone=payload.phone,
        professional_bio=payload.professional_bio,
        is_verified=False,  # admin confere o CRM/CRP antes de liberar acesso pleno
        link_code=gerar_link_code(db),
    )
    db.add(profile)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=TokenPair)
@limiter.limit("5/minute")  # protege contra força bruta de senha
def login(request: Request, payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == payload.username).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuário ou senha inválidos")
    if not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Usuário desativado")

    return TokenPair(
        access_token=create_token(user.id, user.role.value, "access"),
        refresh_token=create_token(user.id, user.role.value, "refresh"),
    )


@router.post("/refresh", response_model=TokenPair)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    try:
        data = decode_token(payload.refresh_token)
        if data.get("type") != "refresh":
            raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token inválido")
    except JWTError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Token inválido ou expirado")

    user = db.query(User).filter(User.id == data["sub"]).first()
    if not user or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Usuário inválido")

    return TokenPair(
        access_token=create_token(user.id, user.role.value, "access"),
        refresh_token=create_token(user.id, user.role.value, "refresh"),
    )

@router.post("/reset-password", status_code=status.HTTP_200_OK)
@limiter.limit("5/minute")  # mesmo cuidado anti força bruta do login
def reset_password(request: Request, payload: ResetPasswordRequest, db: Session = Depends(get_db)):
    """
    Troca a senha usando o código temporário gerado pela administração.
    Mensagem de erro única de propósito: não revela se o usuário existe,
    se o código está errado ou vencido.
    """
    erro = HTTPException(
        status.HTTP_400_BAD_REQUEST,
        "Código inválido ou vencido. Peça um novo à administração.",
    )

    user = db.query(User).filter(User.username == payload.username).first()
    if not user or not user.reset_code_hash or not user.reset_code_expires_at:
        raise erro
    if user.reset_code_expires_at < datetime.utcnow():
        raise erro
    if not verify_password(payload.code.strip().upper(), user.reset_code_hash):
        raise erro

    user.hashed_password = hash_password(payload.new_password)
    user.reset_code_hash = None
    user.reset_code_expires_at = None
    db.commit()
    return {"detail": "Senha redefinida com sucesso"}

