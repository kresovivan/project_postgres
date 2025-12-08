--- Задание номер 1.
CREATE DATABASE novosibirsk_metro_2025
WITH 
TEMPLATE = template0
ENCODING = 'UTF8'
LC_COLLATE = 'ru_RU.UTF-8'
LC_CTYPE = 'ru_RU.UTF-8';

ALTER DATABASE novosibirsk_metro_2025 OWNER TO postgres;
GRANT CONNECT ON
DATABASE novosibirsk_metro_2025 TO postgres;

GRANT ALL PRIVILEGES ON
DATABASE novosibirsk_metro_2025 TO postgres;
-- 1. Таблица линий метро
CREATE TABLE metro_lines (
    line_id SERIAL PRIMARY KEY,
    line_name VARCHAR(50) NOT NULL,
    line_color VARCHAR(20) NOT NULL,
    line_number INTEGER NOT NULL UNIQUE,
    opening_year INTEGER,
    description TEXT,
    CONSTRAINT chk_line_color CHECK (line_color IN ('red', 'green'))
);
-- Комментарии для metro_lines
COMMENT ON TABLE metro_lines IS 'Таблица линий метрополитена Новосибирска';
COMMENT ON COLUMN metro_lines.line_id IS 'Уникальный идентификатор линии';
COMMENT ON COLUMN metro_lines.line_name IS 'Название линии метро';
COMMENT ON COLUMN metro_lines.line_color IS 'Цвет линии для отображения на схемах';
COMMENT ON COLUMN metro_lines.line_number IS 'Порядковый номер линии (1 - первая, 2 - вторая)';
COMMENT ON COLUMN metro_lines.opening_year IS 'Год открытия линии';
COMMENT ON COLUMN metro_lines.description IS 'Описание линии';
-- Вставка данных в таблицу metro_lines линий метро
INSERT
	INTO
	metro_lines (line_name,
	line_color,
	line_number,
	opening_year,
	description)
VALUES 
('Ленинская линия',
'red',
1,
1986,
'Первая линия Новосибирского метрополитена. Проходит с северо-запада на юго-восток города.'),
('Дзержинская линия',
'green',
2,
1987,
'Вторая линия Новосибирского метрополитена. Проходит с юго-запада на северо-восток.');
-- Вставка в таблицу станций stations Новосибирского метрополитена
-- Таблица stations - станции метрополитена
-- Хранит информацию о всех станциях метро с их характеристиками
-- Создание таблицы stations
CREATE TABLE stations (
    station_id INT PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    line_id INT NOT NULL,
    order_on_line INT NOT NULL,
    has_transfer BOOLEAN DEFAULT FALSE,
    transfer_station_name VARCHAR(100),
    opening_year INT,
    DEPTH FLOAT,
    platform_type VARCHAR(50),
    street_location TEXT,
    coordinates VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    transfer_line_id INT,
    transfer_station_id INT,
-- Ограничения для целостности данных
    CONSTRAINT fk_line_id FOREIGN KEY (line_id) REFERENCES metro_lines(line_id),
    CONSTRAINT fk_transfer_line FOREIGN KEY (transfer_line_id) REFERENCES metro_lines(line_id),
    CONSTRAINT fk_transfer_station FOREIGN KEY (transfer_station_id) REFERENCES stations(station_id)
);

-- Комментарии к таблице и её колонкам
COMMENT ON TABLE stations IS 'Таблица станций метрополитена. Хранит информацию о всех станциях с их характеристиками и географическими координатами.';
COMMENT ON COLUMN stations.station_id IS 'Уникальный идентификатор станции (первичный ключ, автоинкремент).';
COMMENT ON COLUMN stations.station_name IS 'Название станции метро. Например: "Красный проспект", "Площадь Ленина".';
COMMENT ON COLUMN stations.line_id IS 'Идентификатор линии метро, к которой принадлежит станция (внешний ключ к metro_lines).';
COMMENT ON COLUMN stations.order_on_line IS 'Порядковый номер станции на линии. От 1 (начальная) до N (конечная).';
COMMENT ON COLUMN stations.has_transfer IS 'Флаг пересадочной станции. TRUE - есть пересадка, FALSE - нет пересадки.';
COMMENT ON COLUMN stations.transfer_station_name IS 'Название станции для пересадки. Указывается для пересадочных станций.';
COMMENT ON COLUMN stations.opening_year IS 'Год открытия станции. Например: 1986, 1992, 2000.';
COMMENT ON COLUMN stations.depth IS 'Глубина залегания станции в метрах. Например: 10.5, 15.0, 18.0.';
COMMENT ON COLUMN stations.platform_type IS 'Тип платформы: island (островная), side (береговая), combined (комбинированная).';
COMMENT ON COLUMN stations.street_location IS 'Местоположение станции (адрес, улица, площадь).';
COMMENT ON COLUMN stations.coordinates IS 'Географические координаты в формате POINT(долгота, широта). Например: POINT(82.912569, 55.059291).';
COMMENT ON COLUMN stations.latitude IS 'Широта в градусах для географических расчётов. Диапазон: -90 до +90.';
COMMENT ON COLUMN stations.longitude IS 'Долгота в градусах для географических расчётов. Диапазон: -180 до +180.';
-- Вставка данных в таблицу stations
INSERT
	INTO
	stations (station_id,
	station_name,
	line_id,
	order_on_line,
	has_transfer,
	transfer_station_name,
	opening_year,
	DEPTH,
	platform_type,
	street_location,
	coordinates,
	latitude,
	longitude,
	transfer_line_id,
	transfer_station_id)
VALUES
(1,
'Заельцовская',
1,
1,
FALSE,
NULL,
1992,
18.0,
'island',
'улица Дуси Ковальчук',
'(82.912569,55.059291)',
55.05929100,
82.91256900,
NULL,
NULL),
(2,
'Гагаринская',
1,
2,
FALSE,
NULL,
1992,
12.0,
'island',
'проспект Димитрова',
'(82.91477,55.051071)',
55.05107100,
82.91477000,
NULL,
NULL),
(3,
'Красный проспект',
1,
3,
TRUE,
'Сибирская',
1986,
10.0,
'island',
'Красный проспект, площадь Ленина',
'(82.917447,55.040998)',
55.04099800,
82.91744700,
2,
10),
(4,
'Площадь Ленина',
1,
4,
FALSE,
NULL,
1986,
15.0,
'island',
'площадь Ленина',
'(82.92069,55.029941)',
55.02994100,
82.92069000,
NULL,
NULL),
(5,
'Октябрьская',
1,
5,
FALSE,
NULL,
1986,
10.0,
'island',
'улица Ленина',
'(82.939007,55.018789)',
55.01878900,
82.93900700,
NULL,
NULL),
(6,
'Речной вокзал',
1,
6,
FALSE,
NULL,
1986,
8.0,
'island',
'улица Большевистская',
'(82.93827,55.008738)',
55.00873800,
82.93827000,
NULL,
NULL),
(7,
'Студенческая',
1,
7,
FALSE,
NULL,
1986,
11.0,
'island',
'улица Немировича-Данченко',
'(82.906631,54.989089)',
54.98908900,
82.90663100,
NULL,
NULL),
(8,
'Площадь Маркса',
1,
8,
FALSE,
NULL,
1991,
16.0,
'island',
'площадь Маркса',
'(82.89313,54.982931)',
54.98293100,
82.89313000,
NULL,
NULL),
(9,
'Площадь Гарина-Михайловского',
2,
1,
FALSE,
NULL,
1987,
9.0,
'island',
'площадь Гарина-Михайловского',
'(82.897783,55.035947)',
55.03594700,
82.89778300,
NULL,
NULL),
(10,
'Сибирская',
2,
2,
TRUE,
'Красный проспект',
1987,
12.0,
'island',
'улица Ленина',
'(82.919172,55.042163)',
55.04216300,
82.91917200,
1,
3),
(11,
'Маршала Покрышкина',
2,
3,
FALSE,
NULL,
2000,
14.0,
'island',
'улица Маршала Покрышкина',
'(82.935566,55.043634)',
55.04363400,
82.93556600,
NULL,
NULL),
(12,
'Березовая роща',
2,
4,
FALSE,
NULL,
2000,
17.0,
'island',
'улица Богдана Хмельницкого',
'(82.952913,55.043242)',
55.04324200,
82.95291300,
NULL,
NULL),
(13,
'Золотая Нива',
2,
5,
FALSE,
NULL,
2011,
15.0,
'island',
'улица Тюленина',
'(82.976044,55.037928)',
55.03792800,
82.97604400,
NULL,
NULL);


----Задание номер 2
/*Напишите функцию - которая на вход получает 
 *название линий метрополитена,
 *а на выход возвращается станция пересечения.*/
--DROP FUNCTION find_intersection_stations
--DROP TYPE IF EXISTS intersection_station_type

CREATE TYPE intersection_station_type AS (
    line1_station_name VARCHAR(100),
    line2_station_name VARCHAR(100),
    line1_name VARCHAR(50),
    line2_name VARCHAR(50)
);

CREATE OR REPLACE
FUNCTION find_intersection_stations(
    p_line1_name VARCHAR(50),
    p_line2_name VARCHAR(50)
)
RETURNS SETOF intersection_station_type 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
	s1.station_name AS line1_station_name,
	s2.station_name AS line2_station_name,
	ml1.line_name AS line_name1,
	ml2.line_name AS line_name2
FROM
	stations s1
JOIN metro_lines ml1 ON
	s1.line_id = ml1.line_id
JOIN stations s2 ON
	s1.transfer_station_id = s2.station_id
JOIN metro_lines ml2 ON
	s2.line_id = ml2.line_id
WHERE
	ml1.line_name = p_line1_name
	AND ml2.line_name = p_line2_name
	AND s1.has_transfer = TRUE
UNION
    
    SELECT
	s2.station_name AS line1_station_name,
	s1.station_name AS line2_station_name,
	ml2.line_name AS line_name1,
	ml1.line_name AS line_name2
FROM
	stations s1
JOIN metro_lines ml1 ON
	s1.line_id = ml1.line_id
JOIN stations s2 ON
	s1.transfer_station_id = s2.station_id
JOIN metro_lines ml2 ON
	s2.line_id = ml2.line_id
WHERE
	ml2.line_name = p_line1_name
	AND ml1.line_name = p_line2_name
	AND s1.has_transfer = TRUE
ORDER BY
	line1_station_name;
END;

$$;
-- Использование:
SELECT
	t.station_name
FROM
	find_intersection_stations('Ленинская', 'Дзержинская') AS t(station_name);


---Задание 3.
/*Напишите запрос, который покажет все возможные маршруты из станции А на станцию Б,
 * при условии совершения не более двух пересадок.
*/

WITH RECURSIVE metro_routes AS (
-- Базовый случай: начальная станция
SELECT
	s.station_id,
	s.station_name,
	s.line_id,
	s.order_on_line,
	s.has_transfer,
	s.transfer_station_id,
	ARRAY[s.station_id]::INTEGER[] AS visited_stations,
	ARRAY[s.station_name]::VARCHAR[] AS route_path,
	ARRAY[s.line_id]::INTEGER[] AS lines_used,
	0 AS transfers_count,
	1 AS DEPTH,
	ARRAY[s.station_name]::VARCHAR[] AS detailed_route
FROM
	stations s
WHERE
	s.station_name = 'Заельцовская'
UNION ALL
-- Рекурсивный шаг: переход к следующей станции
SELECT
	next.station_id,
	next.station_name,
	next.line_id,
	next.order_on_line,
	next.has_transfer,
	next.transfer_station_id,
	mr.visited_stations || next.station_id,
	mr.route_path || next.station_name::VARCHAR,
	mr.lines_used || next.line_id,
	mr.transfers_count + CASE
		WHEN mr.line_id != next.line_id THEN 1
		ELSE 0
	END,
	mr.depth + 1,
	mr.detailed_route || 
            CASE
		WHEN mr.line_id != next.line_id THEN ' → ПЕРЕСАДКА → '
		ELSE ' → '
	END || next.station_name::VARCHAR
FROM
	metro_routes mr
CROSS JOIN LATERAL (
	SELECT
		s2.*
	FROM
		stations s1
	LEFT JOIN stations s2 ON
		(
		-- 1. Следующая станция на той же линии (вперед)
            (s1.line_id = s2.line_id
			AND s2.order_on_line = s1.order_on_line + 1)
		OR
		-- 2. Предыдущая станция на той же линии (назад)
            (s1.line_id = s2.line_id
			AND s2.order_on_line = s1.order_on_line - 1)
		OR
		-- 3. Пересадка на другую станцию
            (s1.transfer_station_id = s2.station_id
			AND s1.has_transfer = TRUE)
        )
	WHERE
		s1.station_id = mr.station_id
		AND s2.station_id IS NOT NULL
    ) next
WHERE
	mr.depth < 15 AND next.station_id != ALL(mr.visited_stations)
		          AND mr.transfers_count + CASE WHEN mr.line_id != next.line_id 
		                                          THEN 1
			                                    ELSE 0
		                                   END <= 2
)
SELECT
	transfers_count AS "Кол-во пересадок",
	DEPTH AS "Всего станций в маршруте",
	array_to_string(route_path, ' → ') AS "Маршрут",
	array_to_string(lines_used, ' → ') AS "Использованные линии"
FROM
	metro_routes
WHERE
	station_name = 'Золотая Нива'
	AND transfers_count <= 2
ORDER BY
	transfers_count,
	depth;


/*
*Физический смысл скрипта:
Скрипт реализует алгоритм поиска в глубину (DFS) по графу метрополитена, где:
Вершины графа = станции метро
Рёбра графа = возможные перемещения (по линии или пересадки)
Цель = найти ВСЕ пути от станции A к станции B

┌─────────────────────────────────────────────────────────────────────┐
│                        АЛГОРИТМ РАБОТЫ СКРИПТА                      │
└─────────────────────────────────────────────────────────────────────┘

1. НАЧАЛО (итерация 0):
   ┌─────────────────────┐
   │  СТАНЦИЯ: Заельцовская │
   │  Линия: 1, Порядок: 1  │
   └─────────────────────┘
   │
   ▼

2. РЕКУРСИВНЫЙ ПОИСК ВСЕХ ВОЗМОЖНЫХ ПУТЕЙ:
   
   Для каждой текущей станции ищем ВСЕ варианты движения:
   
   ┌─────────────────────────────────────────────────────┐
   │                ВАРИАНТЫ ПЕРЕХОДА:                    │
   │ 1. → Следующая станция на линии (order+1)           │
   │ 2. ← Предыдущая станция на линии (order-1)          │
   │ 3. ⇄ Пересадка на другую линию (transfer_station_id)│
   └─────────────────────────────────────────────────────┘
   
   Пример: Из Заельцовской (линия 1, порядок 1):
           → Гагаринская (линия 1, порядок 2) ✅
           ← (нет, это первая станция) ❌
           ⇄ (нет пересадки) ❌

3. ПРИМЕР РАЗВИТИЯ МАРШРУТА:
   
   Итерация 0: [Заельцовская]
            ↓
   Итерация 1: [Заельцовская → Гагаринская]
            ↓
   Итерация 2: [Заельцовская → Гагаринская → Красный проспект]
            ↓
   Итерация 3: [Заельцовская → Гагаринская → Красный проспект → ПЕРЕСАДКА → Сибирская]
            ↓
   Итерация 4: [Заельцовская → ... → Сибирская → Маршала Покрышкина]

4. ОГРАНИЧЕНИЯ (чтобы не уйти в бесконечный цикл):
   • Максимальная глубина: 15 станций
   • Не более 2 пересадок
   • Не посещать одну станцию дважды
   
 */  
   
   /*
 ======================================================================
 АЛГОРИТМ ПОИСКА ВСЕХ МАРШРУТОВ В МЕТРОПОЛИТЕНЕ
 ======================================================================
 Физический смысл: Поиск всех возможных путей от станции A к станции B
 с ограничением не более 2 пересадок методом рекурсивного обхода графа.
 
 Граф метро представлен как:
   - Узлы: станции
   - Рёбра: 1) движение по линии (вперёд/назад)
             2) пересадки между станциями
 ======================================================================
*/

WITH RECURSIVE metro_routes AS (
    /* ===============================================================
       БАЗОВЫЙ СЛУЧАЙ (Anchor Member) - ИНИЦИАЛИЗАЦИЯ ПУТИ
       ===============================================================
       Начинаем с начальной станции "Заельцовская".
       Создаём начальный маршрут с этой одной станцией.
    */
    SELECT 
        s.station_id,                   -- ID текущей станции
        s.station_name,                 -- Название текущей станции
        s.line_id,                      -- Номер линии, на которой находится станция
        s.order_on_line,                -- Порядковый номер на линии
        s.has_transfer,                 -- Есть ли пересадка с этой станции
        s.transfer_station_id,          -- ID станции пересадки (если есть)
        
        -- Массив посещённых станций (ID) - для отслеживания циклических путей
        ARRAY[s.station_id]::INTEGER[] AS visited_stations,
        
        -- Массив названий станций в маршруте - формируем читаемый путь
        ARRAY[s.station_name]::VARCHAR[] AS route_path,
        
        -- Массив используемых линий - отслеживаем смену линий
        ARRAY[s.line_id]::INTEGER[] AS lines_used,
        
        -- Счётчик пересадок: начальное значение 0
        0 AS transfers_count,
        
        -- Глубина рекурсии (количество станций в текущем маршруте)
        1 AS depth,
        
        -- Детализированный маршрут с указанием пересадок
        ARRAY[s.station_name]::VARCHAR[] AS detailed_route
        
    FROM stations s
    WHERE s.station_name = 'Заельцовская'  -- Начальная точка маршрута
    
    UNION ALL
    
    /* ===============================================================
       РЕКУРСИВНЫЙ ШАГ (Recursive Member) - РАСШИРЕНИЕ МАРШРУТА
       ===============================================================
       Для каждого найденного частичного маршрута ищем ВСЕ возможные
       продолжения, соблюдая ограничения.
    */
    SELECT 
        next.station_id,                -- ID следующей станции
        next.station_name,              -- Название следующей станции
        next.line_id,                   -- Линия следующей станции
        next.order_on_line,             -- Порядок на линии
        next.has_transfer,              -- Есть ли пересадка дальше
        next.transfer_station_id,       -- ID следующей пересадки
        
        -- Добавляем новую станцию в список посещённых
        mr.visited_stations || next.station_id,
        
        -- Добавляем название новой станции в путь
        mr.route_path || next.station_name::VARCHAR,
        
        -- Добавляем линию новой станции
        mr.lines_used || next.line_id,
        
        -- Увеличиваем счётчик пересадок, если сменили линию
        mr.transfers_count + 
            CASE 
                WHEN mr.line_id != next.line_id THEN 1  -- Смена линии = пересадка
                ELSE 0                                   -- Движение по той же линии
            END,
            
        -- Увеличиваем глубину (количество станций в маршруте)
        mr.depth + 1,
        
        -- Формируем детализированное описание с указанием пересадок
        mr.detailed_route || 
            CASE 
                WHEN mr.line_id != next.line_id THEN ' → ПЕРЕСАДКА → '
                ELSE ' → '
            END || next.station_name::VARCHAR
            
    FROM metro_routes mr  -- Берём текущие частичные маршруты
    
    /* ===============================================================
       CROSS JOIN LATERAL: ДЛЯ КАЖДОЙ ТЕКУЩЕЙ СТАНЦИИ НАХОДИМ ВСЕ
       ВОЗМОЖНЫЕ СЛЕДУЮЩИЕ СТАНЦИИ
       ===============================================================
       LATERAL позволяет использовать значение mr.station_id в подзапросе.
    */
    CROSS JOIN LATERAL (
        SELECT s2.*  -- Все данные о следующей возможной станции
        
        FROM stations s1  -- Текущая станция (та же что и mr)
        
        -- Ищем ВСЕ станции, на которые можно попасть из s1:
        LEFT JOIN stations s2 ON (
            -- 1. СЛЕДУЮЩАЯ СТАНЦИЯ НА ТОЙ ЖЕ ЛИНИИ (движение вперёд)
            (s1.line_id = s2.line_id 
             AND s2.order_on_line = s1.order_on_line + 1)
            
            OR
            
            -- 2. ПРЕДЫДУЩАЯ СТАНЦИЯ НА ТОЙ ЖЕ ЛИНИИ (движение назад)
            (s1.line_id = s2.line_id 
             AND s2.order_on_line = s1.order_on_line - 1)
            
            OR
            
            -- 3. ПЕРЕСАДКА НА ДРУГУЮ СТАНЦИЮ (через переход)
            (s1.transfer_station_id = s2.station_id 
             AND s1.has_transfer = TRUE)
        )
        
        -- Фильтруем: берём только текущую станцию из маршрута
        WHERE s1.station_id = mr.station_id
          -- Отбрасываем случаи, когда следующей станции нет
          AND s2.station_id IS NOT NULL
          
    ) next  -- Название для результата подзапроса
    
    /* ===============================================================
       УСЛОВИЯ ПРОДОЛЖЕНИЯ РЕКУРСИИ (Termination Conditions)
       ===============================================================
       Останавливаем рекурсию, когда:
    */
    WHERE 
        -- 1. Не превышена максимальная длина маршрута (15 станций)
        mr.depth < 15 
        
        -- 2. Не создаём циклы: следующая станция не должна быть уже в пути
        AND next.station_id != ALL(mr.visited_stations)
        
        -- 3. Не превышено максимальное количество пересадок (2)
        AND mr.transfers_count + 
            CASE WHEN mr.line_id != next.line_id THEN 1 ELSE 0 END <= 2
)

/* ======================================================================
   ФИНАЛЬНЫЙ ВЫБОР РЕЗУЛЬТАТОВ
   ======================================================================
   Из всех найденных маршрутов выбираем только те, которые:
   1. Заканчиваются на целевой станции "Золотая Нива"
   2. Имеют не более 2 пересадок (дополнительная проверка)
*/
SELECT 
    transfers_count AS "Кол-во пересадок",
    depth AS "Всего станций в маршруте",
    
    -- Преобразуем массив названий в читаемую строку
    array_to_string(route_path, ' → ') AS "Маршрут",
    
    -- Показываем последовательность используемых линий
    array_to_string(lines_used, ' → ') AS "Использованные линии"
    
FROM metro_routes
WHERE 
    -- Фильтруем по конечной станции
    station_name = 'Золотая Нива'
    
    -- Дублируем условие по пересадкам (для надёжности)
    AND transfers_count <= 2
    
-- Сортируем: сначала маршруты с меньшим числом пересадок,
-- затем с меньшим числом станций
ORDER BY 
    transfers_count,  -- Приоритет: минимальное количество пересадок
    depth;           -- Второй приоритет: минимальная длина маршрута
   
   
 