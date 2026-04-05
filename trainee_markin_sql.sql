-- Создание схемы trainee_markin
CREATE SCHEMA IF NOT EXISTS trainee_markin;

-- Переключение на созданную схему
SET search_path TO trainee_markin;

-- =====================================================
-- Таблица Street
-- =====================================================
CREATE TABLE IF NOT EXISTS street
(
    streetcd INTEGER PRIMARY KEY,
    streetnm VARCHAR(100) NOT NULL
);

INSERT INTO street (streetcd, streetnm)
VALUES (1, 'ЦИОЛКОВСКОГО УЛИЦА'),
       (2, 'НОВАЯ УЛИЦА'),
       (3, 'ВОЙКОВ ПЕРЕУЛОК'),
       (4, 'ТАТАРСКАЯ УЛИЦА'),
       (5, 'ГАГАРИНА УЛИЦА'),
       (6, 'МОСКОВСКАЯ УЛИЦА'),
       (7, 'КУТУЗОВА УЛИЦА'),
       (8, 'МОСКОВСКОЕ ШОССЕ');

-- =====================================================
-- Таблица Abonent
-- =====================================================
CREATE TABLE IF NOT EXISTS abonent
(
    accountcd VARCHAR(10) PRIMARY KEY,
    streetcd INTEGER NOT NULL,
    houseno VARCHAR(10) NOT NULL,
    flatno VARCHAR(10),
    fio VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    FOREIGN KEY (streetcd) REFERENCES street (streetcd)
);

INSERT INTO abonent (accountcd, streetcd, houseno, flatno, fio, phone)
VALUES ('005488', 3, '4', '1', 'Аксенов С. А.', '556893'),
       ('015527', 3, '1', '65', 'Конюхов В. С.', '761699'),
       ('080047', 8, '39', '36', 'Шубина Т. П.', '257842'),
       ('080270', 6, '35', '6', 'Тимошкина Н. Г.', '321002'),
       ('080613', 8, '35', '11', 'Лукашина Р. М.', '254417'),
       ('115705', 3, '1', '82', 'Мищенко Е. В.', '769975'),
       ('126112', 4, '7', '11', 'Маркова В. П.', '683301'),
       ('136159', 7, '39', '1', 'Свирина З. А.', NULL),
       ('136160', 4, '9', '15', 'Шмаков С. В.', NULL),
       ('136169', 4, '7', '13', 'Денисова Е. К.', '680305'),
       ('443069', 4, '51', '55', 'Стародубцев Е. В.', '683014'),
       ('443690', 7, '5', '1', 'Тулупова М. И.', '214833');

-- =====================================================
-- Таблица Services
-- =====================================================
CREATE TABLE IF NOT EXISTS services
(
    servicecd INTEGER PRIMARY KEY,
    servicenm VARCHAR(100) NOT NULL
);

INSERT INTO services (servicecd, servicenm)
VALUES (1, 'Газоснабжение'),
       (2, 'Электроснабжение'),
       (3, 'Теплоснабжение'),
       (4, 'Водоснабжение');

-- =====================================================
-- Таблица Disrepair
-- =====================================================
CREATE TABLE IF NOT EXISTS disrepair
(
    failurecd INTEGER PRIMARY KEY,
    failurenm VARCHAR(200) NOT NULL
);

INSERT INTO disrepair (failurecd, failurenm)
VALUES (1, 'Засорилась водогрейная колонка'),
       (2, 'Не горит АГВ'),
       (3, 'Течет из водогрейной колонки'),
       (4, 'Неисправна печная горелка'),
       (5, 'Неисправен газовый счетчик'),
       (6, 'Плохое поступление газа на горелку плиты'),
       (7, 'Туго поворачивается пробка крана плиты'),
       (8, 'При закрытии краника горелка плиты не гаснет'),
       (12, 'Неизвестна');

-- =====================================================
-- Таблица NachislSumma
-- =====================================================
CREATE TABLE IF NOT EXISTS nachislsumma
(
    nachisl_factcd INTEGER PRIMARY KEY,
    accountcd VARCHAR(10) NOT NULL,
    servicecd INTEGER NOT NULL,
    nachisl_sum NUMERIC(10, 2) NOT NULL,
    nachisl_month INTEGER NOT NULL,
    nachisl_year INTEGER NOT NULL,
    FOREIGN KEY (accountcd) REFERENCES abonent (accountcd),
    FOREIGN KEY (servicecd) REFERENCES services (servicecd)
);

INSERT INTO nachislsumma (nachisl_factcd, accountcd, servicecd, nachisl_sum, nachisl_month, nachisl_year)
VALUES (1, '136160', 2, 656.00, 1, 2021),
       (2, '005488', 2, 646.00, 12, 2018),
       (3, '005488', 2, 656.00, 4, 2021),
       (4, '115705', 2, 640.00, 1, 2018),
       (5, '115705', 2, 850.00, 9, 2019),
       (6, '136160', 1, 518.30, 1, 2020),
       (7, '080047', 2, 680.00, 10, 2020),
       (8, '080047', 2, 680.00, 10, 2019),
       (9, '080270', 2, 646.00, 12, 2019),
       (10, '080613', 2, 656.00, 6, 2019),
       (11, '115705', 2, 850.00, 9, 2018),
       (12, '115705', 2, 658.70, 8, 2019),
       (13, '136160', 2, 620.00, 5, 2019),
       (15, '136169', 2, 620.00, 5, 2019),
       (16, '136169', 2, 658.70, 11, 2019),
       (17, '443069', 2, 680.00, 9, 2019),
       (18, '443069', 2, 638.50, 8, 2019),
       (19, '005488', 2, 658.70, 12, 2019),
       (20, '015527', 1, 528.32, 7, 2020),
       (21, '080047', 1, 519.56, 3, 2020),
       (22, '080613', 1, 510.60, 9, 2020),
       (23, '443069', 1, 538.28, 12, 2020),
       (24, '015527', 1, 538.32, 4, 2021),
       (25, '115705', 1, 537.15, 10, 2021),
       (26, '080613', 1, 512.60, 8, 2018),
       (27, '136169', 1, 525.32, 1, 2021),
       (28, '080270', 1, 557.10, 2, 2020),
       (29, '136159', 1, 508.30, 8, 2021),
       (30, '005488', 1, 562.13, 4, 2018),
       (31, '115705', 1, 537.80, 5, 2019),
       (32, '443690', 1, 517.80, 6, 2020),
       (33, '080047', 1, 522.56, 5, 2021),
       (34, '126112', 1, 515.30, 8, 2018),
       (35, '080047', 1, 532.56, 9, 2019),
       (36, '080613', 1, 512.60, 4, 2020),
       (37, '115705', 1, 537.15, 11, 2021),
       (38, '080270', 1, 558.10, 12, 2018),
       (39, '136169', 1, 528.32, 1, 2019),
       (40, '015527', 1, 518.32, 2, 2020),
       (41, '443690', 1, 521.67, 3, 2021),
       (42, '080613', 1, 522.86, 4, 2018),
       (43, '080270', 1, 560.10, 5, 2019),
       (44, '136169', 1, 528.32, 2, 2020),
       (45, '080047', 1, 522.20, 7, 2021),
       (46, '126112', 1, 525.30, 8, 2019),
       (47, '443069', 1, 538.32, 9, 2019),
       (48, '136159', 1, 508.30, 10, 2020),
       (49, '115705', 1, 537.15, 6, 2021),
       (50, '136160', 1, 518.30, 12, 2018),
       (51, '005488', 3, 2279.80, 5, 2020),
       (52, '005488', 3, 2266.70, 2, 2021),
       (53, '015527', 3, 2343.36, 11, 2021),
       (54, '080047', 3, 2271.60, 2, 2021),
       (55, '080270', 3, 2278.25, 11, 2021),
       (56, '080613', 3, 2254.40, 7, 2019),
       (57, '080613', 3, 2258.80, 2, 2021),
       (58, '080613', 3, 2239.33, 5, 2021),
       (59, '126112', 3, 2179.90, 4, 2020),
       (60, '136159', 3, 2180.13, 9, 2021),
       (61, '136160', 3, 2238.80, 3, 2018),
       (62, '136160', 3, 2237.38, 3, 2019),
       (63, '136169', 3, 2349.19, 6, 2020),
       (64, '136169', 3, 2346.18, 7, 2020),
       (65, '443690', 3, 2290.33, 3, 2021),
       (66, '015527', 4, 280.10, 7, 2020),
       (67, '015527', 4, 311.30, 10, 2021),
       (68, '080270', 4, 144.34, 3, 2019),
       (69, '080270', 4, 253.43, 6, 2020),
       (70, '080270', 4, 154.60, 4, 2021),
       (71, '115705', 4, 253.85, 1, 2020),
       (72, '126112', 4, 135.50, 6, 2020),
       (73, '136159', 4, 49.38, 4, 2019),
       (74, '136159', 4, 118.88, 6, 2020),
       (75, '136169', 4, 228.44, 10, 2021),
       (76, '443069', 4, 166.69, 5, 2020),
       (77, '443069', 4, 144.45, 10, 2021),
       (78, '443069', 4, 180.88, 8, 2019),
       (79, '443069', 4, 200.13, 9, 2020);

-- =====================================================
-- Таблица PaySumma
-- =====================================================
CREATE TABLE IF NOT EXISTS paysumma
(
    pay_factcd INTEGER PRIMARY KEY,
    accountcd VARCHAR(10) NOT NULL,
    servicecd INTEGER NOT NULL,
    paysum NUMERIC(10, 2) NOT NULL,
    paydate DATE NOT NULL,
    paymonth INTEGER NOT NULL,
    payyear INTEGER NOT NULL,
    FOREIGN KEY (accountcd) REFERENCES abonent (accountcd),
    FOREIGN KEY (servicecd) REFERENCES services (servicecd)
);

INSERT INTO paysumma (pay_factcd, accountcd, servicecd, paysum, paydate, paymonth, payyear)
VALUES (1, '005488', 2, 658.70, '2020-01-08', 12, 2019),
       (2, '005488', 2, 640.00, '2019-01-06', 12, 2018),
       (3, '005488', 2, 656.00, '2021-05-06', 4, 2021),
       (4, '115705', 2, 640.00, '2018-02-10', 1, 2018),
       (5, '115705', 2, 850.00, '2019-10-03', 9, 2019),
       (6, '136160', 2, 620.00, '2019-06-13', 5, 2019),
       (7, '136160', 2, 656.00, '2021-02-12', 1, 2021),
       (8, '136169', 2, 620.00, '2019-06-22', 5, 2019),
       (9, '080047', 2, 680.00, '2020-11-26', 10, 2020),
       (10, '080047', 2, 680.00, '2019-11-21', 10, 2019),
       (11, '080270', 2, 630.00, '2020-01-03', 12, 2019),
       (12, '080613', 2, 658.50, '2019-07-19', 6, 2019),
       (13, '115705', 2, 850.00, '2018-10-06', 9, 2018),
       (14, '115705', 2, 658.70, '2019-09-04', 8, 2019),
       (15, '136169', 2, 658.70, '2019-12-01', 11, 2019),
       (16, '443069', 2, 680.00, '2019-10-03', 9, 2019),
       (17, '443069', 2, 638.50, '2019-09-13', 8, 2019),
       (18, '136160', 1, 518.00, '2020-02-05', 1, 2020),
       (19, '015527', 1, 530.00, '2020-08-03', 7, 2020),
       (20, '080047', 1, 519.56, '2020-04-02', 3, 2020),
       (21, '080613', 1, 511.00, '2020-10-03', 9, 2020),
       (22, '443069', 1, 538.28, '2021-02-04', 12, 2020),
       (23, '015527', 1, 540.00, '2021-05-07', 4, 2021),
       (24, '115705', 1, 537.15, '2021-11-04', 10, 2021),
       (25, '080613', 1, 512.00, '2018-09-20', 8, 2018),
       (26, '136169', 1, 525.32, '2021-02-03', 1, 2021),
       (27, '080270', 1, 560.00, '2020-03-05', 2, 2020),
       (28, '136159', 1, 508.30, '2021-09-10', 8, 2021),
       (29, '005488', 1, 565.00, '2018-05-03', 4, 2018),
       (30, '115705', 1, 537.80, '2019-07-12', 5, 2019),
       (31, '443690', 1, 517.80, '2020-07-04', 6, 2020),
       (32, '080047', 1, 522.56, '2021-06-05', 5, 2021),
       (33, '126112', 1, 515.30, '2018-09-06', 8, 2018),
       (34, '080047', 1, 532.56, '2019-10-06', 9, 2019),
       (35, '080613', 1, 512.60, '2020-05-05', 4, 2020),
       (36, '115705', 1, 537.15, '2021-12-05', 11, 2021),
       (37, '080270', 1, 558.10, '2019-01-03', 12, 2018),
       (38, '136169', 1, 528.32, '2019-02-03', 1, 2019),
       (39, '015527', 1, 518.32, '2020-03-03', 2, 2020),
       (40, '443690', 1, 521.67, '2021-04-03', 3, 2021),
       (41, '080613', 1, 522.86, '2018-05-05', 4, 2018),
       (42, '080270', 1, 560.10, '2019-06-05', 5, 2019),
       (43, '136169', 1, 528.32, '2020-03-03', 2, 2020),
       (44, '080047', 1, 522.20, '2021-08-05', 7, 2021),
       (45, '126112', 1, 525.30, '2019-09-06', 8, 2019),
       (46, '443069', 1, 538.32, '2019-10-04', 9, 2019),
       (47, '136159', 1, 508.30, '2020-11-05', 10, 2020),
       (48, '115705', 1, 537.15, '2021-07-05', 6, 2021),
       (49, '136160', 1, 518.30, '2019-01-04', 12, 2018),
       (50, '005488', 3, 2279.80, '2020-06-05', 5, 2020),
       (51, '005488', 3, 2266.70, '2021-03-05', 2, 2021),
       (52, '015527', 3, 2343.36, '2021-12-05', 11, 2021),
       (53, '080047', 3, 2271.60, '2021-03-06', 2, 2021),
       (54, '080270', 3, 2278.25, '2021-12-06', 11, 2021),
       (55, '080613', 3, 2254.40, '2019-08-07', 7, 2019),
       (56, '080613', 3, 2258.80, '2021-03-05', 2, 2021),
       (57, '080613', 3, 2239.33, '2021-06-05', 5, 2021),
       (58, '126112', 3, 2179.90, '2020-05-05', 4, 2020),
       (59, '136159', 3, 2180.13, '2021-10-06', 9, 2021),
       (60, '136160', 3, 2238.80, '2018-04-05', 3, 2018),
       (61, '136160', 3, 2237.38, '2019-04-05', 3, 2019),
       (62, '136169', 3, 2349.19, '2020-07-14', 6, 2020),
       (63, '136169', 3, 2346.18, '2020-08-13', 7, 2020),
       (64, '443690', 3, 2295.00, '2021-04-09', 3, 2021),
       (65, '015527', 4, 280.10, '2020-08-08', 7, 2020),
       (66, '015527', 4, 311.30, '2021-11-03', 10, 2021),
       (67, '080270', 4, 144.50, '2019-04-18', 3, 2019),
       (68, '080270', 4, 150.00, '2020-07-14', 6, 2020),
       (69, '080270', 4, 160.00, '2021-05-12', 4, 2021),
       (70, '115705', 4, 253.85, '2020-02-02', 1, 2020),
       (71, '126112', 4, 135.50, '2020-07-12', 6, 2020),
       (72, '136159', 4, 49.38, '2019-05-18', 4, 2019),
       (73, '136159', 4, 120.00, '2020-07-09', 6, 2020),
       (74, '136169', 4, 228.44, '2021-11-26', 10, 2021),
       (75, '443069', 4, 166.69, '2020-06-03', 5, 2020),
       (76, '443069', 4, 144.45, '2021-11-16', 10, 2021),
       (77, '443690', 4, 185.00, '2019-09-05', 8, 2019);

-- =====================================================
-- Таблица Request
-- =====================================================
CREATE TABLE IF NOT EXISTS request
(
    requestcd INTEGER PRIMARY KEY,
    accountcd VARCHAR(10) NOT NULL,
    executorcd INTEGER,
    failurecd INTEGER NOT NULL,
    incomingdate DATE NOT NULL,
    executiondate DATE,
    executed BOOLEAN NOT NULL,
    FOREIGN KEY (accountcd) REFERENCES abonent (accountcd),
    FOREIGN KEY (failurecd) REFERENCES disrepair (failurecd)
);

INSERT INTO request (requestcd, accountcd, executorcd, failurecd, incomingdate, executiondate, executed)
VALUES (1, '005488', 1, 1, '2019-12-17', '2019-12-20', TRUE),
       (2, '115705', 3, 1, '2019-08-07', '2019-08-12', TRUE),
       (3, '015527', 1, 12, '2020-02-28', '2020-03-08', FALSE),
       (5, '080270', 4, 1, '2019-12-31', NULL, FALSE),
       (6, '080613', 1, 6, '2019-06-16', '2019-06-24', TRUE),
       (7, '080047', 3, 2, '2020-10-20', '2020-10-24', TRUE),
       (9, '136169', 2, 1, '2019-11-06', '2019-11-08', TRUE),
       (10, '136159', 3, 12, '2019-04-01', '2019-04-03', FALSE),
       (11, '136160', 1, 6, '2021-01-12', '2021-01-12', TRUE),
       (12, '443069', 5, 2, '2019-08-08', '2019-08-10', TRUE),
       (13, '005488', 5, 8, '2018-09-04', '2018-12-05', TRUE),
       (14, '005488', 4, 6, '2021-04-04', '2021-04-13', TRUE),
       (15, '115705', 4, 5, '2018-09-20', '2018-09-23', TRUE),
       (16, '115705', NULL, 3, '2019-12-28', NULL, FALSE),
       (17, '115705', 1, 5, '2019-08-15', '2019-09-06', TRUE),
       (18, '115705', 2, 3, '2020-12-28', '2021-01-04', TRUE),
       (19, '080270', 4, 8, '2019-12-17', '2019-12-27', TRUE),
       (20, '080047', 3, 2, '2019-10-11', '2019-10-11', TRUE),
       (21, '443069', 1, 2, '2019-09-13', '2019-09-14', TRUE),
       (22, '136160', 1, 7, '2019-05-18', '2019-05-25', TRUE),
       (23, '136169', 5, 7, '2019-05-07', '2019-05-08', TRUE);


-- =====================================================
-- Проверка всех таблиц
-- =====================================================
SELECT 'Street' AS table_name, COUNT(*) AS record_count
FROM street
UNION ALL
SELECT 'Abonent', COUNT(*)
FROM abonent
UNION ALL
SELECT 'Services', COUNT(*)
FROM services
UNION ALL
SELECT 'Disrepair', COUNT(*)
FROM disrepair
UNION ALL
SELECT 'NachislSumma', COUNT(*)
FROM nachislsumma
UNION ALL
SELECT 'PaySumma', COUNT(*)
FROM paysumma
UNION ALL
SELECT 'Request', COUNT(*)
FROM request
ORDER BY table_name;

select *
from abonent
where phone is null
order by fio;




-- ============================================================================
-- РАЗДЕЛ 1: ОКОННЫЕ ФУНКЦИИ (WINDOW FUNCTIONS)
-- ============================================================================

-- ROW_NUMBER() - присваивает уникальный порядковый номер каждой строке
-- OVER () - без PARTITION BY нумерует все строки подряд
-- Результат: 1, 2, 3, 4, 5... для всех записей таблицы
SELECT
            ROW_NUMBER() OVER () AS "номер",  -- Порядковый номер строки в результате
            fio                                  -- ФИО абонента
FROM abonent
WHERE 1 = 1;  -- Всегда истинно, используется для динамического формирования WHERE

-- Аналогичный запрос, но с условием, которое всегда ложно для пустой строки
-- WHERE '' IS NOT NULL всегда TRUE, так как пустая строка ≠ NULL
SELECT
            ROW_NUMBER() OVER () AS "номер",
            fio
FROM abonent
WHERE '' IS NOT NULL;  -- Вернёт все строки (пустая строка существует)


-- ============================================================================
-- РАЗДЕЛ 2: РАБОТА С NULL И СРАВНЕНИЯ
-- ============================================================================

/*
IS DISTINCT FROM vs <> (не равно)
=====================================
Проблема обычного <> :
  - NULL <> 'значение' возвращает NULL (неизвестно), а не TRUE
  - Строки с NULL не попадают в выборку

Решение IS DISTINCT FROM:
  - NULL IS DISTINCT FROM 'значение' возвращает TRUE
  - NULL IS DISTINCT FROM NULL возвращает FALSE
  - Работает как "не равно, учитывая NULL"
*/
SELECT *
FROM request
WHERE executiondate IS DISTINCT FROM '20.12.2019';
-- Вернёт: все даты кроме 20.12.2019 + все NULL значения

-- Эквивалентная запись через OR (более длинная)
SELECT *
FROM request
WHERE executiondate <> '20.12.2019'   -- Все даты кроме указанной
   OR executiondate IS NULL;           -- Плюс все NULL


-- ============================================================================
-- РАЗДЕЛ 3: ЛОГИЧЕСКИЕ ОПЕРАТОРЫ (AND, OR)
-- ============================================================================

/*
Запрос с комбинированными условиями:
Требуется найти:
1. Платежи после 13.06.2021 И сумма > 120
ИЛИ
2. Платежи до 2020 года И конкретный лицевой счет
*/
SELECT *
FROM paysumma
WHERE (paydate > '13.06.2021' AND paysum > 120)     -- Условие 1 (оба должны выполняться)
   OR                                                 -- ИЛИ
    (paydate < '01.01.2020' AND accountcd = '005488'); -- Условие 2 (оба должны выполняться)


-- ============================================================================
-- РАЗДЕЛ 4: РАБОТА СО СТРОКАМИ - ИЗВЛЕЧЕНИЕ ЧАСТИ
-- ============================================================================

-- SUBSTRING / SUBSTR - извлекает подстроку
-- Синтаксис: SUBSTR(строка, начало, длина)
-- Нумерация символов начинается с 1 (не с 0!)
SELECT
    accountcd,
    SUBSTRING(fio, 1, 3) AS "Fio3"  -- Первые 3 символа ФИО
FROM abonent;

-- SUBSTR - альтернативный синтаксис (работает в PostgreSQL для совместимости)
SELECT
    accountcd,
    SUBSTR(fio, 1, 3) AS "Fio3"  -- То же самое, что SUBSTRING
FROM abonent;

-- Комбинация SUBSTR + REVERSE
SELECT
    accountcd,
    SUBSTR(fio, 1, 3) AS "Fio3",           -- Первые 3 символа
    REVERSE(SUBSTR(fio, 1, 3)) AS "Fio3_reversed"  -- Они же в обратном порядке
FROM abonent;

-- REVERSE всей строки
SELECT
    accountcd,
    SUBSTR(fio, 1, 3) AS "Fio3",
    REVERSE(fio) AS "Fio_reversed"  -- Всё ФИО задом наперёд
FROM abonent;

-- LEFT - первые N символов строки
SELECT
    LEFT(accountcd, 4) AS accountcd_first_4,  -- Первые 4 символа лицевого счета
    accountcd
FROM abonent;


-- ============================================================================
-- РАЗДЕЛ 5: РАБОТА СО СТРОКАМИ - ЗАМЕНА И МОДИФИКАЦИЯ
-- ============================================================================

-- OVERLAY - замена части строки по позиции
-- Синтаксис: OVERLAY(строка PLACING 'новая' FROM позиция FOR длина)
SELECT OVERLAY('PostgreXXX' PLACING 'SQL' FROM 8 FOR 3);
-- Результат: 'PostgreSQL' (заменили XXX на SQL начиная с 8-й позиции)

-- SUBSTRING с синтаксисом SQL-standard
SELECT
    SUBSTRING(accountcd FROM 3 FOR 1) AS account_prefix,  -- 3-й символ
    accountcd
FROM abonent;

-- REPLACE - замена подстроки на другую
SELECT
    REPLACE(failurenm, 'плиты', 'газовой плиты') AS replace_failurenm,
    failurenm
FROM disrepair;
-- Пример: "ремонт плиты" → "ремонт газовой плиты"


-- ============================================================================
-- РАЗДЕЛ 6: ОБРЕЗКА ПРОБЕЛОВ И СИМВОЛОВ (TRIM)
-- ============================================================================

-- TRIM(LEADING ...) - удаляет символы в НАЧАЛЕ строки
SELECT
    TRIM(LEADING '0' FROM accountcd) AS trim_accountcd,  -- Удалить ведущие нули
    accountcd
FROM abonent;
-- Пример: '00123' → '123'

-- TRIM(TRAILING ...) - удаляет символы в КОНЦЕ строки
SELECT
    streetcd,
    TRIM(TRAILING 'УЛИЦА' FROM streetnm) AS "Str_Name",  -- Удалить "УЛИЦА" в конце
    streetnm
FROM street;
-- Пример: 'Ленина УЛИЦА' → 'Ленина '

-- Альтернатива: сначала REPLACE, потом TRIM пробелов
SELECT
    streetcd,
    TRIM(REPLACE(streetnm, 'УЛИЦА', '')) AS "Str_Name",  -- Удалить "УЛИЦА" везде + пробелы
    streetnm
FROM street;
-- Пример: 'Ленина УЛИЦА' → 'Ленина'

-- LTRIM / RTRIM - упрощённые версии TRIM
SELECT
    streetcd,
    LTRIM(streetnm) AS "LTRIM_Name",   -- Пробелы слева (Leading)
    RTRIM(streetnm) AS "RTRIM_Name",   -- Пробелы справа (Trailing)
    streetnm
FROM street;


-- ============================================================================
-- РАЗДЕЛ 7: ВЫРАВНИВАНИЕ СТРОК (PADDING)
-- ============================================================================

-- RPAD - выравнивание вправо (добавляет символы справа до нужной длины)
-- LPAD - выравнивание влево (добавляет символы слева до нужной длины)
SELECT
    accountcd,
    RPAD(fio, 20, '*') AS fio_right_padded,   -- ФИО + звёздочки справа до 20 символов
    LPAD(fio, 20, '*') AS fio_left_padded     -- Звёздочки слева + ФИО до 20 символов
FROM abonent;
-- Пример: 'Иванов' → 'Иванов**************' (RPAD) или '**************Иванов' (LPAD)

-- Безопасное выравнивание (только если строка короче 20 символов)
SELECT
    CASE
        WHEN LENGTH(fio) < 20 THEN RPAD(fio, 20, '*')  -- Добавляем звёзды только если нужно
        ELSE fio                                        -- Иначе оставляем как есть
        END AS fio_padded
FROM abonent;


-- ============================================================================
-- РАЗДЕЛ 8: ДЛИНА СТРОКИ
-- ============================================================================

-- LENGTH - количество символов в строке
SELECT
    accountcd,
    fio,
    LENGTH(fio) AS fio_length  -- Длина ФИО в символах
FROM abonent;

-- CONCAT - сцепление строк (аналог ||)
SELECT
    accountcd AS "AccountCDRyazan",
    CONCAT(fio, ' имеет телефон ', '8-4912-', phone) AS "ФИО+телефон"
FROM abonent;
-- Пример: 'Иванов имеет телефон 8-4912-555666'

-- REPEAT - повторение строки N раз
SELECT
    accountcd AS "AccountCDRyazan",
    REPEAT(fio, 2) AS "ФИО_повтор"  -- ФИО повторяется 2 раза
FROM abonent;
-- Пример: 'Иванов' → 'ИвановИванов'


-- ============================================================================
-- РАЗДЕЛ 9: РЕГИСТР СИМВОЛОВ
-- ============================================================================

-- INITCAP - первая буква каждого слова заглавная, остальные строчные
SELECT
    streetnm,
    INITCAP(streetnm) AS streetnm_capitalized
FROM street;
-- Пример: 'лЕНИНА уЛИЦА' → 'Ленина Улица'

-- LOWER - все буквы в нижний регистр
SELECT
    streetnm,
    LOWER(streetnm) AS streetnm_lower
FROM street;
-- Пример: 'ЛЕНИНА' → 'ленина'

-- UPPER - все буквы в верхний регистр
SELECT
    streetnm,
    UPPER(streetnm) AS streetnm_upper
FROM street;
-- Пример: 'ленина' → 'ЛЕНИНА'


-- ============================================================================
-- РАЗДЕЛ 10: КОДЫ СИМВОЛОВ (ASCII/Unicode)
-- ============================================================================

-- CHR - символ по его Unicode коду
SELECT CHR(12354);  -- Символ Unicode с кодом 12354 (японская хирагана)
SELECT CHR(82);     -- Символ с кодом 82 (латинская 'R')


-- ============================================================================
-- РАЗДЕЛ 11: ПОЗИЦИЯ ПОДСТРОКИ
-- ============================================================================

-- POSITION - позиция подстроки в строке (нумерация с 1)
SELECT
    accountcd,
    fio
FROM abonent
WHERE POSITION('у' IN fio) = 2;  -- Вторая буква в ФИО = 'у'
-- Пример: 'Кузнецов' → позиция 'у' = 2 ✅


-- ============================================================================
-- РАЗДЕЛ 12: ДЛИНА СТРОКИ В СИМВОЛАХ И БАЙТАХ
-- ============================================================================

SELECT
    servicenm,
    CHAR_LENGTH(servicenm) AS char_len,   -- Длина в символах (для UTF-8 = символы)
    BIT_LENGTH(servicenm) AS bit_len      -- Длина в битах (символ * 8 для ASCII)
FROM services;
-- Для кириллицы в UTF-8: CHAR_LENGTH = 5, BIT_LENGTH может быть больше


-- ============================================================================
-- РАЗДЕЛ 13: ПРОВЕРКА НА ЛИШНИЕ ПРОБЕЛЫ
-- ============================================================================

/*
Сравнение длины строки до и после TRIM:
- Если F1 = F2 → пробелов не было
- Если F1 > F2 → были лишние пробелы (TRIM их удалил)
*/
SELECT
    failurenm AS "FailureNM",
    LENGTH(failurenm) AS f1,              -- Длина до обрезки
    LENGTH(TRIM(failurenm)) AS f2         -- Длина после обрезки пробелов
FROM disrepair
LIMIT 3;


-- ============================================================================
-- РАЗДЕЛ 14: ПОДСЧЁТ ВХОЖДЕНИЙ СИМВОЛА В СТРОКУ
-- ============================================================================

-- Способ 1: Разница длин (работает для одиночных символов)
SELECT
    fio,
    'у',
    LENGTH(fio) - LENGTH(REPLACE(fio, 'у', '')) AS count_u  -- Сколько раз удалили 'у'
FROM abonent;

-- Способ 2: Деление на длину искомой подстроки (универсальный)
SELECT
    fio,
    'у',
    (CHAR_LENGTH(fio) - CHAR_LENGTH(REPLACE(fio, 'у', ''))) / CHAR_LENGTH('у') AS count_u
FROM abonent;

-- Способ 3: Регулярные выражения (самый мощный)
SELECT
    fio,
    'у',
    (SELECT COUNT(*) FROM REGEXP_MATCHES(fio, 'у', 'g')) AS count_u  -- 'g' = все совпадения
FROM abonent;


-- ============================================================================
-- РАЗДЕЛ 15: РАБОТА С ДАТАМИ - EXTRACT
-- ============================================================================

-- EXTRACT - извлечение части даты (день, месяц, год, квартал)
SELECT
    requestcd,
    EXTRACT(DAY FROM incomingdate) AS "IncomingDay",      -- День месяца (1-31)
    EXTRACT(MONTH FROM incomingdate) AS "IncomingMonth",  -- Месяц (1-12)
    EXTRACT(YEAR FROM incomingdate) AS "IncomingYear",    -- Год (4 цифры)
    EXTRACT(QUARTER FROM incomingdate) AS "IncomingQuarter" -- Квартал (1-4)
FROM request
WHERE EXTRACT(YEAR FROM incomingdate) IS DISTINCT FROM 2021;  -- Все годы кроме 2021

-- Разные способы форматирования даты
SELECT
    requestcd,
    EXTRACT(DAY FROM incomingdate) AS "IncomingDay_DAY",
    EXTRACT(MONTH FROM incomingdate) AS "IncomingMonth_MONTH",
    EXTRACT(YEAR FROM incomingdate) AS "IncomingYear_YEAR",
    TO_CHAR(incomingdate, 'Month') AS "IncomingMonth_TO_CHAR",  -- Название месяца (январь)
    EXTRACT(QUARTER FROM incomingdate) AS "IncomingQuarter"
FROM request;


-- ============================================================================
-- РАЗДЕЛ 16: МАТЕМАТИЧЕСКИЕ ФУНКЦИИ
-- ============================================================================

-- Проверка тригонометрического тождества: cos²(x) + sin²(x) = 1
SELECT POWER(COS(PI()), 2) + POWER(SIN(PI()), 2) AS result;
-- Результат: ~1 (может быть 0.999... из-за погрешности float)

-- Константа Пи
SELECT PI();  -- 3.141592653589793

-- Синус угла (в PostgreSQL тригонометрия работает с РАДИАНАМИ!)
SELECT SIN(RADIANS(90));  -- 90 градусов → радианы → синус = 1

-- Округление до N знаков после запятой
SELECT ROUND(123.456, 2);  -- 123.46

-- Случайное число от 0 до 1
SELECT RANDOM();  -- Например: 0.123456789

-- Округление сумм платежей
SELECT
    paysum,
    paydate,
    CEIL(paysum) AS "вверх",      -- Округление ВВЕРХ до целого (123.1 → 124)
    FLOOR(paysum) AS "вниз",      -- Округление ВНИЗ до целого (123.9 → 123)
    ROUND(paysum) AS "ближайшее"  -- Округление до ближайшего целого (123.5 → 124)
FROM paysumma;


-- ============================================================================
-- РАЗДЕЛ 17: ТЕКУЩЕЕ ВРЕМЯ
-- ============================================================================

-- CURRENT_TIMESTAMP - текущая дата и время с часовым поясом
SELECT
    s.*,
    CURRENT_TIMESTAMP AS "когда_выполнен_запрос"
FROM services s;


-- ============================================================================
-- РАЗДЕЛ 18: ИНТЕРВАЛЫ ВРЕМЕНИ (INTERVAL)
-- ============================================================================

-- Добавление дней к дате
SELECT
    incomingdate,
    incomingdate + INTERVAL '14 days' AS "Exec_Limit"  -- Дата + 14 дней
FROM request
WHERE failurecd = 1;

-- Альтернативный синтаксис (умножение интервала)
SELECT
    incomingdate,
    incomingdate + 14 * INTERVAL '1 day' AS "Exec_Limit"  -- То же самое
FROM request
WHERE failurecd = 1;

-- Разные интервалы
SELECT
    incomingdate,
    incomingdate + INTERVAL '14 days' AS "плюс_14_дней",
    incomingdate + INTERVAL '3 months' AS "плюс_3_месяца",
    incomingdate + INTERVAL '1 year' AS "плюс_1_год",
    incomingdate - INTERVAL '7 days' AS "минус_7_дней"  -- Вычитание интервала
FROM request
WHERE failurecd = 1;

-- Интервалы с временем (часы, минуты, секунды)
SELECT
    incomingdate,
    incomingdate + INTERVAL '2 hours' AS "плюс_2_часа",
    incomingdate + INTERVAL '30 minutes' AS "плюс_30_минут",
    incomingdate + INTERVAL '45 seconds' AS "плюс_45_секунд"
FROM request
WHERE failurecd = 1;

-- Сложный интервал (годы + месяцы + дни)
SELECT
    incomingdate,
    incomingdate + INTERVAL '1 year 2 months 14 days' AS "сложный_интервал"
FROM request
WHERE failurecd = 1;

-- MAKE_INTERVAL - программное создание интервала
SELECT
    incomingdate,
    incomingdate + MAKE_INTERVAL(days => 14) AS "Exec_Limit"  -- Именованные параметры
FROM request
WHERE failurecd = 1;


-- ============================================================================
-- РАЗДЕЛ 19: РАЗНИЦА МЕЖДУ ДАТАМИ
-- ============================================================================

-- EXTRACT(EPOCH FROM ...) - разница в секундах
SELECT
    requestcd,
    incomingdate,
    executiondate,
    EXTRACT(EPOCH FROM (executiondate::TIMESTAMP - incomingdate::TIMESTAMP)) / 3600 AS "Hours",  -- В часах
    EXTRACT(EPOCH FROM (executiondate::TIMESTAMP - incomingdate::TIMESTAMP)) AS "Seconds"       -- В секундах
FROM request
WHERE accountcd = '115705';
-- EPOCH = количество секунд между двумя датами


-- ============================================================================
-- РАЗДЕЛ 20: УСЕЧЕНИЕ ДАТЫ (DATE_TRUNC)
-- ============================================================================

-- DATE_TRUNC - округление даты до указанной точности (до начала периода)
SELECT
    incomingdate,
    DATE_TRUNC('YEAR', incomingdate) AS "Начало_года",   -- 2024-01-01 00:00:00
    DATE_TRUNC('MONTH', incomingdate) AS "Начало_месяца", -- 2024-06-01 00:00:00
    DATE_TRUNC('DAY', incomingdate) AS "Начало_дня",     -- 2024-06-15 00:00:00
    DATE_TRUNC('HOUR', incomingdate) AS "Начало_часа"    -- 2024-06-15 14:00:00
FROM request;


-- ============================================================================
-- РАЗДЕЛ 21: СОЗДАНИЕ ДАТЫ ИЗ ЧАСТЕЙ
-- ============================================================================

-- Способ 1: Конкатенация + TO_DATE
SELECT DISTINCT
    nachisl_month,
    nachisl_year,
    TO_DATE('1.' || nachisl_month || '.' || nachisl_year, 'DD.MM.YYYY') AS "FirstDay"
FROM nachislsumma
WHERE servicecd = 2;

-- Способ 2: MAKE_DATE (рекомендуется!)
SELECT DISTINCT
    nachisl_month,
    nachisl_year,
    MAKE_DATE(nachisl_year, nachisl_month, 1) AS "FirstDay"  -- Безопаснее и быстрее
FROM nachislsumma
WHERE servicecd = 2;

-- Способ 3: CAST строки в DATE
SELECT DISTINCT
    nachisl_month,
    nachisl_year,
    CAST('1.' || nachisl_month || '.' || nachisl_year AS DATE) AS "FirstDay"
FROM nachislsumma
WHERE servicecd = 2;


-- ============================================================================
-- РАЗДЕЛ 22: ПРЕОБРАЗОВАНИЕ ТИПОВ (CAST)
-- ============================================================================

-- CAST строки в INTEGER для арифметики
SELECT
    accountcd,
    (CAST(accountcd AS INTEGER) + 2) AS new_acc,  -- '123' → 123 → 125
    fio
FROM abonent;

-- CAST суммы в целое число (отбрасывает дробную часть)
SELECT
    nachisl_sum,
    nachisl_factcd,
    CAST(nachisl_sum AS INTEGER) AS "RoundSum"  -- 550.75 → 550
FROM nachislsumma
WHERE accountcd = '115705';


-- ============================================================================
-- РАЗДЕЛ 23: ФОРМАТИРОВАНИЕ ДАТЫ (TO_CHAR)
-- ============================================================================

SELECT
            CURRENT_DATE AS "Сегодня",
            TO_CHAR(CURRENT_DATE, 'D') AS "Номер_дня_недели_1-7",    -- 1-7 (зависит от NLS)
            TO_CHAR(CURRENT_DATE, 'DAY') AS "День_недели_верхний",   -- ПОНЕДЕЛЬНИК (заглавные)
            TO_CHAR(CURRENT_DATE, 'Day') AS "День_недели_с_заглавной", -- Понедельник (первая заглавная)
            TO_CHAR(CURRENT_DATE, 'Q') AS "Квартал",                 -- 1-4
            TO_CHAR(CURRENT_DATE, 'DD.MM.YYYY') AS "Дата_в_формате", -- 15.06.2024
            TO_CHAR(CURRENT_DATE, 'FMDD Month YYYY') AS "Дата_с_названием_месяца" -- 15 Июнь 2024
-- FM = убрать лишние пробелы (Fill Mode)
FROM request;


-- ============================================================================
-- РАЗДЕЛ 24: АГРЕГАТНЫЕ ФУНКЦИИ
-- ============================================================================

-- AVG с DISTINCT - среднее только по уникальным значениям
SELECT
    AVG(DISTINCT paysum) AS avg_unique,  -- Среднее уникальных сумм
    AVG(paysum) AS avg_all               -- Среднее всех сумм (включая повторы)
FROM paysumma;

-- FILTER - фильтрация внутри агрегатной функции (современный синтаксис)
SELECT
            AVG(executiondate - incomingdate) FILTER (WHERE executiondate IS NOT NULL) AS avg_days
FROM request;

-- Эквивалент через CASE (старый способ)
SELECT
    AVG(
            CASE
                WHEN executiondate IS NOT NULL THEN executiondate - incomingdate
                ELSE NULL  -- NULL игнорируется в AVG
                END
    ) AS avg_days
FROM request;

-- Эквивалент через WHERE (самый простой)
SELECT
    AVG(executiondate - incomingdate) AS avg_days
FROM request
WHERE executiondate IS NOT NULL;

-- FILTER для разных условий в одном запросе
SELECT
            AVG(paysum) FILTER (WHERE servicecd = 1) AS avg_service_1,  -- Среднее по услуге 1
            SUM(paysum) FILTER (WHERE servicecd = 2) AS sum_service_2   -- Сумма по услуге 2
FROM paysumma;

-- SUM - сумма всех значений
SELECT SUM(nachisl_sum) AS total_sum
FROM nachislsumma;

-- MAX / MIN - максимальное и минимальное значение
SELECT
    MAX(paysum) AS max_payment,
    MIN(paysum) AS min_payment
FROM paysumma;

-- COUNT(*) - количество всех строк (включая NULL)
SELECT COUNT(*) AS total_rows
FROM abonent;

-- COUNT(column) - количество НЕ NULL значений
SELECT COUNT(phone) AS phones_filled  -- Не считает NULL
FROM abonent;

-- COUNT(DISTINCT column) - количество уникальных НЕ NULL значений
SELECT COUNT(DISTINCT phone) AS unique_phones
FROM abonent;

-- Комбинированный COUNT для отчёта
SELECT
    COUNT(DISTINCT AccountCD) AS "Число абонентов с заявками",  -- Уникальные абоненты
    COUNT(*) AS "Всего заявок",                                  -- Все строки
    COUNT(ExecutionDate) AS "из них выполнено",                  -- Только где есть дата
    COUNT(RequestCD) FILTER (WHERE Executed) AS "погашено"       -- Только выполненные
FROM Request;


-- ============================================================================
-- РАЗДЕЛ 25: GREATEST / LEAST
-- ============================================================================

-- GREATEST - максимальное значение из списка
-- LEAST - минимальное значение из списка
SELECT
    GREATEST(10, 20, 30) AS max_value,  -- 30
    LEAST(10, 20, 30) AS min_value;     -- 10

-- Применение к датам: заменить старые даты на минимальную границу
SELECT
    requestcd,
    GREATEST(executiondate, DATE '2020-01-01') AS "MAXVALUE"
-- Если executiondate < 2020-01-01, вернёт '2020-01-01'
FROM request
WHERE executorcd = 1;


-- ============================================================================
-- РАЗДЕЛ 26: STRING_AGG - ОБЪЕДИНЕНИЕ СТРОК
-- ============================================================================

-- STRING_AGG - конкатенация строк с разделителем (аналог GROUP_CONCAT в MySQL)
SELECT
    STRING_AGG(ServiceNM, ',') AS "Список услуг"  -- Через запятую
FROM Services;

-- С группировкой
SELECT
    ServiceCD,
    STRING_AGG(ServiceNM, ',') AS "Список услуг"
FROM Services
GROUP BY ServiceCD;

-- Только уникальные значения
SELECT
    STRING_AGG(DISTINCT ServiceNM, ',') AS "Список услуг"  -- Без повторов
FROM Services;


-- ============================================================================
-- РАЗДЕЛ 27: CASE - УСЛОВНАЯ ЛОГИКА
-- ============================================================================

-- Простой CASE с конкатенацией
SELECT
    RequestCD,
    ('Номер л/с абонента ' || AccountCD) AS "Ab_Info",
    ('Код неисправности ' || FailureCD) AS "Failure",
    CASE
        WHEN Executed = FALSE THEN 'Не погашена'
        ELSE 'Погашена'
        END AS "Status"
FROM Request
WHERE AccountCD = '115705';

-- CASE с диапазонами дат
SELECT
    pay_factcd,
    accountcd,
    paysum,
    CASE
        WHEN paydate < '2019-01-01' THEN 'Давно'
        WHEN paydate BETWEEN '2019-01-01' AND '2020-12-31' THEN 'Не очень давно'
        ELSE 'Недавно'
        END AS "Oplata"
FROM paysumma
WHERE paysum BETWEEN 530 AND 600;

-- CASE с регулярным выражением (валидация email)
-- ~* = регистронезависимое совпадение с regex
SELECT
    CASE
        WHEN :Email ~* '^[A-Z0-9._%-]+@[A-Z0-9._%-]+\.[A-Z]{2,}$' THEN 'Есть'
        ELSE 'Нет'
        END AS email_valid;

-- Вложенный CASE
SELECT
    paydate,
    CASE
        WHEN EXTRACT(DOW FROM paydate) NOT IN (0, 6) THEN 'Рабочий день'  -- DOW: 0=Вс, 6=Сб
        ELSE
            CASE
                WHEN EXTRACT(DOW FROM paydate) = 0 THEN 'Воскресенье'
                ELSE 'Суббота'
                END
        END AS day_type
FROM paysumma;

-- CASE внутри SUM для подсчёта условий
SELECT
    COUNT(*) AS "Всего заявок",
    SUM(CASE WHEN executiondate IS NULL THEN 1 ELSE 0 END) AS "невыполненных",
    SUM(CASE WHEN NOT executed THEN 1 ELSE 0 END) AS "непогашенных"
FROM request;


-- ============================================================================
-- РАЗДЕЛ 28: NULLIF и COALESCE
-- ============================================================================

-- NULLIF - возвращает NULL, если значения равны
SELECT NULLIF(Phone, Phone) FROM Abonent;  -- Всегда NULL (значение = самому себе)

-- COALESCE - возвращает первое НЕ NULL значение
SELECT COALESCE(phone, 'Нет телефона') AS phone_with_default
FROM abonent;
-- Если phone = NULL, вернёт 'Нет телефона'

-- NULLIF для исключения конкретных значений
SELECT NULLIF(phone, '556893') AS phone
FROM abonent;
-- Если phone = '556893', вернёт NULL

-- Практическое применение: найти заявки, где ExecutionDate = IncomingDate
SELECT *
FROM Request
WHERE NULLIF(ExecutionDate, IncomingDate) IS NULL;
-- Если даты равны → NULLIF вернёт NULL → IS NULL = TRUE
-- Это заявки, выполненные в день поступления (или NULL = NULL)


-- ============================================================================
-- РАЗДЕЛ 29: CASE В WHERE
-- ============================================================================

SELECT
    accountcd,
    servicecd,
    paysum
FROM paysumma
WHERE servicecd =
      CASE
          WHEN accountcd::INTEGER = 136169 THEN 1
          WHEN accountcd::INTEGER = 136160 THEN 3
          WHEN accountcd::INTEGER = 80270 THEN 4
          ELSE 2
          END;
-- Динамический выбор servicecd в зависимости от accountcd


-- ============================================================================
-- РАЗДЕЛ 30: GROUP BY И АГРЕГАЦИЯ
-- ============================================================================

-- Базовая группировка с агрегатами
SELECT
    nachisl_year,
    SUM(nachisl_sum) AS total,
    ROUND(AVG(nachisl_sum), 2) AS avg,
    MIN(nachisl_sum) AS min_val,
    MAX(nachisl_sum) AS max_val
FROM nachislsumma
GROUP BY nachisl_year;

-- Группировка по алиасу (не все СУБД поддерживают)
SELECT
    nachisl_sum AS "Summa_550",
    COUNT(*)
FROM nachislsumma
WHERE nachisl_sum > 530 AND nachisl_sum < 550
GROUP BY "Summa_550";  -- Группировка по уникальным суммам

-- Конкатенация с агрегатами
SELECT
    AccountCD,
    COUNT(*) || ' - с максимальной суммой ' || MAX(PaySum) AS "Pay_Info"
FROM PaySumma
GROUP BY AccountCD;

-- LIMIT с GROUP BY
SELECT
    AccountCD,
    PayYear,
    MIN(PaySum)
FROM PaySumma
WHERE PayYear IN (2019, 2020)
GROUP BY AccountCD, PayYear
ORDER BY AccountCD, PayYear
    FETCH NEXT 10 ROWS ONLY;  -- Только первые 10 строк (современный синтаксис)


-- ============================================================================
-- РАЗДЕЛ 31: UNION ALL
-- ============================================================================

-- Объединение результатов двух запросов (с дубликатами)
SELECT *
FROM Abonent
WHERE accountcd LIKE '%080%'  -- 3 строки
UNION ALL
SELECT *
FROM Abonent
WHERE accountcd LIKE '%443%'; -- 2 строки
-- Итого: 5 строк (если бы UNION - удалило бы дубликаты)


-- ============================================================================
-- РАЗДЕЛ 32: ГРУППИРОВКА ПО ЧАСТИ ЗНАЧЕНИЯ
-- ============================================================================

SELECT
    ('Начало счета ' || SUBSTRING(AccountCD FROM 1 FOR 3)) AS "Acc_3",
    COUNT(*)
FROM Abonent
GROUP BY "Acc_3";  -- Группировка по первым 3 цифрам счёта


-- ============================================================================
-- РАЗДЕЛ 33: ГРУППИРОВКА ПО УСЛОВИЮ (CASE в GROUP BY)
-- ============================================================================

SELECT
    'В среднем начислено ' ||
    (CASE
         WHEN nachisl_year < 2020 THEN 'до 2020 года'
         ELSE 'после 2019 года'
        END) AS "Period",
    AVG(nachisl_sum) AS "Average_Sum"
FROM nachislsumma
GROUP BY "Period";  -- Группировка по вычисляемому полю


-- ============================================================================
-- РАЗДЕЛ 34: ВЛОЖЕННЫЕ АГРЕГАТЫ С ОКОННЫМИ ФУНКЦИЯМИ
-- ============================================================================

SELECT
    servicecd,
    MAX(MAX(paysum)) OVER (PARTITION BY servicecd) AS max_avg_paysum,
    MIN(MIN(paysum)) OVER (PARTITION BY servicecd) AS min_avg_paysum
FROM paysumma
GROUP BY servicecd;
-- Сначала GROUP BY, потом оконная функция по результатам группировки


-- ============================================================================
-- РАЗДЕЛ 35: ROLLUP - ИЕРАРХИЧЕСКАЯ АГРЕГАЦИЯ
-- ============================================================================

-- ROLLUP создаёт промежуточные итоги по уровням иерархии
SELECT
    AccountCD,
    ServiceCD,
    PayYear,
    SUM(PaySum)
FROM PaySumma
GROUP BY ROLLUP (AccountCD, ServiceCD, PayYear);
-- Создаёт группы: (Account, Service, Year) → (Account, Service) → (Account) → (ВСЕГО)

-- ROLLUP с интерпретацией уровней через GROUPING
SELECT
    CASE
        WHEN GROUPING(AccountCD) = 1 AND GROUPING(ServiceCD) = 1 AND GROUPING(PayYear) = 1
                                     THEN 'ВСЕГО ПО БАЗЕ'
        WHEN GROUPING(AccountCD) = 1 THEN 'ИТОГО ПО ВСЕМ АБОНЕНТАМ'
        WHEN GROUPING(ServiceCD) = 1 THEN 'ИТОГО ПО ВСЕМ УСЛУГАМ'
        ELSE AccountCD::TEXT
        END AS "Абонент",
    CASE
        WHEN GROUPING(ServiceCD) = 1 AND GROUPING(PayYear) = 1 AND GROUPING(AccountCD) = 0
                                     THEN 'ВСЕ УСЛУГИ ЗА ВСЕ ГОДЫ'
        WHEN GROUPING(ServiceCD) = 1 THEN 'ВСЕ УСЛУГИ'
        ELSE ServiceCD::TEXT
        END AS "Услуга",
    CASE
        WHEN GROUPING(PayYear) = 1 THEN 'ВСЕ ГОДЫ'
        ELSE PayYear::TEXT
        END AS "Год",
    SUM(PaySum) AS "Сумма"
FROM PaySumma
GROUP BY ROLLUP (AccountCD, ServiceCD, PayYear)
ORDER BY AccountCD, ServiceCD, PayYear;
-- GROUPING() = 1 означает, что эта колонка агрегирована (NULL от ROLLUP)


-- ============================================================================
-- РАЗДЕЛ 36: HAVING - ФИЛЬТР ПОСЛЕ ГРУППИРОВКИ
-- ============================================================================

-- HAVING фильтрует результаты GROUP BY (WHERE фильтрует до группировки)
SELECT
    accountcd,
    COUNT(*) AS request_count,
    MIN(incomingdate) AS first_request
FROM request
GROUP BY accountcd
HAVING COUNT(*) > 2;  -- Только абоненты с более чем 2 заявками

-- Сложное условие в HAVING через CASE
SELECT
    accountcd,
    servicecd,
    MAX(paysum) AS max_payment
FROM paysumma p
GROUP BY p.accountcd, p.servicecd
HAVING (
           MAX(CASE WHEN servicecd = 2 THEN p.paysum ELSE NULL END) > 600  -- Услуга 2 > 600
               OR
           MAX(CASE WHEN servicecd = 4 THEN p.paysum ELSE NULL END) > 300  -- Услуга 4 > 300
           );

-- HAVING с агрегатом без GROUP BY (вся таблица = 1 группа)
SELECT
    MAX(IncomingDate) AS max_date
FROM Request
HAVING MAX(IncomingDate) > '31.08.2019';  -- Фильтр по результату агрегации


-- ============================================================================
-- РАЗДЕЛ 37: ORDER BY С АГРЕГАТАМИ
-- ============================================================================

SELECT
    ServiceCD,
    COUNT(ServiceCD) AS service_count,
    AVG(PaySum) AS avg_payment
FROM PaySumma
GROUP BY ServiceCD
ORDER BY
    COUNT(ServiceCD) DESC,  -- Сначала по количеству (убывание)
    AVG(PaySum);            -- Потом по средней сумме (возрастание)


-- ============================================================================
-- РАЗДЕЛ 38: ORDER BY С NULL
-- ============================================================================

-- NULLS FIRST / NULLS LAST - управление позицией NULL в сортировке
SELECT
    RequestCD,
    ExecutionDate,
    AccountCD
FROM Request
WHERE (AccountCD LIKE '08%') OR (AccountCD LIKE '11%')
ORDER BY ExecutionDate DESC NULLS FIRST;  -- NULL будут первыми при DESC


-- ============================================================================
-- РАЗДЕЛ 39: ORDER BY С CASE (КАСТОМНАЯ СОРТИРОВКА)
-- ============================================================================

-- Приоритет услуг: 3 → 1 → 2 → 4 → остальные
SELECT
    AccountCD,
    ServiceCD,
    PaySum
FROM PaySumma
ORDER BY
    CASE ServiceCD
        WHEN 3 THEN 1      -- Услуга 3 первая (код сортировки = 1)
        WHEN 1 THEN 2      -- Услуга 1 вторая
        WHEN 2 THEN 3      -- Услуга 2 третья
        WHEN 4 THEN 4      -- Услуга 4 четвёртая
        ELSE 5             -- Остальные последние
        END;

-- Сортировка по статусу выполнения
SELECT
    RequestCD,
    ExecutionDate,
    Executed,
    AccountCD
FROM Request
ORDER BY
    CASE
        WHEN Executed = FALSE AND ExecutionDate IS NULL THEN 1   -- Не выполнена
        WHEN Executed = FALSE AND ExecutionDate IS NOT NULL THEN 2 -- Выполнена, не погашена
        WHEN Executed = TRUE THEN 3                               -- Выполнена и погашена
        ELSE 4
        END;

-- Сортировка по разным типам данных в зависимости от условия
SELECT
    AccountCD,
    ServiceCD,
    PaySum,
    PayDate
FROM PaySumma
ORDER BY
    CASE
        WHEN ServiceCD = 1 THEN PaySum::TEXT      -- Услуга 1: сортировка по сумме
        WHEN ServiceCD = 2 THEN PayDate::TEXT     -- Услуга 2: сортировка по дате
        WHEN ServiceCD = 3 THEN AccountCD::TEXT   -- Услуга 3: сортировка по счёту
        ELSE PaySum::TEXT
        END;
-- Все ветви CASE должны возвращать один тип данных (приводим к TEXT)