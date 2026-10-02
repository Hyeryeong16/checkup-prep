"""
PostgreSQL 연결 관리.
DATABASE_URL 환경변수(.env)에서 접속 정보를 읽습니다.
예: DATABASE_URL=postgresql://postgres:password@localhost:5432/checkup_prep
"""
import os
from contextlib import contextmanager

import psycopg
from psycopg.rows import dict_row
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/checkup_prep",
)


@contextmanager
def get_connection():
    """with get_connection() as conn: 형태로 사용. 매 요청마다 새 연결(학습 프로젝트 규모엔 충분)."""
    conn = psycopg.connect(DATABASE_URL, row_factory=dict_row)
    try:
        yield conn
    finally:
        conn.close()
