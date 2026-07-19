"""
Configuracao dos testes (pytest).

Usa um banco PostgreSQL separado ("amparo_test") para nunca tocar nos dados
de desenvolvimento. Antes de rodar, crie o banco uma unica vez:

    psql -U postgres -c "CREATE DATABASE amparo_test;"

E rode os testes a partir da raiz do backend com:

    pytest -v

As variaveis abaixo podem ser sobrescritas por variaveis de ambiente
(TEST_DATABASE_URL) se o usuario/senha do seu Postgres forem diferentes.
"""
import os

# IMPORTANTE: definir as variaveis ANTES de importar o app, porque o
# config.py le o ambiente no momento do import.
os.environ.setdefault(
    "DATABASE_URL",
    os.environ.get(
        "TEST_DATABASE_URL",
        "postgresql://postgres:teste123@localhost:5432/amparo_test",
    ),
)
os.environ.setdefault("SECRET_KEY", "chave-somente-para-testes")
os.environ.setdefault(
    "FIELD_ENCRYPTION_KEY",
    # Chave Fernet fixa de teste (NUNCA usar fora dos testes)
    "sVdMyGVCP31L3hjzY6xkc4vFV0m6wYnUPu60Ait0Wh0=",
)
os.environ.setdefault("ALLOWED_ORIGINS", "http://localhost:5000")
os.environ.setdefault("ENVIRONMENT", "test")

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, engine, SessionLocal
from app.models import User, UserRole
from app.security import hash_password

# O rate limit do login (5/minuto) atrapalharia os testes, que logam dezenas
# de vezes. Desligamos so no ambiente de teste.
app.state.limiter.enabled = False


@pytest.fixture(autouse=True)
def banco_limpo():
    """Recria todas as tabelas antes de cada teste - isolamento total."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield


@pytest.fixture
def client():
    return TestClient(app)


# ---------------- Helpers ----------------

PACIENTE_PADRAO = {
    "full_name": "Paciente Teste",
    "email": "paciente@teste.com",
    "username": "paciente_t",
    "password": "senha12345",
    "confirm_password": "senha12345",
    "birth_date": "1995-03-10",
    "baby_birth_date": "2026-06-20",
    "delivery_type": "cesarea",
    "baby_name": "Alice",
    "is_breastfeeding": True,
}

PROFISSIONAL_PADRAO = {
    "full_name": "Dra. Teste",
    "email": "medica@teste.com",
    "username": "medica_t",
    "password": "senha12345",
    "confirm_password": "senha12345",
    "professional_type": "medico",
    "registration_number": "123456",
    "registration_state": "MG",
    "specialty": "Obstetricia",
    "offers_teleconsultation": True,
}


def criar_admin(username="admin_t", password="senha12345"):
    """Admin nao tem rota publica de cadastro; criamos direto no banco."""
    db = SessionLocal()
    try:
        user = User(
            email=f"{username}@teste.com",
            username=username,
            hashed_password=hash_password(password),
            full_name="Admin Teste",
            role=UserRole.admin,
        )
        db.add(user)
        db.commit()
    finally:
        db.close()
    return username, password


def login(client, username, password):
    resp = client.post(
        "/auth/login", json={"username": username, "password": password}
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}


def registrar_paciente(client, **extras):
    payload = {**PACIENTE_PADRAO, **extras}
    resp = client.post("/auth/register/patient", json=payload)
    assert resp.status_code == 201, resp.text
    return payload


def registrar_profissional(client, **extras):
    payload = {**PROFISSIONAL_PADRAO, **extras}
    resp = client.post("/auth/register/professional", json=payload)
    assert resp.status_code == 201, resp.text
    return payload
