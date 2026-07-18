from datetime import date as date_type

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_patient
from app.models import MoodEntry, PatientProfile
from app.schemas import MoodEntryCreate, MoodEntryOut

router = APIRouter(prefix="/mood", tags=["Calendário de humor (aba inicial)"])


@router.post("", response_model=MoodEntryOut, status_code=status.HTTP_201_CREATED)
def register_mood(
    payload: MoodEntryCreate,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    existing = db.query(MoodEntry).filter(
        MoodEntry.patient_id == patient.id,
        MoodEntry.entry_date == payload.entry_date,
    ).first()
    if existing:
        existing.mood_scale = payload.mood_scale
        existing.note = payload.note
        db.commit()
        db.refresh(existing)
        return existing

    entry = MoodEntry(patient_id=patient.id, **payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/calendar", response_model=list[MoodEntryOut])
def get_calendar(
    start: date_type,
    end: date_type,
    patient: PatientProfile = Depends(get_current_patient),
    db: Session = Depends(get_db),
):
    """Retorna os registros de humor do período, para pintar o calendário na home."""
    if start > end:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Data inicial deve ser antes da final")
    return db.query(MoodEntry).filter(
        MoodEntry.patient_id == patient.id,
        MoodEntry.entry_date >= start,
        MoodEntry.entry_date <= end,
    ).order_by(MoodEntry.entry_date).all()
