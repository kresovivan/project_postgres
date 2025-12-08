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