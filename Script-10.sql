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


GRANT USAGE ON SCHEMA postgres_air TO postgres;
GRANT SELECT ON postgres_air.pg_stat_statements TO postgres;

-- Создать view-синоним в схеме bookings
CREATE OR REPLACE VIEW bookings.pg_stat_statements AS 
SELECT * FROM postgres_air.pg_stat_statements;

GRANT SELECT ON bookings.pg_stat_statements TO postgres;

SELECT * FROM bookings.pg_stat_statements;



SELECT 
    query as "Запрос",
    calls as "Вызовы",
    round(total_exec_time::numeric, 2) as "Общее время (мс)",
    round(mean_exec_time::numeric, 2) as "Среднее время (мс)",
    round((100 * total_exec_time / sum(total_exec_time) OVER ())::numeric, 2) as "Процент от общего времени",
    CASE 
        WHEN mean_exec_time < 10 THEN '✅ ОЧЕНЬ БЫСТРЫЙ (<10ms)'
        WHEN mean_exec_time < 50 THEN '⚡ БЫСТРЫЙ (10-50ms)'
        WHEN mean_exec_time < 100 THEN '🔶 СРЕДНИЙ (50-100ms)'
        WHEN mean_exec_time < 1000 THEN '⚠️ МЕДЛЕННЫЙ (100ms-1s)'
        ELSE '🚨 ОЧЕНЬ МЕДЛЕННЫЙ (>1s)'
    END as "Категория",
    rows as "Строк возвращено",
    round(rows::numeric / calls, 2) as "Строк на вызов"
FROM pg_stat_statements 
WHERE calls > 0
    -- Исключаем системные схемы и служебные запросы
    AND query NOT LIKE '%pg_%'  -- Системные таблицы PostgreSQL
    AND query NOT LIKE '%information_schema%'  -- Информационная схема
    AND query NOT ILIKE '%pg_stat_statements%'  -- Запросы к самой статистике
    AND query NOT ILIKE '%pg_catalog%'  -- Системный каталог
    AND query NOT ILIKE '%pg_toast%'  -- TOAST таблицы
    AND query NOT ILIKE '%pg_temp%'  -- Временные таблицы
    AND query NOT ILIKE '%pg_toast_temp%'  -- Временные TOAST таблицы
    -- Исключаем служебные SQL команды
    AND query NOT ILIKE 'DEALLOCATE%'
    AND query NOT ILIKE 'DISCARD%'
    AND query NOT ILIKE 'FETCH%'
    AND query NOT ILIKE 'CLOSE%'
    AND query NOT ILIKE 'SET %'
    AND query NOT ILIKE 'RESET %'
    AND query NOT ILIKE 'SHOW %'
    -- Исключаем короткие служебные запросы
    AND length(trim(query)) > 20
    -- Дополнительная проверка: запрос должен содержать обращения к таблицам (не только служебные команды)
    AND (query ILIKE '%FROM %' OR query ILIKE '%JOIN %' OR query ILIKE '%UPDATE %' OR query ILIKE '%INSERT %')
ORDER BY mean_exec_time DESC
LIMIT 50;


