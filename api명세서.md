# dailyYam(냠냠코치) — API 명세서

> Backend: Spring Boot 3 (Java 17) + MyBatis + MySQL
> Base URL: `/api` · 인증: JWT (Access/Refresh) · 본 문서는 [erd.md](erd.md), [요구사항정의서.md](요구사항정의서.md)와 연계된다.

---

## 목차

1. [공통 규약](#1-공통-규약)
2. [인증 / 회원 (Auth & User)](#2-인증--회원-auth--user)
3. [질환 (Health Conditions)](#3-질환-health-conditions)
4. [식단 (Meal)](#4-식단-meal)
5. [AI 분석 (AI Analysis)](#5-ai-분석-ai-analysis)
6. [영양 / 음식 DB (Nutrition & Foods)](#6-영양--음식-db-nutrition--foods)
7. [점수 산출 (Diet Score)](#7-점수-산출-diet-score)
8. [목표 / 통계 (Goals & Stats)](#8-목표--통계-goals--stats)
9. [코치 (Coach)](#9-코치-coach)
10. [알림 (Notifications)](#10-알림-notifications)
11. [관리자 (Admin)](#11-관리자-admin)

---

## 1. 공통 규약

### 1.1 요청/응답 형식

- Content-Type: `application/json; charset=UTF-8` (이미지 업로드는 `multipart/form-data`)
- 모든 시각은 ISO 8601 (`2026-06-22T08:30:00+09:00`)
- enum은 영문 대문자 코드 사용 (`BREAKFAST`, `DIABETES` 등)

### 1.2 인증 헤더

```
Authorization: Bearer {accessToken}
```

- Access Token 만료 시 `401`(`TOKEN_EXPIRED`) → `/api/auth/refresh`로 재발급
- Refresh Token은 만료/로그아웃 시 서버에서 폐기

### 1.3 공통 응답 래퍼

```json
// 성공
{ "success": true, "data": { /* 응답 본문 */ } }

// 실패
{ "success": false, "error": { "code": "MEAL_NOT_FOUND", "message": "식단을 찾을 수 없습니다." } }
```

### 1.4 공통 에러 코드

| HTTP | code | 설명 |
|------|------|------|
| 400 | `INVALID_INPUT` | 요청 값 검증 실패 |
| 401 | `UNAUTHORIZED` | 인증 토큰 없음/유효하지 않음 |
| 401 | `TOKEN_EXPIRED` | Access Token 만료 |
| 403 | `FORBIDDEN` | 권한 없음(RBAC 위반) |
| 404 | `NOT_FOUND` | 리소스 없음 |
| 409 | `CONFLICT` | 중복(이메일 중복 등) |
| 422 | `UNPROCESSABLE` | 비즈니스 규칙 위반 |
| 500 | `INTERNAL_ERROR` | 서버 내부 오류 |
| 502 | `AI_UNAVAILABLE` | AI/외부 API 호출 실패 |

### 1.5 권한(RBAC)

| Role | 설명 |
|------|------|
| `USER` | 본인 데이터 CRUD, AI 코치 이용 (현재 핵심 역할) |
| `COACH` 🔵 | 담당 회원 데이터 열람·피드백·목표 설정 — **향후 확장** |
| `ADMIN` 🔵 | 사용자 관리, 코치 승인 — **향후 확장** |

> 🔵 표시(`COACH`/`ADMIN`) 및 "담당 코치" 권한이 있는 엔드포인트(§9 코치, §11 관리자 등)는 실제 코치 도입 시 활성화하는 향후 확장 범위다. 현재 핵심 구현은 `USER` 기준.

### 1.6 페이지네이션 (목록 공통)

- 쿼리: `?page=0&size=20&sort=loggedAt,desc`
- 응답: `{ content: [...], page, size, totalElements, totalPages }`

---

## 2. 인증 / 회원 (Auth & User)

### 2.1 회원가입 — F06 🔴

`POST /api/auth/register` · 인증 불필요

**Request**
```json
{
  "email": "sally@dailyyam.com",
  "password": "Passw0rd!",
  "name": "Sally Choi",
  "heightCm": 167.0,
  "weightKg": 74.2,
  "conditionIds": [1, 3]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| email | string | ✅ | 이메일(중복 불가) |
| password | string | ✅ | 8자 이상 |
| name | string | ✅ | 이름 |
| heightCm | number | ⬜ | 키 |
| weightKg | number | ⬜ | 몸무게 |
| conditionIds | number[] | ⬜ | 보유 질환 ID 목록(F06 질환) |

**Response 201**
```json
{ "success": true, "data": { "userId": 1, "email": "sally@dailyyam.com", "role": "USER" } }
```

**에러**: `409 CONFLICT`(이메일 중복), `400 INVALID_INPUT`

### 2.2 로그인 — F10 🟡

`POST /api/auth/login` · 인증 불필요

**Request**
```json
{ "email": "sally@dailyyam.com", "password": "Passw0rd!" }
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGci...",
    "refreshToken": "eyJhbGci...",
    "user": { "id": 1, "name": "Sally Choi", "role": "USER" }
  }
}
```

**에러**: `401 UNAUTHORIZED`(자격 불일치)

### 2.3 토큰 재발급

`POST /api/auth/refresh` · 인증 불필요

**Request**: `{ "refreshToken": "eyJhbGci..." }`
**Response 200**: `{ "accessToken": "...", "refreshToken": "..." }`
**에러**: `401 UNAUTHORIZED`(refresh 만료/폐기)

### 2.4 로그아웃 — F10

`POST /api/auth/logout` · `USER`/`COACH`/`ADMIN`
Refresh Token 폐기. **Response 200**: `{ "success": true }`

### 2.5 내 정보 조회 — F07 🟡

`GET /api/users/me` · 본인

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": 1, "email": "sally@dailyyam.com", "name": "Sally Choi",
    "role": "USER", "status": "ACTIVE",
    "heightCm": 167.0, "weightKg": 74.2,
    "conditions": [ { "id": 1, "code": "DIABETES", "name": "당뇨" } ]
  }
}
```

### 2.6 내 정보 수정 — F08 🟡

`PUT /api/users/me` · 본인

**Request** (부분 수정 허용)
```json
{ "name": "Sally", "heightCm": 167.0, "weightKg": 73.5, "conditionIds": [1] }
```
**Response 200**: 수정된 사용자 정보

### 2.7 회원 비활성화 / 삭제 — F09 🔴

`PATCH /api/users/me/deactivate` · 본인 — `status`를 `SUSPENDED`로 변경(soft delete)
`DELETE /api/users/me` · 본인 — 완전 삭제(연관 데이터 CASCADE)

**Response 200**: `{ "success": true }`

---

## 3. 질환 (Health Conditions)

### 3.1 질환 마스터 목록 — F06

`GET /api/conditions` · 인증 필요

**Response 200**
```json
{
  "success": true,
  "data": [
    { "id": 1, "code": "DIABETES", "name": "당뇨", "guideline": "당류·정제 탄수화물 제한" },
    { "id": 2, "code": "HYPERTENSION", "name": "고혈압", "guideline": "나트륨 2g/일 이하" }
  ]
}
```

> 회원의 질환 등록/수정은 §2.6 `PUT /api/users/me`의 `conditionIds`로 처리.

---

## 4. 식단 (Meal)

### 4.1 식단 작성 — F01 🟡

> **흐름(사진 필수)**: 사용자는 식단 작성 시 **반드시 음식 사진을 업로드**한다.
> 1. **AI 분석(선행, §5.1)** — 업로드한 사진을 AI가 분석해 음식·영양·항목 **초안**을 생성·표시(저장 전).
> 2. **사용자 수정** — 화면에서 항목/중량/메모 등 초안을 자유롭게 수정.
> 3. **최종 등록(본 API)** — 수정된 내용 + 사진을 함께 전송하여 확정 저장.
>
> 즉 사진 없는 순수 수동 입력만으로는 식단을 작성할 수 없으며, **사진 업로드 → AI 분석 → 수정 → 저장**이 정규 경로다.

`POST /api/meals` · 본인 · `multipart/form-data` (이미지 **필수**)

**Request** — `multipart/form-data` 두 파트
- `image`: 음식 사진 파일 (**필수**)
- `data`: 아래 JSON (수정 완료된 식단 내용)

**`data` (application/json)**
```json
{
  "mealType": "LUNCH",
  "loggedAt": "2026-06-22T12:45:00+09:00",
  "memo": "샐러드 위주",
  "analysisId": "a1b2c3",
  "items": [
    { "foodId": 1024, "foodName": "현미밥", "quantity": 200, "unit": "G", "source": "MANUAL" },
    { "foodId": null, "foodName": "닭가슴살 구이", "quantity": 150, "unit": "G", "source": "AI" }
  ]
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| image | file | ✅ | 음식 사진(필수). 미첨부 시 `400 IMAGE_REQUIRED` |
| mealType | enum | ✅ | `BREAKFAST`/`LUNCH`/`DINNER`/`SNACK` |
| loggedAt | datetime | ✅ | 식사 시각 |
| memo | string | ⬜ | 메모 |
| analysisId | string | ⬜ | §5.1 AI 분석 결과 식별자(분석→저장 추적, AI 수정률 KPI용) |
| items[].foodId | number | ⬜ | 식약처 음식 마스터 ID(선택 시), 수동입력은 null |
| items[].foodName | string | ✅ | 음식명 |
| items[].quantity | number | ✅ | 수량/중량 |
| items[].unit | enum | ✅ | `G`/`ML`/`EA`/`SERVING` |
| items[].source | enum | ✅ | `AI`(AI 초안 유지) / `MANUAL`(사용자가 추가·수정) |

> `items`는 AI 초안을 사용자가 수정한 **최종 상태**다. AI가 제시한 항목을 그대로 두면 `source=AI`, 사용자가 바꾸거나 추가하면 `source=MANUAL`로 보내 AI 정확도(수정률)를 측정한다.

**Response 201**
```json
{ "success": true, "data": { "mealId": 555, "score": { "totalScore": 82.5, "grade": "B" } } }
```
> 저장 시 사진을 S3에 업로드(`meal_items.photo_url`)하고 영양 계산(`nutrition_records`) + 점수 산출(`diet_scores`)을 동기 수행.

**에러**: `400 IMAGE_REQUIRED`(사진 미첨부), `400 INVALID_INPUT`

### 4.2 식단 목록 조회 — F02 🟡

`GET /api/meals?date=2026-06-22` · 본인 (또는 코치가 `?memberId=` 지정)

**Response 200**
```json
{
  "success": true,
  "data": {
    "date": "2026-06-22",
    "totalCalories": 1100,
    "meals": [
      {
        "id": 555, "mealType": "LUNCH", "loggedAt": "2026-06-22T12:45:00+09:00",
        "foodName": "소고기 퀴노아 샐러드 볼",
        "calories": 680, "protein": 38, "carbs": 65, "fat": 26,
        "tags": ["균형 잡힌"], "imageUrl": "https://.../m555.jpg",
        "score": { "totalScore": 82.5, "grade": "B" }
      }
    ]
  }
}
```

### 4.3 식단 상세 조회 — F02 🟡

`GET /api/meals/{id}` · 본인/담당 코치

**Response 200**
```json
{
  "success": true,
  "data": {
    "id": 555, "mealType": "LUNCH", "memo": "샐러드 위주",
    "loggedAt": "2026-06-22T12:45:00+09:00", "imageUrl": "https://.../m555.jpg",
    "items": [
      {
        "id": 9001, "foodId": 1024, "foodName": "현미밥", "quantity": 200, "unit": "G",
        "source": "MANUAL",
        "nutrition": { "calories": 220, "protein": 4, "carbs": 48, "fat": 1, "sodium": 3 }
      }
    ],
    "total": { "calories": 680, "protein": 38, "carbs": 65, "fat": 26 },
    "score": { "totalScore": 82.5, "grade": "B", "goalScore": 85, "conditionScore": 78, "balanceScore": 84, "comment": "단백질 우수, 나트륨 주의" }
  }
}
```
**에러**: `404 NOT_FOUND`, `403 FORBIDDEN`(담당 아닌 코치)

### 4.4 식단 수정 — F03 🔴

`PUT /api/meals/{id}` · 본인

**Request**: §4.1과 동일 구조(항목 전체 치환)
**Response 200**: 수정된 식단 + 재산출된 점수
> 수정 시 `nutrition_records`·`diet_scores` 재계산.

### 4.5 식단 삭제 — F04 🔴

`DELETE /api/meals/{id}` · 본인

**Response 200**: `{ "success": true }`
> 연관 `meal_items`·`nutrition_records`·`diet_scores` CASCADE 삭제.

---

## 5. AI 분석 (AI Analysis)

### 5.1 사진 식단 분석 — F16 🟡

> **식단 작성(§4.1)의 필수 선행 단계.** 사용자가 업로드한 사진을 AI가 분석해 식단 **초안**을 만들어 화면에 표시한다. 사용자는 이 초안을 수정한 뒤 §4.1로 최종 등록한다.

`POST /api/meals/analyze` · 본인

**Request**
```json
{ "base64Image": "data:image/jpeg;base64,...", "imageMimeType": "image/jpeg" }
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "analysisId": "a1b2c3",
    "foodName": "닭가슴살 구이와 현미밥",
    "calories": 485, "protein": 32, "carbs": 54, "fat": 12,
    "items": [ { "name": "닭가슴살 구이", "weight": "150g", "calories": 245 } ],
    "tags": ["고단백", "저지방"],
    "insight": "단백질이 잘 갖춰진 식사입니다."
  }
}
```
> AI 결과는 **확정 저장 아님(초안)** — 사용자가 확인/수정 후 §4.1로 저장한다. 응답의 `analysisId`를 §4.1 저장 요청에 전달해 분석→등록을 연결한다(AI 수정률 KPI).
> 구현: **Spring AI 멀티모달(Claude via GMS)** — 이미지를 `ChatModel`에 첨부해 구조화 출력으로 분석. `GMS_KEY` 미설정 시 Mock 응답, 호출 실패 시 `502 AI_UNAVAILABLE` 대신 fallback Mock 반환.

### 5.2 칼로리 추정

`POST /api/calories/estimate` · 본인
**Request**: `{ "name": "식빵", "weight": "60g" }`
**Response 200**: `{ "calories": 150, "method": "AI" }`

### 5.3 AI 코치 대화 — F17 🟡

`POST /api/ai-coach/messages` · 본인 — 사용자 메시지 전송 → AI 코치 답변

**Request**
```json
{ "content": "오늘 점심 균형 어땠어요?" }
```

**Response 200**
```json
{
  "success": true,
  "data": {
    "reply": "점심에 단백질이 충분했고 나트륨이 조금 높았어요. 저녁엔 채소를 늘려보세요.",
    "refType": "SCORE", "refId": 555
  }
}
```
> AI 응답은 사용자의 식단·`diet_scores`·`user_conditions`를 컨텍스트로 생성. 키 미설정 시 Mock 응답.

### 5.4 AI 코치 대화 내역 — F17 🟡

`GET /api/ai-coach/messages?page=0&size=20` · 본인 — `ai_coach_messages` 시간순 조회

---

## 6. 영양 / 음식 DB (Nutrition & Foods)

### 6.1 음식 검색 (식약처 DB) — F01 🔴

`GET /api/foods?keyword=현미밥&page=0&size=20` · 인증 필요

**Response 200**
```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1024, "name": "현미밥", "dbSource": "MFDS",
        "servingSize": 100, "servingUnit": "G",
        "calories": 110, "protein": 2, "carbs": 24, "fat": 0.5, "sodium": 1.5
      }
    ],
    "page": 0, "totalElements": 37
  }
}
```
> Redis 캐시 우선, miss 시 외부 식약처 API 조회 후 `foods` upsert(lazy).

### 6.2 음식 상세

`GET /api/foods/{id}` · 인증 필요 — 단일 음식 영양 정보(기준 제공량당)

---

## 7. 점수 산출 (Diet Score)

### 7.1 식단 점수 조회 — F05 🟡

`GET /api/meals/{id}/score` · 본인/담당 코치

**Response 200**
```json
{
  "success": true,
  "data": {
    "logId": 555, "totalScore": 82.5, "grade": "B",
    "goalScore": 85, "conditionScore": 78, "balanceScore": 84,
    "comment": "단백질 섭취 우수. 고혈압 가이드 대비 나트륨이 다소 높습니다.",
    "calcSource": "RULE"
  }
}
```

### 7.2 일일 종합 점수 — F05

`GET /api/score/daily?date=2026-06-22` · 본인/담당 코치
하루 식사 점수의 가중 평균 + 목표/질환 부합 요약 반환.

> 점수 산출 입력: 영양 합계 + `daily_goals` + `user_conditions`/`health_conditions.guideline` + 국민건강통계 기준. `calcSource`=`RULE`(기본)/`AI`(심화).

---

## 8. 목표 / 통계 (Goals & Stats)

### 8.1 목표 조회/설정

`GET /api/goals?date=2026-06-22` · 본인/담당 코치
`PUT /api/goals` · 본인 또는 담당 코치(`setBy` 기록)

**Request (PUT)**
```json
{ "goalDate": "2026-06-22", "targetCalories": 2100, "targetProtein": 120, "targetCarbs": 260, "targetFat": 65 }
```

### 8.2 신체 통계 조회/수정

`GET /api/stats` · 본인
`PUT /api/stats` · 본인
**Request (PUT)**: `{ "currentWeight": 73.5 }` → `previousWeight` 자동 보존, `bmi` 재계산

### 8.3 주간/월간 통계

`GET /api/stats/trend?period=WEEK` · 본인/담당 코치
**Response**: 일자별 칼로리·탄단지·점수 배열(차트용)

### 8.4 대시보드 통합 조회

`GET /api/dashboard` · 본인
**Response**: 오늘 식사 + 목표 + 신체통계 + 일일 점수 통합(프론트 DashboardView 대응)

---

## 9. 코치 (Coach)

> 🔵 **향후 확장** — 실제(인간) 코치 도입 시 구현. `COACH` Role + 대상 회원과 `coach_members.status='ACTIVE'` 매핑 필수, 위반 시 `403 FORBIDDEN`. AI 코치는 §5.3 참조.

| 엔드포인트 | 설명 | 요구사항 |
|-----------|------|----------|
| `GET /api/coach/members` | 담당 회원 목록(이름·최근 점수·주의 여부) | F19 |
| `GET /api/coach/members/{memberId}/meals` | 회원 식단 열람(§4.2 위임, 매핑 검증) | F19 |
| `POST /api/coach/feedback` | 코치 수동 피드백 작성 | F19 |
| `GET /api/feedback?memberId=` | 피드백 조회(회원/담당 코치) | F19 |
| `PUT /api/coach/members/{memberId}/goals` | 회원 목표 설정(`setBy`=코치) | F19 |
| `POST /api/coach/chat`, `GET /api/coach/chat` | 코치-회원 양방향 채팅 | F20 |

---

## 10. 알림 (Notifications)

### 10.1 알림 목록

`GET /api/notifications?unread=true` · 본인

**Response 200**
```json
{
  "success": true,
  "data": [
    { "id": 7, "type": "AI_FEEDBACK", "message": "AI 코치의 새 피드백이 도착했어요", "refId": 88, "isRead": false, "createdAt": "..." }
  ]
}
```

### 10.2 읽음 처리

`PATCH /api/notifications/{id}/read` · 본인

> 인앱 알림은 조회 시점 확인. **실시간 WebSocket 푸시(`WS /ws/notifications`)는 향후 확장**(실제 코치 피드백 푸시와 함께 도입).

---

## 11. 관리자 (Admin)

> 🔵 **향후 확장** — 실제 코치 도입 시 구현. 모두 `ADMIN` Role 필수.

| 엔드포인트 | 설명 | 요구사항 |
|-----------|------|----------|
| `GET /api/admin/coach-applications?status=` | 코치 신청 목록 | F18 |
| `PATCH /api/admin/coach-applications/{id}` | 코치 승인/반려 (승인 시 `role=COACH`) | F18 |
| `GET /api/admin/users` · `PATCH /api/admin/users/{id}/status` | 사용자 관리(활성/정지) | F18 |

---

> 엔드포인트별 요구사항 매핑·구현 우선순위는 [요구사항정의서.md](요구사항정의서.md) §3·§7 참조.
