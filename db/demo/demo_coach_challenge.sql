-- dailyYam 시연용 코치 + 챌린지 seed
-- 실행 대상: MySQL / MariaDB
--
-- 생성 계정:
--   코치: coach@ssafy.com  / 비밀번호: Admin1234!  (role=COACH)
--
-- 전제:
--   demo_seed.sql 을 먼저 실행해 example@ssafy.com(데모 사용자)의 식단/점수가 있어야
--   챌린지 진행률(연속 달성)이 의미 있게 보입니다.
--
-- 주의:
--   1. Flyway migration 폴더가 아니라 db/demo 폴더에 둔 수동 실행용 SQL입니다.
--   2. 재실행 시 이 코치(coach@ssafy.com)가 만든 챌린지를 모두 지우고 다시 생성합니다.
--   3. (선택) 데모 사용자의 레벨/경험치/완료이력을 초기화해 "레벨업" 시연을 반복할 수 있게 합니다.

START TRANSACTION;

-- 1) 코치 계정 (없으면 생성, 있으면 COACH 로 승격)
INSERT INTO users (
    email, password_hash, name, role, status, height_cm, weight_kg
) VALUES (
    'coach@ssafy.com',
    '$2a$10$b2o3le6B5wAS6mDRdq5KWOTY42a3BrjTcCRV5STXr.09uKaEgjjVG',  -- Admin1234!
    '김코치',
    'COACH',
    'ACTIVE',
    175.00,
    70.00
) ON DUPLICATE KEY UPDATE
    name   = VALUES(name),
    role   = 'COACH',
    status = 'ACTIVE';

SET @coach_id = (SELECT id FROM users WHERE email = 'coach@ssafy.com');

-- 2) 재실행 대비: 이 코치가 만든 기존 챌린지 + 그 완료이력 제거
--    (user_challenge_completions 는 FK CASCADE 가 없으므로 먼저 지운다)
DELETE FROM user_challenge_completions
WHERE challenge_id IN (SELECT id FROM challenges WHERE created_by = @coach_id);

DELETE FROM challenges WHERE created_by = @coach_id;

-- 3) (선택) 데모 사용자 보상 상태 초기화 — 레벨업 시연을 반복하려면 유지, 아니면 이 블록 삭제
UPDATE users
SET level = 1, exp = 0, completed_challenge_count = 0
WHERE email = 'example@ssafy.com';

DELETE FROM user_challenge_completions
WHERE user_id = (SELECT id FROM users WHERE email = 'example@ssafy.com');

-- 4) 코치가 만든 챌린지 3종
--    기간은 데모 식단 범위(최근 2주)를 포함하도록 CURDATE 기준 상대값으로 설정한다.
INSERT INTO challenges (
    title, description, target_score, consecutive_days, start_date, end_date, created_by, active
) VALUES
    ('꾸준함 챌린지',
     '일별 식단 점수 75점 이상을 3일 연속 달성해보세요.',
     75.00, 3,
     DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
     @coach_id, TRUE),

    ('고득점 챌린지',
     '일별 식단 점수 90점 이상을 5일 연속 달성하면 성공입니다.',
     90.00, 5,
     DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
     @coach_id, TRUE),

    ('균형 식단 챌린지',
     '일별 식단 점수 80점 이상을 7일 연속 유지해보세요.',
     80.00, 7,
     DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
     @coach_id, TRUE);

COMMIT;

-- 실행 후 확인용 쿼리
-- SELECT id, email, name, role FROM users WHERE email = 'coach@ssafy.com';
-- SELECT id, title, target_score, consecutive_days, start_date, end_date, active
--   FROM challenges WHERE created_by = (SELECT id FROM users WHERE email='coach@ssafy.com');
--
-- 데모 사용자로 GET /api/challenges 호출 시:
--   '꾸준함 챌린지'(75점 3일)는 6/23~6/25 연속 달성으로 success=true → 경험치 +100 지급
--   나머지 둘은 진행 중(연속일 부족)으로 표시됩니다.
