"""arquivos: fotos de perfil e anexos do chat

Revision ID: a3b8c9d0e1f2
Revises: f2a7b8c9d0e1
Create Date: 2026-07-19
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = 'a3b8c9d0e1f2'
down_revision = 'f2a7b8c9d0e1'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'stored_files',
        sa.Column('id', postgresql.UUID(as_uuid=False), primary_key=True),
        sa.Column(
            'owner_user_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('users.id'), nullable=False,
        ),
        sa.Column('filename', sa.String(), nullable=False),
        sa.Column('mime_type', sa.String(), nullable=False),
        sa.Column('size', sa.Integer(), nullable=False),
        sa.Column('data', sa.LargeBinary(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )
    op.create_index('ix_stored_files_owner', 'stored_files', ['owner_user_id'])
    op.add_column(
        'users',
        sa.Column(
            'profile_photo_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('stored_files.id'), nullable=True,
        ),
    )
    op.add_column(
        'messages',
        sa.Column(
            'attachment_id', postgresql.UUID(as_uuid=False),
            sa.ForeignKey('stored_files.id'), nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column('messages', 'attachment_id')
    op.drop_column('users', 'profile_photo_id')
    op.drop_index('ix_stored_files_owner', table_name='stored_files')
    op.drop_table('stored_files')
