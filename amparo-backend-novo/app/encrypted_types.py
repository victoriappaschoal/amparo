"""
Tipo de coluna customizado para SQLAlchemy que criptografa o valor
antes de gravar no banco e descriptografa ao ler.

Usado nos campos mais sensíveis (respostas e pontuação da Escala de
Edimburgo) para que, mesmo em caso de acesso indevido ao banco de
dados bruto, os dados de saúde mental fiquem protegidos.
"""
import json
from cryptography.fernet import Fernet
from sqlalchemy.types import TypeDecorator, String

from app.config import settings

_fernet = Fernet(settings.field_encryption_key.encode())


class EncryptedString(TypeDecorator):
    """Armazena uma string criptografada (Fernet/AES) como texto no banco."""

    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return _fernet.encrypt(value.encode()).decode()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return _fernet.decrypt(value.encode()).decode()


class EncryptedJSON(TypeDecorator):
    """Armazena um dict/list como JSON criptografado."""

    impl = String
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        raw = json.dumps(value)
        return _fernet.encrypt(raw.encode()).decode()

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        raw = _fernet.decrypt(value.encode()).decode()
        return json.loads(raw)
