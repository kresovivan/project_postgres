/*
Используются материалы книги "Оптимизация запросов в Posgresql"
Добмровская Г., Новиков Б. Бейликова А. ДМК Пресс.

*/
explain ANALYZE
WITH bk_chi AS (WITH bk AS (WITH level4 AS (SELECT *
                                            FROM account
                                            WHERE frequent_flyer_id IN (SELECT frequent_flyer_id
                                                                        FROM frequent_flyer
                                                                        WHERE level = 4))
                            SELECT *
                            FROM booking
                            WHERE account_id IN (SELECT account_id FROM level4))

                SELECT *
                FROM bk
                WHERE bk.booking_id IN (SELECT booking_id
                                        FROM booking_leg
                                        WHERE leg_num = 1
                                          AND is_returning IS FALSE
                                          AND flight_id IN (SELECT flight_id
                                                            FROM flight
                                                            WHERE departure_airport IN ( 'ORD', 'MDW' )
                                                              AND scheduled_departure::date = '2020-07-04')
                                        )
                )
select count(*)
from passenger
where booking_id in (select booking_id from bk_chi)



explain ANALYZE
select count(*)
from booking bk
join booking_leg bl on bl.booking_id = bl.booking_id
join flight f on f.flight_id = bl.flight_id
join account a on a.account_id = bk.account_id
join frequent_flyer ff on ff.frequent_flyer_id = a.frequent_flyer_id
join passenger ps on ps.booking_id = bk.booking_id
where ff.level = 4
and bl.leg_num = 1
and bl.is_returning is FALSE
and f.departure_airport in ( 'ORD', 'MDW' )
  AND f.scheduled_departure::date = '2020-07-04';


SELECT
    n.nspname as schema_name,
    c.relname as table_name,
    c.relkind as type,
    c.reltuples as estimated_rows
FROM pg_class c
         JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'postgres_air'
  AND c.relkind IN ('r', 'p')  -- обычные таблицы и partitioned таблицы
ORDER BY c.relname;

/*Обработка ANALYZE по циклу*/
DO $$
    DECLARE
        cmd text;
    BEGIN
        FOR cmd IN
            SELECT format('ANALYZE VERBOSE %I.%I', n.nspname, c.relname)
            FROM pg_class c
                     JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE c.relkind = 'r'
              AND n.nspname NOT LIKE 'pg_%'
              AND n.nspname != 'information_schema'
              AND n.nspname = 'postgres_air'
            LOOP
                EXECUTE cmd;
                RAISE NOTICE 'Executed: %', cmd;
            END LOOP;
    END $$;


SELECT * from analyze_schema_distribution_detailed_ru('postgres_air','boarding_pass');


/*
Разница на практике:
Тип	Когда использовать	Пример	Эффект
Обычный индекс	Равномерное распределение	CREATE INDEX idx_email ON users(email)	Индексирует ВСЕ строки
Разреженный	Много NULL/одинаковых значений	CREATE INDEX idx_not_null ON users(email) WHERE email IS NOT NULL	Исключает NULL
Фильтрованный	Работа с подмножеством данных	CREATE INDEX idx_active ON users(email) WHERE status = 'active'	Только активные
*/

CREATE OR REPLACE FUNCTION analyze_schema_distribution_detailed_ru(
    schema_name text DEFAULT 'public',
    specific_table text DEFAULT NULL
)
    RETURNS TABLE(
                     имя_таблицы text,                    -- table_name
                     имя_столбца text,                    -- column_name
                     тип_данных text,                     -- data_type
                     всего_строк bigint,                  -- total_rows
                     не_null_количество bigint,           -- non_null_count
                     null_количество bigint,              -- null_count
                     процент_не_null numeric,             -- non_null_pct
                     уникальных_значений bigint,          -- distinct_count
                     процент_уникальных numeric,          -- distinct_pct
                     минимальное_значение text,           -- sample_min
                     максимальное_значение text,          -- sample_max
                     рекомендация text,                   -- recommendation
                     формула_расчета text                 -- calculation_details
                 ) AS
$$
DECLARE
    v_table_name text;
    v_column_name text;
    v_data_type text;
    v_total_rows bigint;
    v_non_null_count bigint;
    v_null_count bigint;
    v_non_null_pct numeric;
    v_distinct_count bigint;
    v_distinct_pct numeric;
    v_sample_min text;
    v_sample_max text;
    v_details text;
    cur CURSOR FOR
        SELECT
            c.relname as table_name,
            a.attname as column_name,
            format_type(a.atttypid, a.atttypmod) as data_type
        FROM pg_class c
                 JOIN pg_namespace n ON c.relnamespace = n.oid
                 JOIN pg_attribute a ON a.attrelid = c.oid
        WHERE n.nspname = schema_name
          AND c.relkind = 'r'
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND (specific_table IS NULL OR c.relname = specific_table)
        ORDER BY c.relname, a.attnum;
BEGIN
    -- Создаем временную таблицу
    CREATE TEMP TABLE IF NOT EXISTS temp_analysis_detailed_ru (
                                                                  имя_таблицы text,
                                                                  имя_столбца text,
                                                                  тип_данных text,
                                                                  всего_строк bigint,
                                                                  не_null_количество bigint,
                                                                  null_количество bigint,
                                                                  процент_не_null numeric,
                                                                  уникальных_значений bigint,
                                                                  процент_уникальных numeric,
                                                                  минимальное_значение text,
                                                                  максимальное_значение text,
                                                                  формула_расчета text
    ) ON COMMIT DROP;

    TRUNCATE TABLE temp_analysis_detailed_ru;

    OPEN cur;

    LOOP
        FETCH cur INTO v_table_name, v_column_name, v_data_type;
        EXIT WHEN NOT FOUND;

        -- Вычисляем total_rows
        EXECUTE format('SELECT count(*) FROM %I.%I',
                       schema_name, v_table_name)
            INTO v_total_rows;

        -- Вычисляем non_null_count
        EXECUTE format('SELECT count(%I) FROM %I.%I',
                       v_column_name, schema_name, v_table_name)
            INTO v_non_null_count;

        -- Вычисляем null_count
        v_null_count := v_total_rows - v_non_null_count;

        -- Вычисляем non_null_pct
        v_non_null_pct := ROUND(
                v_non_null_count::numeric /
                NULLIF(v_total_rows, 0) * 100, 2
                          );

        -- Вычисляем distinct_count
        EXECUTE format('SELECT count(distinct %I) FROM %I.%I',
                       v_column_name, schema_name, v_table_name)
            INTO v_distinct_count;

        -- Вычисляем distinct_pct
        v_distinct_pct := ROUND(
                v_distinct_count::numeric /
                NULLIF(v_non_null_count, 0) * 100, 2
                          );

        -- Получаем min/max значения
        BEGIN
            EXECUTE format(
                    'SELECT COALESCE(min(%I)::text, ''NULL'') FROM %I.%I',
                    v_column_name, schema_name, v_table_name
                    ) INTO v_sample_min;

            EXECUTE format(
                    'SELECT COALESCE(max(%I)::text, ''NULL'') FROM %I.%I',
                    v_column_name, schema_name, v_table_name
                    ) INTO v_sample_max;
        EXCEPTION WHEN OTHERS THEN
            v_sample_min := 'не доступно';
            v_sample_max := 'не доступно';
        END;

        -- Формируем строку с формулами
        v_details := format(
                'Процент не-NULL = %s / %s * 100 = %s%%, ' ||
                'Процент уникальных = %s / %s * 100 = %s%%',
                v_non_null_count, v_total_rows, v_non_null_pct,
                v_distinct_count, v_non_null_count, v_distinct_pct
                     );

        -- Вставляем результат
        INSERT INTO temp_analysis_detailed_ru
        VALUES (
                   v_table_name,
                   v_column_name,
                   v_data_type,
                   v_total_rows,
                   v_non_null_count,
                   v_null_count,
                   v_non_null_pct,
                   v_distinct_count,
                   v_distinct_pct,
                   v_sample_min,
                   v_sample_max,
                   v_details
               );
    END LOOP;

    CLOSE cur;

    -- Возвращаем результаты
    RETURN QUERY
        SELECT
            ta.имя_таблицы,
            ta.имя_столбца,
            ta.тип_данных,
            ta.всего_строк,
            ta.не_null_количество,
            ta.null_количество,
            ta.процент_не_null,
            ta.уникальных_значений,
            ta.процент_уникальных,
            ta.минимальное_значение,
            ta.максимальное_значение,
            CASE
                WHEN ta.процент_уникальных > 90 AND ta.всего_строк > 1000
                    THEN '✅ Рекомендуется обычный индекс (высокая уникальность)'
                WHEN ta.процент_не_null < 10
                    THEN '⚠️  Много NULL значений (>90%) - создать индекс ТОЛЬКО для заполненных строк'
                WHEN ta.процент_уникальных < 5
                    THEN '⚡ Мало уникальных значений (<5%) - создать фильтрованный индекс'
                ELSE '➖ Особых рекомендаций нет'
                END AS рекомендация,
            ta.формула_расчета
        FROM temp_analysis_detailed_ru ta
        ORDER BY ta.имя_таблицы, ta.имя_столбца;
END;
$$ LANGUAGE plpgsql;

----Функция для обслуживания статистики таблицы

CREATE OR REPLACE FUNCTION maintain_table_statistics(
    p_schema_name TEXT DEFAULT 'public',
    p_table_name TEXT DEFAULT NULL,  -- Добавили DEFAULT NULL
    p_operation TEXT DEFAULT 'ANALYZE'
)
    RETURNS TABLE(
                     operation TEXT,
                     start_time TIMESTAMP,
                     end_time TIMESTAMP,
                     duration INTERVAL,
                     message TEXT
                 )
    LANGUAGE plpgsql
AS $$
DECLARE
    v_full_table TEXT;
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_sql TEXT;
BEGIN
    -- Проверка обязательного параметра
    IF p_table_name IS NULL THEN
        RAISE EXCEPTION 'Имя таблицы обязательно для указания';
    END IF;

    v_full_table := format('%I.%I', p_schema_name, p_table_name);
    v_start_time := clock_timestamp();

    -- Выполняем запрошенную операцию
    CASE UPPER(p_operation)
        WHEN 'ANALYZE' THEN
            v_sql := format('ANALYZE VERBOSE %s', v_full_table);
            EXECUTE v_sql;

        WHEN 'VACUUM' THEN
            v_sql := format('VACUUM (VERBOSE, ANALYZE) %s', v_full_table);
            EXECUTE v_sql;

        WHEN 'REINDEX' THEN
            -- Перестраиваем все индексы таблицы
            v_sql := format('REINDEX TABLE CONCURRENTLY %s', v_full_table);
            EXECUTE v_sql;

        WHEN 'STATS' THEN
            -- Только сбор статистики без блокировок
            v_sql := format('ANALYZE %s', v_full_table);
            EXECUTE v_sql;

        ELSE
            RAISE EXCEPTION 'Неизвестная операция: %. Допустимые: ANALYZE, VACUUM, REINDEX, STATS',
                p_operation;
        END CASE;

    v_end_time := clock_timestamp();

    RETURN QUERY
        SELECT
            p_operation::TEXT as operation,
            v_start_time as start_time,
            v_end_time as end_time,
            (v_end_time - v_start_time) as duration,
            format('Операция %s выполнена для таблицы %s',
                   p_operation, v_full_table) as message;
END;
$$;


select *
    from maintain_table_statistics('postgres_air','booking');



DROP FUNCTION IF EXISTS get_table_statistics;

CREATE OR REPLACE FUNCTION get_table_statistics(
    schema_name TEXT,
    table_name TEXT
)
    RETURNS TABLE(
                     metric_category TEXT,
                     metric_name TEXT,
                     metric_value TEXT,
                     metric_details TEXT
                 )
    LANGUAGE plpgsql
AS $$
DECLARE
    v_full_table TEXT;
    v_row_count BIGINT;
    v_table_size BIGINT;
    v_index_size BIGINT;
    v_total_size BIGINT;
    v_n_dead_tup BIGINT;
    v_n_live_tup BIGINT;
    v_last_analyze TIMESTAMP;
BEGIN
    -- Формируем полное имя таблицы
    v_full_table := format('%I.%I', schema_name, table_name);

    -- Проверяем существование таблицы
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = schema_name AND tablename = table_name
    ) THEN
        RAISE EXCEPTION 'Таблица %.% не найдена', schema_name, table_name;
    END IF;

    -- Получаем количество строк
    EXECUTE format('SELECT COUNT(*) FROM %s', v_full_table) INTO v_row_count;

    -- Получаем информацию о размерах
    v_table_size := pg_relation_size(v_full_table::regclass);
    v_index_size := pg_indexes_size(v_full_table::regclass);
    v_total_size := pg_total_relation_size(v_full_table::regclass);

    -- Получаем статистику
    SELECT
        n_dead_tup, n_live_tup, last_analyze
    INTO v_n_dead_tup, v_n_live_tup, v_last_analyze
    FROM pg_stat_user_tables
    WHERE schemaname = schema_name AND relname = table_name;

    -- 1. Основная информация
    metric_category := '1. ОСНОВНАЯ ИНФОРМАЦИЯ';
    metric_name := 'Таблица';
    metric_value := table_name;
    metric_details := 'Схема: ' || schema_name;
    RETURN NEXT;

    metric_name := 'Количество строк';
    metric_value := v_row_count::TEXT;
    metric_details := 'Текущее количество записей';
    RETURN NEXT;

    -- 2. Размеры
    metric_category := '2. РАЗМЕРЫ';
    metric_name := 'Размер данных';
    metric_value := pg_size_pretty(v_table_size);
    metric_details := v_table_size::TEXT || ' байт';
    RETURN NEXT;

    metric_name := 'Размер индексов';
    metric_value := pg_size_pretty(v_index_size);
    metric_details := v_index_size::TEXT || ' байт';
    RETURN NEXT;

    metric_name := 'Общий размер';
    metric_value := pg_size_pretty(v_total_size);
    metric_details := v_total_size::TEXT || ' байт';
    RETURN NEXT;

    -- 3. Статистика обслуживания
    metric_category := '3. СТАТИСТИКА';
    metric_name := 'Живых строк';
    metric_value := COALESCE(v_n_live_tup, 0)::TEXT;
    metric_details := 'По данным статистики';
    RETURN NEXT;

    metric_name := 'Мертвых строк';
    metric_value := COALESCE(v_n_dead_tup, 0)::TEXT;
    metric_details := 'Ожидают очистки';
    RETURN NEXT;

    metric_name := 'Последний ANALYZE';
    metric_value := COALESCE(v_last_analyze::TEXT, 'Никогда');
    metric_details := 'Сбор статистики';
    RETURN NEXT;

    -- 4. Рекомендации
    metric_category := '4. РЕКОМЕНДАЦИИ';

    IF v_n_live_tup > 0 AND v_n_dead_tup::NUMERIC / v_n_live_tup > 0.2 THEN
        metric_name := '⚠ НУЖЕН VACUUM';
        metric_value := 'СРОЧНО';
        metric_details := 'Более 20% мертвых строк';
        RETURN NEXT;
    END IF;

    IF v_last_analyze IS NULL OR (CURRENT_TIMESTAMP - v_last_analyze) > INTERVAL '7 days' THEN
        metric_name := '⚠ НУЖЕН ANALYZE';
        metric_value := 'РЕКОМЕНДУЕТСЯ';
        metric_details := 'Статистика устарела';
        RETURN NEXT;
    END IF;

    IF v_n_dead_tup < 1000 AND v_last_analyze IS NOT NULL THEN
        metric_name := '✓ СОСТОЯНИЕ';
        metric_value := 'ХОРОШЕЕ';
        metric_details := 'Таблица в нормальном состоянии';
        RETURN NEXT;
    END IF;

END;
$$;

select *
from  get_table_statistics('postgres_air','booking');


DROP FUNCTION IF EXISTS show_table_info;

CREATE OR REPLACE FUNCTION show_table_info(
    schema_name TEXT,
    table_name TEXT
)
    RETURNS TABLE(
                     info_type TEXT,
                     info_name TEXT,
                     info_value TEXT
                 )
    LANGUAGE plpgsql
AS $$
DECLARE
    v_full_table TEXT;
BEGIN
    v_full_table := format('%I.%I', schema_name, table_name);

    -- Проверяем существование таблицы
    IF NOT EXISTS (
        SELECT 1 FROM pg_tables
        WHERE schemaname = schema_name AND tablename = table_name
    ) THEN
        RAISE EXCEPTION 'Таблица %.% не найдена', schema_name, table_name;
    END IF;

    -- 1. ОБЩАЯ ИНФОРМАЦИЯ
    info_type := '📋 ТАБЛИЦА';
    info_name := 'Имя таблицы';
    info_value := table_name;
    RETURN NEXT;

    info_name := 'Схема';
    info_value := schema_name;
    RETURN NEXT;

    -- 2. КОЛОНКИ
    info_type := '📊 КОЛОНКИ';
    info_name := 'Количество колонок';
    SELECT COUNT(*)::TEXT INTO info_value
    FROM pg_attribute
    WHERE attrelid = v_full_table::regclass
      AND attnum > 0
      AND NOT attisdropped;
    RETURN NEXT;

    -- Детали колонок
    RETURN QUERY EXECUTE '
        SELECT
            ''📊 КОЛОНКИ''::TEXT,
            attnum::TEXT || ''. '' || attname::TEXT,
            pg_catalog.format_type(atttypid, atttypmod)::TEXT ||
                CASE WHEN attnotnull THEN '' NOT NULL'' ELSE '''' END
        FROM pg_attribute
        WHERE attrelid = $1::regclass
            AND attnum > 0
            AND NOT attisdropped
        ORDER BY attnum
    ' USING v_full_table::regclass;

    -- 3. ИНДЕКСЫ
    info_type := '🔍 ИНДЕКСЫ';
    info_name := 'Количество индексов';
    SELECT COUNT(*)::TEXT INTO info_value
    FROM pg_indexes
    WHERE schemaname = schema_name AND tablename = table_name;
    RETURN NEXT;

    -- Детали индексов (ИСПРАВЛЕННЫЙ ЗАПРОС)
    RETURN QUERY EXECUTE '
        SELECT
            ''🔍 ИНДЕКСЫ''::TEXT,
            indexname::TEXT,
            CASE
                WHEN indexdef LIKE ''%UNIQUE%'' THEN ''УНИКАЛЬНЫЙ''
                ELSE ''ОБЫЧНЫЙ''
            END || '', '' ||
            CASE
                WHEN indexdef LIKE ''%USING btree%'' THEN ''B-TREE''
                WHEN indexdef LIKE ''%USING hash%'' THEN ''HASH''
                ELSE ''ДРУГОЙ ТИП''
            END
        FROM pg_indexes
        WHERE schemaname = $1
            AND tablename = $2
        ORDER BY indexname::TEXT
    ' USING schema_name, table_name;

    -- 4. ТРИГГЕРЫ
    info_type := '⚡ ТРИГГЕРЫ';
    info_name := 'Количество триггеров';
    SELECT COUNT(*)::TEXT INTO info_value
    FROM pg_trigger
    WHERE tgrelid = v_full_table::regclass AND NOT tgisinternal;
    RETURN NEXT;

    -- Детали триггеров
    RETURN QUERY EXECUTE '
        SELECT
            ''⚡ ТРИГГЕРЫ''::TEXT,
            t.tgname::TEXT,
            p.proname::TEXT || ''() - '' ||
            CASE
                WHEN t.tgtype::integer & 2 = 2 THEN ''INSERT, ''
                ELSE ''''
            END ||
            CASE
                WHEN t.tgtype::integer & 4 = 4 THEN ''DELETE, ''
                ELSE ''''
            END ||
            CASE
                WHEN t.tgtype::integer & 8 = 8 THEN ''UPDATE''
                ELSE ''''
            END
        FROM pg_trigger t
        JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE t.tgrelid = $1::regclass
            AND NOT t.tgisinternal
        ORDER BY t.tgname::TEXT
    ' USING v_full_table::regclass;

    -- Если триггеров нет
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger
        WHERE tgrelid = v_full_table::regclass
          AND NOT tgisinternal
    ) THEN
        info_type := '⚡ ТРИГГЕРЫ';
        info_name := 'Информация';
        info_value := 'Триггеры отсутствуют';
        RETURN NEXT;
    END IF;

END;
$$;


select *
from  show_table_info('postgres_air','booking');




SELECT * FROM pg_stat_user_tables;

SELECT * FROM pg_statio_user_tables;

SELECT relname,
       relpages,
       reltuples,
       relallvisible
FROM pg_class
WHERE relkind = 'r';

SELECT * FROM pg_stat_all_tables;  -- Все таблицы, включая системные
SELECT * FROM pg_stat_xact_all_tables;  -- Транзакционная статистика


CREATE TABLE boarding_pass_part (
                                    pass_id serial4 NOT NULL,
                                    passenger_id int8 NULL,
                                    booking_leg_id int8 NULL,
                                    seat text NULL,
                                    boarding_time timestamptz NULL,
                                    precheck bool NULL,
                                    update_ts timestamptz NULL
)
PARTITION BY RANGE (boarding_time);

---создание секций

CREATE TABLE boarding_pass_may_2020
    PARTITION OF boarding_pass_part
        FOR VALUES FROM ('2024-05-01'::timestamptz) TO ('2024-06-01'::timestamptz);

CREATE TABLE boarding_pass_june_2020
    PARTITION OF boarding_pass_part
        FOR VALUES FROM ('2024-06-01'::timestamptz) TO ('2024-07-01'::timestamptz);

CREATE TABLE boarding_pass_july_2020
    PARTITION OF boarding_pass_part
        FOR VALUES FROM ('2024-07-01'::timestamptz) TO ('2024-08-01'::timestamptz);

CREATE TABLE boarding_pass_aug_2020
    PARTITION OF boarding_pass_part
        FOR VALUES FROM ('2024-08-01'::timestamptz) TO ('2024-09-01'::timestamptz);


INSERT INTO boarding_pass_part
SELECT *
FROM boarding_pass;





SELECT
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM pg_stat_user_tables t2 WHERE t2.relname = t.tablename) as estimated_rows
FROM pg_tables t
WHERE tablename LIKE 'boarding_pass_part%'
ORDER BY tablename;

-- Или через системные таблицы
SELECT
    nmsp_child.nspname AS child_schema,
    child.relname AS child_table,
    pg_get_expr(child.relpartbound, child.oid) AS partition_bounds
FROM pg_inherits
         JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
         JOIN pg_class child ON pg_inherits.inhrelid = child.oid
         JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
         JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE parent.relname = 'boarding_pass_part'
ORDER BY partition_bounds;






SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as total_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
LIMIT 10;

ANALYZE;

SELECT pg_stat_reset();

SELECT city,
       date_trunc('month', f.scheduled_departure),
       sum(passengers) passengers
FROM airport a
         JOIN flight f  ON a.airport_code = f.departure_airport
         JOIN (
    SELECT flight_id, count(*) passengers
    FROM booking_leg l
             JOIN boarding_pass_part b USING (booking_leg_id)
    WHERE   b.boarding_time    > '2024-07-15'
      AND   b.boarding_time   < '2024-07-17'
    GROUP BY flight_id
) cnt ON f.flight_id = cnt.flight_id
GROUP BY 1,2

VACUUM pg_catalog.pg_class;
VACUUM pg_catalog.pg_attribute;
VACUUM (VERBOSE, ANALYZE);


SET SEARCH_PATH TO postgres_air;

CREATE INDEX flight_arrival_airport ON flight ( arrival_airport );
CREATE INDEX booking_leg_flight_id ON booking_leg ( flight_id );
CREATE INDEX flight_actual_departure ON flight ( actual_departure );
CREATE INDEX boarding_pass_booking_leg_id ON boarding_pass ( booking_leg_id );
CREATE INDEX boarding_pass_update_ts ON boarding_pass ( update_ts );
CREATE INDEX flight_actual_departure_not_null ON flight ( actual_departure )
    WHERE actual_departure IS NOT NULL;
CREATE INDEX account_login ON account ( login );
CREATE INDEX account_login_lower_pattern ON account ( LOWER(login) text_pattern_ops );
CREATE INDEX passenger_last_name ON passenger ( last_name );
CREATE INDEX boarding_pass_passenger_id ON boarding_pass ( passenger_id );
CREATE INDEX passenger_last_name_lower_pattern ON passenger ( LOWER(last_name) text_pattern_ops );
CREATE INDEX passenger_booking_id ON passenger ( booking_id );
CREATE INDEX booking_account ON booking ( account_id );
CREATE INDEX account_last_name ON account ( last_name );
CREATE INDEX flight_depart_arr_sched_dep ON flight ( departure_airport, arrival_airport, scheduled_departure );
CREATE INDEX flight_depart_arr_sched_dep_sched_arr ON flight ( departure_airport, arrival_airport, scheduled_departure,
                                                               scheduled_arrival );
CREATE INDEX frequent_flyer_fl_last_name_lower_pattern ON frequent_flyer ( LOWER(last_name) text_pattern_ops );
CREATE INDEX frequent_flyer_fl_last_name_lower ON frequent_flyer ( LOWER(last_name) );


CREATE INDEX flight_actual_f_departure ON flight_no_index ( actual_departure );
CREATE INDEX flight_arrival_f_airport ON flight_no_index ( arrival_airport );
CREATE INDEX flight_actual_departure_f_not_null ON flight_no_index ( actual_departure ) WHERE actual_departure IS NOT NULL;
CREATE INDEX flight_depart_arr_sched_f_dep ON flight_no_index ( departure_airport, arrival_airport, scheduled_departure );
CREATE INDEX flight_depart_arr_sched_f_dep_sched_arr ON flight_no_index ( departure_airport, arrival_airport,
                                                                        scheduled_departure, scheduled_arrival );

create table flight_no_index AS select * from flight limit 0;

truncate table flight_no_index;

Insert into flight_no_index
Select * from flight limit 683178;
----1 row retrieved starting from 1 in 382 ms (execution: 48 ms, fetching: 334 ms)
----683,178 rows affected in 9 s 673 ms

select count(*)
    from flight_no_index

VACUUM(ANALYZE, VERBOSE)


CREATE TABLE flight_no_constr AS
SELECT *
FROM flight
LIMIT 0;

SET SEARCH_PATH TO postgres_air;
SELECT departure_airport, arrival_airport, scheduled_departure
FROM flight

create table postgres_air.flight
(
    flight_id           integer default nextval('postgres_air.flight_flight_id_seq'::regclass) not null
        primary key,
    flight_no           text                                                                   not null,
    scheduled_departure timestamp with time zone                                               not null,
    scheduled_arrival   timestamp with time zone                                               not null,
    departure_airport   char(3)                                                                not null
        constraint departure_airport_fk
            references postgres_air.airport,
    arrival_airport     char(3)                                                                not null
        constraint arrival_airport_fk
            references postgres_air.airport,
    status              text                                                                   not null,
    aircraft_code       char(3)                                                                not null
        constraint aircraft_code_fk
            references postgres_air.aircraft,
    actual_departure    timestamp with time zone,
    actual_arrival      timestamp with time zone,
    update_ts           timestamp with time zone
);


alter table postgres_air.flight
    add constraint arrival_airport_fk
        foreign key (arrival_airport) references postgres_air.airport;

alter table postgres_air.flight
    add constraint departure_airport_fk
        foreign key (departure_airport) references postgres_air.airport;


----скрипт понимания зависимостей вторичных ключей от первичных ключей.
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM
    information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
             ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.constraint_column_usage AS ccu
             ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'flight'
  AND tc.table_schema = 'postgres_air';



CREATE OR REPLACE FUNCTION num_passengers(p_flight_id int)
    RETURNS integer
AS
$$
BEGIN
    RETURN (SELECT COUNT(*)
            FROM postgres_air.booking_leg bl
                     JOIN postgres_air.booking b USING (booking_id)
                     JOIN postgres_air.passenger p USING (booking_id)
            WHERE flight_id = p_flight_id);
END;
$$ LANGUAGE plpgsql;

EXPLAIN ANALYZE VERBOSE
select
    f.flight_id,
    num_passengers(f.flight_id)
from flight f
where departure_airport='ORD'
and scheduled_departure BETWEEN '2024-07-05' and '2024-07-13';


EXPLAIN ANALYZE VERBOSE
select
    f.flight_id,
    p.num_pas
from flight f
CROSS JOIN lateral num_passengers(f.flight_id) as p(num_pas)
where departure_airport='ORD'
  and scheduled_departure BETWEEN '2024-07-05' and '2024-07-13';


create type boarding_pass_record as (
    boarding_pass_id integer,
    booking_leg_id bigint,
    flight_no text,
    departure_airport text,
    arrival_airport text,
    last_name text,
    first_name text,
    seat text,
    boarding_time timestamptz);

drop function boarding_passes_pass;
CREATE OR REPLACE FUNCTION boarding_passes_pass(p_pass_id int)
    RETURNS setof boarding_pass_record
AS
$body$
BEGIN
    RETURN QUERY
        SELECT pass_id,
               bp.booking_leg_id,
               flight_no,
               departure_airport::text,
               arrival_airport::text,
               last_name,
               first_name,
               seat,
               boarding_time
        FROM flight f
                 JOIN booking_leg bl USING (flight_id)
                 JOIN boarding_pass bp USING (booking_leg_id)
                 JOIN passenger p USING (passenger_id)
        WHERE pass_id = p_pass_id;
END;
$body$ LANGUAGE plpgsql;

select *
from  boarding_passes_pass(462972);


CREATE OR REPLACE FUNCTION issue_boarding_pass(
    p_booking_leg_id int,
    p_passenger_id int,
    p_seat text,
    p_boarding_time timestamptz
)
    RETURNS setof boarding_pass_record
AS
$body$
DECLARE
    v_pass_id int;
BEGIN
INSERT INTO boarding_pass(
        passenger_id,
        booking_leg_id,
        seat,
        boarding_time,
        update_ts
    ) VALUES (
        p_passenger_id,
        p_booking_leg_id,
        p_seat,
        p_boarding_time,
        now()
    )
RETURNING pass_id INTO v_pass_id; ---он генерируется сам
RETURN QUERY
select *
FROM boarding_passes_pass(v_pass_id);
end;
$body$ LANGUAGE plpgsql;


select *
from issue_boarding_pass(175820, 462972,
                         '22A', '2025-06-16 21:45'::timestamptz)

select * ----30195235 ---175820
from  boarding_pass
where pass_id = 30195236


select *
from  boarding_passes_pass( 30195236);

