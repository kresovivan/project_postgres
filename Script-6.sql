SET SEARCH_PATH TO postgres_air;
CREATE INDEX flight_arrival_airport ON flight(arrival_airport);
CREATE INDEX booking_leg_flight_id ON booking_leg(flight_id);
CREATE INDEX flight_actual_departure ON flight(actual_departure);
CREATE INDEX boarding_pass_booking_leg_id ON boarding_pass(booking_leg_id);

EXPLAIN
SELECT *
FROM flight
WHERE departure_airport = 'LAX' 
AND update_ts BETWEEN '2020-08-16' AND '2020-08-18'
AND status = 'Delayed'
AND scheduled_departure BETWEEN  '2020-08-16' AND '2020-08-18'


Select flight_id 
From flight f where exists
(select flight_id from booking_leg 
where flight_id = f.flight_id)

Select flight_id 
From flight f 
intersect
select flight_id 
from booking_leg 



Select flight_id 
From flight f where not exists
(select flight_id from booking_leg 
where flight_id = f.flight_id)

Select flight_id 
From flight f 
except
select flight_id 
from booking_leg 




SELECT *
FROM flight f
JOIN (SELECT DISTINCT flight_id FROM booking_leg) bl
using(flight_id)


SELECT 
a.avg_price,
a.departure_airport,
a.num_passengers 
FROM (
SELECT 
bl.flight_id,
departure_airport,
(avg(price))::numeric(7,2) AS avg_price,
count(DISTINCT passenger_id) AS num_passengers
FROM booking b
JOIN booking_leg bl using(booking_id)
JOIN flight f USING(flight_id)
JOIN passenger p using(booking_id)
GROUP BY 1,2
) a
WHERE a.flight_id IN (SELECT flight_id
FROM flight 
WHERE scheduled_departure BETWEEN '2020-01-07' AND 
'2020-08-07')




SELECT 
city,
date_trunc('month', scheduled_departure) AS month,
count(*) passengers
FROM airport a
JOIN flight f ON a.airport_code = f.departure_airport 
JOIN booking_leg l ON f.flight_id  = l.flight_id 
JOIN boarding_pass b ON b.booking_leg_id = l.booking_leg_id 
GROUP BY city,month
ORDER BY passengers desc


SELECT 
city,
date_trunc('month', scheduled_departure) AS month,
count(*) passengers
FROM airport a
JOIN flight f ON a.airport_code = f.departure_airport 
JOIN (
SELECT flight_id, count(*) passengers 
FROM booking_leg l
JOIN boarding_pass b ON b.booking_leg_id = l.booking_leg_id 
GROUP BY flight_id
) cnt ON cnt.flight_id = f.flight_id 
GROUP BY city,month
ORDER BY passengers desc



SELECT 
departure_airport,
(avg(price))::numeric(7,2) AS avg_price,
count(DISTINCT passenger_id) AS num_passengers
FROM booking b
JOIN booking_leg bl using(booking_id)
JOIN flight f USING(flight_id)
JOIN passenger p using(booking_id)
WHERE scheduled_departure BETWEEN '2020-01-07' AND 
'2020-08-07'
GROUP BY 1,2




Select *
From flight f where NOT exists
(select flight_id from booking_leg where flight_id = f.flight_id)


SELECT *
FROM flight f
left join booking_leg bl using(flight_id)
WHERE bl.flight_id IS null

-- Завершите предыдущую прерванную транзакцию
ROLLBACK;

-- Теперь выполняйте ваш код
DO $$
DECLARE
    flight_record RECORD;
    flight_batch_cursor CURSOR FOR
        SELECT *
        FROM flight
        WHERE status = 'On scheduled';
    batch_count INTEGER := 0;
BEGIN
    -- Открываем курсор
    OPEN flight_batch_cursor;
    
    -- Обрабатываем данные пачками
    LOOP
        FETCH flight_batch_cursor INTO flight_record;
        EXIT WHEN NOT FOUND;
        
        -- Здесь ваша бизнес-логика
        batch_count := batch_count + 1;
        
        -- Пример обработки данных
        RAISE NOTICE 'Processing flight: %, Aircraft: %, Status: %', 
            flight_record.flight_no, 
            flight_record.aircraft_code,
            flight_record.status;
        
        -- Каждые 20 записей выводим сообщение
        IF batch_count % 20 = 0 THEN
            RAISE NOTICE 'Processed batch of 20 flights. Total: %', batch_count;
        END IF;
    END LOOP;
    
    -- Закрываем курсор
    CLOSE flight_batch_cursor;
    
    RAISE NOTICE 'Completed! Total flights processed: %', batch_count;
END $$;



BEGIN;
-- Курсор для вашего запроса
DECLARE my_flight_cursor CURSOR FOR
SELECT *
FROM flight
WHERE status = 'On scheduled';

-- Читаем и обрабатываем данные порциями
LOOP
    -- Получаем 5 записей за раз
    FETCH 5 FROM my_flight_cursor;
    EXIT WHEN NOT FOUND;
    -- Здесь можно обрабатывать данные
    -- Например, выводить их или передавать в другую систему
END LOOP;

CLOSE my_flight_cursor;
COMMIT;



/*Когда использовать курсоры:
✅ Большие наборы данных - чтобы не грузить все в память
✅ Построчная обработка с сложной логикой
✅ Длительные операции с возможностью прерывания
✅ Пакетная обработка с коммитами через время*/


DO $$
DECLARE
    flight_row RECORD;
    -- Курсор с блокировкой строк для обновления
    update_cursor CURSOR FOR
        SELECT *
        FROM flight
        WHERE status = 'On scheduled'
          AND scheduled_departure < NOW() - INTERVAL '1 hour'
        FOR UPDATE;  -- Блокируем строки для изменения
BEGIN
    OPEN update_cursor;
    
    RAISE NOTICE 'Обновляем задержанные рейсы...';
    
    LOOP
        FETCH update_cursor INTO flight_row;
        EXIT WHEN NOT FOUND;
        
        -- Меняем статус на "Delayed"
        UPDATE flight 
        SET status = 'Delayed',
            last_updated = NOW()
        WHERE CURRENT OF update_cursor;  -- Обновляем текущую строку курсора
        
        RAISE NOTICE 'Обновлен рейс %: On scheduled → Delayed', flight_row.flight_no;
    END LOOP;
    
    CLOSE update_cursor;
END $$;







SELECT * FROM pg_stat_activity 

SELECT * FROM pg_locks 
WHERE granted = false;

ROLLBACK;





ALTER TABLE booking 
ADD CONSTRAINT booking_pkey PRIMARY KEY (booking_id)

CREATE UNIQUE INDEX account_freq_flyer ON account (frequent_flyer_id)

ALTER TABLE booking 
ADD CONSTRAINT booking_booking_ref_pkey UNIQUE (booking_ref)
/*
DROP INDEX CONCURRENTLY IF EXISTS  flight_arrival_airport;
DROP INDEX CONCURRENTLY IF EXISTS  booking_leg_flight_id;
DROP INDEX CONCURRENTLY IF EXISTS flight_actual_departure; 
DROP INDEX CONCURRENTLY IF EXISTS boarding_pass_booking_leg_id;
*/
/*ANALYZE flight,booking_leg,boarding_pass*/

/*Короткий запрос является коротким, когда количество строк необходимых 
 * для получения результата  - невелико, независимо от того, насколько 
 * велики задействованные таблицы. Короткие запросы могут считывать 
 * все строки из маленьких таблиц, но лишь неболльшой процент строк из
 * больших таблиц!!!  */

/*ALTER TABLE booking
ADD CONSTRAINT booking_pkey PRIMARY KEY (booking_id);*/

EXPLAIN ANALYZE 
SELECT 
f.flight_id,
f.scheduled_departure,
ac.model
count(passenger_id) passengers
FROM flight f
JOIN booking_leg bl on bl.flight_id = f.flight_id
JOIN passenger p ON p.booking_id = bl.booking_id 
JOIN aircraft ac ON ac.code = f.aircraft_code 
WHERE f.departure_airport = 'JFK'
AND f.arrival_airport = 'ORD'
AND f.scheduled_departure BETWEEN '2020-08-01' AND '2020-08-16'
GROUP BY 
f.flight_id,
f.scheduled_departure,
ac.model



/*Очень неэффетиквно*/
WITH filtered_flights AS (
    SELECT 
        flight_id,
        scheduled_departure,
        aircraft_code
    FROM flight 
    WHERE departure_airport = 'JFK'
        AND arrival_airport = 'ORD'
        AND scheduled_departure BETWEEN '2024-08-01' AND '2024-08-16'
),

filtered_booking_legs AS (
    SELECT 
        bl.booking_id,
        bl.flight_id
    FROM booking_leg bl
    WHERE bl.flight_id IN (SELECT flight_id FROM filtered_flights)
),

filtered_passengers AS (
    SELECT 
        p.booking_id,
        p.passenger_id
    FROM passenger p
    WHERE p.booking_id IN (SELECT booking_id FROM filtered_booking_legs)
),

filtered_aircrafts AS (
    SELECT 
        ac.code,
        ac.model
    FROM aircraft ac
    WHERE ac.code IN (SELECT DISTINCT aircraft_code FROM filtered_flights)
)

SELECT 
    f.flight_id,
    f.scheduled_departure,
    ac.model,
    COUNT(p.passenger_id) AS passengers
FROM filtered_flights f
JOIN filtered_booking_legs bl ON bl.flight_id = f.flight_id
JOIN filtered_passengers p ON p.booking_id = bl.booking_id
JOIN filtered_aircrafts ac ON ac.code = f.aircraft_code
GROUP BY 
    f.flight_id,
    f.scheduled_departure,
    ac.model
ORDER BY f.scheduled_departure;


EXPLAIN analyze
WITH filtered_flights AS (
    SELECT 
        flight_id,
        scheduled_departure,
        aircraft_code
    FROM flight 
    WHERE departure_airport = 'JFK'
        AND arrival_airport = 'ORD'
       
),

flight_booking_legs AS (
    SELECT 
        bl.booking_id,
        f.flight_id,
        f.scheduled_departure,
        f.aircraft_code
    FROM filtered_flights f
    JOIN booking_leg bl ON bl.flight_id = f.flight_id
),

flight_passengers AS (
    SELECT 
        fbl.flight_id,
        fbl.scheduled_departure,
        fbl.aircraft_code,
        p.passenger_id
    FROM flight_booking_legs fbl
    JOIN passenger p ON p.booking_id = fbl.booking_id
)

SELECT 
    fp.flight_id,
    fp.scheduled_departure,
    ac.model,
    COUNT(fp.passenger_id) AS passengers
FROM flight_passengers fp
JOIN aircraft ac ON ac.code = fp.aircraft_code
GROUP BY 
    fp.flight_id,
    fp.scheduled_departure,
    ac.model
ORDER BY fp.scheduled_departure;

EXPLAIN analyze
/*+
    Materialize(filtered_flights)
    HashJoin(booking_leg filtered_flights)
    HashJoin(passenger flight_booking_legs) 
    HashJoin(aircraft flight_passengers)
    HashAggregate(final_result)
    IndexScan(flight flight_dep_arr_idx)
    IndexScan(booking_leg booking_leg_flight_id_idx)
    IndexScan(passenger passenger_booking_id_idx)
*/
WITH filtered_flights AS (
    SELECT 
        flight_id,
        scheduled_departure,
        aircraft_code
    FROM flight 
    WHERE departure_airport = 'JFK'
        AND arrival_airport = 'ORD'
),

flight_booking_legs AS (
    SELECT 
        bl.booking_id,
        f.flight_id,
        f.scheduled_departure,
        f.aircraft_code
    FROM filtered_flights f
    JOIN booking_leg bl ON bl.flight_id = f.flight_id
),

flight_passengers AS (
    SELECT 
        fbl.flight_id,
        fbl.scheduled_departure,
        fbl.aircraft_code,
        p.passenger_id
    FROM flight_booking_legs fbl
    JOIN passenger p ON p.booking_id = fbl.booking_id
)

SELECT 
    fp.flight_id,
    fp.scheduled_departure,
    ac.model,
    COUNT(fp.passenger_id) AS passengers
FROM flight_passengers fp
JOIN aircraft ac ON ac.code = fp.aircraft_code
GROUP BY 
    fp.flight_id,
    fp.scheduled_departure,
    ac.model
ORDER BY fp.scheduled_departure;


/*Индексы и преобразования столлбцов*/
CREATE INDEX account_last_name ON account(last_name);

/*Следующий запрос не сможет воспользоваться этим индексом*/

EXPLAIN 
SELECT *
FROM account
WHERE lower(last_name)='daniels'

CREATE INDEX account_last_name_lower ON account(lower(last_name));


/*Bitmap Heap Scan on account  (cost=51.40..5379.65 rows=5609 width=52)
  Recheck Cond: (lower(last_name) = 'daniels'::text)
  ->  Bitmap Index Scan on account_last_name_lower  (cost=0.00..49.99 rows=5609 width=0)
        Index Cond: (lower(last_name) = 'daniels'::text) */
EXPLAIN 
SELECT *
FROM account
WHERE lower(last_name)='Daniels'



/*Gather (cost=1000.00..17383.86 rows=35060 width=71)
  Workers Planned: 2
  ->  Parallel Seq Scan on flight  (cost=0.00..12877.86 rows=14608 width=71)
        Filter: ((scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND 
        (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp 
        with time zone))*/
EXPLAIN
SELECT *
FROM flight
WHERE scheduled_departure BETWEEN '2020-08-01' AND '2024-08-10'


CREATE INDEX scheduled_departure_time ON flight(scheduled_departure);

/*Bitmap Heap Scan on flight  (cost=416.79..9550.69 rows=35060 width=71)
  Recheck Cond: ((scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) 
  AND (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone))
  ->  Bitmap Index Scan on scheduled_departure_time  (cost=0.00..408.03 rows=35060 width=0)
        Index Cond: ((scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) 
        AND (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone))
*/

EXPLAIN
SELECT *
FROM flight
WHERE scheduled_departure BETWEEN '2024-08-01' AND '2024-08-10'


/*Индекс не используется
 функция изменяет значение столбца 
 Gather  (cost=1000.00..14219.46 rows=3416 width=71)
  Workers Planned: 2
  ->  Parallel Seq Scan on flight  (cost=0.00..12877.86 rows=1423 width=71)
        Filter: ((COALESCE(actual_departure, scheduled_departure) >= 
        '2024-08-01 00:00:00+03'::timestamp with time zone) 
        AND (COALESCE(actual_departure, scheduled_departure) 
        <= '2024-08-10 00:00:00+03'::timestamp with time zone))*/
EXPLAIN
SELECT *
FROM flight
WHERE COALESCE(actual_departure, scheduled_departure) 
BETWEEN '2024-08-01' AND '2024-12-10'


/*Данный запрос перепишем
 * Bitmap Heap Scan on flight  (cost=859.05..10871.39 rows=54071 width=71)
  Recheck Cond: (((actual_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (actual_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone)) OR ((scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone)))
  Filter: (((actual_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (actual_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone)) OR ((actual_departure IS NULL) AND (scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone)))
  ->  BitmapOr  (cost=859.05..859.05 rows=70217 width=0)
        ->  Bitmap Index Scan on flight_actual_departure  (cost=0.00..423.99 rows=35156 width=0)
              Index Cond: ((actual_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (actual_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone))
        ->  Bitmap Index Scan on scheduled_departure_time  (cost=0.00..408.03 rows=35060 width=0)
              Index Cond: ((scheduled_departure >= '2024-08-01 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-08-10 00:00:00+03'::timestamp with time zone))
*/
EXPLAIN
SELECT *
FROM flight
WHERE (actual_departure BETWEEN '2024-08-01' AND '2024-08-10')
      OR (actual_departure IS NULL  AND scheduled_departure BETWEEN '2024-08-01' AND '2024-08-10');


/*Индексы и оператор like
 * не работает c B-деревом
 *text_pattern_ops - 
 *операторный класс для поиска по шаблонам*/

CREATE INDEX account_last_name_lower_pattern
ON account(lower(last_name) text_pattern_ops);

EXPLAIN
SELECT *
FROM account a 
WHERE lower(last_name) LIKE 'johns%'  


SELECT name, setting, short_desc 
FROM pg_settings 
WHERE name LIKE '%lc%' OR name LIKE '%locale%';

/*Составные индексы
 *Индекс  flight_depart_arr_sched_dep будет поддерживать поиск
 *по столбцам  departure_airport, 
 *departure_airport, arrival_airport, 
 *departure_airport, arrival_airport, scheduled_departure
 *но не будет поддерживать например arrival_airport или scheduled_departure*/

CREATE INDEX flight_depart_arr_sched_dep 
ON flight (departure_airport, arrival_airport, scheduled_departure)
/*Составной индекс не используется
 * Bitmap Heap Scan on flight f  (cost=142.51..232.51 rows=61 width=71)
  Recheck Cond: ((scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-07-04 00:00:00+03'::timestamp with time zone) AND (arrival_airport = 'JFK'::bpchar))
  ->  BitmapAnd  (cost=142.51..142.51 rows=61 width=0)
        ->  Bitmap Index Scan on scheduled_departure_time  (cost=0.00..46.70 rows=3878 width=0)
              Index Cond: ((scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-07-04 00:00:00+03'::timestamp with time zone))
        ->  Bitmap Index Scan on flight_arrival_airport  (cost=0.00..95.52 rows=10680 width=0)
              Index Cond: (arrival_airport = 'JFK'::bpchar)*/
EXPLAIN
SELECT *
FROM flight f 
WHERE  f.arrival_airport = 'JFK'
AND f.scheduled_departure BETWEEN '2024-07-03' AND '2024-07-04'


/*Index Scan using flight_depart_arr_sched_dep on flight f  (cost=0.42..3.45 rows=1 width=20)
  Index Cond: ((departure_airport = 'ORD'::bpchar) AND (arrival_airport = 'JFK'::bpchar) 
  AND (scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-07-04 00:00:00+03'::timestamp with time zone))*/
EXPLAIN
SELECT *
FROM flight f 
WHERE f.departure_airport = 'ORD' --(1)
AND f.arrival_airport = 'JFK' --(2)
AND f.scheduled_departure BETWEEN '2024-07-03' AND '2024-07-04' --(3)

/*Чем ниже селективность тем быстрее идет поиск и когда мы оптимизируем 
 * короткие запросы, наша йель избежать чтения большого количества 
 * строк на каждом шаге
 * 
 * Селективность в теории баз данных — это фундаментальное понятие, 
 * которое показывает, какая доля строк из общей таблицы будет 
 * выбрана в результате выполнения условия в запросе 
 * (обычно в WHERE, JOIN или HAVING
 * 
 * */
CREATE INDEX flight_depart_arr_sched_dep_sched_arr 
ON flight (departure_airport, arrival_airport, scheduled_departure,
scheduled_arrival);

DROP INDEX flight_depart_arr_sched_dep_sched_arr 
/*
 * Index Only Scan using flight_depart_arr_sched_dep_sched_arr on flight f  (cost=0.42..3.45 rows=1 width=20)
  Index Cond: ((departure_airport = 'ORD'::bpchar) AND (arrival_airport = 'JFK'::bpchar) AND (scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure 
  <= '2024-07-04 00:00:00+03'::timestamp with time zone))
 * */


EXPLAIN
SELECT 
f.departure_airport,
f.scheduled_departure,
f.scheduled_arrival 
FROM flight f 
WHERE f.departure_airport = 'ORD' --(1)
AND f.arrival_airport = 'JFK' --(2)
AND f.scheduled_departure BETWEEN '2024-07-03' AND '2024-07-04' --(3)

/*Если в условии убрать первый столбец индекса: 
 * Bitmap Heap Scan on flight f  (cost=142.51..232.51 rows=61 width=71)
  Recheck Cond: ((scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-07-04 00:00:00+03'::timestamp with time zone) AND (arrival_airport = 'JFK'::bpchar))
  ->  BitmapAnd  (cost=142.51..142.51 rows=61 width=0)
        ->  Bitmap Index Scan on scheduled_departure_time  (cost=0.00..46.70 rows=3878 width=0)
              Index Cond: ((scheduled_departure >= '2024-07-03 00:00:00+03'::timestamp with time zone) AND (scheduled_departure <= '2024-07-04 00:00:00+03'::timestamp with time zone))
        ->  Bitmap Index Scan on flight_arrival_airport  (cost=0.00..95.52 rows=10680 width=0)
              Index Cond: (arrival_airport = 'JFK'::bpchar)
  */

EXPLAIN
SELECT
f.departure_airport,
f.scheduled_departure,
f.scheduled_arrival 
FROM flight f 
WHERE  f.arrival_airport = 'JFK' --(2)
AND f.scheduled_departure BETWEEN '2024-07-03' AND '2024-07-04' --(3)

/*Покрывающий индекс - сканирование только индекса*/

CREATE INDEX flight_depart_arr_sched_dep_inc_sched_arr 
ON flight (departure_airport, arrival_airport, scheduled_departure)
INCLUDE (scheduled_arrival);


EXPLAIN
SELECT 
f.departure_airport,
f.scheduled_departure,
f.scheduled_arrival 
FROM flight f 
WHERE f.departure_airport = 'ORD' --(1)
AND f.arrival_airport = 'JFK' --(2)
AND f.scheduled_departure BETWEEN '2024-07-03' AND '2024-07-04' --(3)

/*Избыточные критерии отборааа
 * когда логика фильтрации сложна и включает атртрибуты
 * из нескольких таблиц и необходимо предоставить избыточные фильтры
 * чтобы движок баазы данных использовал определенные индексы или
 * уменьшил размер соединяемых наборов строк*/

CREATE INDEX boarding_pass_update_ts ON boarding_pass(update_ts)
REINDEX INDEX boarding_pass_update_ts;
VACUUM (VERBOSE, ANALYZE) boarding_pass;

EXPLAIN
SELECT 
f.scheduled_departure,
f.actual_departure,
f.status 
FROM flight f
JOIN booking_leg bl USING (flight_id)
JOIN boarding_pass bp using(booking_leg_id)
WHERE bp.update_ts > f.scheduled_departure + INTERVAL '30 minutes'
AND f.update_ts >=f.scheduled_departure - INTERVAL '1 hour'
AND bp.update_ts >= '2024-08-01' AND bp.update_ts < '2024-08-03'


/*Частичные индексы
 * индекс строится на подмножестве таблицы, определяемом в предложении
 * where команды create index*/

CREATE INDEX flight_actual_departure_not_null ON flight(actual_departure)
WHERE actual_departure IS NOT NULL

CREATE INDEX flight_canceled ON flight(flight_id)
WHERE status = 'Canceled'

EXPLAIN ANALYZE

SELECT 
f.scheduled_departure,
f.actual_departure,
f.status 
FROM flight f
WHERE f.status = 'Canceled'
AND f.scheduled_departure  BETWEEN '2024-07-01' AND '2024-10-02'


EXPLAIN ANALYZE
SELECT *
FROM boarding_pass
WHERE update_ts BETWEEN '2024-07-10' AND '2024-08-25'


REINDEX INDEX boarding_pass_pkey;
VACUUM (VERBOSE, ANALYZE) boarding_pass;

/*INSERT INTO postgres_air.boarding_pass (
    passenger_id,
    booking_leg_id,
    seat,
    boarding_time,
    precheck,
    update_ts
)
SELECT 
    passenger_id,
    booking_leg_id,
    seat,
    boarding_time,
    precheck,
    update_ts
FROM postgres_air.boarding_pass
CROSS JOIN GENERATE_SERIES(1, 3); */


/*Полусоединение*/
SELECT *
FROM flight f 
WHERE EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)

/*Подробнее о порядке соединений*/

CREATE INDEX booking_upadate_ts ON booking (update_ts)



SET join_collapse_limit = 8;
EXPLAIN ANALYZE
SELECT f.departure_airport, bl.booking_id, bl.is_returning   
FROM booking_leg bl 
JOIN flight f USING (flight_id)
WHERE f.departure_airport IN (SELECT airport_code FROM airport WHERE iso_country = 'US')
AND bl.booking_id IN (SELECT booking_id FROM booking WHERE update_ts > '2024-07-01')


SET join_collapse_limit = 1;
EXPLAIN ANALYZE
SELECT f.departure_airport, bl.booking_id, bl.is_returning   
FROM booking_leg bl 
JOIN flight f USING (flight_id)
WHERE f.departure_airport IN (SELECT airport_code FROM airport WHERE iso_country = 'US')
AND bl.booking_id IN (SELECT booking_id FROM booking WHERE COALESCE(update_ts,'2024-07-02')  > '2024-07-01')


/*Антисоединение*/
EXPLAIN ANALYZE
SELECT *
FROM flight f 
WHERE  NOT EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)


EXPLAIN ANALYZE
SELECT *
FROM flight f 
WHERE flight_id NOT IN (SELECT flight_id FROM booking_leg)


/*Полусоединения с использованием оператора join*/

EXPLAIN ANALYZE
SELECT f.*
FROM flight f 
JOIN booking_leg bl USING (flight_id) 

/*Чтобы вернуть только по одной записи на рейс*/

EXPLAIN ANALYZE
SELECT *
FROM flight f 
JOIN (SELECT DISTINCT flight_id from booking_leg) bl 
USING (flight_id) 

EXPLAIN ANALYZE
SELECT *
FROM flight f 
WHERE EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)

/*Антисоединение не може создавать дубликаты*/


EXPLAIN ANALYZE
SELECT f.*
FROM flight f 
LEFT JOIN booking_leg bl USING (flight_id) 
WHERE bl.flight_id IS NULL

SET join_collapse_limit = 1;
EXPLAIN ANALYZE
SELECT *
FROM flight f 
WHERE  NOT EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)


/* Факториал — это не просто абстрактное математическое понятие, 
а чрезвычайно полезный инструмент с огромным количеством практических применений. 
Его основная цель — посчитать количество 
способов, которыми можно упорядочить или выбрать объекты. */


/*Сначала группируем затем выбираем
 * вычисллим коллличество пассажиров вылетающих из каждого города по месяцам
 */

SELECT
a.city,
date_trunc('month', f.scheduled_departure) AS month,
count(*) passengers
FROM airport a
JOIN flight f ON a.airport_code = f.departure_airport 
JOIN booking_leg l ON f.flight_id = l.flight_id 
JOIN boarding_pass b ON b.booking_leg_id = l.booking_leg_id
GROUP BY a.city,month
ORDER BY passengers

/*Получает аналогичные данные что и в первом запросе
 * но в нем сначала выполняется группировка
 * 
 * количество вылетающих пассажиров вычичсляется для каждого рейса
 * во вложенном представлении cnt  после этого резулльтат объединяется
 * с таблицей flight для получения кода аэропорта, а затем соединяется с таблицей
 * airport, чтобы найти город в котором расположен каждый аэропорт, после
 * этого количество рейсов суммируется по городам*/
SELECT
a.city,
date_trunc('month', f.scheduled_departure) AS month,
sum(passengers) AS passengers
FROM airport a
JOIN flight f ON a.airport_code = f.departure_airport

JOIN (SELECT l.flight_id, count(*) passengers
FROM  booking_leg l
JOIN boarding_pass b ON b.booking_leg_id = l.booking_leg_id
GROUP BY l.flight_id) cnt ON f.flight_id = cnt.flight_id

GROUP BY 1,2
ORDER BY passengers


/*Исполльзование операторов над множествами
 * операции над множествами позволлляют выбрать альтернативный эффективный
 * план выполлнения
 * except вместо not exists и not in
 * inersect вместо exists и in
 * использовать union вместо сложных критериев отбора с or 
 * */

EXPLAIN ANALYZE
SELECT f.flight_id 
FROM flight f
EXCEPT 
SELECT bl.flight_id 
FROM booking_leg bl
ORDER BY flight_id 

EXPLAIN ANALYZE
SELECT f.flight_id 
FROM flight f 
WHERE  NOT EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)
ORDER BY flight_id 


EXPLAIN ANALYZE
SELECT f.flight_id 
FROM flight f
INTERSECT 
SELECT bl.flight_id 
FROM booking_leg bl
ORDER BY flight_id 

EXPLAIN ANALYZE
SELECT f.flight_id 
FROM flight f 
WHERE EXISTS (SELECT flight_id FROM booking_leg 
WHERE flight_id = f.flight_id)
ORDER BY flight_id 

/*Еще одна причина медлленного выполнения это многкратное сканирование таблиц
 * рассмотрим на примере таблицы сущность - аттрибут - значение.
 *для этого создадим такую таблицу*/

create table custom_field (
custom_field_id serial,
passenger_id int,
custom_field_name text,
custom_field_value text);
alter table custom_field
add constraint custom_field_pk primary key (custom_field_id);

do $$
declare v_rec record;
begin
for v_rec in (select passenger_id from passenger)
loop
insert into custom_field (passenger_id, 
						 custom_field_name,
                          custom_field_value)
						  values
						  (v_rec.passenger_id,
						  'passport_num',
						  ((random()*1000000000000)::bigint)::text);
end loop;
end;
$$;



do $$
declare v_rec record;
v_days int;
begin
for v_rec in (select passenger_id from passenger)
loop
v_days:=(random()*5000)::int;
insert into custom_field (passenger_id, 
						 custom_field_name,
                          custom_field_value)
						  values
						  (v_rec.passenger_id,
						  'passport_exp_date',
						  (('2020-08-18'::date + v_days*interval '1 day')::date)::text);
end loop;
end;
$$;

do $$
declare v_rec record;
v_country text;
begin
for v_rec in (select passenger_id from passenger)
loop
v_country:=case mod (v_rec.passenger_id, 7)
when 0 then 'Mordor'
when 1 then 'Narnia'
When 2 then 'Shambhala'
when 3 then 'Shire'
when 4 then 'Narnia'
when 5 then 'Shire'
when 6 then 'Narnia'
end ;

insert into custom_field (passenger_id, 
						 custom_field_name,
                          custom_field_value)
						  values
						  (v_rec.passenger_id,
						  'passport_country',
						  v_country);
end loop;
end;
$$;


EXPLAIN ANALYZE
SELECT *
FROM passenger p 
JOIN custom_field pn ON pn.passenger_id = p.passenger_id 
AND pn.custom_field_name = 'passport_num'
WHERE pn.passenger_id < 5000000

SELECT version();



-- Создаем временную таблицу
CREATE TEMPORARY TABLE temp_test (
    id SERIAL,
    data TEXT,
    large_content TEXT
);

-- Наполняем данными и следим за дисковыми операциями
DO $$
BEGIN
    -- Вставка данных (может остаться в RAM)
    INSERT INTO temp_test (data, large_content)
    SELECT 
        'data_' || i,
        repeat('x', 1000)  -- Большие данные
    FROM generate_series(1, 10000) i;
    
    RAISE NOTICE 'Данные вставлены';
END $$;


-- Проверим текущие настройки
SELECT name, setting, unit 
FROM pg_settings 
WHERE name IN ('work_mem', 'temp_buffers', 'maintenance_work_mem');

DROP TABLE temp_test


SELECT 
    schemaname,
    tablename,
    tableowner,
    tablespace
FROM pg_tables 
WHERE tablename LIKE 'temp%';


SELECT datname, temp_files, temp_bytes 
FROM pg_stat_database 
WHERE datname = current_database();




/*Секционирование таблиц*/

DROP TABLE boarding_pass_part

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
FOR VALUES FROM ('2020-05-01'::timestamptz) TO ('2020-06-01'::timestamptz);

CREATE TABLE boarding_pass_june_2020
PARTITION OF boarding_pass_part
FOR VALUES FROM ('2020-06-01'::timestamptz) TO ('2020-07-01'::timestamptz);

CREATE TABLE boarding_pass_july_2020
PARTITION OF boarding_pass_part
FOR VALUES FROM ('2020-07-01'::timestamptz) TO ('2020-08-01'::timestamptz);

CREATE TABLE boarding_pass_aug_2020
PARTITION OF boarding_pass_part
FOR VALUES FROM ('2020-08-01'::timestamptz) TO ('2020-09-01'::timestamptz);


INSERT INTO boarding_pass_part
SELECT * 
FROM boarding_pass;

EXPLAIN ANALYZE
SELECT city,
date_trunc('month', f.scheduled_departure),
sum(passengers) passengers
FROM airport a
JOIN flight f  ON a.airport_code = f.departure_airport
JOIN ( 
SELECT flight_id, count(*) passengers
FROM booking_leg l
JOIN boarding_pass b USING (booking_leg_id)
WHERE b.boarding_time > '2020-07-15'
AND b.boarding_time   < '2020-07-17'
GROUP BY flight_id
) cnt ON f.flight_id = cnt.flight_id 
GROUP BY 1,2


EXPLAIN ANALYZE
SELECT city,
date_trunc('month', f.scheduled_departure),
sum(passengers) passengers
FROM airport a
JOIN flight f  ON a.airport_code = f.departure_airport
JOIN ( 
SELECT flight_id, count(*) passengers
FROM booking_leg l
JOIN boarding_pass_part b USING (booking_leg_id)
WHERE b.boarding_time   > '2020-07-15'
AND   b.boarding_time   < '2020-07-17'
GROUP BY flight_id
) cnt ON f.flight_id = cnt.flight_id 
GROUP BY 1,2



SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE tablename LIKE 'boarding_pass_%'
ORDER BY tablename;



/*ALTER TABLE boarding_pass_part ALTER boarding_time SET STATISTICS 1000;
ANALYZE boarding_pass_part;*/

/*
-- Для мая 2020
CREATE INDEX CONCURRENTLY idx_boarding_pass_may_2020_booking_leg_time 
ON boarding_pass_may_2020 (booking_leg_id, boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_may_2020_boarding_time 
ON boarding_pass_may_2020 (boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_may_2020_time_leg 
ON boarding_pass_may_2020 (boarding_time, booking_leg_id);

-- Для июня 2020
CREATE INDEX CONCURRENTLY idx_boarding_pass_june_2020_booking_leg_time 
ON boarding_pass_june_2020 (booking_leg_id, boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_june_2020_boarding_time 
ON boarding_pass_june_2020 (boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_june_2020_time_leg 
ON boarding_pass_june_2020 (boarding_time, booking_leg_id);

-- Для июля 2020
CREATE INDEX CONCURRENTLY idx_boarding_pass_july_2020_booking_leg_time 
ON boarding_pass_july_2020 (booking_leg_id, boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_july_2020_boarding_time 
ON boarding_pass_july_2020 (boarding_time);

CREATE INDEX CONCURRENTLY idx_boarding_pass_july_2020_time_leg 
ON boarding_pass_july_2020 (boarding_time, booking_leg_id);
*/

SELECT l.flight_id
FROM booking_leg l
JOIN boarding_pass b USING (booking_leg_id)
WHERE b.boarding_time > '2020-07-15'
AND b.boarding_time   < '2020-07-30'

/*Для сеционированной таблицы время уменьшилось в 2,5 раза*/
 


/*
SET max_parallel_workers_per_gather = 0;
SET max_parallel_workers = 0;
*/

/*
SHOW max_parallel_workers_per_gather;
SHOW max_parallel_workers;
SHOW parallel_setup_cost;
SHOW parallel_tuple_cost;
*/

---ALTER DATABASE demo SET max_parallel_workers_per_gather = 0;
----ALTER DATABASE demo SET max_parallel_workers = 0;


CREATE OR REPLACE
FUNCTION text_to_numeric(input_text text)
RETURNS NUMERIC AS 
$BODY$
BEGIN 
	RETURN REPLACE(input_text, ',', '')::NUMERIC;
EXCEPTION
WHEN OTHERS THEN 
RETURN NULL::NUMERIC;
END;

$BODY$
LANGUAGE plpgsql;

---text_to_numeric('1,234,567.89') → REPLACE('1,234,567.89', ',', '') → '1234567.89' → 1234567.89
SELECT text_to_numeric('1-234-567.89'); 


CREATE TYPE boarding_pass_record AS (
boarding_pass_id int,
booking_leg_id bigint,
flight_no text,
departure_airport text,
arrival_airport text,
last_name text,
first_name text,
seat text,
boarding_time timestamptz
)


DROP TYPE IF EXISTS boarding_pass_record CASCADE;

CREATE OR REPLACE FUNCTION  boarding_passes_flight(p_flight_id int)
RETURNS SETOF boarding_pass_record
AS $body$
BEGIN 
	RETURN QUERY
select 
bp.pass_id,
bp.booking_leg_id,
f.flight_no,
f.departure_airport::text,
f.arrival_airport::text,
p.last_name,
p.first_name, 
bp.seat,
bp.boarding_time
from flight f
join booking_leg bl   on f.flight_id = bl.flight_id
join boarding_pass bp on bp.booking_leg_id = bl.booking_leg_id 
join passenger p      on p.passenger_id = bp.passenger_id 
where bl.flight_id = p_flight_id;
END;
$body$
LANGUAGE plpgsql;

SELECT *
FROM boarding_passes_flight(13650); 

/*Без структуры пришлось создавать функцию такого вида*/

CREATE OR REPLACE FUNCTION boarding_passes_flight(p_flight_id int)
RETURNS TABLE(
    boarding_pass_id int,
    booking_leg_id bigint,
    flight_no text,
    departure_airport text,
    arrival_airport text,
    last_name text,
    first_name text,
    seat text,
    boarding_time timestamptz
)
AS $body$
BEGIN 
    RETURN QUERY
    SELECT 
        bp.pass_id,
        bp.booking_leg_id,
        f.flight_no,
        f.departure_airport,
        f.arrival_airport,
        p.last_name,
        p.first_name, 
        bp.seat,
        bp.boarding_time
    FROM flight f
    JOIN booking_leg bl   ON f.flight_id = bl.flight_id
    JOIN boarding_pass bp ON bp.booking_leg_id = bl.booking_leg_id 
    JOIN passenger p      ON p.passenger_id = bp.passenger_id 
    WHERE bl.flight_id = p_flight_id;
END;
$body$
LANGUAGE plpgsql;


/*Созадим еще одну функцию*/

CREATE OR REPLACE FUNCTION  boarding_passes_pass(p_pass_id int)
RETURNS SETOF boarding_pass_record ---SETOF - "множество записей"
AS $body$
BEGIN 
	RETURN QUERY
select 
bp.pass_id,
bp.booking_leg_id,
f.flight_no,
f.departure_airport::text,
f.arrival_airport::text,
p.last_name,
p.first_name, 
bp.seat,
bp.boarding_time
from flight f
join booking_leg bl   on f.flight_id = bl.flight_id
join boarding_pass bp on bp.booking_leg_id = bl.booking_leg_id 
join passenger p      on p.passenger_id = bp.passenger_id 
where bp.pass_id  = p_pass_id;
END;
$body$
LANGUAGE plpgsql;

SELECT *
FROM  boarding_passes_pass(13650)

EXPLAIN ANALYZE 
SELECT *
FROM boarding_passes_flight(13650); 

/*EXPLAIN ANALYZE SELECT boarding_passes_flight(13650);
Функция может выполняться многократно (в зависимости от оптимизатора)
Дополнительные затьраты на упаковку/распаковку составного типа
Невозможно использовать индексы для фильтрации
Дополнительные overhead для SELECT function()
Память:
Хранение составных типов как единых объектов
Дополнительные преобразования при сериализации
Обработка:
Упаковка результатов в составной тип
Распаковка при необходимости доступа к отдельным полям
SELECT * FROM function() в 2-5 раз быстрее и предоставляет 
больше возможностей для работы с данными. 
SELECT function() следует использовать только 
когда действительно нужен составной тип как единый объект.
*/
EXPLAIN ANALYZE 
SELECT boarding_passes_flight(13650); 


/*Как использовать динамический SQL в OLTP-системах*/

DROP TYPE IF EXISTS booking_leg_part;
CREATE TYPE booking_leg_part AS (
departure_airport char(3),
booking_id int,
is_returning boolean
)


CREATE OR REPLACE FUNCTION select_booking_leg_country (
p_country text,
p_updated timestamptz
)
RETURNS SETOF booking_leg_part
AS $body$
BEGIN 
	return query 

select 
f.departure_airport,
bl.booking_id,
bl.is_returning
from booking_leg bl
JOIN flight f ON bl.flight_id = f.flight_id 
WHERE f.departure_airport IN (SELECT airport_code
FROM airport WHERE iso_country = p_country
)
AND bl.booking_id IN (SELECT booking_id 
FROM booking WHERE update_ts > p_updated);

END; 
$body$
LANGUAGE plpgsql;


EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country_dynamic('US', '2020-07-01')

EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country('US', '2020-07-01')


EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country('US', '2020-08-15')

EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country('CZ', '2020-07-01')

EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country('CZ', '2020-08-15')


/*Функция выполняющая динамический SQL*/
CREATE OR REPLACE FUNCTION select_booking_leg_country_dynamic(
    p_country text,
    p_updated timestamptz
)
RETURNS SETOF booking_leg_part
AS $body$
BEGIN 
    RETURN QUERY EXECUTE '
        SELECT 
            f.departure_airport,
            bl.booking_id,
            bl.is_returning
        FROM booking_leg bl
        JOIN flight f ON bl.flight_id = f.flight_id 
        WHERE f.departure_airport IN (
            SELECT airport_code
            FROM airport 
            WHERE iso_country = $1
        )
        AND bl.booking_id IN (
            SELECT booking_id 
            FROM booking 
            WHERE update_ts > $2
        )'
    USING p_country, p_updated;
END; 
$body$
LANGUAGE plpgsql;


EXPLAIN ANALYZE 
SELECT *
FROM select_booking_leg_country_dynamic('US', '2020-08-15')

/*SQL создается непосредственно передвыполнением, оптимизатор не
 * исполльзует кэшированный план, вместо этого строит
 * план для каждого выполлнения, время окупается за счет
 * боее подходящего плана выполнения
 * Динамический SQL быстрее потому что:
✅ Custom plans для каждого вызова
✅ Учет селективности конкретных параметров
✅ Актуальная статистика при каждом выполнении
✅ Оптимальное использование индексов
*/


/*Как использовать динамический SQL в системах OLAP
* наибольших результатов можно достигнуть при большом 
* результирующем множестве
*/

CREATE OR REPLACE FUNCTION age_category (p_age text)
RETURNS TEXT 
AS $body$
BEGIN 
	RETURN(
case 
when p_age <=2 then 'Infant'
when p_age <=12 then 'Child'
when p_age <=65 then 'Adult'
else 'Senior' end);
END;
$body$
LANGUAGE plpgsql; 

EXPLAIN ANALYZE
SELECT passenger_id, age_category(age), age
FROM passenger

CREATE TYPE passenger_age_cat_record AS (
passenger_id int,
age_category text
);

CREATE OR REPLACE FUNCTION passenger_age_category_select(p_limit int)
RETURNS SETOF passenger_age_cat_record
AS $body$
BEGIN 
    RETURN QUERY EXECUTE format(
        'SELECT 
            passenger_id,
            age_category(age) AS age_category
         FROM passenger
         LIMIT %s',
        p_limit
    );
END; 
$body$
LANGUAGE plpgsql;


SELECT *
FROM passenger_age_category_select(50000000);


SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration, -- Длительность выполнения
    query, -- Текст текущего запроса
    state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
  AND state = 'active';


SELECT *
FROM pg_stats

-- Текущий search_path
SHOW search_path;
-- По умолчанию: "$user", public


SELECT 
    round(blks_hit * 100.0 / (blks_hit + blks_read), 2) AS cache_hit_ratio
FROM pg_stat_database 
WHERE datname = current_database();


SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration, -- Длительность выполнения
    query, -- Текст текущего запроса
    state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 seconds'
  AND state = 'active';


SELECT 
    e.extname as extension_name,
    n.nspname as schema_name,
    r.rolname as owner_name
FROM pg_extension e
JOIN pg_namespace n ON e.extnamespace = n.oid
JOIN pg_roles r ON e.extowner = r.oid
WHERE e.extname = 'pg_stat_statements';



SELECT 
first_name,
last_name,
pn.passenger_id,
pn.custom_field_value AS passport_num,
pe.custom_field_value AS passport_exp_date,
pc.custom_field_value AS passport_coutry
FROM passenger p
JOIN custom_field pn ON pn.passenger_id = p.passenger_id 
                     AND pn.custom_field_name = 'passport_num'
JOIN custom_field pe ON pe.passenger_id = p.passenger_id
                     AND pe.custom_field_name = 'passport_exp_date'
JOIN custom_field pc ON pc.passenger_id = p.passenger_id
                     AND pc.custom_field_name = 'passport_country'
                     
                     
SELECT 
p.first_name,
p.last_name,
p.passenger_id,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_num' 
THEN cf.custom_field_value ELSE NULL END),'') AS passport_num,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_exp_date'
THEN cf.custom_field_value ELSE NULL END),'') AS passport_exp_date,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_country'
THEN cf.custom_field_value ELSE NULL END),'') AS passport_country
FROM passenger p
JOIN custom_field cf ON p.passenger_id = cf.passenger_id 
GROUP BY 
p.passenger_id,
p.first_name,
p.last_name


SELECT 
p.first_name,
p.last_name,
p.passenger_id,
cf.passport_num,
cf.passport_exp_date,
cf.passport_country
FROM passenger p
JOIN (
SELECT 
cf.passenger_id,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_num' 
THEN cf.custom_field_value ELSE NULL END),'') AS passport_num,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_exp_date'
THEN cf.custom_field_value ELSE NULL END),'') AS passport_exp_date,
coalesce(max(CASE WHEN cf.custom_field_name = 'passport_country'
THEN cf.custom_field_value ELSE NULL END),'') AS passport_country
FROM custom_field cf
GROUP BY cf.passenger_id
) cf ON p.passenger_id = cf.passenger_id 



CREATE OR REPLACE VIEW  flight_stats AS
SELECT 
bl.flight_id,
departure_airport,
(avg(price))::numeric(7,2) AS avg_price,
count(DISTINCT passenger_id) AS num_passengers
FROM booking b
JOIN booking_leg bl using(booking_id)
JOIN flight f USING(flight_id)
JOIN passenger p using(booking_id)
GROUP BY 1,2

SELECT *
FROM flight_stats
WHERE flight_id = 222183

             

