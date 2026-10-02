from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from datetime import timedelta
import re

import queries
from models import PrepPlanRequest, PrepPlanResponse, RuleVariantNote

app = FastAPI(
    title="건강검진 준비 플랜 API",
    description="선택한 검사 조합에 맞춰 D-day 준비 타임라인, 주치의 상담 항목, 충돌 경고를 계산합니다.",
    version="0.1.0",
)

# 로컬 개발용 - React(Vite) 개발 서버(기본 5173)에서의 호출 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 검사 조합에 따라 규칙 자체가 달라지는 검사들 (지금은 PET-CT만 해당)
RULE_VARIANT_EXAMS = {"pet_ct"}
MEDICATION_FLAG_IDS = {"anticoagulant_medication"}

# 위 검사들 중, 병합 타임라인에 '단독/조합' 둘 중 맞는 것만 남기기 위한
# conflict_group 목록. prep_items에 두 버전이 모두 들어있어서
# 병합 쿼리만으로는 걸러지지 않아 애플리케이션 레이어에서 제외한다.
VARIANT_ONLY_GROUPS = {
    "pet_ct": {
        "standalone": {"petct_fasting_standalone"},
        "combined": {"petct_fasting_combined"},
    }
}


def _fasting_priority(item: dict) -> tuple[int, int]:
    """먼저 시작하는 날을 우선하고 같은 날에는 명시된 시간을 비교한다."""
    title = item["title"]
    hours = [int(value) for value in re.findall(r"(\d+)\s*시간", title)]
    # '전날 저녁부터'는 같은 날의 시간 단위 안내보다 이르게 시작할 수 있다.
    return (-item["earliest_offset"], 24 if "전날 저녁" in title else max(hours, default=0))


def _is_glp1_guidance(item: dict) -> bool:
    title = item["title"].lower()
    # 삭센다는 DB에 기록된 별도 일정으로 표시한다.
    return "삭센다" not in title and any(label in title for label in ("glp-1", "위고비", "마운자로", "오젬픽"))


def _merge_common_reminders(items: list[dict]) -> list[dict]:
    """같은 날짜에 중복된 공통 렌즈·문진표 안내를 내용 손실 없이 묶는다."""
    def topic(item: dict) -> str | None:
        title = item["title"]
        if "렌즈" in title:
            return "렌즈 착용 안내"
        if "문진표" in title:
            return "문진표 안내"
        return None

    groups = {}
    for item in items:
        label = topic(item)
        if label:
            groups.setdefault((label, item["earliest_offset"]), []).append(item)

    merged = []
    seen = set()
    for item in items:
        label = topic(item)
        key = (label, item["earliest_offset"])
        group = groups.get(key, [])
        if label and len(group) > 1 and any("common" in entry["exam_ids"] for entry in group):
            if key in seen:
                continue
            seen.add(key)
            details = list(dict.fromkeys(
                f'{entry["title"]}: {entry["description"]}' if entry.get("description") else entry["title"]
                for entry in group
            ))
            merged.append({
                **item,
                "title": label,
                "description": " / ".join(details),
                "exam_ids": list(dict.fromkeys(exam_id for entry in group for exam_id in entry["exam_ids"])),
                "confirmed_by_sources": list(dict.fromkeys(source for entry in group for source in entry["confirmed_by_sources"])),
                "raw_item_count": sum(entry.get("raw_item_count", 1) for entry in group),
            })
        else:
            merged.append(item)
    return merged


def _is_insulin_guidance(item: dict) -> bool:
    return "인슐린" in item["title"]


def _merge_evening_meal_guidance(items: list[dict]) -> list[dict]:
    """같은 날의 일반 저녁 식사 안내를 통합하고 원문의 시간·수분 조건을 보존한다."""
    groups = {}
    for item in items:
        title = item["title"]
        if "전날 저녁" in title and ("식사" in title or "금식" in title) and not any(
            label in title for label in ("유동식", "저잔사", "대장", "위절제", "식욕억제제")
        ):
            groups.setdefault(item["earliest_offset"], []).append(item)
    replacements = {}
    removed = set()
    for group in groups.values():
        if len(group) < 2:
            continue
        # 금식이 포함된 항목을 우선하고, 구체적인 원문을 대표 제목으로 사용한다.
        selected = max(group, key=lambda item: ("금식" in item["title"], len(item["title"])))
        details = list(dict.fromkeys(
            f'{item["title"]}: {item["description"]}' if item.get("description") else item["title"]
            for item in group
        ))
        replacements[id(group[0])] = {
            **selected,
            "title": ("전날 저녁 가벼운 식사 이후 금식"
                      if any("가벼운 식사" in item["title"] for item in group)
                      and any("금식" in item["title"] for item in group)
                      else selected["title"]),
            "description": " / ".join(details),
            "exam_ids": list(dict.fromkeys(exam_id for item in group for exam_id in item["exam_ids"])),
            "confirmed_by_sources": list(dict.fromkeys(source for item in group for source in item["confirmed_by_sources"])),
            "raw_item_count": sum(item.get("raw_item_count", 1) for item in group),
        }
        removed.update(id(item) for item in group[1:])
    return [replacements.get(id(item), item) for item in items if id(item) not in removed]


def _is_aftercare(item: dict) -> bool:
    title = item["title"]
    return any(label in title for label in ("검사 후", "검진 후", "촬영 후", "CT 후", "PET-CT 후"))


def _aftercare_item(item: dict) -> dict:
    return {
        "conflict_group": item["conflict_group"],
        "exam_ids": item["exam_ids"],
        "title": item["title"],
        "description": item.get("description"),
        "confirmed_by_sources": item["confirmed_by_sources"],
    }


def _organize_preparation(timeline: list[dict]) -> tuple[list[dict], list[dict], list[dict]]:
    """검사 전·후 안내를 분리하고 금식과 사전 연락 안내를 정리한다."""
    preparation = []
    contact = []
    aftercare = []
    fasting = []
    glp1 = [item for item in timeline if _is_glp1_guidance(item) and not _is_aftercare(item)]
    glp1_reference = min(glp1, key=lambda item: item["earliest_offset"]) if glp1 else None
    for item in timeline:
        title = item["title"]
        if _is_aftercare(item):
            aftercare.append(_aftercare_item(item))
        elif _is_insulin_guidance(item):
            contact.append(item)
        elif _is_glp1_guidance(item):
            if item is glp1_reference:
                preparation.append({
                    **item,
                    "title": ("GLP-1 계열 복용 중 — 검사 2주 전 중단 여부 확인"
                              if item["earliest_offset"] <= -14 else "GLP-1 계열 복용 중 — 검사 전 중단 여부 확인"),
                    "description": "위고비·마운자로·오젬픽 등 복용 사실을 검사 기관과 처방의에게 알리고 중단 시점을 확인하세요. 임의로 약을 중단하지 마세요.",
                    "exam_ids": list(dict.fromkeys(exam_id for guidance in glp1 for exam_id in guidance["exam_ids"])),
                })
        elif ("항혈전제" in title or "항응고제" in title) and "주치의 상담" in title:
            contact.append({
                "conflict_group": item["conflict_group"],
                "exam_ids": item["exam_ids"],
                "title": title,
                "description": item["description"],
                "disclaimer_flag": False,
                "confirmed_by_sources": item["confirmed_by_sources"],
            })
        elif any(label in title for label in ("검사 취소", "검진 취소", "예약 변경", "검사 변경")):
            contact.append({
                "conflict_group": item["conflict_group"],
                "exam_ids": item["exam_ids"],
                "title": "검사 취소·변경 시 검사 기관에 미리 연락하세요",
                "description": item["description"],
                "disclaimer_flag": False,
                "confirmed_by_sources": item["confirmed_by_sources"],
            })
        elif "촬영 중 부동자세" in title or "소요시간" in title:
            continue
        elif "금식" in title and "금식 불필요" not in title:
            fasting.append(item)
        elif "금식 불필요" not in title:
            preparation.append(item)

    if fasting:
        selected = max(fasting, key=_fasting_priority)
        preparation.append({
            **selected,
            "exam_ids": list(dict.fromkeys(exam_id for item in fasting for exam_id in item["exam_ids"])),
            "confirmed_by_sources": list(dict.fromkeys(source for item in fasting for source in item["confirmed_by_sources"])),
            "raw_item_count": sum(item["raw_item_count"] for item in fasting),
        })
    preparation = _merge_common_reminders(preparation)
    preparation = _merge_evening_meal_guidance(preparation)
    preparation.sort(key=lambda item: item["earliest_offset"])
    return preparation, contact, aftercare


def _merge_anticoagulant_consults(items: list[dict]) -> list[dict]:
    """같은 복용 약물에 대한 사전 상담 안내를 하나로 모은다."""
    matching = [item for item in items if "항혈전제" in item["title"] or "항응고제" in item["title"]]
    if len(matching) < 2:
        return items
    first = matching[0]
    details = list(dict.fromkeys(
        text for item in matching
        for text in [item["title"], item["description"]]
        if text
    ))
    merged = {
        **first,
        "title": "항혈전제·항응고제 복용 중 — 검진 전 주치의 상담 필요",
        "description": "\n".join(details),
        "exam_ids": list(dict.fromkeys(exam_id for item in matching for exam_id in item["exam_ids"])),
        "confirmed_by_sources": list(dict.fromkeys(source for item in matching for source in item["confirmed_by_sources"])),
        "disclaimer_flag": any(item["disclaimer_flag"] for item in matching),
    }
    return [item for item in items if item not in matching] + [merged]


def _merge_insulin_consults(items: list[dict]) -> list[dict]:
    """서로 다른 인슐린 중단 지시를 하나의 사전 확인 안내로 교체한다."""
    matching = [item for item in items if _is_insulin_guidance(item)]
    if not matching:
        return items
    first = matching[0]
    merged = {
        "conflict_group": first["conflict_group"],
        "exam_ids": list(dict.fromkeys(exam_id for item in matching for exam_id in item["exam_ids"])),
        "title": "인슐린 주사·펌프 사용 중 — 검사 전 투여 계획 확인",
        "description": "검사 전날과 당일의 인슐린 투여 시간·용량, 펌프 사용, 혈당 측정 계획을 검사 기관과 처방의에게 확인하세요. 임의로 중단하지 마세요.",
        "disclaimer_flag": any(item.get("disclaimer_flag", False) for item in matching),
        "confirmed_by_sources": list(dict.fromkeys(source for item in matching for source in item["confirmed_by_sources"])),
    }
    return [item for item in items if item not in matching] + [merged]


def _merge_cancellation_consults(items: list[dict]) -> list[dict]:
    """검사 취소·변경 연락 안내를 한 건으로 모으고 검사 태그를 합친다."""
    matching = [item for item in items if item["title"] == "검사 취소·변경 시 검사 기관에 미리 연락하세요"]
    if len(matching) < 2:
        return items
    first = matching[0]
    descriptions = list(dict.fromkeys(item["description"] for item in matching if item.get("description")))
    merged = {
        **first,
        "exam_ids": list(dict.fromkeys(exam_id for item in matching for exam_id in item["exam_ids"])),
        "description": " / ".join(descriptions),
        "confirmed_by_sources": list(dict.fromkeys(source for item in matching for source in item["confirmed_by_sources"])),
        "disclaimer_flag": any(item.get("disclaimer_flag", False) for item in matching),
    }
    return [item for item in items if item["title"] != first["title"]] + [merged]


def _merge_pregnancy_consults(items: list[dict], pregnant: bool, breastfeeding: bool) -> list[dict]:
    """선택된 검사에 대한 임신·수유 사전 확인 안내를 정리한다."""
    matching = [item for item in items if "임신" in item["title"] or "가임기 여성" in item["title"]]
    others = [item for item in items if item not in matching]
    lactation = [item for item in matching if "수유" in item["title"]]
    if breastfeeding and lactation:
        item = lactation[0]
        others.append({
            **item,
            "conflict_group": f"{item['conflict_group']}_lactation_notice",
            "title": "수유 중이라면 검사 기관에 미리 알리세요",
            "description": "수유 중임을 알리고 검사에 필요한 안내를 확인하세요.",
        })
    if not pregnant or not matching:
        return others
    first = matching[0]
    return others + [{
        "conflict_group": first["conflict_group"],
        "exam_ids": list(dict.fromkeys(exam_id for item in matching for exam_id in item["exam_ids"])),
        "title": "임신 중이거나 가능성이 있다면 검사 기관에 미리 알리세요",
        "description": "선택한 검사의 진행 가능 여부를 검사 기관 및 담당의와 사전에 상담하세요.",
        "disclaimer_flag": any(item.get("disclaimer_flag", False) for item in matching),
        "confirmed_by_sources": list(dict.fromkeys(source for item in matching for source in item["confirmed_by_sources"])),
    }]


@app.get("/exams")
def list_exams():
    """
    선택 가능한 '검사' 목록만 반환.
    - 'common'은 사용자가 직접 고르는 항목이 아니라 내부 공통 규칙용이라 제외
    - category='약물'(예: anticoagulant_medication)은 검사가 아니라
      '복용 중인 약물이 있는지'를 나타내는 사용자 특성 플래그라 별도 취급
      → 프론트엔드에서 /medication-flags로 따로 조회
    """
    exams = queries.get_exams(in_scope_only=True)
    return [e for e in exams if e["exam_id"] != "common" and e["category"] != "약물"]


@app.get("/medication-flags")
def list_medication_flags():
    """
    검사는 아니지만 병합 로직상 exam_id로 취급되는 약물 복용 플래그 목록.
    (지금은 anticoagulant_medication 하나) 사용자가 '해당됨'을 체크하면
    이 exam_id를 /prep-plan 요청의 exam_ids에 함께 포함시키면 된다.
    """
    exams = queries.get_exams(in_scope_only=True)
    return [e for e in exams if e["category"] == "약물"]


@app.get("/exams/{exam_id}/medications")
def list_medications_for_exam(exam_id: str):
    """특정 검사를 선택했을 때 물어봐야 할 관련 약물 목록."""
    meds = queries.get_medications_for_exam(exam_id)
    if not meds:
        # 관련 약물이 없는 것과 exam_id 자체가 잘못된 것을 구분하고 싶다면
        # 여기서 exams 테이블 존재 여부를 먼저 확인하는 로직을 추가할 수 있음
        return []
    return meds


@app.post("/prep-plan", response_model=PrepPlanResponse)
def build_prep_plan(request: PrepPlanRequest):
    """
    핵심 엔드포인트: 선택된 검사 조합에 대해
    1) D-day 병합 타임라인
    2) 주치의 상담이 필요한 항목
    3) 반대 방향 충돌 경고
    4) 단독/조합 여부에 따라 달라지는 규칙(PET-CT 등) 안내
    를 한 번에 계산해서 반환한다.
    """
    exam_ids = request.exam_ids
    is_standalone = len(set(exam_ids) - MEDICATION_FLAG_IDS) == 1

    timeline = queries.get_merged_timeline(exam_ids, request.sex, request.pregnant, request.breastfeeding)
    consult_items = queries.get_physician_consult_items(
        exam_ids, request.sex, request.pregnant, request.breastfeeding
    )
    warnings = queries.get_conflict_warnings(exam_ids)

    # 단독/조합 중 지금 상황과 맞지 않는 쪽의 항목을 타임라인에서 제외
    excluded_groups: set[str] = set()
    for exam_id in exam_ids:
        variants = VARIANT_ONLY_GROUPS.get(exam_id)
        if variants:
            excluded_groups |= (
                variants["combined"] if is_standalone else variants["standalone"]
            )
    timeline = [t for t in timeline if t["conflict_group"] not in excluded_groups]
    timeline, contact_items, aftercare_items = _organize_preparation(timeline)
    aftercare_items.extend(_aftercare_item(item) for item in consult_items if _is_aftercare(item))
    aftercare_items = list({item["conflict_group"]: item for item in aftercare_items}.values())
    consult_items = [item for item in consult_items if not _is_aftercare(item)]
    consult_items.extend(contact_items)
    consult_items = _merge_anticoagulant_consults(consult_items)
    consult_items = _merge_insulin_consults(consult_items)
    consult_items = _merge_cancellation_consults(consult_items)
    consult_items = [
        item for item in consult_items
        if not ("사전 예약 필수" in item["title"] and "수면 내시경" in item["title"])
        and "식욕억제제" not in item["title"]
    ]
    consult_items = _merge_pregnancy_consults(consult_items, request.pregnant, request.breastfeeding)
    for item in timeline:
        item["start_date"] = request.exam_date + timedelta(days=item["earliest_offset"])

    # 단독/조합에 따라 규칙이 갈리는 검사 처리 (별도 안내 배너)
    rule_variant_notes: list[RuleVariantNote] = []
    for exam_id in exam_ids:
        if exam_id in RULE_VARIANT_EXAMS:
            context_type = "standalone" if is_standalone else "combined"
            variant = queries.get_rule_variant(exam_id, context_type)
            if variant:
                if "금식" in (variant.get("description") or "") and any("금식" in item["title"] for item in timeline):
                    continue
                if variant["start_day_offset"] is not None:
                    variant["start_date"] = request.exam_date + timedelta(days=variant["start_day_offset"])
                if variant["end_day_offset"] is not None:
                    variant["end_date"] = request.exam_date + timedelta(days=variant["end_day_offset"])
                rule_variant_notes.append(RuleVariantNote(**variant))

    return PrepPlanResponse(
        exam_date=request.exam_date,
        timeline=timeline,
        physician_consult_items=consult_items,
        aftercare_items=aftercare_items,
        conflict_warnings=warnings,
        rule_variant_notes=rule_variant_notes,
    )


@app.get("/health")
def health_check():
    return {"status": "ok"}
