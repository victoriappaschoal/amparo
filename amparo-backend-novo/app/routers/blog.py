from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import BlogArticle, User, UserRole
from app.schemas import BlogArticleOut, BlogArticleCreate
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
