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



SELECT 
    query as "Запрос",
    calls as "Вызовы",
    -- Время выполнения
    round(total_exec_time::numeric, 2) as "Общее_мс",
    round((total_exec_time / 1000)::numeric, 2) as "Общее_сек",
    round((total_exec_time / 60000)::numeric, 2) as "Общее_мин",
    round(mean_exec_time::numeric, 2) as "Среднее_мс", 
    round((mean_exec_time / 1000)::numeric, 2) as "Среднее_сек",
    -- Процент от общего времени с графиком
    round(percent_of_total::numeric, 2) as "Процент_%",
    repeat('█', greatest(1, (percent_of_total * 2)::int)) || 
    repeat('░', 20 - greatest(1, (percent_of_total * 2)::int)) as "Прогресс_бар",
    -- Категория производительности
    performance_category as "Категория",
    -- График скорости выполнения
    speed_chart as "Скорость",
    -- Статистика по строкам
    rows as "Всего_строк",
    round(rows_per_call, 2) as "Строк_за_вызов",
    CASE 
        WHEN rows_per_sec > 0 THEN round(rows_per_sec::numeric, 2)
        ELSE 0
    END as "Строк_в_сек"
FROM (
    SELECT *,
        (100 * total_exec_time / sum(total_exec_time) OVER ()) as percent_of_total,
        (rows::numeric / calls) as rows_per_call,
        CASE 
            WHEN total_exec_time > 0 THEN (rows * 1000 / total_exec_time)
            ELSE 0
        END as rows_per_sec,
        CASE 
            WHEN mean_exec_time < 10 THEN '✅ ОЧЕНЬ БЫСТРЫЙ'
            WHEN mean_exec_time < 50 THEN '⚡ БЫСТРЫЙ' 
            WHEN mean_exec_time < 100 THEN '🔶 СРЕДНИЙ'
            WHEN mean_exec_time < 1000 THEN '⚠️ МЕДЛЕННЫЙ'
            ELSE '🚨 ОЧЕНЬ МЕДЛЕННЫЙ'
        END as performance_category,
        CASE 
            WHEN mean_exec_time < 10 THEN '▁▂▃▄▅▆▇█░░'
            WHEN mean_exec_time < 25 THEN '▁▂▃▄▅▆▇█▇░'
            WHEN mean_exec_time < 50 THEN '▁▂▃▄▅▆▇██▅'
            WHEN mean_exec_time < 100 THEN '▁▂▃▄▅▆▇██▇'
            WHEN mean_exec_time < 500 THEN '▁▂▃▄▅▆▇███'
            ELSE '▁▂▃▄▅▆▇████'
        END as speed_chart
    FROM pg_stat_statements 
    WHERE calls > 0
        AND query NOT LIKE '%pg_%'
        AND query NOT LIKE '%information_schema%'
        AND query NOT ILIKE '%pg_stat_statements%'
        AND query NOT ILIKE '%pg_catalog%'
        AND query NOT ILIKE 'SET %'
        AND query NOT ILIKE 'RESET %'
        AND length(trim(query)) > 20
        AND (query ILIKE '%FROM %' OR query ILIKE '%JOIN %' OR query ILIKE '%UPDATE %' OR query ILIKE '%INSERT %')
) as stats
ORDER BY mean_exec_time DESC
LIMIT 50;


-- Включить/выключить методы соединения
SET enable_nestloop = on/off;
SET enable_hashjoin = on/off; 
SET enable_mergejoin = on/off;

-- Контроль методов доступа
SET enable_seqscan = on/off;
SET enable_indexscan = on/off;
SET enable_bitmapscan = on/off;

-- Контроль агрегаций
SET enable_hashagg = on/off;
SET enable_groupagg = on/off;


SELECT * FROM pg_available_extensions WHERE name LIKE '%hint%';
-- Если pg_hint_plan не установлен
CREATE EXTENSION pg_hint_plan;

SELECT * FROM pg_extension;


/*+ HashJoin(orders customers) */
EXPLAIN (ANALYZE, COSTS OFF)
SELECT * FROM orders 
JOIN customers ON orders.customer_id = customers.id;







CREATE OR REPLACE FUNCTION get_query_performance_stats(
    min_calls bigint DEFAULT 1,
    result_limit integer DEFAULT 50
)
RETURNS TABLE (
    query_text text,
    calls bigint,
    total_time_ms numeric,
    total_time_sec numeric,
    total_time_min numeric,
    avg_time_ms numeric,
    avg_time_sec numeric,
    percent_of_total numeric,
    performance_category text,
    query_type_category text,
    rows_returned bigint,
    rows_per_call numeric,
    rows_per_second numeric,
    cache_efficiency numeric,
    query_type text
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH query_stats AS (
        SELECT 
            q.query,
            q.calls,
            q.total_exec_time,
            q.mean_exec_time,
            q.rows,
            q.shared_blks_hit,
            q.shared_blks_read,
            -- Определяем тип запроса
            CASE 
                WHEN q.query ILIKE 'SELECT%' THEN 'SELECT'
                WHEN q.query ILIKE 'INSERT%' THEN 'INSERT'
                WHEN q.query ILIKE 'UPDATE%' THEN 'UPDATE'
                WHEN q.query ILIKE 'DELETE%' THEN 'DELETE'
                WHEN q.query ILIKE 'WITH%' THEN 'CTE'
                ELSE 'OTHER'
            END as detected_query_type,
            -- Процент от общего времени
            100 * q.total_exec_time / NULLIF(sum(q.total_exec_time) OVER (), 0) as time_percent
        FROM pg_stat_statements q
        WHERE q.calls >= min_calls
            AND q.query NOT LIKE '%pg_%'
            AND q.query NOT LIKE '%information_schema%'
            AND q.query NOT ILIKE '%pg_stat_statements%'
            AND length(trim(q.query)) > 20
    )
    SELECT 
        -- Текст запроса
        left(stats.query, 100) as query_text,
        
        -- Основная статистика
        stats.calls,
        round(stats.total_exec_time::numeric, 2) as total_time_ms,
        round((stats.total_exec_time / 1000)::numeric, 2) as total_time_sec,
        round((stats.total_exec_time / 60000)::numeric, 2) as total_time_min,
        round(stats.mean_exec_time::numeric, 2) as avg_time_ms,
        round((stats.mean_exec_time / 1000)::numeric, 2) as avg_time_sec,
        
        -- Процент от общего времени
        round(stats.time_percent::numeric, 2) as percent_of_total,
        
        -- Категория производительности по времени
        CASE 
            WHEN stats.mean_exec_time < 10 THEN '✅ ОЧЕНЬ БЫСТРЫЙ (<10ms)'
            WHEN stats.mean_exec_time < 50 THEN '⚡ БЫСТРЫЙ (10-50ms)'
            WHEN stats.mean_exec_time < 100 THEN '🔶 СРЕДНИЙ (50-100ms)'
            WHEN stats.mean_exec_time < 1000 THEN '⚠️ МЕДЛЕННЫЙ (100ms-1s)'
            ELSE '🚨 ОЧЕНЬ МЕДЛЕННЫЙ (>1s)'
        END as performance_category,
        
        -- Категория типа запроса (длинный/короткий на основе ваших определений)
        CASE 
            -- Короткий запрос: небольшое количество строк относительно размера таблицы
            WHEN stats.rows::numeric / NULLIF(stats.calls, 0) < 1000 
                 AND stats.mean_exec_time < 100 THEN '🟢 КОРОТКИЙ'
            
            -- Длинный запрос: высокая селективность, много обработанных строк
            WHEN stats.rows::numeric / NULLIF(stats.calls, 0) >= 10000 
                 OR stats.mean_exec_time > 1000 THEN '🔴 ДЛИННЫЙ'
            
            -- Средний запрос
            ELSE '🟡 СРЕДНИЙ'
        END as query_type_category,
        
        -- Статистика по строкам
        stats.rows as rows_returned,
        round((stats.rows::numeric / NULLIF(stats.calls, 0))::numeric, 2) as rows_per_call,
        
        -- Производительность (строк в секунду)
        CASE 
            WHEN stats.total_exec_time > 0 THEN 
                round((stats.rows * 1000 / stats.total_exec_time)::numeric, 2)
            ELSE 0
        END as rows_per_second,
        
        -- Эффективность кеша
        CASE 
            WHEN (stats.shared_blks_hit + stats.shared_blks_read) > 0 THEN
                round(100 * stats.shared_blks_hit::numeric / 
                      (stats.shared_blks_hit + stats.shared_blks_read), 2)
            ELSE 0
        END as cache_efficiency,
        
        -- Тип запроса
        stats.detected_query_type as query_type
        
    FROM query_stats stats
    WHERE stats.time_percent IS NOT NULL
    ORDER BY 
        -- Сначала сортируем по категории (длинные запросы вверху)
        CASE 
            WHEN stats.rows::numeric / NULLIF(stats.calls, 0) >= 10000 
                 OR stats.mean_exec_time > 1000 THEN 1
            WHEN stats.rows::numeric / NULLIF(stats.calls, 0) < 1000 
                 AND stats.mean_exec_time < 100 THEN 3
            ELSE 2
        END,
        stats.mean_exec_time DESC
    LIMIT result_limit;

END;
$$;


SELECT *
FROM get_query_performance_stats();





CREATE OR REPLACE FUNCTION analyze_query_plan(
    query_text text,
    explain_analyze boolean DEFAULT false
)
RETURNS TABLE (
    optimization_area text,
    problem_description text,
    recommendation text,
    severity text,
    estimated_cost numeric,
    actual_time numeric,
    plan_node text
) 
LANGUAGE plpgsql
AS $$
DECLARE
    explain_result text;
    plan_json json;
    rec record;
BEGIN
    -- Выполняем EXPLAIN и получаем результат в JSON
    IF explain_analyze THEN
        EXECUTE 'EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) ' || query_text 
        INTO plan_json;
    ELSE
        EXECUTE 'EXPLAIN (COSTS, VERBOSE, FORMAT JSON) ' || query_text 
        INTO plan_json;
    END IF;

    -- Анализируем каждый узел плана
    FOR rec IN (
        WITH recursive plan_tree AS (
            SELECT 
                plan -> 0 as node,
                (plan -> 0 ->> 'Node Type')::text as node_type,
                (plan -> 0 ->> 'Total Cost')::numeric as total_cost,
                (plan -> 0 ->> 'Actual Total Time')::numeric as actual_time,
                (plan -> 0 ->> 'Plan Rows')::numeric as plan_rows,
                (plan -> 0 ->> 'Actual Rows')::numeric as actual_rows,
                (plan -> 0 ->> 'Relation Name')::text as relation_name,
                (plan -> 0 ->> 'Index Name')::text as index_name,
                (plan -> 0 ->> 'Join Type')::text as join_type,
                (plan -> 0 ->> 'Filter')::text as filter,
                (plan -> 0 ->> 'Sort Key')::text as sort_key,
                (plan -> 0 ->> 'Hash Cond')::text as hash_cond,
                (plan -> 0 ->> 'Shared Hit Blocks')::numeric as shared_hit_blocks,
                (plan -> 0 ->> 'Shared Read Blocks')::numeric as shared_read_blocks,
                0 as level
            FROM (SELECT plan_json as plan) p
            
            UNION ALL
            
            SELECT 
                child.node,
                (child.node ->> 'Node Type')::text,
                (child.node ->> 'Total Cost')::numeric,
                (child.node ->> 'Actual Total Time')::numeric,
                (child.node ->> 'Plan Rows')::numeric,
                (child.node ->> 'Actual Rows')::numeric,
                (child.node ->> 'Relation Name')::text,
                (child.node ->> 'Index Name')::text,
                (child.node ->> 'Join Type')::text,
                (child.node ->> 'Filter')::text,
                (child.node ->> 'Sort Key')::text,
                (child.node ->> 'Hash Cond')::text,
                (child.node ->> 'Shared Hit Blocks')::numeric,
                (child.node ->> 'Shared Read Blocks')::numeric,
                level + 1
            FROM plan_tree pt,
                LATERAL json_array_elements(pt.node -> 'Plans') as child(node)
            WHERE pt.node -> 'Plans' IS NOT NULL
        )
        SELECT * FROM plan_tree
    ) LOOP
        -- Анализ Seq Scan
        IF rec.node_type = 'Seq Scan' THEN
            optimization_area := 'TABLE SCAN';
            problem_description := 'Полное сканирование таблицы ' || COALESCE(rec.relation_name, 'unknown');
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            
            IF rec.plan_rows > 10000 THEN
                severity := 'HIGH';
                recommendation := 'Добавить индекс на столбцы в условиях WHERE или рассмотреть партиционирование таблицы';
                RETURN NEXT;
            ELSE
                severity := 'MEDIUM';
                recommendation := 'Для небольших таблиц Seq Scan может быть оптимальным. Проверить размер таблицы.';
                RETURN NEXT;
            END IF;
        END IF;

        -- Анализ отсутствия индекса
        IF rec.node_type = 'Seq Scan' AND rec.filter IS NOT NULL THEN
            optimization_area := 'MISSING INDEX';
            problem_description := 'Seq Scan с фильтром: ' || rec.filter;
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            severity := 'HIGH';
            recommendation := 'Создать индекс на столбцах из условия: ' || rec.filter;
            RETURN NEXT;
        END IF;

        -- Анализ Nested Loop для больших таблиц
        IF rec.node_type = 'Nested Loop' AND rec.plan_rows > 1000 THEN
            optimization_area := 'JOIN STRATEGY';
            problem_description := 'Nested Loop join для большого количества строк: ' || rec.plan_rows::text;
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            severity := 'HIGH';
            recommendation := 'Рассмотреть использование Hash Join или Merge Join. Проверить наличие индексов для внутренней таблицы.';
            RETURN NEXT;
        END IF;

        -- Анализ Sort операций
        IF rec.node_type = 'Sort' AND rec.plan_rows > 10000 THEN
            optimization_area := 'SORT OPERATION';
            problem_description := 'Сортировка большого количества строк: ' || rec.plan_rows::text;
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            severity := 'MEDIUM';
            recommendation := 'Рассмотреть создание индекса на сортируемых столбцах: ' || COALESCE(rec.sort_key, 'unknown');
            RETURN NEXT;
        END IF;

        -- Анализ Hash Join
        IF rec.node_type = 'Hash Join' THEN
            optimization_area := 'HASH JOIN';
            problem_description := 'Hash Join с условием: ' || COALESCE(rec.hash_cond, 'unknown');
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            severity := 'INFO';
            recommendation := 'Hash Join обычно эффективен для больших таблиц. Убедиться, что work_mem достаточно для хранения хэш-таблицы.';
            RETURN NEXT;
        END IF;

        -- Анализ расхождения между планируемыми и фактическими строками
        IF rec.plan_rows IS NOT NULL AND rec.actual_rows IS NOT NULL THEN
            IF rec.plan_rows > 0 AND ABS(rec.plan_rows - rec.actual_rows) / rec.plan_rows > 10 THEN
                optimization_area := 'STATISTICS ACCURACY';
                problem_description := 'Большое расхождение между планируемыми (' || rec.plan_rows::text || 
                                      ') и фактическими (' || rec.actual_rows::text || ') строками';
                estimated_cost := rec.total_cost;
                actual_time := rec.actual_time;
                plan_node := rec.node_type;
                severity := 'MEDIUM';
                recommendation := 'Обновить статистику: ANALYZE таблицы или увеличить default_statistics_target';
                RETURN NEXT;
            END IF;
        END IF;

        -- Анализ эффективности кеша
        IF rec.shared_hit_blocks IS NOT NULL AND rec.shared_read_blocks IS NOT NULL THEN
            IF rec.shared_read_blocks > 1000 THEN
                optimization_area := 'CACHE EFFICIENCY';
                problem_description := 'Большое количество чтений с диска: ' || rec.shared_read_blocks::text || ' блоков';
                estimated_cost := rec.total_cost;
                actual_time := rec.actual_time;
                plan_node := rec.node_type;
                severity := 'MEDIUM';
                recommendation := 'Увеличить shared_buffers или рассмотреть использование более эффективных индексов';
                RETURN NEXT;
            END IF;
        END IF;

        -- Анализ Index Scan
        IF rec.node_type LIKE 'Index%' AND rec.index_name IS NOT NULL THEN
            optimization_area := 'INDEX USAGE';
            problem_description := 'Использование индекса: ' || rec.index_name;
            estimated_cost := rec.total_cost;
            actual_time := rec.actual_time;
            plan_node := rec.node_type;
            severity := 'INFO';
            recommendation := 'Индекс используется корректно. Проверить селективность индекса.';
            RETURN NEXT;
        END IF;

    END LOOP;

    -- Общие рекомендации
    optimization_area := 'GENERAL OPTIMIZATION';
    problem_description := 'Общие рекомендации по оптимизации';
    recommendation := '1. Убедитесь, что статистика актуальна (ANALYZE)' || E'\n' ||
                     '2. Проверьте настройки памяти (work_mem, shared_buffers)' || E'\n' ||
                     '3. Рассмотрите партиционирование для больших таблиц' || E'\n' ||
                     '4. Используйте подходящие типы индексов (B-tree, Hash, GIN, GiST)' || E'\n' ||
                     '5. Избегайте SELECT * - выбирайте только нужные столбцы';
    severity := 'INFO';
    estimated_cost := NULL;
    actual_time := NULL;
    plan_node := 'ALL';
    RETURN NEXT;

EXCEPTION
    WHEN OTHERS THEN
        optimization_area := 'ERROR';
        problem_description := 'Ошибка при анализе запроса: ' || SQLERRM;
        recommendation := 'Проверьте синтаксис запроса и права доступа';
        severity := 'CRITICAL';
        estimated_cost := NULL;
        actual_time := NULL;
        plan_node := 'ERROR';
        RETURN NEXT;
END;
$$;



CREATE OR REPLACE FUNCTION generate_optimization_commands(query_text text)
RETURNS TABLE (
    command_type text,
    sql_command text,
    description text
) 
LANGUAGE plpgsql
AS $$
DECLARE
    plan_json json;
    table_name text;
    filter_condition text;
BEGIN
    EXECUTE 'EXPLAIN (COSTS, VERBOSE, FORMAT JSON) ' || query_text 
    INTO plan_json;

    -- Извлекаем информацию о таблицах и фильтрах из плана
    -- Это упрощенная версия - в реальности нужен более сложный парсинг
    
    -- Рекомендация по анализу статистики
    command_type := 'MAINTENANCE';
    sql_command := 'ANALYZE;';
    description := 'Обновить статистику по всем таблицам';
    RETURN NEXT;

    -- Пример рекомендации по созданию индекса (нужно адаптировать под конкретный запрос)
    IF query_text ~* 'WHERE.*=.*' THEN
        command_type := 'INDEX CREATION';
        sql_command := '-- Создайте индекс на основе условий WHERE из запроса';
        description := 'Пример создания индекса для условий фильтрации';
        RETURN NEXT;
    END IF;

    -- Рекомендация по настройке памяти
    command_type := 'CONFIGURATION';
    sql_command := 'SET work_mem = ''100MB''; -- Для текущей сессии';
    description := 'Увеличить work_mem для операций сортировки и хэширования';
    RETURN NEXT;

    -- Рекомендация по переписыванию запроса
    command_type := 'QUERY REWRITE';
    sql_command := '-- Рассмотрите: ' || E'\n' ||
                   '-- 1. Использование EXISTS вместо IN для подзапросов' || E'\n' ||
                   '-- 2. Избегание SELECT *' || E'\n' ||
                   '-- 3. Использование JOIN вместо подзапросов где возможно';
    description := 'Общие рекомендации по переписыванию запроса';
    RETURN NEXT;

END;
$$;


-- Создаем тестовую таблицу
CREATE TABLE test_orders AS 
SELECT 
    generate_series(1, 100000) as id,
    'customer_' || (random() * 1000)::int as customer,
    (random() * 1000)::numeric as amount,
    now() - (random() * 365)::int * interval '1 day' as order_date;

-- Анализируем запрос
SELECT * FROM generate_optimization_commands('
SELECT city,
date_trunc(''month'', f.scheduled_departure),
sum(passengers) passengers
FROM airport a
JOIN flight f  ON a.airport_code = f.departure_airport
JOIN ( 
SELECT flight_id, count(*) passengers
FROM booking_leg l
JOIN boarding_pass_part b USING (booking_leg_id)
WHERE b.boarding_time   > ''2020-07-15''
AND   b.boarding_time   < ''2020-07-30''
GROUP BY flight_id
) cnt ON f.flight_id = cnt.flight_id 
GROUP BY 1,2
');



-- Проверка риска wraparound
SELECT 
    datname,
    age(datfrozenxid) as age,
    round(age(datfrozenxid)::numeric / 2000000000 * 100, 2) as percent_used
FROM pg_database 
ORDER BY age DESC;

-- Критические таблицы
SELECT *
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE relkind = 'r'
    AND age(relfrozenxid) > 100000000  -- > 100 млн транзакций
ORDER BY age(relfrozenxid) DESC
LIMIT 10;



-- Войдите в базу данных как superuser
CREATE EXTENSION pg_repack;

-- Проверьте установку
SELECT extname, extversion FROM pg_extension WHERE extname = 'pg_repack';


SHOW transaction_timeout
SHOW idle_in_transaction_session_timeout

CREATE EXTENSION pg_buffercache;

CREATE EXTENSION pg_prewarm

SELECT count(*)
FROM pg_buffercache
WHERE usagecount > 0 

-- Прогреваем таблицу
SELECT pg_prewarm('boarding_pass','buffer');

EXPLAIN (ANALYZE, BUFFERS) 
SELECT *
FROM boarding_pass;
-- Buffers: shared hit=15642 read=0  ← Все чтения из кэша (быстро)

-- Проверяем текущее состояние кэша
SELECT 
    COUNT(*) as total_buffers,
    COUNT(*) FILTER (WHERE isdirty) as dirty_buffers
FROM pg_buffercache 
WHERE relfilenode = pg_relation_filenode('boarding_pass'::regclass);

-- Прогреваем
SELECT pg_prewarm('boarding_pass', 'read');

-- Проверяем после прогрева
SELECT COUNT(*) as cached_buffers
FROM pg_buffercache 
WHERE relfilenode = pg_relation_filenode('boarding_pass'::regclass);


-- Увеличьте временно
show shared_buffers;

-- effective_cache_size = (RAM - shared_buffers) * 0.75
-- Например для 16GB RAM: (16GB - 4GB) * 0.75 = 9GB
SHOW effective_cache_size;
SHOW temp_buffers;
SELECT name, setting, unit, context, vartype, min_val, max_val 
FROM pg_settings 
WHERE name = 'temp_buffers';
-- work_mem = (RAM * 0.25) / max_connections
-- Пример: (16GB * 0.25) / 100 = 40MB
SHOW work_mem;
SHOW max_connections;


SELECT name, setting, unit, context, vartype, min_val, max_val 
FROM pg_settings 
WHERE name = 'temp_buffers';



-- Текущие настройки CHECKPOINT
SELECT name, setting, unit, context 
FROM pg_settings 
WHERE name LIKE '%checkpoint%' OR name LIKE '%wal%';

-- Ключевые параметры:
SHOW checkpoint_timeout;      -- Таймаут между checkpoint (по умолчанию 5min)
SHOW checkpoint_completion_target; -- Цель завершения (0.5-0.9)
SHOW max_wal_size;           -- Макс размер WAL перед принудительным checkpoint
SHOW min_wal_size;           -- Мин размер WAL

-- Статистика checkpoint
SELECT *
FROM pg_stat_bgwriter;

-- Проверить настройки
SHOW archive_mode;
SHOW archive_command;

-- Проверить права
-- Убедиться, что archive_command выполняется успешно

-- Все настройки связанные с WAL и checkpoint
SELECT 
    name, 
    setting, 
    unit, 
    context,
    category,
    short_desc
FROM pg_settings 
WHERE name LIKE '%wal%' 
   OR name LIKE '%checkpoint%'
   OR name LIKE '%archive%'
ORDER BY category, name;



-- Основные настройки WAL


-- Текущее положение в WAL
SELECT 
    pg_current_wal_lsn() as current_lsn,
    pg_walfile_name(pg_current_wal_lsn()) as current_wal_file,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0'::pg_lsn)) as total_wal_size;


-- Текущее положение в WAL
SELECT 
    pg_current_wal_lsn() as current_lsn,
    pg_walfile_name(pg_current_wal_lsn()) as current_wal_file,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0'::pg_lsn)) as total_wal_size;


-- Комплексный мониторинг WAL
SELECT 
    'WAL_LEVEL' as parameter,
    setting as value
FROM pg_settings WHERE name = 'wal_level'

UNION ALL

SELECT 
    'WAL_SIZE',
    pg_size_pretty(setting::bigint * 1024 * 1024)
FROM pg_settings WHERE name = 'max_wal_size'

UNION ALL

SELECT 
    'CHECKPOINT_TIMEOUT',
    setting || ' seconds'
FROM pg_settings WHERE name = 'checkpoint_timeout'

UNION ALL

SELECT 
    'ARCHIVE_MODE',
    setting
FROM pg_settings WHERE name = 'archive_mode'

UNION ALL

SELECT 
    'LAST_ARCHIVED',
    COALESCE(last_archived_wal, 'None')
FROM pg_stat_archiver;


-- Создайте точку восстановления
SELECT pg_create_restore_point('before_wal_config');

-- Выполните checkpoint
CHECKPOINT;

-- Выполните в DBeaver чтобы узнать текущий WAL файл
SELECT pg_walfile_name(pg_current_wal_lsn()) as current_wal_file;
-- Выполните в DBeaver чтобы узнать текущий WAL файл
-- Найдите data directory
SHOW data_directory;

-- Должно показывать:
SELECT name, setting FROM pg_settings WHERE name = 'archive_mode';
-- archive_mode | on

SELECT archived_count FROM pg_stat_archiver;

-- В DBeaver выполните
CREATE TABLE test_wal11 AS SELECT generate_series(1, 10000000) as id;
DROP TABLE test_wal11;
CHECKPOINT;

SELECT pg_current_wal_insert_lsn();

ALTER SYSTEM SET archive_command = 'cmd /c copy "C:\\Program Files\\PostgreSQL\\17\\data\\pg_wal\\%f" "C:\\PostgreSQL\\wal_archive\\%f"';

SELECT pg_switch_wal();
SELECT pg_create_restore_point('manual_archive_trigger');


-- Выполните в DBeaver
SELECT * FROM pg_stat_archiver;

ALTER SYSTEM SET max_wal_size = '1GB';
SHOW max_wal_size
SELECT pg_reload_conf();

-- Выполните в DBeaver
SELECT 
    name, 
    setting, 
    pending_restart 
FROM pg_settings 
WHERE name IN ('archive_mode', 'wal_level', 'archive_command');


# Перейдите в папку bin PostgreSQL
cd "C:\Program Files\PostgreSQL\15\bin"

# Создайте базовую резервную копию
pg_basebackup -D "C:\PostgreSQL\backups\base_backup_%DATE%" -U postgres -v -P -Fp -Xs -R
-- Принудительный checkpoint
CHECKPOINT;

-- Создание точки восстановления
SELECT pg_create_restore_point('manual_checkpoint_' || now()::date);

-- Проверка WAL потребления
SELECT 
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0'::pg_lsn)) as total_wal_generated,
    (SELECT pg_size_pretty(sum(size)) FROM pg_ls_waldir()) as current_wal_size;




-- Генерация рекомендованных настроек WAL
SELECT 
    name,
    current_setting(name) as current_value,
    recommended_value,
    description
FROM (VALUES 
    ('wal_level', 'replica', 'Уровень логирования: minimal, replica, logical'),
    ('max_wal_size', '2GB', 'Максимальный размер WAL перед checkpoint'),
    ('min_wal_size', '1GB', 'Минимальный размер WAL'),
    ('wal_keep_size', '1GB', 'Сколько WAL сохранять для реплик'),
    ('checkpoint_timeout', '15min', 'Таймаут между checkpoint'),
    ('archive_mode', 'on', 'Включить архивацию WAL'),
    ('archive_command', '''cp %p /backup/wal_archive/%f''', 'Команда архивации')
) AS settings(name, recommended_value, description);


SELECT 
    pg_current_wal_lsn() as current_lsn,
    pg_walfile_name(pg_current_wal_lsn()) as current_wal_file;



-- Создайте и удалите таблицу для генерации WAL
CREATE TABLE checkpoint_test AS 
SELECT generate_series(1, 10000000) as id, md5(random()::text) as data;

DROP TABLE checkpoint_test;

-- Принудительный CHECKPOINT
CHECKPOINT;

-- Проверьте статистику архивации
SELECT 
    archived_count,
    last_archived_wal,
    last_archived_time,
    failed_count
FROM pg_stat_archiver;

SELECT 
    name, 
    setting, 
    pending_restart 
FROM pg_settings 
WHERE name IN ('archive_mode', 'archive_command', 'wal_level');

-- Создайте точку восстановления (гарантированно создает WAL)
SELECT pg_create_restore_point('manual_archive_trigger');

-- Или переключите WAL файл вручную
SELECT pg_switch_wal();

-- Проверьте папку архива вручную через командную строку
-- dir C:\PostgreSQL\wal_archive

-- Узнаем путь к postgresql.conf
SHOW config_file;

-- Обычные пути в Windows:
-- C:\Program Files\PostgreSQL\15\data\postgresql.conf
-- C:\Program Files\PostgreSQL\16\data\postgresql.conf
archive_command = 'powershell -Command "Copy-Item ''%p'' ''C:\PostgreSQL\wal_archive\%f''"'

/*
# В postgresql.conf
# WAL Settings
wal_level = replica
max_wal_size = 2GB
min_wal_size = 1GB
wal_keep_size = 1GB
wal_compression = on

# Checkpoint Settings  
checkpoint_timeout = 15min
checkpoint_completion_target = 0.8
# Archive Settings
archive_mode = on
# Performance
shared_buffers = 2GB
work_mem = 16MB
maintenance_work_mem = 512MB
*
**/

SELECT * FROM pg_stat_checkpointer

SELECT * FROM pg_stat_bgwriter

SELECT backend_type,
sum(reads) reads, sum(writes) writes, sum(fsyncs) fsyncs
FROM pg_stat_io
GROUP BY backend_type
ORDER BY backend_type;

SHOW data_checksums;

SELECT * FROM wal LIMIT 1


SELECT * 
FROM pg_locks



BEGIN;
SELECT pg_backend_pid();

SELECT pid,locktype, virtualxid, mode, granted
FROM pg_locks WHERE pid = 17752;

SELECT pg_current_xact_id();

SELECT locktype, virtualxid, transactionid AS xid, mode, granted
FROM pg_locks WHERE xid = 2268;
commit



/*Общую картину ожиданий дает функция pg_blocking_pids. Она показывает номера процессов, которые стоят в очереди перед указанным и либо
удерживают, либо запрашивают несовместимую блокировку:*/
SELECT pid,
pg_blocking_pids(pid),
wait_event_type,
state,
left(query,50) AS query
FROM pg_stat_activity


CREATE EXTENSION IF NOT EXISTS pageinspect;

CREATE FUNCTION row_locks(relname text, pageno integer)
RETURNS TABLE(
ctid tid, xmax text,
lock_only text, is_multi text,
keys_upd text, keyshr text, shr text
) AS $$
SELECT (pageno,lp)::text::tid,
t_xmax,
CASE WHEN t_infomask & 128 = 128 THEN 't' END,
CASE WHEN t_infomask & 4096 = 4096 THEN 't' END,
CASE WHEN t_infomask2 & 8192 = 8192 THEN 't' END,
CASE WHEN t_infomask & 16 = 16 THEN 't' END,
CASE WHEN t_infomask & 16+64 = 16+64 THEN 't' END
FROM heap_page_items(get_raw_page(relname,pageno))
ORDER BY lp;
$$ LANGUAGE sql;

> SELECT * FROM row_locks('accounts',0) LIMIT 2;
ctid | xmax | lock_only | is_multi | keys_upd | keyshr | shr
−−−−−−−+−−−−−−−−+−−−−−−−−−−−+−−−−−−−−−−+−−−−−−−−−−+−−−−−−−−+−−−−−
(0,1) | 149956 | | | | |
(0,2) | 149956 | | | t | |


SELECT *
FROM pg_tables
WHERE tableowner = 'postgres'
ORDER BY tablename;


SELECT schemaname, tablename
FROM (
-- pg_tables
SELECT n.nspname AS schemaname,
c.relname AS tablename,
pg_get_userbyid(c.relowner) AS tableowner
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE c.relkind = ANY (ARRAY['r'::char, 'p'::char])
)
WHERE tableowner = 'postgres'
ORDER BY tablename;


SET debug_print_plan TO off;

EXPLAIN
SELECT f.flight_id 
FROM flight f
EXCEPT 
SELECT bl.flight_id 
FROM booking_leg bl
ORDER BY flight_id 

SELECT pg_reload_conf();


---EXPLAIN(memory) SELECT schemaname, tablename
FROM pg_tables
WHERE tableowner = 'postgres'
ORDER BY tablename;

-- Проверить, доступен ли генетический оптимизатор
SELECT name, setting 
FROM pg_settings 
WHERE name LIKE '%geco%' OR name LIKE '%genetic%';

-- Или так
SHOW geqo;

SHOW geqo_threshold;
SHOW geqo_effort;
SHOW geqo_generations;
SHOW geqo_pool_size;
SHOW geqo_selection_bias;



CREATE OR REPLACE FUNCTION analyze_column_distribution(
    p_table_name text,
    p_sample_limit int DEFAULT 10000
) 
RETURNS TABLE(
    column_name text,
    data_type text,
    total_count bigint,
    distinct_count bigint,
    null_count bigint,
    null_percent numeric,
    distinct_percent numeric,
    most_common_values text[],
    most_common_freqs int[]
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_schema_name text;
    v_table_exists boolean;
    v_columns_count int;
BEGIN
    -- Диагностика: какая схема и существует ли таблица
    SELECT 
        table_schema,
        EXISTS (SELECT 1 FROM information_schema.tables 
                WHERE table_schema = c.table_schema AND table_name = c.table_name) as table_exists,
        COUNT(*) as columns_count
    INTO v_schema_name, v_table_exists, v_columns_count
    FROM information_schema.columns c
    WHERE c.table_name = p_table_name
    GROUP BY table_schema, table_name;

    RAISE NOTICE 'Диагностика: таблица=%, схема=%, существует=%, столбцов=%', 
        p_table_name, v_schema_name, v_table_exists, v_columns_count;

    IF v_columns_count = 0 THEN
        RAISE EXCEPTION 'Таблица "%" не найдена или не имеет столбцов', p_table_name;
    END IF;

    -- Используем найденную схему или по умолчанию 'public'
    IF v_schema_name IS NULL THEN
        v_schema_name := 'public';
    END IF;

    -- Для каждого столбца собираем статистику
    RETURN QUERY EXECUTE format('
        SELECT 
            a.attname::text as column_name,
            pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type,
            (SELECT count(*) FROM %I.%I) as total_count,
            (SELECT count(DISTINCT %I) FROM %I.%I) as distinct_count,
            (SELECT count(*) FROM %I.%I WHERE %I IS NULL) as null_count,
            round(
                (SELECT count(*) FROM %I.%I WHERE %I IS NULL) * 100.0 / 
                NULLIF((SELECT count(*) FROM %I.%I), 0), 2
            ) as null_percent,
            round(
                (SELECT count(DISTINCT %I) FROM %I.%I) * 100.0 / 
                NULLIF((SELECT count(*) FROM %I.%I), 0), 2
            ) as distinct_percent,
            COALESCE(ARRAY(
                SELECT %I::text 
                FROM %I.%I 
                WHERE %I IS NOT NULL 
                GROUP BY %I 
                ORDER BY count(*) DESC 
                LIMIT 5
            ), ARRAY[]::text[]) as most_common_values,
            COALESCE(ARRAY(
                SELECT count(*)::int
                FROM %I.%I 
                WHERE %I IS NOT NULL 
                GROUP BY %I 
                ORDER BY count(*) DESC 
                LIMIT 5
            ), ARRAY[]::int[]) as most_common_freqs
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = %L
            AND c.relname = %L
            AND a.attnum > 0
            AND NOT a.attisdropped
        ORDER BY a.attnum',
        -- Повторяем параметры для каждого использования
        v_schema_name, p_table_name,  -- total_count
        p_table_name, v_schema_name, p_table_name,  -- distinct_count  
        v_schema_name, p_table_name, p_table_name,  -- null_count
        v_schema_name, p_table_name, p_table_name,  -- null_percent (1)
        v_schema_name, p_table_name,  -- null_percent (2)
        p_table_name, v_schema_name, p_table_name,  -- distinct_percent (1)
        v_schema_name, p_table_name,  -- distinct_percent (2)
        p_table_name, v_schema_name, p_table_name, p_table_name, p_table_name,  -- most_common_values
        v_schema_name, p_table_name, p_table_name, p_table_name,  -- most_common_freqs
        v_schema_name,  -- схема в условии JOIN
        p_table_name   -- имя таблицы в условии
    );
END;
$$;

ANALYZE booking
ALTER SYSTEM SET work_mem = '300MB';
SHOW work_mem 

SELECT *
FROM analyze_column_distribution('passenger')



PREPARE plane(text) AS
SELECT * 
FROM aircrafts WHERE aircraft_code = $1;

explain
EXECUTE plane('SU9');

SELECT name, statement, parameter_types
FROM pg_prepared_statements

analyze bookings
CREATE INDEX ON bookings(total_amount);
EXPLAIN SELECT * FROM bookings
WHERE total_amount > 1000000;

EXPLAIN SELECT * 
FROM bookings WHERE total_amount > 800000;


BEGIN;
DECLARE cur CURSOR FOR
SELECT * FROM aircrafts ORDER BY aircraft_code;
FETCH 10 FROM cur;
COMMIT;



/*
Базовая статистика уровня отношения 1
хранится в таблице pg_class системного каталога. 
К ней относятся:
• число строк в отношении (reltuples);
• размер отношения, в страницах (relpages);
• количество страниц, отмеченных в карте видимости (relallvisible)

Значение reltuples используется в качестве оценки кардинальности, 
когда запрос не накладывает никаких условий на строки таблицы.
Статистика собирается при анализе, ручном или автоматическом1
. Однако
ввиду особой важности базовая статистика рассчитывается 
также при выполнении некоторых операций (VACUUM FULL и CLUSTER2
, CREATE INDEX и REINDEX 3) и уточняется при очистке 
Значение relallvisible используется при оценке стоимости 
сканирования только индекса. Оно обновляется при очистке.


Дело в том, что планировщик повышает точность оценки, 
масштабируя значение reltuples в соответствии 
с отклонением реального размера файла
данных от значения relpages1. 
Поскольку размер файла вырос в два раза
по сравнению с relpages, количество строк скорректировалось 
исходя из предположения, что плотность данных не изменилась
*/
SELECT oid, relname, reltuples, relpages, relallvisible
FROM pg_class WHERE relname = 'flights';

VACUUM (VERBOSE, ANALYZE) flights;


CREATE TABLE flights_copy(LIKE flights)
WITH (autovacuum_enabled = false);

INSERT INTO flights_copy SELECT * FROM flights;

INSERT INTO flights_copy SELECT * FROM flights;

SELECT count(*) FROM flights_copy;

SELECT reltuples *
(pg_relation_size('flights_copy') / 8192) / relpages AS tuples
FROM pg_class 
WHERE relname = 'flights_copy'

EXPLAIN SELECT * FROM flights_copy;
ANALYZE flights_copy;
VACUUM flights_copy;

SELECT reltuples, relpages, relallvisible
FROM pg_class WHERE relname = 'flights_copy';


SELECT * 
FROM flights_copy;



SELECT count(*) FROM flights WHERE actual_departure IS NULL;
SELECT s.tablename, s.attname, round(reltuples * s.null_frac) AS rows
FROM pg_class
JOIN pg_stats s ON s.tablename = relname
WHERE s.tablename = 'flights'
AND s.attname = 'actual_departure';


EXPLAIN SELECT *
FROM flights
WHERE departure_airport = (
SELECT airport_code FROM airports WHERE city = 'Санкт-Петербург'
);


SELECT sum(s.most_common_freqs[
array_position((s.most_common_vals::text::text[]),v)
])
FROM pg_stats s, unnest(s.most_common_vals::text::text[]) v
WHERE s.tablename = 'boarding_passes' AND s.attname = 'seat_no'
AND v > '30C';


SELECT sum(s.most_common_freqs[
array_position((s.most_common_vals::text::text[]),v)
])
FROM pg_stats s, unnest(s.most_common_vals::text::text[]) v
WHERE s.tablename = 'boarding_passes' AND s.attname = 'seat_no';


SELECT count(*) FROM boarding_passes WHERE seat_no > '30C';

SHOW default_statistics_target


-- При relallvisible = 0 этот запрос НЕ сможет использовать index-only scan
EXPLAIN (ANALYZE)
SELECT flight_id FROM flights WHERE status = 'Scheduled';

-- Вместо желаемого:
-- "Index Only Scan using idx_flights_status on flights"

-- Будет использован:
-- "Index Scan using idx_flights_status on flights"

-- Проверить текущее значение
SHOW parallel_leader_participation;

-- Или подробнее
SELECT name, setting, short_desc 
FROM pg_settings 
WHERE name = 'parallel_leader_participation';

-- Для всей системы (требует перезагрузки)
ALTER SYSTEM SET parallel_leader_participation = on;
SELECT pg_reload_conf();

-- Или в postgresql.conf
-- parallel_leader_participation = off



SELECT attname, avg_width FROM pg_stats
WHERE (tablename, attname) IN ( VALUES
('tickets', 'passenger_name'), 
('ticket_flights','fare_conditions')
) ;


SELECT s.attname, s.avg_width 
FROM pg_stats s
JOIN (
    VALUES 
    ('tickets', 'passenger_name'), 
    ('ticket_flights','fare_conditions')
) AS filter_table(table_name, column_name)
ON s.tablename = filter_table.table_name AND s.attname = filter_table.column_name;

/*Поле correlation представления pg_stats показывает корреляцию между физическим расположением данных и логическим порядком в смысле
с. 526 операций сравнения. Если значения хранятся строго по возрастанию, корреляция будет близка к единице; если по убыванию — к минус единице. Чем
более хаотично расположены данные на диске, тем ближе значение к нулю. */
SELECT attname, correlation
FROM pg_stats WHERE tablename = 'airports_data'
ORDER BY abs(correlation) DESC;


EXPLAIN 
SELECT * FROM flights
WHERE extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
) = 1;


SELECT round(reltuples * 0.005)
FROM pg_class WHERE relname = 'flights';

/*Расширенная статистика
 * Чтобы собранная статистика использовалась, выражение в условии запроса
должно быть записано в том же виде, что и в команде CREATE STATISTICS.
Размер собираемой расширенной статистики можно изменить отдельно
командой ALTER STATISTICS, например:
=> ALTER STATISTICS flights_expr_stat SET STATISTICS 42;

 * */
CREATE STATISTICS flights_expr_stat ON (extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
))
FROM flights;





ANALYZE flights;
EXPLAIN SELECT * FROM flights
WHERE extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
) = 1;

/*Доступную пользователю расширенную статистику по выражению можно
посмотреть в более удобном виде с помощью специального представления:
*/
SELECT left(expr,1000) AS expr,
null_frac, avg_width, n_distinct,
most_common_vals AS mcv,
left(most_common_freqs::text,1000) AS mcf,
correlation
FROM pg_stats_ext_exprs WHERE statistics_name = 'flights_expr_stat' 



/*Статистика для индекса по выражению
Второй способ исправить оценки кардинальности — воспользоваться тем,
что при создании индекса по выражению для него собирается отдельная ста- с. 388
тистика, как для таблицы. Это удобно, если индекс действительно нужен.*/

DROP STATISTICS flights_expr_stat;
CREATE INDEX ON flights(extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
));

ANALYZE flights;
EXPLAIN SELECT * FROM flights
WHERE extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
) = 1;


/*Статистика для индексов по выражению хранится так же, как статистика по
таблице. Например, из pg_stats можно получить количество уникальных
значений, указав в качестве tablename имя индекса:
*/
SELECT n_distinct 
FROM pg_stats
WHERE tablename = 'flights_extract_idx';

SELECT extract(month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow')
FROM flights
GROUP BY extract(month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow')

show default_statistics_target
ALTER SYSTEM SET default_statistics_target = 500;

show random_page_cost
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET seq_page_cost = 1.0;
ALTER SYSTEM SET effective_io_concurrency = 1.0;
ALTER SYSTEM SET effective_io_concurrency = 0;
SELECT pg_reload_conf();

show seq_page_cost
SHOW random_page_cost


ALTER SYSTEM SET cpu_tuple_cost = 0.005;
ALTER SYSTEM SET cpu_index_tuple_cost = 0.0025; 
ALTER SYSTEM SET cpu_operator_cost = 0.001;
ALTER SYSTEM SET max_parallel_workers_per_gather = 8;
SELECT pg_reload_conf();

SHOW shared_buffers
-- Увеличьте shared_buffers (если достаточно RAM)
ALTER SYSTEM SET shared_buffers = '4GB';
-- Или для текущей сессии
SET shared_buffers = '4GB';
SHOW effective_io_concurrency

SHOW  work_mem 

-- Операции, которые используют временные файлы (слишком мало work_mem)
SELECT query, plans, calls, temp_blks_written
FROM pg_stat_statements 
WHERE temp_blks_written > 0
ORDER BY temp_blks_written DESC
LIMIT 10;

SET debug_print_plan = on;
SET client_min_messages = log;  -- чтобы видеть в консоли
ANALYZE flights;
EXPLAIN SELECT * FROM flights
WHERE extract(
month FROM scheduled_departure AT TIME ZONE 'Europe/Moscow'
) = 1;



SELECT name, setting, unit 
FROM pg_settings 
WHERE name LIKE '%log%' 
AND name IN ('log_directory', 'log_filename', 'logging_collector');

/*Класс операторов*/
CREATE INDEX ON aircrafts
USING btree -- метод доступа по умолчанию
(
model text_ops, -- класс операторов по умолчанию для text
range int4_ops -- класс операторов по умолчанию для integer
);


SELECT amname, opcname, opcintype::regtype
FROM pg_am am
JOIN pg_opclass opc ON opcmethod = am.oid;

SELECT opcname, amopstrategy, amopopr::regoperator
FROM pg_am am
JOIN pg_opfamily opf ON opfmethod = am.oid
JOIN pg_opclass opc ON opcfamily = opf.oid
JOIN pg_amop amop ON amopfamily = opcfamily
WHERE amname = 'btree'
--AND opcname IN ('text_ops', 'text_pattern_ops')
--AND amoplefttype = 'text'::regtype
--AND amoprighttype = 'text'::regtype
ORDER BY opcname, amopstrategy;


SELECT amprocnum, amproc::regproc
FROM pg_am am
JOIN pg_opfamily opf ON opfmethod = am.oid
JOIN pg_opclass opc ON opcfamily = opf.oid
JOIN pg_amproc amproc ON amprocfamily = opcfamily
WHERE amname = 'btree'
--AND opcname = 'text_ops'
--AND amproclefttype = 'text'::regtype
--AND amprocrighttype = 'text'::regtype
ORDER BY amprocnum;


SELECT opcname, opcintype::regtype
FROM pg_am am
JOIN pg_opfamily opf ON opfmethod = am.oid
JOIN pg_opclass opc ON opcfamily = opf.oid
WHERE amname = 'btree'
AND opfname = 'integer_ops';

SELECT opcname, amopopr::regoperator
FROM pg_am am
JOIN pg_opfamily opf ON opfmethod = am.oid
JOIN pg_opclass opc ON opcfamily = opf.oid
JOIN pg_amop amop ON amopfamily = opcfamily
WHERE amname = 'btree'
AND opfname = 'integer_ops'
AND amoplefttype = 'integer'::regtype
AND amopstrategy = 2
ORDER BY opcname;


SELECT amname, amhandler FROM pg_am WHERE amtype = 'i';




CREATE INDEX tickets_passenger_name_pattern_idx
ON tickets(passenger_name text_pattern_ops);
EXPLAIN analyze
SELECT * 
FROM tickets WHERE passenger_name LIKE 'ELENA%';

EXPLAIN analyze
SELECT * 
FROM tickets 
WHERE ((passenger_name ~>=~ 'ELENA') AND (passenger_name ~<~ 'ELENB'))