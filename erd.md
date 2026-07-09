# dailyYam — ERD (Entity Relationship Diagram)

> 데이터베이스: MySQL 8 / 매핑: MyBatis
> dailyYam 데이터 모델. [요구사항정의서.md](요구사항정의서.md)의 기능을 충족하도록 설계되었다.
> 🔵 **향후 확장**(실제 코치) 표시 테이블은 AI 코치 검증 후 단계로, 초기 구현 범위에서 제외 가능하다.

---

## 목차

1. [ERD 다이어그램](#1-erd-다이어그램)
2. [테이블 상세 정의](#2-테이블-상세-정의)
3. [관계 요약](#3-관계-요약)
4. [설계 노트](#4-설계-노트)

---

## 1. ERD 다이어그램

```mermaid
erDiagram
    users ||--o{ refresh_tokens : "발급"
    users ||--o{ meal_logs : "기록"
    users ||--o{ daily_goals : "설정"
    users ||--|| user_stats : "보유"
    users ||--o{ notifications : "수신"
    users ||--o{ user_conditions : "질환보유"
    health_conditions ||--o{ user_conditions : "분류"
    meal_logs ||--|| diet_scores : "점수산출"
    users ||--o{ ai_coach_messages : "AI코치 대화"

    %% ===== 향후 확장 (실제 코치) =====
    users ||--o{ coach_members : "코치(coach_id)"
    users ||--o{ coach_members : "회원(member_id)"
    users ||--o{ coach_applications : "신청"

    meal_logs ||--o{ meal_items : "포함"
    foods ||--o{ meal_items : "참조"
    meal_items ||--|| nutrition_records : "영양정보"

    coach_members ||--o{ feedback_notes : "피드백"
    meal_logs ||--o{ feedback_notes : "참조(log_id)"

    coach_members ||--|| chat_rooms : "채팅방"
    chat_rooms ||--o{ chat_messages : "메시지"
    users ||--o{ chat_messages : "발신(sender_id)"
    feedback_notes ||--o| chat_messages : "피드백카드"

    users {
        bigint id PK
        varchar email UK
        varchar password_hash
        varchar name
        varchar role "USER|COACH|ADMIN"
        varchar status "ACTIVE|PENDING|SUSPENDED"
        varchar oauth_provider "null|google|kakao"
        varchar oauth_id
        decimal height_cm
        decimal weight_kg
        timestamp created_at
        timestamp updated_at
    }

    refresh_tokens {
        bigint id PK
        bigint user_id FK
        varchar token UK
        timestamp expires_at
        timestamp created_at
    }

    health_conditions {
        bigint id PK
        varchar code UK "DIABETES|HYPERTENSION|..."
        varchar name "당뇨|고혈압|..."
        text guideline "권장/주의 영양 가이드"
        timestamp created_at
    }

    user_conditions {
        bigint id PK
        bigint user_id FK
        bigint condition_id FK
        text memo "사용자 메모(선택)"
        timestamp created_at
    }

    diet_scores {
        bigint id PK
        bigint log_id FK UK
        bigint user_id FK
        decimal total_score "0~100"
        varchar grade "A|B|C|D"
        decimal goal_score "목표 부합 점수"
        decimal condition_score "질환 적합 점수"
        decimal balance_score "영양 균형 점수"
        text comment "산출 코멘트"
        varchar calc_source "RULE|AI"
        timestamp created_at
    }

    coach_applications {
        bigint id PK
        bigint user_id FK
        text reason
        varchar status "PENDING|APPROVED|REJECTED"
        bigint reviewed_by FK "admin user_id"
        timestamp reviewed_at
        timestamp created_at
    }

    coach_members {
        bigint id PK
        bigint coach_id FK
        bigint member_id FK
        varchar status "ACTIVE|PENDING|TERMINATED"
        timestamp created_at
        timestamp updated_at
    }

    meal_logs {
        bigint id PK
        bigint user_id FK
        varchar meal_type "BREAKFAST|LUNCH|DINNER|SNACK"
        text memo
        timestamp logged_at
        timestamp created_at
        timestamp updated_at
    }

    meal_items {
        bigint id PK
        bigint log_id FK
        bigint food_id FK "nullable, foods 매칭 시"
        varchar food_name
        decimal quantity
        varchar unit "g|ml|개|인분"
        varchar photo_url
        varchar source "AI|MANUAL"
        timestamp created_at
    }

    foods {
        bigint id PK
        varchar db_source "MFDS|USDA|OFF"
        varchar external_id "외부DB 식품코드"
        varchar name
        decimal serving_size "기준 제공량"
        varchar serving_unit "g|ml"
        decimal calories
        decimal protein
        decimal carbs
        decimal fat
        decimal sodium
        timestamp created_at
        timestamp updated_at
    }

    nutrition_records {
        bigint id PK
        bigint item_id FK
        decimal calories
        decimal protein
        decimal carbs
        decimal fat
        decimal sodium
        varchar db_source "MFDS|USDA|OFF"
        timestamp created_at
    }

    daily_goals {
        bigint id PK
        bigint user_id FK
        date goal_date
        decimal target_calories
        decimal target_protein
        decimal target_carbs
        decimal target_fat
        bigint set_by FK "본인 또는 코치 user_id"
        timestamp created_at
    }

    user_stats {
        bigint id PK
        bigint user_id FK UK
        decimal current_weight
        decimal previous_weight
        decimal bmi
        decimal progress_rate
        timestamp updated_at
    }

    feedback_notes {
        bigint id PK
        bigint coach_id FK
        bigint member_id FK
        bigint log_id FK "nullable"
        varchar title
        text content
        text tip
        boolean is_read
        timestamp created_at
    }

    notifications {
        bigint id PK
        bigint user_id FK
        varchar type "FEEDBACK|MEAL_SAVED|GOAL_UPDATED"
        varchar message
        bigint ref_id "관련 엔티티 id"
        boolean is_read
        timestamp created_at
    }

    ai_coach_messages {
        bigint id PK
        bigint user_id FK
        varchar role "USER|AI"
        text content
        varchar ref_type "SCORE|MEAL|null"
        bigint ref_id "nullable"
        timestamp created_at
    }

    chat_rooms {
        bigint id PK
        bigint coach_member_id FK UK
        varchar last_message
        timestamp last_message_at
        timestamp created_at
    }

    chat_messages {
        bigint id PK
        bigint room_id FK
        bigint sender_id FK
        text content "nullable"
        boolean is_feedback_card
        bigint feedback_id FK "nullable"
        boolean is_read
        timestamp created_at
    }
```

---

## 2. 테이블 상세 정의

### 2.1 `users` — 회원 / 코치 / 관리자

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | 사용자 고유 ID |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL | 로그인 이메일 |
| `password_hash` | VARCHAR(255) | NULL 허용 | BCrypt 해시 (소셜 로그인 시 NULL) |
| `name` | VARCHAR(100) | NOT NULL | 사용자 이름 |
| `role` | VARCHAR(20) | NOT NULL, DEFAULT 'USER' | `USER`(핵심) / `COACH` · `ADMIN`(🔵 향후) |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'ACTIVE' | `ACTIVE` / `PENDING` / `SUSPENDED` |
| `oauth_provider` | VARCHAR(20) | NULL | `google` / `kakao` / NULL |
| `oauth_id` | VARCHAR(255) | NULL | 소셜 제공자 사용자 ID |
| `height_cm` | DECIMAL(5,2) | NULL | 키 (BMI 계산용) |
| `weight_kg` | DECIMAL(5,2) | NULL | 몸무게 (가입 시 초기값) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 생성 시각 |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | 수정 시각 |

- 인덱스: `idx_users_email (email)`, `idx_users_role_status (role, status)`
- 현재 핵심 구현은 `role='USER'`만 사용. `COACH`/`ADMIN`(코치 가입 시 `PENDING` 승인 대기)은 향후 확장에서 활성화.

### 2.2 `refresh_tokens` — JWT Refresh Token

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 토큰 소유자 |
| `token` | VARCHAR(512) | UNIQUE, NOT NULL | Refresh Token 값(또는 해시) |
| `expires_at` | TIMESTAMP | NOT NULL | 만료 시각 (refresh-expiry 604800s) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_refresh_user (user_id)`
- 로그아웃/재발급 시 해당 row 삭제 또는 회전(rotation).

### 2.2a `health_conditions` — 질환 마스터 (F06/F05)

> 회원 프로필의 질환(질병) 분류 마스터. 점수 산출(F05) 시 질환별 영양 가이드라인의 기준이 된다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `code` | VARCHAR(40) | UNIQUE, NOT NULL | `DIABETES` / `HYPERTENSION` / `KIDNEY` / `OBESITY` 등 |
| `name` | VARCHAR(100) | NOT NULL | 표시명 (당뇨, 고혈압 등) |
| `guideline` | TEXT | NULL | 권장/주의 영양 가이드 (예: 고혈압→나트륨 제한) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 국민건강통계·식약처 가이드 기준으로 초기 더미 데이터 적재(seed).
- 점수 산출 시 `guideline`을 룰 엔진/AI 프롬프트의 입력으로 활용.

### 2.2b `user_conditions` — 회원-질환 매핑 (F06)

> 회원이 보유한 질환. 프로필(키·몸무게·**질환**) 관리의 질환 부분을 담당. 다대다(회원 N : 질환 N) 매핑.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 회원 |
| `condition_id` | BIGINT | FK → health_conditions.id, NOT NULL | 질환 |
| `memo` | TEXT | NULL | 사용자 입력 메모(선택) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 제약: `UNIQUE (user_id, condition_id)` — 동일 질환 중복 등록 방지
- 인덱스: `idx_user_conditions_user (user_id)`
- 질환이 없는 회원은 row 없음(0개). 프로필 화면에서 다중 선택으로 관리.

### 2.3 `coach_applications` — 코치 신청·승인 워크플로우 🔵 향후 확장

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id | 코치 신청자 |
| `reason` | TEXT | NULL | 신청 사유 / 자격 |
| `status` | VARCHAR(20) | DEFAULT 'PENDING' | `PENDING` / `APPROVED` / `REJECTED` |
| `reviewed_by` | BIGINT | FK → users.id, NULL | 검토한 관리자 |
| `reviewed_at` | TIMESTAMP | NULL | 검토 시각 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 승인 시 `users.role`을 `COACH`, `users.status`를 `ACTIVE`로 갱신.

### 2.4 `coach_members` — 코치-회원 매핑 🔵 향후 확장

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `coach_id` | BIGINT | FK → users.id, NOT NULL | 코치 |
| `member_id` | BIGINT | FK → users.id, NOT NULL | 회원 |
| `status` | VARCHAR(20) | DEFAULT 'PENDING' | `ACTIVE` / `PENDING` / `TERMINATED` |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 제약: `UNIQUE (coach_id, member_id)` — 중복 매핑 방지
- 인덱스: `idx_cm_coach (coach_id, status)`, `idx_cm_member (member_id, status)`
- `status='TERMINATED'`이면 코치의 회원 데이터 접근 즉시 차단 (서비스 레이어에서 검증).

### 2.5 `meal_logs` — 식사 기록

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 기록 소유자 |
| `meal_type` | VARCHAR(20) | NOT NULL | `BREAKFAST` / `LUNCH` / `DINNER` / `SNACK` |
| `memo` | TEXT | NULL | 메모 |
| `logged_at` | TIMESTAMP | NOT NULL | 식사 시각 (사용자 지정) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_meal_logs_user_date (user_id, logged_at)` — 일/주/월 통계 조회 최적화
- 삭제 시 `meal_items` → `nutrition_records` CASCADE 정리.

### 2.6 `meal_items` — 식사 항목 (개별 음식)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `log_id` | BIGINT | FK → meal_logs.id, NOT NULL | 소속 식사 기록 |
| `food_id` | BIGINT | FK → foods.id, NULL | 영양 마스터 매칭 (매칭 실패/순수 수동 입력 시 NULL) |
| `food_name` | VARCHAR(200) | NOT NULL | 음식 이름 (표시용 스냅샷, foods.name과 다를 수 있음) |
| `quantity` | DECIMAL(7,2) | NOT NULL | 수량/중량 값 |
| `unit` | VARCHAR(20) | NOT NULL | `g` / `ml` / `개` / `인분` |
| `photo_url` | VARCHAR(512) | NULL | S3 서명 URL (사진 기록 시) |
| `source` | VARCHAR(10) | DEFAULT 'MANUAL' | `AI` / `MANUAL` (AI 수정률 KPI 측정용) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- `food_id`로 영양 마스터를 참조하되, `food_name`은 기록 시점 스냅샷으로 보존(마스터 갱신·삭제와 무관하게 기록 유지).

### 2.7a `foods` — 음식 영양 마스터 (외부 DB 정규화 캐시)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `db_source` | VARCHAR(10) | NOT NULL | `MFDS`(식약처) / `USDA` / `OFF` |
| `external_id` | VARCHAR(100) | NOT NULL | 외부 DB 식품 코드 |
| `name` | VARCHAR(200) | NOT NULL | 식품명 |
| `serving_size` | DECIMAL(7,2) | NOT NULL | 기준 제공량 (예: 100) |
| `serving_unit` | VARCHAR(20) | NOT NULL, DEFAULT 'g' | `g` / `ml` |
| `calories` | DECIMAL(7,2) | | 기준 제공량당 kcal |
| `protein` | DECIMAL(6,2) | | 기준 제공량당 단백질 g |
| `carbs` | DECIMAL(6,2) | | 기준 제공량당 탄수화물 g |
| `fat` | DECIMAL(6,2) | | 기준 제공량당 지방 g |
| `sodium` | DECIMAL(7,2) | NULL | 기준 제공량당 나트륨 mg |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 제약: `UNIQUE (db_source, external_id)` — 동일 외부 식품 중복 저장 방지
- 인덱스: `idx_foods_name (name)` — 수동 입력 시 음식명 검색용
- **저장 전략**: 외부 영양 DB 조회 시 Redis 캐시 → miss이면 외부 API 호출 → `foods`에 upsert 후 사용. 한 번 정규화하면 동일 식품 재호출 불필요.
- **기준 제공량당 값 저장**: 실제 섭취량(`meal_items.quantity`) 비례 스케일링은 `nutrition_records`에 확정값으로 저장.

### 2.7 `nutrition_records` — 영양 정보 (항목별 1:1)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `item_id` | BIGINT | FK → meal_items.id, UNIQUE | 1:1 매핑 |
| `calories` | DECIMAL(7,2) | NOT NULL | kcal |
| `protein` | DECIMAL(6,2) | | 단백질 g |
| `carbs` | DECIMAL(6,2) | | 탄수화물 g |
| `fat` | DECIMAL(6,2) | | 지방 g |
| `sodium` | DECIMAL(7,2) | NULL | 나트륨 mg |
| `db_source` | VARCHAR(10) | | `MFDS`(식약처) / `USDA` / `OFF`(Open Food Facts) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 분량 기반 스케일링 결과를 저장: `foods`의 기준 제공량당 값 × (`meal_items.quantity` / `foods.serving_size`)로 계산한 **확정값**.
- `foods` 마스터가 없는 순수 수동 입력(`food_id` NULL)은 사용자가 직접 입력한 영양값을 그대로 저장.

### 2.7b `diet_scores` — 식단 점수 산출 결과 (F05) 🔴 필수

> 명세서 필수 기능: "목표(건강/질병/다이어트)에 맞게 식단을 분석하여 **점수를 산출**". 식사 기록 1건당 점수 1건(1:1).

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `log_id` | BIGINT | FK → meal_logs.id, UNIQUE | 대상 식사 기록 (1:1) |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 조회 최적화용 비정규화 |
| `total_score` | DECIMAL(5,2) | NOT NULL | 종합 점수 0~100 |
| `grade` | VARCHAR(2) | | 등급 `A` / `B` / `C` / `D` |
| `goal_score` | DECIMAL(5,2) | NULL | 목표(칼로리·탄단지) 부합 점수 |
| `condition_score` | DECIMAL(5,2) | NULL | 질환 적합 점수 (user_conditions 기반) |
| `balance_score` | DECIMAL(5,2) | NULL | 영양 균형 점수 |
| `comment` | TEXT | NULL | 점수 산출 코멘트/근거 |
| `calc_source` | VARCHAR(10) | DEFAULT 'RULE' | `RULE`(국민건강통계 기준 룰) / `AI` |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_diet_scores_user (user_id, created_at)` — 점수 추이 통계용
- **산출 입력**: 식사 영양 합계(`nutrition_records`) + 목표(`daily_goals`) + 질환(`user_conditions`/`health_conditions.guideline`) + 국민건강통계 기준치.
- **산출 방식**: 1차 룰 기반(`RULE`) 점수, 심화로 생성형 AI 보정(`AI`) 가능. `total_score`는 세 하위 점수의 가중 합으로 계산.
- 식사 기록 수정(F03) 시 재계산하여 갱신, 삭제(F04) 시 CASCADE.

### 2.8 `daily_goals` — 일일 목표 (이력 관리)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 대상 회원 |
| `goal_date` | DATE | NOT NULL | 적용 일자 |
| `target_calories` | DECIMAL(7,2) | | 목표 칼로리 |
| `target_protein` | DECIMAL(6,2) | | 목표 단백질 |
| `target_carbs` | DECIMAL(6,2) | | 목표 탄수화물 |
| `target_fat` | DECIMAL(6,2) | | 목표 지방 |
| `set_by` | BIGINT | FK → users.id | 본인 또는 담당 코치 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 제약: `UNIQUE (user_id, goal_date)` — 날짜별 1개 목표
- 현재는 본인이 목표 설정. `set_by`는 변경 주체 추적용(향후 코치가 회원 목표 수정 시 활용).

### 2.9 `user_stats` — 사용자 신체 통계 (1:1)

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, UNIQUE | 1:1 |
| `current_weight` | DECIMAL(5,2) | | 현재 체중 |
| `previous_weight` | DECIMAL(5,2) | | 이전 체중 (감량 추이) |
| `bmi` | DECIMAL(4,2) | | 신체질량지수 |
| `progress_rate` | DECIMAL(5,2) | | 목표 달성률 % |
| `updated_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

### 2.10 `feedback_notes` — 코치 수동 피드백 🔵 향후 확장

> 실제(인간) 코치가 작성하는 피드백. AI 코치 피드백은 `ai_coach_messages`(§2.11a)에 저장한다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `coach_id` | BIGINT | FK → users.id, NOT NULL | 작성 코치 |
| `member_id` | BIGINT | FK → users.id, NOT NULL | 대상 회원 |
| `log_id` | BIGINT | FK → meal_logs.id, NULL | 참조 식사 기록(선택) |
| `title` | VARCHAR(200) | | 피드백 제목 |
| `content` | TEXT | NOT NULL | 피드백 내용 |
| `tip` | TEXT | NULL | 개선 팁 (ChatFeedback.tip 대응) |
| `is_read` | BOOLEAN | DEFAULT false | 회원 열람 여부 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_feedback_member (member_id, created_at)`

### 2.11 `notifications` — 인앱 알림

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 수신자 |
| `type` | VARCHAR(20) | NOT NULL | `AI_FEEDBACK` / `MEAL_SAVED` / `GOAL_UPDATED` |
| `message` | VARCHAR(255) | | 알림 본문 |
| `ref_id` | BIGINT | NULL | 관련 엔티티 id |
| `is_read` | BOOLEAN | DEFAULT false | |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_noti_user_unread (user_id, is_read)`
- AI 코치 피드백·식단 저장 등 이벤트의 인앱 알림. 실시간 WebSocket 푸시는 향후 확장(현재는 조회 시점 확인).

### 2.11a `ai_coach_messages` — AI 코치 대화 (F17)

> AI 코치와의 채팅·피드백 메시지. 사용자 메시지와 AI 응답을 시간순으로 저장한다.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `user_id` | BIGINT | FK → users.id, NOT NULL | 대화 소유자 |
| `role` | VARCHAR(10) | NOT NULL | `USER`(사용자) / `AI`(AI 코치) |
| `content` | TEXT | NOT NULL | 메시지 본문 |
| `ref_type` | VARCHAR(10) | NULL | 참조 대상 `SCORE` / `MEAL` / NULL |
| `ref_id` | BIGINT | NULL | 참조 엔티티 id (점수·식사 등) |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_ai_coach_user (user_id, created_at)`
- AI 응답은 사용자의 식단·`diet_scores`·`user_conditions`를 컨텍스트로 생성(`ref_type`/`ref_id`로 근거 추적).

### 2.12 `chat_rooms` — 코치-회원 채팅방 🔵 향후 확장

> 실제 코치와의 양방향 채팅. AI 코치 검증 후 착수.

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `coach_member_id` | BIGINT | FK → coach_members.id, UNIQUE | 매핑당 1개 채팅방 |
| `last_message` | VARCHAR(255) | NULL | 목록 미리보기용 마지막 메시지 |
| `last_message_at` | TIMESTAMP | NULL | 정렬용 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 채팅방은 코치-회원 매핑(`coach_members`)에 종속 → 매핑 해지 시 채팅방도 비활성/정리.

### 2.13 `chat_messages` — 채팅 메시지 🔵 향후 확장

| 컬럼 | 타입 | 제약 | 설명 |
|------|------|------|------|
| `id` | BIGINT AUTO_INCREMENT | PK | |
| `room_id` | BIGINT | FK → chat_rooms.id, NOT NULL | 소속 채팅방 |
| `sender_id` | BIGINT | FK → users.id, NOT NULL | 발신자(코치 또는 회원) |
| `content` | TEXT | NULL | 텍스트 메시지 (피드백 카드면 NULL 가능) |
| `is_feedback_card` | BOOLEAN | DEFAULT false | 피드백 카드 메시지 여부 (`ChatMessage.isFeedbackCard` 대응) |
| `feedback_id` | BIGINT | FK → feedback_notes.id, NULL | 카드형 메시지가 참조하는 피드백 |
| `is_read` | BOOLEAN | DEFAULT false | 상대방 열람 여부 |
| `created_at` | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | |

- 인덱스: `idx_chat_msg_room (room_id, created_at)`
- 프론트 `ChatMessage` 타입의 `isFeedbackCard`/`feedback`을 `is_feedback_card` + `feedback_id` 참조로 표현.

---

## 3. 관계 요약

| 부모 | 자식 | 관계 | 비고 |
|------|------|------|------|
| users | refresh_tokens | 1:N | 토큰 발급 |
| users | meal_logs | 1:N | 식사 기록 |
| users | daily_goals | 1:N | 날짜별 목표 |
| users | user_stats | 1:1 | 신체 통계 |
| users | notifications | 1:N | 인앱 알림 |
| users | user_conditions | 1:N | 보유 질환 |
| health_conditions | user_conditions | 1:N | 질환 마스터 |
| users | ai_coach_messages | 1:N | AI 코치 대화 |
| meal_logs | meal_items | 1:N | 식사 항목 |
| foods | meal_items | 1:N | 영양 마스터 참조 |
| meal_items | nutrition_records | 1:1 | 영양 정보(확정값) |
| meal_logs | diet_scores | 1:1 | 식단 점수 산출 결과 |

**향후 확장 (실제 코치)**

| 부모 | 자식 | 관계 | 비고 |
|------|------|------|------|
| users | coach_applications | 1:N | 코치 신청·승인 |
| users | coach_members | 1:N (coach/member 각각) | 자기참조 매핑 |
| coach_members | feedback_notes | 1:N | 코치 수동 피드백 |
| meal_logs | feedback_notes | 1:N | 식사 참조 피드백 |
| coach_members | chat_rooms | 1:1 | 양방향 채팅방 |
| chat_rooms | chat_messages | 1:N | 채팅 메시지 |
| feedback_notes | chat_messages | 1:0..1 | 피드백 카드 메시지 |

---

## 4. 설계 노트

**공통**
- enum은 영문 대문자 코드(`BREAKFAST` 등), 화면 표시만 한글 매핑.
- 통계 조회용 `meal_logs(user_id, logged_at)` 복합 인덱스 필수.
- 코치의 회원 데이터 접근은 `coach_members.status='ACTIVE'` JOIN으로 강제.

**foods 음식 마스터**
- `foods`(기준 제공량당 값) ← `meal_items.food_id` 참조, 실제 섭취 확정값은 `nutrition_records`에 저장 (마스터 갱신과 기록 분리).
- `meal_items.food_name`은 기록 시점 스냅샷 → 마스터 변경/삭제와 무관하게 기록 보존.
- 식약처 DB는 전량 적재 대신 조회 시점 lazy upsert(Redis miss → 외부 호출 → 저장).

**점수 산출 (F05)**
- `diet_scores.total_score` = 목표 부합(`goal_score`) + 질환 적합(`condition_score`, `health_conditions.guideline` 기준) + 균형(`balance_score`, 국민건강통계 기준)의 가중 합.
- 1차 룰 기반(`RULE`), 심화에서 AI 보정(`AI`). 식사 수정 시 재계산, 삭제 시 CASCADE.

**AI 코치 (F17, 핵심)**
- AI 코치 대화는 `ai_coach_messages`에 저장. AI 응답은 사용자 식단·`diet_scores`·`user_conditions`를 컨텍스트로 생성.
- 코칭은 별도 코치 계정 없이 동작 → `users.role`은 `USER`만으로 충분.

**향후 확장 (실제 코치)**
- `coach_applications`·`coach_members`·`feedback_notes`·`chat_rooms`·`chat_messages`는 실제(인간) 코치용으로, AI 코치 검증 후 착수. 초기 스키마/구현 범위에서 제외 가능.
- `users.role`의 `COACH`/`ADMIN`, WebSocket 실시간 알림도 이 단계에서 활성화.
