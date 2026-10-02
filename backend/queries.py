"""
DBeaver에서 검증한 SQL들을 함수로 감싼 모듈.
- get_exams: 검사 목록
- get_medications_for_exam: 검사별 관련 약물
- get_merged_timeline: conflict_group(+canonical) 기준 D-day 병합 타임라인
- get_physician_consult_items: start_day_offset이 NULL인 '주치의 상담' 항목
- get_conflict_warnings: 반대 방향 충돌 경고
"""
from db import get_connection


def get_exams(in_scope_only: bool = True):
    query = "SELECT exam_id, exam_name, category FROM exams"
    if in_scope_only:
        query += " WHERE in_scope = TRUE"
    query += " ORDER BY exam_name"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query)
            return cur.fetchall()


def get_medications_for_exam(exam_id: str):
    query = """
        SELECT m.drug_id, m.drug_name, m.drug_class,
               m.stop_rule_type, m.stop_day_offset,
               m.requires_consult, m.requires_day_of_test, m.note
        FROM exam_medication_relevance r
        JOIN medications m ON m.drug_id = r.drug_id
        WHERE r.exam_id = %s
        ORDER BY m.drug_name
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (exam_id,))
            return cur.fetchall()


def _sex_filter_clause(allowed_tags: list[str]) -> str:
    """
    성별/임신 여부에 따라 노출해도 되는 항목만 남기는 조건절.
    sex_specific이 NULL(전체 공통)인 항목은 항상 포함하고,
    'female'/'pregnancy' 태그가 붙은 항목은 allowed_tags에 있을 때만 포함한다.
    """
    return "AND (p.sex_specific IS NULL OR p.sex_specific = ANY(%(allowed_tags)s))"


def _allowed_tags(sex: str, pregnant: bool, breastfeeding: bool) -> list[str]:
    if sex == "male":
        return []
    tags = ["female"]
    if pregnant:
        tags.append("pregnancy")
    if breastfeeding:
        tags.extend(["breastfeeding", "lactation"])
    return tags


def get_merged_timeline(exam_ids: list[str], sex: str, pregnant: bool, breastfeeding: bool = False):
    """
    선택된 검사들의 준비사항을 conflict_group(canonical 매핑 적용)별로 병합해
    D-day 오름차순으로 반환한다. 성별/임신 여부에 안 맞는 항목(예: 남성에게
    생리 관련 안내)은 제외한다.
    """
    allowed = _allowed_tags(sex, pregnant, breastfeeding)
    included_exam_ids = list(dict.fromkeys([*exam_ids, "common"]))
    query = f"""
        WITH grouped AS (
            SELECT
                COALESCE(c.canonical_group, p.conflict_group) AS effective_group,
                p.exam_id, p.start_day_offset, p.title, p.description, p.source
            FROM prep_items p
            LEFT JOIN conflict_group_canonical c ON c.raw_group = p.conflict_group
            WHERE p.exam_id = ANY(%(exam_ids)s)
              AND p.start_day_offset IS NOT NULL
              {_sex_filter_clause(allowed)}
              AND (%(breastfeeding)s OR (
                  COALESCE(p.title, '') NOT LIKE '%%수유%%'
                  AND COALESCE(p.description, '') NOT LIKE '%%수유%%'
              ))
        )
        SELECT
            g.effective_group AS conflict_group,
            MIN(g.start_day_offset) AS earliest_offset,
            (ARRAY_AGG(g.exam_id ORDER BY g.start_day_offset ASC))[1] AS trigger_exam,
            ARRAY_AGG(DISTINCT g.exam_id) AS exam_ids,
            COALESCE(
                d.display_title,
                (ARRAY_AGG(g.title ORDER BY g.start_day_offset ASC))[1]
            ) AS title,
            COALESCE(
                d.display_description,
                (ARRAY_AGG(g.description ORDER BY g.start_day_offset ASC))[1]
            ) AS description,
            ARRAY_AGG(DISTINCT g.source) AS confirmed_by_sources,
            COUNT(*) AS raw_item_count
        FROM grouped g
        LEFT JOIN conflict_group_canonical_display d ON d.canonical_group = g.effective_group
        GROUP BY g.effective_group, d.display_title, d.display_description
        ORDER BY earliest_offset ASC
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"exam_ids": included_exam_ids, "allowed_tags": allowed, "breastfeeding": breastfeeding})
            return cur.fetchall()


def get_physician_consult_items(exam_ids: list[str], sex: str, pregnant: bool, breastfeeding: bool = False):
    """
    day_offset이 없어 타임라인에 못 들어가는 '주치의 상담 필요' 항목들.
    성별/임신 여부에 안 맞는 항목은 제외한다.
    """
    allowed = _allowed_tags(sex, pregnant, breastfeeding)
    included_exam_ids = list(dict.fromkeys([*exam_ids, "common"]))
    query = f"""
        WITH grouped AS (
            SELECT
                COALESCE(c.canonical_group, p.conflict_group) AS effective_group,
                p.exam_id, p.title, p.description, p.disclaimer_flag, p.source
            FROM prep_items p
            LEFT JOIN conflict_group_canonical c ON c.raw_group = p.conflict_group
            WHERE p.exam_id = ANY(%(exam_ids)s)
              AND p.start_day_offset IS NULL
              {_sex_filter_clause(allowed)}
              AND (%(breastfeeding)s OR (
                  COALESCE(p.title, '') NOT LIKE '%%수유%%'
                  AND COALESCE(p.description, '') NOT LIKE '%%수유%%'
              ))
        )
        SELECT
            g.effective_group AS conflict_group,
            ARRAY_AGG(DISTINCT g.exam_id) AS exam_ids,
            COALESCE(
                d.display_title,
                (ARRAY_AGG(g.title))[1]
            ) AS title,
            COALESCE(
                d.display_description,
                (ARRAY_AGG(g.description))[1]
            ) AS description,
            BOOL_OR(g.disclaimer_flag) AS disclaimer_flag,
            ARRAY_AGG(DISTINCT g.source) AS confirmed_by_sources
        FROM grouped g
        LEFT JOIN conflict_group_canonical_display d ON d.canonical_group = g.effective_group
        GROUP BY g.effective_group, d.display_title, d.display_description
        ORDER BY g.effective_group
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, {"exam_ids": included_exam_ids, "allowed_tags": allowed, "breastfeeding": breastfeeding})
            return cur.fetchall()


def get_conflict_warnings(exam_ids: list[str]):
    """선택된 검사 조합에서 방향이 반대라 경고가 필요한 쌍."""
    query = """
        WITH selected_groups AS (
            SELECT DISTINCT conflict_group
            FROM prep_items
            WHERE exam_id = ANY(%s)
              AND conflict_group IS NOT NULL
        )
        SELECT o.group_a, o.group_b, o.warning_template, o.severity
        FROM conflict_group_opposites o
        WHERE o.group_a IN (SELECT conflict_group FROM selected_groups)
          AND o.group_b IN (SELECT conflict_group FROM selected_groups)
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (exam_ids,))
            return cur.fetchall()


def get_rule_variant(exam_id: str, context_type: str):
    """PET-CT처럼 단독/조합 여부에 따라 규칙이 달라지는 검사의 변형 규칙."""
    query = """
        SELECT exam_id, context_type, start_day_offset, end_day_offset, description
        FROM exam_rule_variants
        WHERE exam_id = %s AND context_type = %s
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, (exam_id, context_type))
            return cur.fetchone()
