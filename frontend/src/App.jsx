import { useEffect, useMemo, useState } from 'react'
import { fetchExams, fetchMedicationFlags, fetchPrepPlan } from './api'
import './App.css'

const WEEKDAYS = ['일', '월', '화', '수', '목', '금', '토']

// 태그로 표시할 때 이름이 너무 긴 항목은 짧게 바꿔서 보여줌
const TAG_LABEL_OVERRIDES = {
  anticoagulant_medication: '복용 중인 약',
  common: '공통',
}

function formatOffset(offset) {
  if (offset === 0) return 'D-day'
  if (offset < 0) return `D${offset}`
  return `D+${offset}`
}

// 'YYYY-MM-DD' 문자열을 로컬 날짜로 변환 (시간대 어긋남 방지)
function parseInputDate(value) {
  const [y, m, d] = value.split('-').map(Number)
  return new Date(y, m - 1, d)
}

function formatKoreanDate(date) {
  return `${date.getMonth() + 1}월 ${date.getDate()}일 (${WEEKDAYS[date.getDay()]})`
}

function todayInputValue() {
  const t = new Date()
  const mm = String(t.getMonth() + 1).padStart(2, '0')
  const dd = String(t.getDate()).padStart(2, '0')
  return `${t.getFullYear()}-${mm}-${dd}`
}

function isBeforeToday(date) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  return date < today
}

// "제목 (부연)" / "제목 - 부연" 형태를 "제목 — 부연"으로 통일
function prettifyTitle(title) {
  let result = title.replace(/ - /g, ' — ')
  if (!result.includes(' — ')) {
    result = result.replace(/\s*\(([^()]+)\)\s*$/, ' — $1')
  }
  return result
}

function groupByDay(timeline) {
  const map = new Map()
  for (const item of timeline) {
    const key = item.earliest_offset
    if (!map.has(key)) map.set(key, [])
    map.get(key).push(item)
  }
  return [...map.entries()].sort((a, b) => a[0] - b[0])
}

export default function App() {
  const [exams, setExams] = useState([])
  const [medicationFlags, setMedicationFlags] = useState([])
  const [examDate, setExamDate] = useState('')
  const [selected, setSelected] = useState(new Set())
  const [selectedFlags, setSelectedFlags] = useState(new Set())
  const [sex, setSex] = useState('')
  const [pregnant, setPregnant] = useState(false)
  const [breastfeeding, setBreastfeeding] = useState(false)
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    setResult(null)
  }, [examDate, selected, selectedFlags, sex, pregnant, breastfeeding])

  useEffect(() => {
    fetchExams()
      .then(setExams)
      .catch((e) => setError(e.message))
    fetchMedicationFlags()
      .then(setMedicationFlags)
      .catch((e) => setError(e.message))
  }, [])

  // exam_id -> 화면에 보여줄 이름
  const examNameById = useMemo(() => {
    const map = {}
    for (const e of [...exams, ...medicationFlags]) map[e.exam_id] = e.exam_name
    return map
  }, [exams, medicationFlags])

  function tagLabel(examId) {
    return TAG_LABEL_OVERRIDES[examId] ?? examNameById[examId] ?? examId
  }

  // 각 준비사항이 어떤 검사와 관련 있는지 보여주는 작은 태그들
  function renderTags(examIds, tone = 'default') {
    if (!examIds || examIds.length === 0) return null
    return (
      <span className="exam-tags">
        {examIds.map((id) => (
          <span key={id} className={`exam-tag ${tone}`}>
            {tagLabel(id)}
          </span>
        ))}
      </span>
    )
  }

  function toggle(examId) {
    setSelected((prev) => {
      const next = new Set(prev)
      next.has(examId) ? next.delete(examId) : next.add(examId)
      return next
    })
  }

  function toggleFlag(examId) {
    setSelectedFlags((prev) => {
      const next = new Set(prev)
      next.has(examId) ? next.delete(examId) : next.add(examId)
      return next
    })
  }

  const canSubmit = selected.size > 0 && sex && examDate && !loading

  async function handleSubmit() {
    if (!canSubmit) return
    setLoading(true)
    setError(null)
    try {
      const examIds = [...selected, ...selectedFlags]
      const data = await fetchPrepPlan(examIds, sex, sex === 'female' && pregnant, examDate, sex === 'female' && breastfeeding)
      setResult(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="page">
      <header className="header">
        <h1>검진 준비 플랜</h1>
        <p>
          검진일과 받을 검사를 선택하면 날짜별 준비 일정과, 검사 조합에서 미리
          확인해야 할 것들을 정리해 드립니다.
        </p>
      </header>

      <section className="exam-section">
        <h2>검진일을 선택하세요</h2>
        <input
          type="date"
          className="date-input"
          min={todayInputValue()}
          value={examDate}
          onChange={(e) => setExamDate(e.target.value)}
        />
      </section>

      <section className="exam-section">
        <h2>성별을 선택하세요</h2>
        <div className="exam-grid">
          <label className={`exam-card${sex === 'female' ? ' selected' : ''}`}>
            <input
              type="radio"
              name="sex"
              checked={sex === 'female'}
              onChange={() => setSex('female')}
            />
            <span className="label">여성</span>
          </label>
          <label className={`exam-card${sex === 'male' ? ' selected' : ''}`}>
            <input
              type="radio"
              name="sex"
              checked={sex === 'male'}
              onChange={() => {
                setSex('male')
                setPregnant(false)
                setBreastfeeding(false)
              }}
            />
            <span className="label">남성</span>
          </label>
        </div>
        {sex === 'female' && (
          <><label
            className={`exam-card pregnant-toggle${
              pregnant ? ' selected' : ''
            }`}
          >
            <input
              type="checkbox"
              checked={pregnant}
              onChange={() => setPregnant((p) => !p)}
            />
            <span className="label">임신 중이거나 가능성이 있어요</span>
          </label>
          <label className={`exam-card pregnant-toggle${breastfeeding ? ' selected' : ''}`}>
            <input
              type="checkbox"
              checked={breastfeeding}
              onChange={() => setBreastfeeding((value) => !value)}
            />
            <span className="label">현재 수유 중이에요</span>
          </label></>
        )}
      </section>

      <section className="exam-section">
        <h2>받을 검사를 선택하세요</h2>
        <div className="exam-grid">
          {exams.map((exam) => (
            <label
              key={exam.exam_id}
              className={`exam-card${
                selected.has(exam.exam_id) ? ' selected' : ''
              }`}
            >
              <input
                type="checkbox"
                checked={selected.has(exam.exam_id)}
                onChange={() => toggle(exam.exam_id)}
              />
              <span>
                <span className="label">{exam.exam_name}</span>
                <span className="category">{exam.category}</span>
              </span>
            </label>
          ))}
        </div>
      </section>

      {medicationFlags.length > 0 && (
        <section className="exam-section">
          <h2>해당하는 사항이 있나요?</h2>
          <div className="exam-grid">
            {medicationFlags.map((flag) => (
              <label
                key={flag.exam_id}
                className={`exam-card${
                  selectedFlags.has(flag.exam_id) ? ' selected' : ''
                }`}
              >
                <input
                  type="checkbox"
                  checked={selectedFlags.has(flag.exam_id)}
                  onChange={() => toggleFlag(flag.exam_id)}
                />
                <span>
                  <span className="label">{flag.exam_name}</span>
                </span>
              </label>
            ))}
          </div>
        </section>
      )}

      <button
        className="submit-btn"
        onClick={handleSubmit}
        disabled={!canSubmit}
      >
        {loading ? '계산 중...' : '준비 플랜 만들기'}
      </button>

      {error && <p className="error-text">{error}</p>}

      {result && (
        <div className="results">
          {result.conflict_warnings.map((w, i) => (
            <div key={i} className="warning-banner">
              {w.warning_template}
            </div>
          ))}

          {result.rule_variant_notes.map((n, i) => (
            <div key={i} className="warning-banner">
              {n.context_type === 'combined'
                ? '다른 검사와 함께 받는 경우: '
                : '단독으로 받는 경우: '}
              {n.description}
            </div>
          ))}

          {result.physician_consult_items.length > 0 && (
            <section className="notice-box">
              <h2>⚠️ 검진 전 확인이 필요해요</h2>
              <ul className="notice-list">
                {result.physician_consult_items.map((item) => (
                  <li key={item.conflict_group}>
                    <details>
                      <summary>
                        <span className="item-title">
                          {prettifyTitle(item.title)}
                        </span>
                        {renderTags(item.exam_ids, 'warn')}
                      </summary>
                      {item.description && (
                        <p className="desc" style={{ whiteSpace: 'pre-line' }}>{item.description}</p>
                      )}
                    </details>
                  </li>
                ))}
              </ul>
              <p className="notice-hint">
                항목을 누르면 자세한 내용을 볼 수 있어요.
              </p>
            </section>
          )}

          <h2>날짜별 준비 타임라인</h2>
          <div className="timeline">
            {groupByDay(result.timeline).map(([offset, items]) => {
              const date = items[0]?.start_date ? parseInputDate(items[0].start_date) : null
              return (
                <div key={offset} className="day-group">
                  <h3 className="day-heading">
                    <span className="day-label">{formatOffset(offset)}</span>
                    {date && (
                      <span className="day-date">{formatKoreanDate(date)}</span>
                    )}
                    {date && isBeforeToday(date) && (
                      <span className="past-note">이미 지난 날</span>
                    )}
                  </h3>
                  <ul className="day-items">
                    {items.map((item) => (
                      <li key={item.conflict_group}>
                        <details>
                          <summary>
                            <span className="item-title">
                              {prettifyTitle(item.title)}
                            </span>
                            {renderTags(item.exam_ids)}
                          </summary>
                          {item.description && (
                            <p className="desc">{item.description}</p>
                          )}
                        </details>
                      </li>
                    ))}
                  </ul>
                </div>
              )
            })}
          </div>

          {result.aftercare_items?.length > 0 && (
            <section className="notice-box aftercare-box">
              <h2>검사 후 안내</h2>
              <p className="notice-hint">검사 후 약 복용·수유 관련 안내는 검사 기관에 최종 확인하세요.</p>
              <ul className="notice-list">
                {result.aftercare_items.map((item) => (
                  <li key={item.conflict_group}>
                    <details>
                      <summary>
                        <span className="item-title">{prettifyTitle(item.title)}</span>
                        {renderTags(item.exam_ids, 'warn')}
                      </summary>
                      {item.description && <p className="desc">{item.description}</p>}
                    </details>
                  </li>
                ))}
              </ul>
            </section>
          )}
          <p className="disclaimer">이 플랜은 참고용입니다. 최종 준비사항은 예약하신 병원의 안내를 따르세요.</p>
        </div>
      )}
    </div>
  )
}
