"""
Upload e download de arquivos (fotos de perfil e anexos do chat).

Decisões de segurança para o escopo do projeto:
- Só usuários autenticados; limite de 5 MB; apenas imagens (JPEG/PNG/WebP).
- Download permitido para: o dono do arquivo; os participantes da conversa,
  quando o arquivo é anexo de mensagem; e qualquer autenticado quando o
  arquivo é foto de perfil (avatares são visíveis no app).
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, status
from fastapi.responses import Response
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import (
    StoredFile, User, Message, PatientProfile, DoctorProfile, BlogArticle,
)
from app.schemas import StoredFileOut, ProfilePhotoSet

router = APIRouter(prefix="/files", tags=["Arquivos"])

_MAX_BYTES = 5 * 1024 * 1024  # 5 MB
_TIPOS_PERMITIDOS = {"image/jpeg", "image/png", "image/webp"}


@router.post("", response_model=StoredFileOut, status_code=status.HTTP_201_CREATED)
async def upload(
    file: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if file.content_type not in _TIPOS_PERMITIDOS:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Tipo de arquivo não permitido. Envie uma imagem JPEG, PNG ou WebP.",
        )
    data = await file.read()
    if len(data) > _MAX_BYTES:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Arquivo muito grande (máximo 5 MB).",
        )

    arquivo = StoredFile(
        owner_user_id=user.id,
        filename=file.filename or "arquivo",
        mime_type=file.content_type,
        size=len(data),
        data=data,
    )
    db.add(arquivo)
    db.commit()
    db.refresh(arquivo)
    return arquivo


def _pode_baixar(arquivo: StoredFile, user: User, db: Session) -> bool:
    if arquivo.owner_user_id == user.id:
        return True

    # Foto de perfil de alguém -> avatar, visível a autenticados
    dono_como_foto = (
        db.query(User).filter(User.profile_photo_id == arquivo.id).first()
    )
    if dono_como_foto is not None:
        return True

    # Imagem de artigo do blog -> visível a autenticados
    artigo = (
        db.query(BlogArticle).filter(BlogArticle.image_file_id == arquivo.id).first()
    )
    if artigo is not None:
        return True

    # Anexo de mensagem -> só participantes da conversa
    mensagem = (
        db.query(Message).filter(Message.attachment_id == arquivo.id).first()
    )
    if mensagem is not None:
        paciente = (
            db.query(PatientProfile)
            .filter(PatientProfile.id == mensagem.patient_id)
            .first()
        )
        medico = (
            db.query(DoctorProfile)
            .filter(DoctorProfile.id == mensagem.doctor_id)
            .first()
        )
        return (paciente is not None and paciente.user_id == user.id) or (
            medico is not None and medico.user_id == user.id
        )

    return False


@router.get("/{file_id}")
def download(
    file_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    arquivo = db.query(StoredFile).filter(StoredFile.id == file_id).first()
    if not arquivo:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Arquivo não encontrado")
    if not _pode_baixar(arquivo, user, db):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Sem acesso a este arquivo")
    return Response(content=arquivo.data, media_type=arquivo.mime_type)


@router.put("/profile-photo", response_model=StoredFileOut)
def definir_foto_de_perfil(
    payload: ProfilePhotoSet,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Define a foto de perfil do próprio usuário (arquivo enviado por ele)."""
    arquivo = (
        db.query(StoredFile)
        .filter(
            StoredFile.id == payload.file_id,
            StoredFile.owner_user_id == user.id,
        )
        .first()
    )
    if not arquivo:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Arquivo não encontrado")
    user.profile_photo_id = arquivo.id
    db.commit()
    return arquivo
