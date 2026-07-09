# dailyYam - AI 식단 관리 웹 서비스

> 음식 사진 한 장으로 식단을 기록하고, AI 코치가 데이터에 근거한 피드백을 제공하는 스마트 식단 관리 플랫폼

---

## 주요 기능

### 일반 회원
| 기능 | 설명 |
|------|------|
| **AI 식단 기록** | 식사 사진 업로드 시 AI 비전 모델이 음식명·칼로리·3대 영양소를 자동 분석 |
| **대시보드** | 오늘의 칼로리 달성률, 탄수화물·단백질·지방 섭취 현황을 실시간 확인 |
| **식단 이력** | 날짜별 과거 식사 기록 조회 및 상세 영양 정보 확인 |
| **AI 인사이트** | 주간 칼로리 추이 차트, 체중·BMI 추적, 목표 달성률 관리 |
| **AI 코치 채팅** | 식단·목표 데이터를 바탕으로 AI 코치가 맥락 기반 피드백 응답 |
| **알림 / 설정 / 프로필** | 알림 관리, 목표 수치 변경, 개인 정보 수정 |

### 코치
| 기능 | 설명 |
|------|------|
| **코치 대시보드** | 전담 회원 현황 한눈에 파악 |
| **회원 관리** | 담당 회원 목록 및 상태 관리 |
| **회원 채팅** | 회원에게 식단 피드백 카드 전송 |
| **피드백 리뷰** | AI 인사이트 기반 피드백 검토 |

---

## 기술 스택

### Frontend
- **Vue 3** (Composition API + `<script setup>`)
- **TypeScript**
- **Tailwind CSS v4** (Vite 플러그인)
- **Pinia** — 전역 상태 관리 (인증)
- **Vue Router 4** — SPA 라우팅 + Navigation Guard
- **Chart.js + vue-chartjs** — 주간 칼로리 차트
- **Lucide Vue** — 아이콘

### Backend
- **Spring Boot API** via Vite proxy
- **SSAFY GMS 게이트웨이 → OpenAI gpt** — `gpt-4o-mini`(비전 식단 분석) / `gpt-5-mini`(AI 코치)
- **In-memory DB** — 런타임 상태 저장 (재시작 시 초기화)

### Build & Dev
- **Vite 6** — 프론트엔드 번들러 / HMR
- **Vite preview** — production build preview

---

## 프로젝트 구조

```
dailyYam_front/
├── src/
│   ├── main.ts                  # 앱 진입점 / 라우터 / Pinia 초기화
│   ├── App.vue                  # 루트 컴포넌트
│   ├── types.ts                 # 공통 타입 정의
│   ├── stores/
│   │   ├── auth.ts              # 인증 스토어 (Pinia)
│   │   └── meal.ts              # 식단 스토어 (Pinia)
│   ├── components/
│   │   ├── Sidebar.vue          # 사이드바 (회원/코치 모드 분기)
│   │   ├── Header.vue           # 상단 헤더
│   │   ├── AuthLayout.vue       # 인증 페이지 공통 레이아웃
│   │   ├── FieldInput.vue       # 폼 입력 컴포넌트
│   │   └── Toggle.vue           # 토글 컴포넌트
│   └── views/
│       ├── LandingView.vue      # 랜딩 페이지
│       ├── LoginView.vue        # 로그인 (회원/코치 탭)
│       ├── OnboardingView.vue   # 회원가입
│       ├── PasswordResetView.vue
│       ├── DashboardView.vue    # 메인 대시보드
│       ├── MealLogView.vue      # AI 식단 기록
│       ├── MealHistoryView.vue  # 식단 이력
│       ├── MealDetailView.vue   # 식단 상세
│       ├── AiInsightsView.vue   # AI 인사이트 & 목표
│       ├── ChatView.vue         # 코치 채팅 (회원)
│       ├── CoachChatView.vue    # 회원 채팅 (코치)
│       ├── CoachDashboardView.vue
│       ├── CoachMembersView.vue
│       ├── NotificationsView.vue
│       ├── SettingsView.vue
│       └── ProfileEditView.vue
├── vite.config.ts
├── tsconfig.json
├── package.json
├── index.html
├── .env                         # 환경 변수 (gitignore)
└── .env.example                 # 환경 변수 예시
```

---

## API 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `GET` | `/api/dashboard` | 식단 목록, 일일 목표, 사용자 통계 조회 |
| `POST` | `/api/meals` | 새 식단 기록 추가 |
| `PUT` | `/api/goals` | 일일 영양 목표 수정 |
| `PUT` | `/api/stats` | 체중·BMI·달성률 업데이트 |
| `POST` | `/api/meals/analyze` | 음식 사진 → AI 비전(gpt-4o-mini) 영양 분석 |
| `POST` | `/api/calories/estimate` | 음식명 + 중량 → 칼로리 추정 |
| `GET` | `/api/chats` | 코치 채팅방 목록 조회 |
| `POST` | `/api/chats/:coachId/messages` | 코치에게 메시지 전송 (AI 코치 응답) |

---

## 시작하기

### 요구사항
- Node.js 18+
- SSAFY GMS Key (선택 — 없으면 Mock 데이터로 동작)

### 설치

```bash
npm install
```

### 환경 변수 설정

`.env.example`을 복사하여 `.env` 파일을 생성합니다.

```bash
cp .env.example .env
```

`.env` 파일에 GMS Key를 입력합니다.

```env
GMS_KEY="your_gms_key_here"
APP_URL="http://localhost:3000"
```

> **GMS Key가 없어도 동작합니다.** 이미지 분석 및 AI 코치 기능이 미리 정의된 Mock 데이터로 응답합니다.

### 개발 서버 실행

```bash
npm run dev
```

브라우저에서 [http://localhost:3000](http://localhost:3000) 접속

### 프로덕션 빌드

```bash
npm run build
npm start
```

---

## 인증 구조

- 인증 상태는 **localStorage** 기반으로 관리 (`dailyyam_auth`, `dailyyam_role`, `dailyyam_name`)
- **회원 / 코치** 두 가지 역할을 지원하며, 로그인 시 선택
- Navigation Guard가 비인증 사용자를 `/login`으로 리다이렉트

**공개 경로 (인증 불필요)**
```
/  /landing  /login  /password-reset  /onboarding
```

---

## 데이터 타입

```typescript
interface Meal {
  id: string;
  time: string;           // "HH:MM"
  mealType: string;       // "아침" | "점심" | "저녁" | "간식"
  foodName: string;
  calories: number;
  protein: number;        // g
  carbs: number;          // g
  fat: number;            // g
  tags: string[];
  imageUrl: string;
  items?: MealItem[];     // 세부 구성 항목
  loggedAt: string;       // ISO 8601
}

interface DailyGoals {
  targetCalories: number;
  targetProtein: number;
  targetCarbs: number;
  targetFat: number;
}

interface UserStats {
  currentWeight: number;
  previousWeight: number;
  bmi: number;
  progressRate: number;   // %
}
```

---

## 스크립트

| 명령어 | 설명 |
|--------|------|
| `npm run dev` | 개발 서버 시작 (Vite HMR) |
| `npm run build` | 프론트엔드 빌드 + 서버 번들링 |
| `npm start` | 프로덕션 서버 시작 |
| `npm run lint` | TypeScript 타입 검사 |
| `npm run clean` | dist 폴더 삭제 |
