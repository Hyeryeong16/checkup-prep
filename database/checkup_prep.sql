--
-- PostgreSQL database dump
--

\restrict RdPl3cC8OWpn0iNsVGLMZEmJwiqg07gPFo5EIqhoLDaoK6TPp5ggYafovSjffpn

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-09-30 14:18:07 KST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 867 (class 1247 OID 16406)
-- Name: rule_context_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.rule_context_type AS ENUM (
    'standalone',
    'combined'
);


ALTER TYPE public.rule_context_type OWNER TO postgres;

--
-- TOC entry 861 (class 1247 OID 16390)
-- Name: severity_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.severity_level AS ENUM (
    'high',
    'medium',
    'low'
);


ALTER TYPE public.severity_level OWNER TO postgres;

--
-- TOC entry 864 (class 1247 OID 16398)
-- Name: stop_rule_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.stop_rule_type AS ENUM (
    'fixed_offset',
    'physician_judgment',
    'physician_judgment_plus_test'
);


ALTER TYPE public.stop_rule_type OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 227 (class 1259 OID 16521)
-- Name: conflict_group_canonical; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conflict_group_canonical (
    raw_group character varying(50) NOT NULL,
    canonical_group character varying(50) NOT NULL
);


ALTER TABLE public.conflict_group_canonical OWNER TO postgres;

--
-- TOC entry 3906 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE conflict_group_canonical; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.conflict_group_canonical IS '표시 레이어 전용 매핑. prep_items.conflict_group 원본은 그대로 두고, 화면에 보여줄 때만 이 테이블로 합침';


--
-- TOC entry 228 (class 1259 OID 16528)
-- Name: conflict_group_canonical_display; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conflict_group_canonical_display (
    canonical_group character varying(50) NOT NULL,
    display_title text NOT NULL,
    display_description text
);


ALTER TABLE public.conflict_group_canonical_display OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16509)
-- Name: conflict_group_opposites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conflict_group_opposites (
    group_a character varying(50) NOT NULL,
    group_b character varying(50) NOT NULL,
    warning_template text NOT NULL,
    severity public.severity_level DEFAULT 'high'::public.severity_level NOT NULL
);


ALTER TABLE public.conflict_group_opposites OWNER TO postgres;

--
-- TOC entry 3907 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE conflict_group_opposites; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.conflict_group_opposites IS '병합 로직(GROUP BY conflict_group)으로는 감지되지 않는, 서로 반대 방향인 준비사항 쌍';


--
-- TOC entry 223 (class 1259 OID 16459)
-- Name: exam_medication_relevance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_medication_relevance (
    exam_id character varying(50) NOT NULL,
    drug_id character varying(50) NOT NULL
);


ALTER TABLE public.exam_medication_relevance OWNER TO postgres;

--
-- TOC entry 3908 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE exam_medication_relevance; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.exam_medication_relevance IS '어느 검사에서 어느 약물 규칙이 적용되는지 매핑';


--
-- TOC entry 225 (class 1259 OID 16477)
-- Name: exam_rule_variants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exam_rule_variants (
    variant_id integer NOT NULL,
    exam_id character varying(50) NOT NULL,
    context_type public.rule_context_type NOT NULL,
    start_day_offset integer,
    end_day_offset integer,
    description text,
    source character varying(150)
);


ALTER TABLE public.exam_rule_variants OWNER TO postgres;

--
-- TOC entry 3909 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE exam_rule_variants; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.exam_rule_variants IS '같은 검사라도 다른 검사와 조합 여부에 따라 규칙 자체가 달라지는 경우 (예: PET-CT)';


--
-- TOC entry 224 (class 1259 OID 16476)
-- Name: exam_rule_variants_variant_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.exam_rule_variants_variant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.exam_rule_variants_variant_id_seq OWNER TO postgres;

--
-- TOC entry 3910 (class 0 OID 0)
-- Dependencies: 224
-- Name: exam_rule_variants_variant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.exam_rule_variants_variant_id_seq OWNED BY public.exam_rule_variants.variant_id;


--
-- TOC entry 219 (class 1259 OID 16411)
-- Name: exams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exams (
    exam_id character varying(50) NOT NULL,
    exam_name character varying(100) NOT NULL,
    category character varying(50),
    in_scope boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.exams OWNER TO postgres;

--
-- TOC entry 3911 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE exams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.exams IS '사용자가 선택 가능한 검사 목록';


--
-- TOC entry 222 (class 1259 OID 16445)
-- Name: medications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medications (
    drug_id character varying(50) NOT NULL,
    drug_name character varying(100) NOT NULL,
    drug_class character varying(50) NOT NULL,
    aliases text[],
    stop_rule_type public.stop_rule_type NOT NULL,
    stop_day_offset integer,
    requires_consult boolean DEFAULT false,
    requires_day_of_test boolean DEFAULT false,
    note text,
    source character varying(150),
    CONSTRAINT chk_stop_offset_consistency CHECK ((((stop_rule_type = 'fixed_offset'::public.stop_rule_type) AND (stop_day_offset IS NOT NULL)) OR ((stop_rule_type <> 'fixed_offset'::public.stop_rule_type) AND (stop_day_offset IS NULL))))
);


ALTER TABLE public.medications OWNER TO postgres;

--
-- TOC entry 3912 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE medications; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.medications IS '약물 마스터 - 항응고제/GLP-1처럼 약물명 단위로 규칙이 갈리는 항목 처리';


--
-- TOC entry 221 (class 1259 OID 16421)
-- Name: prep_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prep_items (
    prep_id integer NOT NULL,
    exam_id character varying(50) NOT NULL,
    category character varying(50) NOT NULL,
    start_day_offset integer,
    end_day_offset integer,
    severity public.severity_level DEFAULT 'medium'::public.severity_level NOT NULL,
    conflict_group character varying(50),
    title text NOT NULL,
    description text,
    applies_to text,
    disclaimer_flag boolean DEFAULT false,
    source character varying(150),
    last_verified_date date,
    extra_notes jsonb,
    created_at timestamp with time zone DEFAULT now(),
    sex_specific character varying(20),
    CONSTRAINT chk_offset_order CHECK (((end_day_offset IS NULL) OR (start_day_offset IS NULL) OR (end_day_offset >= start_day_offset)))
);


ALTER TABLE public.prep_items OWNER TO postgres;

--
-- TOC entry 3913 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE prep_items; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.prep_items IS '검사별 준비사항 - 병합/충돌 로직의 핵심 데이터';


--
-- TOC entry 3914 (class 0 OID 0)
-- Dependencies: 221
-- Name: COLUMN prep_items.conflict_group; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.prep_items.conflict_group IS '같은 그룹끼리 묶어 MIN(start_day_offset)으로 트리거 검사를 계산';


--
-- TOC entry 220 (class 1259 OID 16420)
-- Name: prep_items_prep_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prep_items_prep_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.prep_items_prep_id_seq OWNER TO postgres;

--
-- TOC entry 3915 (class 0 OID 0)
-- Dependencies: 220
-- Name: prep_items_prep_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prep_items_prep_id_seq OWNED BY public.prep_items.prep_id;


--
-- TOC entry 3716 (class 2604 OID 16480)
-- Name: exam_rule_variants variant_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_rule_variants ALTER COLUMN variant_id SET DEFAULT nextval('public.exam_rule_variants_variant_id_seq'::regclass);


--
-- TOC entry 3710 (class 2604 OID 16424)
-- Name: prep_items prep_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prep_items ALTER COLUMN prep_id SET DEFAULT nextval('public.prep_items_prep_id_seq'::regclass);


--
-- TOC entry 3899 (class 0 OID 16521)
-- Dependencies: 227
-- Data for Name: conflict_group_canonical; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conflict_group_canonical (raw_group, canonical_group) FROM stdin;
anticoagulant_stop	anticoagulant_general_consult
antiplatelet_stop	anticoagulant_general_consult
anticoagulant_antiplatelet_combined	anticoagulant_general_consult
anticoagulant_stop_strict	anticoagulant_general_consult
anticoagulant_antiplatelet_endoscopy	anticoagulant_general_consult
petct_diabetes	petct_diabetes_varies
petct_insulin	petct_diabetes_varies
menstrual_cycle	menstrual_cycle_varies
menstrual_cycle_urine	menstrual_cycle_varies
menstrual_cycle_specific	menstrual_cycle_varies
menstrual_cycle_window	menstrual_cycle_varies
\.


--
-- TOC entry 3900 (class 0 OID 16528)
-- Dependencies: 228
-- Data for Name: conflict_group_canonical_display; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conflict_group_canonical_display (canonical_group, display_title, display_description) FROM stdin;
anticoagulant_general_consult	항혈전제/항응고제 - 복용 중이면 D-7 전후로 주치의 상담 필요	아스피린, 플라빅스, 와파린 등 항혈전제·항응고제를 복용 중이라면 조직검사·용종제거 시 출혈 위험이 있습니다. 처방 주치의와 중단 여부를 상의하세요. 정확한 중단 시점은 약물 종류와 병력에 따라 다르므로(경도 항혈소판제는 당일만, 와파린은 당일 혈액검사로 결정 등) 반드시 개별 상담이 필요합니다.
petct_diabetes_varies	당뇨약/인슐린 - PET-CT는 병원마다 지침이 다름 (반드시 확인 필요)	PET-CT 검사 시 당뇨약·인슐린을 중단할지 지참할지는 병원마다 다르게 안내합니다(일부는 중단, 일부는 지참 후 개별 조절). 혈당 조절이 안 되면 검사가 연기될 수 있으니, 예약하신 병원에 직접 확인하거나 담당의와 상의하세요.
breastfeeding_restriction	수유 중이라면 유방촬영/유방초음파는 미루는 것이 좋습니다	모유 수유 중에는 유방 조직 변화로 검사 정확도가 떨어질 수 있어, 수유 중단 후 최소 6개월 뒤 검사를 권장합니다. 불편한 증상이 있다면 미루지 말고 진료를 받으세요.
menstrual_cycle_varies	생리 중이거나 생리 후 며칠 이내라면 - 병원마다 검사 가능 여부가 다름	생리 중이거나 생리 직후에 유방촬영·부인과·소변검사를 받을 수 있는지는 병원마다 기준이 다릅니다. 예약하신 병원에 검진 가능 시기를 직접 확인하세요.
\.


--
-- TOC entry 3898 (class 0 OID 16509)
-- Dependencies: 226
-- Data for Name: conflict_group_opposites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conflict_group_opposites (group_a, group_b, warning_template, severity) FROM stdin;
bladder_fill	petct_urination	⚠️ 방광/골반초음파는 검사 전 소변을 참아야 하지만, PET-CT는 촬영 직전 소변을 봐야 합니다. 두 검사를 같은 날 받는다면 반드시 순서를 확인하세요(보통 방광초음파를 먼저 진행).	high
bladder_fill	bone_scan_urination	⚠️ 방광/골반초음파는 검사 전 소변을 참아야 하지만, 골 스캔은 촬영 전 소변을 봐야 합니다. 두 검사를 같은 날 받는다면 순서를 확인하세요.	medium
\.


--
-- TOC entry 3895 (class 0 OID 16459)
-- Dependencies: 223
-- Data for Name: exam_medication_relevance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_medication_relevance (exam_id, drug_id) FROM stdin;
colonoscopy	aspirin
gastroscopy	aspirin
colonoscopy	clopidogrel
gastroscopy	clopidogrel
colonoscopy	warfarin
gastroscopy	warfarin
gastroscopy	wegovy
colonoscopy	wegovy
gastroscopy	saxenda
pet_ct	metformin
\.


--
-- TOC entry 3897 (class 0 OID 16477)
-- Dependencies: 225
-- Data for Name: exam_rule_variants; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exam_rule_variants (variant_id, exam_id, context_type, start_day_offset, end_day_offset, description, source) FROM stdin;
1	pet_ct	standalone	0	0	검사 전 6~8시간 금식 (병원별 6~8시간 범위, 보수적 기준 적용 시 8시간)	분당차병원/중앙대병원 등
2	pet_ct	combined	-1	0	전날 저녁부터 검사 시까지 금식 (종합검진과 함께 실시 시)	서울성모병원
\.


--
-- TOC entry 3891 (class 0 OID 16411)
-- Dependencies: 219
-- Data for Name: exams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exams (exam_id, exam_name, category, in_scope, created_at) FROM stdin;
colonoscopy	대장내시경	내시경	t	2026-09-18 17:38:06.974228+09
gastroscopy	위내시경	내시경	t	2026-09-18 17:38:06.974228+09
abdominal_us	복부초음파	초음파	t	2026-09-18 17:38:06.974228+09
bladder_pelvic_us	방광/골반초음파	초음파	t	2026-09-18 17:38:06.974228+09
blood_test	혈액검사	혈액	t	2026-09-18 17:38:06.974228+09
pet_ct	PET-CT/특수 CT	영상	t	2026-09-18 17:38:06.974228+09
mammography	유방촬영/유방초음파	영상	t	2026-09-18 17:38:06.974228+09
anticoagulant_medication	항응고제/당뇨약 복용자 항목	약물	t	2026-09-18 17:38:06.974228+09
common	전체 검진 공통 항목	공통	t	2026-09-21 09:53:57.139313+09
out_of_scope_lung_sputum	가래(객담)검사	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_myocardial_spect	심근 SPECT	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_bone_scan	골 스캔	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_breast_biopsy	유방 조직검사(총생검)	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_stool_test	분변검사	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_cervical_cytology	자궁경부세포검사	스코프 외	f	2026-09-21 09:53:57.139313+09
out_of_scope_mri	MRI	스코프 외	f	2026-09-21 09:53:57.139313+09
\.


--
-- TOC entry 3894 (class 0 OID 16445)
-- Dependencies: 222
-- Data for Name: medications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medications (drug_id, drug_name, drug_class, aliases, stop_rule_type, stop_day_offset, requires_consult, requires_day_of_test, note, source) FROM stdin;
aspirin	아스피린	mild_antiplatelet	{아스트릭스,프레탈,안플라그}	fixed_offset	0	f	f	검사 당일 오전만 중단, 평소엔 지속	\N
clopidogrel	플라빅스	moderate_antiplatelet	{피도글,트롬빅스,브릴린타,에피언트}	physician_judgment	\N	t	f	중단 여부는 처방 주치의 판단	\N
warfarin	와파린	anticoagulant_strict	{쿠마딘,자렐토,프라닥사,엘리퀴스}	physician_judgment_plus_test	\N	t	t	와파린은 당일 혈액응고검사 수치로 조직검사 가능 여부 최종 결정	\N
wegovy	위고비	glp1_weekly	{마운자로,오젬픽}	fixed_offset	-14	t	f	KMI 기준 D-14(보수적), 일부 병원은 D-7 안내 - 기본값은 보수적 기준 채택	\N
saxenda	삭센다	glp1_daily	\N	fixed_offset	-1	t	f	매일 주사형이라 주 1회형(위고비 등)보다 중단 기간 짧음	\N
metformin	메트포르민	diabetes_biguanide	{다이아벡스,글루코파지,글루파,가브스,자누메트}	fixed_offset	2	f	f	조영제 CT 검사 "후" 48시간 중단 - D+2로 표기(사후관리 항목, UI에서 별도 섹션 처리 필요)	\N
\.


--
-- TOC entry 3893 (class 0 OID 16421)
-- Dependencies: 221
-- Data for Name: prep_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prep_items (prep_id, exam_id, category, start_day_offset, end_day_offset, severity, conflict_group, title, description, applies_to, disclaimer_flag, source, last_verified_date, extra_notes, created_at, sex_specific) FROM stdin;
1	common	식이제한	-3	-1	medium	pre_diet_restriction	기름진 음식/음주 제한	검진 2~3일 전부터 술, 육류, 기름진 음식을 삼갑니다.	전체 검진 공통	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
2	common	식이제한	-1	-1	medium	light_dinner	전날 저녁 가벼운 식사	검진 하루 전 저녁식사는 오후 6시경 가볍게 섭취합니다.	전체 검진 공통	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
3	common	금식	-1	0	high	fasting	자정 이후 절대 금식	담배, 껌, 은단을 포함하여 자정 이후 금식합니다. (쿨프렙 복용은 예외)	전체 검진 공통 (프리미엄 검진은 별도 안내)	f	서울아산병원 건강증진센터	2026-09-15	{"water_exception": "검사 2시간 전까지 생수 한정 300cc까지 허용"}	2026-09-21 14:39:46.088176+09	\N
4	anticoagulant_medication	약물중단	-7	0	high	anticoagulant_stop	아스피린 1차 예방 복용자 중단	심근경색·협심증·심실세동·뇌졸중 병력이 없고 1차 예방 목적으로 아스피린을 복용 중인 경우, 검진 1주일 전부터 복용을 중단합니다.	관련 심뇌혈관 질환 병력 없는 1차 예방 목적 아스피린 복용자	t	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
5	anticoagulant_medication	약물중단	-7	0	high	anticoagulant_stop	항응고제/항혈전제 2차 예방 복용자 - 담당의 상담 필수	심근경색·협심증·뇌졸중 2차 예방 목적의 아스피린/항혈전제, 또는 항응고제(쿠마딘, 와파린)를 복용 중인 경우 검진 1주일 전까지 처방 담당의와 상의해야 합니다.	관련 병력 있는 항응고제/항혈전제 복용자	t	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
6	colonoscopy	식이제한	-3	-1	high	low_residue_diet	저잔사식 시작	씨 있는 과일, 흑미·현미·잡곡밥, 김·미역 등 해조류, 견과류, 섬유질 많은 음식을 삼갑니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
7	colonoscopy	장정결제	-1	0	high	bowel_prep	장정결제 시간 맞춰 복용	별첨 안내문에 따라 정해진 시간에 맞추어 장정결제를 복용합니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
8	colonoscopy	동반자/준비물	0	0	medium	sedation_companion	진정(수면) 내시경 시 보호자 동반 권장	검사 후 회복실에서 30분 휴식하며, 보호자 동반이 권장됩니다. 검사 당일 자가운전 및 기계조작은 삼갑니다.	진정(수면) 내시경 선택자	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
9	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	진정(수면) 내시경 시 보호자 동반 권장	검사 후 회복실에서 30분 휴식하며, 보호자 동반이 권장됩니다. 검사 당일 자가운전 및 기계조작은 삼갑니다.	진정(수면) 내시경 선택자	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
10	blood_test	약물중단	0	0	high	diabetes_med_stop	당뇨약/인슐린 당일 복용 금지	혈당강하제(당뇨약) 복용자는 검진 당일 아침 인슐린 주사나 당뇨약 복용을 금합니다.	\N	t	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
11	common	약물유지(예외)	0	0	medium	maintain_medication	항고혈압제/부정맥치료제/항경련제는 당일 복용 유지	금식 중이어도 해당 약물 복용자는 검진 당일 오전 6시경 최소량의 물로 복용합니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
12	pet_ct	약물중단(사후)	0	2	high	metformin_contrast	메트포르민 복용자 - 조영제 CT 후 재개 시점	메트포르민 계열 복용자가 조영제 CT 촬영을 하는 경우, 검사 후 48시간 경과 뒤 복용을 재개합니다.	\N	t	서울아산병원 건강증진센터	2026-09-15	{"note": "D-day 이전 준비가 아니라 검사 이후 지침 - 검사 후 안내 영역에 배치 필요"}	2026-09-21 14:39:46.088176+09	\N
13	bladder_pelvic_us	소변관리	0	0	high	bladder_fill	검사 전 소변 참기	소변을 미리 보지 말고 검진 시 제공되는 소변컵에 받습니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
16	common	생활습관/준비물	0	0	low	belongings	귀중품 및 어린이 동반 자제	검진 당일 귀중품 휴대나 어린이 동반은 자제합니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
17	common	행정/예약	-7	0	low	reschedule	예약 변경은 7일 전까지	예약 변경 시 재예약이 상당 기간 지연될 수 있어, 변경은 반드시 검진 7일 전까지 요청해야 합니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
18	out_of_scope_lung_sputum	검체채취	-1	0	medium	sputum_collection	[스코프 외] 가래(객담) 검사	아침 기상 직후 심호흡 후 깊은 기침으로 객담을 채취합니다.	\N	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
19	common	생활습관	-3	-1	medium	pre_diet_restriction	음주 및 과로 자제	검진 2~3일 전부터 음주 및 과로를 피합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"discrepancy_vs_amc": "아산은 술/육류/기름진 음식으로 명시, 삼성은 음주/과로로 표현 - 범위 다름"}	2026-09-21 14:39:46.088176+09	\N
20	common	금식	-1	0	high	fasting	전날 저녁 가벼운 식사 후 자정부터 금식	전날 오후 7시 이전 저녁식사 후, 자정 12시부터 10시간 이상 절대 금식(물, 껌, 담배 포함)합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"discrepancy_vs_amc": "아산은 물 300cc 예외 있음, 삼성은 물 포함 전면 금지로 표기"}	2026-09-21 14:39:46.088176+09	\N
21	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	수면 위내시경 예약자 자가운전 금지	의식하 진정(수면) 위내시경 검사 예약 고객은 검사 당일 자가운전을 삼갑니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
22	colonoscopy	사전예약	\N	\N	medium	reservation_required	수면 내시경/대장내시경은 사전 예약 필수	의식하 진정(수면) 내시경과 대장내시경은 사전 예약으로만 진행 가능한 추가 검사입니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"note": "day_offset 없는 행정 조건성 항목 - 예약 시 확인 안내로 별도 노출"}	2026-09-21 14:39:46.088176+09	\N
23	common	약물유지(예외)	0	0	medium	maintain_medication	혈압약은 당일 최소량 물로 복용	혈압약 복용자는 검진 당일 오전 6시경 최소량의 물로 복용합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
15	common	검사 불가 조건	0	0	high	pregnancy_check	임신 중 검진 불가	임신 중에는 건강검진이 불가능합니다. 가임기 여성은 생리주기를 확인해 임신 여부를 사전에 확인해야 합니다.	가임기 여성	t	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
24	blood_test	약물중단	0	0	high	diabetes_med_stop	당뇨약/인슐린 당일 복용 금지	당뇨약 복용자는 검진 당일 아침 인슐린이나 당뇨약 복용을 금합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
25	common	준비물	0	0	low	documents	건강문진표/영양문진표 지참	건강문진표와 영양문진표를 작성하여 검진 당일 지참합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
28	out_of_scope_cervical_cytology	여성검진 조건	-3	0	medium	cervical_cytology_prep	[스코프 외] 자궁 세포진검사 전 금지사항	검사 48~72시간 전부터 부부관계, 질정, 크림 사용을 금합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
29	out_of_scope_stool_test	검체채취	-1	0	medium	stool_collection	[스코프 외] 채변 검체 지참	대장내시경 장정결제 복용 전에 채취해야 합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"note": "장정결제 시작 전 채변 완료 순서 의존성 있음"}	2026-09-21 14:39:46.088176+09	\N
30	common	행정/예약	-3	0	low	reschedule	예약 변경은 3일 전까지	건강검진 일정 변경 시 예정일 3일 전까지 연락해야 합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"discrepancy_vs_amc": "아산은 7일 전까지 - 병원마다 상이"}	2026-09-21 14:39:46.088176+09	\N
31	common	생활습관/준비물	0	0	low	belongings	귀중품 및 어린이 동반 자제	검진 당일 귀중품 휴대나 어린이 동반은 자제합니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
32	colonoscopy	식이제한	-7	-4	medium	low_residue_diet_early	평소 변비 있는 경우 D-7부터 식이섬유 제한	변비가 심한 경우 검사 1주일 전부터 식이섬유 섭취를 제한합니다.	평소 변비가 심한 수검자	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
33	colonoscopy	식이제한	-3	-2	high	low_residue_diet	저잔사식 시작 (D-3)	섬유질 많은 음식, 씨 있는 음식, 해조류/견과류/질긴 고기류를 피합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
34	colonoscopy	식이제한	-1	-1	high	low_residue_diet	전날 유동식 + 오후 2시 이후 물 외 금식	검사 전날 아침·점심은 유동식으로 섭취하고, 오후 2시 이후부터는 물 이외 금식합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
35	out_of_scope_stool_test	검체채취	-3	-1	medium	stool_collection	[스코프 외] 대변채취 시기	장정결제 복용 1~3일 전에 채취합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
36	anticoagulant_medication	약물유지	0	0	low	antiplatelet_mild	경도 출혈성 항혈소판제 - 검진 당일 오전만 중단	아스피린, 프레탈정 등은 평소대로 복용을 지속하되 검사 당일 오전만 중단합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
37	anticoagulant_medication	약물중단	\N	0	high	antiplatelet_moderate	중등도 출혈성 항혈소판제 - 주치의 상담 필수	플라빅스, 브릴린타 등은 중단 여부를 처방 주치의 판단에 따릅니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
38	anticoagulant_medication	약물중단	\N	0	high	anticoagulant_strict	항응고제 - 주치의 상담 필수, 당일 혈액검사로 최종 결정	와파린, 자렐토 등은 중단 여부를 주치의 판단에 따르며, 와파린은 당일 혈액응고검사 수치로 결정됩니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
39	anticoagulant_medication	약물유지(예외)	0	0	high	antiplatelet_stent_exception	스텐트/판막수술 이력자 - 검사 당일에도 복용 지속	스텐트 삽입 1년 이내이거나 판막교환 수술을 받은 경우, 검사 당일에도 항혈소판제 복용을 지속합니다.	심혈관/뇌혈관 스텐트 1년 이내 또는 판막교환 수술 이력자	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
40	blood_test	약물중단	\N	0	high	diabetes_med_stop	인슐린/당뇨약 - 금식 시작 시점부터 중단	인슐린, 다이아벡스 등은 금식 시점부터 중단합니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
41	gastroscopy	약물중단	\N	0	medium	appetite_suppressant_stop	식욕억제제 - 위내시경 전 중단 필요	위고비, 삭센다, 오젬픽 등 투약 중인 경우 검사 전 중단이 필요합니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
42	gastroscopy	식이제한	-1	-1	low	light_meal_special	식욕억제제 복용자/위절제술 이력자 - 전날 유동식 권고	검사 전날 아침·점심은 유동식으로 섭취하고 금식하도록 권고합니다.	식욕억제제 복용자 또는 위절제술 이력자	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
43	common	금식	-1	0	high	fasting	12시간 이상 금식	식사와 물을 포함하여 술, 약, 껌, 담배도 금식합니다. 물은 8시간 이상 금식 기준입니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
44	common	약물유지(예외)	0	0	medium	maintain_medication	항고혈압제/항경련제는 당일 아침 소량 물로 복용	검사 당일 아침 일찍 소량의 물과 함께 복용합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
45	pet_ct	약물중단(사후)	0	2	high	metformin_contrast	메트포르민 계열 - 조영제 CT 후 48시간 중단	메트포르민 성분은 신장에 무리를 줄 수 있어 조영제 CT 후 48시간 이상 복용하지 않습니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
46	pet_ct	금식	0	0	high	contrast_ct_fasting	조영제 CT - 최소 6시간 금식	조영제를 사용하는 CT 검사는 최소 6시간 이상 금식이 필요합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
47	out_of_scope_mri	소지품/금속물질	0	0	high	mri_metal_removal	[스코프 외] MRI - 금속물질 제거 및 사전 문의 대상	심박동기, 금속성 뇌동맥류 클립, 안구 내 금속 이물질, 폐소공포증 등은 사전 문의가 필요합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
27	common	검사 불가 조건	0	0	high	pregnancy_check	임신 배제 시기 확인	생리주기 및 피임 여부를 점검하여 임신이 확실히 배제된 시기에 검진을 받습니다.	가임기 여성	f	삼성서울병원 건강의학센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
49	out_of_scope_cervical_cytology	여성검진 조건	0	0	low	cervical_cytology_bleeding	[스코프 외] 자궁경부세포검사 후 소량 질출혈 가능	검사 후 소량의 질출혈이 발생할 수 있습니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
51	colonoscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경/산동검사 - 당일 운전 금지 및 보호자 동반 권장	검진 후 운전을 하면 위험하며, 보호자 동반이 권장됩니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
52	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경/산동검사 - 당일 운전 금지 및 보호자 동반 권장	검진 후 운전을 하면 위험하며, 보호자 동반이 권장됩니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
53	common	준비물	0	0	low	documents_belongings	문진 작성 및 소지품(안경/렌즈) 준비	사전 문진 작성이 필요하며, 교정시력 측정을 위해 안경이나 콘택트렌즈를 지참합니다.	\N	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
54	common	사전 고지	\N	\N	high	recent_surgery_notice	최근 6개월 이내 시술/수술 이력 사전 고지 필요	안과수술, 복부수술, 항혈전제 복용이 필요한 시술 이력이 있는 경우 사전 고지가 필요합니다.	\N	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
55	gastroscopy	약물중단	-14	0	high	glp1_stop	GLP-1 계열 비만/당뇨 치료제 중단 (위고비, 마운자로, 오젬픽 등)	검진일 기준 최소 2주(14일) 전부터 투약을 중단해야 합니다.	\N	t	KMI 한국의학연구소	2026-09-15	{"note": "지금까지 확인된 항목 중 가장 이른 시점(D-14)"}	2026-09-21 14:39:46.088176+09	\N
56	colonoscopy	약물중단	-14	0	high	glp1_stop	GLP-1 계열 비만/당뇨 치료제 중단 (위고비, 마운자로, 오젬픽 등)	검진일 기준 최소 2주(14일) 전부터 투약을 중단해야 합니다.	\N	t	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
57	anticoagulant_medication	약물중단	-7	0	high	anticoagulant_stop	항혈소판제/항응고제 - 주치의 상담 후 약 1주일 중단	조직검사/용종제거 시 출혈 위험이 있어 처방의와 협의 후 약 1주일 중단합니다.	\N	t	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
58	colonoscopy	식이제한	-7	-4	medium	low_residue_diet_early	변비 있는 경우 D-7부터 준비	변비가 있는 경우 검사 7일 전부터 미리 준비합니다.	평소 변비가 있는 수검자	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
59	colonoscopy	식이제한	-3	-1	high	low_residue_diet	저잔사식 시작 (D-3)	현미, 흑미, 김, 김치, 미역, 나물 및 씨 있는 과일 섭취를 금합니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
60	colonoscopy	식이제한	-1	0	high	low_residue_diet	전날 식단 (오전/오후 예약에 따라 스케줄 다름)	오전/오후 예약에 따라 저녁 식사·금식 시각이 다릅니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
61	common	금식	-1	0	high	fasting	전날 저녁 가벼운 식사 후 8시간 이상 금식	금식 중 물, 껌, 사탕, 담배, 커피, 색 있는 음료, 유제품 모두 금합니다.	\N	f	KMI 한국의학연구소	2026-09-15	{"discrepancy_vs_others": "병원마다 물 허용 기준 다름 - 서비스 기본값은 KMI 수준의 가장 엄격한 기준 채택"}	2026-09-21 14:39:46.088176+09	\N
62	blood_test	약물중단	-1	0	high	insulin_stop	인슐린 주사 - 전날 저녁부터 중단	인슐린은 검사 전날 저녁부터 중단, 당뇨약은 당일 아침 복용하지 않습니다.	\N	t	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
63	common	약물유지(예외)	0	0	medium	maintain_medication	고혈압약/항경련제 - 오전/오후 예약에 따라 복용 시점 다름	오전 예약자는 전날 취침 전, 오후 예약자는 당일 새벽에 복용합니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
69	out_of_scope_cervical_cytology	여성검진 조건	-3	0	medium	cervical_cytology_prep	[스코프 외] 자궁경부암 검사 전 금지사항	24시간 내 성관계/크림/질세척, 72시간 내 질정 사용을 금합니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
70	bladder_pelvic_us	소변관리	0	0	high	bladder_fill	전립선/자궁초음파 - 소변 참고 내원	초음파 검사 이후에 소변검사를 실시해야 합니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
71	abdominal_us	금식	0	0	high	abdominal_us_fasting	복부초음파 - 8시간 이상 금식	복부초음파 외 다른 초음파는 금식이 필요 없습니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
72	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 자가운전 절대 불가, 대중교통 이용	검사 후 3~4시간 휴식 필요, 자가운전 절대 불가.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
73	colonoscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 자가운전 절대 불가, 대중교통 이용	검사 후 3~4시간 휴식 필요, 자가운전 절대 불가.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
74	out_of_scope_stool_test	검체채취	\N	\N	low	stool_collection	[스코프 외] 대장암 선별검사(분변) - 제출 48시간 이내 채취	M2-PK, 얼리텍 검사 등은 제출 전 48시간 이내 채취해야 합니다.	\N	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
50	common	검사 불가 조건	\N	0	high	pregnancy_check	임신 가능성 확인 - 방사선 검사 전 필수	방사선은 태아에게 위험할 수 있어, 임신 여부 확인이 필요할 수 있습니다.	가임기 여성	t	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
68	common	검사 불가 조건	0	0	high	pregnancy_check	임신 가능성 - X-ray/내시경/방사선 검사 제한	임신 가능성이 있는 경우 일부 항목이 제한됩니다.	가임기 여성	t	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
75	common	생활습관	-3	-1	medium	pre_diet_restriction	음주/기름진 음식 자제	검진 2~3일 전부터 음주, 기름진 음식을 피합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
76	common	금식	-1	0	high	fasting	전날 저녁 이후 금식 (오전/오후 검진에 따라 시각 다름)	오전/오후 검진에 따라 저녁식사·금식 시각이 다릅니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
77	common	약물중단	-3	-2	low	general_med_stop	평소 복용약 - 가급적 2~3일 전부터 중단 권고 (일반 원칙)	평소 복용하는 약은 가급적 2~3일 전부터 복용하지 않도록 권고합니다.	\N	t	한국건강관리협회	2026-09-15	{"note": "구체적 약물별 규칙이 없을 때의 fallback 원칙"}	2026-09-21 14:39:46.088176+09	\N
78	anticoagulant_medication	약물중단	-7	0	high	antiplatelet_stop	항혈전제 - D-7부터 중단 (주치의 확인 필수)	아스피린, 플라빅스 등은 주치의 확인 후 일주일 전부터 중단합니다.	\N	t	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
79	anticoagulant_medication	약물중단	-3	0	high	anticoagulant_stop_strict	항응고제 - D-3부터 중단	쿠마딘, 와파린, 헤파린 등은 검사 3일 전부터 중단합니다.	\N	t	한국건강관리협회	2026-09-15	{"discrepancy_vs_others": "강남센터/KMI는 항응고제를 주치의 판단(고정일 없음)으로 안내, 이 기관은 D-3로 구체적 제시"}	2026-09-21 14:39:46.088176+09	\N
82	out_of_scope_stool_test	검체채취	-1	0	medium	stool_collection	[스코프 외] 대변채취 - 전날 또는 당일, 밤알 크기	채변용기 1/3 정도(밤알 크기)를 담아 서늘하게 보관합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
83	common	약물유지(예외)	0	0	medium	maintain_medication	혈압약 - 당일 새벽 6시 이전 최소량 물로 복용	단, 위장조영술을 하는 경우는 약을 먹지 말고 지참합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
84	blood_test	약물중단	-1	0	high	insulin_stop	인슐린 - 전날 저녁부터 중단, 당뇨약 당일 아침 중단	인슐린은 전날 저녁부터 주사하지 않으며, 당뇨약은 당일 아침 복용을 금합니다.	\N	t	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
85	common	질환별 사전 고지	\N	\N	high	condition_disclosure	특정 질환자 - 검사 전 사전 고지/상담 필요	갑상선질환, 녹내장, 전립선비대, 고령, 신부전 등 특정 질환자는 사전 고지가 필요합니다.	\N	t	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
86	bladder_pelvic_us	소변관리	0	0	high	bladder_fill	하복부초음파(전립선/방광/난소) - 소변 참고 내원	아침 소변을 보지 않고 참은 상태로 내원합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
87	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 자가운전 불가, 보호자 동반	당일 자가운전이 불가능하며 보호자를 동반해야 합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
88	colonoscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 자가운전 불가, 보호자 동반	당일 자가운전이 불가능하며 보호자를 동반해야 합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
89	out_of_scope_mri	소지품/금속물질	0	0	high	mri_metal_removal	[스코프 외] MRI - 금속물질 제거 및 사전 고지 대상	보청기, 틀니, 피어싱 등 금속성 물질은 탈착해야 합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
90	pet_ct	금식	0	0	high	contrast_ct_fasting	조영 CT - 약 6시간 금식	조영CT 검사 전 약 6시간 정도 금식이 필요합니다.	\N	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
91	pet_ct	검사 제한/사전고지	\N	0	high	contrast_ct_contraindication	조영 CT - 검사 어려운 경우 사전 고지 필요	갑상선기능항진증, 신장절제/투석, 조영제 부작용 이력, 비아그라 복용 후 48시간 미경과 등은 사전 고지가 필요합니다.	\N	t	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
92	common	생활습관	-3	-1	medium	pre_diet_restriction	기름진 음식/음주/과로 자제	검진 2~3일 전부터 기름진 음식, 음주 및 과로를 피합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
93	common	금식	-1	0	high	fasting	전날 저녁 이후 금식 (오전/오후 검진에 따라 다름)	오전/오후 검진에 따라 물 허용 기준까지 세밀하게 다릅니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
94	out_of_scope_stool_test	검체채취	-1	0	medium	stool_collection	[스코프 외] 대변검사 - 전날 또는 당일 오전 채취 권장	대장내시경 예약 고객은 장정결제 복용 전 채취를 권장합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
95	bladder_pelvic_us	소변관리	0	0	high	bladder_fill	골반초음파/하복부초음파 - 소변 참고 내원	검진 당일 소변은 되도록 참고 내원합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
99	out_of_scope_cervical_cytology	여성검진 조건	-1	0	medium	cervical_cytology_prep	[스코프 외] 자궁경부세포검사 전 24시간 금지사항	부부관계, 질정, 크림, 질세척 사용을 24시간 전부터 금합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
100	anticoagulant_medication	약물중단	-7	0	high	anticoagulant_antiplatelet_combined	항혈소판제+항응고제 - D-7, 담당의 상담 필수	처방 담당의와 상의 후 일주일 전부터 복용을 중단합니다.	\N	t	하나로의료재단	2026-09-15	{"discrepancy_vs_others": "항혈소판제/항응고제를 구분하지 않고 D-7로 통일 - 세 번째 버전의 항응고제 기준"}	2026-09-21 14:39:46.088176+09	\N
80	mammography	여성검진 조건	0	0	low	menstrual_cycle	생리 중 검사 제한 가능	생리 중인 경우 검사 내용에 제한이 있을 수 있습니다.	가임기 여성	f	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
81	common	검사 불가 조건	\N	0	high	pregnancy_check	가임기 여성 - 예약 전 임신 여부 확인	가임기 여성은 검진 예약 전 반드시 임신 여부를 확인해야 합니다.	가임기 여성	t	한국건강관리협회	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
96	common	검사 불가 조건	\N	0	high	pregnancy_check	가임기 여성 - 임신 가능성 필수 확인	생리 주기를 체크해 임신 여부를 필수 확인해야 합니다.	가임기 여성	t	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
101	anticoagulant_medication	약물중단	\N	0	medium	hidden_aspirin_check	혈압약/당뇨약/심장약 내 아스피린 성분 확인 필요	복합제 성분으로 아스피린이 포함된 경우가 있을 수 있습니다.	\N	t	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
102	blood_test	약물중단	0	0	high	diabetes_med_stop	당뇨약/인슐린 당일 중단	검진 당일 당뇨약, 인슐린 주사를 중단합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
103	common	약물유지(예외)	0	0	medium	maintain_medication	항고혈압/부정맥/심장질환/갑상선/항경련제 - 당일 아침 소량 물로 복용	해당 약물은 검진 당일 아침 일찍 소량의 물로 복용합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
104	gastroscopy	검사 제한/사전고지	\N	\N	medium	endoscopy_contraindication	내시경 검사 제한 조건 (사전 고지 필요)	라식/라섹 수술은 3개월 후 권장, 매니큐어 제거, 치아 손상 가능성, BMI 35 이상 제한.	\N	t	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
105	colonoscopy	검사 제한/사전고지	\N	\N	medium	endoscopy_contraindication	내시경 검사 제한 조건 (사전 고지 필요)	라식/라섹 수술은 3개월 후 권장, 매니큐어 제거, 치아 손상 가능성, BMI 35 이상 제한.	\N	t	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
106	gastroscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 당일 자가운전 불가	반드시 대중교통을 이용해야 합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
107	colonoscopy	동반자/준비물	0	0	medium	sedation_companion	수면내시경 - 당일 자가운전 불가	반드시 대중교통을 이용해야 합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
108	common	준비물	0	0	low	belongings	렌즈 제거, 안경 지참, 귀중품/어린이 동반 자제	안압 검사 시 렌즈 손상 우려로 렌즈는 제거하고 안경을 지참합니다.	\N	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
109	mammography	외용제/착용품 제한	0	0	medium	mammography_topical_restriction	검사 당일 로션/데오도란트/장신구 금지	데오도란트 성분이 영상에 인공물로 나타나 미세석회화처럼 오인될 수 있습니다.	\N	f	을지대학교병원 유방갑상선암센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
111	mammography	금식	0	0	low	no_fasting_needed	유방초음파 - 금식 불필요	유방초음파는 금식 등의 준비가 필요하지 않습니다.	\N	f	을지대학교병원 유방갑상선암센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
112	out_of_scope_breast_biopsy	검사 후 관리	0	4	medium	post_biopsy_care	[스코프 외] 유방 조직검사(총생검) 후 주의사항	방수밴드는 3~4일 유지하며, 물이 닿지 않도록 주의하고 음주/무리한 운동을 삼갑니다.	\N	f	을지대학교병원 유방갑상선암센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
113	gastroscopy	약물중단	-7	0	high	glp1_stop_wegovy_mounjaro	위고비/마운자로 - D-7 중단	위내시경 검사 예정 시 위고비, 마운자로는 검사 7일 전부터 중단해야 합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	{"discrepancy_vs_others": "KMI는 GLP-1 전체 D-14, 이 병원은 위고비/마운자로 D-7 - 약물명 단위 세분화 필요"}	2026-09-21 14:39:46.088176+09	\N
114	gastroscopy	약물중단	-1	0	high	glp1_stop_saxenda	삭센다 - D-1 중단	위내시경 검사 예정 시 삭센다는 검사 1일 전부터 중단해야 합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	{"note": "매일 주사형이라 주 1회형보다 중단 기간 짧음"}	2026-09-21 14:39:46.088176+09	\N
115	anticoagulant_medication	약물중단	\N	0	high	anticoagulant_antiplatelet_endoscopy	항혈전제/항응고제 - 내시경 조직검사 전 중단	중단 여부는 처방 담당 주치의와 상의해야 합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	{"note": "정확한 D-day 없이 주치의 상의로 일임 - 오히려 안전한 방식일 수 있음"}	2026-09-21 14:39:46.088176+09	\N
116	common	생활습관	-3	-1	medium	pre_diet_restriction	육류/음주/과로/심한 운동 자제	검진 2~3일 전부터 육류, 음주, 과로 및 심한 운동을 피합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
117	common	금식	-1	0	high	fasting	전날 저녁 8시까지 식사, 자정까지 물만 가능	자정 이후엔 물, 껌, 사탕, 담배도 절대 금합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
118	out_of_scope_stool_test	검체채취	-1	0	medium	stool_collection	[스코프 외] 채변 - 전날 저녁 또는 당일 아침, 장정결제 전 채취	신선한 변을 채취하며 서늘하게 보관합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
121	out_of_scope_cervical_cytology	여성검진 조건	-1	0	medium	cervical_cytology_prep	[스코프 외] 부인과 검사 - 24시간 내 질정/크림 사용 금지	검사 전 24시간 내에 질정, 크림 사용을 금합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
122	gastroscopy	준비물	0	0	medium	nail_polish_removal	수면내시경 - 매니큐어/젤네일 제거 필수	산소포화도 측정이 불가하므로 반드시 제거하고 검사를 진행합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
123	colonoscopy	준비물	0	0	medium	nail_polish_removal	수면내시경 - 매니큐어/젤네일 제거 필수	산소포화도 측정이 불가하므로 반드시 제거하고 검사를 진행합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
124	common	약물유지(예외)	0	0	medium	maintain_medication	혈압약/항경련제 - 당일 오전 5시경 소량 물로 복용	당뇨약은 당일 아침 인슐린 투여나 복용을 금합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
125	pet_ct	약물중단 주의	\N	0	high	metformin_iodine_contrast	메트포르민 함유 당뇨약 - 요오드 조영제 병용 주의	요오드 표지 조영제와 메트포르민 함유 경구 혈당강하제는 병용 투여에 주의가 필요합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
110	mammography	검사 불가 조건	0	0	high	pregnancy_check	임신 중이거나 가능성 있는 경우 의료진에게 필수 고지	X선을 이용한 검사이므로 임신 관련 사항을 의료진에게 알려야 합니다.	가임기 여성	t	을지대학교병원 유방갑상선암센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
126	pet_ct	생활습관	-1	0	high	petct_exercise_restriction	검사 전날 산책/운동 절대 금지 (D-1)	등산, 골프, 헬스 등을 절대 금하며 충분한 수면을 취해야 합니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	{"discrepancy_vs_others": "분당차/서울대암병원은 D-2, 이 병원은 D-1 - 서비스 기본값은 보수적인 D-2 유지"}	2026-09-21 14:39:46.088176+09	\N
127	pet_ct	금식	-1	0	high	petct_fasting_combined	[종합검진과 함께 실시] 전날 저녁부터 검사 당일까지 금식	오전/오후 검진에 따라 금식 시작 시각이 다릅니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
128	pet_ct	금식	0	0	high	petct_fasting_standalone	[PET-CT만 단독 실시] 6시간 이상 금식 + 검사 2시간 전 생수 섭취	첨가물 있는 음료는 안 되며, 물 외에는 모두 금지됩니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	{"note": "단독 vs 조합 여부에 따라 규칙 자체가 달라지는 핵심 사례 - exam_rule_variants 테이블 참고"}	2026-09-21 14:39:46.088176+09	\N
129	pet_ct	약물중단	0	0	high	petct_insulin_pump	인슐린 펌프 사용자 - 검사 4시간 전 중단	인슐린 펌프를 사용하는 경우 검사 4시간 전에 중단해야 합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
130	pet_ct	약물중단	\N	0	medium	petct_headache_med	뇌질환 관련 약물(두통약 등) - 사전 상담 필요	두통약 등 뇌질환 관련 약물 복용자는 미리 상담을 받아야 합니다.	\N	t	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
131	pet_ct	검사 당일 절차	0	0	low	petct_companion_restriction	검사 당일 임산부/영유아 동반 자제	방사성의약품 노출 방지를 위해 동반하지 않는 것이 좋습니다.	\N	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
133	pet_ct	금식	0	0	high	petct_fasting	FDG PET/CT - 6시간 이상 금식 + 당분 음료 금지	물(생수)은 충분히 마셔도 되지만 당분이 있는 음료수는 절대 안 됩니다.	\N	f	분당차병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
134	pet_ct	생활습관	-2	0	high	petct_exercise_restriction	검사 2일 전부터 심한 운동 자제	근육의 당 대사 증가가 영상 판독에 영향을 줄 수 있습니다.	\N	f	분당차병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
135	pet_ct	검사 당일 절차	0	0	medium	petct_urination	촬영 직전 소변 필수	촬영 직전 꼭 소변을 봐야 합니다.	\N	f	분당차병원 핵의학과	2026-09-15	{"note": "방광/골반초음파와 정반대 방향(소변 참기 vs 소변 보기) - 병합 로직에서 명확히 구분 필요"}	2026-09-21 14:39:46.088176+09	\N
136	pet_ct	사전 고지/혈당 조절	\N	0	high	petct_diabetes	당뇨병 환자 - 예약 시 사전 고지 및 혈당 조절 필요	혈당 조절이 안 되면 검사가 연기 또는 취소될 수 있습니다.	\N	t	분당차병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
137	pet_ct	행정/예약	-1	0	medium	petct_reschedule	예약 변경은 최소 하루 전 필수 통보	방사성의약품은 시간이 지나면 사용할 수 없습니다.	\N	f	분당차병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
138	pet_ct	금식	-1	0	high	petct_fasting	종양 PET - 전날 밤 12시부터 금식, 물은 충분히	검사 전날 밤 12시부터 금식해야 하며, 물은 많이 마셔도 됩니다.	\N	f	삼성서울병원 핵의학과	2026-09-15	{"discrepancy_vs_others": "분당차는 6시간, 삼성서울은 전날 자정부터(약 10시간+) - 보수적 기준"}	2026-09-21 14:39:46.088176+09	\N
139	pet_ct	검사 당일 절차	0	0	medium	petct_urination	포도당 대사 PET - 촬영 직전 소변 필요	촬영 직전에 소변을 봐야 정확한 검사가 가능합니다.	\N	f	삼성서울병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
140	pet_ct	검사 당일 절차	0	0	low	petct_procedure	촬영 중 부동자세 유지 및 소요시간 안내	대기시간 포함 1시간 반에서 2시간 정도 소요됩니다.	\N	f	삼성서울병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
141	pet_ct	금식	0	0	high	petct_fasting	PET-CT - 8시간 이상 금식 (생수만 가능)	8시간 이상 금식해야 하며, 생수만 섭취 가능합니다.	\N	f	중앙대학교병원 핵의학과	2026-09-15	{"discrepancy_vs_others": "3개 병원 모두 다른 금식 시간(6h/자정부터/8h) - 6~10시간 범위로 수렴"}	2026-09-21 14:39:46.088176+09	\N
142	pet_ct	약물유지(예외)	0	0	medium	petct_diabetes	당뇨환자 - 당일 당뇨약 지참 (중단이 아닌 지참)	당뇨환자는 검사 당일 당뇨약을 지참합니다.	\N	t	중앙대학교병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
144	pet_ct	행정/예약	-1	0	medium	petct_reschedule	검사 취소 시 하루 전(근무시간) 연락 필요	검사를 취소하는 경우 하루 전 근무시간까지 연락해야 합니다.	\N	f	중앙대학교병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
145	out_of_scope_myocardial_spect	약물중단	-2	0	medium	caffeine_asthma_med_restriction	[스코프 외] 심근 SPECT - 카페인/천식약 제한	카페인 함유 식품 금지, 천식약 일부는 48시간 중단, 당일 금연 필요.	\N	f	중앙대학교병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
146	out_of_scope_bone_scan	검사 당일 절차	0	0	low	bone_scan_urination	[스코프 외] 골 스캔 - 금식 불필요, 검사 전 소변 필수	금식이 필요 없으며 검사 전 반드시 소변을 봐야 합니다.	\N	f	중앙대학교병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
147	pet_ct	금식	0	0	high	petct_fasting	F-18-FDG PET/CT - 최소 8시간 이상 금식	껌, 보리차, 녹차 및 과당이 함유된 음료수 섭취를 금합니다.	\N	f	서울대학교암병원	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
148	pet_ct	생활습관	-2	0	high	petct_exercise_restriction	검사 2일 전부터 격렬한 운동 금지 (재확인)	마라톤, 싸이클, 에어로빅, 수영 등을 삼가야 합니다.	\N	f	서울대학교암병원	2026-09-15	{"note": "분당차병원과 일치 - 일반 규칙으로 격상"}	2026-09-21 14:39:46.088176+09	\N
149	pet_ct	준비물	0	0	low	petct_clothing	귀금속/금속장식 없는 옷 착용 권장	MRI의 금속물질 제거와 유사한 맥락입니다.	\N	f	서울대학교암병원	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
150	pet_ct	약물중단	0	0	high	petct_insulin	당뇨병 환자 - 당일 검사 전 인슐린 투약 금지	인슐린제제 투약을 금해야 합니다.	\N	t	서울대학교암병원	2026-09-15	{"note": "중앙대는 당뇨약 지참(중단 아님) - 인슐린과 경구약 구분 필요"}	2026-09-21 14:39:46.088176+09	\N
143	pet_ct	검사 불가 조건	\N	0	high	pregnancy_check	임산부/가임 여성 - 사전 주치의 상담 필요	임산부 및 가임 여성은 사전에 주치의와 상담이 필요합니다.	임신 중이거나 가임기인 여성	t	중앙대학교병원 핵의학과	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
153	pet_ct	검사 당일 절차	0	0	low	petct_post_exam_hydration	검사 후 충분한 수분 섭취 권장	검사 당일 충분한 수분섭취(물 500ml 이상)를 권장합니다.	\N	f	서울대학교암병원	2026-09-15	\N	2026-09-21 14:39:46.088176+09	\N
14	mammography	여성검진 조건	0	0	medium	menstrual_cycle	생리 중 검사 제한	생리 중에는 소변 및 부인과 검사를 제외한 검사는 가능합니다. 생리 종료 5일 후부터 재방문 가능.	가임기 여성	f	서울아산병원 건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
26	mammography	여성검진 조건	0	0	medium	menstrual_cycle	생리기간 회피 권장	여성 고객은 생리기간을 피해서 검사받는 것이 좋습니다.	\N	f	삼성서울병원 건강의학센터	2026-09-15	{"discrepancy_vs_amc": "아산은 생리 중에도 소변/부인과 제외 가능(완화), 삼성은 전체 회피 권장(보수적)"}	2026-09-21 14:39:46.088176+09	female
48	mammography	여성검진 조건	0	0	low	menstrual_cycle	월경 기간 중 부인과 검사 가능, 소변검사만 불가	월경 기간에도 부인과 검사는 가능하며, 소변검사만 불가합니다.	가임기 여성	f	서울대학교병원 강남센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
64	mammography	여성검진 조건	\N	0	medium	breastfeeding_restriction	모유 수유 중 유방촬영/유방초음파 연기 권장	수유 중단 후 6개월 이후 검사를 권장합니다.	모유 수유 중인 여성	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
65	gastroscopy	여성검진 조건	0	0	low	breastfeeding_sedation	수유 중 진정(수면)내시경 후 24시간 수유 중단	검사 후 24시간 동안 모유 수유를 중단해야 합니다.	모유 수유 중인 여성 + 수면내시경 선택자	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
66	colonoscopy	여성검진 조건	0	0	low	breastfeeding_sedation	수유 중 진정(수면)내시경 후 24시간 수유 중단	검사 후 24시간 동안 모유 수유를 중단해야 합니다.	모유 수유 중인 여성 + 수면내시경 선택자	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
67	mammography	여성검진 조건	0	0	low	menstrual_cycle_urine	생리 종료 7일 후부터 소변검사/부인과검사 가능	탐폰 지참 시 생리 중에도 검사가 가능합니다.	가임기 여성	f	KMI 한국의학연구소	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
97	mammography	여성검진 조건	0	0	medium	menstrual_cycle_specific	생리 중 - 소변검사/자궁경부세포검사만 제한	생리가 끝난 4~5일 후가 권장됩니다.	가임기 여성	f	하나로의료재단	2026-09-15	{"discrepancy_vs_others": "생리 관련 기준이 기관마다 표현이 다름 - 병원별 확인 필수 항목으로 확정"}	2026-09-21 14:39:46.088176+09	female
98	mammography	여성검진 조건	\N	0	medium	breastfeeding_restriction	수유 중 - 유방촬영/유방초음파 제한	모유 수유 중단 후 최소 6개월 후 검사가 가능합니다.	모유 수유 중인 여성	f	하나로의료재단	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
119	mammography	여성검진 조건	0	0	medium	menstrual_cycle_window	생리 시작일로부터 8~12일 사이 권장	마지막 생리 시작일로부터 8~12일 사이에 검진을 진행하는 것이 좋습니다.	가임기 여성	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
120	mammography	여성검진 조건	\N	0	medium	breastfeeding_restriction	수유 중 유방촬영 불가	수유 중인 경우 유방촬영 검사가 불가합니다.	모유 수유 중인 여성	f	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
132	pet_ct	검사 불가 조건	\N	0	high	pregnancy_breastfeeding_check	임신 가능성/수유 중 - 반드시 사전 고지	임신 가능성이 있거나 수유 중인 경우 반드시 미리 말씀해야 합니다.	가임기 또는 수유 중인 여성	t	서울성모병원 평생건강증진센터	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
152	pet_ct	여성검진 조건	0	0	medium	petct_breastfeeding_pause	수유 중 - 검사 후 최소 24시간 수유 중단	검사 후 최소 24시간 경과 후 수유를 재개할 수 있습니다.	모유 수유 중인 여성	f	서울대학교암병원	2026-09-15	\N	2026-09-21 14:39:46.088176+09	female
151	pet_ct	검사 불가 조건	\N	0	high	pregnancy_check	가임기 여성 - 임신 유무 확인 필수, 임신 중엔 비권장	임신 중 PET/CT는 권장하지 않으며, 필요 시 담당의사와 상담합니다.	가임기 여성	t	서울대학교암병원	2026-09-15	\N	2026-09-21 14:39:46.088176+09	pregnancy
\.


--
-- TOC entry 3916 (class 0 OID 0)
-- Dependencies: 224
-- Name: exam_rule_variants_variant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.exam_rule_variants_variant_id_seq', 2, true);


--
-- TOC entry 3917 (class 0 OID 0)
-- Dependencies: 220
-- Name: prep_items_prep_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prep_items_prep_id_seq', 153, true);


--
-- TOC entry 3739 (class 2606 OID 16536)
-- Name: conflict_group_canonical_display conflict_group_canonical_display_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conflict_group_canonical_display
    ADD CONSTRAINT conflict_group_canonical_display_pkey PRIMARY KEY (canonical_group);


--
-- TOC entry 3737 (class 2606 OID 16527)
-- Name: conflict_group_canonical conflict_group_canonical_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conflict_group_canonical
    ADD CONSTRAINT conflict_group_canonical_pkey PRIMARY KEY (raw_group);


--
-- TOC entry 3735 (class 2606 OID 16520)
-- Name: conflict_group_opposites conflict_group_opposites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conflict_group_opposites
    ADD CONSTRAINT conflict_group_opposites_pkey PRIMARY KEY (group_a, group_b);


--
-- TOC entry 3729 (class 2606 OID 16465)
-- Name: exam_medication_relevance exam_medication_relevance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_medication_relevance
    ADD CONSTRAINT exam_medication_relevance_pkey PRIMARY KEY (exam_id, drug_id);


--
-- TOC entry 3731 (class 2606 OID 16489)
-- Name: exam_rule_variants exam_rule_variants_exam_id_context_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_rule_variants
    ADD CONSTRAINT exam_rule_variants_exam_id_context_type_key UNIQUE (exam_id, context_type);


--
-- TOC entry 3733 (class 2606 OID 16487)
-- Name: exam_rule_variants exam_rule_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_rule_variants
    ADD CONSTRAINT exam_rule_variants_pkey PRIMARY KEY (variant_id);


--
-- TOC entry 3721 (class 2606 OID 16419)
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (exam_id);


--
-- TOC entry 3727 (class 2606 OID 16458)
-- Name: medications medications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medications
    ADD CONSTRAINT medications_pkey PRIMARY KEY (drug_id);


--
-- TOC entry 3725 (class 2606 OID 16437)
-- Name: prep_items prep_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prep_items
    ADD CONSTRAINT prep_items_pkey PRIMARY KEY (prep_id);


--
-- TOC entry 3722 (class 1259 OID 16444)
-- Name: idx_prep_items_conflict_group; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prep_items_conflict_group ON public.prep_items USING btree (conflict_group);


--
-- TOC entry 3723 (class 1259 OID 16443)
-- Name: idx_prep_items_exam_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_prep_items_exam_id ON public.prep_items USING btree (exam_id);


--
-- TOC entry 3741 (class 2606 OID 16471)
-- Name: exam_medication_relevance exam_medication_relevance_drug_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_medication_relevance
    ADD CONSTRAINT exam_medication_relevance_drug_id_fkey FOREIGN KEY (drug_id) REFERENCES public.medications(drug_id) ON DELETE CASCADE;


--
-- TOC entry 3742 (class 2606 OID 16466)
-- Name: exam_medication_relevance exam_medication_relevance_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_medication_relevance
    ADD CONSTRAINT exam_medication_relevance_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(exam_id) ON DELETE CASCADE;


--
-- TOC entry 3743 (class 2606 OID 16490)
-- Name: exam_rule_variants exam_rule_variants_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exam_rule_variants
    ADD CONSTRAINT exam_rule_variants_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(exam_id) ON DELETE CASCADE;


--
-- TOC entry 3740 (class 2606 OID 16438)
-- Name: prep_items prep_items_exam_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prep_items
    ADD CONSTRAINT prep_items_exam_id_fkey FOREIGN KEY (exam_id) REFERENCES public.exams(exam_id) ON DELETE CASCADE;


-- Completed on 2026-09-30 14:18:07 KST

--
-- PostgreSQL database dump complete
--

\unrestrict RdPl3cC8OWpn0iNsVGLMZEmJwiqg07gPFo5EIqhoLDaoK6TPp5ggYafovSjffpn

