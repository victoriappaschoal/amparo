from datetime import datetime, timedelta
from typing import Literal

from jose import jwt, JWTError
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def create_token(subject: str, role: str, token_type: Literal["access", "refresh"]) -> str:
    if token_type == "access":
        expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    else:
        expire = datetime.utcnow() + timedelta(days=settings.refresh_token_expire_days)

    payload = {
        "sub": subject,
        "role": role,
        "type": token_type,
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_token(token: str) -> dict:
    """Levanta JWTError se o token for inválido ou tiver expirado."""
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
