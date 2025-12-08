DO $$
DECLARE
    seq_time numeric;
    rand_time numeric;
    ratio numeric;
    start_t timestamptz;
    end_t timestamptz;
    i integer;
BEGIN
    -- Время ОДНОГО Seq Scan
    start_t := clock_timestamp();
    PERFORM count(*) FROM benchmark_test;
    end_t := clock_timestamp();
    seq_time := extract(epoch FROM (end_t - start_t)) * 1000;
    
    -- Время 10 Index Scan (усредненное)
    rand_time := 0;
    FOR i IN 1..10 LOOP
        start_t := clock_timestamp();
        PERFORM * FROM benchmark_test WHERE id = (random() * 1000000)::int;
        end_t := clock_timestamp();
        rand_time := rand_time + extract(epoch FROM (end_t - start_t)) * 1000;
    END LOOP;
    rand_time := rand_time / 10;  -- среднее время одного Index Scan
    
    ratio := round(rand_time / seq_time, 2);
    
    RAISE NOTICE 'Seq Scan: % ms', round(seq_time, 3);
    RAISE NOTICE 'Avg Index Scan: % ms', round(rand_time, 3);
    RAISE NOTICE 'Соотношение случайное/последовательное: %', ratio;
    RAISE NOTICE 'Рекомендуемый random_page_cost: %', greatest(1.0, least(ratio, 4.0));
END $$;






BEGIN;
EXPLAIN (ANALYZE, COSTS OFF)
UPDATE aircrafts
SET range = range + 100
WHERE model ~ '^Air';
