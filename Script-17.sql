-- Скрипт для безопасного пересоздания
DO $$
BEGIN
    -- Завершаем все соединения с базой demo
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'demo') THEN
        PERFORM pg_terminate_backend(pid) 
        FROM pg_stat_activity 
        WHERE datname = 'demo' AND pid <> pg_backend_pid();
        
        DROP DATABASE demo;
    END IF;
    
    CREATE DATABASE demo;
END $$;