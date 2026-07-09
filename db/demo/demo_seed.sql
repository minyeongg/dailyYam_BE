-- dailyYam 시연용 식단 기록 seed
-- 실행 대상: MySQL / MariaDB
-- 계정: example@ssafy.com
-- 비밀번호: Admin1234!
--
-- 주의:
-- 1. 이 파일은 Flyway migration 폴더가 아니라 db/demo 폴더에 둔 수동 실행용 SQL입니다.
-- 2. 재실행 시 example@ssafy.com 계정의 `[DEMO]` 메모가 붙은 식단만 삭제 후 다시 생성합니다.
-- 3. photo_url은 백엔드 정적 서빙 경로(`/uploads/meals/...`)만 넣습니다.
--    실제 이미지가 필요하면 서버의 UPLOAD_DIR 기본값 기준 `dailyyum_back/uploads/meals/`에
--    아래 파일명으로 이미지를 넣어 주세요.

START TRANSACTION;

INSERT INTO users (
    email,
    password_hash,
    name,
    role,
    status,
    height_cm,
    weight_kg
) VALUES (
    'example@ssafy.com',
    '$2a$10$b2o3le6B5wAS6mDRdq5KWOTY42a3BrjTcCRV5STXr.09uKaEgjjVG',
    'ssafy15',
    'USER',
    'ACTIVE',
    167.00,
    73.50
) ON DUPLICATE KEY UPDATE
    password_hash = VALUES(password_hash),
    name = VALUES(name),
    role = 'USER',
    status = 'ACTIVE',
    height_cm = VALUES(height_cm),
    weight_kg = VALUES(weight_kg);

SET @demo_user_id = (SELECT id FROM users WHERE email = 'example@ssafy.com');

DELETE ml
FROM meal_logs ml
WHERE ml.user_id = @demo_user_id
  AND ml.memo LIKE '[DEMO]%';

DELETE FROM daily_goals
WHERE user_id = @demo_user_id
  AND goal_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 20 DAY) AND CURDATE();

INSERT INTO user_stats (
    user_id,
    current_weight,
    previous_weight,
    bmi,
    progress_rate
) VALUES (
    @demo_user_id,
    73.50,
    75.10,
    26.35,
    64.00
) ON DUPLICATE KEY UPDATE
    current_weight = VALUES(current_weight),
    previous_weight = VALUES(previous_weight),
    bmi = VALUES(bmi),
    progress_rate = VALUES(progress_rate);

INSERT INTO daily_goals (
    user_id,
    goal_date,
    target_calories,
    target_protein,
    target_carbs,
    target_fat,
    set_by
)
SELECT
    @demo_user_id,
    DATE_SUB(CURDATE(), INTERVAL day_offset DAY),
    2100.00,
    120.00,
    260.00,
    58.00,
    @demo_user_id
FROM (
    SELECT 0 AS day_offset UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
    UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20
) d
ON DUPLICATE KEY UPDATE
    target_calories = VALUES(target_calories),
    target_protein = VALUES(target_protein),
    target_carbs = VALUES(target_carbs),
    target_fat = VALUES(target_fat),
    set_by = VALUES(set_by);

INSERT INTO foods (
    db_source,
    external_id,
    name,
    serving_size,
    serving_unit,
    calories,
    protein,
    carbs,
    fat,
    sodium
) VALUES
    ('DEMO', 'DEMO-BROWN-RICE', '현미밥', 100.00, 'G', 165.00, 3.60, 34.00, 1.20, 5.00),
    ('DEMO', 'DEMO-GRILLED-CHICKEN', '닭가슴살 구이', 100.00, 'G', 165.00, 31.00, 0.00, 3.60, 74.00),
    ('DEMO', 'DEMO-SALAD', '아보카도 샐러드', 100.00, 'G', 140.00, 3.00, 8.00, 11.00, 180.00),
    ('DEMO', 'DEMO-SALMON', '연어구이', 100.00, 'G', 208.00, 20.00, 0.00, 13.00, 59.00),
    ('DEMO', 'DEMO-TOFU', '두부구이', 100.00, 'G', 110.00, 10.00, 3.00, 7.00, 12.00),
    ('DEMO', 'DEMO-EGG', '삶은 달걀', 50.00, 'G', 78.00, 6.30, 0.60, 5.30, 62.00),
    ('DEMO', 'DEMO-YOGURT', '그릭요거트', 100.00, 'G', 95.00, 9.00, 4.00, 5.00, 36.00),
    ('DEMO', 'DEMO-BANANA', '바나나', 100.00, 'G', 89.00, 1.10, 23.00, 0.30, 1.00),
    ('DEMO', 'DEMO-TTEOKBOKKI', '떡볶이', 100.00, 'G', 230.00, 5.00, 48.00, 2.50, 520.00),
    ('DEMO', 'DEMO-KIMBAP', '참치김밥', 100.00, 'G', 180.00, 7.00, 28.00, 4.50, 420.00),
    ('DEMO', 'DEMO-PORK-RICE', '제육덮밥', 100.00, 'G', 205.00, 8.50, 27.00, 7.00, 480.00),
    ('DEMO', 'DEMO-SOUP', '된장국', 100.00, 'ML', 42.00, 3.10, 5.00, 1.20, 390.00)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    serving_size = VALUES(serving_size),
    serving_unit = VALUES(serving_unit),
    calories = VALUES(calories),
    protein = VALUES(protein),
    carbs = VALUES(carbs),
    fat = VALUES(fat),
    sodium = VALUES(sodium);

-- 오늘: 대시보드 최근 활동/칼로리/탄단지 확인용
INSERT INTO meal_logs (user_id, meal_type, memo, logged_at)
VALUES (@demo_user_id, 'BREAKFAST', '[DEMO] 아침 - 가볍게 단백질 보충', TIMESTAMP(CURDATE(), '08:05:00'));
SET @log_id = LAST_INSERT_ID();
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-YOGURT'), '그릭요거트', 150.00, 'G', '/uploads/meals/demo-breakfast-yogurt.jpg', 'MANUAL'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BANANA'), '바나나', 120.00, 'G', '/uploads/meals/demo-breakfast-yogurt.jpg', 'MANUAL'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-EGG'), '삶은 달걀', 100.00, 'G', '/uploads/meals/demo-breakfast-yogurt.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 142.50, 13.50, 6.00, 7.50, 54.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '그릭요거트'
UNION ALL SELECT id, 106.80, 1.30, 27.60, 0.40, 1.20, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '바나나'
UNION ALL SELECT id, 156.00, 12.60, 1.20, 10.60, 124.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '삶은 달걀';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 91.20, 'A', 92.00, NULL, 90.80, '아침 단백질 구성이 좋아요. 점심에는 복합탄수화물을 보충해 보세요.', 'RULE');

INSERT INTO meal_logs (user_id, meal_type, memo, logged_at)
VALUES (@demo_user_id, 'LUNCH', '[DEMO] 점심 - 현미밥과 닭가슴살 샐러드', TIMESTAMP(CURDATE(), '12:35:00'));
SET @log_id = LAST_INSERT_ID();
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BROWN-RICE'), '현미밥', 180.00, 'G', '/uploads/meals/demo-lunch-chicken-salad.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-GRILLED-CHICKEN'), '닭가슴살 구이', 150.00, 'G', '/uploads/meals/demo-lunch-chicken-salad.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SALAD'), '아보카도 샐러드', 120.00, 'G', '/uploads/meals/demo-lunch-chicken-salad.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 297.00, 6.50, 61.20, 2.20, 9.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '현미밥'
UNION ALL SELECT id, 247.50, 46.50, 0.00, 5.40, 111.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '닭가슴살 구이'
UNION ALL SELECT id, 168.00, 3.60, 9.60, 13.20, 216.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '아보카도 샐러드';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 96.40, 'A', 98.00, NULL, 94.60, '탄수화물과 단백질 균형이 안정적입니다.', 'RULE');

INSERT INTO meal_logs (user_id, meal_type, memo, logged_at)
VALUES (@demo_user_id, 'DINNER', '[DEMO] 저녁 - 연어와 두부 위주', TIMESTAMP(CURDATE(), '18:45:00'));
SET @log_id = LAST_INSERT_ID();
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SALMON'), '연어구이', 140.00, 'G', '/uploads/meals/demo-dinner-salmon.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-TOFU'), '두부구이', 120.00, 'G', '/uploads/meals/demo-dinner-salmon.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SOUP'), '된장국', 180.00, 'ML', '/uploads/meals/demo-dinner-salmon.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 291.20, 28.00, 0.00, 18.20, 82.60, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '연어구이'
UNION ALL SELECT id, 132.00, 12.00, 3.60, 8.40, 14.40, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '두부구이'
UNION ALL SELECT id, 75.60, 5.60, 9.00, 2.20, 702.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '된장국';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 88.70, 'B', 90.00, NULL, 86.30, '단백질은 충분하지만 국물류 나트륨은 조금 줄이면 좋아요.', 'RULE');

-- 최근 2주: 이력/잔디/통계 추세 확인용
INSERT INTO meal_logs (user_id, meal_type, memo, logged_at) VALUES
    (@demo_user_id, 'BREAKFAST', '[DEMO] D-1 아침', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '08:20:00')),
    (@demo_user_id, 'LUNCH', '[DEMO] D-1 점심', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '12:40:00')),
    (@demo_user_id, 'DINNER', '[DEMO] D-2 저녁', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 2 DAY), '19:05:00')),
    (@demo_user_id, 'LUNCH', '[DEMO] D-3 점심', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 3 DAY), '12:20:00')),
    (@demo_user_id, 'SNACK', '[DEMO] D-4 간식', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 4 DAY), '16:10:00')),
    (@demo_user_id, 'DINNER', '[DEMO] D-5 저녁', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 5 DAY), '18:55:00')),
    (@demo_user_id, 'LUNCH', '[DEMO] D-7 점심', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 7 DAY), '12:15:00')),
    (@demo_user_id, 'DINNER', '[DEMO] D-9 저녁', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 9 DAY), '19:25:00')),
    (@demo_user_id, 'BREAKFAST', '[DEMO] D-11 아침', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 11 DAY), '08:15:00')),
    (@demo_user_id, 'LUNCH', '[DEMO] D-13 점심', TIMESTAMP(DATE_SUB(CURDATE(), INTERVAL 13 DAY), '12:30:00'));

-- D-1 아침
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-1 아침' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source)
VALUES (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-YOGURT'), '그릭요거트', 180.00, 'G', '/uploads/meals/demo-yogurt-bowl.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 171.00, 16.20, 7.20, 9.00, 64.80, 'DEMO' FROM meal_items WHERE log_id = @log_id;
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 84.30, 'B', 82.00, NULL, 86.60, '아침 섭취량이 조금 적지만 단백질 선택은 좋아요.', 'RULE');

-- D-1 점심
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-1 점심' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-KIMBAP'), '참치김밥', 260.00, 'G', '/uploads/meals/demo-kimbap.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SOUP'), '된장국', 150.00, 'ML', '/uploads/meals/demo-kimbap.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 468.00, 18.20, 72.80, 11.70, 1092.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '참치김밥'
UNION ALL SELECT id, 63.00, 4.70, 7.50, 1.80, 585.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '된장국';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 72.60, 'C', 74.00, NULL, 70.80, '나트륨이 높은 편이라 저녁은 담백하게 조절해 보세요.', 'RULE');

-- D-2 저녁
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-2 저녁' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SALMON'), '연어구이', 130.00, 'G', '/uploads/meals/demo-salmon.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SALAD'), '아보카도 샐러드', 160.00, 'G', '/uploads/meals/demo-salmon.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 270.40, 26.00, 0.00, 16.90, 76.70, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '연어구이'
UNION ALL SELECT id, 224.00, 4.80, 12.80, 17.60, 288.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '아보카도 샐러드';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 93.80, 'A', 92.00, NULL, 95.20, '지방 비율은 조금 높지만 질 좋은 지방 위주의 식사입니다.', 'RULE');

-- D-3 점심
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-3 점심' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-PORK-RICE'), '제육덮밥', 420.00, 'G', '/uploads/meals/demo-pork-rice.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 861.00, 35.70, 113.40, 29.40, 2016.00, 'DEMO' FROM meal_items WHERE log_id = @log_id;
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 58.40, 'D', 60.00, NULL, 56.20, '칼로리와 나트륨이 높아요. 채소와 물 섭취를 같이 챙겨주세요.', 'RULE');

-- D-4 간식
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-4 간식' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source)
VALUES (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BANANA'), '바나나', 110.00, 'G', '/uploads/meals/demo-banana.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 97.90, 1.20, 25.30, 0.30, 1.10, 'DEMO' FROM meal_items WHERE log_id = @log_id;
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 79.50, 'C', 78.00, NULL, 81.00, '간식으로는 무난하지만 단백질이 부족합니다.', 'RULE');

-- D-5 저녁
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-5 저녁' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-TOFU'), '두부구이', 180.00, 'G', '/uploads/meals/demo-tofu.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BROWN-RICE'), '현미밥', 150.00, 'G', '/uploads/meals/demo-tofu.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 198.00, 18.00, 5.40, 12.60, 21.60, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '두부구이'
UNION ALL SELECT id, 247.50, 5.40, 51.00, 1.80, 7.50, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '현미밥';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 89.10, 'B', 88.00, NULL, 90.20, '담백한 구성이 좋아요. 채소를 조금 더 곁들이면 완성도가 높습니다.', 'RULE');

-- D-7 점심
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-7 점심' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BROWN-RICE'), '현미밥', 170.00, 'G', '/uploads/meals/demo-balanced-plate.jpg', 'MANUAL'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-GRILLED-CHICKEN'), '닭가슴살 구이', 140.00, 'G', '/uploads/meals/demo-balanced-plate.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 280.50, 6.10, 57.80, 2.00, 8.50, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '현미밥'
UNION ALL SELECT id, 231.00, 43.40, 0.00, 5.00, 103.60, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '닭가슴살 구이';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 95.70, 'A', 96.00, NULL, 95.40, '목표 대비 매우 좋은 균형입니다.', 'RULE');

-- D-9 저녁
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-9 저녁' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source)
VALUES (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-TTEOKBOKKI'), '떡볶이', 300.00, 'G', '/uploads/meals/demo-tteokbokki.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 690.00, 15.00, 144.00, 7.50, 1560.00, 'DEMO' FROM meal_items WHERE log_id = @log_id;
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 63.20, 'C', 64.00, NULL, 62.40, '탄수화물과 나트륨 비중이 높습니다. 다음 끼니는 단백질 위주가 좋아요.', 'RULE');

-- D-11 아침
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-11 아침' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-EGG'), '삶은 달걀', 100.00, 'G', '/uploads/meals/demo-eggs.jpg', 'MANUAL'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-BANANA'), '바나나', 100.00, 'G', '/uploads/meals/demo-eggs.jpg', 'MANUAL');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 156.00, 12.60, 1.20, 10.60, 124.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '삶은 달걀'
UNION ALL SELECT id, 89.00, 1.10, 23.00, 0.30, 1.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '바나나';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 82.80, 'B', 82.00, NULL, 83.60, '아침 식사로 가볍고 안정적입니다.', 'RULE');

-- D-13 점심
SET @log_id = (SELECT id FROM meal_logs WHERE user_id = @demo_user_id AND memo = '[DEMO] D-13 점심' ORDER BY id DESC LIMIT 1);
INSERT INTO meal_items (log_id, food_id, food_name, quantity, unit, photo_url, source) VALUES
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-GRILLED-CHICKEN'), '닭가슴살 구이', 160.00, 'G', '/uploads/meals/demo-chicken.jpg', 'AI'),
    (@log_id, (SELECT id FROM foods WHERE db_source = 'DEMO' AND external_id = 'DEMO-SALAD'), '아보카도 샐러드', 100.00, 'G', '/uploads/meals/demo-chicken.jpg', 'AI');
INSERT INTO nutrition_records (item_id, calories, protein, carbs, fat, sodium, db_source)
SELECT id, 264.00, 49.60, 0.00, 5.80, 118.40, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '닭가슴살 구이'
UNION ALL SELECT id, 140.00, 3.00, 8.00, 11.00, 180.00, 'DEMO' FROM meal_items WHERE log_id = @log_id AND food_name = '아보카도 샐러드';
INSERT INTO diet_scores (log_id, user_id, total_score, grade, goal_score, condition_score, balance_score, comment, calc_source)
VALUES (@log_id, @demo_user_id, 97.10, 'A', 98.00, NULL, 96.20, '단백질과 지방 품질이 좋아 코치 추천 예시로 적합합니다.', 'RULE');

COMMIT;

-- 실행 후 확인용 쿼리
-- SELECT id, email, name FROM users WHERE email = 'example@ssafy.com';
-- SELECT DATE(logged_at) AS d, COUNT(*) AS meal_count FROM meal_logs WHERE user_id = @demo_user_id GROUP BY DATE(logged_at) ORDER BY d DESC;
-- SELECT ml.id, ml.meal_type, ml.logged_at, ds.total_score, ds.grade FROM meal_logs ml JOIN diet_scores ds ON ds.log_id = ml.id WHERE ml.user_id = @demo_user_id ORDER BY ml.logged_at DESC;
