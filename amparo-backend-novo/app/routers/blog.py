from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import BlogArticle, User, UserRole
from app.schemas import BlogArticleOut, BlogArticleCreate, BlogArticleUpdate
from fastapi import HTTPException

router = APIRouter(prefix="/blog", tags=["Blog"])


@router.get("", response_model=list[BlogArticleOut])
def list_articles(db: Session = Depends(get_db)):
    """Lista pública (dentro do app) de artigos já publicados."""
    return db.query(BlogArticle).filter(BlogArticle.published == True).order_by(  # noqa: E712
        BlogArticle.created_at.desc()
    ).all()


@router.post("", response_model=BlogArticleOut, status_code=status.HTTP_201_CREATED)
def create_article(
    payload: BlogArticleCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Só admin/equipe cadastra artigos (curadoria feita por vocês, como combinado)."""
    if user.role != UserRole.admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Apenas administradores podem publicar artigos")

    article = BlogArticle(**payload.model_dump())
    db.add(article)
    db.commit()
    db.refresh(article)
    return article


def _artigo_ou_404(article_id: str, db: Session) -> BlogArticle:
    artigo = db.query(BlogArticle).filter(BlogArticle.id == article_id).first()
    if not artigo:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Artigo não encontrado")
    return artigo


def _exigir_admin(user: User) -> None:
    if user.role != UserRole.admin:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Apenas administradores podem gerenciar artigos"
        )


@router.put("/{article_id}", response_model=BlogArticleOut)
def update_article(
    article_id: str,
    payload: BlogArticleUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Edita um artigo existente (título, conteúdo, categoria)."""
    _exigir_admin(user)
    artigo = _artigo_ou_404(article_id, db)
    for campo, valor in payload.model_dump(exclude_unset=True).items():
        setattr(artigo, campo, valor)
    db.commit()
    db.refresh(artigo)
    return artigo


@router.delete("/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_article(
    article_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Exclui um artigo do blog."""
    _exigir_admin(user)
    artigo = _artigo_ou_404(article_id, db)
    db.delete(artigo)
    db.commit()
