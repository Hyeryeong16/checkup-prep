from pydantic import BaseModel, Field
from typing import Literal
from datetime import date


class PrepPlanRequest(BaseModel):
    exam_date: date = Field(..., description="검진일 (YYYY-MM-DD)")
    exam_ids: list[str] = Field(
        ..., min_length=1,
        description="사용자가 선택한 검사 ID 목록 (예: ['colonoscopy', 'pet_ct'])",
        examples=[["colonoscopy", "gastroscopy", "pet_ct"]],
    )
    sex: Literal["male", "female"] = Field(
        ..., description="성별 - 생리/수유 등 여성 전용 항목 노출 여부를 결정"
    )
    pregnant: bool = Field(
        default=False,
        description="임신 중 여부 (sex='male'이면 무시됨) - 임신 관련 항목 노출 여부를 결정",
    )
    breastfeeding: bool = Field(
        default=False, description="현재 수유 중인지 여부"
    )


class TimelineItem(BaseModel):
    conflict_group: str
    earliest_offset: int
    start_date: date
    trigger_exam: str
    exam_ids: list[str]
    title: str
    description: str | None = None
    confirmed_by_sources: list[str]
    raw_item_count: int


class ConsultItem(BaseModel):
    conflict_group: str
    exam_ids: list[str]
    title: str
    description: str | None = None
    disclaimer_flag: bool
    confirmed_by_sources: list[str]


class AftercareItem(BaseModel):
    conflict_group: str
    exam_ids: list[str]
    title: str
    description: str | None = None
    confirmed_by_sources: list[str]


class ConflictWarning(BaseModel):
    group_a: str
    group_b: str
    warning_template: str
    severity: str


class RuleVariantNote(BaseModel):
    exam_id: str
    context_type: str
    start_day_offset: int | None = None
    end_day_offset: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    description: str | None = None


class PrepPlanResponse(BaseModel):
    exam_date: date
    timeline: list[TimelineItem]
    physician_consult_items: list[ConsultItem]
    aftercare_items: list[AftercareItem] = Field(default_factory=list)
    conflict_warnings: list[ConflictWarning]
    rule_variant_notes: list[RuleVariantNote] = []
