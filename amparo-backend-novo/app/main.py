from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.routers import (
    auth, mood, symptoms, emotional_health, consultations, blog, profile,
    patients, admin, messages, availability, files,
)
from app.routers.auth import limiter

app = FastAPI(
    title="Amparo API",
    description="Backend do app de acompanhamento pós-parto Amparo.",
    version="1.0.0",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(mood.router)
app.include_router(symptoms.router)
app.include_router(emotional_health.router)
app.include_router(consultations.router)
app.include_router(blog.router)
app.include_router(patients.router)
app.include_router(admin.router)
app.include_router(messages.router)
app.include_router(availability.router)
app.include_router(files.router)


@app.get("/health", tags=["Status"])
def health_check():
    return {"status": "ok"}
