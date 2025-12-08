----1. Поиск пересекающихся периодов действия карт клиентов

CREATE TABLE bank_cards (
    card_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    card_number VARCHAR(20) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    card_type VARCHAR(20) NOT NULL
);

INSERT INTO bank_cards (client_id, card_number, valid_from, valid_to, card_type) VALUES
(1, '4276********1234', '2023-01-01', '2025-12-31', 'DEBIT'),
(1, '4276********5678', '2024-06-01', '2026-05-31', 'CREDIT'),
(1, '4276********9012', '2024-01-01', '2024-12-31', 'DEBIT'),
(2, '5469********1111', '2023-03-01', '2025-02-28', 'DEBIT'),
(2, '5469********2222', '2024-09-01', '2026-08-31', 'CREDIT'),
(3, '4276********3333', '2024-01-01', '2024-12-31', 'DEBIT'),
(3, '4276********4444', '2024-07-01', '2025-06-30', 'DEBIT');


--Задача: Найти клиентов, 
--у которых пересекаются периоды действия карт
EXPLAIN ANALYZE 
SELECT 
    c1.client_id,
    c1.card_number as card_1,
    c2.card_number as card_2,
    GREATEST(c1.valid_from, c2.valid_from) as overlap_start,
    LEAST(c1.valid_to, c2.valid_to)        as overlap_end
FROM bank_cards c1
JOIN bank_cards c2 ON c1.client_id = c2.client_id 
                   AND c1.card_id < c2.card_id
                   AND c1.valid_from <= c2.valid_to 
                   AND c1.valid_to >= c2.valid_from
WHERE c1.card_type = c2.card_type  -- Ищем пересечения карт одного типа
ORDER BY c1.client_id, overlap_start;


/*(daterange(c1.valid_from, c1.valid_to, '[]') * daterange(c2.valid_from, c2.valid_to, '[]'))
  * это оператор ПЕРЕСЕЧЕНИЯ (intersection)
Можно также извлечь границы пересечения
Аналогия с математикой множеств
Представьте, что это как операции с множествами:
A && B = "множества A и B пересекаются?" (да/нет)
A * B = "найти пересечение множеств A и B" (новое множество)
Что означает '[]' в daterange?
Третий параметр '[]' определяет, включаются ли границы:
'[)' - включить начальную дату, исключить конечную (по умолчанию)
'()' - исключить обе границы
'[]' - включить обе границы
'(]' - исключить начальную, включить конечную 

daterange('2024-01-01', '2024-01-31', '[]')  -- включает и 1 и 31 января
daterange('2024-01-01', '2024-01-31', '[)')  -- включает 1, но исключает 31 января
&& в JOIN - фильтрует только те пары карт, у которых есть пересечение периодов

-- && - пересекается с (overlaps)
daterange1 && daterange2
-- @> - содержит (contains)
daterange1 @> daterange2      -- содержит весь диапазон
daterange1 @> '2024-01-15'    -- содержит конкретную дату
-- <@ - содержится в (contained by)
daterange1 <@ daterange2
-- << - строго левее (strictly left of)
daterange1 << daterange2
-- >> - строго правее (strictly right of)  
daterange1 >> daterange2
-- &< - не extends правее (does not extend to the right of)
daterange1 &< daterange2
-- &> - не extends левее (does not extend to the left of)
daterange1 &> daterange2
-- -|- - примыкает (adjacent to)
daterange1 -|- daterange2
*/

EXPLAIN ANALYZE 
SELECT 
    c1.client_id,
    c1.card_number as card_1,
    c2.card_number as card_2,
    -- Используем daterange для определения пересечения
    (daterange(c1.valid_from, c1.valid_to, '[]') * daterange(c2.valid_from, c2.valid_to, '[]')) 
    as overlap_period,
    LOWER(daterange(c1.valid_from, c1.valid_to, '[]') * daterange(c2.valid_from, c2.valid_to, '[]')) as overlap_start,
    UPPER(daterange(c1.valid_from, c1.valid_to, '[]') * daterange(c2.valid_from, c2.valid_to, '[]')) as overlap_end
---LOWER() - НИЖНЯЯ ГРАНИЦА (начало диапазона)
---UPPER() - ВЕРХНЯЯ ГРАНИЦА (конец диапазона) 
FROM bank_cards c1
JOIN bank_cards c2 ON c1.client_id = c2.client_id 
                   AND c1.card_id < c2.card_id
                   AND daterange(c1.valid_from, c1.valid_to, '[]') 
                   && daterange (c2.valid_from, c2.valid_to, '[]')
WHERE c1.card_type = c2.card_type
ORDER BY c1.client_id, overlap_start;




-- Создание таблиц с обычными датами (без generated columns)
CREATE TABLE acc (
    acc_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    account_number VARCHAR(20) NOT NULL UNIQUE,
    first_order_account VARCHAR(10) NOT NULL,
    second_order_account VARCHAR(10) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('current', 'credit', 'deposit', 'card')),
    open_date DATE NOT NULL,
    close_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cdh (
    cdh_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    credit_type VARCHAR(30) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    credit_status VARCHAR(20) NOT NULL CHECK (credit_status IN ('active', 'closed', 'overdue')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE saldo (
    saldo_id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL,
    balance_date DATE NOT NULL,
    balance DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/*
-- Создание индексов
CREATE INDEX idx_acc_client_id ON acc(client_id);
CREATE INDEX idx_acc_dates ON acc(open_date, close_date);
CREATE INDEX idx_acc_account_number ON acc(account_number);
CREATE INDEX idx_cdh_client_id ON cdh(client_id);
CREATE INDEX idx_cdh_dates ON cdh(start_date, end_date);
CREATE INDEX idx_cdh_account_number ON cdh(account_number);
CREATE INDEX idx_saldo_account_number ON saldo(account_number);
CREATE INDEX idx_saldo_date ON saldo(balance_date);
*/

-- Заполнение таблицы счетов (acc) - открытые и закрытые счета
INSERT INTO acc (client_id, account_number, first_order_account, second_order_account, account_type, open_date, close_date) VALUES
-- Клиент 1: открытые и закрытые счета
(1, '40702810100010000001', '40702', '81010', 'current', '2023-01-01', NULL),
(1, '45201810100010000002', '45201', '81010', 'credit', '2023-02-01', NULL),
(1, '42301810100010000003', '42301', '81010', 'deposit', '2023-03-01', '2024-03-01'),
(1, '40817810100010000004', '40817', '81010', 'card', '2022-12-01', '2023-12-31'),
-- Клиент 2: открытые и закрытые счета
(2, '40702810200020000001', '40702', '81020', 'current', '2023-04-01', NULL),
(2, '45201810200020000002', '45201', '81020', 'credit', '2023-05-01', '2024-05-01'),
(2, '42301810200020000003', '42301', '81020', 'deposit', '2022-11-01', '2023-11-01'),
-- Клиент 3: только открытые счета
(3, '40702810300030000001', '40702', '81030', 'current', '2023-06-01', NULL),
(3, '45201810300030000002', '45201', '81030', 'credit', '2023-07-01', NULL);

-- Заполнение таблицы кредитов (cdh) - открытые и закрытые кредиты
INSERT INTO cdh (client_id, account_number, credit_type, start_date, end_date, amount, interest_rate, credit_status) VALUES
-- Клиент 1: активные и закрытые кредиты
(1, '45201810100010000002', 'consumer', '2023-02-01', '2024-02-01', 100000, 12.5, 'closed'),
(1, '45201810100010000002', 'consumer', '2024-02-02', '2025-02-02', 150000, 11.5, 'active'),
(1, '45201810100010000002', 'mortgage', '2023-01-15', '2043-01-15', 3000000, 8.2, 'active'),
-- Клиент 2: закрытый кредит
(2, '45201810200020000002', 'auto_loan', '2023-05-01', '2024-05-01', 800000, 9.8, 'closed'),
-- Клиент 3: активный кредит
(3, '45201810300030000002', 'business', '2023-07-01', '2026-07-01', 2000000, 10.5, 'active');

-- Заполнение таблицы остатков (saldo) - с нулевыми остатками для закрытых кредитов
INSERT INTO saldo (account_number, balance_date, balance) VALUES
-- Остатки по счетам клиента 1
('40702810100010000001', '2024-01-15', 150000.50),
('40702810100010000001', '2024-01-31', 180000.75),
('40702810100010000001', '2024-02-15', 220000.25),

('45201810100010000002', '2024-01-15', -50000.25),
('45201810100010000002', '2024-01-31', -45000.75),
('45201810100010000002', '2024-02-01', 0.00), -- Закрытие первого кредита
('45201810100010000002', '2024-02-15', -75000.00), -- Новый кредит
('45201810100010000002', '2024-02-28', -72000.50),

-- Остатки по закрытому счету клиента 1
('40817810100010000004', '2023-12-15', 0.00),

-- Остатки по счетам клиента 2
('40702810200020000001', '2024-01-20', 300000.00),
('40702810200020000001', '2024-01-31', 350000.00),

('45201810200020000002', '2024-01-20', -480000.00),
('45201810200020000002', '2024-04-30', -100000.00),
('45201810200020000002', '2024-05-01', 0.00), -- Закрытие кредита

-- Остатки по счетам клиента 3
('40702810300030000001', '2024-01-25', 500000.00),
('45201810300030000002', '2024-01-25', -1800000.00);


-- 1. Запрос пересечения счетов с кредитами (аналогично вашему примеру)
SELECT 
    a.client_id,
    a.account_number as acc_number,
    c.account_number as credit_acc_number,
    a.account_type,
    a.first_order_account,
    a.second_order_account,
    c.credit_type,
    c.amount as credit_amount,
    c.credit_status,
    -- Используем daterange для определения пересечения
    (daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]'))     as overlap_period,
    LOWER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_start,
    UPPER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_end
FROM acc a
JOIN cdh c ON a.client_id = c.client_id 
           AND daterange(a.open_date, a.close_date, '[]') && daterange(c.start_date, c.end_date, '[]')
ORDER BY a.client_id, overlap_start;

-- 2. Запрос пересечения счетов с кредитами и остатками
SELECT 
    a.client_id,
    a.account_number as acc_number,
    a.account_type,
    c.credit_type,
    c.credit_status,
    s.balance_date,
    s.balance,
    -- Пересечение счета и кредита
    (daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as acc_cdh_overlap,
    LOWER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_start,
    UPPER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_end,
    -- Проверка что остаток попадает в период пересечения
    CASE 
        WHEN s.balance_date BETWEEN 
            LOWER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) AND
            UPPER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]'))
        THEN 'VALID_BALANCE'
        ELSE 'INVALID_BALANCE'
    END as balance_validity
FROM acc a
JOIN cdh c ON a.client_id = c.client_id 
           AND daterange(a.open_date, a.close_date, '[]') && daterange(c.start_date, c.end_date, '[]')
JOIN saldo s ON a.account_number = s.account_number
WHERE daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]') IS NOT NULL
ORDER BY a.client_id, overlap_start, s.balance_date;

-- 3. Детальный анализ пересечений с группировкой
WITH overlap_data AS (
    SELECT 
        a.client_id,
        a.account_number,
        a.account_type,
        c.credit_type,
        c.credit_status,
        (daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_range,
        LOWER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_start,
        UPPER(daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_end
    FROM acc a
    JOIN cdh c ON a.client_id = c.client_id 
               AND daterange(a.open_date, a.close_date, '[]') && daterange(c.start_date, c.end_date, '[]')
    WHERE daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]') IS NOT NULL
)
SELECT 
    od.client_id,
    od.account_number,
    od.account_type,
    od.credit_type,
    od.credit_status,
    od.overlap_start,
    od.overlap_end,
    COUNT(s.saldo_id) as balance_records_count,
    AVG(s.balance) as average_balance,
    MIN(s.balance) as min_balance,
    MAX(s.balance) as max_balance
FROM overlap_data od
LEFT JOIN saldo s ON od.account_number = s.account_number 
                  AND s.balance_date BETWEEN od.overlap_start AND od.overlap_end
GROUP BY 
    od.client_id, od.account_number, od.account_type, od.credit_type, 
    od.credit_status, od.overlap_start, od.overlap_end
ORDER BY od.client_id, od.overlap_start;

-- 4. Поиск всех остатков в периоде пересечения счетов и кредитов
SELECT 
    a.client_id,
    a.account_number,
    a.account_type,
    c.credit_type,
    s.balance_date,
    s.balance,
    daterange(a.open_date, a.close_date, '[]') as account_range,
    daterange(c.start_date, c.end_date, '[]') as credit_range,
    (daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]')) as overlap_range
FROM acc a
JOIN cdh c ON a.client_id = c.client_id 
JOIN saldo s ON a.account_number = s.account_number
WHERE daterange(a.open_date, a.close_date, '[]') && daterange(c.start_date, c.end_date, '[]')
  AND s.balance_date <@ (daterange(a.open_date, a.close_date, '[]') * daterange(c.start_date, c.end_date, '[]'))
ORDER BY a.client_id, s.balance_date;

/*Комбинирование grouping sets, cube, rollup*/

CREATE TABLE sales (
    region VARCHAR(20),
    product VARCHAR(20),
    year INTEGER,
    amount DECIMAL(10,2)
);

INSERT INTO sales VALUES
('North', 'Product A', 2023, 1000),
('North', 'Product A', 2024, 1200),
('North', 'Product B', 2023, 800),
('North', 'Product B', 2024, 900),
('South', 'Product A', 2023, 1500),
('South', 'Product A', 2024, 1600),
('South', 'Product B', 2023, 700),
('South', 'Product B', 2024, 850);


-- GROUPING SETS пример
SELECT 
    region,
    product,
    year,
    SUM(amount) as total_amount,
    GROUPING(region, product, year) as grouping_id
FROM sales
GROUP BY GROUPING SETS (
    (region, product, year),    -- Детальная группировка
    (region, product),          -- Итоги по региону и продукту
    (region),                   -- Итоги по региону
    ()                          -- Общий итог
)
ORDER BY region, product, year;



-- ROLLUP создает все комбинации иерархии слева направо
SELECT 
    region,
    product,
    year,
    SUM(amount) as total_amount,
    GROUPING(region) as g_region,
    GROUPING(product) as g_product,
    GROUPING(year) as g_year
FROM sales
GROUP BY ROLLUP 
(region, product, year)
ORDER BY region, product, year;

/*
GROUP BY GROUPING SETS (
    (region, product, year),    -- Детальные данные
    (region, product),          -- Итоги по региону и продукту
    (region),                   -- Итоги по региону
    ()                          -- Общий итог
*/
)


----CUBE создает все возможные комбинации группировки.


SELECT 
    region,
    product,
    year,
    SUM(amount) as total_amount,
    GROUPING(region) as g_region,
    GROUPING(product) as g_product,
    GROUPING(year) as g_year
FROM sales
GROUP BY CUBE (region, product, year)
ORDER BY region, product, year;

/*Эквивалентно 
 * GROUP BY GROUPING SETS (
    (region, product, year),    -- Детальные данные
    (region, product),          -- Итоги по региону и продукту
    (region, year),             -- Итоги по региону и году
    (product, year),            -- Итоги по продукту и году
    (region),                   -- Итоги по региону
    (product),                  -- Итоги по продукту
    (year),                     -- Итоги по году
    ()                          -- Общий итог
)
 * 
 * */
TRUNCATE sales_having 
INSERT INTO sales_having  (region, product_category, product_name, sales_date, quantity, unit_price, salesperson) VALUES
-- Северный регион с разными значениями
('North', 'Electronics', 'Laptop', '2024-01-15', 1, 1200.00, 'Ivan Petrov'),
('North', 'Electronics', 'Laptop', '2024-01-20', 10, 1200.00, 'Ivan Petrov'), -- Большая продажа
('North', 'Electronics', 'Smartphone', '2024-02-05', 2, 800.00, 'Ivan Petrov'),
('North', 'Electronics', 'Tablet', '2024-02-10', 1, 600.00, 'Ivan Petrov'),

('North', 'Furniture', 'Office Chair', '2024-01-25', 1, 250.00, 'Maria Ivanova'),
('North', 'Furniture', 'Office Chair', '2024-02-15', 8, 250.00, 'Maria Ivanova'), -- Большая партия
('North', 'Furniture', 'Desk', '2024-02-20', 1, 450.00, 'Maria Ivanova'),

('North', 'Books', 'Programming Guide', '2024-01-30', 20, 45.00, 'Alexey Sidorov'), -- Много книг
('North', 'Books', 'Programming Guide', '2024-02-25', 2, 45.00, 'Alexey Sidorov'),
('North', 'Books', 'Design Patterns', '2024-02-28', 1, 60.00, 'Alexey Sidorov'),

-- Южный регион с экстремальными значениями
('South', 'Electronics', 'Laptop', '2024-01-18', 1, 1200.00, 'Olga Volkova'),
('South', 'Electronics', 'Laptop', '2024-02-12', 15, 1200.00, 'Olga Volkova'), -- Очень большая продажа
('South', 'Electronics', 'Smartphone', '2024-02-18', 3, 800.00, 'Olga Volkova'),

('South', 'Furniture', 'Office Chair', '2024-01-22', 1, 250.00, 'Sergey Kozlov'),
('South', 'Furniture', 'Office Chair', '2024-02-22', 12, 250.00, 'Sergey Kozlov'), -- Большая партия
('South', 'Furniture', 'Desk', '2024-02-25', 1, 450.00, 'Sergey Kozlov'),

('South', 'Books', 'Programming Guide', '2024-02-08', 25, 45.00, 'Elena Popova'), -- Очень много книг
('South', 'Books', 'Programming Guide', '2024-02-16', 1, 45.00, 'Elena Popova'), -- Очень мало книг
('South', 'Books', 'Design Patterns', '2024-02-20', 2, 60.00, 'Elena Popova'),

-- Восточный регион
('East', 'Electronics', 'Tablet', '2024-01-28', 1, 600.00, 'Dmitry Orlov'),
('East', 'Electronics', 'Tablet', '2024-02-03', 6, 600.00, 'Dmitry Orlov'),
('East', 'Furniture', 'Desk', '2024-02-18', 1, 450.00, 'Dmitry Orlov'),
('East', 'Books', 'Design Patterns', '2024-02-22', 1, 60.00, 'Anna Smirnova'),

-- Западный регион
('West', 'Electronics', 'Laptop', '2024-02-01', 1, 1200.00, 'Pavel Novikov'),
('West', 'Electronics', 'Smartphone', '2024-02-20', 1, 800.00, 'Pavel Novikov'),
('West', 'Furniture', 'Office Chair', '2024-02-25', 1, 250.00, 'Natalia Frolova');


SELECT 
    region,
    SUM(quantity * unit_price) as total_revenue
FROM sales_having
GROUP BY region
HAVING SUM(quantity * unit_price) > 20000
ORDER BY total_revenue DESC;


----Пример 3: Продавцы с более чем 2 продажами
SELECT 
    salesperson,
    COUNT(*) as sales_count,
    SUM(quantity * unit_price) as total_revenue
FROM sales_having
GROUP BY salesperson
HAVING COUNT(*) > 2
ORDER BY sales_count DESC;

---Пример 6: Месяцы с выручкой более 3000
SELECT 
    EXTRACT(MONTH FROM sales_date) as month_number,
    TO_CHAR(sales_date, 'Month') as month_name,
    SUM(quantity * unit_price) as monthly_revenue,
    COUNT(*) as sales_count
FROM sales_having
GROUP BY EXTRACT(MONTH FROM sales_date), TO_CHAR(sales_date, 'Month')
HAVING SUM(quantity * unit_price) > 3000
ORDER BY month_number;



SELECT 
    region,
    product_category,
    SUM(quantity * unit_price) as category_revenue,
    AVG(unit_price) as avg_unit_price
FROM sales_having
WHERE product_category = 'Electronics' AND sales_date BETWEEN '2024-01-01' AND '2024-02-29'
GROUP BY region, product_category
HAVING SUM(quantity * unit_price) > 1000
ORDER BY category_revenue DESC;


----Пример 8: Продавцы с высокой эффективностью в определенном регионе
SELECT 
    salesperson,
    region,
    COUNT(*) as sales_count,
    SUM(quantity * unit_price) as total_revenue,
    AVG(quantity * unit_price) as avg_sale_value
FROM sales_having
WHERE region = 'North'
GROUP BY salesperson, region
HAVING COUNT(*) >= 2 
   AND AVG(quantity * unit_price) > 400
ORDER BY total_revenue DESC;


----Пример 10: Анализ сезонности по месяцам

SELECT 
    EXTRACT(MONTH FROM sales_date) as month,
    TO_CHAR(sales_date, 'Month') as month_name,
    SUM(quantity) as total_units_sold,
    SUM(quantity * unit_price) as total_revenue,
    COUNT(DISTINCT product_category) as unique_categories
FROM sales_having
GROUP BY EXTRACT(MONTH FROM sales_date), TO_CHAR(sales_date, 'Month')
HAVING SUM(quantity * unit_price) > 2000
  AND COUNT(DISTINCT product_category) >= 2
ORDER BY month;


---Пример 11: Комбинирование агрегатных функций в HAVING
-- Сначала посмотрим на общую выручку по регионам и категориям
SELECT 
    region,
    product_category,
    COUNT(*) as sales_count,
    SUM(quantity * unit_price) as total_revenue,
    MAX(quantity * unit_price) as max_sale_value,
    MIN(quantity * unit_price) as min_sale_value,
    AVG(quantity * unit_price) as avg_sale_value,
    -- Проверим условия HAVING
    MAX(quantity * unit_price) / AVG(quantity * unit_price) * 100 as max_vs_avg_ratio,
/*Показывает: Во сколько раз максимальная продажа больше средней продажи
Пример: Если ratio = 3.5, значит самая крупная продажа в 3.5 раза больше средней*/
    MIN(quantity * unit_price) / AVG(quantity * unit_price) * 100 as min_vs_avg_ratio
 /*Показывает: Какую долю от средней продажи составляет минимальная продажа
Пример: Если ratio = 0.3, значит самая маленькая продажа составляет 30% от средней*/
FROM sales_having
GROUP BY region, product_category
ORDER BY region, product_category;


SELECT 
    region,
    product_category,
    MAX(quantity * unit_price) as max_sale_value,
    MIN(quantity * unit_price) as min_sale_value,
    AVG(quantity * unit_price) as avg_sale_value
FROM  sales_having
GROUP BY region, product_category
HAVING MAX(quantity * unit_price) > 2 * AVG(quantity * unit_price)
    OR MIN(quantity * unit_price) < 0.5 * AVG(quantity * unit_price)
ORDER BY region, product_category;