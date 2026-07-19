"""adiciona link_code ao perfil profissional (vinculo por codigo)

Revision ID: c8d2e3f4a5b6
Revises: b7c1d2e3f4a5
Create Date: 2026-07-19
"""
import secrets

from alembic import op
import sqlalchemy as sa

revision = 'c8d2e3f4a5b6'
down_revision = 'b7c1d2e3f4a5'
branch_labels = None
depends_on = None

_ALFABETO = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"


def upgrade() -> None:
    op.add_column('doctor_profiles', sa.Column('link_code', sa.String(), nullable=True))
    op.create_index('ix_doctor_profiles_link_code', 'doctor_profiles', ['link_code'], unique=True)

    # Backfill: gera código para profissionais já cadastrados.
    conn = op.get_bind()
    ids = [r[0] for r in conn.execute(sa.text("SELECT id FROM doctor_profiles WHERE link_code IS NULL"))]
    usados = set()
    for doctor_id in ids:
        while True:
            codigo = "".join(secrets.choice(_ALFABETO) for _ in range(6))
            if codigo not in usados:
                usados.add(codigo)
                break
        conn.execute(
            sa.text("UPDATE doctor_profiles SET link_code = :c WHERE id = :i"),
            {"c": codigo, "i": doctor_id},
        )


def downgrade() -> None:
    op.drop_index('ix_doctor_profiles_link_code', table_name='doctor_profiles')
    op.drop_column('doctor_profiles', 'link_code')
