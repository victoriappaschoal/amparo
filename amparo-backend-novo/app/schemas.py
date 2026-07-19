from datetime import date, datetime
from typing import Optional, Literal

from pydantic import BaseModel, EmailStr, Field, conint, conlist, model_validator


# ---------- Auth ----------
# Duas telas de cadastro no front ("Sou paciente" / "Sou profissional"),
# cada uma com seu próprio conjunto de campos -> dois schemas diferentes.

class PatientRegister(BaseModel):
    full_name: str
    email: EmailStr
    username: str = Field(min_length=3)
    password: str = Field(min_length=8)
    confirm_password: str
    birth_date: date
    baby_birth_date: date
    delivery_type: Literal["normal", "cesarea", "forceps"]
    baby_name: Optional[str] = None
    is_breastfeeding: bool
    phone: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None

    @model_validator(mode="after")
    def passwords_match(self):
        if self.password != self.confirm_password:
            raise ValueError("As senhas não coincidem")
        return self


class ProfessionalRegister(BaseModel):
    full_name: str
    email: EmailStr
    username: str = Field(min_length=3)
    password: str = Field(min_length=8)
    confirm_password: str
    professional_type: Literal["medico", "psicologo"]
    registration_number: str  # CRM ou CRP
    registration_state: str   # UF
    specialty: Optional[str] = None
    offers_teleconsultation: bool = False
    phone: Optional[str] = None
    professional_bio: Optional[str] = None

    @model_validator(mode="after")
    def passwords_match(self):
        if self.password != self.confirm_password:
            raise ValueError("As senhas não coincidem")
        return self


class UserLogin(BaseModel):
    username: str
    password: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    id: str
    email: EmailStr
    username: str
    full_name: str
    role: str

    class Config:
        from_attributes = True


# ---------- Perfil ----------

class PatientProfileOut(BaseModel):
    id: str
    birth_date: Optional[date]
    baby_birth_date: Optional[date]
    delivery_type: Optional[str]
    baby_name: Optional[str]
    is_breastfeeding: Optional[bool]
    phone: Optional[str]
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None
    doctor_id: Optional[str]
    user: UserOut

    class Config:
        from_attributes = True


class PatientProfileUpdate(BaseModel):
    """Todos os campos opcionais: paciente edita só o que quiser."""
    full_name: Optional[str] = None
    baby_name: Optional[str] = None
    is_breastfeeding: Optional[bool] = None
    phone: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None


class DoctorProfileOut(BaseModel):
    id: str
    professional_type: str
    registration_number: str
    registration_state: str
    specialty: Optional[str]
    offers_teleconsultation: bool
    phone: Optional[str]
    professional_bio: Optional[str]
    is_verified: bool
    link_code: Optional[str] = None
    user: UserOut

    class Config:
        from_attributes = True


class DoctorProfileUpdate(BaseModel):
    full_name: Optional[str] = None
    specialty: Optional[str] = None
    offers_teleconsultation: Optional[bool] = None
    phone: Optional[str] = None
    professional_bio: Optional[str] = None


# ---------- Mood / calendário ----------

class MoodEntryCreate(BaseModel):
    entry_date: date
    mood_scale: conint(ge=1, le=5)
    note: Optional[str] = None


class MoodEntryOut(BaseModel):
    id: str
    entry_date: date
    mood_scale: int
    note: Optional[str]

    class Config:
        from_attributes = True


# ---------- Diário de sintomas ----------

class SymptomEntryCreate(BaseModel):
    entry_date: date
    answers: dict[str, conint(ge=0, le=5)]  # ex: {"dor_abdominal": 3, "dor_nas_costas": 1}
    observations: Optional[str] = None


class SymptomEntryOut(BaseModel):
    id: str
    entry_date: date
    answers: dict[str, int]
    observations: Optional[str]

    class Config:
        from_attributes = True


# ---------- EPDS (saúde emocional) ----------

class EPDSSubmit(BaseModel):
    entry_date: date
    answers: conlist(conint(ge=0, le=3), min_length=10, max_length=10)


class EPDSPatientAck(BaseModel):
    """O paciente só recebe essa confirmação — nunca o score."""
    id: str
    entry_date: date
    status: str = "Questionário enviado. Os resultados serão avaliados pelo seu médico."

    class Config:
        from_attributes = True


class EPDSDoctorView(BaseModel):
    """Visão completa, restrita ao médico responsável."""
    id: str
    patient_id: str
    entry_date: date
    answers: list[int]
    score: int
    risk_level: str

    class Config:
        from_attributes = True


# ---------- Consultas ----------

class ConsultationCreate(BaseModel):
    scheduled_at: datetime


class ConsultationOut(BaseModel):
    id: str
    scheduled_at: datetime
    status: str

    class Config:
        from_attributes = True


class ConsultationDoctorView(ConsultationOut):
    doctor_notes: Optional[str]
    patient_id: str


class ConsultationNoteUpdate(BaseModel):
    doctor_notes: str
    status: Optional[Literal["scheduled", "completed", "cancelled"]] = None


# ---------- Pacientes (visão do médico) ----------

class PatientListItem(BaseModel):
    """Item da lista 'Meus pacientes' no app do médico."""
    id: str
    full_name: str
    baby_birth_date: Optional[date]
    delivery_type: Optional[str]
    phone: Optional[str]
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relationship: Optional[str] = None


class PatientDetailForDoctor(BaseModel):
    """Detalhe de uma paciente vinculada, na visão do médico."""
    id: str
    full_name: str
    email: EmailStr
    phone: Optional[str]
    birth_date: Optional[date]
    baby_birth_date: Optional[date]
    baby_name: Optional[str]
    delivery_type: Optional[str]
    is_breastfeeding: Optional[bool]


class PatientSummaryForDoctor(BaseModel):
    """
    Resumo clínico rápido para o dashboard do médico. Inclui apenas
    dados que o médico já tem permissão de ver individualmente
    (EPDS, sintomas, consultas) — humor fica de fora de propósito.
    """
    patient_id: str
    last_epds_date: Optional[date] = None
    last_epds_risk_level: Optional[str] = None
    symptom_entries_last_30_days: int = 0
    next_consultation_at: Optional[datetime] = None
    # Vigilância de inatividade: data do último registro diário (humor OU
    # sintomas) e dias corridos sem registrar (conta desde o cadastro se a
    # paciente nunca registrou). O app alerta quando passa de 3 dias.
    last_daily_entry_date: Optional[date] = None
    days_without_daily_entry: int = 0


# ---------- Admin ----------

class DoctorAssignRequest(BaseModel):
    """Body de PUT /admin/patients/{id}/doctor. doctor_id=None desvincula."""
    doctor_id: Optional[str] = None


class AdminPatientListItem(BaseModel):
    id: str
    full_name: str
    email: EmailStr
    doctor_id: Optional[str]


# ---------- Blog ----------

class BlogArticleOut(BaseModel):
    id: str
    title: str
    content: str
    category: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True


class BlogArticleCreate(BaseModel):
    title: str
    content: str
    category: Optional[str] = None
    published: bool = True


# ---------- Chat ----------

class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)


class MessageOut(BaseModel):
    id: str
    sender_role: str  # 'patient' | 'doctor'
    content: str
    created_at: datetime

    class Config:
        from_attributes = True


class LinkByCodeRequest(BaseModel):
    """Vinculo por codigo: a paciente digita o codigo do profissional."""
    code: str = Field(min_length=4, max_length=12)


class ResetPasswordRequest(BaseModel):
    """Troca de senha com o codigo temporario gerado pelo admin."""
    username: str
    code: str = Field(min_length=4, max_length=16)
    new_password: str = Field(min_length=8)


class AdminResetCodeOut(BaseModel):
    code: str
    expires_at: datetime


# ---------- Horarios de atendimento ----------

class AvailabilityCreate(BaseModel):
    weekday: int = Field(ge=1, le=7)          # 1=segunda ... 7=domingo
    start_minute: int = Field(ge=0, le=1439)
    end_minute: int = Field(ge=1, le=1440)

    @model_validator(mode="after")
    def intervalo_valido(self):
        if self.end_minute <= self.start_minute:
            raise ValueError("O fim da janela deve ser depois do inicio")
        return self


class AvailabilityOut(AvailabilityCreate):
    id: str

    class Config:
        from_attributes = True
