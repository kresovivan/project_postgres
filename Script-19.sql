ALTER TABLE words ADD COLUMN timestamp DATETIME;

-- 2. Если нужно обновить существующие записи, чтобы у них тоже было время создания:
UPDATE words SET timestamp = CURRENT_TIMESTAMP WHERE timestamp IS NULL;

UPDATE words SET timestamp = datetime('now');

CREATE TRIGGER IF NOT EXISTS set_words_timestamp 
AFTER INSERT ON words
BEGIN
    UPDATE words SET timestamp = datetime('now') WHERE id = NEW.id;
END;