const BASE_URL = 'http://localhost:8000'

export async function fetchExams() {
  const res = await fetch(`${BASE_URL}/exams`)
  if (!res.ok) throw new Error('검사 목록을 불러오지 못했습니다.')
  return res.json()
}

export async function fetchMedicationFlags() {
  const res = await fetch(`${BASE_URL}/medication-flags`)
  if (!res.ok) throw new Error('약물 관련 항목을 불러오지 못했습니다.')
  return res.json()
}

export async function fetchPrepPlan(examIds, sex, pregnant, examDate, breastfeeding) {
  const res = await fetch(`${BASE_URL}/prep-plan`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      exam_ids: examIds,
      sex,
      pregnant,
      exam_date: examDate,
      breastfeeding,
    }),
  })
  if (!res.ok) throw new Error('준비 플랜을 계산하지 못했습니다.')
  return res.json()
}