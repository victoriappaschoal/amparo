"""adiciona tabela de mensagens (chat paciente-profissional)

Revision ID: b7c1d2e3f4a5
Revises: 054156a5fd88
Create Date: 2026-07-18
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'b7c1d2e3f4a5'
down_revision = '054156a5fd88'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'messages',
        sa.Column('id', postgresql.UUID(as_uuid=False), primary_key=True),
        sa.Column(
            'patient_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('patient_profiles.id'), nullable=False,
        ),
        sa.Column(
            'doctor_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('doctor_profiles.id'), nullable=False,
        ),
        sa.Column('sender_role', sa.String(), nullable=False),
        # conteúdo criptografado pela aplicação (EncryptedString) -> texto no banco
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )
    op.create_index('ix_messages_patient_id', 'messages', ['patient_id'])
    op.create_index('ix_messages_doctor_id', 'messages', ['doctor_id'])
    op.create_index('ix_messages_created_at', 'messages', ['created_at'])


def downgrade() -> None:
    op.drop_index('ix_messages_created_at', table_name='messages')
    op.drop_index('ix_messages_doctor_id', table_name='messages')
    op.drop_index('ix_messages_patient_id', table_name='messages')
    op.drop_table('messages')
