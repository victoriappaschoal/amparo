from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_patient, get_current_verified_doctor, ensure_patient_belongs_to_doctor
from app.models import SymptomDiaryEntry, PatientProfile, DoctorProfile
from app.schemas import SymptomEntryCreate, SymptomEntryOut

router = APIRouter(prefix="/symptoms", tags=["Diário de sintomas"])


@router.post("", response_model=SymptomEntryOut, status_code=status.HTTP_201_CREATED)
def register_symptoms(
    payload: SymptomEntryCreate,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    entry = SymptomDiaryEntry(patient_id=patient.id, **payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("", response_model=list[SymptomEntryOut])
def list_my_symptoms(
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    return db.query(SymptomDiaryEntry).filter(
        SymptomDiaryEntry.patient_id == patient.id
    ).order_by(SymptomDiaryEntry.entry_date.desc()).all()


@router.get("/patient/{patient_id}", response_model=list[SymptomEntryOut])
def list_patient_symptoms_for_doctor(
    patient_id: str,
    doctor: DoctorProfile = Depends(get_current_verified_doctor),
    db: Session = Depends(get_db),
):
    """Médico consulta o diário de sintomas de um paciente vinculado a ele."""
    patient = db.query(PatientProfile).filter(PatientProfile.id == patient_id).first()
    if not patient:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Paciente não encontrado")
    ensure_patient_belongs_to_doctor(patient, doctor)

    return db.query(SymptomDiaryEntry).filter(
        SymptomDiaryEntry.patient_id == patient_id
    ).order_by(SymptomDiaryEntry.entry_date.desc()).all()
