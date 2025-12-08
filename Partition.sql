CREATE TABLE security_logs (
    log_id BIGSERIAL,
    user_id INT,
    action_date TIMESTAMPTZ,
    action_type VARCHAR(50),
    ip_address INET
) PARTITION BY RANGE (action_date);

-- Создаем партиции за 2024 год (по месяцам)
CREATE TABLE security_logs_2024_01 PARTITION OF security_logs FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE security_logs_2024_02 PARTITION OF security_logs FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE security_logs_2024_03 PARTITION OF security_logs FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');
CREATE TABLE security_logs_2024_04 PARTITION OF security_logs FOR VALUES FROM ('2024-04-01') TO ('2024-05-01');
CREATE TABLE security_logs_2024_05 PARTITION OF security_logs FOR VALUES FROM ('2024-05-01') TO ('2024-06-01');
CREATE TABLE security_logs_2024_06 PARTITION OF security_logs FOR VALUES FROM ('2024-06-01') TO ('2024-07-01');
CREATE TABLE security_logs_2024_07 PARTITION OF security_logs FOR VALUES FROM ('2024-07-01') TO ('2024-08-01');
CREATE TABLE security_logs_2024_08 PARTITION OF security_logs FOR VALUES FROM ('2024-08-01') TO ('2024-09-01');
CREATE TABLE security_logs_2024_09 PARTITION OF security_logs FOR VALUES FROM ('2024-09-01') TO ('2024-10-01');
CREATE TABLE security_logs_2024_10 PARTITION OF security_logs FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');
CREATE TABLE security_logs_2024_11 PARTITION OF security_logs FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');
CREATE TABLE security_logs_2024_12 PARTITION OF security_logs FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

-- Создаем партиции за 2025 год (по месяцам)
CREATE TABLE security_logs_2025_01 PARTITION OF security_logs FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE security_logs_2025_02 PARTITION OF security_logs FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE security_logs_2025_03 PARTITION OF security_logs FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE security_logs_2025_04 PARTITION OF security_logs FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE security_logs_2025_05 PARTITION OF security_logs FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE security_logs_2025_06 PARTITION OF security_logs FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE security_logs_2025_07 PARTITION OF security_logs FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE security_logs_2025_08 PARTITION OF security_logs FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE security_logs_2025_09 PARTITION OF security_logs FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE security_logs_2025_10 PARTITION OF security_logs FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE security_logs_2025_11 PARTITION OF security_logs FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE security_logs_2025_12 PARTITION OF security_logs FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');



-- Вставляем реалистичные данные логов безопасности за 2024-2025 годы
INSERT INTO security_logs (user_id, action_date, action_type, ip_address)
SELECT 
    -- user_id: от 1 до 1000 сотрудников
    (random() * 999)::int + 1 as user_id,
    
    -- action_date: равномерно распределяем за 2 года
    timestamp '2024-01-01 00:00:00' + 
    (random() * (interval '2 years')) as action_date,
    
    -- action_type: различные типы действий в системе
    (CASE (random() * 7)::int
        WHEN 0 THEN 'LOGIN_SUCCESS'
        WHEN 1 THEN 'LOGIN_FAILED'
        WHEN 2 THEN 'LOGOUT'
        WHEN 3 THEN 'PASSWORD_CHANGE'
        WHEN 4 THEN 'DATA_ACCESS'
        WHEN 5 THEN 'DATA_MODIFY'
        WHEN 6 THEN 'REPORT_GENERATE'
        ELSE 'SYSTEM_ACCESS'
    END) as action_type,
    
    -- ip_address: реалистичные IP адреса банковской сети
    (CASE (random() * 4)::int
        WHEN 0 THEN '192.168.1.' || ((random() * 254)::int + 1)::text
        WHEN 1 THEN '10.0.' || ((random() * 254)::int + 1)::text || '.' || ((random() * 254)::int + 1)::text
        WHEN 2 THEN '172.16.' || ((random() * 15)::int + 16)::text || '.' || ((random() * 254)::int + 1)::text
        ELSE (185 + (random() * 10)::int)::text || '.' || 
             (100 + (random() * 155)::int)::text || '.' || 
             ((random() * 254)::int + 1)::text || '.' || 
             ((random() * 254)::int + 1)::text
    END)::inet as ip_address

-- Генерируем 1 миллион записей за два года
FROM generate_series(1, 1000000);



-- Создаем индексы для каждой партиции 2024 года
CREATE INDEX idx_security_2024_01_date ON security_logs_2024_01 (action_date);
CREATE INDEX idx_security_2024_01_user ON security_logs_2024_01 (user_id);
CREATE INDEX idx_security_2024_01_action ON security_logs_2024_01 (action_type);

CREATE INDEX idx_security_2024_02_date ON security_logs_2024_02 (action_date);
CREATE INDEX idx_security_2024_02_user ON security_logs_2024_02 (user_id);

VACUUM (FULL, VERBOSE) security_logs;



SELECT 
    schemaname,
    relname as partition_name,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    pg_size_pretty(pg_relation_size(relid)) as size
FROM pg_stat_user_tables 
WHERE relname LIKE 'security_logs%'
ORDER BY pg_relation_size(relid) DESC;
