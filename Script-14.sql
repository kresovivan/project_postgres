SELECT 
    a.pid,
    a.usename,
    a.application_name,
    a.query,
    a.state,
    a.wait_event_type,
    a.wait_event,
    now() - a.query_start as duration,
    -- Определяем тип операции и используем соответствующее представление
    CASE 
        WHEN a.query ILIKE '%CREATE INDEX%' OR a.query ILIKE '%REINDEX%' THEN 'CREATE INDEX'
        WHEN a.query ILIKE '%VACUUM%' THEN 'VACUUM'
        WHEN a.query ILIKE '%CLUSTER%' THEN 'CLUSTER'
        WHEN a.query ILIKE '%ANALYZE%' THEN 'ANALYZE'
        ELSE 'OTHER'
    END as operation_type
FROM pg_stat_activity a
WHERE a.state = 'active'
AND a.query NOT LIKE '%pg_stat_%'
ORDER BY duration DESC;