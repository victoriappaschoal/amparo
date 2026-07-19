"""campos de codigo de redefinicao de senha no usuario

Revision ID: d0f4a5b6c7d8
Revises: c8d2e3f4a5b6
Create Date: 2026-07-19
"""
from alembic import op
import sqlalchemy as sa

revision = 'd0f4a5b6c7d8'
down_revision = 'c8d2e3f4a5b6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('users', sa.Column('reset_code_hash', sa.String(), nullable=True))
    op.add_column('users', sa.Column('reset_code_expires_at', sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'reset_code_expires_at')
    op.drop_column('users', 'reset_code_hash')
