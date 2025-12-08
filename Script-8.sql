SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration, -- Длительность выполнения
    query, -- Текст текущего запроса
    state
FROM pg_stat_activity



CREATE EXTENSION IF NOT EXISTS pg_stat_statements SCHEMA postgres_air

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';
SELECT count(*) FROM pg_stat_statements;

SELECT
    query, -- Текст запроса (нормализованный)
    calls, -- Количество выполнений
    total_exec_time, -- Общее время выполнения (мс)
    mean_exec_time, -- Среднее время выполнения (мс)
    rows, -- Общее количество возвращенных строк
    (total_exec_time / calls) AS avg_time_per_call
FROM pg_stat_statements
WHERE calls > 0
ORDER BY mean_exec_time DESC
LIMIT 10;


SELECT name, default_version, installed_version 
FROM pg_available_extensions 
WHERE name = 'pg_stat_statements';


SELECT name, setting, context 
FROM pg_settings 
WHERE name LIKE '%preload_libraries%' OR name LIKE '%pg_stat_statements%';


SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_stat_statements';


SELECT 
    calls,
    total_exec_time,
    query 
FROM pg_stat_statements 
LIMIT 10;

SELECT current_user, current_database();


SELECT 
    has_schema_privilege(current_user, 'public', 'USAGE') as has_public_usage,
    has_table_privilege(current_user, 'pg_stat_statements', 'SELECT') as has_select_on_pg_stat_statements;


SELECT 
    e.extname as extension_name,
    n.nspname as schema_name,
    r.rolname as owner_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
JOIN pg_roles r ON e.extowner = r.oid
WHERE e.extname = 'pg_stat_statements';

-- Классификация запросов по времени выполнения
SELECT 
    CASE 
        WHEN mean_exec_time < 10 THEN 'Очень быстрые (<10ms)'
        WHEN mean_exec_time < 100 THEN 'Быстрые (10-100ms)' 
        WHEN mean_exec_time < 1000 THEN 'Средние (100ms-1s)'
        ELSE 'Медленные (>1s)'
    END as category,
    COUNT(*) as query_count,
    SUM(calls) as total_calls,
    ROUND(AVG(mean_exec_time), 2) as avg_time
FROM pg_stat_statements 
WHERE calls > 0
GROUP BY 1
ORDER BY avg_time DESC;







WITH acc AS (
  SELECT * FROM (VALUES
    (1, 'CUS001'::text, '4070281000000001'::text, '2024-01-01'::date, '2024-12-31'::date),
    (2, 'CUS001', '4070281000000002', '2024-03-01', '2024-06-30'),
    (3, 'CUS002', '4070281000000003', '2024-07-02', NULL),
    (4, 'CUS003', '4070281000000004', '2024-08-15', NULL)
  ) AS t(id, icusnum, acc, date_beg, date_end)
),

oborot AS (
  SELECT * FROM (VALUES
    ('4070281000000001'::text, '2024-01-31'::date, '2024-02-15'::date, 100000::numeric),
    ('4070281000000001', '2024-02-27', '2024-02-29', 150000),
    ('4070281000000001', '2024-03-31', '2024-03-31', 200000),
    ('4070281000000001', '2024-04-30', '2024-04-30', 180000),
    ('4070281000000002', '2024-03-31', '2024-03-31', 50000),
    ('4070281000000002', '2024-04-30', '2024-04-30', 75000),
    ('4070281000000002', '2024-05-31', '2024-05-31', 60000),
    ('4070281000000002', '2024-06-30', '2024-06-30', 30000),
    ('4070281000000003', '2024-07-28', '2024-07-29', 200000),
    ('4070281000000003', '2024-08-01', '2024-08-02', 250000),
    ('4070281000000004', '2024-08-14', '2024-08-17', 300000),
    ('4070281000000004', '2024-08-18', '2024-08-22', 350000)
  ) AS t(acc, date_beg, date_end, summa_ob)
)

SELECT 
  a.acc,
  a.icusnum,
  GREATEST(a.date_beg, o.date_beg) as intersect_beg,
  LEAST(a.date_end, o.date_end) as intersect_end,
  o.summa_ob,
  CASE 
    WHEN a.date_end IS NULL THEN 'open'
    ELSE 'closed' 
  END as status
FROM acc a
JOIN oborot o ON a.acc = o.acc
WHERE GREATEST(a.date_beg, o.date_beg) <= 
      LEAST(a.date_end, o.date_end)
ORDER BY o.date_beg, o.date_end;






WITH acc AS (
  SELECT * FROM (VALUES
    (1, 'CUS001'::text, '4070281000000001'::text, '2024-01-01'::date, '2024-12-31'::date),
    (2, 'CUS001', '4070281000000002', '2024-03-01', '2024-06-30'),
    (3, 'CUS002', '4070281000000003', '2024-07-02', NULL),
    (4, 'CUS003', '4070281000000004', '2024-08-15', NULL)
  ) AS t(id, icusnum, acc, date_beg, date_end)
),

oborot AS (
  SELECT * FROM (VALUES
    ('4070281000000001'::text, '2024-01-31'::date, '2024-02-15'::date, 100000::numeric),
    ('4070281000000001', '2024-02-27', '2024-02-29', 150000),
    ('4070281000000001', '2024-03-31', '2024-03-31', 200000),
    ('4070281000000001', '2024-04-30', '2024-04-30', 180000),
    ('4070281000000002', '2024-03-31', '2024-03-31', 50000),
    ('4070281000000002', '2024-04-30', '2024-04-30', 75000),
    ('4070281000000002', '2024-05-31', '2024-05-31', 60000),
    ('4070281000000002', '2024-06-30', '2024-06-30', 30000),
    ('4070281000000003', '2024-07-28', '2024-07-29', 200000),
    ('4070281000000003', '2024-08-01', '2024-08-02', 250000),
    ('4070281000000004', '2024-08-14', '2024-08-17', 300000),
    ('4070281000000004', '2024-08-18', '2024-08-22', 350000)
  ) AS t(acc, date_beg, date_end, summa_ob)
)

SELECT 
  a.acc,
  a.icusnum,
  a.date_beg as acc_date_beg,  -- date_beg из таблицы счетов
  a.date_end as acc_date_end,  -- date_end из таблицы счетов
  o.date_beg as ob_date_beg,   -- date_beg из таблицы оборотов
  o.date_end as ob_date_end,   -- date_end из таблицы оборотов
  GREATEST(a.date_beg, o.date_beg) as intersect_beg,
  LEAST(COALESCE(a.date_end, o.date_end), o.date_end) as intersect_end,
  o.summa_ob,
  CASE 
    WHEN a.date_end IS NULL THEN 'open'
    ELSE 'closed' 
  END as status
FROM acc a
JOIN oborot o ON a.acc = o.acc
WHERE GREATEST(a.date_beg, o.date_beg) <= LEAST(COALESCE(a.date_end, o.date_end), o.date_end)
ORDER BY a.icusnum, a.acc, o.date_beg;