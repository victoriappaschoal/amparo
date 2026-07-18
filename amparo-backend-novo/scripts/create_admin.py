"""
Cria (ou promove) um usuário administrador.

Não existe rota pública de cadastro de admin de propósito — o admin é
criado uma única vez, direto no servidor, com este script:

    python -m scripts.create_admin admin@amparo.app admin "Equipe Amparo"

A senha é pedida no terminal (não passa pelo histórico do shell).
Se o e-mail já existir, o usuário é promovido a admin.
"""
import sys
from getpass import getpass

from app.database import SessionLocal
from app.models import User, UserRole
from app.security import hash_password


def main():
    if len(sys.argv) != 4:
        print("Uso: python -m scripts.create_admin <email> <username> <nome completo>")
        sys.exit(1)

    email, username, full_name = sys.argv[1], sys.argv[2], sys.argv[3]

    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == email).first()
        if existing:
            existing.role = UserRole.admin
            db.commit()
            print(f"Usuário {email} já existia — promovido a admin.")
            return

        password = getpass("Senha do admin: ")
        confirm = getpass("Confirme a senha: ")
        if password != confirm:
            print("As senhas não coincidem.")
            sys.exit(1)
        if len(password) < 8:
            print("A senha precisa ter pelo menos 8 caracteres.")
            sys.exit(1)

        user = User(
            email=email,
            username=username,
            hashed_password=hash_password(password),
            full_name=full_name,
            role=UserRole.admin,
        )
        db.add(user)
        db.commit()
        print(f"Admin {email} criado com sucesso.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
