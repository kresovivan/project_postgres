SELECT *
FROM words;


SELECT term, COUNT(*) as duplicate_count
FROM words 
GROUP BY term
HAVING COUNT(*) > 1;


-- Удаляем дубликаты только по полю term
DELETE FROM words 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM words 
    GROUP BY term
);


-- Затем удаляем дубликаты, оставляя первую запись (с наименьшим id)
DELETE FROM words 
WHERE id NOT IN (
    SELECT MIN(id) 
    FROM words 
    GROUP BY term, definition, translation, category, level
);

PRAGMA encoding;