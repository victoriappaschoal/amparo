"""janelas de horario de atendimento do profissional

Revision ID: f2a7b8c9d0e1
Revises: e1f6a7b8c9d0
Create Date: 2026-07-19
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'f2a7b8c9d0e1'
down_revision = 'e1f6a7b8c9d0'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'availability_windows',
        sa.Column('id', postgresql.UUID(as_uuid=False), primary_key=True),
        sa.Column(
            'doctor_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('doctor_profiles.id'), nullable=False,
        ),
        sa.Column('weekday', sa.Integer(), nullable=False),
        sa.Column('start_minute', sa.Integer(), nullable=False),
        sa.Column('end_minute', sa.Integer(), nullable=False),
    )
    op.create_index(
        'ix_availability_windows_doctor_id', 'availability_windows', ['doctor_id']
    )


def downgrade() -> None:
    op.drop_index('ix_availability_windows_doctor_id', table_name='availability_windows')
    op.drop_table('availability_windows')
