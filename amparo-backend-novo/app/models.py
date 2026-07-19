import enum
import uuid
from datetime import datetime, date

from sqlalchemy import (
    LargeBinary,
    Column, String, Integer, Float, Boolean, Date, DateTime,
    ForeignKey, Enum, Text, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base
from app.encrypted_types import EncryptedString, EncryptedJSON


def gen_uuid():
    return str(uuid.uuid4())


class UserRole(str, enum.Enum):
    patient = "patient"
    doctor = "doctor"
    admin = "admin"


class ProfessionalType(str, enum.Enum):
    """Tela 'Cadastro profissional' permite Médico ou Psicólogo."""
    medico = "medico"
    psicologo = "psicologo"


class DeliveryType(str, enum.Enum):
    """Tela 'Cadastro de paciente' -> campo 'Tipo de parto'."""
    normal = "normal"
    cesarea = "cesarea"
    forceps = "forceps"


class User(Base):
    """
    Conta de login. Guarda só o essencial de autenticação.
    Dados de perfil ficam em PatientProfile / DoctorProfile,
    ligados 1-para-1, para separar claramente o que é "identidade"
    do que é "dado de saúde".
    """
    __tablename__ = "users"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    username = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.patient)
    # Redefinição de senha assistida: o admin gera um código temporário e o
    # usuário troca a senha com ele (sem infra de e-mail no escopo atual).
    reset_code_hash = Column(String, nullable=True)
    reset_code_expires_at = Column(DateTime, nullable=True)
    # Foto de perfil (referencia um StoredFile enviado pelo próprio usuário)
    profile_photo_id = Column(UUID(as_uuid=False), ForeignKey("stored_files.id", use_alter=True, name="fk_users_profile_photo"), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient_profile = relationship("PatientProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    doctor_profile = relationship("DoctorProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")


class PatientProfile(Base):
    __tablename__ = "patient_profiles"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=False), ForeignKey("users.id"), unique=True, nullable=False)
    # Vínculo é feito depois por admin/recepção (não no cadastro) -> sempre nullable.
    doctor_id = Column(UUID(as_uuid=False), ForeignKey("doctor_profiles.id"), nullable=True)

    birth_date = Column(Date, nullable=True)
    baby_birth_date = Column(Date, nullable=True)
    delivery_type = Column(Enum(DeliveryType), nullable=True)
    baby_name = Column(String, nullable=True)
    is_breastfeeding = Column(Boolean, nullable=True)
    # Contato de emergência: usado pelo profissional quando a paciente fica
    # dias sem registrar (alerta de inatividade) ou em situações de risco.
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    emergency_contact_relationship = Column(String, nullable=True)
    phone = Column(String, nullable=True)

    user = relationship("User", back_populates="patient_profile")
    doctor = relationship("DoctorProfile", back_populates="patients")

    mood_entries = relationship("MoodEntry", back_populates="patient", cascade="all, delete-orphan")
    symptom_entries = relationship("SymptomDiaryEntry", back_populates="patient", cascade="all, delete-orphan")
    epds_responses = relationship("EPDSResponse", back_populates="patient", cascade="all, delete-orphan")
    consultations = relationship("Consultation", back_populates="patient", cascade="all, delete-orphan")


class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    user_id = Column(UUID(as_uuid=False), ForeignKey("users.id"), unique=True, nullable=False)

    professional_type = Column(Enum(ProfessionalType), nullable=False)
    registration_number = Column(String, nullable=False)  # CRM (médico) ou CRP (psicólogo)
    registration_state = Column(String, nullable=False)  # UF do registro
    specialty = Column(String, nullable=True)  # especialidade médica / área de atuação
    offers_teleconsultation = Column(Boolean, default=False)
    phone = Column(String, nullable=True)
    professional_bio = Column(Text, nullable=True)  # descrição profissional
    is_verified = Column(Boolean, default=False)  # admin valida o registro antes de liberar acesso a pacientes
    # Código curto que o profissional compartilha com suas pacientes para o
    # vínculo por autosserviço (só funciona depois de is_verified=True).
    link_code = Column(String, unique=True, index=True, nullable=True)

    user = relationship("User", back_populates="doctor_profile")
    patients = relationship("PatientProfile", back_populates="doctor")


class MoodEntry(Base):
    """
    Check-in diário de humor exibido no calendário da aba inicial.
    Um registro por paciente por dia.
    """
    __tablename__ = "mood_entries"
    __table_args__ = (UniqueConstraint("patient_id", "entry_date", name="uq_mood_patient_date"),)

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    patient_id = Column(UUID(as_uuid=False), ForeignKey("patient_profiles.id"), nullable=False)
    entry_date = Column(Date, nullable=False, default=date.today)
    mood_scale = Column(Integer, nullable=False)  # ex: 1 (muito mal) a 5 (muito bem)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="mood_entries")


class SymptomDiaryEntry(Base):
    """
    Diário de sintomas. As respostas (ex.: {"dor_abdominal": 3, "dor_nas_costas": 1})
    ficam num JSON de escala 0-5 por sintoma, mais um campo livre de observações.
    """
    __tablename__ = "symptom_diary_entries"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    patient_id = Column(UUID(as_uuid=False), ForeignKey("patient_profiles.id"), nullable=False)
    entry_date = Column(Date, nullable=False, default=date.today)
    answers = Column(EncryptedJSON, nullable=False)  # {"dor_abdominal": 0-5, ...}
    observations = Column(EncryptedString, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="symptom_entries")


class EPDSResponse(Base):
    """
    Escala de Depressão Pós-natal de Edimburgo (10 perguntas, 0-3 cada).
    REGRA DE NEGÓCIO CRÍTICA: a pontuação (score) e a interpretação de risco
    NUNCA são retornadas para o usuário paciente pela API — apenas para o
    médico responsável. Ver app/routers/emotional_health.py.
    """
    __tablename__ = "epds_responses"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    patient_id = Column(UUID(as_uuid=False), ForeignKey("patient_profiles.id"), nullable=False)
    entry_date = Column(Date, nullable=False, default=date.today)
    answers = Column(EncryptedJSON, nullable=False)  # lista com as 10 respostas (0-3)
    score = Column(Integer, nullable=False)
    risk_level = Column(String, nullable=False)  # "baixo" | "moderado" | "alto"
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="epds_responses")


class ConsultationStatus(str, enum.Enum):
    scheduled = "scheduled"
    completed = "completed"
    cancelled = "cancelled"


class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    patient_id = Column(UUID(as_uuid=False), ForeignKey("patient_profiles.id"), nullable=False)
    doctor_id = Column(UUID(as_uuid=False), ForeignKey("doctor_profiles.id"), nullable=True)
    scheduled_at = Column(DateTime, nullable=False)
    status = Column(Enum(ConsultationStatus), default=ConsultationStatus.scheduled)
    doctor_notes = Column(EncryptedString, nullable=True)  # só o médico vê
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("PatientProfile", back_populates="consultations")


class BlogArticle(Base):
    __tablename__ = "blog_articles"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    category = Column(String, nullable=True)
    published = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Message(Base):
    """
    Chat básico paciente <-> profissional vinculado.

    O par (patient_id, doctor_id) define a conversa. O doctor_id é gravado
    no envio (e não resolvido na leitura) para o histórico se preservar
    mesmo se o vínculo mudar no futuro. O conteúdo é dado sensível de
    saúde -> criptografado no banco, como o EPDS e o diário.
    """
    __tablename__ = "messages"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    patient_id = Column(
        UUID(as_uuid=False), ForeignKey("patient_profiles.id"),
        nullable=False, index=True,
    )
    doctor_id = Column(
        UUID(as_uuid=False), ForeignKey("doctor_profiles.id"),
        nullable=False, index=True,
    )
    sender_role = Column(String, nullable=False)  # 'patient' | 'doctor'
    content = Column(EncryptedString, nullable=False)
    # Anexo opcional (imagem) enviado junto com a mensagem
    attachment_id = Column(UUID(as_uuid=False), ForeignKey("stored_files.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)

# Alfabeto sem caracteres ambíguos (0/O, 1/I/L) para o código de vínculo.
_LINK_CODE_ALFABETO = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


def gerar_link_code(db_session) -> str:
    """Gera um código de 6 caracteres único entre os profissionais."""
    import secrets
    while True:
        codigo = "".join(secrets.choice(_LINK_CODE_ALFABETO) for _ in range(6))
        existe = (
            db_session.query(DoctorProfile)
            .filter(DoctorProfile.link_code == codigo)
            .first()
        )
        if not existe:
            return codigo


class AvailabilityWindow(Base):
    """
    Janela de atendimento do profissional (ex.: segunda, 08:00-12:00).
    weekday segue o ISO: 1=segunda ... 7=domingo (igual ao Dart).
    Horários em minutos desde a meia-noite, no fuso de Brasília.
    Se o profissional não cadastrar nenhuma janela, qualquer horário vale.
    """
    __tablename__ = "availability_windows"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    doctor_id = Column(
        UUID(as_uuid=False), ForeignKey("doctor_profiles.id"),
        nullable=False, index=True,
    )
    weekday = Column(Integer, nullable=False)        # 1=seg ... 7=dom
    start_minute = Column(Integer, nullable=False)   # 480 = 08:00
    end_minute = Column(Integer, nullable=False)     # 720 = 12:00


class StoredFile(Base):
    """
    Arquivo enviado pelo app (foto de perfil ou anexo do chat), guardado
    no próprio banco (bytea) — simples e suficiente para o escopo:
    sem serviço externo de armazenamento. Limite de 5 MB por arquivo.
    """
    __tablename__ = "stored_files"

    id = Column(UUID(as_uuid=False), primary_key=True, default=gen_uuid)
    owner_user_id = Column(
        UUID(as_uuid=False), ForeignKey("users.id"), nullable=False, index=True,
    )
    filename = Column(String, nullable=False)
    mime_type = Column(String, nullable=False)
    size = Column(Integer, nullable=False)
    data = Column(LargeBinary, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
