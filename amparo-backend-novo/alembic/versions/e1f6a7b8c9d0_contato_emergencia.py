"""contato de emergencia no perfil da paciente

Revision ID: e1f6a7b8c9d0
Revises: d0f4a5b6c7d8
Create Date: 2026-07-19
"""
from alembic import op
import sqlalchemy as sa

revision = 'e1f6a7b8c9d0'
down_revision = 'd0f4a5b6c7d8'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('patient_profiles', sa.Column('emergency_contact_name', sa.String(), nullable=True))
    op.add_column('patient_profiles', sa.Column('emergency_contact_phone', sa.String(), nullable=True))
    op.add_column('patient_profiles', sa.Column('emergency_contact_relationship', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('patient_profiles', 'emergency_contact_relationship')
    op.drop_column('patient_profiles', 'emergency_contact_phone')
    op.drop_column('patient_profiles', 'emergency_contact_name')
