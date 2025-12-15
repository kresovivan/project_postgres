/**
 * -- Обычный JOIN (всё сразу):
FROM A JOIN B ON A.id = B.a_id

-- LATERAL JOIN (строка за строкой):
FROM A JOIN LATERAL (SELECT ... FROM B WHERE B.a_id = A.id) b ON true

         ┌─────────────────────────────────────────┐
         │      Основной запрос (FROM таблица)     │
         │                                         │
         │  Строка 1: id=1, name='Анна'            │
         │  Строка 2: id=2, name='Борис'           │
         │  Строка 3: id=3, name='Виктор'          │
         └─┬──────┬──────┬──────┬──────┬──────┬────┘
           │      │      │      │      │      │
           ▼      ▼      ▼      ▼      ▼      ▼
┌──────────────┐                         (повторяется
│  LATERAL     │                          для каждой
│  подзапрос   │                          строки!)
│              │
│  Видит поля  │ ←───────────────────────┐
│  текущей     │                         │
│  строки!     │                         │
│  (id=1)      │                         │
└──────────────┘                         │
                                         │
               Обрабатывается как цикл:  │
               for row in main_table:    │
                   lateral_query(row)    │
                                         │
┌─────────────────────────────────────────────┐
│        Результат объединяется:              │
│  [Анна, 300] [Борис, 150] [Виктор, NULL]    │
└─────────────────────────────────────────────┘
LATERAL часто используется с:

generate_series() для временных рядов
jsonb_array_elements() для разворачивания JSON
LIMIT для получения N записей на группу
Функциями, возвращающими таблицы (например, unnest())
*/

CREATE TABLE projects
(
    id         int,
    name       text,
    start_date date,
    end_date   date
);

INSERT INTO projects
VALUES (1, 'Проект А', '2024-01-01', '2024-01-10'),
       (2, 'Проект Б', '2024-02-01', '2024-02-05');
/*Календарь*/
SELECT p.name,
       d.day_date
FROM projects p
         CROSS JOIN LATERAL (
    SELECT generate_series(
                   p.start_date, -- видим p.start_date!
                   p.end_date, -- видим p.end_date!
                   INTERVAL '1 day')::date AS day_date) d;

/*
 *
 *
 *
1. "Какая цель этого отчета?" (мониторинг, отчетность, принятие решений)
2. "Как часто нужны данные?" (ежедневно, еженедельно, в реальном времени)
3. "Кто будет использовать?" (топ-менеджмент, аналитики, регуляторы)
4. "Какие данные уже есть?" (структура БД, доступные таблицы)
5. "Есть ли ограничения по производительности?" (время выполнения запроса)

✅ 1. Цель и бизнес-задача
✅ 2. Пользователи и их потребности
✅ 3. Периодичность и сроки
✅ 4. Источники данных
✅ 5. Метрики и KPI
✅ 6. Фильтры и детализация
✅ 7. Формат и доставка
✅ 8. Безопасность и доступ
✅ 9. Валидация и качество
✅ 10. Приоритеты и этапы
*/


/*Моргунов Евгений
 Общие табличные выражения
 Компания хочет определить пассажиропоток (количество
 пассажиров в единицу времени), проходящий через все аэропорты,
 в которые авиакомпания совершает полеты, от пассажиропотока
 зависит необходимая численность персонала и размеры платежей за
 использование наземных служб.
 Пассажиропоток идет в двух направлениях - вылет пассажиров и их
 прибытие, - поэтому для каждого аэропорта нам нужно получить общее
 количество как вылетевших пассажиров, так и прибывших.
 Для нас не имеет значения, каким рейсом вылетает пассажир, а важно лишь то,
 откуда и куда он летит.
 Установить это можно, соединив таблицы flights и boarding_passes по столбцу
 flight_id.
 Первая таблица содержит сведения об аэрпортах вылета и прибытия для каждого
 пассажира.
 Если теперь сгрупиировать полученные строки по коду аэропорта отправления или
 прибытия и подсчитать их, то мы решим поставленную задачу.

 **/

/*Запрос выполняется 300 миллисекунд*/
EXPLAIN ANALYZE
SELECT td.departure_airport                  AS "Код а/п",
       a.airport_name                        AS "Аэропорт",
       td.dep_pass_count                     AS "Вылетели",
       ta.arr_pass_count                     AS "Прибыли",
       td.dep_pass_count + ta.arr_pass_count AS "Всего"
FROM (SELECT f.departure_airport,
             count(*) AS dep_pass_count
      FROM boarding_passes AS bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.departure_airport) AS td --total_departed_pass_counts
         JOIN
     (SELECT f.arrival_airport,
             count(*) AS arr_pass_count
      FROM boarding_passes AS bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.arrival_airport) AS ta --total_arrived_pass_counts
     ON td.departure_airport = ta.arrival_airport
         JOIN airports AS a ON a.airport_code = td.departure_airport
ORDER BY "Всего" DESC;

/*Для уменьшения времени выполнения запроса можно заранее
 *сгруппировать строки таблицы "Посадочные талоны" по идентификаторам
 *рейсов flight_id во вложенном подзапросе. Для каждого рейcа эта группировка будет
 *содержать ровно одну строку с количеством пассажиров. После этого каждая строка
 *таблицы "Рейсы" flights, отобранная в предложении where, будет соединятся только
 *с одной строкой полученной группировки. Конечно, в подзапросах первого уровня
 *мы должны будем заменить функцию count на sum, чтобы просуммировать количество
 *пассажиров отдельных рейсов и получить итоговую численность вылетевших и
 *прибывших
 *Ускорение достигнуто, но за счет усложнения запроса
 **/

/*180 миллисекунд*/
EXPLAIN ANALYZE
SELECT td.departure_airport                  AS "Код а/п",
       a.airport_name                        AS "Аэропорт",
       td.dep_pass_count                     AS "Вылетели",
       td.dep_pass_count + ta.arr_pass_count AS "Всего"
FROM (SELECT f.departure_airport,
             sum(pass_count) AS dep_pass_count
      FROM (SELECT flight_id, count(*) AS pass_count
            FROM boarding_passes
            GROUP BY flight_id) AS bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.departure_airport) AS td --total_departed_pass_counts
         JOIN
     (SELECT f.arrival_airport,
             sum(pass_count) AS arr_pass_count
      FROM (SELECT flight_id, count(*) AS pass_count
            FROM boarding_passes
            GROUP BY flight_id) AS bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.arrival_airport) AS ta --total_arrived_pass_counts
     ON td.departure_airport = ta.arrival_airport
         JOIN airports AS a ON a.airport_code = td.departure_airport
ORDER BY "Всего" DESC;

/*Можно упростить данный запрос не потеряв в скорости
 *Вложенный подзапрос, агрегирующий таблицу посадочные талоны,
 *выполняется дважды воспользуемся CTE*/


/*Время выполнения 95 миллисекнд
 * Исходя из плана запроса видно что таблица bp используется дважды
 * узлы CTE Scan on bp и поэтому по умолчанию матерализуется
 * Это означает, что результат первого и единственного выполнения подзапроса
 * bp сохраняется, а при повторном обращении к таблице bp берутся уже
 * готовые материализованные данные
 * Если же результат вычисления общего табличного выражения используется
 * в запросе только один раз, то по умолчанию материализации не происходит
 * В таком случае в плане не будет CTE Scan и подзапрос встраивается непо
 * средственно в запрос и оптимизируется вместе с ним!!!
 * В ряде случаев управление материализацией MATERIALIZED и NOT
 * MATERIALIZED позволяет ускорить выполнение запросов (с.82)*/
EXPLAIN
WITH bp AS (SELECT flight_id, count(*) AS pass_count
            FROM boarding_passes
            GROUP BY flight_id) ---общее табличное выражение

SELECT td.departure_airport                  AS "Код а/п",
       a.airport_name                        AS "Аэропорт",
       td.dep_pass_count                     AS "Вылетели",
       ta.arr_pass_count                     AS "Прибыли",
       td.dep_pass_count + ta.arr_pass_count AS "Всего"
FROM (SELECT f.departure_airport,
             sum(pass_count) AS dep_pass_count
      FROM bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.departure_airport) AS td ---total_departed_pass_counts
         JOIN
     (SELECT f.arrival_airport,
             sum(pass_count) AS arr_pass_count
      FROM bp
               JOIN flights AS f ON f.flight_id = bp.flight_id
      WHERE f.status IN ('Arrived', 'Departed')
        AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
      GROUP BY f.arrival_airport) AS ta ---total_arrived_pass_counts
     ON td.departure_airport = ta.arrival_airport
         JOIN airports AS a ON a.airport_code = td.departure_airport
ORDER BY "Всего" DESC;


/*Есть ли еще варианты сделать запрос более оптимальным и производительным
 *Да, необходимо перенсти оба подзапроса из главного запроса в конструкцию
 * WITH.
 * Время выполнения не уменьшилось, но запрос стал более читаемым*/

EXPLAIN ANALYZE
WITH bp AS (SELECT flight_id, count(*) AS pass_count
            FROM boarding_passes
            GROUP BY flight_id), ---общее табличное выражение

     total_departed_pass_counts AS (SELECT f.departure_airport,
                                           sum(pass_count) AS dep_pass_count
                                    FROM bp
                                             JOIN flights AS f ON f.flight_id = bp.flight_id
                                    WHERE f.status IN ('Arrived', 'Departed')
                                      AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
                                    GROUP BY f.departure_airport),

     total_arrived_pass_counts AS (SELECT f.arrival_airport,
                                          sum(pass_count) AS arr_pass_count
                                   FROM bp
                                            JOIN flights AS f ON f.flight_id = bp.flight_id
                                   WHERE f.status IN ('Arrived', 'Departed')
                                     AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL
                                   GROUP BY f.arrival_airport)


SELECT td.departure_airport                  AS "Код а/п",
       a.airport_name                        AS "Аэропорт",
       td.dep_pass_count                     AS "Вылетели",
       ta.arr_pass_count                     AS "Прибыли",
       td.dep_pass_count + ta.arr_pass_count AS "Всего"
FROM total_departed_pass_counts AS td
         JOIN total_arrived_pass_counts AS ta ON td.departure_airport = ta.arrival_airport
         JOIN airports AS a ON a.airport_code = td.departure_airport
ORDER BY "Всего" DESC;

/*Когда результат подзапроса, помещенного в конструкцию WITH, используется
 * в главном запросе (или в другом подзапросе внутри WITH) только один раз,
 * этот подзапрос по умолчанию не материализуется, а просто встраивается
 * в общий план и оптимизируется вместе с ним. А вот подзапрос с именем
 * bp по - прежнему используется более одного раза, пусть и не в главном
 * запросе, а в подзапросах находящихся как и он сам в конструкции WITH.
 * Поэтому он и в этой версии запроса материализуется и отражается под строкой
 * CTE bp.
 *
 * В рассмотренной версии остался потенциал для ускорения - соединение
 * bp и таблицы рейсы flights выполняется дважды в подзапросах
 * total_departed_pass_counts и total_arrived_pass_counts.
 * Вынесем эту операцию в отдельный запрос flights_pass_counts в
 * конструкции WITH
 *
 * Порядок следования подзапросов в WITH имеет значение.
 * Например переставив в последнем запросе местами подзапросы flights_pass_counts
 * и bp получим ошибку: отношение bp не существует.
 */

/*Время выполнения 83 миллисекунды, время выполнения еще немного уменьшилось*/
EXPLAIN ANALYZE
WITH bp AS MATERIALIZED (SELECT flight_id, count(*) AS pass_count
                         FROM boarding_passes
                         GROUP BY flight_id), ---общее табличное выражение

     flights_pass_counts AS (SELECT f.departure_airport,
                                    f.arrival_airport,
                                    bp.pass_count
                             FROM flights AS f
                                      JOIN bp ON f.flight_id = bp.flight_id
                             WHERE f.status IN ('Arrived', 'Departed')
                               AND f.scheduled_departure >= bookings.now() - '1 mon'::INTERVAL),

     total_departed_pass_counts AS (SELECT departure_airport,
                                           sum(pass_count) AS dep_pass_count
                                    FROM flights_pass_counts
                                    GROUP BY departure_airport),

     total_arrived_pass_counts AS (SELECT arrival_airport,
                                          sum(pass_count) AS arr_pass_count
                                   FROM flights_pass_counts
                                   GROUP BY arrival_airport)


SELECT td.departure_airport                  AS "Код а/п",
       a.airport_name                        AS "Аэропорт",
       td.dep_pass_count                     AS "Вылетели",
       ta.arr_pass_count                     AS "Прибыли",
       td.dep_pass_count + ta.arr_pass_count AS "Всего"
FROM total_departed_pass_counts AS td
         JOIN total_arrived_pass_counts AS ta ON td.departure_airport = ta.arrival_airport
         JOIN airports AS a ON a.airport_code = td.departure_airport
ORDER BY "Всего" DESC;

/*Рекурсивные общие табличные выражения
*Граф это множество вершин(узлов), соединенных линиями, которые называют
*ребрами (дугами).
*Каждое ребро соединяет две вершины.
*
*По графу можно перемещаться, переходя от одной вершины к другой, смежной
*с ней, формируя определеную траекторию или путь,
*как последовательность посещенных вершин или ребер.
*Длина пути равна числу ребер, составляющих его.
*Если путь начинается и заканчивается в одной и той же вершине
*и при этом не имеет повторяющихся ребер - он называется циклом.
*
*Связным графом называется граф, в котором от любой вершины можно
*добраться до любой другой.
*
*Граф может быть ориентированным.
*В этом случае его ребра имеют направление,
*и переходить по ребру от вершины к вершине можно только в этом направлении.
*
*Ребрам графа могут быть приписаны числовые значения - веса. Их смысл
*определяется спецификой конкретной задачи. Если представить
*маршруты перелетов, выполняемых авикомпанией, в виде графа, то весами
*можно считать, например, расстояния или продолжительности полетов между
*аэропортами.
*
*Частным случаем графов являются деревья. Они, как и графы общего вида,
*могут быть ориентированными (направленными) и неориентированными (
*ненаправленными). Неориентированное дерево - это связный граф без
*циклов, между любыми двумя его вершинами существует только один путь.
*
*
*Деревья широко используются в информатике, в частности как структура
*данных для индексов в СУБД.
*Они служат также средсвтом моделирования иерархий.
*Иерархия это многоуровневая струткра, в которой элементы, принадлежащие
*соседним уровням, связаны некторым типом взаимоотнощений.
*В качестве примеров иерархий можно привести систему воинских званий,
*административно-территоиальнрое деление страны, классификация биологических
*видов, организационные структуры кмпаний и учреждений, структурное
*устройство машин и механизмов.
*Отношения имеющие место в иерархии могут распространяться от более
*высоких уровней к более низким (от коня к листьям)
*
*Рекурсивные общие табличные выражения и используются для обработки
*иерархических данных.
*/


WITH RECURSIVE included_parts(part, sub_part, quantity) AS
                   (SELECT part, sub_part, quantity
                    FROM parts
                    WHERE part = 'самолет'

                    UNION ALL

                    SELECT p.part, p.sub_part, p.quantity * ip.quantity AS quantity
                    FROM included_parts ip,
                         parts p
                    WHERE p.part = ip.sub_part)

SELECT sub_part, sum(quantity) AS total_quantity
FROM included_parts
GROUP BY sub_part
ORDER BY sub_part;
/*в представлении структураного свойства самолета
 * каждая вершинаграфа соответствует какому то виду узлов или деталей,
 * а вес ребра графа соответствует количеству этих деталей, входящих
 * в состав узла более выского уровня иерархии. В результате оказывается,
 * что к некоторым вершинам графа ведет более одного пути, например -
 * к вершине, обозначающей колесо: ведь оно входит в состав передней
 * и двух основных стоек*/

CREATE TABLE parts
(
    part     text,
    sub_part text,
    quantity int NOT NULL,
    PRIMARY KEY (part, sub_part)
);

/*Реализация вычислительного процесса является итерационной, а не рекурсивной,
 * хотя в синтаксисе присутствует предложение recursive*/


WITH RECURSIVE included_parts(
                              iteration, part, sub_part, tt, quantity, path_to_sub_part) AS
                   (SELECT 1,
                           part,
                           sub_part,
                           COALESCE(part, sub_part) AS tt,
                           quantity,
                           part || '->' || sub_part || '(x' || quantity || ')'
                    FROM parts
                    WHERE part = 'самолет'
                    UNION ALL
                    SELECT iteration + 1,
                           p.part,
                           p.sub_part,
                           ip.tt,
                           p.quantity * ip.quantity AS quantity,
                           ip.part || '->' || ip.sub_part || '(x' || ip.quantity || ')' ||
                           CASE
                               WHEN p.part IS NOT NULL
                                   THEN '->' || p.sub_part || '(x' || p.quantity || ')'
                               ELSE '-> составных частей нет'
                               END
                    FROM included_parts ip
                             LEFT OUTER JOIN parts p ON
                        p.part = ip.sub_part
                    WHERE ip.part IS NOT NULL)

SELECT iteration,
       tt,
       part,
       sub_part,
       quantity,
       path_to_sub_part
FROM included_parts
ORDER BY iteration ASC

/*Штатная иерархия
 * FOREIGN KEY (boss_position_id) REFERENCES staff (POSITION_ID)
FOREIGN KEY (boss_position_id) - указывает, что столбец boss_position_id в
этой таблице будет внешним ключом
REFERENCES staff (POSITION_ID) - ссылается на столбец POSITION_ID в таблице staff
Как это работает:
Это создает иерархическую структуру внутри одной таблицы, где каждый
сотрудник может иметь начальника:
 */
CREATE TABLE staff
(
    position_id      integer PRIMARY KEY,  ---id позиции
    position_title   text NOT NULL,        --наименование должности
    person_name      text NOT NULL UNIQUE, ---имя работника
    boss_position_id integer,              ---id начальника
    FOREIGN KEY (boss_position_id) REFERENCES staff (position_id)
);


-- Вставка данных в таблицу staff
INSERT INTO staff (position_id, position_title, person_name, boss_position_id)
VALUES
-- Руководство (верхний уровень иерархии)
(1, 'Генеральный директор', 'Иванов Иван Иванович', NULL),

-- Директора (подчиняются генеральному директору)
(2, 'Директор по продажам', 'Петров Петр Петрович', 1),
(3, 'Директор по маркетингу', 'Сидорова Анна Сергеевна', 1),
(4, 'Директор по производству', 'Кузнецов Алексей Владимирович', 1),

-- Менеджеры (подчиняются директорам)
(5, 'Менеджер по продажам', 'Смирнов Дмитрий Олегович', 2),
(6, 'Менеджер по маркетингу', 'Федорова Елена Викторовна', 3),
(7, 'Старший менеджер по продажам', 'Новиков Сергей Александрович', 2),
(8, 'Менеджер по производству', 'Морозова Ольга Игоревна', 4),

-- Специалисты (подчиняются менеджерам)
(9, 'Специалист по продажам', 'Васильев Андрей Николаевич', 5),
(10, 'Маркетолог', 'Павлова Мария Дмитриевна', 6),
(11, 'Специалист по продажам', 'Григорьева Татьяна Владимировна', 7),
(12, 'Инженер-технолог', 'Белов Игорь Станиславович', 8),

-- Младшие специалисты
(13, 'Ассистент отдела продаж', 'Козлова Юлия Андреевна', 9),
(14, 'Ассистент маркетолога', 'Лебедев Артем Викторович', 10);

-- Проверка вставленных данных
SELECT *
FROM staff
ORDER BY position_id;
/*Вывести руководителей конкретного работника*/

WITH RECURSIVE search_staff
                   (position_title,
                    person_name,
                    position_id,
                    boss_position_id,
                    level) AS
                   (SELECT s.position_title,
                           s.person_name,
                           s.position_id,
                           s.boss_position_id,
                           1
                    FROM staff s
                    WHERE s.person_name = 'Кузнецов Алексей Владимирович'

                    UNION ALL

                    SELECT s.position_title,
                           s.person_name,
                           s.position_id,
                           s.boss_position_id,
                           ss.level + 1
                    FROM search_staff ss,
                         staff s
                    WHERE s.position_id = ss.boss_position_id)


SELECT position_title,
       person_name,
       position_id,
       boss_position_id,
       (SELECT max(level) FROM search_staff) - LEVEL + 1 AS level
FROM search_staff
ORDER BY level ASC

/*Выведем подчиненных указанного работника
 * схематично как раьотает
 *
 * ШАГ 0: [Олег] ← начальная точка (level 1)
    ↓
ШАГ 1: [Олег, Иван] ← нашли подчиненного (level 2)
    ↓
ШАГ 2: [Олег, Иван, Петр, Анна] ← нашли подчиненных (level 3)
    ↓
ШАГ 3: [Олег, Иван, Петр, Анна, Сергей, Мария] ← нашли подчиненных (level 4)
    ↓
ШАГ 4: [Олег, Иван, Петр, Анна, Сергей, Мария, Елена] ← нашли подчиненного (level 5)
    ↓
ШАГ 5: [результат тот же] ← подчиненных нет, СТОП
*/
WITH RECURSIVE search_staff
                   (position_title,
                    person_name,
                    position_id,
                    boss_position_id,
                    level) AS
                   (SELECT s.position_title,
                           s.person_name,
                           s.position_id,
                           s.boss_position_id,
                           1
                    FROM staff s
                    WHERE s.person_name = 'Кузнецов Алексей Владимирович'

                    UNION ALL

                    SELECT s.position_title,
                           s.person_name,
                           s.position_id,
                           s.boss_position_id,
                           ss.level + 1
                    FROM search_staff ss,
                         staff s
                    WHERE s.boss_position_id = ss.position_id)


SELECT position_title, person_name, position_id, boss_position_id, level
FROM search_staff
ORDER BY level, boss_position_id, position_id

/*Массивы в общих табличных выражениях
 * Выявление циклов.
 * При работе с иерархическими данными важно убдеиться в их корректности
 * в графе между любыми двумя вершинами должен муществовать только один
 * путь и не должно быть циклов
 * Исследование иерархической системы
 * Ограничимся уже созданным первичным ключом, который не позволит
 * появиться ребрам - дубликатам
 * Для выявления множественных путей нужно сначала научиться получать
 * пути, ведущие из начала иерархии ко всем другим вершинам.
 * В нашем примере начало иерархии - вершина с номером 1.
 * Но если бы этот номер не был заранее известен, его можно было бы определить,
 * вспомнив, что в вершину, являющуюся начальной точкой иерархии, не входит
 * ни одно ребро, то есть она не фигурирует в стоблце vertex_to ни в одной
 * строке таблицы Иерархия hier.
 * Одним из решений могло быть такое
 */

CREATE TABLE hier
(
    vertex_from integer,
    vertex_to   integer,
    data        NUMERIC,
    PRIMARY KEY (vertex_from, vertex_to)
);
INSERT INTO hier (vertex_from, vertex_to, data)
VALUES (1, 2, 4.7),
       (1, 3, 5.6),
       (2, 4, 6.3),
       (2, 5, 1.9),
       (3, 6, 3.5),
       (3, 7, 2.8),
       (3, 8, 4.1),
       (5, 9, 3.3),
       (5, 10, 4.5),
       (6, 11, 2.7),
       (6, 12, 1.3),
       (9, 13, 2.1);


SELECT distinct(vertex_from)
FROM hier h1
WHERE NOT EXISTS (SELECT 1 FROM hier h2 WHERE h2.vertex_to = h1.vertex_from)

/*Другое решение на основе внешнего соединения*/
SELECT DISTINCT h1.vertex_from
FROM hier h1
         LEFT JOIN hier h2 ON h2.vertex_to = h1.vertex_from
WHERE h2.vertex_to IS NULL;

/*Самый быстрый запрос, результат аналогичен двум предыдущим*/
SELECT vertex_from
FROM hier
EXCEPT
SELECT vertex_to
FROM hier

/*Например если из дерева удалить одно ребро то дерево распадется на два дерева
 * при этом каждая из двух вершин будет принадлежать разным вновь полученным
 * деревьям теперь приведем запрос, который решает основную задачу: получает пути,
 * ведущие из начала иерархии ко всем другим вершинам
 *
 *
*/

WITH RECURSIVE search_hier(vertex_from, vertex_to, data, depth) AS
                   (SELECT h.vertex_from, h.vertex_to, h.data, 1
                    FROM hier h
                    WHERE h.vertex_from = 1

                    UNION ALL

                    SELECT h.vertex_from, h.vertex_to, h.data, sh.DEPTH + 1
                    FROM search_hier sh,
                         hier h
                    WHERE h.vertex_from = sh.vertex_to)

SELECT *
FROM search_hier
ORDER BY depth, vertex_from, vertex_to


SELECT *
FROM hier h

/*Существует возможность представить полные пути от одной
 * вершины к другой, для этого можно воспользоваться массивами*/

WITH RECURSIVE search_hier(vertex_from, vertex_to, data, depth, path) AS
                   (SELECT h.vertex_from,
                           h.vertex_to,
                           h.data,
                           1,
                           ARRAY [h.vertex_from, h.vertex_to] path
                    FROM hier h
                    WHERE h.vertex_from = 1

                    UNION ALL

                    SELECT h.vertex_from,
                           h.vertex_to,
                           h.data,
                           sh.depth + 1,
                           sh.path || h.vertex_to
                    FROM search_hier sh,
                         hier h
                    WHERE h.vertex_from = sh.vertex_to)

SELECT *
FROM search_hier
ORDER BY depth, vertex_from, vertex_to

/*Теперь мы готовы к тому чтобы научиться выявлять нарушения
 * структуры иерархии: присуствие циклов и наличие более одного
 * пути от начала иерархии (корня дерева к вершинам)*/

INSERT INTO hier
VALUES (5, 2, 3.8),
       (11, 3, 7.4)


WITH RECURSIVE search_hier(vertex_from, vertex_to, data, depth, PATH, cycle) AS
                   (SELECT h.vertex_from,
                           h.vertex_to,
                           h.data,
                           1,
                           ARRAY [h.vertex_from, h.vertex_to] PATH, ----path
                           FALSE                                    ----выявление циклов (cycle)
                    FROM hier h
                    WHERE h.vertex_from = 1

                    UNION ALL

                    SELECT h.vertex_from,
                           h.vertex_to,
                           h.data,
                           sh.depth + 1,
                           sh.path || h.vertex_to,
                           h.vertex_to = ANY (sh.path)
                    FROM search_hier sh,
                         hier h
                    WHERE h.vertex_from = sh.vertex_to
                      AND NOT sh.cycle)

SELECT *
FROM search_hier
ORDER BY depth, vertex_from, vertex_to;

/*Поиск маршрута между двумя городами, между которыми, возможно нет, прямого
 * сообщения.
 * Но даже если оно существует, у пассажира может возникнуть
 * необходимость в маршруте с пересадками,
 * если например, на более удобные рейсы закончились билеты
 *
 * Обратите внимание, что для каждой пары городов, между коорыми установлено
 * сообщение, в таблице (точнее говоря, представлении) "Маршруты" routes
 * находятся две строки: для рейсов в прямом и в обратном направлениях.
 * Таким образом, мы имеем дело с ориентированным графом, причем для каждой пары
 * вершин a и b существует два ребра: (a, b) и (b, a).
 *
 * Важно, что мы ищем только маршрут, то есть определяем принципиальную
 * возможность перемещения между городами, а не подбираем конкретные рейсы
 * с учетом их стыковок по времени вылета!!!
 *
 * Представим стратегию поиска, которая позволит выбрать не только самый
 * короткий (по числу перелдетов) маршрут, но и более длинные маршруты.
 *
 * 1.Сформировать маршруты из исходного города в те города, в которые из него
 * выполняются прямые рейсы.
 *
 * 2.Удлинить формируемые маршруты на один перелет, добавив к текущему конечному
 * пункту те города, в которые есть прямые рейсы из него.
 * Если текущий конечный пункт какого-либо маршрута (до его удлинения) является
 * целевым городом, то прокладывать дальнейший маршрут из него уже не нужно,
 * однако необходимо записать полученный маршрут в результирующий список
 * машрутов.
 *
 * В составе каждого формируемого маршрута не должно быть повторяющихся городов
 * - циклы недопустимы.
 *
 * Процесс удлинения продолжается, пока не достигнута заданная предельная длина
 * маршрута (число перелетов между городами)!!!
 *
 * 3.Выбрать из сформированных маршрутов только те, в которых конечной точкой
 * является целевой город!!!
 *
 * Как пример проложим машрут из Новосибирска в Краснодар. При этом будем ограничивать
 * предельное число перелетов, скажем, четырьмя. Алгоритм не изменится, если
 * число перелетов будет и большим, но негуманно заставлять пассажира совершать
 * так много пересадок.
 *
 * */

EXPLAIN ANALYZE
WITH RECURSIVE search_route(
                            city_from,
                            city_to,
                            transfers,
                            route)
                   AS
                   (SELECT DISTINCT ON (arrival_city) departure_city,
                                                      arrival_city,
                                                      1,
                                                      ARRAY [departure_city, arrival_city]
                    FROM routes
                    WHERE departure_city = 'Новосибирск'

                    UNION ALL

                    SELECT DISTINCT ON (sr.route || r.arrival_city) r.departure_city,
                                                                    r.arrival_city,
                                                                    transfers + 1,
                                                                    sr.route || r.arrival_city
                    FROM search_route sr
                             JOIN routes AS r ON r.departure_city = sr.city_to
                    WHERE sr.city_to <> 'Краснодар'
                      AND sr.transfers <= 4
                      AND r.arrival_city <> ALL (sr.route) --- Предотвращение петель и циклов в графе маршрутов
                   )

SELECT transfers                     AS "Число перелетов",
       array_to_string(route, ' - ') AS "Маршрут"
FROM search_route
WHERE city_to = 'Краснодар'
ORDER BY transfers, route;


/*Модификации данных в общем табличном выражении
 * До сих пор в общих табличных выражениях CTE мы ограничивались
 * только командами Select. Однако в эти выражения можно включать
 * и команды изменения данных: вставку, обновление, удаление строк.
 * Можно как пример переместить данные из оперативных таблиц в архивные
 * учитывая специфику предметной области, размеры таблиц и скорость
 * приращения числа записей. В нашем случае в рамках одной
 * операции бронирования может быть оформлено более одного перелета,
 * которые могут выполняться в разные даты.
 * Мы изберем такую стратегию:
 *
 * 1.Из оперативных таблиц Перелеты ticket_flights, Посадочные талоны boarding_passes
 * и Рейсы flights будем переносить в архивные таблицы записи, относящиеся к рейсам
 * "возраст" которых не менее тридцати дней. Речь идет о рейсах, которые уже
 * завершены или отменены. Важно то, что мы недопустим ситуацию, когда из
 * оперативной таблицы Посадочные талоны boarding_passes в архивную перенесена
 * лишь часть записей, относящихся к конкретному рейсу. Однако при этом возможна
 * ситуация, когда часть записей о перелетах, относящихся к одному и тому же
 * билету, останется в оперативной таблице Перелеты ticket_flights, а другая часть
 * пернесена в архивную таблицу.
 * 2.Из оперативной таблицы Билеты tickets будем переносить в архивную таблицу
 * те строки, у которых нет связанных строк в таблице Перелеты ticket_flights.
 * Проще говоря, эти билеты, осташиеся без перелетов.
 * С таблицей бронирования поступим аналогичным образом: будем переносить
 * в архивную таблицу те строки, у которых нет связанных строк в таблице
 * Билеты (tickets), то есть бронирования, осташиеся без билетов.
 *
 * При выбранной стратегии сохраняется возможность получить полную стоимость
 * даже тех бронирований, часть записей о перелетах которых уже перенсена
 * в архив. Это возможно благодаря тому, что в таблице бронирований bookings
 * есть столбец total_amount, содержащий полную стоиомость бронирования, которая
 * складывается из стоимостей всех входящих в него перелетов. Это пример
 * контролируемой избыточности в базе данных.
 *
 * Прежде всего создадим архивные таблицы. Заполнять данными их, конечно не будем.
 * Создавать первичные и внешние ключи тоже не станем, поскольку данные, которые
 * будут вводиться в ахивные таблицы, не будут согласованными: связанные данные
 * могут разрываться между оперативными и архивными таблицами.
 * Например в архив может быть перенесена лишь часть записей о перелетах,
 * оформленных в одном билете.
 * */

CREATE TABLE flights_arch AS
SELECT *
FROM flights WITH NO DATA;

CREATE TABLE bookings_arch AS
SELECT *
FROM bookings WITH NO DATA;

CREATE TABLE tickets_arch AS
SELECT *
FROM tickets WITH NO DATA;

CREATE TABLE ticket_flights_arch AS
SELECT *
FROM ticket_flights WITH NO DATA;

CREATE TABLE boarding_passes_arch AS
SELECT *
FROM boarding_passes WITH NO DATA;

/*Переносим в архив истоию рейсов, совершенных
 * не менее 30 дней назад:*/

BEGIN;
INSERT INTO flights_arch
SELECT *
FROM flights
WHERE bookings.now()::date - scheduled_departure::date >= 30;

INSERT INTO ticket_flights_arch
SELECT tf.*
FROM ticket_flights AS tf,
     flights AS f
WHERE bookings.now()::date - f.scheduled_departure::date >= 30
  AND tf.flight_id = f.flight_id;

INSERT INTO boarding_passes_arch
SELECT bp.*
FROM boarding_passes AS bp,
     flights AS f
WHERE bookings.now()::date - f.scheduled_departure::date >= 30
  AND bp.flight_id = f.flight_id;

ROLLBACK

/*Удалим таблицы в рамках тразакции в CTE*/
BEGIN;

WITH deleted_f AS
         (DELETE FROM flights
             WHERE bookings.now()::date - scheduled_departure::date >= 30
             RETURNING *),

     deleted_tf AS
         (DELETE FROM ticket_flights AS tf
             USING deleted_f AS df
             WHERE tf.flight_id = df.flight_id
             RETURNING tf.*),

     deleted_bp AS
         (DELETE FROM boarding_passes AS bp
             USING deleted_f AS df
             WHERE bp.flight_id = df.flight_id
             RETURNING bp.*),

     inserted_bp AS
         (INSERT INTO boarding_passes_arch
             SELECT *
             FROM deleted_bp),

     inserted_tf AS
         (INSERT INTO ticket_flights_arch
             SELECT *
             FROM deleted_tf)
INSERT
INTO flights_arch
SELECT *
FROM deleted_f;

SELECT count(*)
FROM boarding_passes_arch bpa
ROLLBACK


/*Материализация общего табличного выражения может
 * влиять на скорость выполнения всего запроса
 * Поскольку результат выполнения подзапроса,
 * представленного в конструкции with используется в главном
 * запросе более одного раза, то по умолчанию запрос
 * материализуется - в плане присутствуют CTE Scan.
 * При выполнении
 * подзапроса aps создается временная таблица с таким же именем.
 * Для соединения двух наборов строк используется метод вложенного
 * цикла узел Nested Loop. В строке join filter  этого узла показано
 * условие соединения.
 * Важно, что в данном случае a1.city b a2.city представляют собой
 * скалярные текстовые значения, а не объекты json поскольку при
 * материализации подзапроса для каждой строки были вычислены
 * выражения с оператором -->, предусмотренные представлением.
 *
 * Материализация подзапроса означает, что результаты его выполнения
 * сохраняются во временной таблице, и повторная выборка проихзводится
 * уже из нее.
 * */

EXPLAIN (VERBOSE, ANALYZE, BUFFERS)
WITH aps AS (SELECT * FROM airports)
SELECT count(*)
FROM aps AS a1
         JOIN aps AS a2 ON a1.city <> a2.city;

/*
QUERY PLAN                                                                                                            |
----------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=155.78..155.78 rows=1 width=8) (actual time=3.667..3.668 rows=1 loops=1)                             |
  CTE aps                                                                                                             |
    ->  Seq Scan on airports_data ml  (cost=0.00..24.53 rows=104 width=99) (actual time=0.052..0.498 rows=104 loops=1)|
  ->  Nested Loop  (cost=0.00..120.54 rows=10712 width=0) (actual time=0.067..3.072 rows=10704 loops=1)               |
        Join Filter: (a1.city <> a2.city)                                                                             |
        Rows Removed by Join Filter: 112                                                                              |
        ->  CTE Scan on aps a1  (cost=0.00..1.04 rows=104 width=32) (actual time=0.056..0.065 rows=104 loops=1)       |
        ->  CTE Scan on aps a2  (cost=0.00..1.04 rows=104 width=32) (actual time=0.000..0.013 rows=104 loops=104)     |
Planning Time: 0.160 ms                                                                                               |
Execution Time: 3.711 ms
*/

/*Проведем экспримент - отменим материализованное представление
 * теперь условие join filter обращается к полям json объектов,
 * имена ключей которых формируются для каждой строки вызовами
 * функции lang и это приводит к значительному замедлению запроса*/

EXPLAIN (VERBOSE, ANALYZE, BUFFERS)
WITH aps AS NOT MATERIALIZED (SELECT * FROM airports)
SELECT count(*)
FROM aps AS a1
         JOIN aps AS a2 ON a1.city <> a2.city;

/*
 * QUERY PLAN                                                                                                                       |
---------------------------------------------------------------------------------------------------------------------------------+
Aggregate  (cost=2278.40..2278.41 rows=1 width=8) (actual time=13.428..13.431 rows=1 loops=1)                                    |
  ->  Nested Loop  (cost=0.00..2267.69 rows=10712 width=0) (actual time=0.064..12.881 rows=10704 loops=1)                        |
        Join Filter: ((ml.city ->> lang()) <> (ml_1.city ->> lang()))                                                            |
        Rows Removed by Join Filter: 112                                                                                         |
        ->  Seq Scan on airports_data ml  (cost=0.00..3.52 rows=104 width=49) (actual time=0.022..0.036 rows=104 loops=1)        |
        ->  Materialize  (cost=0.00..3.73 rows=104 width=49) (actual time=0.000..0.003 rows=104 loops=104)                       |
              ->  Seq Scan on airports_data ml_1  (cost=0.00..3.52 rows=104 width=49) (actual time=0.003..0.016 rows=104 loops=1)|
Planning Time: 0.426 ms                                                                                                          |
Execution Time: 13.475 ms                                                                                                        |
 * */

EXPLAIN (VERBOSE, ANALYZE, BUFFERS)
WITH aps AS (SELECT *
             FROM (SELECT * FROM airports) AS a1
                      JOIN (SELECT * FROM airports) AS a2 ON a1.city <> a2.city)

SELECT count(*)
FROM aps;


/*
 * Детальное сравнение:
Характеристика	  План 1 (Умный)	         План 2 (Полный)
Стратегия LIMIT	  Раннее прекращение	     Сортировка + LIMIT
Время выполнения  0.042 ms	                 2.207 ms
Обработано строк  10 строк	                 9900 строк
Память	          Минимум	                 25kB heap
CTE g1 строки	  1 строка	                 100 строк
CTE g2 строки	  11 строк (всего)	         100 строк × 100 циклов
 *
 * План1: -- Оптимизатор понимает, что нужно только 10 строк
Выполняет Nested Loop до тех пор, пока не наберет 10 подходящих строк
LOOP по g1 (только 1 строка!)
  LOOP по g2 (11 строк из 100)
    Проверяем g1.num <> g2.num
    Если true - добавляем в результат
    КОГДА набрали 10 строк - ПРЕКРАЩАЕМ выполнение!
 *
 * План 2:
Выполняет ВЕСЬ Nested Loop (100 × 100 = 10000 комбинаций)
LOOP по g1 (все 100 строк)
  LOOP по g2 (все 100 строк)
    Проверяем g1.num <> g2.num
    Отфильтровываем 100 дубликатов (где g1.num = g2.num)
    Получаем 9900 строк
-- Сортируем все 9900 строк
-- Берем первые 10 отсортированных строк
 *
 *
 */
EXPLAIN ANALYZE
WITH g AS (SELECT *
           FROM generate_series(1, 100) AS gs(num))
SELECT g1.num, g2.num
FROM g AS g1
         JOIN g AS g2 ON g1.num <> g2.num
ORDER BY 1, 2
LIMIT 10


/*Разница между union и union all*/

EXPLAIN ANALYZE
WITH RECURSIVE t(n) AS
                   (SELECT 1
                    UNION ALL
                    SELECT n + 1
                    FROM t
                    WHERE n < 100)
SELECT count(n),
       sum(n),
       avg(n)
FROM t;


EXPLAIN ANALYZE
WITH RECURSIVE t(n) AS
                   (values (1),
                           (2),
                           (3)
                    UNION ALL
                    SELECT n + 1
                    FROM t
                    WHERE n < 101)
SELECT n
FROM t
ORDER BY n;


/*Агрегатные функции*/

SELECT string_agg(model, E'\n ' ORDER BY model) AS models,
       array_agg(range ORDER BY model)          AS ranges,
       array_agg(model ORDER BY model)          AS models_1,
       min(range)                               AS min,
       max(range)                               AS max,
       bool_or(RANGE < 5000)                    AS b_or, ---если в группе найдется хотя бы
----одна строка, для которой параметр функции имеет значение true
       bool_and(RANGE <= 11100)                 AS b_and,--- если для всех строк в группе
----ее параметр также имеет значение true
       round(avg(range), 2)                     AS everage,
       count(*)
FROM aircrafts
WHERE LEFT(model, strpos(model, ' ') - 1) IN ('Аэробус', 'Боинг')
GROUP BY LEFT(model, strpos(model, ' ') - 1)
--WHERE SPLIT_PART(model, ' ', 1) IN ('Аэробус', 'Боинг')
--GROUP BY SPLIT_PART(model, ' ', 1);


SELECT min(days_of_week), max(days_of_week)
FROM routes

SELECT DISTINCT days_of_week
FROM routes
ORDER BY days_of_week
---массивы, как и строки, сортируются в лексикографическом порядке, то есть
---сначала сравниваются первые элементы массивов,
---при их совпадаении сравниваются вторые элементы и.д.

/*Агрегатные функции тесно связаны с group by*/
EXPLAIN(ANALYZE, costs OFF, timing off)
SELECT status
FROM flights
GROUP BY status


EXPLAIN ANALYZE
SELECT status, count(*)
FROM flights
GROUP BY status


/*FILTER в PostgreSQL - это модификатор для агрегатных функций, который позволяет применять агрегацию только к подмножеству строк.*/
EXPLAIN ANALYZE
SELECT count(flight_id) FILTER (WHERE fare_conditions = 'Economy')  AS Economy,
       count(flight_id) FILTER (WHERE fare_conditions = 'Comfort')  AS Comfort,
       count(flight_id) FILTER (WHERE fare_conditions = 'Business') AS Business
FROM ticket_flights;

---Он
SELECT COUNT(CASE WHEN fare_conditions = 'Economy' THEN 1 END)  AS Economy,
       COUNT(CASE WHEN fare_conditions = 'Comfort' THEN 1 END)  AS Comfort,
       COUNT(CASE WHEN fare_conditions = 'Business' THEN 1 END) AS Business
FROM ticket_flights;

SELECT SUM(CASE WHEN fare_conditions = 'Economy' THEN 1 ELSE 0 END)  AS Economy,
       SUM(CASE WHEN fare_conditions = 'Comfort' THEN 1 ELSE 0 END)  AS Comfort,
       SUM(CASE WHEN fare_conditions = 'Business' THEN 1 ELSE 0 END) AS Business
FROM ticket_flights;

SELECT (SELECT COUNT(*) FROM ticket_flights WHERE fare_conditions = 'Economy')  AS Economy,
       (SELECT COUNT(*) FROM ticket_flights WHERE fare_conditions = 'Comfort')  AS Comfort,
       (SELECT COUNT(*) FROM ticket_flights WHERE fare_conditions = 'Business') AS Business;

---CREATE EXTENSION IF NOT EXISTS tablefunc;
EXPLAIN ANALYZE
SELECT *
FROM crosstab(
             'SELECT ''total'' as row_name, fare_conditions, COUNT(*)
     FROM ticket_flights
     GROUP BY fare_conditions
     ORDER BY 1,2'
     ) AS ct(row_name text, Economy bigint, Comfort bigint, Business bigint);


/*Функции для получения и агрегирования данных в формате json
 * Postgres рекомендует всегда использовать jsonb а не json
 * Привести jsonb к числовому типу можно, а вот json привести
 * к числовому типу нельзя*/


WITH people_info(num, KEY, value) AS
         (VALUES (1, 'weight', 80.5),
                 (1, 'height', 175),
                 (1, 'age', 35),
                 (2, 'weight', 76.4),
                 (2, 'height', 183),
                 (2, 'age', 45),
                 (3, 'weight', 68.8),
                 (3, 'height', 169),
                 (3, 'age', 40))
SELECT num, jsonb_object_agg(key, value) AS info
FROM people_info
GROUP BY num;


WITH people_info(num, KEY, value) AS
         (VALUES (1, 'weight', 80.5),
                 (1, 'height', 175),
                 (1, 'age', 35),
                 (2, 'weight', 76.4),
                 (2, 'height', 183),
                 (2, 'age', 45),
                 (3, 'weight', 68.8),
                 (3, 'height', 169),
                 (3, 'age', 40)),
     jsonbs AS
         (SELECT num, jsonb_object_agg(key, value) AS info
          FROM people_info
          GROUP BY num)

SELECT avg((info -> 'age')::double precision)
FROM jsonbs
;

/*Требуется организовать более реалистиный пример, предположим
 * что необходимо организтвать просмотр в удобной форме
 * всей информации о каждом бронировании, включая все
 * оформленные в его рамках бидеты и перелеты*/

SELECT b.book_ref,
       b.book_date,
       b.total_amount,
       jsonb_pretty(
               jsonb_object_agg(
                       t.ticket_no,
                       jsonb_build_array(
                               t.passenger_id,
                               t.passenger_name,
                           --все перелеты для текущего билета для ticket_flights
--отсортированные по плановому времени вылета
                               (SELECT jsonb_agg(
--описание одного перелета по данным оной строки
                                               jsonb_build_array(
                                                       f.flight_no,
                                                       f.scheduled_departure,
                                                       f.departure_city || '-' || f.arrival_city,
                                                       jsonb_build_object(
                                                               'fare_cond', tf.fare_conditions,
                                                               'amount', tf.amount)
                                               ) ORDER BY f.scheduled_departure)

                                FROM ticket_flights tf
                                         JOIN flights_v f ON f.flight_id = tf.flight_id --using(flight_id)
                                WHERE tf.ticket_no = t.ticket_no
                                GROUP BY tf.ticket_no)
                       )
               )
       ) AS tickets_info
FROM bookings b
         JOIN tickets t ON t.book_ref = b.book_ref -- USING(book_ref)
WHERE b.book_ref = 'D56F95'
GROUP BY b.book_ref

/*Статистические функции
 * Накопление больших объемов информации или данных позволяет выявить
 * закономерности, которым подчиняются эти данные, и получить
 * полезную информацию для принятия решений.
 *Определим с какой точность фиксировались моменты отправлений
 *рейсов, и следовательно с какой точностью можно выичлить их
 *задержки (по минутам, секундам, часам)*/


SELECT count(*) FILTER (WHERE EXTRACT(sec FROM scheduled_departure) > 0)
           AS scheduled_departured_nonzero_secs,
       count(*) FILTER (WHERE EXTRACT(sec FROM actual_departure) > 0)
           AS actual_departured_nonzero_secs
FROM flights_v
WHERE actual_departure > scheduled_departure
---отклонений фактического времени вылета с плановым временем по секундам нет.

---теперь рассмотрим число минут

SELECT count(*) FILTER (WHERE EXTRACT(min FROM scheduled_departure) > 0)
                                                                      AS scheduled_departured_nonzero_secs,
       count(*) FILTER (WHERE EXTRACT(min FROM actual_departure) > 0) AS actual_departured_nonzero_secs,
       count(*) FILTER (WHERE EXTRACT(min FROM scheduled_departure) > 0) -
       count(*) FILTER (WHERE EXTRACT(min FROM actual_departure) > 0) AS diff
FROM flights_v
WHERE actual_departure > scheduled_departure
---расхождени я по минутам есть


/*Рассмотрим какие значения имеет число минут
 * в плановом и фактическом времени вылета*/
SELECT array_agg(DISTINCT EXTRACT(min FROM scheduled_departure)) AS
           scheduled_mins
FROM flights_v
WHERE actual_departure > scheduled_departure

/*Фактическое время может содержать любое число минут
 * от 0 до 59*/
SELECT array_agg(DISTINCT EXTRACT(min FROM actual_departure)) AS
           actual_departure_mins
FROM flights_v
WHERE actual_departure > scheduled_departure

/*Теперь можно перейти к анализу задержек рейсов
 * Начнем с вычисления основных статистических показателей
 * выборки: среднее значение длительности задержки,
 * дисперсии, среднеквадратичного отклонения, моды и
 * медианы.
 * 1.Среднее значение - avg
 * 2.Дисперсия и среднеквадратичное отклонение характеризуют
 * величину разброса полученных значений вокруг среднего значения.
 * Для вычислени дисперсии предназначены две функции:
 * var_pop и var_samp. Первая из них выисляет дисперсию для шенеральной
 * совокупности то есть только для всего исследуемого множества объектов,
 * а вторая - для выборки из этой совокупности.
 * Здесь под выборкой понимается не множество строк, возвращенных запросом, а подмножество
 * объектов, выбранных случайным образом из генеральной совокупности.
 * Поскольку мы имеем возможность исследовать все задержанные рейсы,
 * которые и будут образовывать генеральную совокупность, воспользуемся
 * функцией var_pop. Эта функция не может работать с типом данных interval,
 * поэтому переведем значения задержке, представленных в виде инервалов,
 * в целое число минут.
 * Аналогично и для вычисления среднеквадратичного отклонения воспользуемся
 * функцией stddev_pop.
 * 3.Мода это наиболее типичное значение в выборке, оно имеет наибольшую
 * частоту встречаемости в вариационном ряде. Функция mode
 * 4.Медиана - это значение, которое делит вариационный ряд на две
 * равные части (по числу элементов) - percentile_disc.
 * Дискретная случайная величина и вариационный ряд.
 * Случайную величину называют дискретной, если множество ее возможных
 * значений конечно либо счетно.
 * Счетным называется бесконечное множество, элементы которого можно
 * пронумеровать натуральными числами.
 * Вариационным рядом называется последовательность полученных значений случайно
 * величины, упорядоченных по возрастанию!!!
Общее количество	16056
Минимальная задержка	00:01:00
Максимальная задержка	04:37:00
Средняя задержка	00:12:45.09716
Дисперсия	1784.72
Стандартное отклонение	42.25
Мода	00:03:00
Медиана	00:03:00

Глядя на результат можно предполоджить, что большая часть задержек
рейсов является кратковременной. Тем неменее поскольку среднее значение
больше медианы, а максимально значение - более четырех с половиной часов,
представляется целесообразным сформировать вариационный ряд задержек
рейсов для получения более детальной картины!!!
 *
 *
 */

WITH delays AS (SELECT actual_departure - scheduled_departure AS delay
                FROM flights_v
                WHERE actual_departure > scheduled_departure),
     stats AS (SELECT count(*)                                                      as total_count,
                      min(delay)                                                    AS minimal_delay,
                      max(delay)                                                    AS maximal_delay,
                      avg(delay)                                                    AS average_delay,
                      round(var_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2)    AS variance,
                      round(stddev_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2) AS standart_deviation,
                      mode() WITHIN GROUP (ORDER BY delay)                          as mode_delay,
                      percentile_disc(0.5) WITHIN GROUP (ORDER BY delay)            AS median
               FROM delays)
SELECT unnest(ARRAY [
    'Общее количество',
    'Минимальная задержка',
    'Максимальная задержка',
    'Средняя задержка',
    'Дисперсия',
    'Стандартное отклонение',
    'Мода',
    'Медиана'
    ])        as metric,
       unnest(ARRAY [
           total_count::text,
           minimal_delay::text,
           maximal_delay::text,
           average_delay::text,
           variance::text,
           standart_deviation::text,
           mode_delay::text,
           median::text
           ]) as value
FROM stats;

/*SELECT
count(*),
min(delay) AS minimal_delay,
max(delay) AS maximal_delay,
avg(delay) AS average,
round(var_pop(EXTRACT(epoch FROM delay)/60)::NUMERIC, 2) AS variance,
round(stddev_pop(EXTRACT(epoch FROM delay)/60)::NUMERIC,2) AS standart_deviation,
mode() WITHIN GROUP (ORDER BY delay)
FROM delays*/


/*Из результатов выборки можно увидеть, что она явно разбивается на две части,
 * коротки задержки, не первышающие 11 минут, и длительные
 * задержки первышающие два часа.
 * Для определенности будем считать задержки, не превышающие
 * одного часа, короткими, а первышающие этот рубеж - длительными*/
SELECT (actual_departure - scheduled_departure) AS delay,
       count(*)
FROM flights_v
WHERE actual_departure > scheduled_departure
GROUP BY delay
ORDER BY delay

/*Создадим представление выбирающее коротки задержки*/
CREATE VIEW short_delays AS
SELECT (actual_departure - scheduled_departure) AS delay
FROM flights_v
WHERE actual_departure > scheduled_departure
  AND actual_departure <= scheduled_departure + INTERVAL '1hour';

SELECT *
FROM short_delays

/*Теперь мы видим, что среднее значение почти сопадает с меодой и
 * медианой
 * Получить более информативную картину можно с помощью выичления
 * процентилей*/
WITH stats AS (SELECT count(*)                                                      as total_count,
                      min(delay)                                                    AS minimal_delay,
                      max(delay)                                                    AS maximal_delay,
                      avg(delay)                                                    AS average_delay,
                      round(var_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2)    AS variance,
                      round(stddev_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2) AS standart_deviation,
                      mode() WITHIN GROUP (ORDER BY delay)                          as mode_delay,
                      percentile_disc(0.5) WITHIN GROUP (ORDER BY delay)            AS median
               FROM short_delays)
SELECT unnest(ARRAY [
    'Общее количество',
    'Минимальная задержка',
    'Максимальная задержка',
    'Средняя задержка',
    'Дисперсия',
    'Стандартное отклонение',
    'Мода',
    'Медиана'
    ])        as metric,
       unnest(ARRAY [
           total_count::text,
           minimal_delay::text,
           maximal_delay::text,
           average_delay::text,
           variance::text,
           standart_deviation::text,
           mode_delay::text,
           median::text
           ]) as value
FROM stats;

/*Если выборку длительностей задержек упорядочить по
 * возарстанию, а затем разбить на равные - по числу элементов -
 * диапазоны, то значения, находящиеся на границах этих
 * диапазонов, будут называться процентилями соответствующих
 * уровней. Например, если выборка разбивается на десять
 * диапазонов, в каждый из которых входит по 10% значений,
 * то такие процентили называются децилями. В этом случае
 * мы сможем сказать, например, что 70% значений из выборки
 * не превышают по величине значения дециля уровня 0.7
 * Вычислим процентили (децили) для коротких задержек
 * В нашем случае интервалы времени явлюятся дискретными
 * и измеряются с точностью до минут. Эта функция может получать
 * в качестве параметра массив чисел, представляющих собой доли
 * выборки. В нашем примере вычисляются децили, поэтому и массив
 * содержит значения от 0.1 до 1.0 с шагом 0.1, то есть по 10%.
 * Результатом является также массив. Он содержит граничные значения
 * величин задержек рейсов для каждого диапазона, содержащего
 * 10% элементов выборки. Интерпертировать результат мы можем так -
 * 10% всех задержек не превышают по длительности одну минуту,
 * 20% всех задержек не превышают по длительности 2 минуты,
 * 30% всех задержек также не превышают по длительности 3 минуты
 * И все 100% задержек не превышают по длительности 11 минут.
 * */

SELECT percentile_disc(
       ARRAY [0.1 ,0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
                      )
       WITHIN GROUP (ORDER BY delay) AS deciles
FROM short_delays;

/*Разворот массива в виде столбца таблицы с помощью функции unnest*/

WITH deciles AS
         (SELECT percentile_disc(
                 ARRAY [0.1 ,0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0])
                 WITHIN GROUP (ORDER BY delay) AS deciles
          FROM short_delays)

SELECT unnest(ARRAY [0.1 ,0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]) AS LEVEL,
       unnest(deciles)                                                  AS decile
FROM deciles;

/*Обратите внимание, что значения децилей повторяются. Разобраться,
 * почему это происходит, можно с помощью такого запроса.
 * В это запросе мы не только подсчитываем количество задержек
 * каждой длительностт, но и вычисляем их доли в общем количестве задержек (выражените
 * в процентах). Обратите внимание, что первый параметр функции round
 * должен иметь тип numeric.
 * Для этого достаточно привести к типу numeric только первый
 * компонент выражения.
*/

SELECT delay,
       count(*),
       round(count(*)::NUMERIC /
             (SELECT count(*) FROM short_delays) ----общее число коротких задержек
                 * 100, 2) AS PERCENT
FROM short_delays
GROUP BY delay
ORDER BY delay;


/*Создадим представление выбирающее длинные задержки рейсов*/
CREATE VIEW long_delays AS
SELECT (actual_departure - scheduled_departure) AS delay
FROM flights_v
WHERE actual_departure > scheduled_departure + INTERVAL '1hour';

SELECT *
FROM long_delays


WITH stats AS (SELECT count(*)                                                      as total_count,
                      min(delay)                                                    AS minimal_delay,
                      max(delay)                                                    AS maximal_delay,
                      avg(delay)                                                    AS average_delay,
                      round(var_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2)    AS variance,
                      round(stddev_pop(EXTRACT(epoch FROM delay) / 60)::NUMERIC, 2) AS standart_deviation,
                      mode() WITHIN GROUP (ORDER BY delay)                          as mode_delay,
                      percentile_disc(0.5) WITHIN GROUP (ORDER BY delay)            AS median
               FROM long_delays)
SELECT unnest(ARRAY [
    'Общее количество',
    'Минимальная задержка',
    'Максимальная задержка',
    'Средняя задержка',
    'Дисперсия',
    'Стандартное отклонение',
    'Мода',
    'Медиана'
    ])        as metric,
       unnest(ARRAY [
           total_count::text,
           minimal_delay::text,
           maximal_delay::text,
           average_delay::text,
           variance::text,
           standart_deviation::text,
           mode_delay::text,
           median::text
           ]) as value
FROM stats;

/*Grouping SETS, CUBE, ROLLUP
 * Предположим, что служба ремонта нашей авикаомпании
 * запросила информацию о количестве маршрутов, обслуживаемых
 * самолетами разных моделей в каждом аэропорту.
 * При этом требуется получить и общее число маршрутов, обслуживаемых
 * самолетами каждой модели.
 * Отчет необходимо представить в таком виде:
 *
 * Абакан
 * Всего по а.п
 * Новосибирск
 * Всего по а.п.
 * ИТОГО
 * Для получения ответов на эти вопросы можно с помощью
 * оператора union all объединить 4 запроса с группировкой
 */

EXPLAIN ANALYZE
SELECT r.departure_airport_name AS airport,
       a.model,
       count(*)                 AS routes_count
--- количество маршрутов
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY airport,
         model
UNION ALL

SELECT r.departure_airport_name AS airport,
       NULL                     AS model,
       count(*)                 AS routes_count
--- количество маршрутов
FROM routes r
GROUP BY airport
UNION ALL

SELECT NULL     AS airport,
       a.model,
       count(*) AS routes_count
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY a.model

UNION ALL

SELECT NULL     AS airprot,
       NULL     AS model,
       count(*) AS routes_count
FROM routes
ORDER BY airport,
         routes_count,
         model;



WITH detailed_stats AS (SELECT r.departure_airport_name AS airport,
                               a.model                  AS model,
                               COUNT(*)                 AS routes_count,
                               0                        as sort_order -- для обычных записей
                        FROM routes r
                                 JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
                        GROUP BY r.departure_airport_name, a.model),
     airport_summary AS (SELECT r.departure_airport_name                      AS airport,
                                '↳ Итого по а/п ' || r.departure_airport_name AS model,
                                COUNT(*)                                      AS routes_count,
                                1                                             as sort_order -- для итогов по аэропортам
                         FROM routes r
                         GROUP BY r.departure_airport_name),
     model_summary AS (SELECT 'ИТОГИ ПО МОДЕЛЯМ' AS airport,
                              a.model            AS model,
                              COUNT(*)           AS routes_count,
                              2                  as sort_order -- для итогов по моделям
                       FROM routes r
                                JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
                       GROUP BY a.model),
     final_summary AS (SELECT 'ОБЩИЙ ИТОГ'                          AS airport,
                              'Всего маршрутов: ' || COUNT(*)::text AS model,
                              COUNT(*)                              AS routes_count,
                              3                                     as sort_order -- для общего итога
                       FROM routes)
-- Объединяем все с сортировкой
SELECT airport,
       model,
       routes_count
FROM (SELECT *
      FROM detailed_stats
      UNION ALL
      SELECT *
      FROM airport_summary
      UNION ALL
      SELECT *
      FROM model_summary
      UNION ALL
      SELECT *
      FROM final_summary) combined_data
ORDER BY sort_order,
         CASE WHEN sort_order = 0 THEN airport END,
         CASE WHEN sort_order = 0 THEN model END,
         routes_count DESC;

/*Если sort_order = 0 (детальные данные) → сортируем по airport
Если sort_order ≠ 0 (итоги) → возвращает NULL → не влияет на сортировку
sort_order=0: сортируются как: АэропортA, АэропортB, АэропортC...
sort_order=1,2,3: остаются в порядке sort_order (не сортируются между собой по airport)

Если sort_order = 0 → сортируем по model
Если sort_order ≠ 0 → возвращает NULL
Якутск:
  - Airbus A320-200
  - Boeing 737-300   ← отсортировано по model
*/


WITH hierarchical_stats AS (SELECT COALESCE(r.departure_airport_name, 'ИТОГО') AS airport,
                                   CASE
                                       WHEN r.departure_airport_name IS NULL AND a.model IS NULL THEN 'ОБЩИЙ ИТОГ'
                                       WHEN r.departure_airport_name IS NOT NULL AND a.model IS NULL
                                           THEN 'Итого по а/п ' || r.departure_airport_name
                                       ELSE a.model
                                       END                                     AS model,
                                   COUNT(*)                                    AS routes_count
                            FROM routes r
                                     JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
                            GROUP BY ROLLUP (r.departure_airport_name, a.model))
SELECT airport,
       model,
       routes_count
FROM hierarchical_stats
ORDER BY CASE
             WHEN airport = 'ИТОГО' AND model = 'ОБЩИЙ ИТОГ' THEN 3
             WHEN airport != 'ИТОГО' AND model LIKE 'Итого по а/п%' THEN 2
             WHEN airport = 'ИТОГО' AND model != 'ОБЩИЙ ИТОГ' THEN 1
             ELSE 0
             END,
         airport,
         model;

/*Можно ли ускорить данный запрос, да, конечно для эоого нужно прибуегнуть к конструкции
 * grouping sets, она позволяет выполнить несколько группировок в рамках одного запроса,
 * а затем объединить их результаты аналогично инструкции union all. Таким образом,
 * выражения для группировки, использованные в трех подзапросах включаются в
 * инструкцию gruuping sets, в четверотом подзапросе группировка выполняется для всей
 * выборки, для такого случая в grщuping sets предусмотерно выражение (), то есть пустые скобки*/

---EXPLAIN ANALYZE;
SELECT CASE
           WHEN r.departure_airport_name IS NULL AND a.model IS NULL
               THEN 'ИТОГО:'
           WHEN a.model IS NULL
               THEN 'Всего по а/п: ' || r.departure_airport_name
           WHEN r.departure_airport_name IS NULL
               THEN 'Всего по мод/самолета'
           ELSE r.departure_airport_name
           END  AS airport,
       a.model,
---GROUPING(r.departure_airport_name, a.model) AS GROUPING,
       count(*) AS routes_count
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY
    GROUPING SETS
    ( (r.departure_airport_name, a.model), -- детальные данные
      (r.departure_airport_name),          -- итоги по аэропортам
      (a.model),                           -- итоги по самолетам
    ()                                     -- общий итог
    )
ORDER BY departure_airport_name,
         routes_count,
         a.model;

/*Группировка с помощью rollup
	 *
	 * для вуз типичных ситуаций существуют сокращенные варианты записи конструкции
	 * GROUPING SETS это ROLLUP и CUBE
	 *
	 * rollup(a,b,c...) равнозначна записи
	 *
	 * grouping sets ((a,b,c)
	 * ...
	 * (a,b),
	 * (a),
	 * ()
	 * )
	 * Динамика авиабилетов с разбиением по дням, дкадам и месяцам,
	 * необходимо отражать как сумму бронирований так и количество бронирований
	 * уточним что третья декада может иметь длительность от 8 до 11 дней в
	 * зависимости от месяца
	 *
	 *
*/

EXPLAIN ANALYZE
SELECT EXTRACT(MONTH FROM book_date) AS MONTH,
       CASE
           WHEN EXTRACT(DAY FROM book_date) <= 10 THEN 1
           WHEN EXTRACT(DAY
                        FROM
                        book_date) <= 20 THEN 2
           ELSE 3
           END                       AS ten_days,
       EXTRACT(DAY FROM book_date)   AS DAY,
       count(*)                      AS book_num,
       round(sum(total_amount), 2)   AS amount
FROM bookings
GROUP BY
    ROLLUP (MONTH,
            ten_days,
            DAY)
ORDER BY MONTH,
         ten_days,
         DAY;

---SHOW timezone


SELECT CASE
           WHEN year_num IS NULL THEN '📊 ОБЩИЙ ИТОГ ЗА ВСЕ ГОДЫ'
           WHEN month_num IS NULL THEN '📈 ИТОГО ЗА ' || year_num::TEXT || ' ГОД'
           ELSE year_num::TEXT || ' год - ' ||
                CASE month_num
                    WHEN 1 THEN 'Январь'
                    WHEN 2 THEN 'Февраль'
                    WHEN 3 THEN 'Март'
                    WHEN 4 THEN 'Апрель'
                    WHEN 5 THEN 'Май'
                    WHEN 6 THEN 'Июнь'
                    WHEN 7 THEN 'Июль'
                    WHEN 8 THEN 'Август'
                    WHEN 9 THEN 'Сентябрь'
                    WHEN 10 THEN 'Октябрь'
                    WHEN 11 THEN 'Ноябрь'
                    WHEN 12 THEN 'Декабрь'
                    END
           END                     AS период,

       CASE
           WHEN year_num IS NULL THEN '---'
           WHEN month_num IS NULL THEN '---'
           WHEN decade_num IS NULL THEN '✅ ИТОГО ЗА МЕСЯЦ'
           WHEN decade_num = 1 THEN '1-я декада (1-10 числа)'
           WHEN decade_num = 2 THEN '2-я декада (11-20 числа)'
           WHEN decade_num = 3 THEN '3-я декада (21-31 числа)'
           END                     AS декада,

       CASE
           WHEN year_num IS NULL THEN '---'
           WHEN month_num IS NULL THEN '---'
           WHEN decade_num IS NULL THEN '---'
           WHEN day_num IS NULL THEN '📋 Итог за декаду'
           ELSE day_num::TEXT || ' число'
           END                     AS день,

       count(*)                    AS количество_бронирований,
       round(sum(total_amount), 2) AS общая_сумма,
       round(avg(total_amount), 2) AS средний_чек

FROM (SELECT book_date,
             total_amount,
             EXTRACT(YEAR FROM book_date)  AS year_num,
             EXTRACT(MONTH FROM book_date) AS month_num,
             CASE
                 WHEN EXTRACT(DAY FROM book_date) <= 10 THEN 1
                 WHEN EXTRACT(DAY FROM book_date) <= 20 THEN 2
                 ELSE 3
                 END                       AS decade_num,
             EXTRACT(DAY FROM book_date)   AS day_num
      FROM bookings) подготовленные_данные

GROUP BY ROLLUP (year_num, month_num, decade_num, day_num)

ORDER BY CASE WHEN year_num IS NULL THEN 9999 ELSE year_num END,
         CASE WHEN month_num IS NULL THEN 999 ELSE month_num END,
         CASE WHEN decade_num IS NULL THEN 999 ELSE decade_num END,
         CASE WHEN day_num IS NULL THEN 999 ELSE day_num END;

/*Группировка с помощью cube
 * cube (a,b,c)
 *
 * аналог grouping sets
 * grouping sets
 * (
 * (a,b,c),
 * (a,b  ),
 * (a  ,c),
 * (a    ),
 * (  b,c),
 * (  b  ),
 * (    c),
 * (     )
 * )
 * Обратите внимаение, что для каждого подмножества, содержащего более одногшо столбца, приводится
 * только один варинат записи этого подмножества.
 * Это объясняется тем, что в множестве элементы упорядочены.
 * Поэтому если есть комбинация с,a , то комбинация c,a уже не нужна.
 * Это будет корректно работать в рамках запроса, поскольку в предложении Group by порядок
 * следования выражений не важен!!!
 *
CUBE создает 2ⁿ комбинаций (где n - количество столбцов):
Для CUBE(отдел, должность):
(отдел, должность) - детальные данные
(отдел) - итоги по отделам
(должность) - итоги по должностям
() - общий итог
 *
 */

SELECT r.departure_airport                                                                   AS da,
       r.arrival_airport                                                                     AS aa,
       a.model,
       left(tf.fare_conditions, 1)                                                           AS fc, ---Берет указанное количество символов с начала строки
       count(*),
       round(sum(tf.amount), 2)                                                              AS t_amount,
       GROUPING(r.departure_airport, r.arrival_airport, a.model, tf.fare_conditions)::bit(4) AS mask,
       concat_ws(',',
                 CASE WHEN GROUPING(r.departure_airport) = 0 THEN 'da' END,
                 CASE WHEN GROUPING(r.arrival_airport) = 0 THEN 'aa' END,
                 CASE WHEN GROUPING(a.model) = 0 THEN 'm' END,
                 CASE WHEN GROUPING(tf.fare_conditions) = 0 THEN 'fc' END
       )                                                                                     AS grouped_cols
FROM routes r
         JOIN flights f ON f.flight_no = r.flight_no
         JOIN ticket_flights tf ON tf.flight_id = f.flight_id
         JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY CUBE ( (da, aa),
                a.model,
                tf.fare_conditions
    )
ORDER BY da, aa, a.model, fc;

/*Оконные функции
 * Оконные функции имеют много общего с агрегатными, но между ними есть и приципиальные различия
 * При обычном агрегировании каждая группа строк, формируемая в соответствии с предложением GROUP BY,
 * заменяется одной строкой.
 *
 * Но при сипользовании оконных функций сохраняются все индивидульные строки
 * Вызовы оконных функций допускаются только в предложении SELECT(в списке вывода) и
 * в предложении order by команды Select.
 * Во всех остальных предложениях этой команды, включая WHERE, GROUP BY и HAVING, их вызвать нельзя,
 * поскольку оконные функции логически выполняются после обработки этих предложений!!!
 * Таким образом, если в предложении SELECT присутствует предложение  GROUP BY и возможно HAVING,
 * то оконные функции имеют дело с уже сгруппированными строками.
 *
 * Если в запросе присутствуют и агрегатные функции, и оконные, то оконные вызываются после
 * агрегатных.
 * Поэтому в принципе можно включить вызов агрегатной функции в качестве параметра оконной функции,
 * а вот поступить наоборот нельзя.
 *
 * В технологии оконных фунций базовым является понятие раздела (partition). Раздел включает в себя
 * все строки, имеющие одинаковые значения определенного выражения, вычисляемого для каждой
 * строки их выборки.
 * Это может быть например значение одного или нескольких столбцов или значение какой-либо
 * функции.
 * Разделы определяются предложением PARTITION BY в конструкции OVER.
 *
 * В процессе обработки раздела каждая его строка поочередно помещается, образно говоря, в
 * фокус внимания; для нее некоторым образом определяются связанные с ней строки, которые
 * и учитываются при при вычисления оконной функции.
 * Такая строка считается текущей, а связанные с ней строки образуют ее оконный кадр (window frame).
 * Это второе базовое понятие технологии оконных функций. Существует целый ряд способов задания
 * оконного кадра.
 *
 * Если в конструкции OVER присутствует предложение ORDER BY, определяющее порядок сортировки, то
 * это будут строки раздела, начиная с первой и заканчивая текущей!!!
 * Бывают ситуации, когда кадр не завершается на текущей строке, а включает в себя еще одну
 * или более строк, располагающихся в выбоки после текущей строки.
 * Это происходит, когда значения выражения сортировки этих строк и текущей строки совпадают.
 * Такие строки нахываются родственными (peer).
 *
 * Если же предложения ORDER BY в конструкции  OVER отсутствует, то оконный кадр
 * текущей строки образует все строки раздела, в котором эта строка находится, поскольку
 * все они будут считаться родственными.
 * Таким образом, оконная функция получает доступ ко всем строкам оконного кадра текущей строки,
 * но при этом не заменяет все эти строки одной строкой.
 *
 * Предположим что в нашей авикомпании проводится оптимизация расписания. Руководство обратило
 * внимание на маршрут Москва - Санкт-Петербург, по которому следуют несколько рейсов.
 * Цель исследования: выяснить, какая доля пассажиров, перевезенных за день,
 * приходится на каждый из этих рейсов. Для получения информативной картины необходимо
 * вывести результаты по каждой дате отдельно, а не в виде единого показателя за весь
 * отчетный период.
 * В Запрос включим все сведения представленные в базе данных Авиаперевозки
 * за период с 16 ибля по 15 августа 2017 года. Кроме того, будем учитывать только
 * выполненные рейсы со статусом Arrived
 *
 * Списки аэропортов представлены в виде литералов, это сделано с целью упрощения запроса.
 * Однако при использовани и этих конструкций выполнение запроса значительно замедляется, поскольку
 * планировщик неверно определяет количество аэропортов и выбирает метод вложенного цикла для
 * выполнения соединения наборов строк. В качестве однрой из идей можно прибегнуть
 * к материализации требуемых рейсов в общем табличном выражении предложение MATERIALIZED.
 */


EXPLAIN VERBOSE
WITH passenger AS (SELECT f.scheduled_departure,
                          f.flight_no,
                          count(*) AS pass_count
                   FROM flights f
                            JOIN ticket_flights tf ON f.flight_id = tf.flight_id
                   WHERE f.departure_airport IN ('DME', 'SVO', 'VKO')
                     AND f.arrival_airport = 'LED' ---Пулково
                     AND f.status = 'Arrived'
                   GROUP BY f.flight_id--можно заменить вместо  потому как f.scheduled_departure,f.flight_no зависят от
---первичного ключа
),

     passenger2 AS
         (SELECT scheduled_departure,
                 flight_no,
                 pass_count,
                 sum(pass_count) OVER (PARTITION BY date_trunc('day', scheduled_departure)) AS day_pass_count
          ----это значение вычисляется однократно, чтобы в общем запросе не писать два раза
----оконную функцию
          FROM passenger)

/*
SELECT
scheduled_departure,
flight_no,
pass_count,
day_pass_count,
/*Нет order by поэтому для всего раздела будет один итог за выбранный день
 * Функция sum вызывается не для каждой строки, а одни раз для каждого
 * раздела, затем выисленное значение используется в списке Select для
 * всех строк раздела, поэтому значения в столбце day_pass_count повторяются для
 * всех строк за один день*/
round(pass_count / day_pass_count,2) AS fract
/*прописывем sum(pass_count) потому как нельзя сослаться на псевдоним столбца, вычисляемого
 * в этом же списке Select*/
FROM passenger2
ORDER BY scheduled_departure,flight_no
*/

/*Рассмотренный пример можно модифицировать следующим образом
 * вызов оконной функции будет выполняться дважды но при этом
 * объявление раздела указывается один раз в WINDOW
 *
 * Здесь мы получили картину распределения числа пассажиров между
 * каждыми рейсами каждго дня. Видны рейсы лидеры и рейсы аутсайдеры.
*/

SELECT scheduled_departure,
       flight_no,
       pass_count,
       sum(pass_count) OVER day_flights_win                        AS day_pass_count,
       round(pass_count / sum(pass_count) OVER day_flights_win, 2) AS fract
FROM passenger
WINDOW day_flights_win AS (PARTITION BY date_trunc('day', scheduled_departure))
ORDER BY fract DESC, scheduled_departure ASC, flight_no ASC


/*Однако для принятия обоснованного решения о сокращении числа рейсов необходимо
 * проанализировать динамику перевозки пассажиров по каждому рейсу за каждую
 * неделю отчетного периода. Если известно, что рейс считается рентабельным при
 * перевозке за неделю не мнее определенного числа пассажиров, такая информация
 * позволит увидеть начиная с какого дня недели рейс начинает приносить прибыль
 * Также необходимо попытаться увидеть другие закономерности, ведь возможно,
 * какой-нибудь вечерний рейс наиболее  популярен у пасажиров вылетающих в пятницу,
 * а какой-то утренний рейс у пассажиров, вылетающих в субботу
 *
 *
 * Номер рейса в совокупности с номером недели определяют текущий раздел.
 * Поскольку строки в разделе обрабатываются в порядке номеров дней недели,
 * то оконная функция sum подсчитвает накопленное число пассажиров, перевезенных на
 * конкретном рейсе с начала отчетной недели.
 *
 *Здесь разделы формируются по рейсу и неделе, а в каждом разделе представлены все дни
 *конкретной недели.
 *Порядок сортировки в предложении order by  в коснтрукции over  необязан совпадать с порядком сортировки
 *на уровне всего запроса.
 *
 *Предположим что рейса считается нерентабельным, если на нем перевозятся не менее 500 пассажиров
 *в неделю. Исходя из этого критерия можно сказать что рейс PG0227 на 29 неделе календарного года 2017
 *приносит прибыль начиная с пятницы 21 июля.
 *
 **/
WITH passenger AS (SELECT f.scheduled_departure,
                          f.flight_no,
                          count(*) AS pass_count
                   FROM flights f
                            JOIN ticket_flights tf ON f.flight_id = tf.flight_id
                   WHERE f.departure_airport IN ('DME', 'SVO', 'VKO')
                     AND f.arrival_airport = 'LED' ---Пулково
                     AND f.status = 'Arrived'
                   GROUP BY f.flight_id--можно заменить вместо  потому как f.scheduled_departure,f.flight_no зависят от
---первичного ключа
)


SELECT flight_no,
       scheduled_departure,
       extract(week FROM scheduled_departure)   AS week,
       extract(isodow FROM scheduled_departure) AS dow,
/*Понедельник = 1
Вторник = 2
Среда = 3
Четверг = 4
Пятница = 5
Суббота = 6
Воскресенье = 7*/
       pass_count,
       sum(pass_count) OVER day_flights_win     AS running_count
FROM passenger
WINDOW day_flights_win AS (PARTITION BY flight_no, EXTRACT(week from scheduled_departure)
        ORDER BY EXTRACT(isodow FROM scheduled_departure))
ORDER BY flight_no, week, dow
--также и псевдонимы вычичляемых столбцов списка Select

/*Способы формирования оконного кадра!!!
 *
 *
Тип	Работает с	Пример
ROWS	Физическими строками	ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
RANGE	Значениями	RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING
GROUPS	Группами одинаковых значений	GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
 *
 * Специфика конкретной задачи определяет множество строк раздела, которые необходимо учитывать при
 * вычилении оконной функции для каждой строк выборки.
 * Например может потребоваться принимать во внимание все строки раздела, начиная с первой и заканчивая текущей
 * строкой или учитывать только строку раздела, отстоящую от текщуей на заданное число строк!!!
 * Множество строк, рассматриваемых оконной функцией, задается оконным кадром с помощью
 * специальных синтаксических средств.
 *
 * В качестве примера рассмотрим фрагмент сложной задачи финасвого положения нашей авиакомпании
 * Мы ограничимся лишь изучением процесса поступления денег за счет продажи авиабилетов!!!
 * Будем исходить из того, что равномерное ежедневное поступление денежных средств является
 * хорошим показателем стабильной работы авиакомпании.
 *
 * Для начала рассмотрим так называемое скользящее среднее.
 * Этот показатель отличается от обычного среднего значения тем, что вычисляется
 * в каждой точке выборки на основе значений некотрого интервала от текущей точки в прошлое.
 * Скользящее среднее показывает более четкую картину, потому что оно сглаживает краткосрочные
 * колебания и показывает основной тренд.
 * Для определения равномерности поступления денег от бронирования юилетов мы вычисляем
 * разность между дневной суммой бронирования и скользящим средним значением,
 * вычисленным для этого же дня.
 * Для наглядности представим ее еще и в процентах.
 * Чем меньше эта разность, тем более равномерным является поступление.
 *
 * */

---EXPLAIN ANALYZE
WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date),
                 round((sum(total_amount) / 1000000), 2)
          FROM bookings
          GROUP BY date_trunc('day', book_date))

SELECT to_char(b_date, 'YYYY-MM-DD')                                      AS date,
       day_sum,
       round(avg(day_sum) OVER moving_win, 2)                             AS mv_avg_5,
       round(day_sum - avg(day_sum) OVER moving_win, 2)                   AS delta,
       round((day_sum - avg(day_sum) OVER moving_win) / day_sum * 100, 2) AS percent
FROM day_amounts
WINDOW moving_win AS (
        ORDER BY b_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
        )
ORDER BY date

/*В конструкции with мы выполняем подготовительную работу вычисялем суммы бронирований,
 * выполненных за кажду дату. При этом суммы будем представлять в миллионах рублей.
 * В предложении Window отсуствует предложение partiton by, поэтому разделом будет служить
 * вся выборка.
 * Интервал сглаживания для вычисления скользяшего среднего примем равным
 * пяти дням.
 * Конечно он может быть и другим если его выбор будет каким-то образом обоснован.
 * Поскольку этот интервал отсчитвается от текущего момента времени назад в прошлое!!!, то
 * в качестве оконного кадра текущей строки должны выступать сама эта строка!!! и еще четыре
 * строки, предшествующие ей в порядке сортировки, указанном в предложении order by
 *
 * Выполнение этого требования обеспечивает конструкция ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
 * Она определяет множество строк, составляющих оконный кадр, путем указания его начала (4 Preceding)
 * и конца (Current Row).
 * В Выражении 4 preceding целое число 4 означает смещение первой строки оконного кадра от
 * текущей строки к началу раздела.
 *
 *В рассматриваемой конструкции требует пояснения ключевое слово ROWS. Оно задает так называемый режим
 *формирования кадра. В этом режиме current row означает только текущую строку, а родственные строки
 *не учитываются.
 *Аналогично и выражение 4 preceding означает ровно четыре строки, предшествующие текущей строке,
 *также без учета родственных строк. Но в нашшем случае формируется одна строка, поэтому родственных строк
 *вообще не существует.
 *Как видим в начале отчетного периоа отклонения текущей дневной выручки от значения скользящего
 *среднего были велики а затем они перестали первышать 5-6%.
 *При интепретации нужно учитывать, что границы оконного кадра не могут выходить за пределы раздела.
 *Поэтому при вычислении скользящего среднего для каждой из первых трех строк выборки
 *оконный кадр будет состоять не из пяти строк, а из меньшего количества.
 *Так в составе оконного кадра для первой строки окажется только сама эта строка,
 *для второй строки первая и вторая строк и т.д. Поэтому для первой строки значения в столбцах
 *delta и percent равны нулю.
 *
 *Есть еще варианты оконных кадров:
 *ROWS BETWEEN CURRENT ROW AND 4 FOLLOWING - оконный кадр начинается на текущей строке, а завершается
 *на строке, смещенной от текущей к концу раздела на заданное число строк.
 *RANGE и GROUPS - в них также как и в режиме ROWS, оконный кадр определяется своим началом и концом.
 *При использовании RANGE сортировка строк раздела должна выполняться только по одному столбцу.
 *Смещение задается макисмальной разностью значений этого столбца в текущей строке и в той строке,
 *на которой должен начинаться или заканчиваться оконный кадр. Если в выборке есть родственные строки
 *то при поиске начала окнного кадра используется первая строка из группы этих строк,
 *а при поиске его конца - последняя из них.
 *Заметьте также, что если например вычитание интервала равного 4 дням из даты 2017-07-06 дает
 *дату 2017-07-02, а данной даты нет в выборке данных, то в таком случае началом кадра
 *будет наименьшая дата из выборки, превышающая эту расчетную дату то есть 2017-07-03.
 *
 *При использовании режима GROUPS начало и конец кадра задаются в терминах групп родственных строк.
 *Например, в выражении 4 PRECENDING целое число 4 означало бы, что первая группа оконного кадра
 *расположена в выборке со смещением к началу раздела на 4 группы от текущей группы (к которой относится
 *текущая строка). Но поскольку группы состоят зи строк, когда говорят о первой группе оконного кадра,
 *то имеют вввиду первую строку из этой группы, а когда говорят о последней группе этого кадра,
 *то имеют ввиду последнюю строку из этой группы.
 *
 *
 */

--SHOW timezone
--SET timezone = 'Asia/Krasnoyarsk'


/*range*/
WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date),
                 round((sum(total_amount) / 1000000), 2)
          FROM bookings
          GROUP BY date_trunc('day', book_date))

SELECT to_char(b_date, 'YYYY-MM-DD')                                      AS date,
       day_sum,
       round(avg(day_sum) OVER moving_win, 2)                             AS mv_avg_5,
       round(day_sum - avg(day_sum) OVER moving_win, 2)                   AS delta,
       round((day_sum - avg(day_sum) OVER moving_win) / day_sum * 100, 2) AS percent
FROM day_amounts
WINDOW moving_win AS (
        ORDER BY b_date RANGE BETWEEN INTERVAL '4 days' PRECEDING AND CURRENT ROW
        )
ORDER BY date



/*С GROUPS*/

---1. GROUPS BETWEEN N PRECEDING AND M FOLLOWING
-- Сумма текущей группы + 1 предыдущая группа + 1 следующая группа
SELECT department,
       salary,
       SUM(salary) OVER (
           ORDER BY department
           GROUPS BETWEEN 1 PRECEDING AND 1 FOLLOWING
           ) as sum_3_groups
FROM employees;

---2.GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
-- Накопление по группам
SELECT department,
       salary,
       SUM(salary) OVER (
           ORDER BY department
           GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
           ) as cumulative_by_groups
FROM employees;


---3. GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
-- Обратное накопление
SELECT department,
       salary,
       SUM(salary) OVER (
           ORDER BY department
           GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
           ) as remaining_total
FROM employees;

/*
GROUPS полезен когда:
Нужно анализировать группы одинаковых значений
Работаете с категориальными данными
Хотите сравнивать группы, а не отдельные строки
EXCLUDE полезен когда:
Нужно убрать влияние текущего наблюдения
Исключить дубликаты из расчетов
Сравнивать значение с "остальными"
GROUPS и EXCLUDE - это продвинутые инструменты для сложной аналитики в PostgreSQL!
*/

WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date),
                 round((sum(total_amount) / 1000000), 2)
          FROM bookings
          GROUP BY date_trunc('day', book_date))

SELECT to_char(b_date, 'YYYY-MM-DD')                                      AS date,
       day_sum,
       round(avg(day_sum) OVER moving_win, 2)                             AS mv_avg_5,
       round(day_sum - avg(day_sum) OVER moving_win, 2)                   AS delta,
       round((day_sum - avg(day_sum) OVER moving_win) / day_sum * 100, 2) AS percent
FROM day_amounts
WINDOW moving_win AS (
        ORDER BY b_date GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW
        )
ORDER BY date


---1. PARTITION BY - Разделение на группы
-- Разделяем по предметам
SELECT ученик,
       предмет,
       оценка,
       AVG(оценка) OVER (PARTITION BY предмет) as средняя_по_предмету
FROM журнал;

Ученик | Предмет    | Оценка | Средняя_по_предмету
-------+------------+--------+--------------------
Аня    | Математика | 5      | 4.0    ← (5+4+3)/3 = 4.0
Боря   | Математика | 4      | 4.0    ← смотрим ТОЛЬКО математику
Вова   | Математика | 3      | 4.0    ←
Аня    | Физика     | 4      | 4.5    ← (4+5)/2 = 4.5
Боря   | Физика     | 5      | 4.5    ← смотрим ТОЛЬКО физику

--2. ORDER BY - Сортировка внутри окна

-- Накопительная сумма оценок по предметам
SELECT ученик,
       предмет,
       оценка,
       SUM(оценка) OVER (
           PARTITION BY предмет
           ORDER BY оценка DESC
           ) as накопленная_сумма
FROM журнал;

Ученик | Предмет    | Оценка | Накопленная_сумма
-------+------------+--------+------------------
Аня    | Математика | 5      | 5    ← 5
Боря   | Математика | 4      | 9    ← 5+4
Вова   | Математика | 3      | 12   ← 5+4+3
Аня    | Физика     | 5      | 5    ← 5
Боря   | Физика     | 4      | 9    ← 5+4

/*Совместное использование оконных и агрегатных функций
 *
 * Из документации известно, что при использовании в одном запросе как оконных,
 * так и агрегатных функций с предложением GROUP BY и возможно HAVING оконные
 * функции работают с уже сгруппированными строками.
 *
 * Предположим, что требуется оценить нагрузку на электронную систему
 * бронирования авиабилетов в выходные дни (субботу и воскресенье) по
 * сравнению с рабочими днями. В каждой операци бронирования может
 * оформляться несколько билетов, при этом в каждом билете может присутствовать
 * несколько перелетов, каждый из которых требует использования ресурсов системы.
 * Таким образом, в качестве меры загруженности системы бронирования логично
 * использовать число перелетов, оформленных в ней за один день.
 *
 * Идея запроса такова:
 * 1.Для каждой отчетной недели подсчитать среднее число перелетов,
 * оформленных за пять рабочих дней.
 *
 * 2.Сравнить п. 1 с числом перелетов, оформленных  в выходные дни.
 * Поскольку в таблице Передлеты ticket_flights нет информации о дате
 * бронирования, придется обратиться к таблице Бронирования bookings. Связать эти
 * две таблицы можно через таблицу Билеты tickets.
 */


SELECT to_char(date_trunc('day', b.book_date), 'YYYY-MM-DD') AS b_date,
       EXTRACT(week FROM b.book_date)                        AS week,
       extract(isodow FROM b.book_date)                      AS dow,
       count(*)                                              AS day_tf_count,

       CASE
           WHEN EXTRACT(isodow FROM b.book_date) BETWEEN 1 AND 5 THEN
               round(avg(count(*))
                     FILTER (WHERE EXTRACT(isodow FROM b.book_date) BETWEEN 1 AND 5)
                         OVER week_win, 0)
           END                                               AS avg_5_days,

       -- ТОЛЬКО для выходных показываем значение, для остальных - NULL
       CASE
           WHEN EXTRACT(isodow FROM b.book_date) IN (6, 7) THEN
               round(avg(count(*))
                     FILTER (WHERE EXTRACT(isodow FROM b.book_date) IN (6, 7))
                         OVER week_win, 0)
           END                                               AS avg_67

FROM bookings b
         JOIN tickets t ON t.book_ref = b.book_ref
         JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no
GROUP BY b_date, week, dow
WINDOW week_win AS (PARTITION BY EXTRACT(week FROM b.book_date))
---order by нет, значит выступают все строки раздела
ORDER BY b_date;

---предложение фильтр могут принимать только агрегирующие оконные функции, такие
---как например avg в данном запросе. А вот оконные функции общего назначения
---эти свойством не обладают.


/*Функции общего назначения
 *
 * first_value, last_value, nth_value.
 *
 * Первая из них возвращает первое значение окна оконного кадрая, вторая функция возвращает последнее
 * значения окна оконного кадра, а третья функция для n-ой строки оконного кадра!!!
 *
 * В качестве примера обратимя к оценке равномерности поступления денег за счет продажи авиабилетов.
 * Для каждой даты будем выислять разности между общей суммой бронирования, произведенных в этот день
 * и суммами бронирований, полученными в первый день месяца, в поеследний день месяца и день месяца,
 * являющегося его серединой.
 * Будем считать, что если для всех дат теущего месяца три эти разности окажутся небольшими, то
 * это в какой-то степени говорит о равномерном поступлении денег от продажи билетов насчет
 * авиакомпании.
 *
 * Сначала представим запрос, решающий поставленную задачу, а затем приведем его описание.
 * В псевдонимах столбцов d_fv, d_lv, d_nv буква d означает delta, то есть разность.
 */

WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date),
                 round(sum(total_amount) / 1000000, 2) ---сумма в миллионах рублей
          FROM bookings
          GROUP BY 1),

     days_per_month(month, days_count) AS
         (SELECT EXTRACT('mon' FROM b_date),
                 count(*)::integer
          FROM day_amounts
          GROUP BY 1),

     day_amounts_2 AS
         (SELECT to_char(da.b_date, 'YYYY-MM-DD')       AS date,
                 da.day_sum,
                 first_value(da.day_sum) OVER month_win AS fv,
                 last_value(da.day_sum) OVER month_win  AS lv,
                 nth_value(
                 da.day_sum,
                 (SELECT days_count FROM days_per_month WHERE month = EXTRACT('mon' FROM da.b_date)) / 2
                          ) OVER month_win              AS nv

          FROM day_amounts da
          WINDOW month_win AS
                     (
                             PARTITION BY EXTRACT('mon' FROM da.b_date)
                             ORDER BY da.b_date
                             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                             ))

/*
 * WINDOW month_win AS
(
    PARTITION BY EXTRACT('mon' FROM b_date)   -- 🎯 Разделение
    ORDER BY b_date                           -- 🔄 Сортировка
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- 📏 Фрейм
)
 * b_date     | day_sum | Месяц
-----------+---------+-------
2024-01-01 | 15.25   | 1
2024-01-02 | 18.50   | 1
2024-01-31 | 22.10   | 1
2024-02-01 | 12.00   | 2
2024-02-28 | 25.00   | 2

ОКНО 1 (Январь):
[2024-01-01: 15.25]
[2024-01-02: 18.50]
[2024-01-31: 22.10]

ОКНО 2 (Февраль):
[2024-02-01: 12.00] [2024-02-28: 25.00]


ORDER BY b_date  -- Сортируем по дате внутри каждого окна

ОКНО 1 (Январь):
[01.01: 15.25]
[02.01: 18.50]
[31.01: 22.10]

ОКНО 2 (Февраль):
[01.02: 12.00]
[28.02: 25.00]

ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING

Для строки [02.01: 18.50] в январе:
Фрейм = [01.01: 15.25] ← [02.01: 18.50] → [31.01: 22.10]
         ↑                    ↑                  ↑
UNBOUNDED PRECEDING       CURRENT ROW    UNBOUNDED FOLLOWING


first_value(day_sum) OVER month_win
Ищет в КАЖДОМ окне первую строку
Для января: всегда возвращает 15.25 (01.01)
Для февраля: всегда возвращает 12.00 (01.02)


last_value(day_sum) OVER month_win
Ищет в КАЖДОМ окне последнюю строку
Для января: всегда возвращает 22.10 (31.01)
Для февраля: всегда возвращает 25.00 (28.02)
 *
 *
 *
 *
 *
 *
 *
 *
 * */

SELECT date,
       day_sum,
       fv,
       lv,
       nv,
       day_sum - fv AS d_fv,
       day_sum - lv AS l_fv,
       day_sum - nv AS d_nv
FROM day_amounts_2
ORDER BY date desc;

/*Функции lag и lead
 * Для анализа динамиики изменений можно сравнивать значение этого показателя с его значением за предыдущий период,
 * например за тот же месяц прошлого года.
 * Будем сравнивать сумму полных стоимостей бронирований, оформленных в текущий день, с суммами полученными в тот же
 * день неделю назад!!!
 *
 * При сортировке строк раздела по убыванию дат функция lead выдаст желаемый результат, поскольку возвратится
 * значение суммы, соответстветвующее меньшей дате.
 *Не задаем в окне partition by потому как в качестве раздела участвует вся выборка
 */

WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date)          AS b_date,
                 round(sum(total_amount) / 1000000, 2) AS day_sum
          FROM bookings
          GROUP BY b_date)

SELECT to_char(b_date, 'YYYY-MM-DD')                AS date,
       extract(isodow FROM b_date)                  AS dow,      ----день недели
       day_sum,
       lead(day_sum, 7) OVER all_rows_win           AS week_ago, ---неделю назад от текущей вычисляемой даты
       day_sum - lead(day_sum, 7) OVER all_rows_win AS delta     ---разница между суммами фактической и неделю назад
FROM day_amounts
WINDOW all_rows_win AS (ORDER BY b_date DESC)
ORDER BY b_date DESC
;



WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date)          AS b_date,
                 round(sum(total_amount) / 1000000, 2) AS day_sum
          FROM bookings
          GROUP BY b_date)

SELECT to_char(b_date, 'YYYY-MM-DD')               AS date,
       extract(isodow FROM b_date)                 AS dow,      ----день недели
       day_sum,
       lag(day_sum, 7) OVER all_rows_win           AS week_ago, ---неделю назад от текущей вычисляемой даты
       day_sum - lag(day_sum, 7) OVER all_rows_win AS delta     ---разница между суммами фактической и неделю назад
FROM day_amounts
WINDOW all_rows_win AS (ORDER BY b_date)
ORDER BY b_date DESC
;

/*Остальные оконные функции*/

WITH aircrafts_plus AS
         (SELECT aircraft_code, model, range
          FROM aircrafts
          UNION ALL
          VALUES ('T20', 'Туполев Ту-204', 6700))

SELECT aircraft_code                                         AS ac,
       model,
       "range",
       row_number() OVER all_rows_win                        AS rn,
       rank() OVER all_rows_win                              AS r,
       dense_rank() OVER all_rows_win                        AS dr,
       cume_dist() OVER all_rows_win                         AS cd,
       round((percent_rank() OVER all_rows_win)::NUMERIC, 2) AS pr,
       ntile(4) OVER all_rows_win                            AS nt4,
       ntile(3) OVER all_rows_win                            AS nt3,
       ntile(5) OVER all_rows_win                            AS nt5
FROM aircrafts_plus
WINDOW all_rows_win AS (ORDER BY "range" desc)
ORDER BY rn;


/*Битовые строки тоже можно агрегировать
 * Раздел 3.1. Агрегатные функции*
 *
 * Модели самолетов можно дополнительно охарактеризовать несколькими показателями(сервисами),
 * каждый из которых может либо присутсвовать, либо отсутствовать у конкретной модели.
 * Таким образом, показатели могут иметь истинное или ложное значение
 * Для решения задачи воспользуемся типом данных bit, а конкретно bit(5), потому что
 * у нас есть 5 показателей
 * Каждая позиция в битовой строке будет отвечать за конкретный показатель.
 * Функция bit_and формирует битовую строку, в которой единицы означают, что сервис доступен
 * на всех моделях самолетов. Единицы в битовой строкое, сформированной функцией bit_or, означают,
 * что сервис доступен хотя бы для одной модели.
 * В главном запросе формируются дополнительные показатели: сервисы, которыми оборудованы не все
 * модели и те которыми не оборудована ни одна из них.
 */

WITH all_facilities(faciliti_code, faciliti_name) AS
         (VALUES (B'00001', 'система развлечений'),
                 (B'00010', 'перевозка животных'),
                 (B'00100', 'usb-розетки'),
                 (B'01000', 'теплые пледы'),
                 (B'10000', 'WI-FI в полете')),

     aircrafts_equipment(aircraft_code, facilities) AS
         (VALUES ('SU9', B'01110'),
                 ('320', B'01110'),
                 ('773', B'01111'),
                 ('CN', B'01000')),

     aggregates AS
         (SELECT bit_and(facilities::bit(5)) AS all_equipped,
                 bit_or(facilities::bit(5))  AS at_least_one_equipped
          FROM aircrafts_equipment),

     finals AS (SELECT all_equipped,
                       ~all_equipped          AS not_all_equipped, --- все кроме, ~ побитовый оператор NOT (инверсия битов)
                       at_least_one_equipped,
                       ~at_least_one_equipped AS no_one_equipped   --- кроме,~ побитовый оператор NOT (инверсия битов)
                FROM aggregates)

SELECT *
FROM finals AS f
         JOIN all_facilities AS af ON (af.faciliti_code & f.all_equipped)::int > 0;



WITH all_facilities AS (SELECT faciliti_code::bit(5), faciliti_name
                        FROM (VALUES ('00001', 'система развлечений'),
                                     ('00010', 'перевозка животных'),
                                     ('00100', 'usb-розетки'),
                                     ('01000', 'теплые пледы'),
                                     ('10000', 'WI-FI в полете')) AS t(faciliti_code, faciliti_name)),

     aircrafts_equipment AS (SELECT aircraft_code, facilities::bit(5)
                             FROM (VALUES ('SU9', '01110'),
                                          ('320', '01110'),
                                          ('773', '01111'),
                                          ('CN', '01000')) AS t(aircraft_code, facilities)),

     aggregates AS (SELECT bit_and(facilities) AS all_equipped,
                           bit_or(facilities)  AS at_least_one_equipped
                    FROM aircrafts_equipment),

     categories AS
         (SELECT 1 as sort_order, 'все модели' as agg_name, all_equipped as mask
          FROM aggregates
          UNION ALL
          SELECT 2, 'не все', ~all_equipped
          FROM aggregates
          UNION ALL
          SELECT 3, 'ни одной', ~at_least_one_equipped
          FROM aggregates
          UNION ALL
          SELECT 4, 'хотя бы одна', at_least_one_equipped
          FROM aggregates)

SELECT c.agg_name,
       STRING_AGG(af.faciliti_name, ', ' ORDER BY af.faciliti_code) as facilities
FROM categories c
         JOIN all_facilities af ON (af.faciliti_code & c.mask) != B'00000'::bit(5)
GROUP BY c.sort_order, c.agg_name
ORDER BY c.sort_order;

/*Битовые строки тоже можно агрегировать
 * Функция xor может использоваться для вычислений контрольной суммы неупорядоченного набора значений.
 *Практические рекомендации
Когда использовать BIT_XOR:
-Для быстрой проверки на массовые изменения
-В комбинации с подсчетом строк
-Для нефункциональных данных
Когда НЕ использовать BIT_XOR:
-Для аудита безопасности
-Для финансовых данных
-При высоких требованиях к целостности
 *-- Использование CRC
SELECT SUM(CRC32(CONCAT(id, name, email))) as total_crc FROM users;
Плюсы:
-Обнаруживает большинство случайных ошибок
-Хорошо обнаруживает изменения в отдельных битах
-Быстрее криптографических хешей
Минусы:
-Возможны коллизии
-Не криптографически стойкий

Сравнительная таблица методов
Метод	     Битность	Скорость	     Надежность	    Использование
HASHTEXT	    32	    ⭐⭐⭐⭐⭐	            ⭐⭐	       Быстрая проверка
HASHEXTENDED	64	    ⭐⭐⭐⭐	            ⭐⭐⭐	   Баланс скорость/надежность
MD5	            128	    ⭐⭐⭐	            ⭐⭐⭐⭐	   Надежная проверка
SHA256	        256	    ⭐⭐	                ⭐⭐⭐⭐⭐	   Криптографическая
BIT_XOR	      32/64	    ⭐⭐⭐⭐⭐	            ⭐	       Быстрая, но ненадежная

 */


SELECT bit_xor(a."range") AS check_sum
FROM aircrafts a

SELECT distinct HASHTEXT(a."range"::text) AS check_sum
FROM aircrafts a
ORDER BY HASHTEXT(a."range"::text)


/*Агрегирование в параллельном режиме
 * Мы рассматривали выполнение запросов с агрегатными функциями в параллельном режиме.
 * Однако в том случае, когда предполагается что формируемых групп будет относительно
 * много (их число равно числу исходных строк), то планировщик может отказаться от создания
 * параллельного плана.
 */

EXPLAIN (costs OFF )
SELECT flight_id,
       count(*)
FROM boarding_passes
GROUP BY flight_id


EXPLAIN (costs OFF )
SELECT flight_id,
       boarding_no,
       count(*)
FROM boarding_passes
GROUP BY flight_id, boarding_no


SELECT name, setting, context
FROM pg_settings
WHERE name LIKE '%parallel%';


---Найти конфиг Postgrrsql SHOW config_file
----SELECT pg_reload_conf();

/*Агрегирование числовых данных, содержащихся в формате json */

WITH aircrafts_tmp AS
         (SELECT *,
                 row_to_json(aircrafts)::jsonb AS info
          FROM aircrafts)

SELECT max(range),
       min(range),
       max(info ->> 'range')                  AS max_json,
       min(info ->> 'range')                  AS max_json,
       max((info ->> 'range')::integer)       AS max_json_numeric,
       min((info ->> 'range')::integer)       AS min_json_numeric,
       max(CAST(info ->> 'range' AS integer)) AS max_json_numeric_cast
FROM aircrafts_tmp

         /*
max(info ->>'range') AS max_json,  -- TEXT → TEXT (лексикографическая сортировка)
min(info ->>'range') AS max_json   -- TEXT → TEXT (лексикографическая сортировка)
*/


/*Как первичный ключ влияет на выбор группируемых столбцов?*/
         EXPLAIN ANALYZE
SELECT a.aircraft_code,
       a.model  AS model,
       a."range",
       count(*) AS seats_num
FROM aircrafts a
         join seats s ON s.aircraft_code = a.aircraft_code
GROUP BY a.aircraft_code, a.model, a."range"
ORDER BY seats_num DESC

EXPLAIN ANALYZE
SELECT a.aircraft_code,
       a.model ->> lang() AS model,
       a."range",
       count(*)           AS seats_num
FROM aircrafts_data a
         join seats s ON s.aircraft_code = a.aircraft_code
GROUP BY a.aircraft_code ---, a.model, a."range" ---a.aircraft_code
ORDER BY seats_num DESC


EXPLAIN ANALYZE
SELECT a.aircraft_code,
       a.model,
       a."range",
       count(*) AS seats_num
FROM aircrafts_data a
         join seats s ON s.aircraft_code = a.aircraft_code
GROUP BY a.aircraft_code ---, a.model, a."range" ---a.aircraft_code
ORDER BY seats_num DESC


EXPLAIN ANALYZE
SELECT a.aircraft_code,
       a.model  AS model,
       a."range",
       count(*) AS seats_num
FROM aircrafts_view2 a
         join seats s ON s.aircraft_code = a.aircraft_code
GROUP BY a.aircraft_code, a.model, a."range"
ORDER BY seats_num DESC

/*Аргумент массив функции можно сгенерировать
 *
 * Чтобы вычислить с шагом в 5%, хотелось бы иметь способ генерирования
 * этого массива, избавляющий нас от ручного ввода всех значений,
 * и такой способ есть ARRAY в сочетании с функцией
 * generate_series
 */

WITH percentiles AS
         (SELECT PERCENTILE_DISC(
                 ARRAY(SELECT generate_series(0.05, 1.0, 0.05)) ---Преобразует результат в массив: {0.05, 0.10, 0.15, ..., 1.0}
                                )
                 WITHIN GROUP (ORDER BY delay) AS percentiles ---Указывает, как упорядочить данные перед вычислением перцентилей.
          ---Сортирует строки по столбцу delay по возрастанию.
          FROM short_delays)

/*
Для каждого значения в массиве [0.05, 0.10, ..., 1.00] функция:
Сортирует все значения delay по возрастанию
Вычисляет позицию в отсортированном массиве: position = percentile * (N - 1) + 1
Возвращает значение на этой позиции (округляет вверх)
*/

SELECT generate_series(0.05, 1.0, 0.05) AS level,
       unnest(percentiles)              AS percentile ---функция, которая "разворачивает" массив в набор строк:
FROM percentiles


/*Вычислим описательные статистики -- для всего множества
**Минимальное значение - наименьшее значение в наборе данных. Показывает нижнюю границу диапазона. Чувствительно к выбросам.
**Максимальное значение - наибольшее значение в наборе данных. Показывает верхнюю границу диапазона. Чувствительно к выбросам.
**Среднее значение (среднее арифметическое) - сумма всех значений, деленная на их количество. Центр "тяжести" данных. Сильно подвержено влиянию выбросов.
**Медиана - значение, которое делит упорядоченный набор данных пополам. 50% значений лежат ниже медианы, 50% - выше. Устойчива к выбросам.
**Дисперсия - средний квадрат отклонений значений от среднего. Покажает разброс данных вокруг среднего значения. Чем больше дисперсия, тем сильнее разбросаны данные.
**Среднеквадратическое отклонение (стандартное отклонение)** - квадратный корень из дисперсии. Измеряется в тех же единицах, что и исходные данные. Показывает типичное отклонение значения от среднего.
 */

SELECT count(*),
       min(total_amount),
       max(total_amount),
       percentile_disc(0.5) WITHIN GROUP (ORDER BY total_amount) AS median,
       round(avg(total_amount), 2)                               AS average,
       round(stddev_pop(total_amount), 2)                        AS stddev,
       round(var_pop(total_amount), 2)                           AS variance
FROM bookings EXPLAIN ANALYZE
WITH stats AS (SELECT count(*)                                                  as cnt,
                      min(total_amount)                                         as min_val,
                      max(total_amount)                                         as max_val,
                      percentile_disc(0.5) WITHIN GROUP (ORDER BY total_amount) as median_val,
                      round(avg(total_amount), 2)                               as avg_val,
                      round(stddev_pop(total_amount), 2)                        as stddev_val,
                      round(var_pop(total_amount), 2)                           as var_val
               FROM bookings)
SELECT metric, value
FROM stats
         CROSS JOIN LATERAL (
    VALUES ('count', cnt::text),
           ('min', min_val::text),
           ('max', max_val::text),
           ('median', median_val::text),
           ('average', avg_val::text),
           ('stddev', stddev_val::text),
           ('variance', var_val::text)
    ) AS t(metric, value);

/*Самый неээфективный запрос 7 проходов*/
EXPLAIN ANALYZE
SELECT m.metric,
       CASE m.metric
           WHEN 'count' THEN (SELECT count(*)::text FROM bookings)
           WHEN 'min' THEN (SELECT min(total_amount)::text FROM bookings)
           WHEN 'max' THEN (SELECT max(total_amount)::text FROM bookings)
           WHEN 'median' THEN (SELECT percentile_disc(0.5) WITHIN GROUP (ORDER BY total_amount)::text FROM bookings)
           WHEN 'average' THEN (SELECT round(avg(total_amount), 2)::text FROM bookings)
           WHEN 'stddev' THEN (SELECT round(stddev_pop(total_amount), 2)::text FROM bookings)
           WHEN 'variance' THEN (SELECT round(var_pop(total_amount), 2)::text FROM bookings)
           END as value
FROM (VALUES ('count'),
             ('min'),
             ('max'),
             ('median'),
             ('average'),
             ('stddev'),
             ('variance')) AS m(metric);


/*Самый эффективный запрос
BERNOULLI Выбирает случайную выборку из таблицы bookings
например можно указать значение 10% строк от общего количества (каждая строка с вероятностью 10%)
Все агрегатные функции вычисляются на этой выборке, а не на всей таблице
Гарантирует точный процент выборки


SYSTEM (сканирование на уровне блоков)
Как работает:
Выбирает случайные блоки/страницы данных
Если блок выбран - берутся ВСЕ строки в этом блоке
Быстрее, но может давать неравномерную выборку

count     : 262,788    -- полное количество бронирований
min       : 3,400.00   -- минимальная сумма
max       : 1,204,500.00 -- максимальная сумма
median    : 55,900.00  -- медианная сумма
average   : 79,025.61  -- средняя сумма
stddev    : 77,621.78  -- стандартное отклонение
variance  : 6,025,139,959.40 -- дисперсия

1. Сильное правостороннее распределение
text
Разница: Среднее (79,026) - Медиана (55,900) = 23,126
Интерпретация: Распределение сильно скошено вправо.
Наличие крупных бронирований существенно  "тянет" среднее значение вверх относительно медианы.

2. Очень высокий разброс данных
Коэффициент вариации = 77,622 / 79,026 ≈ 98%
Интерпретация: Чрезвычайно высокая вариативность. Суммы бронирований крайне неоднородны
- от очень маленьких до очень крупных.

3. Экстремальный разброс значений
Максимум в 354 раза больше минимума: 1,204,500 / 3,400 ≈ 354
Максимум в 21.5 раз больше медианы: 1,204,500 / 55,900 ≈ 21.5
Интерпретация: В данных присутствуют как очень мелкие, так и исключительно крупные транзакции.

4. Широкий диапазон типичных значений
Диапазон 68% данных (среднее ± stddev):
Нижняя граница: 79,026 - 77,622 = 1,404
Верхняя граница: 79,026 + 77,622 = 156,648
Интерпретация: Большинство бронирований (68%) находятся в диапазоне от 1,404 до 156,648.


Бизнес-интерпретация:
Структура клиентской базы:
-Массовый сегмент: суммы около медианы 55,900
-Премиальный сегмент: суммы значительно выше среднего
-Эконом сегмент: суммы ниже 20,000
-VIP сегмент: суммы свыше 200,000
Общий объем: ~262,788 × 79,026 ≈ 20.7 миллиардов
Вывод: Бизнес работает с значительными финансовыми объемами.


Сегментация клиентов:
Расчетные сегменты:
• Эконом: до 30,000 (≈35% клиентов)
• Стандарт: 30,000 - 80,000 (≈35% клиентов)
• Премиум: 80,000 - 300,000 (≈25% клиентов)
• VIP: свыше 300,000 (≈5% клиентов)

Распределение доходов (оценочное):
• Эконом сегмент: ~10% выручки
• Стандарт сегмент: ~30% выручки
• Премиум сегмент: ~40% выручки
• VIP сегмент: ~20% выручки

Возможности роста:
Развитие премиум-сегмента - наибольший потенциал маржинальности
Оптимизация портфеля - баланс между массовостью и премиализацией
Улучшение удержания VIP-клиентов

Рекомендации:
1. Сегментированный маркетинг:
Разные стратегии для каждого ценового сегмента
Персонализированные предложения для премиум и VIP клиентов
2. Управление рисками:
Диверсификация клиентской базы
Мониторинг концентрации крупных сделок
3. Оптимизация сервиса:
Разные уровни обслуживания для разных сегментов
Специализированные менеджеры для VIP-клиентов

Заключение:
Данные демонстрируют здоровую, но сложную структуру бизнеса с широким ценовым диапазоном.
Высокое стандартное отклонение указывает на необходимость сегментированного подхода.
Бизнес успешно сочетает массовость с премиальными услугами, что является оптимальной
стратегией для максимизации доходов при управляемых рисках.

Ключевой вывод: Успешная бизнес-модель, требующая тонкой настройки под разные
клиентские сегменты для дальнейшего роста.

Полные данные подтвердили основные выводы из выборки, но выявили более сложную структуру распределения.
Бизнес демонстрирует здоровую диверсификацию с сильным премиальным сегментом.
Критически важный инсайт: 25% клиентов (премиум+VIP) генерируют около 60% выручки,
что указывает на необходимость фокуса на удержании и развитии именно этого сегмента.
Рекомендуемая стратегия: Инвестировать в программы лояльности для премиальных
клиентов при сохранении массового сегмента, как источника стабильного cash flow.

*/
EXPLAIN ANALYZE
SELECT unnest(ARRAY [
    'count',
    'min',
    'max',
    'median',
    'average',
    'stddev',
    'variance'
    ])        as metric,

       unnest(ARRAY [
           count(*)::text,
           min(total_amount)::text,
           max(total_amount)::text,
           percentile_disc(0.5) WITHIN GROUP (ORDER BY total_amount)::text,
           round(avg(total_amount), 2)::text,
           round(stddev_pop(total_amount), 2)::text,
           round(var_pop(total_amount), 2)::text
           ]) as value
FROM bookings
----TABLESAMPLE BERNOULLI(1);

/*Попытайтесь объяснить разницу во времени выполнения в пользу запроса
 * с конструкцией GROUPING SETS вместо UNION

1. Первый запрос (UNION ALL) - "Наивный" подход
Структура выполнения:
text
Append
├── HashAggregate (GROUP BY airport, model)     -- 1-й подзапрос
│   └── Hash Join (routes × aircrafts)
├── HashAggregate (GROUP BY airport)            -- 2-й подзапрос
│   └── Seq Scan (routes)
├── HashAggregate (GROUP BY model)              -- 3-й подзапрос
│   └── Hash Join (routes × aircrafts)
└── Aggregate (COUNT без GROUP BY)              -- 4-й подзапрос
    └── Seq Scan (routes)

Проблемы производительности:
4 независимых сканирования таблицы routes
2 повторных JOIN с таблицей aircrafts
Дублирование вычислений - одни и те же агрегаты считаются многократно
Высокие накладные расходы на материализацию промежуточных результатов*/


SELECT r.departure_airport_name AS airport,
       a.model,
       count(*)                 AS routes_count
--- количество маршрутов
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY airport,
         model
UNION ALL

SELECT r.departure_airport_name AS airport,
       NULL                     AS model,
       count(*)                 AS routes_count
--- количество маршрутов
FROM routes r
GROUP BY airport
UNION ALL

SELECT NULL     AS airport,
       a.model,
       count(*) AS routes_count
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY a.model

UNION ALL

SELECT NULL     AS airprot,
       NULL     AS model,
       count(*) AS routes_count
FROM routes
ORDER BY airport,
         routes_count,
         model;


/*2. Второй запрос (GROUPING SETS) - Оптимизированный подход
Структура выполнения:
text
GroupAggregate
└── MixedAggregate
    └── Hash Join (routes × aircrafts)
        ├── Seq Scan (routes)
        └── Hash
            └── Seq Scan (aircrafts)

Преимущества:
Однократное сканирование таблиц
Однократный JOIN между routes и aircrafts
Параллельное вычисление всех уровней агрегации за один проход
Минимальные накладные расходы

*/

SELECT CASE
           WHEN r.departure_airport_name IS NULL AND a.model IS NULL
               THEN 'ИТОГО:'
           WHEN a.model IS NULL
               THEN 'Всего по а/п: ' || r.departure_airport_name
           ELSE r.departure_airport_name
           END  AS airport,
       a.model,
---GROUPING(r.departure_airport_name, a.model) AS GROUPING,
       count(*) AS routes_count
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY
    GROUPING SETS
    ( (r.departure_airport_name, a.model), -- детальные данные
      (r.departure_airport_name),          -- итоги по аэропортам
      (a.model),                           -- итоги по самолетам
    ()                                     -- общий итог
    )
ORDER BY departure_airport_name,
         routes_count,
         a.model;

/*Влияет ли порядок следования групп столбцов в конструкции
 * grouping sets на работу запроса
 * GROUPING SETS
(
    (a.model),                          -- Группа 1: только модели
    (r.departure_airport_name, a.model), -- Группа 2: аэропорт + модель
    (r.departure_airport_name),         -- Группа 3: только аэропорты
    ()                                  -- Группа 4: общий итог
)


Результаты могут измениться потому что, например, логика CASE не обрабатывает все
возможные комбинации NULL значений, возникающие при разных порядках GROUPING SETS.
Порядок групп влияет на то, какие строки будут неправильно обработаны
в CASE выражении.

Рекомендация: Используйте функцию GROUPING() для надежного определения уровня
агрегации или добавьте недостающие условия в CASE.
 *
 *
 */

SELECT CASE
           WHEN r.departure_airport_name IS NULL AND a.model IS NULL
               THEN 'ИТОГО:'
           WHEN r.departure_airport_name IS NULL
               THEN 'Всего по модели: '
           WHEN a.model IS NULL
               THEN 'Всего по а/п: ' || r.departure_airport_name
           ELSE r.departure_airport_name
           END  AS airport,
       a.model,
       count(*) AS routes_count
---GROUPING(r.departure_airport_name, a.model) AS GROUPING,
FROM routes r
         JOIN aircrafts a ON
    a.aircraft_code = r.aircraft_code
GROUP BY
    GROUPING SETS
    ( (a.model),
      (r.departure_airport_name, a.model),
      (r.departure_airport_name),
    ()
    )
ORDER BY departure_airport_name,
         routes_count,
         a.model;


/*
* GROUPING(column) - это битовая маска, которая показывает,
* был ли столбец агрегирован (свернут) в текущей строке результата.
* GROUPING() - это по сути "флажок", который показывает,
* свернут ли столбец в итоге или показывает детальные данные.
* GROUPING(столбец) = 1  ← столбец СВЕРНУТ (итог)
* GROUPING(столбец) = 0  ← столбец ДЕТАЛЬНЫЙ (в группировке)
*
* КАК ЧИТАТЬ GROUPING() в CASE:
* CASE
    -- Оба свернуты = ОБЩИЙ ИТОГ
    WHEN GROUPING(Магазин)=1 AND GROUPING(Товар)=1 THEN 'ОБЩИЙ ИТОГ'

    -- Товар свернут = ИТОГ ПО МАГАЗИНУ
    WHEN GROUPING(Товар)=1 THEN 'Итог по '   || Магазин

    -- Магазин свернут = ИТОГ ПО ТОВАРУ
    WHEN GROUPING(Магазин)=1 THEN 'Итог по ' || Товар

    -- Оба в группировке = ДЕТАЛЬНЫЕ ДАННЫЕ
    ELSE Магазин
END


* GROUPING(столбец)
              │
    ┌─────────┴─────────┐
    │                   │
   =0                  =1
    │                   │
┌─────────┐        ┌─────────┐
│СТОЛБЕЦ  │        │СТОЛБЕЦ  │
│В ГРУППЕ │        │СВЕРНУТ  │
│(детали) │        │(итог)   │
└─────────┘        └─────────┘


УРОВЕНЬ ГРУППИРОВКИ    GROUPING(Магазин)  GROUPING(Товар)  РЕЗУЛЬТАТ
─────────────────────────────────────────────────────────────────────
(Магазин, Товар)    →        0                 0         ← ДЕТАЛИ по каждому товару в каждом магазине
(Магазин)           →        0                 1         ← ИТОГ по магазинам (товары свернуты)
(Товар)             →        1                 0         ← ИТОГ по товарам (магазины свернуты)
()                  →        1                 1         ← ОБЩИЙ ИТОГ (все свернуто)
*
┌──────────┬──────────┬────────┐
│ Магазин  │ Товар    │ Продажи│
├──────────┼──────────┼────────┤
│ Маг1     │ Яблоки   │ 100    │
│ Маг1     │ Груши    │ 150    │
│ Маг2     │ Яблоки   │ 200    │
│ Маг2     │ Груши    │ 250    │
└──────────┴──────────┴────────┘
SELECT
    CASE
        WHEN GROUPING(Магазин) = 1 AND GROUPING(Товар) = 1 THEN 'ОБЩИЙ ИТОГ'
        WHEN GROUPING(Товар) = 1 THEN 'Итог по '   || Магазин
        WHEN GROUPING(Магазин) = 1 THEN 'Итог по ' || Товар
        ELSE Магазин
    END AS Отчет,
    Товар,
    SUM(Продажи) AS ВсегоПродаж
FROM продажи
GROUP BY GROUPING SETS (
    (Магазин, Товар),  -- детальные данные
    (Магазин),         -- итоги по магазинам
    (Товар),           -- итоги по товарам
    ()                 -- общий итог
)

Как работает grouping:
┌─────────────────────────────────────────────────┐
│ GROUPING(Магазин)=0, GROUPING(Товар)=0          │
│ (оба столбца в группировке - ДЕТАЛИ)            │
├──────────┬──────────┬────────┬──────────────────┤
│ Отчет    │ Товар    │ Продажи│ Пояснение        │
├──────────┼──────────┼────────┼──────────────────┤
│ Маг1     │ Яблоки   │ 100    │ Оба = 0 → Детали │
│ Маг1     │ Груши    │ 150    │ Оба = 0 → Детали │
│ Маг2     │ Яблоки   │ 200    │ Оба = 0 → Детали │
│ Маг2     │ Груши    │ 250    │ Оба = 0 → Детали │
└──────────┴──────────┴────────┴──────────────────┘

┌─────────────────────────────────────────────────┐
│ GROUPING(Магазин)=0, GROUPING(Товар)=1          │
│ (магазин в группировке, товар СВЕРНУТ)          │
├──────────┬──────────┬────────┬──────────────────┤
│ Отчет    │ Товар    │ Продажи│ Пояснение        │
├──────────┼──────────┼────────┼──────────────────┤
│ Итог по  │ NULL     │ 250    │ Товар=1 → Итог   │
│ Маг1     │          │        │ по магазину      │
│ Итог по  │ NULL     │ 450    │ Товар=1 → Итог   │
│ Маг2     │          │        │ по магазину      │
└──────────┴──────────┴────────┴──────────────────┘

┌─────────────────────────────────────────────────┐
│ GROUPING(Магазин)=1, GROUPING(Товар)=0          │
│ (магазин СВЕРНУТ, товар в группировке)          │
├──────────┬──────────┬────────┬──────────────────┤
│ Отчет    │ Товар    │ Продажи│ Пояснение        │
├──────────┼──────────┼────────┼──────────────────┤
│ Итог по  │ Яблоки   │ 300    │ Магазин=1 → Итог │
│ Яблоки   │          │        │ по товару        │
│ Итог по  │ Груши    │ 400    │ Магазин=1 → Итог │
│ Груши    │          │        │ по товару        │
└──────────┴──────────┴────────┴──────────────────┘

┌─────────────────────────────────────────────────┐
│ GROUPING(Магазин)=1, GROUPING(Товар)=1          │
│ (оба столбца СВЕРНУТЫ - ОБЩИЙ ИТОГ)             │
├──────────┬──────────┬────────┬──────────────────┤
│ Отчет    │ Товар    │ Продажи│ Пояснение        │
├──────────┼──────────┼────────┼──────────────────┤
│ ОБЩИЙ    │ NULL     │ 700    │ Оба=1 → Общий    │
│ ИТОГ     │          │        │ итог             │
└──────────┴──────────┴────────┴──────────────────┘

┌──────────────┬──────────┬────────┬──────────────────┐
│    Отчет     │ Товар    │ Продажи│ Уровень GROUPING │
├──────────────┼──────────┼────────┼──────────────────┤
│ Маг1         │ Яблоки   │ 100    │ (0,0) - Детали   │
│ Маг1         │ Груши    │ 150    │ (0,0) - Детали   │
│ Маг2         │ Яблоки   │ 200    │ (0,0) - Детали   │
│ Маг2         │ Груши    │ 250    │ (0,0) - Детали   │
│ Итог по Маг1 │ NULL     │ 250    │ (0,1) - Магазин  │
│ Итог по Маг2 │ NULL     │ 450    │ (0,1) - Магазин  │
│ Итог по Яблок│ Яблоки   │ 300    │ (1,0) - Товар    │
│ Итог по Груши│ Груши    │ 400    │ (1,0) - Товар    │
│ ОБЩИЙ ИТОГ   │ NULL     │ 700    │ (1,1) - Общий    │
└──────────────┴──────────┴────────┴──────────────────┘

ПРАВИЛЬНЫЙ ПОРЯДОК УСЛОВИЙ:
Сначала - самые специфичные условия (оба GROUPING = 1)
Потом - остальные специфичные условия
В конце - общие условия
          ┌─────────────────────────────────┐
          │ ДЛЯ ОБЩЕГО ИТОГА:               │
          │ GROUPING(airport)=1, model=1    │
          └─────────────────────────────────┘
                      ↓
    ┌─────────────────────────────────────┐
    │ УСЛОВИЕ 1: airport=0 AND model=0    │
    │       1=0 AND 1=0 = FALSE ❌        │
    └─────────────────────────────────────┘
                      ↓
    ┌─────────────────────────────────────┐
    │ УСЛОВИЕ 2: airport=1                │
    │            1=1 = TRUE ✅            │ ← ОСТАНАВЛИВАЕМСЯ ЗДЕСЬ!
    │    ВОЗВРАЩАЕМ: 'Всего по модели: '  │
    └─────────────────────────────────────┘
                      ↓
    ┌─────────────────────────────────────┐
    │ УСЛОВИЕ 3: model=1                  │ ← НИКОГДА НЕ ДОЙДЕМ СЮДА!
    │ УСЛОВИЕ 4: airport=1 AND model=1    │ ← НИКОГДА НЕ ДОЙДЕМ СЮДА!
    └─────────────────────────────────────┘

if airport==1 and model==1:    # условие 1 ← сначала самое специфичное
    return "ИТОГО"
elif airport==0 and model==0:  # условие 2
    return "Детали"
elif airport==1:               # условие 3
    return "Всего по модели"
elif model==1:                 # условие 4
    return "Всего по а/п"

 */

EXPLAIN ANALYZE
SELECT CASE
           -- СНАЧАЛА проверяем ОБЩИЙ ИТОГ (оба = 1)
           WHEN GROUPING(r.departure_airport_name) = 1 AND GROUPING(a.model) = 1
               THEN 'ИТОГО:'

           -- ПОТОМ проверяем детальные данные (оба = 0)
           WHEN GROUPING(r.departure_airport_name) = 0 AND GROUPING(a.model) = 0
               THEN 'Детальные записи: ' || r.departure_airport_name

           -- ПОТОМ проверяем итоги по моделям (airport = 1)
           WHEN GROUPING(r.departure_airport_name) = 1
               THEN 'Всего по модели: ' || a.model

           -- В САМОМ КОНЦЕ проверяем итоги по аэропортам (model = 1)
           WHEN GROUPING(a.model) = 1
               THEN 'Всего по а/п: ' || r.departure_airport_name
           END  AS airport,

       CASE
           WHEN GROUPING(r.departure_airport_name) = 0 AND GROUPING(a.model) = 0
               THEN a.model -- только для детальных строк
           ELSE NULL -- для всех итоговых строк = NULL
           END  AS model,

       count(*) AS routes_count

FROM routes r
         JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY GROUPING SETS
    ( (r.departure_airport_name, a.model),
      (a.model),
      (r.departure_airport_name),
    ()
    )
ORDER BY departure_airport_name, a.model, routes_count;

/*Конструкция ROLLUP и ее отражение в плане запроса
 * Создать иерархический отчет о бронированиях с итогами по:
 * Дням → Декадам → Месяцам → Общий итог

ROLLUP создает иерархию итогов:
(month, ten_days, day) - детальные данные по дням
(month, ten_days) - итоги по декадам
(month) - итоги по месяцам
() - общий итог
 */
EXPLAIN ANALYZE
SELECT EXTRACT(MONTH FROM book_date) AS MONTH,
       CASE
           WHEN EXTRACT(DAY FROM book_date) <= 10 THEN 1
           WHEN EXTRACT(DAY FROM book_date) <= 20 THEN 2
           ELSE 3
           END                       AS ten_days,
       EXTRACT(DAY FROM book_date)   AS DAY,
       count(*)                      AS book_num,
       round(sum(total_amount), 2)   AS amount
FROM bookings
GROUP BY
    ROLLUP (month,
            ten_days,
            day)
ORDER BY month,
         ten_days,
         day;



explain analyze
SELECT CASE
           WHEN day IS NULL AND ten_days IS NULL AND month IS NULL THEN 'ОБЩИЙ ИТОГ'
           WHEN day IS NULL AND ten_days IS NULL THEN 'ИТОГ по месяцу ' || month
           WHEN day IS NULL THEN 'ИТОГ по декаде ' || month || '-' || ten_days
           ELSE 'День ' || month || '-' || ten_days || '-' || day
           END AS period_description,

       month,
       ten_days,
       day,
       book_num,
       amount
FROM (SELECT EXTRACT(MONTH FROM book_date) AS MONTH,
             CASE
                 WHEN EXTRACT(DAY FROM book_date) <= 10 THEN 1
                 WHEN EXTRACT(DAY FROM book_date) <= 20 THEN 2
                 ELSE 3
                 END                       AS ten_days,
             EXTRACT(DAY FROM book_date)   AS DAY,
             count(*)                      AS book_num,
             round(sum(total_amount), 2)   AS amount
      FROM bookings
      GROUP BY
          ROLLUP (month,
                  ten_days,
                  day)) AS aggregated_data
ORDER BY month DESC,
         ten_days DESC,
         day DESC;

----ВАЖНО !!!!
EXPLAIN ANALYZE
SELECT MAX(CASE WHEN fare_conditions = 'Economy' THEN count END)  AS Economy,
       MAX(CASE WHEN fare_conditions = 'Comfort' THEN count END)  AS Comfort,
       MAX(CASE WHEN fare_conditions = 'Business' THEN count END) AS Business
FROM counts;

EXPLAIN ANALYZE
SELECT MAX(count) FILTER (WHERE fare_conditions = 'Economy')  AS Economy,
       MAX(count) FILTER (WHERE fare_conditions = 'Comfort')  AS Comfort,
       MAX(count) FILTER (WHERE fare_conditions = 'Business') AS Business
FROM counts;


/*Тот же запрос, но намного быстрее быдет выполняться за счет
 * сканирования только индекса
Почему "Index Only Scan Backward" так эффективен:
Index Only - данные берутся только из индекса, не нужно обращаться к таблице
Backward - обратное сканирование сразу дает MAX значение
Partial Index - индекс содержит только нужные строки (Economy/Comfort/Business)
Итог: Частичные индексы превращают задачу поиска MAX из O(n) в O(1) для каждого класса обслуживания!

*1. Index Only Scan Backward
PostgreSQL сканирует индекс в обратном порядке
Первая запись = максимальное значение
Всего 1 операция чтения на каждый класс
2. Частичные индексы экономят:
Место на диске - только нужные строки
Время построения - меньше данных для индексации
Время обслуживания - быстрее перестроение
*
**/
CREATE INDEX CONCURRENTLY idx_counts_economy ON counts (count) WHERE fare_conditions = 'Economy';
CREATE INDEX CONCURRENTLY idx_counts_comfort ON counts (count) WHERE fare_conditions = 'Comfort';
CREATE INDEX CONCURRENTLY idx_counts_business ON counts (count) WHERE fare_conditions = 'Business';

-- Запрос использует индексы
---VACUUM FULL counts
-- Обновляем статистику
---ANALYZE counts;


EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
WITH count_t AS (SELECT (SELECT MAX(count) FROM counts WHERE fare_conditions = 'Economy')  AS Economy,
                        (SELECT MAX(count) FROM counts WHERE fare_conditions = 'Comfort')  AS Comfort,
                        (SELECT MAX(count) FROM counts WHERE fare_conditions = 'Business') AS Business)

SELECT *
FROM count_t


/*
┌──────────┐
│ unnest   │
├──────────┤
│ Economy  │
│ Comfort  │
│ Business │
└──────────┘
row_id = это "группировочный ключ" который говорит crosstab:
"Эти данные относятся к одной строке результата"
"Сгруппируй их вместе и создай одну выходную строку"
В вашем случае: поскольку у вас только одна группа данных (все максимумы),
используем row_id = 1 для всех строк.
либо можно с VALUES ('Economy'), ('Comfort'), ('Business')


crosstab(
    'исходный_запрос',      -- первый параметр (ОБЯЗАТЕЛЬНЫЙ)
    'запрос_категорий'      -- второй параметр (ОПЦИОНАЛЬНЫЙ)
) AS ct(
    имя_столбца1 тип,      -- определение структуры результата
    имя_столбца2 тип,
)

*/

         EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT economy, comfort, business
FROM crosstab(
             $$
    SELECT
        1,
        fare_conditions,
        MAX(count)::int as max_value
    FROM counts
    GROUP BY fare_conditions$$
         ---- $$select unnest(ARRAY['Economy', 'Comfort', 'Business'])$$
         ----либо можно с VALUES ('Economy'), ('Comfort'), ('Business')
     ) AS ct(
             row_id int,
             Economy int,
             Comfort int,
             Business int
    );


/*Конструкция CUBE,предложение HAVING и функция GROUPING*/


SELECT r.departure_airport                                                                   AS da,
       GROUPING(r.departure_airport)                                                         AS da_g,
       r.arrival_airport                                                                     AS aa,
       GROUPING(r.arrival_airport)                                                           AS aa_g,
       a.model,
       GROUPING(a.model)                                                                     AS m_g,
       left(tf.fare_conditions, 1)                                                           AS fc,  ---LEFT(строка, количество_символов)
---tf.fare_conditions AS fc,
       GROUPING(tf.fare_conditions)                                                          AS fc_g,---Берет указанное количество символов с начала строки
       count(*),
       round(sum(tf.amount), 2)                                                              AS t_amount,
       GROUPING(r.departure_airport, r.arrival_airport, a.model, tf.fare_conditions)::bit(4) AS mask,
       concat_ws(',',
                 CASE WHEN GROUPING(r.departure_airport) = 0 THEN 'da' END,
                 CASE WHEN GROUPING(r.arrival_airport) = 0 THEN 'aa' END,
                 CASE WHEN GROUPING(a.model) = 0 THEN 'm' END,
                 CASE WHEN GROUPING(tf.fare_conditions) = 0 THEN 'fc' END
       )                                                                                     AS grouped_cols
FROM routes r
         JOIN flights f ON f.flight_no = r.flight_no
         JOIN ticket_flights tf ON tf.flight_id = f.flight_id
         JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY CUBE ( (da, aa),
                a.model,
                tf.fare_conditions
---fc
    )
/*Выбираем только итоги по классам обслуживания*/
HAVING tf.fare_conditions IS NOT NULL
   AND r.departure_airport IS NULL
   AND r.arrival_airport IS NULL
   AND a.model IS NULL
ORDER BY da, aa, a.model, fc;


/*Тот же самы запрос с подитогами класса обслуживания
 * Функция grouping возвращает целое число, но можно его
 * преобразовать в битовую маску для удобства сравнения значений.
 * Важно учитывать, что возвращаемое значение зависит от порядка
 * следования имен столбцов, являющихся аргументами функции!!!
 * Этот порядок не обязан совпадать с порядком в предложении group by.
 * Возможно, более улобным
 *
 */
SELECT r.departure_airport                                                                   AS da,
       GROUPING(r.departure_airport)                                                         AS da_g,
       r.arrival_airport                                                                     AS aa,
       GROUPING(r.arrival_airport)                                                           AS aa_g,
       a.model,
       GROUPING(a.model)                                                                     AS m_g,
       left(tf.fare_conditions, 1)                                                           AS fc,  ---LEFT(строка, количество_символов)
---tf.fare_conditions AS fc,
       GROUPING(tf.fare_conditions)                                                          AS fc_g,---Берет указанное количество символов с начала строки
       count(*),
       round(sum(tf.amount), 2)                                                              AS t_amount,
       GROUPING(tf.fare_conditions, r.departure_airport, r.arrival_airport, a.model)::bit(4) AS mask,
       concat_ws(',',
                 CASE WHEN GROUPING(r.departure_airport) = 0 THEN 'da' END,
                 CASE WHEN GROUPING(r.arrival_airport) = 0 THEN 'aa' END,
                 CASE WHEN GROUPING(a.model) = 0 THEN 'm' END,
                 CASE WHEN GROUPING(tf.fare_conditions) = 0 THEN 'fc' END
       )                                                                                     AS grouped_cols
FROM routes r
         JOIN flights f ON f.flight_no = r.flight_no
         JOIN ticket_flights tf ON tf.flight_id = f.flight_id
         JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
GROUP BY CUBE ( (da, aa),
                a.model,
                tf.fare_conditions
---fc
    )
HAVING GROUPING(tf.fare_conditions,
                r.departure_airport,
                r.arrival_airport,
                a.model)::bit(4) = '0111'::bit(4)
ORDER BY da, aa, a.model, fc;

/*Оконная функция ORDER BY можно ли обойтись без нее ?
 *
Что делает: Это самая важная и необычная часть!
Здесь:
Для каждого самолета выполняется подзапрос, который считает количество мест
(SELECT count(*) FROM seats AS s WHERE s.aircraft_code = a.aircraft_code) - коррелированный подзапрос
ORDER BY ... DESC - сортировка самолетов по убыванию количества мест

ORDER BY rank() OVER(seats_win)
Что делает:
rank() OVER(seats_win) - присваивает ранг каждому самолету на основе определенного окна
ORDER BY rank() - сортирует результат по рангу
*
*Данны запрос выводит модели самолетов по убыванию числа кресел в салоне!!!
*
*/

EXPLAIN ANALYZE
SELECT aircraft_code, model, range
FROM aircrafts AS a
WINDOW seats_win AS
           (
---PARTITION BY
                   ORDER BY (SELECT count(*)
                             FROM seats AS s
                             WHERE s.aircraft_code = a.aircraft_code) DESC
                   )
ORDER BY rank() OVER (seats_win)

/*Недостатком вышеприведеннго запроса является то, что у него
 * отсутствует в выборке столбец содержащий число кресел, то есть того
 * показателя по которому идет ранжирование
 * SELECT aircraft_code,  -- 5. Выбор столбцов
       model,
       range,
       RANK() OVER(ORDER BY range DESC) as range_rank
FROM aircrafts          -- 1. Чтение таблицы
WHERE range > 3000      -- 2. Фильтрация строк
GROUP BY ...           -- 3. Группировка
HAVING ...             -- 4. Фильтрация групп
ORDER BY range_rank;   -- 6. Сортировка результатов

Сначала выполняется FROM aircrafts - читаются все строки
Затем WHERE фильтрует строки до вычисления оконных функций
Но range_rank еще не существует на этом этапе!
FROM → WHERE → GROUP BY → HAVING → ОКОННЫЕ ФУНКЦИИ
На этапе HAVING оконные функции еще не вычислены
*/
EXPLAIN ANALYZE
SELECT a.aircraft_code,
       a.model,
       a."range",
       count(*) AS seats_count
FROM aircrafts AS a
         JOIN seats AS s ON s.aircraft_code = a.aircraft_code
GROUP BY a.aircraft_code, a.model, a."range"
ORDER BY count(*) DESC;

EXPLAIN ANALYZE
WITH air AS (SELECT a.aircraft_code,
                    a.model,
                    a."range",
                    count(*) AS seats_count
             FROM aircrafts AS a
                      JOIN seats AS s ON s.aircraft_code = a.aircraft_code
             GROUP BY a.aircraft_code, a.model, a."range"
             ORDER BY count(*) DESC)
SELECT *
FROM air


         /*Порядок выполнения скрипта:
 * ПОРЯДОК ВЫПОЛНЕНИЯ:
1. FROM/JOIN       - чтение таблиц
2. WHERE           - фильтрация строк (оконные функции НЕДОСТУПНЫ)
3. GROUP BY        - группировка
4. HAVING          - фильтрация групп (оконные функции НЕДОСТУПНЫ)
5. SELECT          - вычисление выражений, включая оконные функции
6. ORDER BY        - сортировка (оконные функции ДОСТУПНЫ)
7. LIMIT/OFFSET    - ограничение результатов
*/


/*В запросе может быть несколько разных определений окна OVER
 * функции могут работать с окнами, имеющими разные определения
 *
 * Если нам нужно показать в одной выборке:
 * Упорядоченные модели самолетов как:
 * 1. То дальности полета;
 * 2. Так и по числу мест в салонах.
 * 3. Также разбить модели на группы - в зависиомсти от числа этих мест,
 * то одним из вариантов решения задачи может быть такой.
 */
         EXPLAIN ANALYZE
SELECT aircraft_code                             AS a_code,
       model,
       range,
       (SELECT count(*)
        FROM seats AS s
        WHERE s.aircraft_code = a.aircraft_code) AS seats_num,
---Для каждого самолета подсчитывает количество
---мест через коррелированный подзапрос.
       rank() over (range_win)                   AS r_rank,
       rank() OVER (seats_win)                   AS s_rank,
       ntile(4) OVER (seats_win)                 AS s_ntile
FROM aircrafts AS a
WINDOW range_win AS (ORDER BY range DESC), ---r_rank
       seats_win AS (ORDER BY (SELECT count(*)
                               FROM seats AS s
                               WHERE s.aircraft_code = a.aircraft_code) DESC ----s_rank ----s_ntile
               )
ORDER BY r_rank;

/*Недостатком явлляется то, что используется коррелированный подзапрос дважды
SELECT count(*) FROM seats AS s WHERE s.aircraft_code = a.aircraft_code
Коррелированный подзапрос = подзапрос, который выполняется для КАЖДОЙ
строки внешнего запроса и использует данные из этой строки.
Ключевые признаки коррелированного подзапроса:
Ссылается на таблицу из внешнего запроса
Выполняется для каждой строки
Использует псевдонимы внешних таблиц (a.aircraft_code)
Может быть медленным на больших данных

Перепишем запрос на CTE проверим план выполнения
**/


EXPLAIN ANALYZE
WITH seats_counts AS
         (SELECT aircraft_code                             AS a_code,
                 model,
                 range,
                 (SELECT count(*)
                  FROM seats AS s
                  WHERE s.aircraft_code = a.aircraft_code) AS seats_num
          FROM aircrafts AS a)


SELECT a_code,
       model,
       range,
       seats_num,
---Для каждого самолета подсчитывает количество
---мест через коррелированный подзапрос.
       rank() OVER (range_win)   AS r_rank,
       rank() OVER (seats_win)   AS s_rank,
       ntile(4) OVER (seats_win) AS s_ntile
FROM seats_counts
WINDOW range_win AS (ORDER BY range DESC), ----r_rank
       seats_win AS (ORDER BY seats_num DESC ----s_rank ----s_ntile
               )
ORDER BY r_rank;

/*Использование условия в определении раздела
 * средние значения, вычисленные для рабочих дней, выводились
 * в столбце avg_5_days и для выходных дней (в строках, где в столбце dow
 * стоят значения 6 и 7).
 * Аналогично средние значения, вычисленные для выходных
 * дней, выводились в столбце avg_67_days и для рабочих дней ( в тех строках,
 * где в столбце dow стоят значения от 1 до 5)
 *
 * Теперь значения в avg_5_days будут выводиться только в рабочих днях
 * А в avg_67_days будут выводиться значения только для выходных дней.
 * */

SELECT to_char(date_trunc('day', b.book_date), 'YYYY-MM-DD') AS b_date,
       EXTRACT(week FROM b.book_date)                        AS week,
       extract(isodow FROM b.book_date)                      AS dow,
       count(*)                                              AS day_tf_count,


       round(avg(count(*))
             FILTER (WHERE EXTRACT(isodow FROM b.book_date) BETWEEN 1 AND 5)
                 OVER week_win, 0)                           AS avg_5_days,

       -- ТОЛЬКО для выходных показываем значение, для остальных - NULL
       round(avg(count(*))
             FILTER (WHERE EXTRACT(isodow FROM b.book_date) IN (6, 7))
                 OVER week_win, 0)                           AS avg_67

FROM bookings b
         JOIN tickets t ON t.book_ref = b.book_ref
         JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no
GROUP BY b_date, week, dow
WINDOW week_win AS
           (PARTITION BY
               EXTRACT(week FROM b.book_date),
               EXTRACT(isodow FROM b.book_date) IN (6, 7)
                   )
---order by нет, значит выступают все строки раздела
ORDER BY b_date;

/*Функции lag и lead*/

WITH day_amounts(b_date, day_sum) AS
         (SELECT date_trunc('day', book_date)          AS b_date,
                 round(sum(total_amount) / 1000000, 2) AS day_sum
          FROM bookings
          GROUP BY b_date)

SELECT to_char(b_date, 'YYYY-MM-DD')                AS date,
       extract(isodow FROM b_date)                  AS dow,      ----день недели
       day_sum,
       lead(day_sum, 7) OVER all_rows_win           AS week_ago, ---неделю назад от текущей вычисляемой даты
       day_sum - lead(day_sum, 7) OVER all_rows_win AS delta     ---разница между суммами фактической и неделю назад
FROM day_amounts
WINDOW all_rows_win AS (PARTITION BY date_trunc('month', b_date) )
ORDER BY b_date DESC;

/*Распределение столбца**/


SELECT (abs(hashtext(city::text)) % 10) as segment_simulation,
       count(*)                         as airports_data
FROM airports_data
GROUP BY segment_simulation
ORDER BY segment_simulation;


/*Конструкция LATERAL расширяет возмодности команды Select
 * Она позволяет организовать обработку подзапроса в предложении from
 * таким образом как будто она производится в цикле!!!
 * С помощью данной конструкции в ряде случаев удается значительно
 * упростить запрос, облегчить его интерпретацию.
 * Бывают ситуации, когда без этой инструкции трудно обойтись.
 *
 * Ключевое слово LATERAL может предварять вложенный запрос SELECT в списке FROM.
 * Оно позволяет обращаться в этом вложенном SELECT к столбцам элементов FROM,
 * предшествующим ему в списке FROM. (Без LATERAL все вложенные подзапросы
 * SELECT обрабатываются независимо и не могут ссылаться на другие элементы списка FROM.)
 *
 * Алгоритм решения задачи может быть следующим: для каждого рейса,
 * имеющего статус Arrived, нужно случайным образом выбрать из таблицы
 * "Посадочные талоны" десятую часть строк, соответствующих этому рейсу,
 * а затем объединить полученные множества строк в единую выборку.
 * Конечно реализовать этот алгоритм можно, используя процедурное расширение
 * но можно обойтись и одной командой Select. В этотм поможет
 * конструкция Lateral.
 *
 *
Преимущества LATERAL подхода:
Производительность - один проход по данным для каждого рейс
Читаемость - логика сэмплирования ясна и локализована
Гибкость - легко изменить процент выборки или логику отбора
Масштабируемость - хорошо работает на больших объемах данных
LATERAL позволяет выполнять "параметризованные подзапросы" -
для каждой строки внешнего запроса
выполняется свой подзапрос с параметрами из этой строки.
 */

SELECT city, airport_code
FROM airports
WHERE city IN ('Москва', 'Хабаровск', 'Владивосток', 'Южно-Сахалинск', 'Благовещенск')
ORDER BY city


EXPLAIN ANALYZE
SELECT f.flight_id, bp2.ticket_no
FROM flights f
/*Для КАЖДОГО рейса 'f':
1. Посчитать общее количество посадочных талонов для этого рейса
2. Вычислить 10% от этого количества (округляя вверх)
3. Взять случайную выборку этого размера
4. Вернуть номера билетов из этой выборки*/
         CROSS JOIN LATERAL
    (SELECT ticket_no
     FROM boarding_passes bp
     WHERE bp.flight_id = f.flight_id ---- Для КАЖДОГО рейса!
     ORDER BY random() ---- Случайное перемешивание
/*ORDER BY random():
Перемешивает посадочные талоны в случайном порядке
LIMIT берет первые N строк из случайной последовательности
Это создает случайную выборку*/
     LIMIT ceiling(
             (SELECT count(*)
              FROM boarding_passes bp
              WHERE bp.flight_id = f.flight_id) * 0.1 ---- 10% от общего количества
/*CEILING(COUNT * 0.1)  -- Округление ВВЕРХ
-- 14.3 → 15
-- 7.8 → 8
-- Гарантирует хотя бы 1 билет, даже если 10% < 1*/
           )
    ) AS bp2
/* Базовый фильтр рейсов:
Рейсы Москва → Дальний Восток
Рейсы Дальний Восток → Москва
Только прибывшие рейсы
 */
WHERE f.status = 'Arrived'
  AND (
    (f.departure_airport IN ('DME', 'DME', 'VKO')
        AND f.arrival_airport IN ('VVO', 'KHV', 'UUS', 'BQS')
        )
        OR
    (f.departure_airport IN ('VVO', 'KHV', 'UUS', 'BQS')
        AND f.arrival_airport IN ('DME', 'DME', 'VKO')
        )
    )
ORDER BY f.flight_id, bp2.ticket_no

/* Известно что в предложении FROM команды Select могут использоваться подзапросы
 * По умолчанию (если не принять специальных мер) все они обрабатываются независимо
 * друг от друга и не могут ссылаться на другие элементы списка FROM.
 * При этом порядок следования элементов в данном списке не влияет на порядок выполнения
 * соединений, который выберет планировщик.
 * Однако можно сделать так, чтобы подзапрос мог ссылаться на столбцы таблиц или подзапросов,
 * находящихся перед ним в списке FROM.
 * Для этого необходимо использовать ключеве слово LATERAL
 * перед подзапросом, который должен иметь такую возможность. Наличие ключевого слова вынуждает
 * планировщик сначала выполнить соединение всех элементов списка FROM, находящихся левее
 * этого слова.
 *
 * При наличии ключевого слова LATERAL запрос выполняется следующим образом:
 * -если слева от LATERAL стоит только одна таблица или подзапрос, то для ее строки выполняется
 * подзапрос, стоящий справа.
 * -если в нем есть ссылки на столбцы левой таблицы, то их значения берутся из ее текущей строки.
 * Такие ссылки могут быть например в предложении where или limit.
 * Затем строки, порожденные запросом соединяются с текущей строкой левой таблицы в соответствии с
 * предписанием join. Эта процедура повторяется для всех строк левой таблицы.
 * Все сформированные подмножества строк объединяются в единое множество.
 * В том случае, когда слева от ключевого слова LATERAL стоят несколько таблиц или подзапросов, текущая
 * строка берется из результата их соединения.
 *
 * Приведенное описание говорит о том, что обработка консутркции LATERAL представляет собой
 * параметризованный цикл
 *
 * Берется строка таблицы "Рейсы" flights, удовлетворяющая условию where главного запроса
 * и далее выполняется уже подзапрос bp2 cс условием where bp.flight_id = f.flight_id.
 * Таким образом из таблицы "Посадочные талоны" (boarding passes) выбираются только номера билетов,
 * оформленных на данный рейс.
 * В результирующий набор попадает лишь случайная выборка из этих строк. После этого выполняется
 * декартово произведение текущей строки из таблицы "Рейсы" flights на все строки, которые возвращает
 * подзапрос bp2.
 * Затем берется следующая строка из таблицы "Рейсы" flights удовлетворяющая условие where главного запроса
 * для нее выполняется подзапрос bp2, и эта строка соединяется со строками, которые возвратил ползапрос.
 * Этот процесс повторяется до исчерпания строк таблицы Рейсы (flights) Все наборы строк объединяются
 * в единую выборку.
 * В предложение LIMIT тоже находится подзапрос, в нем определяется число пассажиров для конкретного
 * рейса, для которого производятся вычисления. А от этго числа берется 10-ая часть/
 * Это позволяет выбрать пассажира для поощрения даже на тех рейсах, которыми
 * летели менее 10 человек.
 * Случайная выборка строк из таблицы "Посадочные талоны" (boarding passes) достигается сортировкой
 * на основе значений функции random!!!, вычисленных для каждой строки.
 * Из документации известно, что элементами предложения order by могут быть и произвольные выражения, вычисленные
 * на основе значений исходных строк!!!
 * Для соединений строк план запроса воспользуется вложенным циклом Nested Loop.
 * Метод хеширования здесь не применим, поскольку он последовательно читает сначала один набор строк (
 * строя на его основе хеш таблицу), а затем второй (сопоставляя прочитанные строки с готовой хэштаблицей).
 * Метод слияния тоже не применим, поскольку оба набора строк должны быть отсортированы перед слиянием.
 * И только метод вложенного цикла просматривает строки итеративно, позволяя формировать
 * один из наборов строк частями, что и подразумевается конструкцией LATERAL.
 * На больших выборках время выполнения запросов таких запросов может быть значительным.
 * Относительное ускорение на небольших выборках не будет иметь места на большой выборке!!!
 *
 *
 *
 * Для каждого рейса подсчитаем количество пассажиров, получивших
 * счастлоивый билет, и общее число пассажиров которые участвовали в розыгрыше.
 * Модифицируем запрос:
 */

WITH far_east_flights AS (SELECT flight_id
                          FROM flights
                          WHERE status = 'Arrived'
                            AND (
                              (departure_airport IN ('DME', 'DME', 'VKO')
                                  AND arrival_airport IN ('VVO', 'KHV', 'UUS', 'BQS')
                                  )
                                  OR
                              (departure_airport IN ('VVO', 'KHV', 'UUS', 'BQS')
                                  AND arrival_airport IN ('DME', 'DME', 'VKO')
                                  )
                              ))

   , all_passengers AS (SELECT f.flight_id, count(*) AS all_pass
                        FROM boarding_passes AS bp
                                 JOIN far_east_flights AS f ON f.flight_id = bp.flight_id
                        GROUP BY f.flight_id)


   , happy_passengers AS (SELECT cnt.flight_id,
                                 bp2.ticket_no
                          FROM (SELECT f.flight_id,
                                       ceiling(count(*) * 0.1) AS happy_pass_count
                                FROM far_east_flights AS f
                                         JOIN boarding_passes AS bp ON bp.flight_id = f.flight_id
                                GROUP BY f.flight_id) AS cnt
                                   CROSS JOIN LATERAL (
                              SELECT ticket_no
                              FROM boarding_passes bp
                              WHERE bp.flight_id = cnt.flight_id
                              ORDER BY random()
                              LIMIT cnt.happy_pass_count
                              ) AS bp2)

   , happy_passengers2 AS (SELECT flight_id,
                                  count(*) AS happy_pass
                           FROM happy_passengers
                           GROUP BY flight_id)

SELECT hp.flight_id, ap.all_pass, hp.happy_pass
FROM happy_passengers2 AS hp
         JOIN all_passengers AS ap ON ap.flight_id = hp.flight_id
ORDER BY ap.all_pass DESC, hp.flight_id;


/*В конструкции LATERAL можно использовать не только подзапросы, но и вызовы функций, возвращающих
 * множество строк
 *
 * Согласованность данных является важным критерием  их качесива и пригодности для принятия
 * управленческих решений.
 *
 *
 * Талоны получают последовательные номера начиная с единицы в рамках каждого рейса,
 * тогда каким образом можно выявить возможные пропуски в номерах посадочных талонов?
 * Идея алгоритма такова - для каждого состоявшегося рейса нужно сформировать эталонный
 * список номеров посадочных талонов без пропусков, начиная с единицы и заканчивая
 * максимальным номером оформленного на этот рейс талона.
 * Затем используя это внешнее соединение нужно сопоставить этот полный список номеров
 * талонов со списком номеров талонов, фактически оформленных на этот рейс.
 * Те номера для которых не найдется пары из эталонного списка и будут являться пропущенными
 * номерами
 *
 * */

--SELECT generate_series(1, (SELECT max(boarding_no) AS boarding_no FROM boarding_passes))

BEGIN;
DELETE
FROM boarding_passes
WHERE (flight_id, boarding_no) IN ((25, 3), (25, 6), (26, 3), (27, 5));
ROLLBACK;


SELECT f.flight_id,
       nums.boarding_no
FROM flights f
         CROSS JOIN LATERAL generate_series(
        1, (SELECT max(boarding_no) AS boarding_no
            FROM boarding_passes AS bp
            WHERE bp.flight_id = f.flight_id)
                            ) AS nums(boarding_no)
         LEFT OUTER JOIN boarding_passes AS bp ON bp.flight_id = f.flight_id AND bp.boarding_no = nums.boarding_no
WHERE f.status IN ('Departed', 'Arrived')
  AND bp.boarding_no IS NULL
ORDER BY f.flight_id,
         nums.boarding_no;

/*Тип  json в конструкции lateral
 *
 * Могут возникать ситуации, когда на основе структурированного описания требуется сформировать
 * строки для вставки в таблицу. В таких случаях использование в конструкции LATERAL функции,
 * возвращающих множество строк также поможет решить задачу
 *
 * В качестве иллюстрации рассмотрим следующую задачу
 * Предположим, что мы только присутпаем к работе с базой данных Авиаперевозки и для
 * начала требуется заполнить таблицу Места seats.
 * В этйо таблице три столбца:
 * - aircraft_code.
 * - seat_no.
 * - fare_conditions.
 * Конфигурации планировок салонов представлены в виде json - массива.
 * Элементами массива являются json - объекты, представляющие класс обслуживания.
 * Объект включает в себя название класса обслуживания и два массива:
 * 1.Содержит номера первого и последнего рядов в этом классе
 * 2.Содержит буквенно обозначение мест в этих рядах.
 * Для примера возьмем только две модели самолетов SU9 и CN1.
 * Надо сказать, что не всегда салоны самолетов имеют регулярную структуру, как
 * в данном примере.Для планировок в которых количество кресел отличается
 * от ряда к ряду можно добавить в массив несколько элементов для одного класса.
 *
 * В подзапросе
 */

WITH seats_conf(aircraft_code, seats_conf) AS
/*
 * Создаем временную таблицу seats_conf с двумя колонками: aircraft_code и seats_conf
VALUES создает строки данных:
Для самолета 'SU': JSON с двумя классами обслуживания (Business и Economy)
Для самолета 'CN1': JSON с одним классом обслуживания (Economy)
::jsonb преобразует строку в тип данных JSONB
 * aircraft_code | seats_conf (jsonb)
------------- | ------------------
SU            | [{"fare_conditions": "Business", "rows": [1,3], "letters": ["A","C","D","F"]}, ...]
CN1           | [{"fare_conditions": "Economy", "rows":  [1,6], "letters": ["A","B"]}]

 * */
         (VALUES ('SU', '[
           {
             "fare_conditions": "Business",
             "rows": [
               1,
               3
             ],
             "letters": [
               "A",
               "C",
               "D",
               "F"
             ]
           },
           {
             "fare_conditions": "Economy",
             "rows": [
               4,
               20
             ],
             "letters": [
               "A",
               "C",
               "D",
               "E",
               "F"
             ]
           }
         ]'::jsonb),
                 ('CN1', '[
                   {
                     "fare_conditions": "Economy",
                     "rows": [
                       1,
                       6
                     ],
                     "letters": [
                       "A",
                       "B"
                     ]
                   }
                 ]'::jsonb)),
     fare_cond_confs AS
/*
 * Что происходит:
jsonb_array_elements(sc.seats_conf) - разворачивает JSON-массив в отдельные строки
CROSS JOIN LATERAL - для каждой строки из seats_conf применяет функцию разворачивания
Как работает разворачивание:
Для самолета 'SU' массив из 2 элементов превращается в 2 строки:
До разворачивания:
SU: [ {Business config}, {Economy config} ]

 После разворачивания:
SU: {Business config}
SU: {Economy config}

------------- | ------------
SU            | {"fare_conditions": "Business", "rows": [1,3], "letters": ["A","C","D","F"]}
SU            | {"fare_conditions": "Economy", "rows":  [4,20], "letters": ["A","C","D","E","F"]}
CN1           | {"fare_conditions": "Economy", "rows":  [1,6], "letters": ["A","B"]}

 *
 * */
         (SELECT aircraft_code, conf
          FROM seats_conf sc
                   CROSS JOIN LATERAL jsonb_array_elements(sc.seats_conf) AS conf)


SELECT aircraft_code, param.*
/*jsonb_each(fcc.conf) - разбивает каждый JSON-объект на пары ключ-значение
CROSS JOIN LATERAL - для каждой JSON-строки создает несколько строк с ключами и значениями
Как работает для одной строки:
Вход: {"fare_conditions": "Business", "rows": [1,3], "letters": ["A","C","D","F"]}
После jsonb_each:
key               | value
"fare_conditions" | "Business"
"rows"            | [1,3]
"letters"         | ["A","C","D","F"]*/
FROM fare_cond_confs fcc
         CROSS JOIN LATERAL jsonb_each(fcc.conf) AS param



/*Теперь получим итоговые реузльтат для вставки в таблицу
 * Скрипт генерирует полный список всех мест в самолетах на основе JSON-конфигураций.
 * Для каждого самолета и класса обслуживания он создает комбинации всех рядов (от начального до конечного) со всеми возможными буквами мест, формируя полный перечень мест типа "1A", "1C", "2A", "2C" и т.д.
 * */
-- Создаем временную таблицу seats_conf с конфигурациями мест для разных самолетов
WITH seats_conf(aircraft_code, seats_conf) AS
         (VALUES
              -- Конфигурация для самолета с кодом 'SU'
              ('SU', '[
                {
                  "fare_conditions": "Business",
                  "rows": [
                    1,
                    3
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "F"
                  ]
                },
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    4,
                    20
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "E",
                    "F"
                  ]
                }
              ]'::jsonb
                  /* Класс обслуживания: Бизнес,
  * Ряды с 1 по 3,
  * Буквы мест в ряду
  * Класс обслуживания: Эконом
  * Ряды с 4 по 20
  * Буквы мест в ряду
  * Приводим строку к типу jsonb
  */
              ),
              -- Конфигурация для самолета с кодом 'CN1'
              ('CN1', '[
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    1,
                    6
                  ],
                  "letters": [
                    "A",
                    "B"
                  ]
                }
              ]'::jsonb)
             /* Класс обслуживания: Эконом
   * Ряды с 1 по 6
   * Буквы мест в ряду
   * Приводим строку к типу jsonb
   */

         ),
-- Преобразуем JSON конфигурации в реляционный формат
     fare_cond_confs AS
         (SELECT aircraft_code, conf
          FROM seats_conf sc
                   CROSS JOIN LATERAL jsonb_array_elements(sc.seats_conf) AS conf -- Разбиваем JSON массив на отдельные строки
         )

-- Генерируем все возможные места на основе конфигураций
SELECT aircraft_code,                                     -- Код самолета
       fcc.conf ->> 'fare_conditions' AS fare_conditions, -- Извлекаем класс обслуживания из JSON
       ROW || letter                  AS seat_no          -- Формируем номер места: ряд + буква
FROM fare_cond_confs fcc
-- Генерируем последовательность номеров рядов для каждого класса обслуживания
         CROSS JOIN LATERAL generate_series(
        (fcc.conf -> 'rows' ->> 0)::integer, -- Извлекаем начальный номер ряда из JSON и приводим к integer
        (fcc.conf -> 'rows' ->> 1)::integer -- Извлекаем конечный номер ряда из JSON и приводим к integer
                            ) AS ROW(ROW) -- Генерируем ряды от начального до конечного
-- Разбиваем массив букв мест на отдельные строки
         CROSS JOIN LATERAL jsonb_array_elements_text(fcc.conf -> 'letters') AS letters(letter)
-- Сортируем результаты для удобства чтения
ORDER BY aircraft_code,   -- Сначала по коду самолета
         fare_conditions, -- Затем по классу обслуживания
         ROW,             -- Затем по номеру ряда
         letter
-- И по букве места
/*
 *
 * JSON_TABLE в PostgreSQL - это мощная функция для преобразования JSON-данных в табличный формат.
 * Появилась в версии 16 и предоставляет SQL-Standard способ парсинга JSON.
 * JSON_TABLE(
    json_data,          -- JSON-документ для парсинга
    json_path,          -- JSONPath выражение
    COLUMNS (           -- Определение колонок
    column_name data_type PATH path_expression,
    ...
    )
)

SELECT *
FROM JSON_TABLE(
    '[{"name": "John", "age": 30}, {"name": "Alice", "age": 25}]',
    '$[*]'
    COLUMNS (
        name text PATH '$.name',
        age integer PATH '$.age'
    )
);

| name  | age |
|-------|-----|
| John  | 30  |
| Alice | 25  |


 */

WITH seats_confs(aircraft_code, seats_conf) AS
         (VALUES
              -- Конфигурация для самолета с кодом 'SU'
              ('SU', '[
                {
                  "fare_conditions": "Business",
                  "rows": [
                    1,
                    3
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "F"
                  ]
                },
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    4,
                    20
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "E",
                    "F"
                  ]
                }
              ]'::jsonb),
              -- Конфигурация для самолета с кодом 'CN1'
              ('CN1', '[
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    1,
                    6
                  ],
                  "letters": [
                    "A",
                    "B"
                  ]
                }
              ]'::jsonb))

--- Основной запрос для извлечения и преобразования JSON данных
SELECT sc.aircraft_code, -- Код самолета из временной таблицы
       jt.*              -- Все колонки из результата работы JSON_TABLE
FROM seats_confs AS sc
-- Используем LATERAL JOIN с функцией json_table для парсинга JSON
         CROSS JOIN LATERAL json_table(
        seats_conf, -- JSON-колонка для парсинга
        '$[*]' -- JSONPath выражение: обработать все элементы массива
            COLUMNS               -- Определение структуры выходных колонок
(
fare_condition text PATH  '$.fare_conditions',  -- Извлечь текст из поля fare_conditions
row_from integer    PATH  '$.rows[0]',          -- Извлечь первый элемент массива rows как integer
row_to integer      PATH  '$.rows[1]',          -- Извлечь второй элемент массива rows как integer
letters text[]      PATH  '$."letters"'         -- Извлечь весь массив letters как text array
  )
                            ) AS jt -- Псевдоним для результата json_table
-- Сортировка результатов
ORDER BY aircraft_code, -- Сначала сортируем по коду самолета
         row_from;
-- Затем по начальному номеру ряда (row_from)


/*Усовершенствуем массив, чтобы он отдавал развернутый
* массив букввенных обозначений.
* NESTED PATH '$.letters[*]'
NESTED PATH - создает "вложенный путь" для обработки элементов массива
'$.letters[*]' - JSONPath выражение, которое означает:
$.letters - обращение к полю "letters"
[*] - все элементы массива
COLUMNS (letter text PATH '$')
Создает колонку letter типа text
PATH '$' - берет значение текущего элемента массива

*/



WITH seats_confs(aircraft_code, seats_conf) AS
         (VALUES
              /* CTE с конфигурациями самолетов: код самолета и JSON с расположением мест */
              ('SU', '[
                {
                  "fare_conditions": "Business",
                  "rows": [
                    1,
                    3
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "F"
                  ]
                },
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    4,
                    20
                  ],
                  "letters": [
                    "A",
                    "C",
                    "D",
                    "E",
                    "F"
                  ]
                }
              ]'::jsonb),
              /* Маленький самолет с двухместной конфигурацией в ряду */
              ('CN1', '[
                {
                  "fare_conditions": "Economy",
                  "rows": [
                    1,
                    6
                  ],
                  "letters": [
                    "A",
                    "B"
                  ]
                }
              ]'::jsonb))

SELECT sc.aircraft_code, /* Код самолета для идентификации типа воздушного судна */
       jt.fare_conditions, /* Класс обслуживания: Business или Economy */
       rows.row || jt.letter AS seat_no /* Формирование номера места путем конкатенации номера ряда и буквы */
FROM seats_confs AS sc
/* Парсинг JSON конфигурации и преобразование в табличную структуру */
         CROSS JOIN LATERAL json_table(
        seats_conf, /* JSON-поле с конфигурацией кресел самолета */
        '$[*]' /* JSONPath для итерации по всем элементам верхнего уровня массива */
            COLUMNS               /* Определение структуры выходных колонок из JSON */
   (
fare_conditions text PATH  '$.fare_conditions',  /* Извлечение класса обслуживания из JSON */
row_from integer    PATH  '$.rows[0]',          /* Начальный номер ряда из массива rows */
row_to integer      PATH  '$.rows[1]',          /* Конечный номер ряда из массива rows */
NESTED PATH '$.letters[*]' /* Развертывание массива букв в отдельные строки */
COLUMNS (letter text PATH '$' )/* Извлечение каждой буквы как отдельного значения */
   )
                            ) AS jt /* Результат парсинга JSON с конфигурацией по классам обслуживания */
/* Генерация последовательности номеров рядов для каждого класса обслуживания */
         CROSS JOIN LATERAL generate_series(jt.row_from, jt.row_to) AS rows(row)
/* Сортировка итогового списка мест для удобного отображения */
ORDER BY aircraft_code, row, letter


/*Напишите эту конструкцию с использованием конструкции LATERAL*/

EXPLAIN ANALYZE
SELECT a.model,
       count(*) AS seats_cnt
FROM aircrafts a
         JOIN seats s ON
    s.aircraft_code = a.aircraft_code
GROUP BY a.model
ORDER BY seats_cnt DESC;


EXPLAIN ANALYZE
SELECT a.model,
       (SELECT count(*)
        FROM seats s
        WHERE s.aircraft_code = a.aircraft_code) AS seats_cnt
FROM aircrafts a
ORDER BY seats_cnt DESC;



EXPLAIN ANALYZE
SELECT a.model,
       seats_cnt
FROM aircrafts a
         CROSS JOIN LATERAL (
    SELECT count(*) AS seats_cnt
    FROM seats s
    WHERE s.aircraft_code = a.aircraft_code
    ) AS seats_data
ORDER BY seats_cnt DESC;
/*
Распиши, как работает этот скрипт, поставь многострочный комментарий по строкам:
РАЗБОР ВЫПОЛНЕНИЯ ЗАПРОСА:

1. EXPLAIN ANALYZE - команда для показа плана выполнения и реальных метрик
   • EXPLAIN - показывает предполагаемый план выполнения
   • ANALYZE - фактически выполняет запрос и показывает реальные затраты

2. Основная структура запроса:
   • Берем модели самолетов из таблицы aircrafts
   • Для каждой модели подсчитываем количество мест через LATERAL подзапрос!!!!
   • Сортируем результаты по убыванию количества мест

3. Детали выполнения по шагам:

Шаг 1: Seq Scan на таблице aircrafts (псевдоним 'a')
   • PostgreSQL читает всю таблицу aircrafts построчно
   • Для каждой строки (каждого самолета) выполняется подзапрос

Шаг 2: Для КАЖДОЙ строки из aircrafts выполняется LATERAL подзапрос:
   • Подзапрос: SELECT count(*) FROM seats s WHERE s.aircraft_code = a.aircraft_code
   • Для текущего aircraft_code из внешней таблицы:
     - Выполняется поиск в таблице seats по индексу или последовательное сканирование
     - Подсчитывается количество совпадающих записей
   • Результат (seats_cnt) присоединяется к текущей строке из aircrafts

Шаг 3: Сортировка результатов:
   • Все полученные строки (модель + количество мест) сортируются по seats_cnt DESC
   • Используется операция Sort для упорядочивания результатов

4. Ключевые особенности LATERAL в этом контексте:
   • Подзапрос выполняется ДЛЯ КАЖДОЙ строки основной таблицы
   • Подзапрос имеет доступ к полям внешней таблицы (a.aircraft_code)
   • Результат подзапроса "присоединяется" к каждой строке основной таблицы

5. Эквивалент без LATERAL:
   SELECT a.model, COUNT(s.seat_no) as seats_cnt
   FROM aircrafts a
   LEFT JOIN seats s ON s.aircraft_code = a.aircraft_code
   GROUP BY a.model
   ORDER BY seats_cnt DESC;

6. Производительность:
   • Эффективность зависит от наличия индекса на seats.aircraft_code
   • Для больших таблиц может быть менее эффективен, чем GROUP BY версия
   • Полезен когда нужны сложные вычисления для каждой строки

РЕЗУЛЬТАТ: Получаем список моделей самолетов с количеством мест в каждом, отсортированный по убыванию вместимости

*/


/*Выявление пропусков в нумерации
 * Для каждого значения Нужно найти наименьшее значение, превышающее его
 * Если разность этой праы значений превышает единицу,
 * значит имеет место пропуск в нумерации, надо отображать
 * такие пары и для каждой из них генерировать пропущенные значения*/

CREATE TABLE numbers
(
    a int
);
INSERT INTO numbers
SELECT g
FROM generate_series(1, 100) AS g

DELETE
FROM numbers
WHERE a IN (19, 58, 51, 52);

/*
РАЗБОР СКРИПТА ПОИСКА ПРОПУЩЕННЫХ ЧИСЕЛ В ПОСЛЕДОВАТЕЛЬНОСТИ:
Скрипт находит все пропущенные числа между существующими числами в таблице `numbers`
ПРИМЕР:
Если в таблице numbers есть значения: [1, 2, 4, 7, 8]
То результат будет: [3, 5, 6]

ПОШАГОВЫЙ РАЗБОР:
1. CTE gaps - находит "дырки" в последовательности:
   SELECT a1, a2
   FROM numbers AS n1
   CROSS JOIN LATERAL (
       SELECT n1.a AS a1, n2.a AS a2
       FROM numbers AS n2
       WHERE n2.a > n1.a              -- берем следующее число
       ORDER BY n2.a
       LIMIT 1                        -- только ближайшее следующее число
   ) AS n2
   WHERE a2 - a1 > 1                  -- фильтруем только настоящие дырки

   КАК РАБОТАЕТ CTE gaps:
   - Для каждого числа n1.a ищет ближайшее большее число n2.a
   - Отбирает только пары, где разница больше 1 (есть пропуски)

   ПРИМЕР РАБОТЫ CTE gaps для [1, 2, 4, 7, 8]:
   n1.a | n2.a | Разница | Берем?
   1    | 2    | 1       | НЕТ (разница = 1)
   1    | 4    | 3       | ДА (но берется только 1→2 из-за LIMIT 1)
   2    | 4    | 2       | ДА
   4    | 7    | 3       | ДА
   7    | 8    | 1       | НЕТ

   РЕЗУЛЬТАТ CTE gaps:
   a1 | a2
   2  | 4
   4  | 7

2. Основной запрос - генерирует пропущенные числа:
   SELECT missing
   FROM gaps
   CROSS JOIN generate_series(a1 + 1, a2 - 1) AS missing

   ДЛЯ КАЖДОЙ ПАРЫ ИЗ gaps:
   - Для пары (2, 4): generate_series(2 + 1, 4 - 1) = generate_series(3, 3) = [3]
   - Для пары (4, 7): generate_series(4 + 1, 7 - 1) = generate_series(5, 6) = [5, 6]

   ИТОГОВЫЙ РЕЗУЛЬТАТ: [3, 5, 6]

АЛЬТЕРНАТИВНЫЙ БОЛЕЕ ПРОСТОЙ ВАРИАНТ:

WITH all_numbers AS (
    SELECT generate_series(
        (SELECT min(a) FROM numbers),
        (SELECT max(a) FROM numbers)
    ) AS expected
)
SELECT expected AS missing
FROM all_numbers
WHERE expected NOT IN (SELECT a FROM numbers)
ORDER BY missing;

КОГДА ПОЛЕЗЕН ТАКОЙ СКРИПТ:

1. Поиск пропущенных ID в таблицах
2. Анализ последовательностей номеров документов
3. Поиск дырок в нумерации заказов, счетов и т.д.
4. Валидация данных на целостность последовательностей

ВЕРДИКТ: Скрипт эффективно находит все пропуски в числовой последовательности,
генерируя недостающие числа между существующими.

*/


WITH gaps AS (SELECT a1, a2
              FROM numbers AS n1
                       CROSS JOIN LATERAL (
                  SELECT n1.a AS a1, n2.a AS a2
                  FROM numbers AS n2
                  WHERE n2.a > n1.a
                  ORDER BY n2.a
                  LIMIT 1
                  ) AS n2
              WHERE a2 - a1 > 1)

SELECT missing
FROM gaps
         CROSS JOIN generate_series(a1 + 1, a2 - 1) AS missing
ORDER BY missing

/*Более упрощенный вариант*/
WITH all_numbers AS (SELECT generate_series(
                                    (SELECT min(a) FROM numbers),
                                    (SELECT max(a) FROM numbers)
                            ) AS expected) ----весь числовой ряд без пропусков.

SELECT expected AS missing
FROM all_numbers
WHERE expected NOT IN (SELECT a FROM numbers)
ORDER BY missing;

/*Подпрограммы routines
 * дополняют его элементами императивного стиля программирования
 * Postgres изначально проектировался так, чтобы пользователь мог расширять функциональность СУБД своими
 * собственными объектами, в том числе типами данных, операторами, агрегатами,
 * пользовательскими функциями.
 * При этом создаваемые объекты подключаются к серверу на лету.
 * Такая гибкость обеспечивается тем, что в Postgresql значительная часть метаинформации не закодирована
 * жестко, а хранится в специальных системных таблицах
 *
 * Функции можно разрабатывать на таких языках как Python, Perl, PL/pgsql - который является
 * процедурным расширением PostgreSQL, так же возможно создавать их на языке SQL, возможностей
 * которого вполне достаточно, чтобы решить весьма сложные задачи.
 *
 * Пользовательские функции создаются на стороне сервера и позволяют разработчику:
 * -декомпозировать задачу (наряду с подзапросами и табличными выражениями)
 * -повторно использовать серверный код в нескольких приложениях;
 * -упрощать программный код в нескольких приложениях;
 * -упрощать программный код приложения, заменяя несколько запросов, выполняющих общую задачу,
 * вызовом функции;
 * -избегать модификации приложения при изменении схемы базы данных или алгоритмов выполнения
 * операций за счет сохранения программного интерфейса(API) предоставляемого функцией.
 */


/*Создания функции
 * Необходимо подсчитать число мест в салоне конкретной модели самолета, соответствующих
 * указанному классу обсулживания*/

CREATE FUNCTION count_seats(a_code char(3), fare_cond text)
    RETURNS bigint AS
/*создается тип возвращаемого значения, мы использовали  bigint потому как функция count
возвращает значение именно такого типа
Тело функции представляет из себя символьную строку, предваряется ключевым словом AS
Завершается функция  ключевым словом LANGUAGE с указанием языка, на котором она написана
*/
$$
select count(*)
from seats s
where s.aircraft_code = a_code
  and s.fare_conditions = fare_cond;
$$ LANGUAGE SQL

EXPLAIN ANALYZE
SELECT count_seats('773', 'Business')
           /*Функции могут порождать таблицы и вызваться в преложении from
 * Функция можети возвращать таблицу и с несколькими столбцами*/

/*Можно задавать псевдонимы функции и имени столбца*/
           EXPLAIN ANALYZE
SELECT *
FROM count_seats('773', 'Business') AS c_seats (сs)


/*Если число параметров функции велико, их порядок будет трудно запомнить
 * в таком случае можно воспользоваться нотацией с именованными аргументами.
 * До этого мы применяли нотацию с позиционными аргументами
 * хотя наша функция имеет всего два параметра, воспользуемся для ее вызова
 * нотацией с именованными аргументами*/

SELECT count_seats(fare_cond =>'Business', a_code => 'SU9');

/*Как увидеть информацию о функции*/
-- Этот запрос нужно выполнять из базы данных postgres
-- Этот запрос нужно выполнять из базы данных postgres
SELECT current_database()                            AS database, -- Добавлено: имя текущей базы данных
       n.nspname                                     AS schema,
       p.proname                                     AS function_name,
       CASE p.prokind
           WHEN 'f' THEN 'function'
           WHEN 'p' THEN 'procedure'
           WHEN 'a' THEN 'aggregate'
           WHEN 'w' THEN 'window'
           END                                       AS function_type,
       pg_get_function_arguments(p.oid)              AS arguments,
       (SELECT string_agg(pt.typname, ', ' ORDER BY pa.ordinality)
        FROM unnest(coalesce(p.proargtypes, ARRAY []::oid[])) WITH ORDINALITY AS pa(oid, ordinality)
                 JOIN pg_type pt ON pt.oid = pa.oid) AS argument_types,
       pg_get_function_result(p.oid)                 AS return_type,
       t.typname                                     AS return_type_name,
       CASE
           WHEN p.provolatile = 'i' THEN 'immutable'
           WHEN p.provolatile = 's' THEN 'stable'
           WHEN p.provolatile = 'v' THEN 'volatile'
           END                                       AS volatility,
       CASE
           WHEN p.proisstrict THEN 'yes'
           ELSE 'no'
           END                                       AS returns_null_on_null_input,
       l.lanname                                     AS language,
       p.prosrc                                      AS source_code
FROM pg_proc p
         LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
         LEFT JOIN pg_type t ON p.prorettype = t.oid
         LEFT JOIN pg_language l ON p.prolang = l.oid
-- Раскомментируйте одну из строк ниже для фильтрации:
--WHERE
--p.proname = 'count_seats'  -- замените на имя вашей функции
WHERE p.proname LIKE '%count%' -- поиск по части имени
  AND n.nspname = 'bookings'   -- фильтр по схеме
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY database, -- Добавлено в сортировку
         n.nspname,
         p.proname;

/*Существует еще один способ обозначения параметров - по их порядковым номерам
 * номеру должен предшествовать знак $
 * нотация с позиционными аргументами, выше была приведена нотация с
 * именованными аргументами
 * Здесь в данном скрипте создания функции применение именованных аргументов невозможно*/

CREATE FUNCTION count_seats2(char, text)
    RETURNS bigint AS
$$
select count(*)
from seats s
where s.aircraft_code = $1
  and s.fare_conditions = $2;
$$ LANGUAGE SQL

SELECT *
FROM count_seats2('SU9', 'Business')

/* Параметры функций могут иметь параметры in, out, inout
 * По умолчанию подразумевается in поэтому мы его и не указывали в нашей первой
 * функции.
 * Параметр с таким модификатором является входным, то есть служит для передачи
 * внутрь функции какого-то значения, существующего вне ее.
 *
 * Модификатор out означает что параметр является входным. Таких параметров у
 * функции тоже может быть несколько. В случае отсутствия предложения RETURNS
 * именно параметры с модификаторами out определят выходные значения,
 * сформированные внутри функции, таким образом она сможет вернуть несколько
 * значений.
 * Если же наряду с такими параметрами присуствует и предложение RETURNS, то типы
 * данных этих параметров должны совпадать с типами, заданными в этом предложении!!!
 * Это объясняется тем, что параметры с модификатороами out и предложение returns
 * не дополняют друг друга, а по разному определяют одну и туже информацию
 * и в традиционных языках программирования, и в таких языках СУБД как PL SQL иди
 * Transact-sql, возвращаемое значение и выходные параметры действуют независимо друг
 * от друга.
 * Но в Postgresql out параметры и returns - просто разные способы указать тип возвращаемого
 * значения
 * Модификатор inout дает возможность сочетать свойства входных и выходных параметров.
 * Параметр с таким модификатором позволяет передать значение в функцию, а затем через
 * него жее вернуть значение (возможно другое) вовне!!!
 *
 * Давайте несколько модифицируем исходную задачу и напишем функцию, которая подсчитввает число
 * мест для каждого класса обслуживания в салоне выбранной модели самолета.
 * Предложение returns позволяет указать тип только одного возвращаемого значения,
 * поэтому нужно предусмотреть 4 параметра с модификатором out (Модификатор -
 * это служебное слово, которое уточняет назначение параметра.).
 * У первой версии функции было два входных параметра. Новая версия будет иметь один
 * входнной параметр.
 * Функция должна возвратить:
 * -название модели самолета
 * -код модели самолета
 */

CREATE FUNCTION count_seats3(
    INOUT a_code char DEFAULT 'SU9',
    OUT a_model text,
    OUT seats_business bigint,
    OUT seats_comfort bigint,
    OUT seats_economy bigint
) AS
$$
SELECT a.aircraft_code,
       a.model,
       count(*) filter (where s.fare_conditions = 'Business') AS business,
       count(*) filter (where s.fare_conditions = 'Comfort')  AS comfort,
       count(*) filter (where s.fare_conditions = 'Economy')  AS economy
FROM aircrafts a
         JOIN seats s ON s.aircraft_code = a.aircraft_code
WHERE a.aircraft_code = a_code
GROUP BY a.aircraft_code, a.model
$$ LANGUAGE SQL;

/*
SELECT
    a.aircraft_code,
    a.model,
    SUM(CASE WHEN s.fare_conditions = 'Business' THEN 1 ELSE 0 END) AS business,
    SUM(CASE WHEN s.fare_conditions = 'Comfort'  THEN 1 ELSE 0 END) AS comfort,
    SUM(CASE WHEN s.fare_conditions = 'Economy'  THEN 1 ELSE 0 END) AS economy
FROM aircrafts a
JOIN seats s ON s.aircraft_code = a.aircraft_code
WHERE a.aircraft_code = '319'
GROUP BY a.aircraft_code, a.model;
*/

SELECT *
FROM count_seats3('319')

/* Обратите внимание, что в качестве имен столбцов служат имена выходных
 * параметров функции, то есть тех, которые имеют модификаторы
 * out и inout, а не те имена или псевдонимы столбцов которые используются
 * внутри функции в SQL-запросе.
 * При этом параметры out при вызове функции ей передавать не нужно, а
 * параметр имеющий модификатор  inout, если только для него не задано значение
 * по умолчанию, - нужно.
 * Модификатор -  это служебное слово, которое уточняет назначение параметра
 * Если у функциФункция в SQL - это именованная группа SQL-операторов, которая принимает
 * параметры, выполняет определенные действия и возвращает результат.
 * Функции инкапсулируют логику для многократного использования.
 * Аргумент функции - это входное значение или переменная, которая передается
 * в функцию при ее вызове и используется в вычислениях внутри функции.
 *
 * */

SELECT *
FROM count_seats3()
---с параметром по умолчанию

/*Также можно использовать функцию и таким образом*/

SELECT seats_business + seats_comfort + seats_economy AS total_seats
FROM count_seats3('319')

/*В этом запросе мы не указали псевдонимы для столбцов, которые возвращает
 * функция.
 * В таком случае нам нужно знать имена выходных параметров, которые были заданы
 * при создании функции, что воспользоваться имя*/

SELECT code,
       moodel,
       seats_b,
       seats_c,
       seats_e,
       seats_b + seats_c + seats_e AS total_seats
FROM count_seats3('319') AS cnt_seats (code,
                                       moodel,
                                       seats_b,
                                       seats_c,
                                       seats_e)


/*Можно получить результат выполнения функции в виде значения так называемого составного
 * типа, которое представлено как группа полей, заключенных в скобки
 * Раздел 8.16 справки составные типы
 *
 * Система типов данных устроена так, что когда создается таблица,
 * вместе с ней создается и новый составной тип данных, имя которого совпадает
 * с ее именем, а поля этого типа соответствуют столбцами таблицы.
 * Составной тип по сути является список имен полей и их типов данных,
 * таким образом он является описанием структуры ее строк.
 * Для возвращаемого функцией результата тоже автоматически создается составной
 * тип, но анонимный
 *
 * Сейчас реализуем варинат с возвратом значения (предвариетельно созданного) составного типа,
 * взяв за основу функцию count_seats3 и модифицировав ее соответствующимм образом.
 *
 * !!!ТАкой способ с созданием специального составного типа может иметь смысл, если этот
 * тип может понадобиться и в других ситуациях!!!
 *
 * */

SELECT cnt_seats
FROM count_seats3('319') AS cnt_seats ---(319,"Аэробус A319-100",20,0,96)


CREATE TYPE cnt_seats AS
(
    aircraft_code  char(3),
    model          text,
    seats_business bigint,
    seats_comfort  bigint,
    seats_economy  bigint
);

/*Тело функции остается без изменений, изменяется только список параметров
 * и возвращаемое значение
 * Обратите внимание, что a_code стал взодным параметром. Поскольку код модели
 * самолета входит в состав созданного нами типа, возвращать этот код в качествеэ
 * отдельного элемента данных не требуется.
 * */


CREATE FUNCTION count_seats4(
    a_code char DEFAULT 'SU9'
)
    RETURNS cnt_seats AS
$$
SELECT a.aircraft_code,
       a.model,
       count(*) filter (where s.fare_conditions = 'Business') AS business,
       count(*) filter (where s.fare_conditions = 'Comfort')  AS comfort,
       count(*) filter (where s.fare_conditions = 'Economy')  AS economy
FROM aircrafts a
         JOIN seats s ON s.aircraft_code = a.aircraft_code
WHERE a.aircraft_code = a_code
GROUP BY a.aircraft_code, a.model
$$ LANGUAGE SQL;


SELECT *
FROM count_seats4('773')


/*Теперь поместим вызов функции в select*/

SELECT count_seats4('319')

/*Получим отдельное поле*
 * нотация требует наличия дополнительных скобок во избежание
 * неоднозначности при разборе запроса функции
 */

SELECT (count_seats4('319')).seats_business

/*Есть еще одна нотация функциональная*/

SELECT seats_business(count_seats4('319'))


/*Перегрузка функции
 * Сигнатура функции должна быть уникальной
 * Перегрузка функций - это возможность создать несколько
 * функций с одинаковым именем, но разными параметрами (сигнатурами).
 * PostgreSQL различает их по типам и количеству аргументов
 * Разные сигнатуры = разные функции

Перегрузка - создание функций с одинаковым именем, но разными параметрами
Сигнатура - уникальный идентификатор: имя(тип1, тип2, ...)
PostgreSQL выбирает функцию на основе совпадения типов аргументов
Это мощный механизм для создания гибких API, где одно имя функции может
работать с разными типами данных.
Перегрузим функцию cunt_seats

 */


CREATE FUNCTION count_seats(
    INOUT a_code char DEFAULT 'SU9',
    OUT a_model text,
    OUT seats_business bigint,
    OUT seats_comfort bigint,
    OUT seats_economy bigint
) AS
$$
SELECT a.aircraft_code,
       a.model,
       count(*) filter (where s.fare_conditions = 'Business') AS business,
       count(*) filter (where s.fare_conditions = 'Comfort')  AS comfort,
       count(*) filter (where s.fare_conditions = 'Economy')  AS economy
FROM aircrafts a
         JOIN seats s ON s.aircraft_code = a.aircraft_code
WHERE a.aircraft_code = a_code
GROUP BY a.aircraft_code, a.model
$$ LANGUAGE SQL;

---передаем два аргумента и видим, что вызывается первая версия функции
SELECT *
FROM count_seats('773', 'Business')

---передаем один аргумент и срабатывает вторая версия фукнции, также
---при вызове без аргументов сработает вторая версия функции.
SELECT *
FROM count_seats('773')

/*Удаление функций
 * Как и другие объекты базы данных функции можно удалять
 * для этого служит команда drop function, в ней достаточно
 * только указать только имя функции и типы данных, которые имеют
 * ее параметры, а их имена можно не указывать
 * При этом можно пускать молдификаторы типов
 *
 * Попробуем удалить одну из двух перегруженных функций*/

         DROP FUNCTION count_seats(char, text, bigint, bigint, bigint)
/*SQL Error [42883]: ERROR: function count_seats(character, text, bigint, bigint, bigint)
 * does not exist
 *
 *Ошибка объясняется тем, что в команде удаления функции нужно задать только
 *входные параметры, в том числе имеющие модификатор inout, а параметры
 *имеющие модификатор out  указывать не нужно.
 *Включив в команду выходные параметры, мы фактически указали функцию с другой
 *сигнатурой, а такой функции в нашей базе данных нет */

DROP FUNCTION IF EXISTS count_seats(char)

/*Функции, включающие несколько SQL-команд
 * Напишем функцию записывающую сведения о продаже билета в базу данных.
 * У функции будет целый ряд параметров, а возвращать она будет только
 * полную сумму бронирования.
 * Она позволяет в одном броинровании оформить несколько билетов
 * с несколькими перелетами в каждом
 */

CREATE FUNCTION make_or_update_booking(
    b_ref char, ---номер бронирования
    t_no char, ---номер билета
    p_id varchar, ---идентификатор пассажира
    p_name text, ---имя пассажира
    c_data jsonb, ---контактные данные пассажира
    f_id integer, ---идентификатор рейса
    f_cond varchar, ---класс обслуживания
    amt NUMERIC ---стоимость перелета
)
    RETURNS NUMERIC AS
$$
insert into bookings
    (book_ref, book_date, total_amount)
values (b_ref, bookings.now(), 0)
on conflict do nothing;

insert into tickets
    (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
values (t_no, b_ref, p_id, p_name, c_data)
on conflict do nothing;

insert into ticket_flights
    (ticket_no, flight_id, fare_conditions, amount)
values (t_no, f_id, f_cond, amt);

update bookings
set total_amount = total_amount + amt
where book_ref = b_ref
returning total_amount; ----функция возвращает сумму бронирования
$$
    LANGUAGE SQL;

/*Оформим билет на рейс Нижний Новгород - Пермь*/
BEGIN;
SELECT make_or_update_booking
       (b_ref => 'ABC123'
           , t_no => '1234567890123'
           , p_id => '000 123456'
           , p_name =>'IVAN KRESOV'
           , c_data => '{
          "phone": "+7(967)3007080"
        }'::jsonb
           , f_id => 20502
           , f_cond =>'Economy'
           , amt => 10000::numeric
       ) AS total_amount ----= - это оператор сравнения, а => - это синтаксис именованных параметров.

SELECT *
FROM bookings
WHERE book_ref = 'ABC123'

SELECT *
FROM tickets
WHERE ticket_no = '1234567890123'

SELECT *
FROM ticket_flights
WHERE ticket_no = '1234567890123'
  AND flight_id = '20502'

ROLLBACK;

/*Таким образом функция возвращает результат выполнения
 * своего последнего оператора. Если он порождает одну
 * строку, то она и будет возвращена в качестве результата.
 * Если же оператор порождает множество строк, то будет возвращена
 * первая из них, нужно учитывать, что без использования
 * предложения order by  первой из них станет случайная строка.
 */

/*Функции в стиле стандарта SQL
 * Тело каждой функции, созданной нами до сих пор, представляло собой строковую
 * константу!!!
 * Однако стандарт языка SQL предлагает другой способ, который можно
 * назвать "функция в стиле стандарта SQL"
 * При использовании этого способа тело функции представляет
 * собой блок операторов, входящих в состав функции, или одно выражение, возвращаемое
 * оператором RETURN
 *
 *
 * Между этими способами есть ряд принципиальных различий. При представлении функции
 * в виде строки разбор производится в процессе выполнения функции, а при использовании SQL-стиля
 * - в процессе ее определения. В результате становится возможным отслеживание зависимостей
 * между функцией и другими объектами базы данных.
 * Однако этот стиль применим только к функциям на языке SQL а функции с телом в виде строковой
 * константы можно писать на всех поддерживемых языках.
 */

CREATE FUNCTION count_seats_sql(a_code char, fare_cond text)
    RETURNS bigint
RETURN (SELECT count(*)
        FROM seats s
        WHERE s.aircraft_code = a_code
          AND s.fare_conditions = fare_cond);

SELECT count_seats_sql('SU9', 'Economy')

/*Теперь создадим новую версию функции make_or_update_booking в стиле стандарта
 * SQL, обратите внимание на конструкцию bigin atomic ... end.
 *
 */

CREATE FUNCTION make_or_update_booking_sql(
    b_ref char, ---номер бронирования
    t_no char, ---номер билета
    p_id varchar, ---идентификатор пассажира
    p_name text, ---имя пассажира
    c_data jsonb, ---контактные данные пассажира
    f_id integer, ---идентификатор рейса
    f_cond varchar, ---класс обслуживания
    amt NUMERIC ---стоимость перелета
)
    RETURNS NUMERIC
BEGIN
    ATOMIC -- Начало атомарной (транзакционной) операции

    insert into bookings
        (book_ref, book_date, total_amount)
    values (b_ref, bookings.now(), 0)
    on conflict do nothing;

    insert into tickets
        (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
    values (t_no, b_ref, p_id, p_name, c_data)
    on conflict do nothing;

    insert into ticket_flights
        (ticket_no, flight_id, fare_conditions, amount)
    values (t_no, f_id, f_cond, amt);

    update bookings
    set total_amount = total_amount + amt
    where book_ref = b_ref
    returning total_amount;
END;
----функция возвращает сумму бронирования

/*
Особенности реализации:
ATOMIC блок:
Все операции выполняются в одной транзакции
Либо все успешно, либо все откатываются
Нет риска частичного выполнения

ON CONFLICT DO NOTHING:
Позволяет повторно вызывать функцию с теми же данными
Не вызывает ошибок при дублировании
Идемпотентность операции

RETURNING total_amount:
Функция возвращает обновленную сумму бронирования
Можно использовать результат в приложении

-- Вызов 1: amt = 10000 → total_amount = 10000
-- Вызов 2: amt = 5000  → total_amount = 15000
-- Вызов 3: amt = 7000  → total_amount = 22000
*/

BEGIN;
SELECT make_or_update_booking_sql
       (b_ref => 'ABC123'
           , t_no => '1234567890123'
           , p_id => '000 123456'
           , p_name =>'IVAN KRESOV'
           , c_data => '{
          "phone": "+7(967)3007080"
        }'::jsonb
           , f_id => 20502
           , f_cond =>'Economy'
           , amt => 10000::numeric
       ) AS total_amount ----= - это оператор сравнения, а => - это синтаксис именованных параметров.

SELECT *
FROM bookings
WHERE book_ref = 'ABC123'

ROLLBACK;

/*В функции с телом в виде строковой константы
 * в столбце prosqlbody будет стоять null,
 * а для функции SQL-стиле NULL будет в столбце
 * prosrc*/
SELECT proname,
       LEFT(prosrc, 90)     AS source_code,
       LEFT(prosqlbody, 90) AS parsed_code
FROM pg_proc
WHERE proname ~ 'make_or_update_book'

/*Значения null в качестве аргументов функций
 * Функция может получить в качестве аргумента
 * значение null и разработчик должен позаботиться о
 * том, чтобы это не приводило к сбоям. По умолчанию
 * обработка таких значений возлагается на саму функцию.
 * Однако если функция заведомо должна возвратить null
 * при получении хотя бы одного неопределенного значения,
 * то можно явно указать это в команде CREATE FUNCTION
 * или ALTER FUNCTION с помощью предложения STRICT.
 * Тогда при выполнении запроса функция не исполнится вовсе,
 * а ее результат автоматически принимает значение NULL, позволяя
 * разработчику упростить код.
 */

EXPLAIN ANALYZE
SELECT count_seats_sql('SU9', NULL)

---DROP  FUNCTION count_seats_sql

CREATE FUNCTION count_seats_sql(a_code char, fare_cond text)
    RETURNS bigint
    STRICT ----STRICT в функции PostgreSQL означает, что функция будет
----возвращать NULL немедленно, если любой из её аргументов равен NULL.
RETURN (SELECT count(*)
        FROM seats s
        WHERE s.aircraft_code = a_code
          AND s.fare_conditions = fare_cond);

EXPLAIN ANALYZE ---запрос стал выполняться быстрее
SELECT count_seats_sql('SU9', NULL);

SELECT count_seats_sql('SU9',   'Business') ;

/*Существует альтернативный варинат предложения strict
Эти две строки делают одно и то же:
STRICT
RETURNS NULL ON NULL INPUT - это синоним для STRICT. Оба означают одно и то же!
 */



ALTER FUNCTION count_seats_sql RETURNS NULL ON NULL INPUT

SELECT unnest(ARRAY [
    'oid', 'proname', 'pronamespace', 'proowner', 'prolang',
    'procost', 'prorows', 'provariadic', 'prosupport', 'prokind',
    'prosecdef', 'proleakproof', 'proisstrict', 'proretset', 'provolatile',
    'proparallel', 'pronargs', 'pronargdefaults', 'prorettype', 'proargtypes',
    'proallargtypes', 'proargmodes', 'proargnames', 'proargdefaults',
    'protrftypes', 'prosrc', 'probin', 'prosqlbody', 'proconfig', 'proacl'
    ])        AS column_name,
       unnest(ARRAY [
           oid::text, proname::text, pronamespace::text, proowner::text, prolang::text,
           procost::text, prorows::text, provariadic::text, prosupport::text, prokind::text,
           prosecdef::text, proleakproof::text, proisstrict::text, proretset::text, provolatile::text,
           proparallel::text, pronargs::text, pronargdefaults::text, prorettype::text, proargtypes::text,
           proallargtypes::text, proargmodes::text, proargnames::text, proargdefaults::text,
           protrftypes::text, prosrc::text, probin::text, prosqlbody::text, proconfig::text, proacl::text
           ]) AS column_value
FROM pg_proc
WHERE proname = 'count_seats_sql';

/*Функции и зависимости между объектами баз данных
 *
 * Объекты в базе данных зависят друг от дурга. При удалении объектов связи между ними разрываются,
 * что может приводить к ошибкам в процессе выполнения запросов. Функции также участвуют в связях
 * с другими объектами, и нам необходимо рассмотреть два вопроса:
 * - что происходит с другими объектами, когда удаляется функция, на которую они ссылаются (например
 * функция используется в ограничении check таблицы.
 * - что происходит с функцией, когда удаляются объекты, используемые в ней.
 * Каждый объект в базе данных имеет идентификатор объекта oid, который представляется значениями
 * oid и используется в качестве первичного ключа соответствующего системного каталога.
 *
 * В Postgresql насчитывается несколько десятков системных каталогов из которых нас будут интересовать
 * следующие:
 *
 * pg_class - описывает таблицы, индексы, последовательности, представления, составные типы
 * данных и дургие объекты, объединяемые термином "отношение".
 * pg_proc  - хранит сведения о функциях (в том числе о оконных и агрегатных) и процедурах, то
 * есть о подпрограммах.
 * pg_consraint - содержит ограничения первичных ключей, уникальных, внешних ключей, ограчения
 * check и ряд других ограничений.
 * pg_depend - описывает зависимости между объектами базы данных. Он содержит ряд столбцов, в том числе:
 * class_id(ссылается на pg_class.oid) - oid системного каталога, в котором находится зависимый объект;
 * objid - ссылается  на какойй либо столбец oid - oid конкретного зависимого объекта.
 * refclassid ссылается на pg_class.oid - oid системного каталога, в котором нахолдиться
 * вышестоящий объект.
 * refobjid - ссылается на какой-либо столбец oid - oid вышестоящего объекта
 * deptype  - код, определяющий вид зависимости.
 *
 * Факт наличия записи в каталоге pg_depend говорит о том, что нельзя удалить вышестоящий объект,
 * не удалив также зависимый подчиненный.
 * Будем учитывать два варианта зависимости, задаваемых в столбце deptype, представлены они в подразделе
 * 51.18 pg_depend.
 * Обычная зависимость (n)  - зависимость между лбъектами, создаваемыми отдельно. Зависимый объект можно
 * удалить, не затрагивая вышестоящий.
 *
 * Однако вышестоящий объект при наличии зависимого можно удалить, только добавив слово cascade в команду
 * удаления. При этом зависимый объект также будет удален. В качестве примера можно привести зависимость столбца
 * таблицы от его типа данных или внешнего ключа от таблицы, на которую он ссылается.
 * Автоматическая зависимость (a) - зависимый объект, как и в предыдущем варинате зависимости,
 * можно удалить, не затрагивая вышестоящий. Однако при удалении вышестоящего объекта зависимый
 * должен быть удален автоматически,независимо от наличия предложения cascade в команде удаления.
 * В качестве примера может служить именованное ограничение, наложенное на таблицу, которое автоматически
 * удаляется при ее удалении.
 * Создадим представление для расшифровки информации в pg_depend
 */

CREATE VIEW pg_depend_v AS
(
SELECT objid,
       classid::regclass::text    AS classname,
       CASE classid
           WHEN 'pg_proc'::regclass THEN objid::regproc::text
           WHEN 'pg_class'::regclass THEN objid::regclass::text
           WHEN 'pg_constraint'::regclass THEN (SELECT conname FROM pg_constraint WHERE oid = pg_depend.objid)
           END                    AS objname,
       refclassid::regclass::text AS refclassname,
       refobjid,
       CASE refclassid
           WHEN 'pg_proc'::regclass THEN refobjid::regproc::text
           WHEN 'pg_class'::regclass THEN refobjid::regclass::text
           WHEN 'pg_constraint'::regclass THEN (SELECT conname FROM pg_constraint WHERE oid = pg_depend.refobjid)
           END                    AS refobjname,

       CASE deptype
           WHEN 'n' THEN 'normal'
           WHEN 'a' THEN 'auto'
           ELSE 'other'
           END                    AS deptype
FROM pg_depend
    );

SELECT *
FROM pg_depend_v
/*
 *classid::regclass::text показывает какой это тип объекта:
pg_class - таблица, индекс, последовательность
pg_constraint - ограничение (внешний ключ, уникальность)
pg_proc - функция
pg_type - тип данных
*
*/


-- Проверить, можно ли безопасно удалить таблицу
WITH RECURSIVE
    table_levels AS (SELECT c.oid,
                            c.relname               as table_name,
                            0                       as level,
                            ARRAY [c.relname::text] as path
                     FROM pg_class c
                              JOIN pg_namespace n ON n.oid = c.relnamespace
                     WHERE c.relkind = 'r'
                       AND n.nspname = 'bookings'
                       AND NOT EXISTS (SELECT 1
                                       FROM pg_constraint
                                       WHERE conrelid = c.oid
                                         AND contype = 'f')

                     UNION ALL

                     SELECT c.oid,
                            c.relname    as table_name,
                            tl.level + 1 as level,
                            tl.path || c.relname::text
                     FROM pg_constraint con
                              JOIN pg_class c ON c.oid = con.conrelid
                              JOIN pg_namespace n ON n.oid = c.relnamespace
                              JOIN table_levels tl ON tl.oid = con.confrelid
                     WHERE con.contype = 'f'
                       AND n.nspname = 'bookings'
                       AND c.relname != ALL (tl.path)
                       AND con.oid = (SELECT MIN(con2.oid)
                                      FROM pg_constraint con2
                                      WHERE con2.conrelid = con.conrelid
                                        AND con2.confrelid = con.confrelid)),
    distinct_tables AS (SELECT DISTINCT ON (level, table_name) level,
                                                               table_name,
                                                               (SELECT path
                                                                FROM table_levels t2
                                                                WHERE t2.level = t1.level
                                                                  AND t2.table_name = t1.table_name
                                                                LIMIT 1) as sample_path
                        FROM table_levels t1
                        ORDER BY level, table_name)
SELECT ROW_NUMBER() OVER (ORDER BY level DESC, table_name) as "№",
       level                                               as "Уровень",
       table_name                                          as "Таблица",
       array_to_string(sample_path, ' → ')                 as "Пример_зависимостей",
       CASE level
           WHEN 0 THEN '🟢 УДАЛЯТЬ ПОСЛЕДНИМИ - независимые таблицы'
           WHEN 1 THEN '🟡 УДАЛЯТЬ ТРЕТЬИМИ - зависят от справочников'
           WHEN 2 THEN '🟠 УДАЛЯТЬ ВТОРЫМИ - промежуточные таблицы'
           WHEN 3 THEN '🔴 УДАЛЯТЬ ПЕРВЫМИ - самые дочерние таблицы'
           ELSE '⚪ УДАЛЯТЬ на уровне ' || level
           END                                             as "Инструкция"
FROM distinct_tables
ORDER BY level DESC, table_name;


/*Узнать какие ключи поддерживаю каскадное удаление, а какие нет*/
SELECT c.relname   as child_table,
       p.relname   as parent_table,
       con.conname as foreign_key,
       CASE con.confdeltype
           WHEN 'a' THEN '❌ NO ACTION'
           WHEN 'r' THEN '❌ RESTRICT'
           WHEN 'c' THEN '✅ CASCADE'
           WHEN 'n' THEN '🔵 SET NULL'
           WHEN 'd' THEN '🟡 SET DEFAULT'
           ELSE '❓ UNKNOWN'
           END     as delete_rule,
       CASE
           WHEN con.confdeltype IN ('c', 'n', 'd') THEN 'МОЖНО каскадно'
           ELSE 'НЕЛЬЗЯ каскадно'
           END     as cascade_possible
FROM pg_constraint con
         JOIN pg_class c ON c.oid = con.conrelid
         JOIN pg_class p ON p.oid = con.confrelid
         JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE con.contype = 'f'
  AND n.nspname = 'bookings'
ORDER BY p.relname, c.relname;

/*Зависимость объектов базы данных от функций
 * не важно представлено ли ее тело ввиде символьной строки или
 * она написана в стиле сандарта SQL */

CREATE TEMP TABLE aircrafts_tmp
AS
SELECT *
FROM aircrafts

/* Создадим функцию для проверки допустимости кода модели самолета
 * в реальной жизни обходимся проверкой ограничения check*/

CREATE FUNCTION air_code_correct(a_code char)
    RETURNS boolean
RETURN a_code ~ '^[0-9A-Z]{3}$';


/*^ - начало строки
[0-9A-Z] - один символ из диапазона:
0-9 - цифры от 0 до 9
A-Z - заглавные буквы от A до Z
{3} - ровно 3 повторения предыдущего шаблона
строки*/

/*Добавим данное ограничение, основанное на этой фкнции*/

ALTER TABLE aircrafts_tmp
    ADD CHECK (air_code_correct(aircraft_code));

-- Детальная информация о таблице
-- Индексы таблицы
-- Полная информация о таблице aircrafts_tmp (аналог \d+)
WITH table_info AS (
    -- 1. Столбцы таблицы
    SELECT 1                                               as section,
           a.attnum                                        as order_num,
           a.attname                                       AS "Name",
           pg_catalog.format_type(a.atttypid, a.atttypmod) AS "Definition",
           CASE
               WHEN a.attnotnull THEN 'not null'
               ELSE ''
               END                                         AS "Modifiers"
    FROM pg_catalog.pg_attribute a
    WHERE a.attrelid = 'aircrafts_tmp'::regclass
      AND a.attnum > 0
      AND NOT a.attisdropped

    UNION ALL

    -- 2. Индексы
    SELECT 2                                           as section,
           row_number() OVER ()                        as order_num,
           i.relname                                   AS "Name",
           array_to_string(array_agg(a.attname), ', ') AS "Definition",
           CASE
               WHEN idx.indisunique THEN 'UNIQUE'
               ELSE ''
               END                                     AS "Modifiers"
    FROM pg_catalog.pg_index idx
             JOIN pg_catalog.pg_class i ON i.oid = idx.indexrelid
             JOIN pg_catalog.pg_class t ON t.oid = idx.indrelid
             JOIN pg_catalog.pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY (idx.indkey)
    WHERE t.relname = 'aircrafts_tmp'
    GROUP BY i.relname, idx.indisunique

    UNION ALL

    -- 3. Ограничения проверки
    SELECT 3                         as section,
           row_number() OVER ()      as order_num,
           conname                   AS "Name",
           pg_get_constraintdef(oid) AS "Definition",
           ''                        AS "Modifiers"
    FROM pg_constraint
    WHERE conrelid = 'aircrafts_tmp'::regclass
      AND contype = 'c')

SELECT CASE section
           WHEN 1 THEN 'Column'
           WHEN 2 THEN 'Index'
           WHEN 3 THEN 'Check'
           END AS "Type",
       "Name",
       "Definition",
       "Modifiers"
FROM table_info
ORDER BY section, order_num;

INSERT INTO aircrafts_tmp
VALUES ('96', 'Ильюшин ИЛ-96-300', 10000)

SELECT *
FROM pg_depend_v
WHERE refobjname = 'aircrafts_tmp'
  AND classname = 'pg_constraint'

/*Между двумя объектами может существовать и более одной связи,
 * теперь вясним какие ограничения зависят от функции air_code_correct
 */
SELECT *
FROM pg_depend_v
WHERE refobjname = 'air_code_correct'
  AND classname = 'pg_constraint'

/*Попробуем удалить функцию*/
DROP FUNCTION air_code_correct;
/*SQL Error [2BP01]: ERROR: cannot drop function air_code_correct(character) because other
 *objects depend on it
  Подробности: constraint aircrafts_tmp_aircraft_code_check on table aircrafts_tmp depends
  on function air_code_correct(character)
  Подсказка: Use DROP ... CASCADE to drop the dependent objects too.
 */
DROP FUNCTION air_code_correct CASCADE;

/*Воссоздадим функцию но само ограничение не
 * восстановится при этом*/
CREATE OR REPLACE FUNCTION air_code_correct(a_code char)
    RETURNS boolean
RETURN a_code ~ '^[0-9A-Z]{3}$';

/*В представленной команде есть важное отличие от предыдущей команды создания функции
 * а именно предложение OR REPLACE. Его наличие позволяет заменить тело существующей
 * функции не прибегая к помощи команды DROP FUNCTION.
 * Важно,что удаление существующей функции с помощью команды drop function
 * и последующее создание функций с той же  сигнатурой (то есть с тем же именем и с теми же входными параметрами) с помощью
 * команды create function не тождественно использованию лишь команды CREATE FUNCTION,
 * дополненной предложением OR REPLACE.
 * В первом случае воссозданная функция будет являться уже другой сущностью, отличной от первоначальной.
 * Функцию нельзя удалить, не удалив при этом и ссылающиеся на нее другие объекты.
 *
 */


/*Добавим ограничение на таблицу aircrafts_tmp с задействованной функцией в check
 * Далее мы проверим изменится ли значение oid при пересоздании функции*/
ALTER TABLE aircrafts_tmp
    ADD CHECK (air_code_correct(aircraft_code));


CREATE OR REPLACE FUNCTION air_code_correct(a_code char)
    RETURNS boolean
    LANGUAGE SQL
RETURN a_code ~ '^[0-9A-z]{3}$'; ---цифры и строчные буквы

SELECT oid, proname
FROM pg_proc
WHERE proname = 'air_code_correct'
---68582 идентификатор остался тем же,значит для системы это один и тот же объект.
/* Ограничение сохранилось Column	aircraft_code	character(3)
Column	model	text
Column	range	integer
Check	aircrafts_tmp_aircraft_code_check	CHECK (air_code_correct(aircraft_code))
*/


/*Таким образом,если от конкретной функции зависят конкретные объекты базы данных то при
 * ее удалении эти объекты также будут удалены
 * с учетом вида зависимости - deptype.
 * Однако при использовании предложения OR REPLACE  функция сохраняется с одним и тем же oid,
 * поэтому зависимые объекты также сохраняются.
 */

CREATE EXTENSION IF NOT EXISTS dblink; ----использование dblink
SELECT proname
FROM pg_proc
WHERE proname LIKE 'dblink%';

SELECT *
FROM dblink(
             'dbname=demo user=postgres password=Meduzafighter900',
             'SELECT acc_id,client_id
             from bookings.acc'
     ) AS t(acc_id bigint, client_id int);

/*зависимость функций от объектов базы данных
 * обратимся к системному каталогу pg_depend и
 * посмотрим от каких функций зависят
 * две наши функции
 *
 * Таким образом:
 * - если тело функции представлено строкой, ее зависимость
 * от удаляемых объектов обнаруживается только во время выполнения
 * запроса с этой функцией*
 *
 * - если функция написана на стандарте SQL, то  при попытке удаления объекта,
 * который она использует, возникает ошибка. Однако если команда удаления включает
 * в себя cascade, то будет удален не только этот объект,но и сама функция.
 *
 * В общем случае на выполнение операции удаления влияет вид зависимости между
 * объектами, который отражается в столбце depend системного каталога PG_DEPEND!!!
 */

SELECT DISTINCT classname,
                objname,
                refclassname,
                refobjname,
                deptype
FROM pg_depend_v
WHERE classname = 'pg_proc'
  AND objname IN ('make_or_update_booking', 'make_or_update_booking_sql')
  AND refclassname IN ('pg_proc', 'pg_class');


/*Функции, возвращающие множество строк
 *Функция определена как возвращающая setof routes это означает множество
 *значений типа routes
 *1.SETOF = "набор, множество"
 * Функция возвращает не одну строку, а несколько строк (как таблица)
 * Можно использовать как обычную таблицу в запросах
 *2.routes = тип строки таблицы routes
 * Возвращает строки той же структуры, что и таблица routes
 * Все колонки таблицы routes будут доступны
 * Если значения не будут переданы в функцию тозначения будут
 * использоваться по умолчанию
 */

CREATE OR REPLACE FUNCTION list_routes(
    d_city text DEFAULT 'Москва',
    a_city text DEFAULT 'Санкт_петербург'
)
    RETURNS SETOF routes AS
$$
select *
from routes
where departure_city = d_city
  and arrival_city = a_city;
$$ LANGUAGE SQL;


/*Нужно учитывать то, что при позиционной передачие аргументов мы не сможем передать
 * значение второго из них, не передав значение первого!!!
 * Однако это можно сделать с помощью именованного аргумента*/
SELECT flight_no,
       departure_city    AS dep_city,
       departure_airport AS dep_ap,
       arrival_city      AS arr_city,
       arrival_airport   AS arr_ap,
       days_of_week
FROM list_routes(a_city => 'Курган') ---по умолчанию  d_city = 'Москва'


CREATE OR REPLACE FUNCTION list_routes_2(
    d_city text DEFAULT 'Москва',
    a_city text DEFAULT 'Санкт_петербург'
)
    RETURNS SETOF record AS
$$
select r.flight_no, r.departure_city, r.arrival_city, a.model
from routes r
         join aircrafts AS a on a.aircraft_code = r.aircraft_code
where r.departure_city = d_city
  and r.arrival_city = a_city;
$$ LANGUAGE SQL;


/*Для того чтобы не было ошибки вывода данных, определим струткуру значения составного
 * типа, то есть зададим список с определениями столбцов.
 * Определение столбца - это его имя и тип данных а не просто псевдоним, которого
 * достаточно в других случаях. Конечно имена столбцов в этом списке могут не совпадать
 * с именами столбцов, которые используются внутри функции*/
SELECT f_no,
       dep_city,
       arr_city,
       model
FROM list_routes_2('Москва', 'Курган') AS lr (f_no char(6), dep_city text, arr_city text, model text)
ORDER BY f_no


/*Возникает вопрос  нельзя ли обойтись без задания списка при вызове функции, не создавая
 * составного типа.
 * Обойтись можно, для этого необходимо определить поля возвращаемого составного типа в заголовке
 * самой функции с помощью out параметров
*/

CREATE OR REPLACE FUNCTION list_routes_3(
    d_city text DEFAULT 'Москва',
    a_city text DEFAULT 'Санкт_петербург',
    OUT f_no char,
    OUT dep_city text,
    OUT arr_city text,
    OUT model text
)
    RETURNS SETOF record AS
$$
select r.flight_no, r.departure_city, r.arrival_city, a.model
from routes r
         join aircrafts AS a on a.aircraft_code = r.aircraft_code
where r.departure_city = d_city
  and r.arrival_city = a_city;
$$ LANGUAGE SQL;

Select *
FROM list_routes_3(d_city => 'Москва', a_city => 'Новосибирск');

/*Если потребуется заменить заголовки столбцов можно задать их псевдонимы (не определения!!!)
 * в промышленном коде заголовки столбцов должны быть указаны на английском языке*/

Select *
FROM list_routes_3(d_city => 'Москва', a_city => 'Новосибирск') AS f(Рейс, Откуда, Куда, Самолет)

/*Есть еще один способ объявления возвращаемого значения в виде множест ва строк:
 * предложение returns table со списком определений столбцов. Напомним чтоопределение
 * это не только имя столбца, но и его тип данных. Предложение return table эквивалеетно
 * комбианции предложений  returns setoff record или setof со скалярным типом и out - параметров.
 * Здесь нельзя определять параметры с модификаторами out и inout
 */

CREATE OR REPLACE FUNCTION list_routes_4(
    d_city text DEFAULT 'Москва',
    a_city text DEFAULT 'Санкт_петербург'
)
    RETURNS TABLE
            (
                f_no     char,
                dep_city text,
                arr_city text,
                model    text
            )
AS
$$
select r.flight_no, r.departure_city, r.arrival_city, a.model
from routes r
         join aircrafts AS a on a.aircraft_code = r.aircraft_code
where r.departure_city = d_city
  and r.arrival_city = a_city;
$$ LANGUAGE SQL;

/*Функции с переменным числом аргументов
Продолжим модернизировать исходную задачу
Число городов прибытия может быть различным,то есть не один,при
вызовах функции.
Реализовать такую логику работы можно с помощью параметра с модификатором
VARIADIC.
Он позволяет при вызове функции передавать ей переменное число
аргументов, аналогично функциям printf в языке C. Хотя параметр с модификатором
VARIADIC задается в виде массива, но на самом деле функция ожидает скалярные аргументы,
имеющие тип элементов этого массива.
Скалярные аргументы - это аргументы функций, которые принимают отдельные значения (скаляры),
а не наборы или таблицы данных.
При вызове функции, аргументы синтаксически-оформленные как скалярные, помещаются в массив и
передаются функции - как единый входной аргумент.
Внутри функции эти значения будут доступны ей в виде массива.
Неявно предполагается, чтопараметры с модификатором VARIADIC имеют модификатор IN.
Модификатор (modifier) в контексте SQL и баз данных - это ключевое слово или конструкция, которая
изменяет поведение оператора, функции, запроса или определения объекта.

Первым параметром является город отправления, вторым список городов прибытия.
Он объявлен как массив a_cities, содержащий элементы типа text. При этом длина массива
не указана, поскольку модификаторы при создании функции отбрасываются, зато он имеет
модификатор variadic.
Поскольку внутри функции список городов назначения будет представлен в виде массива, можно
воспользоваться оператором ANY.

*/

CREATE OR REPLACE FUNCTION list_routes_5(
    d_city text,
    VARIADIC a_cities text[]
)
    RETURNS SETOF routes AS
    --SETOF - модификатор, который означает: Функция возвращает набор строк (множество записей).
--А не одну строку
$$
select *
from routes
where departure_city = d_city
  and arrival_city = ANY (a_cities);
/*ANY() - функция-предикат, которая:
Проверяет, равен ли arrival_city ЛЮБОМУ элементу массива a_cities
Эквивалент: arrival_city IN ('Санкт-Петербург', 'Казань', 'Сочи')
*/
$$ LANGUAGE SQL;



SELECT *
FROM list_routes_5('Москва', 'Кемерово', 'Красноярск', 'Элиста')
ORDER BY arrival_city,
         days_of_week

/*Параметры с модификатором Variadic также могут иметь значения по умолчанию.
 * Представлять их нужно в виде массива, а не ввиде списка скалярных значений
 */


CREATE OR REPLACE FUNCTION list_routes_6(
    d_city text,
    VARIADIC a_cities text[] DEFAULT ARRAY ['Москва', 'Санкт-Петербург']::text[] ---массив по умолчанию
)
    RETURNS SETOF routes AS
    --SETOF - модификатор, который означает: Функция возвращает набор строк (множество записей).
--А не одну строку
$$
select *
from routes
where departure_city = d_city
  and arrival_city = ANY (a_cities);
/*ANY() - функция-предикат, которая:
Проверяет, равен ли arrival_city ЛЮБОМУ элементу массива a_cities
Эквивалент: arrival_city IN ('Санкт-Петербург', 'Казань', 'Сочи')
*/
$$ LANGUAGE SQL;


SELECT *
FROM list_routes_6('Элиста')
ORDER BY arrival_city,
         days_of_week

/*Также список городов можно получить с помощью подзапроса, тонаша функция подойдет
 * и для такого случая. Массив можно сформировать с помощью конструктора ARRAY (
 * конструкторы массивов) Передавая функции параметр-массив вместо списка
 * скалярных значений, следует обяхательно добавить модификатор variadic
 *
 * Таким образом можно выбирать способ передачи аргументов с параметр с
 * модификатором VARIADIC: либо список скалярных значений одного и того же типа
 * либо массив но вто втором случае приходится добавлять это же ключевое слово
 * при вызове функции
 */

EXPLAIN ANALYZE
SELECT *
FROM list_routes_6('Санкт-Петербург',
                   VARIADIC ARRAY(SELECT city FROM airports WHERE city = 'Москва')
     )
ORDER BY arrival_city,
         days_of_week


EXPLAIN ANALYZE
SELECT *
FROM list_routes_6('Санкт-Петербург', 'Moscow')
ORDER BY arrival_city,
         days_of_week


/*Создадим функция формирует несколько столбцов, совокупность которых не соответствует
 * какому либо существующему составному типу данных*/

CREATE OR REPLACE FUNCTION list_routes_7(
    d_city text DEFAULT 'Москва',
    VARIADIC a_cities text[] DEFAULT ARRAY ['Москва', 'Санкт-Петербург']::text[], ---массив по умолчанию
    OUT f_no char,
    OUT dep_city text,
    OUT arr_city text,
    OUT model text
)
    RETURNS SETOF record AS
$$
select r.flight_no, r.departure_city, r.arrival_city, a.model
from routes r
         join aircrafts AS a on a.aircraft_code = r.aircraft_code
where r.departure_city = d_city
  and r.arrival_city = ANY (a_cities);
$$ LANGUAGE SQL;

EXPLAIN ANALYZE
SELECT *
FROM list_routes_7()


/*С использованием ETURNS TABLE */
CREATE OR REPLACE FUNCTION list_routes_8(
    d_city text DEFAULT 'Москва',
    VARIADIC a_cities text[] DEFAULT ARRAY ['Москва', 'Санкт-Петербург']::text[]
)
    RETURNS TABLE
            (
                f_no     char(6),
                dep_city text,
                arr_city text,
                model    text
            )
AS
$$
SELECT r.flight_no,
       r.departure_city,
       r.arrival_city,
       a.model
FROM routes r
         JOIN aircrafts AS a ON a.aircraft_code = r.aircraft_code
WHERE r.departure_city = d_city
  AND r.arrival_city = ANY (a_cities);
$$
    LANGUAGE SQL;

EXPLAIN ANALYZE
SELECT *
FROM list_routes_8()

/*Удаление перегруженных функций
 */

         DROP FUNCTION IF EXISTS list_routes_6(text,text[])

DROP FUNCTION IF EXISTS list_routes_5
---если перегруженной функции нет, то можно опустить список данных

/*Конструкция Lateral и функции
Все табличные функции, разработанные нами до сих пор, получали в качестве аргумента название только
ондого города отправления.
А если нам потребуется выбрать все маршруты между городами того или иного часвого пояса?
Возьмем для примера часовой пояс, в котором число городов слишком велико для того, чтобы
легко решить задачу, выполняя несколько однотипных запросов.
Для эксперимента подходит часовой пояс Asia/Yekaterinburg, в котором 22 аэропорта.
Мы бы решили задачу, если бы могли в рамках одного запроса выбирающего все города в часовом поясе
Asia/Yekaterinburg, вызывать функцию list_routes_7 для каждой выбираемой строки, так чтобы из
этой строки функция получала значение своего первого параметра.
Такая возможность есть при помощи Lateral команды Select.
Запрос выполняется так - сканируется таблица аэропорты и для ее текущей строки вызывается
функция list_routes_7 , которая в качестве первого аргумента получает значение поля a.city
из этой строки. Строки, возвращенные функцией, соединяются с этой строкой таблицы Аэропорты
обычным образом как это делается для строк соединяемых таблиц. Затем эти же действия
повторяются для следующей строки таблицы Аэропорты, так шаг за шагом формируется
результирующее множество строк.
Левое внешнее соединение гарантирует формирование результирующей строки выборки
даже в том случае, если функция не возвратит ни одной строки.

ДЛЯ КАЖДОГО города в списке:
    ВЫЗВАТЬ функцию поиска_рейсов(этот_город, весь_список_городов)

*/

---Всегда показывает города, даже если нет рейсов
EXPLAIN(ANALYZE, costs OFF, timing OFF)
SELECT a.city AS dep_city,
       lr.arr_city,
       lr.f_no,
       lr.model
FROM airports AS a
         LEFT JOIN LATERAL list_routes_7(
        a.city,
        VARIADIC ARRAY(SELECT city FROM airports WHERE timezone = 'Asia/Yekaterinburg')
                           ) AS lr ON TRUE
WHERE a.timezone = 'Asia/Yekaterinburg'
ORDER BY dep_city, lr.arr_city;



---Показывает ТОЛЬКО города, у которых ЕСТЬ рейсы
---Это как "дайте только тех, у кого есть"
EXPLAIN(ANALYZE, costs OFF, timing OFF)
SELECT a.city AS dep_city,
       lr.arr_city,
       lr.f_no,
       lr.model
FROM airports AS a
         CROSS JOIN LATERAL list_routes_7(
        a.city,
        VARIADIC ARRAY(SELECT city FROM airports WHERE timezone = 'Asia/Yekaterinburg')
                            ) AS lr
WHERE a.timezone = 'Asia/Yekaterinburg'
ORDER BY dep_city, lr.arr_city;

/*
Берёте первый город (например, Екатеринбург)
Открываете расписание и смотрите:
Есть ли рейс Екатеринбург → Челябинск?
Есть ли рейс Екатеринбург → Тюмень?
Есть ли рейс Екатеринбург → Уфа?
... и так для всех 21 города
Записываете всё, что нашли

Берёте второй город (Челябинск)
Снова смотрите:
Челябинск → Екатеринбург?
Челябинск → Тюмень?
... и т.д.
Повторяете для всех 22 городов

Итог: Вы сделаете 22 × 21 = 462 проверки!

Почему LEFT JOIN LATERAL ... ON TRUE?
Это значит "соедини ВСЕГДА". Даже если для города нет рейсов,
всё равно покажи этот город в результатах (просто колонки рейсов будут пустые).

*/

/*Категории изменчивости функций
 * Каждая функция написанная нами имеет очень важную характеристику: категорию
 * изменчивости (volatility) это свойство проявляется в двух формах
 * Категория изменчивости как сказано в разделе документации 36.7. представляет
 * собой общение некоторого предсказуемого поведения функции.
 * Это позволяет оптимизатору построить более экономичный план выполнения запроса
 * Второй стороной категории изменичовсти является видимость собственных изменений,
 * доступны ли функции, вызываемой в SQL операторе, те изменения базы данных, которые
 * произвел этот оператор
 *
 * Всего существет три категории изменчивости функции
 * volatile - изменчивая,
 * stable - стабильная,
 * immutable - постоянная
 *
 * volatile - изменчивая функция может не только читать, но и изменять данные,
 * важно чтов рамках одного sql запроса она может возвращать различные результаты,
 * если будет вызвана несколько раз с одинаковыми аргументами или без аргументов,
 * если у функции нет параметров. Если аргменты различаются, тои возвращаемые параметры
 * не обязаны быть одними и теми же.
 * Когда в запросе присутствует изменчивая функция то оптимизатор не делает никаких
 * предположений о ее поведении, поэтому значение фукнции будет вычисляться каждый раз,
 * когда потребуется.
 *
 * stable - функция не может модифицировать базу данных, она получает одинаковые аргументы
 * и возвращает одинаковые результаты. Это позволяет оптимизатору заменить множество
 * вызовов этой функции одним.
 * Оптимизатор может применить индекс для поиска по условию включающему вызов функции.
 * Но при индексном доступе значение вычисляется только один раз, а не для каждой строки,
 * поэтому функция должна быть стабильной, планировщик не будет использовать индекс,
 * если в условии присутствует функция с характеристиками volatile!!!
 *
 * Самой строгой категорией является постоянная - immutable. Функция с такой категорией
 * не может модифицировать базу данных, она всегда возвращает одинаковые результаты
 * для одинаковых значений аргументов. Если аргументы являются константами, то оптимизатор
 * может вычислить значение функции еще на стадии планирования.
 *
 * Важно понимать что первичным является содержание функции а не категория изменчивости,
 * то есть катогрия назначается в зависимости от операций, выполняемых фукнцией.
 *
 *
 *
 */

SELECT
    -- Схема.Имя
    (SELECT nspname FROM pg_namespace WHERE oid = pronamespace) || '.' || proname AS "Function",
    proargtypes::regtype[],
    -- Аргументы
    pg_get_function_arguments(oid)                                                AS "Arguments",

    -- Возвращаемый тип
    CASE proretset
        WHEN true THEN 'SETOF '
        ELSE ''
        END || format_type(prorettype, NULL)                                      AS "Result type",

    -- Изменчивость
    CASE provolatile
        WHEN 'i' THEN 'Immutable'
        WHEN 's' THEN 'Stable'
        WHEN 'v' THEN 'Volatile'
        END                                                                       AS "Vol",

    -- Параллельность
    CASE proparallel
        WHEN 's' THEN 'SAFE'
        WHEN 'u' THEN 'UNSAFE'
        WHEN 'r' THEN 'RESTRICTED'
        END                                                                       AS "Par",

    -- Тип
    CASE prokind
        WHEN 'f' THEN 'func'
        WHEN 'p' THEN 'proc'
        WHEN 'a' THEN 'agg'
        WHEN 'w' THEN 'win'
        ELSE '???'
        END                                                                       AS "Type",

    -- Язык
    (SELECT lanname FROM pg_language WHERE oid = prolang)                         AS "Lang",

    -- Владелец
    (SELECT usename FROM pg_user WHERE usesysid = proowner)                       AS "Owner",

    -- Описание (кратко)
    COALESCE(
            (SELECT SUBSTRING(description FROM 1 FOR 50) ||
                    CASE WHEN LENGTH(description) > 50 THEN '...' ELSE '' END
             FROM pg_description
             WHERE objoid = pg_proc.oid),
            '-'
    )                                                                             AS "Description"

FROM pg_proc
WHERE proname LIKE '%random%'
   OR proname LIKE '%date_part%'
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'pg_catalog')
ORDER BY proname, pronargs;


SELECT random(1, 20), random(1, 20)
FROM generate_series(1, 6) AS g


EXPLAIN ANALYZE
SELECT current_timestamp


/*Три вызова current_timestamp и date_part заменяются одним*/
           EXPLAIN ANALYZE
SELECT *
FROM generate_series(1, 3)
WHERE date_part('year', current_timestamp) = '2025'

/*Филтрация строк теперь отсутствует проверка условия
 * whrere была выполнена еще на этапе планирования*/
EXPLAIN ANALYZE
SELECT *
FROM generate_series(1, 3)
WHERE date_part('year', '2025-12-06 19:08:33'::timestamp) = '2025'


WITH distinct_letters(aircraft_code, letter) AS
         (SELECT DISTINCT aircraft_code, RIGHT(seat_no, 1)
          FROM seats),

     arrays_of_letters AS (SELECT aircraft_code, array_agg(letter ORDER BY letter) AS letters
                           FROM distinct_letters
                           GROUP BY aircraft_code)

SELECT aircraft_code, letters
FROM arrays_of_letters
ORDER BY array_length(letters, 1) DESC, aircraft_code;
---array_length(массив, размерность) возвращает длину массива по указанной размерности.

/*
array_length(ARRAY['A','B','C'], 1) → 3
array_length(ARRAY['A'], 1)         → 1
*/

/*Физический смысл PREPARE
Физически PREPARE — это:
Кэширование плана запроса в памяти сервера
Разделение кода и данных на уровне сетевых пакетов
Прекомпиляция дерева выполнения запроса
Решаемые задачи:
✅ Производительность — снижение нагрузки CPU на 60-90%
✅ Безопасность — гарантированная защита от инъекций
✅ Масштабируемость — эффективная работа под высокой нагрузкой
✅ Стабильность — предсказуемое время выполнения запросов
Используйте подготовленные операторы когда:
Один запрос выполняется >10 раз в минуту
Требуется защита от SQL-инъекций
Работаете с высоконагруженными сервисами
Выполняете ETL-процессы или пакетные операции
*/


/*Видиомсть изменений
 * Возникает еще один вопрос видит ли функция изменения, сделанные запросом, из которого
 * она вызвается.
 * Ответ на него также зависит от категории изменчивости функции, а вот от уровня изоляции
 * транзакции не зависит.
 * У функций, написанных на SQL или на любом другом стандартном процедурном языке, есть ещё одно важное свойство,
 *  определяемое характеристикой изменчивости, а именно видимость изменений, произведённых
 * командой SQL, которая вызывает эту функцию. Функция VOLATILE будет видеть такие изменения,
 * тогда как STABLE и IMMUTABLE — нет. Это поведение реализуется посредством снимков в MVCC
 * (см. Главу 13): STABLE и IMMUTABLE используют снимок, полученный в начале вызывающего запроса,
 * тогда как функции VOLATILE получают свежий снимок в начале каждого запроса, который они
 * выполняют.
 *
 * В качестве иллюстарции раширим демобазу уетом числа мест багажа и его общего веса
 * при регистрации каждого пассажаира. К завершению регистрации будут получены итоговые
 * значения, необходимые службе, доставляющей багаж на борт самолета, и пилотам для
 * расчета взлетных характеристик.
 * Созадидм таблиwe Багаж - luggage.
 */

CREATE TABLE luggage
(
    flight_id   integer,
    boarding_no integer,
    piece_no    SMALLINT NOT NULL CHECK (piece_no > 0),
    weight      numeric(3, 1) CHECK (weight > 0.0 ),
    PRIMARY KEY (flight_id, boarding_no, piece_no),
    FOREIGN KEY (flight_id, boarding_no)
        REFERENCES boarding_passes (flight_id, boarding_no) ON DELETE CASCADE
);

/*Нам необходимо две функции - первая будет
 * вводить в таблицы сведения об очередном пассажире,
 * включая его багаж, а вторая подводить текущие итоги*/

CREATE OR REPLACE FUNCTION BOARDING(
    FLIGHT_ID INTEGER,
    BOARDING_NO INTEGER,
    VARIADIC WEIGHTS NUMERIC[]
    ---VARIADIC позволяет передать произвольное количество
    ---аргументов, которые автоматически упаковываются в массив.
) RETURNS VOID AS ---void НЕ ВОЗВРАЩАЕТ никакого значения
$$
with luggage_pieces as
         (select boarding.flight_id,
                 boarding.boarding_no,
                 num,
                 weight
          from unnest(weights) with ordinality lw(weight, num))
insert
into luggage(flight_id, boarding_no, piece_no, weight)
select boarding.flight_id,
       boarding.boarding_no,
       num,
       weight
from luggage_pieces;
$$ LANGUAGE SQL VOLATILE;

/*вторая функция собирает данные о количестве зарегистрированных
 * пассажиров, общем числе мест багажа и его общем весе
 */
DROP FUNCTION BOARDING_INFO;

CREATE OR REPLACE FUNCTION BOARDING_INFO(
    INOUT FLIGHT_ID INTEGER,
    OUT TOTAL_PASSENGERS BIGINT,
    OUT TOTAL_LUGGAGE_PIECES BIGINT,
    OUT TOTAL_LUGGAGE_WEIGHT NUMERIC
)
    RETURNS RECORD AS
$$
with boarding_pass_info as
         (select count(*) as total_passengers
          from boarding_passes
          where flight_id = boarding_info.flight_id),

     luggage_info as
         (select count(*)    as total_luggage_pieces,
                 sum(weight) as total_luggage_weight
          from luggage
          where flight_id = boarding_info.flight_id)

select flight_id,
       bpi.total_passengers,
       li.total_luggage_pieces,
       li.total_luggage_weight
from boarding_pass_info as bpi,
     luggage_info as li;
$$ LANGUAGE SQL STABLE;

/*Число посадочных талонов равно 0*/
SELECT count(*)
FROM boarding_passes
WHERE flight_id = 13841;

/*для регистрации понадобятся номера билетов купленных на этот рейс
 */

SELECT tf.ticket_no,
       tf.fare_conditions
FROM ticket_flights tf
WHERE flight_id = 13841
ORDER BY tf.ticket_no;

/*также нам необходимо знать компоновку салона самолета
 * Аэробус A-319 для корректного размещения регистриуремых пассажиров
 * в соответствии с классом обслуживания, указанных в билете
 * На всех уровнях изоляции  транзакций изменичвая функция
 * видит изменения, призведленные в базе данных запросом,
 * из которого она вызвана,  стабильная stable - нет.
 */

SELECT seat_no, fare_conditions
FROM seats
WHERE aircraft_code = '319'
ORDER BY left(seat_no, length(seat_no) - 1)::integer, right(seat_no, 1);
----- Сначала по числу (ряду)
----- Затем по букве

BEGIN ISOLATION LEVEL READ COMMITTED;
-- Теперь:
-- 1. Вы НЕ увидите незафиксированные изменения других транзакций
-- 2. Вы УВИДИТЕ изменения других транзакций после их COMMIT
-- 3. В рамках одной транзакции может быть "неповторяемое чтение"

ALTER FUNCTION boarding_info VOLATILE;
----BEGIN ISOLATION LEVEL READ COMMITTED;

WITH make_boarding AS
         (
             INSERT
                 INTO
                     boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
                     VALUES ('0005433846800', 13841, 1, '1A')
                     RETURNING *)
SELECT bi.flight_id,
       bi.total_passengers,
       bi.total_luggage_pieces,
       bi.total_luggage_weight
FROM make_boarding AS mb,
     boarding(mb.flight_id, mb.boarding_no, 15.0, 12.5) AS b,
     boarding_info(mb.flight_id) AS bi

/*Дополнительные сведения о функциях
 * Подстановка кода функций в запрос
 * Создадим функцию которая подсчитывает число
 * пассажиров, перевезенных по каждому маршруту за весь период времени,
 * представленный в базе данных
 */

CREATE OR REPLACE FUNCTION count_passengers(OUT f_no char, OUT pass_num bigint)
    RETURNS SETOF record AS
/*
Что такое SETOF record?
SETOF = множество (может быть 0, 1 или много строк)
record = запись (строка с неопределённой структурой)
Вместе: возвращает таблицу с двумя колонками
*/
$$
select flight_no,
       count(*)
from flights as f
         join boarding_passes AS bp ON bp.flight_id = f.flight_id
where status in ('Departed', 'Arrived')
group by flight_no;
$$
    LANGUAGE SQL VOLATILE;


EXPLAIN ANALYZE
SELECT f_no, pass_num
FROM count_passengers()
ORDER BY pass_num DESC;


ALTER FUNCTION count_passengers VOLATILE;
/*Сначала выполняется функции а потом из результат выполнения берется всего одна строка
 * Function Scan on count_passengers  (cost=0.10..6.10 rows=5 width=40) (actual time=136.957..136.970 rows=1 loops=1)
  Filter: (f_no = 'PG0149'::bpchar)
  Rows Removed by Filter: 469
Planning Time: 0.044 ms
Execution Time: 137.004 ms
 */
EXPLAIN ANALYZE
SELECT f_no, pass_num
FROM count_passengers()
WHERE f_no = 'PG0149';

/*Можно ли каким-то образом ускорить  выполнение запроса, давайте
 * назначим этой функции категорию изменчивости STABLE.
 * Функция не изменяет базу данных значит мы приняли
 * правомерное решение об использовании  STABLE.
 *Subquery Scan on "*SELECT*"  (cost=0.29..670.54 rows=34 width=40) (actual time=0.430..0.431 rows=1 loops=1)
  ->  GroupAggregate  (cost=0.29..670.54 rows=34 width=15) (actual time=0.429..0.430 rows=1 loops=1)
        Group Key: f.flight_no
        ->  Nested Loop  (cost=0.29..669.29 rows=540 width=7) (actual time=0.040..0.331 rows=1333 loops=1)
              ->  Index Scan using flights_flight_no_scheduled_departure_key on flights f  (cost=0.12..73.02 rows=35 width=11) (actual time=0.022..0.044 rows=31 loops=1)
                    Index Cond: ((flight_no)::bpchar = 'PG0149'::bpchar)
                    Filter: ((status)::text = ANY ('{Departed,Arrived}'::text[]))
                    Rows Removed by Filter: 30
              ->  Index Only Scan using boarding_passes_flight_id_seat_no_key on boarding_passes bp  (cost=0.17..16.77 rows=53 width=4) (actual time=0.003..0.007 rows=43 loops=31)
                    Index Cond: (flight_id = f.flight_id)
                    Heap Fetches: 488
Planning Time: 0.360 ms
Execution Time: 0.461 ms

Функция тсала прозрачной для планировщика запросов
 */
    ALTER FUNCTION count_passengers STABLE;

EXPLAIN ANALYZE
SELECT f_no, pass_num
FROM count_passengers()
WHERE f_no IN ('PG0149', 'PG0148');

/*Функции и параллельный режим выполнения запросов
 *
 * В Postgresql при выполнении ряда условий запрос может быть
 * выполнен в параллельном режиме. В этом случае в помощь основному
 * ведущему процессу создаются один или несколько фоновых рабочих процессов,
 * которые берут его часть работы на себя. Глава 15 в справке Postgresql Pro-
 * Параллельный запрос.
 *
 * Характеристика функции parallel может влиять на принятие планировщиком решения о выборке
 * режима выполнения. Это характеристика принимает одно из следующих значений:
 * SAFE - функция может без ограничений выполняться в параллельном режиме;
 * RESTRICTED - функция может работать только в ведущем процессе,
 * но не препятствует распараллеливанию запроса.
 * UNSAFE - функция запрещает распараллеливание запроса (это значение выбирается
 * по умолчанию при создании функции)
 * Для многих запросов параллельное выполнение не даёт никакого выигрыша, либо из-за
 * ограничений текущей реализации, либо из-за принципиальной невозможности построить
 * параллельный план, который был бы быстрее последовательного!!! Однако для запросов, в
 * которых это может быть полезно, распараллеливание часто даёт очень значительное ускорение.
 *  Многие такие запросы могут выполняться в параллельном режиме как минимум вдвое быстрее,
 * а некоторые — быстрее в четыре и даже более раз. Обычно наибольший выигрыш можно получить
 * с запросами, обрабатывающими большой объём данных, но возвращающими пользователю всего
 * несколько строк!!!
 */

CREATE OR REPLACE
    FUNCTION get_amount_range(
    amount NUMERIC,
    range_width integer,
    OUT min_amount integer,
    OUT max_amount integer
)
    LANGUAGE SQL
    IMMUTABLE PARALLEL SAFE
BEGIN
    ATOMIC
    SELECT RANGE * range_width,
           (RANGE + 1) * range_width
    FROM (SELECT div(amount, range_width) AS RANGE);
END;

/*Вторая функци похожа на первую но предназначена для дат и
 * работает с фиксированной шириной диапазона, равной семи дням
 * она определяет понедельник, воскресенье той недели, на которую
 * выпадает указанная дата
 * Обе функции написаны в стиле стандарта SQL, каждая содержит только один
 * оператор, однако нам пришлось использовать синтаксис begin atomic ...end
 * из-за двух возвращаемых значений*/


CREATE OR REPLACE
    FUNCTION get_date_range(
    dt date,
    OUT monday date,
    OUT sunday date
)
    LANGUAGE SQL
    IMMUTABLE PARALLEL SAFE
BEGIN
    ATOMIC
    SELECT prev_sunday + 1,
           prev_sunday + 7
    FROM (SELECT dt - extract(isodow FROM dt)::integer AS prev_sunday);
END;


/*
┌─────────────────────────────────────────────────────────────┐
│                    ШАГ 0: ИСХОДНЫЕ ДАННЫЕ                   │
└─────────────────────────────────────────────────────────────┘
Таблица bookings:
┌─────────────┬──────────────┬─────────────────┐
│ booking_id  │ total_amount │    другие       │
│   (PK)      │   (numeric)  │     поля        │
├─────────────┼──────────────┼─────────────────┤
│     1       │   150,000    │      ...        │
│     2       │   280,000    │      ...        │
│     3       │    90,000    │      ...        │
│     4       │   450,000    │      ...        │
│     5       │   120,000    │      ...        │
│     6       │   310,000    │      ...        │
│     7       │    85,000    │      ...        │
│     8       │   190,000    │      ...        │
└─────────────┴──────────────┴─────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         ШАГ 1: CROSS JOIN LATERAL (строка за строкой)       │
└─────────────────────────────────────────────────────────────┘

Для КАЖДОЙ строки bookings вызываем get_amount_range(total_amount, 100000):

ПРОЦЕСС:
1. Берём строку booking_id=1 → total_amount=150,000
   ┌───────────────┐
   │ Функция       │
   │ get_amount_   │ input: (150000, 100000)
   │ range()       │ → output: (100000, 200000)
   └───────────────┘
   Результат: (min=100000, max=200000)

2. Добавляем к исходной строке:
   ┌─────┬──────────────┬────────────┬────────────┐
   │ bid │ total_amount │ min_amount │ max_amount │
   ├─────┼──────────────┼────────────┼────────────┤
   │  1  │   150,000    │  100,000   │  200,000   │
   └─────┴──────────────┴────────────┴────────────┘

ПОВТОРЯЕМ ДЛЯ ВСЕХ СТРОК:

┌─────┬──────────────┬────────────┬────────────┐
│ bid │ total_amount │ min_amount │ max_amount │
├─────┼──────────────┼────────────┼────────────┤
│  1  │   150,000    │  100,000   │  200,000   │
│  2  │   280,000    │  200,000   │  300,000   │
│  3  │    90,000    │    0       │  100,000   │
│  4  │   450,000    │  400,000   │  500,000   │
│  5  │   120,000    │  100,000   │  200,000   │ ← Та же пара!
│  6  │   310,000    │  300,000   │  400,000   │
│  7  │    85,000    │    0       │  100,000   │ ← Та же пара!
│  8  │   190,000    │  100,000   │  200,000   │ ← Та же пара!
└─────┴──────────────┴────────────┴────────────┘


                  ┌─────────────────┐
                  │   bookings      │
                  │  (8 строк)      │
                  └────────┬────────┘
                           │ CROSS JOIN LATERAL
                           │ (строка за строкой)
                           ▼
           ┌─────────────────────────────────────┐
           │ Для КАЖДОЙ строки вызываем:         │
           │ get_amount_range(total_amount, 100k)│
           └─────────────────────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           │                               │
           ▼                               ▼
┌─────────────────────┐         ┌─────────────────────┐
│  Промежуточный      │         │  Промежуточный      │
│  результат для      │         │  результат для      │
│  строки 1:          │         │  строки 2:          │
│  (150k, 100k, 200k) │         │  (280k, 200k, 300k) │
└─────────────────────┘         └─────────────────────┘
           │                               │
           └───────────────┬───────────────┘
                           │
          Все 8 строк собраны в одну таблицу
                           │
                           ▼
           ┌─────────────────────────────────────┐
           │  8 строк с полями:                  │
           │  bid, total_amount, min, max        │
           └─────────────────────────────────────┘
                           │
                           ▼ GROUP BY (min, max)
           ┌─────────────────────────────────────┐
           │  Группы:                            │
           │  • (0, 100k): 2 строки              │
           │  • (100k, 200k): 3 строки           │
           │  • (200k, 300k): 1 строка           │
           │  • (300k, 400k): 1 строка           │
           │  • (400k, 500k): 1 строка           │
           └─────────────────────────────────────┘
                           │
                           ▼ Агрегация (COUNT, SUM)
           ┌─────────────────────────────────────┐
           │  Для каждой группы:                 │
           │  1. COUNT(*) → количество           │
           │  2. SUM(total_amount) → сумма       │
           └─────────────────────────────────────┘
                           │
                           ▼ ORDER BY min_amount
                  ┌─────────────────┐
                  │  ФИНАЛЬНЫЙ      │
                  │  РЕЗУЛЬТАТ      │
                  │  (5 строк)      │
                  └─────────────────┘


1. FROM/JOIN → "Какие данные берём и как соединяем"
2. WHERE → "Какие строки фильтруем"
3. GROUP BY → "Как группируем"
4. Агрегации → "Что считаем в группах"
5. HAVING → "Какие группы фильтруем"
6. SELECT → "Что показываем"
7. ORDER BY → "Как сортируем"


 */

SELECT amount_range.min_amount AS min_amount_k,
       amount_range.max_amount AS max_amount_k,
       COUNT(*)                AS booking_count, -- ← ДОБАВИЛИ!
       SUM(b.total_amount)     AS total_sum      -- ← ДОБАВИЛИ!
FROM bookings b
         CROSS JOIN LATERAL get_amount_range(b.total_amount, 100000) AS amount_range
----CROSS JOIN LATERAL func(...) =
----"Для каждой строки левой таблицы → вызвать функцию → добавить результат"
GROUP BY amount_range.min_amount, amount_range.max_amount
ORDER BY min_amount_k;


SELECT week.monday         AS monday,
       week.sunday         AS sunday,
       COUNT(*)            AS booking_count, -- ← ДОБАВИЛИ!
       SUM(b.total_amount) AS total_sum      -- ← ДОБАВИЛИ!
FROM bookings b
         CROSS JOIN LATERAL get_date_range(b.book_date::date) AS week
----CROSS JOIN LATERAL func(...) =
----"Для каждой строки левой таблицы → вызвать функцию → добавить результат"
GROUP BY week.sunday, week.monday



SELECT dt::date, -- Явно приводим к DATE!
       extract(isodow FROM dt::date)                     as iso_day,
       dt::date - extract(isodow FROM dt::date)::integer as result
FROM generate_series('2024-03-11'::date, '2024-03-31'::date, '1 day') as dt;

/*Теория принятия решений
  Никто не станет спорить с тем чтодля принятия обоснованных решений нужна полная и достоверная информация.
  Однако не менее важны и адекватные методы.
  Для нашей задачи выберем метод формирования множества Парето.
  Критерий Парето таков: Следует считать, что любое изменение, которое никому не причиняет убытков
  и которое приносит некоторым людям пользу, является улучшением.
  Говоря более строгим языком система находится в Парето-оптимальном состоянии, когда ни один
  ее показатель не может быть улучшен без ухудшения какого-либо другого показателя.

  Предположим, что нашей авиакомпании потребовался поставщик качественных обедов для пассажиров.
  В теории принятия решений варианты выбора называют альтернативами. Принятие решения в нашем
  случае заключается в быборе лучше альтернативы, то есть наиболее подходящего варианта обеда.
  Показатели для оценк альтернатив выберем следующие:
  - калорийность;
  - разнообразие;
  - цена.


  В литературе по теории принятия решений показатели зачастую называют критериями, хотя это,
  строго говоря не одно и тоже. Критерий - это правило интерпретации значений показателя,
  например отнесения конкретного значения к группе допустимых или недопустимых. Критерии
  разделяются на позитивные и негативные.
  Для позитивного критерия желательным является увеличение его значения,
  а для негативного - уменьшение.

  Если альтернативы оценивают по нескольким критериям, как в нашем примере, тотакая задача принятия
  решений называется многокритериальной.
  В многокритериальных задачах проявляется эффект несравнимости альтернатив. Что это такое?
  В рассматриваемом методе - формирования множества Парето - важнейшим является доминирование
  альтернатив.
  Альтернатива А называется доминирующей по отношению к альтернативе В, еслиоценки альтернативы
  А по всем критериям не хуже, чем оценки альтернативы В, а хотя бы по одному критерию строго лучше.
  При этом альтернатива В является доминируемой.
  Если же альтернатива А првосходит альтернативу В по одним критериям, но уступает ей по другим,
  тогда эти альтернативы несравнимы. Точнее говоря, их можно сравнить, но для этого нужно привлечь
  дополнительные критерии.

  💼 Пример из бизнеса: выбор стратегии
        Стратегия	    Рост выручки	Риски	   Срок окупаемости
        Агрессивная	    Высокий (+50%)	Высокие	     1 год
        Консервативная	Низкий (+10%)	Низкие	     3 года
        Умеренная	    Средний (+25%)	Средние	     2 года
Все три стратегии несравнимы:
Нет стратегии, которая лучше по всем параметрам
Выбор зависит от аппетита к риску и срочности получения результата

Глубокая мысль:
Несравнимость — это не проблема метода, а свойство реального мира.
В сложных решениях почти всегда приходится выбирать между несравнимыми вариантами.
Пример из жизни:
Выбрать между высокооплачиваемой работой с переработками и низкооплачиваемой с
свободным временем — несравнимые альтернативы, потому что сравниваете деньги с временем.


Если из исходного множества альтернатив отобрать недоминируемые (это вариант, который никто не
  превосходит по всем параметрам одновременно), то это подмножество и будет
  множеством Парето для исходного множества. Любая альтернатива, входящая м ножество Парето, будет
  предпочтительнее любой из оставшихся альтернатив исходного множества. Однако между собой
  альтернативы из множества Парето несравнимы.

  Таким образом, альтернатива называется Парето - оптимальной, если для нее не существует
  доминирующей альтернативы. Для Парето-оптимальной альтернативы нельзя найти другую альтернативу,
  которая превосходила бы ее хотя бы по одному критерию и при этом ни по одному не уступала бы.
  Во многих методах принятия решений формирование множества Парето выполняется в качестве
  первого этапа. Если требуется выбрать одну лучшую (по многим критериям) альтернативу, то
  она обязательно принадлежит этому множеству. Цель такого этапа сузить исходное множество
  альтернатив, с тем чтобы потом с помощью привлечения дополнительной информации выбрать
  из него одну - лучшую - альтернативу.

  Один из способов формирования множества Парето - попарное сравнение альтернатив и исключение
  доминируемых. Именно его мы и покажем.

  Если из двух сранивмаемых альтернатив А и В альтернатива А оказалась лучше, чем В, тоальтернатива
  В однозначно не должна быть включена во множество Парето!!!
  Однако насчет альтернативы А, победившей в этом сравнении, пока еще ничего сказать нельзя: ведь
  при ее сравнении с другими альтернативами может найтись такая, которая окажется лучше А (
  тогда А не войдет во множество Парето), но может и не найтись (тогда А войдет во множество Парето).

  Когда множество Парето определено, для отыскания единственной оптимальной альтернативы среди
  его элементов можно пойти одни из двух путей:
    1.Предоставить возможность выбора лицу, принимающему решения, на основе его неформальных
  предпочтений.
    2.Уменьшить множество Парето (в идеале до одного элемента) с помощью некоторых формализованных
  процедур, но для этого требуется дополнительная информация о критериях или о свойствах
  оптимального решения.
  */

create table meal
(
    meal_code text primary key,       ---код обеда
    price     numeric(6, 2) not null, ---цена
    calories  smallint      not null, ---калорийность
    variety   smallint      not null  ---число блюд
);

truncate table meal
insert into meal (meal_code, price, calories, variety)
values ('A', 550.00, 1500, 3),
       ('B', 490.00, 1300, 4),
       ('C', 600.00, 1400, 4),
       ('D', 580.00, 1600, 5),
       ('E', 570.00, 1380, 5),
       ('F', 520.00, 1450, 3),
       ('G', 580.00, 1580, 4),
       ('H', 570.00, 1380, 4),
       ('I', 510.00, 1450, 3),
       ('J', 530.00, 1450, 6),
       ('K', 540.00, 1580, 4);

SELECT *
from meal;

/*Сравним альтернативы E и H. В нашем примере цена обеда является, конечно, негативным
  критерием, а калорийность и разнообразие обеда - позитивными критериями.
  Значение первых двух показателей совпадают, а по третьему альтернатива E превосходит
  альтренативу H, значит альтернатива H не войдет в множество парето, а насчет судьбы
  альтернативы E не основании одной победы над альтернативой H ничего
  определенного сказать нельзя
  Сравнив альтернативу E с альтернативой J видим, что первая уступает второй по всем
  критериям, таким образом альтернатива E не войдет в множество Парето, хотя она
  превзошла альтернативу H.

  А вот альтернативы J и A оказываются несравнимы по Парето, потому что первая
  превосходит вторую по первому и третьему критерию, но уступает ей по второму критерию

  Создадим функцию, которая будет сравнивать две альтернативы, будем подсчитывать, сколько
  раз показатели первой из них оказались лучше, чем у второй, а сколько раз - хуже.
  Число совпадающих значений показателей в расчет не принимается.
  Посчитанное количество побед и поражений первой альтернативы по отдельным критериям запишем
  в массив, состоящий из двух элементов.
  Поскольку нам важен факт наличия или отсутствия таких побед и поражений, приходится использовать
  именно массив, а не скалярную величину, представляющую собой разницу в счете*/

create or replace function compare_pairwise(a1 meal, a2 meal)
    returns smallint[] as
$$
select array [
           ---подсчет числа побед первой альтернативы
           (case when a1.price < a2.price then 1 else 0 end) +
           (case when a1.calories > a2.calories then 1 else 0 end) +
           (case when a1.variety > a2.variety then 1 else 0 end),
           ---подсчет числа поражений первой альтернативы
           (case when a1.price > a2.price then 1 else 0 end) +
           (case when a1.calories < a2.calories then 1 else 0 end) +
           (case when a1.variety < a2.variety then 1 else 0 end)
           ]::smallint[] as score
$$ language sql;


/*Параметрами функции будут значения составного типа meal. До сих пор в разрабатываемых
  функциях мы не использовали такие параметры, настало время восполнить этот пробел.
  Напомним, что при создании таблицы создается составной тип, имя которого совпадает
  с ее именем. Внутри функции к элементам такого значения можно обращаться также,
  как и к столбцам таблицы (a1.calories)
  При сравнении пары альтернатив не важно сколько раз каждая из них превзошла другую по отдельным
  критериям. Важно лишь зафиксировать, превзошла ли первая альтернатива вторую хотя бы по одному
  критерию. Поэтому результат можно представить, например, целым числом с помощью побитовых строк.
  При такой реализации значение 0 будет означать, что альтернативы совпадают, 1 - что лучше
  первая альтернатива, 2 - что лучше вторая альтернатива, 3 - что альтернативы несравнимы.

  */

create or replace function compare_pairwise_2(a1 meal, a2 meal)
    returns smallint as
$$
select (case
            when a1.price < a2.price then b'01' ---первая альтернатива лучше
            when a2.price < a1.price then b'10' ---вторая альтернатива лучше
            else b'00' ---значения одинаковые
            end |
        case
            when a1.calories > a2.calories then b'01'
            when a2.calories > a1.calories then b'10'
            else b'00'
            end |
        case
            when a1.variety > a2.variety then b'01'
            when a2.variety > a1.variety then b'10'
            else b'00'
            end) ::integer as score
$$ language sql;


/*
При такой реализации значение 0 будет означать, что альтернативы совпадают, 1 - что лучше
  первая альтернатива, 2 - что лучше вторая альтернатива, 3 - что альтернативы несравнимы.
*/

select m1.meal_code               as alt1,
       m2.meal_code               as al2,
       m1.price                   as price1,
       m2.price                   as price2,
       m1.calories                as calories1,
       m2.calories                as calories2,
       m1.variety                 as variety1,
       m2.variety                 as variety2,
       compare_pairwise_2(m1, m2) as score
from meal as m1,
     meal as m2
where m1.meal_code = 'D'
order by m2.meal_code, score;


/*На основании результатов выполнения запроса, можно сказать, что
  альтернативы С и G не войдут в множество Парето
  📋 Таблица исключений:
Сравнение	Результат	Доминирование	В Парето?
D vs C	{3,0}	D строго доминирует C	❌ C не в Парето
D vs G	{2,0}	D слабо доминирует G	❌ G не в Парето
D vs A	{2,1}	Нет доминирования	? (нужны сравнения с другими)
D vs J	{1,2}	Нет доминирования	? (нужны сравнения с другими)
🔚 Итог:
На основании этого запроса можно гарантированно утверждать, что C и G не войдут в множество Парето, потому что:
C доминируема D (D лучше по всем 3 критериям)
G доминируема D (D не хуже по всем критериям и строго лучше по двум)
Для остальных альтернатив нужны дополнительные сравнения — нельзя сказать, войдут они в Парето или нет,
только на основе сравнений с D.
Красивая аналогия:
Если в спортивном турнире команда D уже обыграла команды C и G со счётом 3:0 и 2:0, то C и G
точно не будут чемпионами.
Но про остальные команды нельзя сказать, пока они не сыграют между собой!


1. Альтернатива A: {2,1}
Статус: НЕИЗВЕСТНО (но есть шансы)
D лучше по калориям (1600 > 1500) и разнообразию (5 > 3)
A лучше по цене (550 < 580)
Нет доминирования → A может быть в Парето
Но! Может существовать альтернатива, которая дешевле A И имеет больше калорий/разнообразия

2. Альтернатива B: {2,1}
Статус: НЕИЗВЕСТНО (вероятно в Парето)
D лучше по калориям (1600 > 1300) и разнообразию (5 > 4)
B лучше по цене (490 < 580) — значительно лучше!
B — самая дешёвая из всех (490)
Высокая вероятность, что B в Парето как "бюджетный вариант"

3. Альтернатива E: {1,1}
Статус: НЕИЗВЕСТНО (сомнительно)
D лучше по калориям (1600 > 1380)
E лучше по цене (570 < 580)
По разнообразию равны (5 = 5)
E может быть доминируема: есть ли вариант дешевле 570 с калориями > 1380?

4. Альтернатива F: {2,1}
Статус: НЕИЗВЕСТНО
D лучше по калориям (1600 > 1450) и разнообразию (5 > 3)
F лучше по цене (520 < 580)
Похож на B, но дороже (520 vs 490) и с лучшими калориями (1450 vs 1300)

5. Альтернатива H: {2,1}
Статус: НЕИЗВЕСТНО (сомнительно)
Идентичен E по цене (570) и калориям (1380)
Но разнообразие хуже (4 vs 5 у E)
H вероятно доминируема E (та же цена и калории, но меньше разнообразие)

6. Альтернатива I: {2,1}
Статус: ВЕРОЯТНО в Парето

D лучше по калориям (1600 > 1450) и разнообразию (5 > 3)
I лучше по цене (510 < 580) — вторая по дешевизне после B
Сильный "бюджетный" кандидат

7. Альтернатива J: {1,2}
Статус: ВЕРОЯТНО в Парето
D лучше только по калориям (1600 > 1450)
J лучше по цене (530 < 580) и разнообразию (6 > 5)
J имеет максимальное разнообразие (6) среди всех
Сильный кандидат как "вариант с максимальным выбором"

Сильные кандидаты в Парето:
B (490) — самый дешёвый
I (510) — второй по дешевизне, хорошие калории
J (530) — максимальное разнообразие (6)
D (580) — рекордные калории (1600)

Сомнительные:
A (550) — средний по всем параметрам
E (570) — баланс цена/калории, но разнообразие 5
F (520) — между B и I

  */
select m1.meal_code             as alt1,
       m2.meal_code             as al2,
       m1.price                 as price1,
       m2.price                 as price2,
       m1.calories              as calories1,
       m2.calories              as calories2,
       m1.variety               as variety1,
       m2.variety               as variety2,
       compare_pairwise(m1, m2) as score
from meal as m1,
     meal as m2
where m1.meal_code = 'D'
order by m2.meal_code, score;


/*Переходя к функции формирования множества Парето, примем такой алгоритм ее работы:
  сначала на основе результатов попарных сравнений сформируем множество доминируемых
  альтернатив, а затем отберем из исходного множества только те альтернативы, которых
  нет в списке доминируемых.
  Эти альтернативы могут быть и не сравнимы по данным критериям. Возможно также
  совпадение значений их показателей. В двух последних случаях конструкция CASE
  возвратит NULL

  Обратите внимание на условие соединения строк в предложении ON. Здесь используется
  операция "меньше", поскольку порядок сравниваемых альтернатив в паре не имеет значения.
  Сравнение альтернативы А с альтернативой В даст туже информацию, что и сравнение В с А,
  только лишь в массиве содержащем числовые результаты сравнения, поменяются местами
  значения первого и второго элементов. Таким образом использование декартового произведения
  или условия "не равно" - привело бы к дублированию работы.



  */

create or replace function pareto()
    returns setof meal as
$$
with dominated_alternatives AS
         (select distinct case---первая альтернатива побеждала, а вторая нет
                              when score[1] > 0 and score[2] = 0 then m2
                              ---вторая альтернатива побеждала, а первая нет
                              when score[1] = 0 and score[2] > 0 then m1
                              ---Альтернативы несравнимы или равны
                              else null
                              end as dominated
          from meal as m1
                   join meal as m2 on m1.meal_code < m2.meal_code
                   cross join compare_pairwise(m1.*, m2.*) as cp(score))
select meal
from meal
except
select dominated
from dominated_alternatives;
$$
    language sql;

/*Покажем результат попарного сравнения всех альтернатив
  Поскольку мы проводим оценку с позиции альтернативы, указанной в столбце alt1, то у доминируемых
  альтернатив первый элемент массива, содержащего результаты сравнения будет равен нулю, а второй
  больше нуля.

Пример 1: C доминируема D
text
C,D,"{0,3}"
a1 = C, a2 = D
Результат {0, 3} означает:
0 побед у C (первый элемент = 0)
3 поражения у C (второй элемент > 0)
Вывод: C доминируема D

Пример 2: D доминирует C
text
D,C,"{3,0}"
a1 = D, a2 = C
Результат {3, 0} означает:
3 победы у D
0 поражений у D
Вывод: D доминирует C


🎨 Визуализация правила:
text
{победы_a1, поражения_a1}

ДОМИНИРУЕМА a1:     {0, >0}    ← первый 0, второй >0
ДОМИНИРУЕТ a1:      {>0, 0}    ← первый >0, второй 0
НЕСРАВНИМЫ:         {>0, >0}   ← оба >0
ЭКВИВАЛЕНТНЫ:       {0, 0}     ← оба 0

Пример:
compare_pairwise(C, D) = {0,3} → C доминируема
compare_pairwise(D, C) = {3,0} → D доминирует

*/

select m1.meal_code as alt1,
       m2.meal_code as alt2,
       score
    from meal as m1
    join meal as m2 on m1.meal_code < m2.meal_code
    cross join compare_pairwise(m1.*, m2.*) as score
order by alt1, alt2;

/*Можем провести этап конкурса обедов для пассажиров
  группа претендентов значительно сократилась однако единственный
  победитель найден не был*/
select *
from pareto()
order by variety,meal_code;

/*Предположим чтоуже после проведения первоначального отбора обедов для
  наших пассажиров к нам обратился еще один потенциальный поставщик, обозначаемый
  буквой К, передадим значения показателей в функцию в качестве аргумента следующим
  образом

  Полученный результат говорит о том, что компания опоздавшая к началу конкурса могла бы
  претендовать на получение контракта, поскольку для предлагаемого ею обеда не нашлось
  ни одной доминирующей альтернативы.*/

  select
      'K' as alt1,
      meal.meal_code as alt2,
      compare_pairwise(
      row('K', 540.00, 1580, 4)::meal,
      meal.*) as score
      from meal
          order by alt2;

/*Процедуры
  В Postgres реализованы процедуры, представленные в разделе документации 36.4 пользовательские
  процедуры, это объекты подобные функциям, поэтом глава посвященныя функциям, считается актуальной
  и для процедур.
  Однако между ними есть целый ряд отличий:

  1.В процедурах можно использовать команды управления транзакциями, а внутри функций это
  сделать невозможно. Правда, в процедурах, написанных на языке SQL это тоже невозможно,
  годится только например PL\pgSQL.
  2.Функция вызывается как часть команды манипулирования данными, например select или update,
  а для вызова процедуры служит отдельная команда CALL/
  3.Поскольку процедура выполняется отдельной командой, возврат значения из нее с помощью
  оператору RETURN не предусмотрен: в отличие от функции, это значение было бы невозможно
  использовать. Поэтому в определении процедуры нет RETURNS.
  Процедура или функция может возвращать значения с помощью параметров имеющих модификаторы out
  или inout. Однако таким способом может быть возвращена одна строка, поскольку предложения
  returns setof и returns table в процедурах не используются.
  4.Процедуры, опять же вследствие особенностей их вызова не имеютцелого ряда характеристик,
  присущих функциям: категории изменчивости, способа реагирования на аргументы со значением null -
  безопасности выполнения в параллельных запросах.
  Процедуры используют общее пространство имен, поэтому из двух перегруженных объектов один может быть
  функцией, а другой процедурой.
  */

  alter table meal
  add column pareto_optimal bool; ---изначально альтернативы предполагаются недоминируемыми

create or replace procedure pareto_proc() AS
$$
    update meal set pareto_optimal = 't';
    with dominated_alternatives AS (
    select distinct case---первая альтернатива побеждала, а вторая нет
                              when score[1] > 0 and score[2] = 0 then m2
                              ---вторая альтернатива побеждала, а первая нет
                              when score[1] = 0 and score[2] > 0 then m1
                              ---Альтернативы несравнимы или равны
                              else null
                              end as dominated
          from meal as m1
                   join meal as m2 on m1.meal_code < m2.meal_code
                   cross join compare_pairwise(m1.*, m2.*) as cp(score)

    )
    update meal set pareto_optimal = 'f'
    from dominated_alternatives AS da
    where meal.meal_code = (da.dominated).meal_code;
    ---элемент dominated представляет собой значение составного типа meal
$$
    language sql;

call pareto_proc(); ---вызов процедуры

/*сделаем процедуру для возврата результатов изменений*/

create or replace procedure pareto_proc_2(out pareto_optimals text) AS
    $$
    call pareto_proc();
        select string_agg(meal_code,', ' order by meal.meal_code)
        from meal
        where pareto_optimal;
    $$
language sql;


call pareto_proc_2(null)
/*для выходного параметра процедуры передается значение
как и в случае с функциями, имен столбцов полученной таблицы определяются
именами выходных параметров, а не псевдонимами столбцов выборки.
Для удаления процедуры служит команда drop procedure, если имя процедуры уникально,
  то наименование параметров можно не указывать.
  */

/*Совместное использование параметров с модификатором out и предложением
  returns
  Параметры с модификатором out позволяют функции возвратить более одного значения.
  При использовании таких параметров можно в ряде случаев обойтись без предложения
  returns в определении функции

  Когда бывает целесобразно использовать параметры с модификатором out вместе
  с предложением returns, что это дает?
  В PostgreSQL есть три способа вернуть значения из функции:

Только RETURNS — классический способ
Только OUT параметры — альтернативный способ
OUT + RETURNS вместе — гибридный способ

-- OUT: структурированные данные (record)
-- RETURNS: скалярное значение (int, text, json и т.д.)
OUT — основные выходные данные
RETURNS — статус, метаданные, флаги

Ограничения и нюансы:
Порядок важен: Сначала объявляются все параметры, включая OUT, затем RETURNS
Тип RETURNS должен быть совместим с фактически возвращаемым значением
В SQL-функциях комбинация OUT+RETURNS обычно не нужна
Итог: когда использовать OUT + RETURNS?

Ситуация              | OUT | RETURNS | Пример
----------------------|-----|---------|---------------------------------
Только данные         | ✅  | ❌      | get_stats(OUT a, OUT b)
Данные + статус       | ✅  | ✅      | update_record(OUT old, RETURNS status)
Агрегация + детали    | ✅  | ✅      | analyze(OUT details, RETURNS summary)
Обратная совместимость| ✅  | ✅      | Добавление статуса к существующей функции

Золотое правило:
Используйте OUT + RETURNS, когда нужно вернуть
и структурированные данные, и дополнительную информацию
разного типа и назначения.
*/

/*
Значение параметра функции в качестве идентификатора в ее коде - это возможно?

Ответ - да:
CREATE OR REPLACE FUNCTION get_column_value(
    table_name text,
    column_name text,
    id_value integer
)
RETURNS text AS
$$
DECLARE
    result text;
BEGIN
    -- Используем параметры как идентификаторы
    EXECUTE format('SELECT %I FROM %I WHERE id = $1', column_name, table_name)
    INTO result
    USING id_value;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Использование
SELECT get_column_value('meal', 'meal_code', 1);


-- НЕ РАБОТАЕТ! ОШИБКА!
SELECT $1 FROM $2 WHERE id = $3;  -- нельзя
Нужно использовать:
format() с %I (идентификатор) или %L (литерал)
quote_ident() и quote_literal()
Динамический SQL через EXECUTE

Итог:
Да, использовать параметры как идентификаторы можно, но:
Только через EXECUTE в PL/pgSQL
Всегда экранировать через format() с %I или quote_ident()
Значения передавать через USING, а не конкатенацию
Проверять входные данные на корректность

*/
CREATE OR REPLACE FUNCTION count_seats_dynamic(
    a_code char(3),
    fare_cond text,
    table_name text DEFAULT 'seats',           -- параметры по умолчанию идут ПОСЛЕ
    aircraft_code_col text DEFAULT 'aircraft_code',    -- обязательных параметров!
    fare_cond_col text DEFAULT 'fare_conditions'
)
    RETURNS bigint AS
/*
Переработанная функция с использованием параметров как идентификаторов.
Позволяет динамически указывать имена таблицы и столбцов.

ПРАВИЛО: Параметры со значениями по умолчанию должны быть ПОСЛЕ
        обязательных параметров без значений по умолчанию.

Функция format() в PostgreSQL используется для безопасного форматирования SQL-строк
с подстановкой параметров. Основные плейсхолдеры:
%s - подстановка значения как строка (текст)
%I - подстановка идентификатора с экранированием (для имен таблиц, колонок)
%L - подстановка литерала с экранированием (для значений)
%% - символ процента

*/
$$
DECLARE
    seat_count bigint;
BEGIN
    -- Используем параметры как идентификаторы через format()
    EXECUTE format(
            'SELECT COUNT(*) ' ||
            'FROM %I WHERE %I = $1 AND %I = $2',
            table_name,
            aircraft_code_col,
            fare_cond_col
            )
        INTO seat_count
        USING a_code, fare_cond;

    RETURN seat_count;
END;
$$ LANGUAGE plpgsql;

SELECT count_seats_dynamic('SU9', 'Business', 'seats');


---Символ одинарной кавычки в теле функции
CREATE FUNCTION test() RETURNS TEXT AS $$
BEGIN
    RETURN 'O''Reilly';  -- Две одинарные кавычки
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION test() RETURNS TEXT AS $func$
BEGIN
    RETURN $str$O'Reilly$str$;
END;
$func$ LANGUAGE plpgsql;

/*Перегруженные aerywbb и значения параметров по умолчанию
  функции в СУБД Postgres можно перегружать, то есть создавать одноименные функции
 с различающимися типами входных параметров (имеющих модификаторы in или out либо
  объявленные без модификаторов) в таком случае сигнатуры функции будут различными.
  Сигнатура функции = Имя функции + Типы параметров (аргументов)
  При вызове PostgreSQL определяет конкретную перегруженную функцию на основании
  переданных ей аргументов.
  Аргументы функции — это переменные, переданные в функцию при её вызове,
  которые функция использует для выполнения операций.
  Однако с этим могут возникать и сложности, если параметры имеют значение по умолчанию*/

CREATE OR REPLACE FUNCTION test_default(
    par1 int,
    par2 int DEFAULT 2) RETURNS text AS
$$
SELECT FORMAT('test_default1; par1 = %s, par2 = %s', par1, par2);
$$
    LANGUAGE sql;


CREATE OR REPLACE FUNCTION test_default(
    par1 int,
    par2 int DEFAULT 2,
    par3 int DEFAULT 3) RETURNS text AS
$$
SELECT FORMAT('test_default2; par1 = %s, par2 = %s, par3 = %s', par1, par2, par3);
$$
    LANGUAGE sql;

/*Попробуем вызвать первую из них, задавая сначала один аргумент, потом два аргумента*/

select test_default(10);
/*
[2025-12-10 16:24:05] [42725] ERROR: function test_default(integer) is not unique
[2025-12-10 16:24:05] Подсказка: Could not choose a best candidate function. You might need to add explicit type casts.
[2025-12-10 16:24:05] Позиция: 8*/

select test_default(10,20);

/*[2025-12-10 16:24:54] [42725] ERROR: function test_default(integer, integer) is not unique
[2025-12-10 16:24:54] Подсказка: Could not choose a best candidate function. You might need to add explicit type casts.
[2025-12-10 16:24:54] Позиция: 8*/

select test_default(10,20, 30);
---Вызов успешен test_default2; par1 = 10, par2 = 20, par3 = 30

/*Можно вызвать вторую версию функции и с применением именованных аргументов.
  Причем, их можно переставить местами и опустить параметр par2, поскольку он имеет
  значение по умолчанию*/

select test_default(par3 =>30, par1=>10);
---Вызов успешен test_default2; par1 = 10, par2 = 2, par3 = 30

/*Таким образом, вызвать первую функцию, которая имеет два параметра невозможно.
  Это объясняется тем, что при задании одного из двух аргументов под этот вызов
  подходят обе наши функции, поэтому Postgresql не может выбрать конкретную функцию
  */

---показать путь
show search_path


/*Удалим данные функции и создадим их на разных схемах базы данных*/

drop function  test_default(int, int);
drop function  test_default(int, int, int);

/*Одну функцию создадим на схеме booking а другую в схеме public*/

CREATE OR REPLACE FUNCTION public.test_default(
    par1 int,
    par2 int DEFAULT 2) RETURNS text AS
$$
SELECT FORMAT('test_default1; par1 = %s, par2 = %s', par1, par2);
$$
    LANGUAGE sql;


CREATE OR REPLACE FUNCTION bookings.test_default(
    par1 int,
    par2 int DEFAULT 2,
    par3 int DEFAULT 3) RETURNS text AS
$$
SELECT FORMAT('test_default2; par1 = %s, par2 = %s, par3 = %s', par1, par2, par3);
$$
    LANGUAGE sql;

select test_default(10);
select test_default(10,20);
select test_default(10,20, 30);

/*Измените путь поиска*/

set search_path = public, bookings;


select test_default(10);
select test_default(10,20);
select test_default(10,20, 30);

/*Если перегруженные функции находятся в разных схемах, то всегда
  можно указать при вызове функции схемы*/

select bookings.test_default(10);

/*Cброс PATH до исходного состояния*/
reset SEARCH_PATH;
show SEARCH_PATH;

/*Аргументом функции может быть и значение null

При выполнении запросов функция может получить значение null в качестве аргумента
Такие ситуации должны корректно обрабатываться и не приводить к сбоям.
Данный вопрос рассмотрен в подразделе 5.1.6 Значения null в качестве аргументов функции

Зачем вообще нужны STRICT функции?
Оптимизация производительности:
Избегают дорогостоящих вычислений, когда результат заведомо известен (NULL)!!!
Особенно важно для тяжелых вычислений или запросов к большим таблицам

Семантическая корректность:
Если хотя бы один аргумент операции не определен (NULL), результат всей операции не определен
Это соответствует математической логике и принципам SQL
Защита от ошибок:
Если NULL в аргументе указывает на ошибку в данных или логике, лучше сразу это обнаружить
*/
CREATE FUNCTION count_seats_sql(a_code char, fare_cond text)
    RETURNS bigint
    LANGUAGE sql
    STRICT
----STRICT в функции PostgreSQL означает, что функция будет
----возвращать NULL немедленно, если любой из её аргументов равен NULL.
RETURN (SELECT count(*)
        FROM seats s
        WHERE s.aircraft_code = a_code
          AND s.fare_conditions = fare_cond);

-- Вариант 1: RETURNS NULL ON NULL INPUT (полный синоним STRICT)
CREATE OR REPLACE FUNCTION count_seats_sql(a_code char, fare_cond text)
    RETURNS bigint
    LANGUAGE sql
    RETURNS NULL ON NULL INPUT  -- Более понятная альтернатива STRICT
RETURN (
    SELECT count(*)
    FROM seats s
    WHERE s.aircraft_code = a_code
      AND s.fare_conditions = fare_cond
);


EXPLAIN ANALYZE
SELECT count_seats_sql('SU9', NULL);

/*Взаимосвязи объектов в базе данных
  Как вы думаете можно ли удалить таблицу, которая используется в функции
  на языке SQL, а столбец таблицы?
  Можно ли создать функцию, в которой используется еще не созданная таблица или столбец,
  которого нет в существующей таблице?
  Как повлияет на результаты эксперимента способ оформления тела функции
  в виде символьной строки или в виде стандарта SQL?*/

create table test_depend_t (a int, b int);
insert into test_depend_t values(1,2);
INSERT INTO test_depend_t (a, b)
SELECT
    i,                    -- a = 1, 2, 3, ..., 100000
    i + 1                 -- b = 2, 3, 4, ..., 100001
FROM generate_series(1, 100000) AS i;
---truncate table test_depend_t
---drop table test_depend_t cascade
/*[2025-12-11 20:02:01] [2BP01] ERROR: cannot drop table test_depend_t because other objects depend on it
[2025-12-11 20:02:01] Подробности: function test_depend1() depends on table test_depend_t
[2025-12-11 20:02:01] function test_depend_3() depends on table test_depend_t
[2025-12-11 20:02:01] Подсказка: Use DROP ... CASCADE to drop the dependent objects too.
  */

create or replace function test_depend()
returns int as
    $$
    select count(*)
    from test_depend_t;
    $$
LANGUAGE sql;


CREATE OR REPLACE FUNCTION test_depend1()
    RETURNS bigint
    LANGUAGE sql
BEGIN ATOMIC
SELECT COUNT(*)
FROM test_depend_t;
END;


explain analyze
select *
from  test_depend()

explain analyze
select *
from  test_depend1();

alter table test_depend_t drop column b;

alter table test_depend_t add column c int;

alter table test_depend_t add column b int;

create or replace function test_depend_2()
    returns int as
$$
select b
from test_depend_t
    limit 1;
$$
    LANGUAGE sql;
/*Если нет таблицы test_depend_t функция не создается
  relation "test_depend_t" does not exist
[2025-12-11 20:04:58] Позиция: 84*/


CREATE OR REPLACE FUNCTION test_depend_3()
    RETURNS bigint
    LANGUAGE sql
BEGIN ATOMIC
SELECT b
FROM test_depend_t
limit 1;
END;
/*если нет таблицы test_depend_t, то функция не создается
  [2025-12-11 20:04:09] [42P01] ERROR: relation "test_depend_t" does not exist
[2025-12-11 20:04:09] Позиция: 112*/

explain analyze
select *
from  test_depend_2();


explain analyze
select *
from  test_depend_3();

/*Функцию невозможно создать, если в таблице нет столбца, который
  участвует в функции [2025-12-11 19:57:59] [42703] ERROR: column "b" does not exist
[2025-12-11 19:57:59] Позиция: 104*/



/*Могут ли параметры inout и in идти вперемежку?
  Эта функция выбирает все маршруты, проложенные из одного города
  в другой.
  Что, если отказаться от двух параметров d_city и a_city, заменив
  модификатор out на inout у параметров dep_city и arr_city?
  Так мы сократим число параметров в функции

SETOF означает "множество записей" (табличная функция)
record - тип записи, структура которой определяется
OUT параметрами*/

drop function if exists list_routes_3;

CREATE OR REPLACE FUNCTION list_routes_3(
    ---d_city text DEFAULT 'Москва',
    ---a_city text DEFAULT 'Санкт_петербург',
    OUT f_no char,
    ---OUT dep_city text,
    ---OUT arr_city text,
    INOUT dep_city text DEFAULT 'Москва',
    INOUT arr_city text DEFAULT 'Санкт_петербург',
    OUT model text
)
    RETURNS SETOF record AS
$$
SELECT r.flight_no, r.departure_city, r.arrival_city, a.model
FROM routes                r
         JOIN aircrafts AS a ON a.aircraft_code = r.aircraft_code
WHERE r.departure_city = dep_city
  AND r.arrival_city   = arr_city;
$$ LANGUAGE sql;

/*
f_no  |dep_city|arr_city   |model
PG0222|Москва  |Новосибирск|Боинг 777-300
PG0277|Москва  |Новосибирск|Боинг 777-300

именованные аргументы
*/
Select *
FROM list_routes_3(dep_city => 'Москва', arr_city => 'Новосибирск')
union
Select *
FROM list_routes_3(arr_city => 'Новосибирск',dep_city => 'Москва');

/*
f_no  |dep_city   |arr_city   |model
PG0222|Москва     |Новосибирск|Боинг 777-300
PG0223|Новосибирск|Москва     |Боинг 777-300
PG0277|Москва     |Новосибирск|Боинг 777-300
PG0278|Новосибирск|Москва     |Боинг 777-300

позиционные аргументы
*/
Select *
FROM list_routes_3('Москва', 'Новосибирск')
union
Select *
FROM list_routes_3('Новосибирск', 'Москва');

---нет маршрутов
Select *
FROM list_routes_3();


/*Функция по стандарту SQL, без символьной строки*/
CREATE OR REPLACE FUNCTION list_routes_30(
    p_dep_city text DEFAULT 'Москва',
    p_arr_city text DEFAULT 'Санкт_петербург'
)
    RETURNS TABLE(
                     flight_no char(6),
                     departure_city text,
                     arrival_city text,
                     model text
                 )
    LANGUAGE SQL
BEGIN ATOMIC
/*Ключевое слово ATOMIC означает, что блок выполняется как единая атомарная операция:
Либо все операторы выполняются успешно
Либо ни один не выполняется (при ошибке происходит откат)*/
SELECT
    r.flight_no,
    r.departure_city,
    r.arrival_city,
    a.model
FROM routes r
         JOIN aircrafts a ON a.aircraft_code = r.aircraft_code
WHERE r.departure_city = p_dep_city
  AND r.arrival_city = p_arr_city;
END;

select *
from list_routes_30('Новосибирск', 'Москва');

/*Параметр variadic идет последним, почему ?

  PostgreSQL парсит аргументы функции слева направо
  Парсер:
Берет первый аргумент → сопоставляет с первым параметром
Берет второй аргумент → сопоставляет со вторым параметром
...
ДОХОДИТ ДО КОНЦА списка параметров
Если последний параметр VARIADIC → все оставшиеся аргументы туда

VARIADIC параметр идет последним потому что:
Однозначность парсинга - парсер точно знает, когда начинаются variadic аргументы
Семантическая ясность - "все оставшиеся аргументы" логично быть в конце
Совместимость - с массивами и другими языками программирования
Практичность - упрощает вызов функции
Исторические прецеденты - так делается в большинстве языков
Это дизайн-решение, которое делает API функций чище и предотвращает множество
ошибок и неоднозначностей.
  */


/*Псевдовнимы таблиц и столбцов:
  есть некоторая свобода

  Функциям в предложении from могут назначаться псевдонимы.
  В таких случаях, как правило, задают псевдонимы и столбцам
  В качестве иллюстрации воcпользуемся запросом для формирования номеров
  кресел в салонах самолета
  В первом варианте используются и псевдонимы таблицы и псевдонимы столбца*/

---указываем псевдонимы строк
select
    row,
    letter,
    row  || letter as seat_no
from generate_series(1,3) as rows(row), ---rows → имя таблицы (псевдоним)
                                        ---(row) → имя столбца в этой "таблице"
     unnest(array['A','B','C','D','F']) as letters(letter)
order by row, letter


----указываем псевдонимы таблиц
select
    rows,
    letters,
    row  || letter as seat_no
from generate_series(1,3) as rows(row), ---rows → имя таблицы (псевдоним)
     ---(row) → имя столбца в этой "таблице"
     unnest(array['A','B','C','D','F']) as letters(letter)
order by row, letter


select
    row,
    letter,
    row  || letter as seat_no
from generate_series(1,3) as row, ---rows → имя таблицы (псевдоним)
     ---(row) → имя столбца в этой "таблице"
     unnest(array['A','B','C','D','F']) as letter
order by row, letter


-- Посмотрим на реальные типы
select
    pg_typeof(row) as type_of_row,
    pg_typeof(rows) as type_of_rows,
    pg_typeof(letter) as type_of_letter,
    pg_typeof(letters) as type_of_letters
from generate_series(1,3) as rows(row),
     unnest(array['A','B','C','D','F']) as letters(letter)
limit 1;


select
    pg_typeof(row) as type_of_row,
    pg_typeof(letter) as type_of_letters
from generate_series(1,3) as row,
     unnest(array['A','B','C','D','F']) as letter
limit 1;

-- Развернуть все столбцы таблицы "rows"
---select (rows).*
-- А поскольку в "rows" только один столбец "row":
-- Что эквивалентно просто `row`
---select (rows).row
/*
Результаты получим одинаковые (хотя имена столбцов могут различаться)
Попытайтесь объяснить почему все три варианта работают одинаково,
причем правильно.
Найдите обоснование в документации.
Начать можно с описания команды Select, приведенного в документации

FROM table_reference [ AS ] alias [ ( column_alias [, ...] ) ]
Если указан только псевдоним таблицы без списка столбцов,
имена столбцов берутся из исходной таблицы.
*/

/*
Когда в предложении from несколько табличных функций
в предложении from у нас была одна конструкция lateral,
а что если таких конструкций будет две


Интегральный показатель - это комплексная, обобщенная количественная характеристика,
которая объединяет несколько отдельных показателей (параметров, факторов) в одну общую оценку.
Простыми словами:
Это "сводная оценка", которая показывает общую картину, объединяя множество деталей в одно число.

На принятие решения руководством авиакомпании о сохранении тех или иных маршрутов влияет в том числе
их востребованность у пассажиров.
Она зависит от разных факторов: от исторически сложившихся связей между городами, от стоимости авиабилетов,
от наличия других транспортных возможностей, от численности населения городов, и т.д.
Интегральным показателем востребованности будем считать степень заполнения самолетов, выполнябщих рейсы по конкретным
маршрутам. Мы будем прнимать во внимание лишь рейсы, имеющие статус Departed или Arrived.

Начнем разработку с функции вычисления интересующего нас показателя конкретной пары городов за
указанный период, причем для рейсов как "туда" так и "обратно".

В первом подзапросе в конструкции with вычисляется количество мест в каждой модели самолета.
Во втором подзапросе вычисляется количество пассажиров на каждом рейсе, выполненном по одному из
двух заданных направлений ("Туда" и "Обратно") Хотя целью этого подзапроса является вычисление
количества пассажиров на каждом рейсе, а не на каждом направлении, тем неменее в группировке
участвуют столбцы "город отправления", "город прибытия" и "код модели самолета", поскольку они будут
нужны на заключительном этапе, а главном запросе.


*/

create or replace function  get_routes_occupation(
dep_city  text,
arr_city  text,
from_date date,
till_date date)
returns table (
    dep_city text,
    arr_city text,
    total_passengers numeric, --число перевезенных пассажиров
    total_seats numeric,      --общее число мест в самолетах
    occupancy_rate numeric    --доля занятых мест
              ) AS
    $$
    with seats_counts AS
    (select aircraft_code,
    count(*) as seats_cnt
    from seats
    group by aircraft_code
    ),
    per_flight_results AS
    (select
    r.departure_city,
    r.arrival_city,
    f.flight_id,
    f.aircraft_code,
    count(*) as passengers_cnt
    from routes as r
    join flights as f on f.flight_no = r.flight_no
    join ticket_flights AS tf on tf.flight_id = f.flight_id
    where (
    (r.departure_city = dep_city AND r.arrival_city = arr_city)   ---туда
    or (r.departure_city = arr_city AND r.arrival_city = dep_city) ---обратно
    )
    and f.scheduled_departure between from_date and till_date
    and f.status in ('Departed','Arrived')
    group by r.departure_city, r.arrival_city, f.flight_id, f.aircraft_code)

    select
    pfr.departure_city,
    pfr.arrival_city,
    sum(pfr.passengers_cnt) as total_passengers,
    sum(sc.seats_cnt) as total_seats,
    round(sum(pfr.passengers_cnt) / sum(sc.seats_cnt),2) as occupancy_rate
    from per_flight_results as pfr
    join seats_counts as sc on sc.aircraft_code = pfr.aircraft_code
    group by pfr.departure_city, pfr.arrival_city;

$$ LANGUAGE sql;

select
dep_city,
arr_city,
total_passengers as pass,
total_seats as seats,
occupancy_rate as rate
from get_routes_occupation('Москва', 'Краснодар','2017-08-01','2017-08-15')


select
    dep_city,
    arr_city,
    total_passengers as pass,
    total_seats as seats,
    occupancy_rate as rate
from get_routes_occupation('Владивосток', 'Москва','2017-08-01','2017-08-15');

/*Теперь посмотрим, как часто летают в Москву жители самых восточных регионов России, то есть тех,
в которых аэропорты расположены восточнее долготы 150 градусов
cross join - декартово произведение
Каждая строка из airports соединяется с каждой строкой из результата функции
Но поскольку функция зависит от строки airports, это эффективный JOIN
lateral - ключевое слово!
Позволяет функции get_routes_occupation видеть колонки из текущей строки airports
Без lateral нельзя было бы передать ai.city как параметр
Функция вызывается для каждой строки таблицы airports

1. Берём таблицу airports (все аэропорты)
2. Фильтруем: оставляем только аэропорты с долготой > 150°
3. Для каждого оставшегося аэропорта:
   а. Берем его город (например, 'Владивосток')
   б. Вызываем функцию get_routes_occupation:
       - dep_city = 'Владивосток'
       - arr_city = 'Москва'
       - период: 1-15 августа 2017
   в. Функция возвращает статистику по рейсам
4. Объединяем данные аэропорта с результатом функции
5. Выводим нужные колонки

-- Фактический порядок в PostgreSQL:
1. FROM airports as ai
2. WHERE ai.coordinates[0] > 150           -- Сначала фильтрация!
3. CROSS JOIN LATERAL (для каждой строки)
4. SELECT (проекция колонок)

В выполненном запросе брался первый аргумент функции из текущей строки таблицы аэропорты, а второй
  аргумент оставляся неизменным.

*/



  Select
      gro.dep_city,
      gro.arr_city,
      gro.total_passengers,
      gro.total_seats,
      gro.occupancy_rate,
      ai.coordinates
      from airports as ai
  cross join lateral get_routes_occupation(ai.city, 'Москва','2017-08-01','2017-08-15') as gro
  where ai.coordinates[0] > 150; --- 0 географическая долгота, 1 географическая широта в тие данных points

/*Давайте усложним задачу: нужно определить степень заполнения самолетов на всех направлениях,
  проложенных из каждого города, находящегося, например в часовом поясе asia/vladivostok
  Очевидно придется, каким-то образом определять список всех городов, с которыми имеет авиасообщение конкретный
  город, а затем подставить полученные названия городов поочередено в качестве второго аргумента
  функции get_routes_occupation, которая будет вызываться для каждого города из выбранного часового
  пояса*

  Функция, формирующая список городов, в которые можно улететь из указанного города, будет
  несложной.

 */

CREATE OR REPLACE FUNCTION list_connected_cities(
    city               text,
    OUT connected_city text
)
    RETURNS setof text AS
$$
SELECT DISTINCT arrival_city
FROM routes
WHERE departure_city = city;
$$ LANGUAGE sql;


/*Проверяем функцию в работе*/
SELECT city, connected_city
FROM airports AS ai
         CROSS JOIN LATERAL list_connected_cities(ai.city) AS connected_city
WHERE timezone = 'Asia/Vladivostok'
ORDER BY city, connected_city;

/*Теперь имея функцию list_connected_cities можно решить поставленную выше задачу
  В предложении from поставим вызов функции list_connected_cities левее вызова
  функции get_routes_occupation, чтобы вторая функция могла ссылаться на результаты
  работы первой функции
*/

EXPLAIN ANALYZE
SELECT gro.dep_city,
       gro.arr_city,
       gro.total_passengers,
       gro.total_seats,
       gro.occupancy_rate
FROM airports AS a
         CROSS JOIN LATERAL list_connected_cities(a.city) AS lcc
         CROSS JOIN LATERAL get_routes_occupation(a.city, lcc.connected_city, '2017-08-01', '2017-08-15') AS gro
WHERE a.timezone = 'Asia/Vladivostok'
ORDER BY gro.dep_city, gro.arr_city;

/*В выборке повторяются города Владивосток и Хабаровск, поскольку оба эти города
  находятся в часовом поясе 'Asia/Vladivostok'

План:
Sort  (cost=297268.36..300268.36 rows=3000000 width=160) (actual time=5478.963..5478.965 rows=22 loops=1)
  Sort Key: gro.dep_city, gro.arr_city
  Sort Method: quicksort  Memory: 26kB
  ->  Nested Loop  (cost=0.40..30034.03 rows=3000000 width=160) (actual time=122.668..5478.922 rows=22 loops=1)
        ->  Nested Loop  (cost=0.20..33.83 rows=3000 width=81) (actual time=26.187..78.115 rows=11 loops=1)
              ->  Seq Scan on airports_data ml  (cost=0.00..3.62 rows=3 width=49) (actual time=0.017..0.032 rows=3 loops=1)
                    Filter: (timezone = 'Asia/Vladivostok'::text)
                    Rows Removed by Filter: 101
              ->  Function Scan on list_connected_cities lcc  (cost=0.20..5.20 rows=1000 width=32) (actual time=26.021..26.023 rows=4 loops=3)
        ->  Function Scan on get_routes_occupation gro  (cost=0.20..5.20 rows=1000 width=160) (actual time=490.974..490.975 rows=2 loops=11)
Planning Time: 0.117 ms
Execution Time: 5479.085 ms


  Прежде чем перейти к обсуждению плана, напомним, что объект Аэропорты (airports) на самом деле
  является представлением, за которым скрывается таблица airports на самом деле является представлением
  за которым скрывается таблица airports_data

В этом плане мы видим двойной вложенный цикл. Работа начинается с отбора трех строк из таблицы
airports_data, для каждой из которых вызывается функция list_connected_cities.
Она порождает в среднем по четыре строки при каждом вызове (показатели rows=4 loops=3), а общее
число порожденных строк равно 11, как свидетельствует показатель actual rows = 11 во внутреннем
узле Nested Loop.

Рассуждая аналогично, можно заключить, что во внешнем вложенном цикле для каждой из одиннадцати строк,
порожденных во внутреннем цикле, вызывается функция get_routes_occupation, выдающая по две строки за
  один вызов (actual rows=2 loops=11). В результате число сформированных строк становится равным 22

*/


/*Табличные функции в списке Select
  Иногда можно, но лучше в предложении FROM */

EXPLAIN ANALYZE
select get_routes_occupation(a.city, list_connected_cities(a.city),
       unnest(array['2017-07-16','2017-08-01']::date[]),
       unnest(array['2017-07-31','2017-08-15']::date[])
       )
from airports a
where timezone = 'Asia/Vladivostok'
order by city;

/*Стабильные функции могут зависеть от настроек сервера
*/

begin;
set TIMEZONE = 'Asia/Vladivostok';

select current_timestamp;

set TIMEZONE = 'Europe/Moscow';

select current_timestamp;

rollback;

select current_timestamp;


/*Функция random является изменчивой volatile функцией. В тексте главы был показан результат
  ее работы при многократном вызове.
  Но ведь возможны случаи когда, когда для каждой строки формируемой в запросе, требуется случайное
  значение - но одно и тоже
  Каким образом получить такой результат
    val1                 val2
0.6223617015248359 |0.6223617015248359
0.6223617015248359 |0.6223617015248359
0.6223617015248359 |0.6223617015248359
0.6223617015248359 |0.6223617015248359
0.6223617015248359 |0.6223617015248359
*/
SELECT
    (SELECT random()
     FROM (SELECT setseed(0.456)) as s) as val1,
    (SELECT random()
     FROM (SELECT setseed(0.456)) as s) as val2,
    id
FROM generate_series(1, 5) as id;

/*Можно сделать таким способом через  CROSS JOIN LATERAL
Nested Loop - используется вложенный цикл для соединения
rows=5 - ожидается 5 строк на выходе
width=16 - каждая строка занимает 16 байт (2 значения double precision по 8 байт)
loops=1 - весь запрос выполняется один раз

->  Result  (cost=0.00..0.01 rows=1 width=8) (actual time=0.002..0.002 rows=1 loops=1)
Это ключевой момент!
Result - это выполнение подзапроса (SELECT random() as r)
rows=1 - подзапрос возвращает 1 строку (одно значение random())
loops=1 - подзапрос выполнен ВСЕГО ОДИН РАЗ
actual time=0.002..0.002 - время выполнения ~0.002 мс

  >  Function Scan on generate_series (cost=0.00..0.03 rows=5 width=0) (actual time=0.005..0.005 rows=5 loops=1)
Function Scan on generate_series - выполнение функции generate_series(1, 5)
rows=5 - генерируется 5 строк
width=0 - сами числа не включаются в выход (они не используются в SELECT)

Шаг 1: Внутренний цикл (подзапрос)
sql
-- Выполняется ОДИН РАЗ в начале:
(SELECT random() as r)  --> возвращает, например, 0.47902012761444346
Шаг 2: Внешний цикл (generate_series)
sql
-- Для каждой из 5 строк generate_series
FROM generate_series(1, 5)  -- 1, 2, 3, 4, 5
Шаг 3: Соединение (Nested Loop)
text
Результат:
Строка 1: 0.47902012761444346 (из подзапроса) + 1 (из generate_series, но не используется)
Строка 2: 0.47902012761444346 (то же самое значение!) + 2
Строка 3: 0.47902012761444346 (то же самое значение!) + 3
Строка 4: 0.47902012761444346 (то же самое значение!) + 4
Строка 5: 0.47902012761444346 (то же самое значение!) + 5

*/

EXPLAIN ANALYZE
SELECT
    fr.r as "rand1",
    fr.r  as "rand2"
FROM generate_series(1, 5)
         CROSS JOIN LATERAL (SELECT random() as r) fr;

/*Функция random неожиданные результаты
  При неосторожном обращении с функцией random можно получить неожиданные
  результаты, давайте проведем несколько экспериментов*/

select
    g,
    random(),
    random()
from generate_series(1,3) as g

/*Теперь добавим сортировку по второму столбцу
*/

select
    g,
    random(),
    random()
from generate_series(1,3) as g
order by 2

/*Если вместо order by 2 написать order by random() картина будет аналогичная:*/

select g, random(), random()
from generate_series(1,3) as g
order by random()

/*Но если сортировать по двум столбцам, то при order by 2,3 все значения
  будут разные, а order by random(), random() даст по два одинаковых значения в каждой строке!!!
  */

explain analyze VERBOSE
select g, random(), random()
from generate_series(1,3) as g
order by 2,3

explain analyze VERBOSE
select g, random(), random()
from generate_series(1,3) as g
order by random(),random()

/*
Sort  (cost=0.03..0.03 rows=3 width=20) (actual time=0.015..0.016 rows=3 loops=1)
  Output: g, (random()), (random())
  Sort Key: (random()), (random())
  Sort Method: quicksort  Memory: 25kB
  ->  Function Scan on pg_catalog.generate_series g  (cost=0.00..0.02 rows=3 width=20) (actual time=0.007..0.007 rows=3 loops=1)
        Output: g, random(), random()
        Function Call: generate_series(1, 3)
Query Identifier: 2559064185615782429
Planning Time: 0.040 ms
Execution Time: 0.037 ms
*/



/*Result  (cost=0.03..0.05 rows=3 width=20) (actual time=0.022..0.022 rows=3 loops=1)
  Output: g, (random()), (random())
  ->  Sort  (cost=0.03..0.03 rows=3 width=12) (actual time=0.021..0.021 rows=3 loops=1)
        Output: g, (random())
        Sort Key: (random())
        Sort Method: quicksort  Memory: 25kB
        ->  Function Scan on pg_catalog.generate_series g  (cost=0.00..0.02 rows=3 width=12) (actual time=0.011..0.012 rows=3 loops=1)
              Output: g, random()
              Function Call: generate_series(1, 3)



Подробный анализ:
Запрос 1:
Function Scan: Генерирует 3 строки, сразу вычисляет ДВА random() для каждой
width=20: g(4 байта?) + random()(8) + random()(8) = 20
Sort: Сортирует результат по двум random() как ключам
Запрос 2:
Function Scan: Генерирует 3 строки, вычисляет ОДИН random()
width=12: g(4) + random()(8) = 12
Sort: Сортирует по одному random()
Result: Добавляет второй random() (возможно, вычисляет его здесь)
width становится 20
*/


/*Поиск корней квадратного уравнения
На языке SQL можно написать функцию, вычисляющую, например, действительные корни квадратного
уравнения.
В конструкции with сначала вычисляется дискриминант, а затем - корни уравнения. В
  главном запросе значения корней округляются с требуемой точностью. Обратите внимание,
  что подзапрос в вызове функций sqrt заключается в скобки.
*/
----drop function square_equation;

CREATE OR REPLACE FUNCTION square_equation(
    a        double precision,
    b        double precision,
    c        double PRECISION,
    accuracy integer DEFAULT 2,
    OUT x1   numeric,
    OUT x2   numeric
) AS
$$
WITH discriminant AS
             (SELECT b * b - 4 * a * c AS d),
     roots AS
         (SELECT (-b + SQRT((SELECT d FROM discriminant))) / (2 * a) AS x_one,
                 (-b - SQRT((SELECT d FROM discriminant))) / (2 * a) AS x_two)

SELECT ROUND(x_one::NUMERIC, accuracy) AS x_one,
       ROUND(x_two::NUMERIC, accuracy) AS x_two
FROM roots;
$$ LANGUAGE sql;


select square_equation(3,-6,2);

/*Зададим точность округления до 4 цифр функция в select - выводится как составной тип*/
select square_equation(3,-6,2,4);

/*Значения выводятся как отдельные столбцы если указываем функцию во from*/
select *
from square_equation(3,-6,2,4);


select *
from square_equation(3,-6,2,4);

/*[2025-12-13 23:36:55] [2201F] ERROR: cannot take square root of a negative number
[2025-12-13 23:36:55] Где: SQL function "square_equation" statement 1*/
select *
from square_equation(3,-6,4,4);

/*[2025-12-13 23:37:45] [22012] ERROR: division by zero
[2025-12-13 23:37:45] Где: SQL function "square_equation" statement 1 */
select *
from square_equation(0,-6,2,4);

/*При создании этой функции мы не указали категорию изменчивости функции, поэтому
  по умолчанию принимается volatile а можно ли назначить
  категорию изменчивости stable или immutable? И почему?*/

---drop function square_equation_1

CREATE OR REPLACE FUNCTION square_equation_1(
    a        double precision,
    b        double precision,
    c        double precision,
    accuracy integer DEFAULT 2,
    OUT x1   numeric,
    OUT x2   numeric
) RETURNS record
    IMMUTABLE
    STRICT
AS $$
DECLARE
    d double precision;
    d_rounded numeric;  -- Для округленного значения дискриминанта
BEGIN
    -- Проверка: accuracy должен быть >= 0
    IF accuracy < 0 THEN
        RAISE EXCEPTION 'Точность (accuracy) должна быть >= 0';
    END IF;

    -- Проверка a = 0
    IF a = 0 THEN
        RAISE EXCEPTION 'Коэффициент "a" не может быть равен нулю в квадратном уравнении';
    END IF;

    -- Вычисляем дискриминант
    d := b * b - 4 * a * c;

    -- Округляем дискриминант для сообщения об ошибке
    d_rounded := ROUND(d::numeric, accuracy);

    -- Проверка отрицательного дискриминанта
    IF d < 0 THEN
        RAISE EXCEPTION 'Дискриминант отрицательный (%): уравнение не имеет действительных корней',
            d_rounded;
    END IF;

    -- Вычисляем корни
    x1 := ROUND(((-b + SQRT(d)) / (2 * a))::NUMERIC, accuracy);
    x2 := ROUND(((-b - SQRT(d)) / (2 * a))::NUMERIC, accuracy);

    RETURN;
END;
$$ LANGUAGE plpgsql;


select square_equation_1(0,-6,2,4);

select *
from square_equation_1(3,-6,4,3);

SELECT square_equation_1(3, -6, 2)
FROM generate_series(1, 10);

SELECT square_equation(3, -6, 2)
FROM generate_series(1, 10);

/*Создайте таблицу coeffs, содержащую значения коэффициентов уравнений столбцы a,b,c.
  Введите в нее несколько строк. Напишите запрос, в котором функция решает все уравнения,
  определяемые коэффициентами из каждой строки таблицы, но также и в виде отдельных столбцов.

  */

-- Создаем таблицу
CREATE TABLE coeffs (
                        id SERIAL PRIMARY KEY,
                        a DOUBLE PRECISION NOT NULL CHECK (a != 0),
                        b DOUBLE PRECISION NOT NULL,
                        c DOUBLE PRECISION NOT NULL,
                        equation_name TEXT,
                        discriminant DOUBLE PRECISION GENERATED ALWAYS AS (b * b - 4 * a * c) STORED,
                        CHECK (discriminant >= 0), -- Гарантируем неотрицательный дискриминант
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Заполняем только корректными данными
INSERT INTO coeffs (a, b, c, equation_name) VALUES
-- Два действительных корня (D > 0)
(1, -3, 2, 'x² - 3x + 2 = 0 (корни: 2, 1)'),
(1, 0, -4, 'x² - 4 = 0 (корни: 2, -2)'),
(2, 5, -3, '2x² + 5x - 3 = 0 (корни: 0.5, -3)'),
(1, -5, 6, 'x² - 5x + 6 = 0 (корни: 3, 2)'),
(1, 1, -6, 'x² + x - 6 = 0 (корни: 2, -3)'),
(2, -7, 3, '2x² - 7x + 3 = 0 (корни: 3, 0.5)'),
(1, -8, 12, 'x² - 8x + 12 = 0 (корни: 6, 2)'),

-- Один действительный корень (D = 0)
(1, 4, 4, 'x² + 4x + 4 = 0 (один корень: -2)'),
(1, -6, 9, 'x² - 6x + 9 = 0 (один корень: 3)'),
(4, 4, 1, '4x² + 4x + 1 = 0 (один корень: -0.5)'),
(9, -12, 4, '9x² - 12x + 4 = 0 (один корень: 2/3)'),

-- Дробные коэффициенты
(1.5, -2.7, 1.2, '1.5x² - 2.7x + 1.2 = 0'),
(0.5, 1.5, -2, '0.5x² + 1.5x - 2 = 0'),
(2.25, -3.75, 1.25, '2.25x² - 3.75x + 1.25 = 0'),

-- Разные комбинации знаков
(1, 3, 2, 'x² + 3x + 2 = 0 (корни: -1, -2)'),
(1, -2, -3, 'x² - 2x - 3 = 0 (корни: 3, -1)'),
(1, 2, -3, 'x² + 2x - 3 = 0 (корни: 1, -3)'),
(1, -4, -5, 'x² - 4x - 5 = 0 (корни: 5, -1)'),

-- Коэффициенты с нулевым b
(2, 0, -8, '2x² - 8 = 0 (корни: 2, -2)'),
(3, 0, -27, '3x² - 27 = 0 (корни: 3, -3)'),

-- Коэффициенты с нулевым c
(1, 3, 0, 'x² + 3x = 0 (корни: 0, -3)'),
(2, -5, 0, '2x² - 5x = 0 (корни: 2.5, 0)'),

-- Более сложные случаи
(1, -2.5, 1.5, 'x² - 2.5x + 1.5 = 0'),
(0.25, -1, 1, '0.25x² - x + 1 = 0 (один корень: 2)');

SELECT *
FROM coeffs;

/*OUT x1 numeric,
OUT x2 numeric

Что происходит:
Функция вызывается ДВАЖДЫ для каждой строки
Первый вызов: получаем x1
Второй вызов: получаем x2
 */

EXPLAIN ANALYZE
SELECT x1(square_equation(a, b, c)), x2(square_equation(a, b, c))
FROM coeffs;

/*Функция вызывается ОДИН РАЗ для каждой строки
* разворачивает все поля результата*/

EXPLAIN ANALYZE VERBOSE
SELECT (square_equation(a, b, c)).*
FROM coeffs;

EXPLAIN ANALYZE VERBOSE
SELECT x1, x2
FROM coeffs
         CROSS JOIN LATERAL square_equation(a, b, c);

EXPLAIN ANALYZE VERBOSE
SELECT s.x1, s.x2
FROM coeffs,
     square_equation(a, b, c) AS s( x1, x2 );

/*Расчет заработной платы пилотов в зависимости от оклада, районного
  коэффициента, и различных персональных надбавок, а также
  с учетом налогов, вызовите вашу функцию в запросе возвращающей более
  одной строки, чтобы функция проводила вычисления на основе различных исходных
  значений, получаемых из базы данных*/


pilots (master table)
       │
    ├───┬─── personal_allowances (1:N)
    │   └─── pilot_id → pilots.pilot_id
    │
    ├───┬─── salary_calculations (1:N)
    │   └─── pilot_id → pilots.pilot_id
    │
    ├───┼─── base_salaries (N:1 via rank + license_type)
    │   │    pilots.rank → base_salaries.rank
    │   │    pilots.license_type → base_salaries.license_type
    │   │
    │   └─── experience_categories (N:1 via experience)
    │        (current_date - pilots.hire_date) BETWEEN
    │        experience_categories.min_years AND max_years
    │
    └───┼─── tax_rates (indirect via salary)
         │    salary_calculations.gross_salary BETWEEN
         │    tax_rates.min_income AND max_income
-- Таблица пилотов
CREATE TABLE pilots (
                        pilot_id SERIAL PRIMARY KEY,
                        first_name VARCHAR(50) NOT NULL,
                        last_name VARCHAR(50) NOT NULL,
                        birth_date DATE NOT NULL,
                        hire_date DATE NOT NULL,
                        license_type VARCHAR(20) CHECK (license_type IN ('ATPL', 'CPL', 'MPL')),
                        rank VARCHAR(20) CHECK (rank IN ('Капитан', 'Первый офицер', 'Второй офицер')),
                        base_city VARCHAR(50) NOT NULL,
                        region_coefficient NUMERIC(4,2) DEFAULT 1.0,
                        has_northern_allowance BOOLEAN DEFAULT FALSE,
                        northern_coefficient NUMERIC(4,2) DEFAULT 1.0
);

-- Комментарии для таблицы pilots
COMMENT ON TABLE pilots IS 'Основная таблица сотрудников - пилотов авиакомпании. Содержит персональные данные, квалификацию и региональные коэффициенты.';

-- Комментарии для полей таблицы pilots
COMMENT ON COLUMN pilots.pilot_id IS 'Уникальный идентификатор пилота. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN pilots.first_name IS 'Имя пилота. Обязательное поле, максимальная длина 50 символов.';
COMMENT ON COLUMN pilots.last_name IS 'Фамилия пилота. Обязательное поле, максимальная длина 50 символов.';
COMMENT ON COLUMN pilots.birth_date IS 'Дата рождения пилота. Используется для расчета возраста и пенсионных отчислений.';
COMMENT ON COLUMN pilots.hire_date IS 'Дата приема на работу. Используется для расчета стажа работы в компании.';
COMMENT ON COLUMN pilots.license_type IS 'Тип летной лицензии: ATPL (Airline Transport), CPL (Commercial), MPL (Multi-crew). Определяет квалификацию пилота.';
COMMENT ON COLUMN pilots.rank IS 'Должность пилота: Капитан (командир ВС), Первый офицер (второй пилот), Второй офицер (третий пилот).';
COMMENT ON COLUMN pilots.base_city IS 'Базовый город работы пилота. Влияет на региональный коэффициент и логистику.';
COMMENT ON COLUMN pilots.region_coefficient IS 'Региональный коэффициент к зарплате. Например: 1.2 для Москвы, 1.7 для Крайнего Севера.';
COMMENT ON COLUMN pilots.has_northern_allowance IS 'Флаг наличия права на северную надбавку. TRUE - имеет право, FALSE - не имеет.';
COMMENT ON COLUMN pilots.northern_coefficient IS 'Коэффициент северной надбавки. Диапазон от 1.0 до 2.0 в зависимости от региона.';

-- Таблица стажа и категорий
CREATE TABLE experience_categories (
                                       category_id SERIAL PRIMARY KEY,
                                       min_years INTEGER NOT NULL,
                                       max_years INTEGER,
                                       category_name VARCHAR(50) NOT NULL,
                                       experience_bonus_percent NUMERIC(5,2) NOT NULL
);

-- Комментарии для таблицы experience_categories
COMMENT ON TABLE experience_categories IS 'Категории стажа работы с соответствующими процентами надбавок. Используется для автоматического расчета премии за выслугу лет.';

-- Комментарии для полей таблицы experience_categories
COMMENT ON COLUMN experience_categories.category_id IS 'Уникальный идентификатор категории стажа. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN experience_categories.min_years IS 'Минимальный стаж в годах для попадания в категорию (включительно).';
COMMENT ON COLUMN experience_categories.max_years IS 'Максимальный стаж в годах для категории (исключительно). NULL означает "и выше".';
COMMENT ON COLUMN experience_categories.category_name IS 'Название категории стажа. Например: "Начинающий", "Опытный", "Эксперт".';
COMMENT ON COLUMN experience_categories.experience_bonus_percent IS 'Процент надбавки к окладу за стаж работы. Например: 5.00 = 5% надбавки.';

-- Таблица окладов по должностям
CREATE TABLE base_salaries (
                               salary_id SERIAL PRIMARY KEY,
                               rank VARCHAR(20) UNIQUE NOT NULL,
                               license_type VARCHAR(20) NOT NULL,
                               base_salary NUMERIC(10,2) NOT NULL
);

-- Комментарии для таблицы base_salaries
COMMENT ON TABLE base_salaries IS 'Базовые оклады по должностям и типам лицензий. Тарифная сетка компании.';

-- Комментарии для полей таблицы base_salaries
COMMENT ON COLUMN base_salaries.salary_id IS 'Уникальный идентификатор записи об окладе. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN base_salaries.rank IS 'Должность пилота. Должен соответствовать значениям из таблицы pilots.rank. Уникальное значение.';
COMMENT ON COLUMN base_salaries.license_type IS 'Тип лицензии. Должен соответствовать значениям из таблицы pilots.license_type.';
COMMENT ON COLUMN base_salaries.base_salary IS 'Базовый месячный оклад в рублях до вычета налогов и коэффициентов.';

-- Таблица персональных надбавок
CREATE TABLE personal_allowances (
                                     allowance_id SERIAL PRIMARY KEY,
                                     pilot_id INTEGER REFERENCES pilots(pilot_id),
                                     allowance_type VARCHAR(50) CHECK (allowance_type IN ('За знание языков', 'За ночные рейсы',
                                                                                          'За международные рейсы', 'За сложные условия',
                                                                                          'За выслугу лет', 'Другое')),
                                     amount NUMERIC(10,2) NOT NULL,
                                     valid_from DATE NOT NULL,
                                     valid_to DATE,
                                     is_permanent BOOLEAN DEFAULT FALSE
);

-- Комментарии для таблицы personal_allowances
COMMENT ON TABLE personal_allowances IS 'Дополнительные выплаты пилотам сверх базового оклада. Могут быть постоянными или временными.';

-- Комментарии для полей таблицы personal_allowances
COMMENT ON COLUMN personal_allowances.allowance_id IS 'Уникальный идентификатор надбавки. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN personal_allowances.pilot_id IS 'Ссылка на пилота. Внешний ключ к таблице pilots.pilot_id.';
COMMENT ON COLUMN personal_allowances.allowance_type IS 'Тип надбавки: за языки, ночные рейсы, международные рейсы, сложные условия, выслугу лет или другие.';
COMMENT ON COLUMN personal_allowances.amount IS 'Сумма надбавки в рублях. Ежемесячная выплата.';
COMMENT ON COLUMN personal_allowances.valid_from IS 'Дата начала действия надбавки. С этой даты надбавка включается в расчет зарплаты.';
COMMENT ON COLUMN personal_allowances.valid_to IS 'Дата окончания действия надбавки. NULL означает бессрочное действие.';
COMMENT ON COLUMN personal_allowances.is_permanent IS 'Флаг постоянной надбавки. TRUE - надбавка без срока действия, FALSE - временная надбавка.';

-- Таблица налоговых ставок
CREATE TABLE tax_rates (
                           tax_id SERIAL PRIMARY KEY,
                           rate_name VARCHAR(50) NOT NULL,
                           min_income NUMERIC(10,2),
                           max_income NUMERIC(10,2),
                           tax_percent NUMERIC(5,2) NOT NULL,
                           effective_date DATE NOT NULL
);

-- Комментарии для таблицы tax_rates
COMMENT ON TABLE tax_rates IS 'Актуальные ставки НДФЛ (налога на доходы физических лиц). Поддерживает прогрессивную шкалу налогообложения.';

-- Комментарии для полей таблицы tax_rates
COMMENT ON COLUMN tax_rates.tax_id IS 'Уникальный идентификатор налоговой ставки. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN tax_rates.rate_name IS 'Название налоговой ставки. Например: "Основная ставка НДФЛ", "Повышенная ставка для высоких доходов".';
COMMENT ON COLUMN tax_rates.min_income IS 'Минимальный годовой доход для применения ставки (включительно). NULL означает "от 0".';
COMMENT ON COLUMN tax_rates.max_income IS 'Максимальный годовой доход для применения ставки (включительно). NULL означает "и выше".';
COMMENT ON COLUMN tax_rates.tax_percent IS 'Процент налога. Например: 13.00 = 13% от налогооблагаемой базы.';
COMMENT ON COLUMN tax_rates.effective_date IS 'Дата вступления ставки в силу. Позволяет хранить историю изменений налогового законодательства.';

-- Таблица расчетов зарплаты (история)
CREATE TABLE salary_calculations (
                                     calculation_id SERIAL PRIMARY KEY,
                                     pilot_id INTEGER REFERENCES pilots(pilot_id),
                                     calculation_date DATE NOT NULL DEFAULT CURRENT_DATE,
                                     period_start DATE NOT NULL,
                                     period_end DATE NOT NULL,
                                     base_salary NUMERIC(10,2),
                                     region_coefficient NUMERIC(4,2),
                                     northern_coefficient NUMERIC(4,2),
                                     experience_bonus_percent NUMERIC(5,2),
                                     total_allowances NUMERIC(10,2),
                                     gross_salary NUMERIC(10,2),
                                     tax_amount NUMERIC(10,2),
                                     tax_percent NUMERIC(5,2),
                                     net_salary NUMERIC(10,2),
                                     calculation_details JSONB
);

-- Комментарии для таблицы salary_calculations
COMMENT ON TABLE salary_calculations IS 'Журнал расчетов заработной платы за различные периоды. Позволяет отслеживать историю выплат и проводить аудит.';

-- Комментарии для полей таблицы salary_calculations
COMMENT ON COLUMN salary_calculations.calculation_id IS 'Уникальный идентификатор расчета зарплаты. Автоматически генерируемый последовательный номер.';
COMMENT ON COLUMN salary_calculations.pilot_id IS 'Ссылка на пилота. Внешний ключ к таблице pilots.pilot_id.';
COMMENT ON COLUMN salary_calculations.calculation_date IS 'Дата проведения расчета зарплаты. По умолчанию - текущая дата.';
COMMENT ON COLUMN salary_calculations.period_start IS 'Начало расчетного периода. Обычно первое число месяца.';
COMMENT ON COLUMN salary_calculations.period_end IS 'Конец расчетного периода. Обычно последнее число месяца.';
COMMENT ON COLUMN salary_calculations.base_salary IS 'Базовый оклад пилота на момент расчета. Фиксируется для истории.';
COMMENT ON COLUMN salary_calculations.region_coefficient IS 'Региональный коэффициент на момент расчета. Фиксируется для истории.';
COMMENT ON COLUMN salary_calculations.northern_coefficient IS 'Северный коэффициент на момент расчета. Фиксируется для истории.';
COMMENT ON COLUMN salary_calculations.experience_bonus_percent IS 'Процент надбавки за стаж на момент расчета. Фиксируется для истории.';
COMMENT ON COLUMN salary_calculations.total_allowances IS 'Сумма всех персональных надбавок за расчетный период.';
COMMENT ON COLUMN salary_calculations.gross_salary IS 'Начисленная зарплата до вычета налогов (грязная зарплата).';
COMMENT ON COLUMN salary_calculations.tax_amount IS 'Сумма удержанного налога на доходы физических лиц (НДФЛ).';
COMMENT ON COLUMN salary_calculations.tax_percent IS 'Примененная налоговая ставка в процентах.';
COMMENT ON COLUMN salary_calculations.net_salary IS 'Зарплата к выплате после вычета налогов (чистая зарплата).';
COMMENT ON COLUMN salary_calculations.calculation_details IS 'Детальная информация о расчете в формате JSON. Содержит состав надбавок, применяемые коэффициенты и другие параметры.';


-- 1. Вставляем категории стажа (experience_categories)
INSERT INTO experience_categories (min_years, max_years, category_name, experience_bonus_percent)
VALUES (0, 2, 'Начинающий', 5.00),
       (2, 5, 'Опытный специалист', 10.00),
       (5, 10, 'Старший специалист', 15.00),
       (10, 20, 'Ведущий специалист', 20.00),
       (20, NULL, 'Эксперт', 25.00);

-- 2. Вставляем базовые оклады (base_salaries)
--truncate base_salaries
INSERT INTO base_salaries (rank, license_type, base_salary)
VALUES ('Капитан', 'ATPL', 350000.00),
       ('Капитан', 'CPL', 320000.00),
       ('Первый офицер', 'ATPL', 280000.00),
       ('Первый офицер', 'CPL', 250000.00),
       ('Второй офицер', 'MPL', 220000.00),
       ('Второй офицер', 'CPL', 200000.00);

-- 3. Вставляем налоговые ставки (tax_rates)
INSERT INTO tax_rates (rate_name, min_income, max_income, tax_percent, effective_date)
VALUES ('Основная ставка НДФЛ', 0.00, 5000000.00, 13.00, '2024-01-01'),
       ('Повышенная ставка НДФЛ', 5000000.01, NULL, 15.00, '2024-01-01');

-- 4. Вставляем 20 пилотов (pilots)
INSERT INTO pilots (first_name, last_name, birth_date, hire_date, license_type, rank, base_city, region_coefficient,
                    has_northern_allowance, northern_coefficient)
VALUES
-- Старшие капитаны с большим опытом
('Александр', 'Иванов', '1978-03-15', '2000-06-10', 'ATPL', 'Капитан', 'Москва', 1.20, FALSE, 1.0),
('Дмитрий', 'Петров', '1980-11-22', '2002-09-15', 'ATPL', 'Капитан', 'Новосибирск', 1.30, TRUE, 1.5),
('Михаил', 'Сидоров', '1982-05-30', '2005-03-20', 'ATPL', 'Капитан', 'Екатеринбург', 1.25, FALSE, 1.0),
('Сергей', 'Кузнецов', '1985-08-14', '2008-07-05', 'ATPL', 'Капитан', 'Хабаровск', 1.40, TRUE, 1.7),

-- Капитаны со средним опытом
('Андрей', 'Попов', '1987-02-18', '2010-11-12', 'CPL', 'Капитан', 'Краснодар', 1.15, FALSE, 1.0),
('Алексей', 'Лебедев', '1988-12-25', '2012-04-18', 'ATPL', 'Капитан', 'Владивосток', 1.35, TRUE, 1.6),
('Павел', 'Соколов', '1990-07-03', '2014-02-28', 'ATPL', 'Капитан', 'Казань', 1.10, FALSE, 1.0),

-- Первые офицеры с опытом
('Иван', 'Козлов', '1991-09-17', '2015-08-22', 'ATPL', 'Первый офицер', 'Нижний Новгород', 1.18, FALSE, 1.0),
('Роман', 'Новиков', '1992-06-11', '2016-01-15', 'ATPL', 'Первый офицер', 'Мурманск', 1.50, TRUE, 2.0),
('Евгений', 'Морозов', '1993-02-28', '2017-05-30', 'CPL', 'Первый офицер', 'Омск', 1.22, FALSE, 1.0),

-- Первые офицеры (молодые)
('Виктор', 'Волков', '1994-10-05', '2018-03-14', 'CPL', 'Первый офицер', 'Ростов-на-Дону', 1.16, FALSE, 1.0),
('Григорий', 'Алексеев', '1995-01-19', '2019-07-08', 'CPL', 'Первый офицер', 'Красноярск', 1.32, TRUE, 1.4),

-- Вторые офицеры
('Артем', 'Семенов', '1996-08-12', '2020-10-01', 'MPL', 'Второй офицер', 'Уфа', 1.12, FALSE, 1.0),
('Константин', 'Егоров', '1997-03-27', '2021-12-05', 'MPL', 'Второй офицер', 'Иркутск', 1.28, TRUE, 1.3),
('Станислав', 'Павлов', '1993-05-30', '2022-04-20', 'CPL', 'Второй офицер', 'Волгоград', 1.14, FALSE, 1.0),

-- Разные города и условия
('Вадим', 'Степанов', '1989-11-08', '2013-08-15', 'ATPL', 'Капитан', 'Якутск', 1.45, TRUE, 1.8),
('Олег', 'Николаев', '1990-06-14', '2015-01-10', 'CPL', 'Первый офицер', 'Калининград', 1.20, FALSE, 1.0),
('Максим', 'Орлов', '1984-04-09', '2009-11-22', 'ATPL', 'Капитан', 'Магадан', 1.48, TRUE, 1.9),
('Юрий', 'Андреев', '1995-12-01', '2021-05-18', 'MPL', 'Второй офицер', 'Самара', 1.13, FALSE, 1.0),
('Владислав', 'Макаров', '1992-07-24', '2018-02-28', 'CPL', 'Первый офицер', 'Тюмень', 1.26, FALSE, 1.0);

-- 5. Вставляем персональные надбавки (personal_allowances)
-- Надбавки распределены между разными пилотами
INSERT INTO personal_allowances (pilot_id, allowance_type, amount, valid_from, valid_to, is_permanent)
VALUES
-- Постоянные надбавки
(1, 'За знание языков', 20000.00, '2020-01-01', NULL, TRUE),
(2, 'За северные условия', 35000.00, '2015-01-01', NULL, TRUE),
(3, 'За международные рейсы', 25000.00, '2018-06-01', NULL, TRUE),
(4, 'За сложные условия', 30000.00, '2019-03-15', NULL, TRUE),
(5, 'За выслугу лет', 15000.00, '2020-01-01', NULL, TRUE),
(6, 'За знание языков', 18000.00, '2021-02-01', NULL, TRUE),

-- Временные надбавки (на определенный период)
(7, 'За ночные рейсы', 12000.00, '2024-03-01', '2024-12-31', FALSE),
(8, 'За международные рейсы', 22000.00, '2024-04-01', '2024-10-31', FALSE),
(9, 'За северные условия', 40000.00, '2023-01-01', '2025-12-31', FALSE),
(10, 'За сложные условия', 20000.00, '2024-05-01', '2024-11-30', FALSE),
(11, 'За знание языков', 15000.00, '2024-01-01', '2024-12-31', FALSE),

-- Дополнительные надбавки
(12, 'За ночные рейсы', 14000.00, '2024-06-01', '2024-12-31', FALSE),
(13, 'За международные рейсы', 18000.00, '2024-02-01', '2024-08-31', FALSE),
(14, 'За северные условия', 32000.00, '2022-07-01', '2024-12-31', FALSE),
(15, 'За выслугу лет', 10000.00, '2024-01-01', NULL, TRUE),
(16, 'За сложные условия', 28000.00, '2023-11-01', '2025-06-30', FALSE),
(17, 'За знание языков', 17000.00, '2024-03-15', '2024-09-30', FALSE),
(18, 'За северные условия', 45000.00, '2020-01-01', NULL, TRUE),
(19, 'За ночные рейсы', 11000.00, '2024-04-01', '2024-12-31', FALSE),
(20, 'За международные рейсы', 19000.00, '2024-01-01', '2024-12-31', FALSE),

-- Некоторые пилоты имеют несколько надбавок
(1, 'За международные рейсы', 18000.00, '2023-01-01', '2024-12-31', FALSE),
(2, 'За сложные условия', 22000.00, '2024-01-01', NULL, TRUE),
(3, 'За знание языков', 16000.00, '2022-08-01', NULL, TRUE),
(5, 'За ночные рейсы', 13000.00, '2024-03-01', '2024-09-30', FALSE),
(8, 'За северные условия', 28000.00, '2024-01-01', '2025-01-01', FALSE),
(12, 'За международные рейсы', 21000.00, '2024-05-01', '2024-11-30', FALSE);

-- 6. Вставляем историю расчетов зарплаты (salary_calculations)
-- За последние 3 месяца для всех пилотов
INSERT INTO salary_calculations (pilot_id, calculation_date, period_start, period_end,
                                 base_salary, region_coefficient, northern_coefficient,
                                 experience_bonus_percent, total_allowances,
                                 gross_salary, tax_amount, tax_percent, net_salary, calculation_details)
SELECT p.pilot_id,
       CASE
           WHEN m.month_offset = 0 THEN CURRENT_DATE - INTERVAL '5 days'
           WHEN m.month_offset = 1 THEN CURRENT_DATE - INTERVAL '35 days'
           WHEN m.month_offset = 2 THEN CURRENT_DATE - INTERVAL '65 days'
           END                                                                                AS calculation_date,
       DATE_TRUNC('month', CURRENT_DATE - (m.month_offset || ' months')::INTERVAL)            AS period_start,
       (DATE_TRUNC('month', CURRENT_DATE - (m.month_offset || ' months')::INTERVAL) + INTERVAL '1 month' -
        INTERVAL '1 day')::DATE                                                               AS period_end,
       bs.base_salary,
       p.region_coefficient,
       p.northern_coefficient,
       ec.experience_bonus_percent,
       COALESCE(pa.total_allowances, 0)                                                       AS total_allowances,
       -- Расчет гросс-зарплаты
       ROUND((bs.base_salary * p.region_coefficient * p.northern_coefficient *
              (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)), 2) AS gross_salary,
       -- Расчет налога
       ROUND((bs.base_salary * p.region_coefficient * p.northern_coefficient *
              (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)) *
             CASE
                 WHEN (bs.base_salary * p.region_coefficient * p.northern_coefficient *
                       (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)) > 416666.67
                     THEN 0.15 -- Годовой эквивалент > 5 млн
                 ELSE 0.13
                 END, 2)                                                                      AS tax_amount,
       CASE
           WHEN (bs.base_salary * p.region_coefficient * p.northern_coefficient *
                 (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)) > 416666.67
               THEN 15.00
           ELSE 13.00
           END                                                                                AS tax_percent,
       -- Расчет чистой зарплаты
       ROUND((bs.base_salary * p.region_coefficient * p.northern_coefficient *
              (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)) *
             (1 - CASE
                      WHEN (bs.base_salary * p.region_coefficient * p.northern_coefficient *
                            (1 + ec.experience_bonus_percent / 100) + COALESCE(pa.total_allowances, 0)) > 416666.67
                          THEN 0.15
                      ELSE 0.13
                 END), 2)                                                                     AS net_salary,
       -- Детали расчета в JSON
       JSONB_BUILD_OBJECT(
               'experience_years',
               ROUND(EXTRACT(YEAR FROM AGE(CURRENT_DATE - (m.month_offset || ' months')::INTERVAL, p.hire_date)) +
                     EXTRACT(MONTH FROM AGE(CURRENT_DATE - (m.month_offset || ' months')::INTERVAL, p.hire_date)) /
                     12.0, 2),
               'category_name', ec.category_name,
               'allowances_details', COALESCE(pa.allowances_json, '[]'::jsonb)
       )                                                                                      AS calculation_details
FROM pilots p
         JOIN base_salaries bs ON p.rank = bs.rank AND p.license_type = bs.license_type
         JOIN experience_categories ec ON
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) >= ec.min_years
        AND (ec.max_years IS NULL OR EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) < ec.max_years)
         LEFT JOIN (SELECT pilot_id,
                           SUM(amount)  AS total_allowances,
                           JSONB_AGG(JSONB_BUILD_OBJECT(
                                   'type', allowance_type,
                                   'amount', amount,
                                   'valid_from', valid_from,
                                   'valid_to', valid_to
                                     )) AS allowances_json
                    FROM personal_allowances
                    WHERE valid_from <= CURRENT_DATE
                      AND (valid_to IS NULL OR valid_to >= CURRENT_DATE - INTERVAL '3 months')
                    GROUP BY pilot_id) pa ON p.pilot_id = pa.pilot_id
         CROSS JOIN (VALUES (0), (1), (2)) AS m( month_offset ) -- 3 последних месяца
WHERE p.pilot_id <= 20 -- Все 20 пилотов
ORDER BY p.pilot_id, m.month_offset DESC;

-- 1. Проверяем количество записей
SELECT 'pilots' AS table_name, COUNT(*) AS count
FROM pilots
UNION ALL
SELECT 'experience_categories', COUNT(*)
FROM experience_categories
UNION ALL
SELECT 'base_salaries', COUNT(*)
FROM base_salaries
UNION ALL
SELECT 'tax_rates', COUNT(*)
FROM tax_rates
UNION ALL
SELECT 'personal_allowances', COUNT(*)
FROM personal_allowances
UNION ALL
SELECT 'salary_calculations', COUNT(*)
FROM salary_calculations;

SELECT *
FROM pilots;

select *
FROM experience_categories;

SELECT  *
FROM base_salaries;

SELECT *
FROM tax_rates;

SELECT *
FROM personal_allowances;

/*
UPDATE personal_allowances
SET valid_to = '9999-12-31'::DATE
WHERE valid_to IS NULL;
*/

/*
SELECT *
FROM salary_calculations;
*/


/*Создать функцию по расчету заработной платы пилотов в зависимости от оклада, районного
  коэффициента, и различных персональных надбавок, а также
  с учетом налогов, вызовите вашу функцию в запросе возвращающей более
  одной строки, чтобы функция проводила вычисления на основе различных исходных
  значений, получаемых из базы данных*/


SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) as experience_interval,
        AGE(CURRENT_DATE, hire_date) as age_mons_days_hours_mins_secs
FROM pilots;

SELECT *
FROM pilots;

select *
FROM experience_categories;

SELECT  *
FROM base_salaries;


/*Вычисляем пилотов и надбавки и бонусы, которые им положены*/
with pilots_cte as (SELECT
    p.pilot_id,
    p.first_name || ' ' || p.last_name as pilot_name, -- Рассчитываем стаж в годах
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) as experience_years,  -- Определяем категорию
    ec.category_name,
    coalesce(ec.experience_bonus_percent, 0) as experience_bonus_percent,
    p.region_coefficient,
    p.northern_coefficient,
    bs.base_salary,
    (bs.base_salary *  p.region_coefficient *
    p.northern_coefficient * (COALESCE(ec.experience_bonus_percent,  0.00001)/100+1) ) * 12 as for_year,
    tr.tax_percent
FROM pilots p
left JOIN personal_allowances pa ON p.pilot_id = pa.pilot_id
left JOIN experience_categories ec ON
    -- Проверяем, что стаж попадает в диапазон
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) >= ec.min_years
AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) < ec.max_years
left join base_salaries bs on bs.license_type = p.license_type
and bs.rank = p.rank
left join tax_rates tr on  -- может быть несколько надбавок
    (bs.base_salary *  p.region_coefficient *
               p.northern_coefficient * (COALESCE(ec.experience_bonus_percent,  0)/100+1) )  * 12
    between tr.min_income and tr.max_income
group by
    p.pilot_id,
    pilot_name,
    experience_years,
    ec.category_name,
    ec.experience_bonus_percent,
    p.region_coefficient,
    p.northern_coefficient,
    bs.base_salary,
    for_year,
    tr.tax_percent
ORDER BY p.pilot_id)

select
    pilot_id,
    pilot_name,
    experience_years,
    category_name,
    experience_bonus_percent,
    region_coefficient,
    northern_coefficient,
    base_salary,
    for_year,
    tax_percent
from pilots_cte;




/*Функция*/

CREATE OR REPLACE FUNCTION get_pilot_salary_calc(
    INOUT p_pilot_id INTEGER DEFAULT NULL,  -- INOUT параметр
    OUT pilot_name TEXT,
    OUT experience_years NUMERIC,
    OUT category_name TEXT,
    OUT experience_bonus_percent NUMERIC,
    OUT region_coefficient NUMERIC,
    OUT northern_coefficient NUMERIC,
    OUT base_salary NUMERIC,
    OUT for_year NUMERIC,
    OUT tax_percent NUMERIC
)
    RETURNS SETOF record AS
$$
SELECT
    p.pilot_id,                    -- INTEGER (соответствует OUT pilot_id INTEGER)
    p.first_name || ' ' || p.last_name as pilot_name,  -- TEXT
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) as experience_years,  -- NUMERIC
    ec.category_name,              -- TEXT
    COALESCE(ec.experience_bonus_percent, 0) as experience_bonus_percent,  -- NUMERIC
    p.region_coefficient,          -- NUMERIC
    p.northern_coefficient,        -- NUMERIC
    bs.base_salary,                -- NUMERIC
    (bs.base_salary * p.region_coefficient *
     p.northern_coefficient * (COALESCE(ec.experience_bonus_percent, 0.00001)/100+1)) * 12 as for_year,  -- NUMERIC
    tr.tax_percent                 -- NUMERIC
FROM pilots p
         LEFT JOIN personal_allowances pa ON p.pilot_id = pa.pilot_id
         LEFT JOIN experience_categories ec ON
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) >= ec.min_years
        AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.hire_date)) < ec.max_years
         LEFT JOIN base_salaries bs ON bs.license_type = p.license_type
    AND bs.rank = p.rank
         LEFT JOIN tax_rates tr ON
    (bs.base_salary * p.region_coefficient *
     p.northern_coefficient * (COALESCE(ec.experience_bonus_percent, 0)/100+1)) * 12
        BETWEEN tr.min_income AND tr.max_income
WHERE p_pilot_id IS NULL OR p.pilot_id = p_pilot_id
GROUP BY
    p.pilot_id,
    p.first_name,
    p.last_name,
    p.hire_date,
    ec.category_name,
    ec.experience_bonus_percent,
    p.region_coefficient,
    p.northern_coefficient,
    bs.base_salary,
    tr.tax_percent
ORDER BY p.pilot_id;
$$
    LANGUAGE SQL;

/*Внешний цикл: таблица pilots (20 строк)
Внутренний цикл: функция get_pilot_salary_calc вызывается для каждой строки внешнего цикла
Всего выполнено 20 вызовов функции (loops=20)*/
explain analyze
select *
from pilots ps
cross join lateral get_pilot_salary_calc(ps.pilot_id);

/*Параметр конфигурации сервера можно изменить на время выполнения
  функции*/

  alter function get_rand_num set timezone = 'Europe/Moscow';

/*Видит ли изменчивая функция изменения, произведенные конкурентной
  транзакцией?

 Функция boarding_info должна иметь категорию volatile
*/

alter function boarding_info volatile;

/*Нужно привести БД в исходное состояние, чтобы избежать дублирования данных*/

delete from boarding_passes
where flight_id = 13841;

---begin isolation level read committed;
---begin isolation level repeatable read;

begin isolation level serializable;
WITH make_boarding AS
         (INSERT INTO boarding_passes ( ticket_no, flight_id, boarding_no, seat_no )
             VALUES ('0005433846800', 13841, 1, '1A')
             RETURNING *)
select bi.*
FROM pg_sleep(40),
    make_boarding AS mb
         CROSS JOIN LATERAL boarding(mb.flight_id, mb.boarding_no, 15.0, 12.5) AS b
         CROSS JOIN LATERAL boarding_info(mb.flight_id) AS bi;

end;
/*
Простой вывод:
SERIALIZABLE уровень изоляции работает как очень строгий учитель:
"Если я не могу гарантировать, что результат выполнения ваших транзакций
параллельно будет таким же, как если бы вы выполнялись строго одна за другой..."
"...то я отменю одну из транзакций и скажу: 'Начни заново!'"
"Это лучше, чем получить неправильные или несогласованные данные"

*/


/*На ктором терминале
  begin isolation level read committed;

WITH make_boarding AS
         (INSERT INTO boarding_passes ( ticket_no, flight_id, boarding_no, seat_no )
             VALUES ('0005432003745', 13841, 2, '6A')
             RETURNING *)
select bi.*
from make_boarding as mb,
    boarding(mb.flight_id, mb.boarding_no, 15.0, 12.5) as b,
    boarding_info(mb.flight_id) as bi

end;*/

select * from boarding_passes  where flight_id = 13841;
delete from boarding_passes
where flight_id = 13841;

SELECT query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE query LIKE '%boarding_passes%' OR query LIKE '%pg_sleep%';

/*А если вызвать изменчивую функцию из стабильной или постоянной?
  Требуется, чтобы стабильные и постоянные функции не содержали
  SQL-команд, кроме Select, для предотвращения модификации данных.
  Но из таких функцией могут быть вызваны изменчивые функции, способные
  модифицировать БД.
  В документации сказано, что если реализовать такую схему, то можно увидеть,
  что стабильные и постоянные функции не замечают изменений в базе данных,
  произведенных изменчивой функцией, поскольку такие изменения не проявляются
  в снимке данных*/

/*Не только багаж, но и питание
  C целью дальнейшего повышения качества обслуживания пассажиров наша авиакомпания
  решила опрашивать их перед полетом насчет предпочитаемого питания

  Необходимо создать таблицу и модифицировать функции,
  выполняющие регистрацию билета*/

-- Создание новой таблицы с именем "flight_meals" (бортовое питание)
CREATE TABLE flight_meals
(
    -- Определение первого столбца: идентификатор рейса
    flight_id   integer,

    -- Определение второго столбца: номер посадочного талона
    boarding_no integer,

    -- Определение третьего столбца: основное блюдо
    -- Тип данных: текстовая строка
    -- Ограничение NOT NULL: поле обязательно для заполнения
    main_course text NOT NULL

        -- Проверочное ограничение (CHECK constraint):
        -- Разрешены только три значения из списка: 'мясо', 'курица', 'рыба'
        -- Это обеспечивает валидацию данных на уровне БД
        CHECK (main_course IN ( 'мясо', 'курица', 'рыба' ) ),

    -- Определение первичного ключа таблицы:
    -- Составной ключ из двух столбцов (flight_id + boarding_no)
    -- Гарантирует уникальность каждой комбинации рейса и номера посадки
    PRIMARY KEY ( flight_id, boarding_no ),

    -- Определение внешнего ключа (ссылочная целостность):
    -- Столбцы flight_id и boarding_no ссылаются на другую таблицу
    FOREIGN KEY ( flight_id, boarding_no )

        -- Указание таблицы-родителя и столбцов для связи:
        -- Ссылка на таблицу boarding_passes (посадочные талоны)
        -- и её столбцы flight_id и boarding_no
        REFERENCES boarding_passes ( flight_id, boarding_no )

        -- Правило каскадного удаления:
        -- При удалении записи в таблице boarding_passes
        -- автоматически удаляются все связанные записи в этой таблице
        ON DELETE CASCADE
);

INSERT INTO flight_meals (flight_id, boarding_no, main_course)
SELECT
    bp.flight_id,
    bp.boarding_no,
    CASE FLOOR(RANDOM() * 3)
        WHEN 0 THEN 'мясо'
        WHEN 1 THEN 'курица'
        WHEN 2 THEN 'рыба'
        END as main_course
FROM (
         VALUES
             (30625,1),(30625,2),(30625,3),(30625,4),(30625,5),(30625,6),(30625,7),(30625,8),(30625,9),(30625,10),
             (30625,11),(30625,12),(30625,13),(30625,14),(30625,15),(30625,16),(30625,17),(30625,18),(30625,19),(30625,20),
             (30625,21),(30625,22),(30625,23),(30625,24),(30625,25),(30625,26),(30625,27),(30625,28),(30625,29),(30625,30),
             (30625,31),(30625,32),(30625,33),(30625,34),(30625,35),(30625,36),(30625,37),(30625,38),(30625,39),(30625,40),
             (30625,41),(30625,42),(30625,43),(30625,44),(30625,45),(30625,46),(30625,47),(30625,48),(30625,49),(30625,50),
             (30625,51),(30625,52),(30625,53),(30625,54),(30625,55),(30625,56),(30625,57),(30625,58),(30625,59),(30625,60),
             (30625,61),(30625,62),(30625,63),(30625,64),(30625,65),(30625,66),(30625,67),(30625,68),(30625,69),(30625,70),
             (30625,71),(30625,72),(30625,73),(30625,74),(30625,75),(30625,76),(30625,77),(30625,78),(30625,79),(30625,80),
             (30625,81),(30625,82),(30625,83),(30625,84),(30625,85),(30625,86),(30625,87),(30625,88),(30625,89),(30625,90),
             (30625,91),(30625,92),
             (24836,1),(24836,2),(24836,3),(24836,4),(24836,5),(24836,6),(24836,7),(24836,8),(24836,9),(24836,10),
             (24836,11),(24836,12),(24836,13),(24836,14),(24836,15),(24836,16),(24836,17),(24836,18),(24836,19),(24836,20),
             (24836,21),(24836,22),(24836,23),(24836,24),(24836,25),(24836,26),(24836,27),(24836,28),(24836,29),(24836,30),
             (24836,31),(24836,32),(24836,33),(24836,34),(24836,35),(24836,36),(24836,37),(24836,38),(24836,39),(24836,40),
             (24836,41),
             (2055,1),(2055,2),(2055,3),(2055,4),(2055,5),(2055,6),(2055,7),(2055,8),(2055,9),(2055,10),
             (2055,11),(2055,12),(2055,13),(2055,14),(2055,15),(2055,16),(2055,17),(2055,18),(2055,19),(2055,20),
             (2055,21),(2055,22),(2055,23),(2055,24),(2055,25),(2055,26),(2055,27),(2055,28),(2055,29),(2055,30),
             (2055,31),(2055,32),(2055,33),(2055,34),
             (2575,1),(2575,2),(2575,3),(2575,4),
             (28205,1),(28205,2),
             (19732,1),(19732,2),(19732,3),(19732,4),
             (19092,1),(19092,2),
             (6786,1),(6786,2),(6786,3),(6786,4),(6786,5),(6786,6),(6786,7),(6786,8),(6786,9),(6786,10),
             (6786,11),(6786,12),
             (25029,1),(25029,2),(25029,3),(25029,4),
             (823,1),(823,2),(823,3),(823,4),(823,5),(823,6),(823,7),(823,8),(823,9),
             (16157,1),(16157,2),(16157,3),
             (4021,1),(4021,2),(4021,3),(4021,4),
             (3660,1),(3660,2),(3660,3),(3660,4),(3660,5),(3660,6),(3660,7),(3660,8),(3660,9),(3660,10),
             (3660,11),(3660,12),(3660,13),(3660,14),(3660,15),(3660,16),(3660,17),(3660,18),(3660,19),(3660,20),
             (3660,21),(3660,22),(3660,23),(3660,24),(3660,25),(3660,26),(3660,27),(3660,28),(3660,29),(3660,30),
             (3660,31),(3660,32),
             (16272,1),(16272,2),
             (3993,1),(3993,2),(3993,3),(3993,4),(3993,5),(3993,6),(3993,7),(3993,8),(3993,9),(3993,10),
             (3993,11),(3993,12),(3993,13),(3993,14),(3993,15),(3993,16),(3993,17),(3993,18),(3993,19),
             (22080,1),(22080,2),(22080,3),
             (728,1),(728,2),(728,3),(728,4),
             (15900,1),(15900,2),(15900,3),(15900,4),(15900,5),
             (17677,1),(17677,2),(17677,3),
             (7862,1),(7862,2),(7862,3),(7862,4),(7862,5),(7862,6),(7862,7),(7862,8),(7862,9),(7862,10),
             (7862,11),
             (33092,1),(33092,2),(33092,3),(33092,4),(33092,5),
             (7477,1),(7477,2),(7477,3),(7477,4),(7477,5),(7477,6),(7477,7),(7477,8),(7477,9),(7477,10),
             (7477,11),
             (29573,1),(29573,2),(29573,3),(29573,4),(29573,5),(29573,6),(29573,7),
             (6547,1),(6547,2),(6547,3),(6547,4),(6547,5),(6547,6),(6547,7),(6547,8),(6547,9),(6547,10),
             (6547,11),(6547,12),(6547,13),(6547,14),(6547,15),(6547,16),(6547,17),(6547,18),(6547,19),(6547,20),
             (6547,21),(6547,22),(6547,23),(6547,24),(6547,25),(6547,26),(6547,27),(6547,28),(6547,29),(6547,30),
             (6547,31),(6547,32),(6547,33),(6547,34),(6547,35),(6547,36),(6547,37),(6547,38),(6547,39),(6547,40),
             (6547,41),(6547,42),(6547,43),(6547,44),(6547,45),(6547,46),(6547,47),(6547,48),(6547,49),(6547,50),
             (1654,1),(1654,2),(1654,3),(1654,4),(1654,5),(1654,6),(1654,7),(1654,8),(1654,9),(1654,10),
             (1654,11),(1654,12),(1654,13),(1654,14),(1654,15),(1654,16),(1654,17),(1654,18),(1654,19),(1654,20),
             (1654,21),(1654,22),(1654,23),(1654,24),(1654,25),(1654,26),(1654,27),(1654,28),(1654,29),(1654,30),
             (1654,31),(1654,32),(1654,33),(1654,34),(1654,35),(1654,36),(1654,37),(1654,38),(1654,39),(1654,40),
             (1654,41),(1654,42),(1654,43),(1654,44),(1654,45),(1654,46),(1654,47),
             (21707,1),(21707,2),(21707,3),(21707,4),(21707,5),(21707,6),(21707,7),(21707,8),(21707,9),(21707,10),
             (21707,11),(21707,12),(21707,13),(21707,14),(21707,15),(21707,16),(21707,17),(21707,18),(21707,19),(21707,20),
             (21707,21),(21707,22),(21707,23),(21707,24),(21707,25),(21707,26),(21707,27),(21707,28),(21707,29),(21707,30),
             (21707,31),(21707,32),(21707,33),(21707,34),(21707,35),(21707,36),(21707,37),(21707,38),(21707,39),(21707,40),
             (21707,41)
     ) AS bp(flight_id, boarding_no);




DROP FUNCTION BOARDING_INFO_1;

CREATE OR REPLACE FUNCTION boarding_info_1(
    INOUT flight_id          INTEGER,
    OUT total_passengers     BIGINT,
    OUT total_luggage_pieces BIGINT,
    OUT total_luggage_weight NUMERIC,
    OUT meat_count           BIGINT,
    OUT chicken_count        BIGINT,
    OUT fish_count           BIGINT
)
    RETURNS RECORD AS
$$
WITH boarding_pass_info AS
         (SELECT COUNT(*) AS total_passengers
          FROM boarding_passes
          WHERE flight_id = boarding_info_1.flight_id),

     luggage_info AS
         (SELECT COUNT(*)    AS total_luggage_pieces,
                 SUM(weight) AS total_luggage_weight
          FROM luggage
          WHERE flight_id = boarding_info_1.flight_id),

     meal_counts AS
         (SELECT
              COUNT(CASE WHEN fm.main_course = 'мясо' THEN 1 END) as meat_count,
              COUNT(CASE WHEN fm.main_course = 'курица' THEN 1 END) as chicken_count,
              COUNT(CASE WHEN fm.main_course = 'рыба' THEN 1 END) as fish_count
          FROM flight_meals fm
          WHERE fm.flight_id = boarding_info_1.flight_id)

SELECT boarding_info_1.flight_id,
       COALESCE(bpi.total_passengers, 0) as total_passengers,
       COALESCE(li.total_luggage_pieces, 0) as total_luggage_pieces,
       COALESCE(li.total_luggage_weight, 0) as total_luggage_weight,
       COALESCE(mc.meat_count, 0) as meat_count,
       COALESCE(mc.chicken_count, 0) as chicken_count,
       COALESCE(mc.fish_count, 0) as fish_count
FROM boarding_pass_info AS bpi
         CROSS JOIN luggage_info AS li
         CROSS JOIN meal_counts AS mc;
$$ LANGUAGE sql STABLE;


select *
from boarding_info_1(2055);

/*Подведение итогов по операции бронирования
  В одной операции бронирования может быть оформлено несколько билетов, причем
  на разных пассажиров, а в каждом билете может присутствовать несколько перелетов
  Было бы удобно иметь функцию, которая собирает всю информацию об операции бронирования
  примерно таким образом*/

drop function get_booking_info;

CREATE OR REPLACE FUNCTION get_booking_info(
    INOUT in_book_ref  char(6),
    OUT ticket_no  char(13),
    OUT flight char(6),
    OUT da char(3),
    OUT aa char(3),
    OUT scheduled_departure  timestamp with time zone,
    OUT amount  numeric(10,2)
)
    RETURNS SETOF RECORD AS ---множество записей setof
$$
select tc.passenger_name as passenger_name,
       tc.ticket_no as ticket_no,
       fl.flight_no as flight,
       fl.departure_airport as da,
       fl.arrival_airport   as aa,
       fl.scheduled_departure as scheduled_departure,
       bs.total_amount as amount
from bookings bs
left join  tickets tc on tc.book_ref = bs.book_ref
left join boarding_passes bp on bp.ticket_no = tc.ticket_no
left  join flights  fl on bp.flight_id = fl.flight_id
where bs.book_ref =  in_book_ref
$$ LANGUAGE sql;

SELECT *
FROM get_booking_info('46850C');

SELECT tc.passenger_name      AS passenger_name,
       tc.ticket_no           AS ticket_no,
       fl.flight_no           AS flight,
       fl.departure_airport   AS da,
       fl.arrival_airport     AS aa,
       fl.scheduled_departure AS scheduled_departure,
       bs.total_amount        AS amount
FROM bookings bs
         LEFT JOIN tickets tc ON tc.book_ref = bs.book_ref
         LEFT JOIN boarding_passes bp ON bp.ticket_no = tc.ticket_no
         LEFT JOIN flights fl ON bp.flight_id = fl.flight_id
WHERE bs.book_ref = '46850C';

SELECT book_ref,
       COUNT(book_ref)
FROM tickets
GROUP BY book_ref
HAVING COUNT(book_ref) > 4;

/*Подстановка в запрос кода скалярной функции
  Возможна подстановка в запрос кода табличных функций и скалярных функций.
  Это такие функции которые можно использовать в выражениях или предикатах,
  то есть там, где требуется значение или условие

Скалярная функция (Scalar Function)
Возвращает одно значение (скаляр) для каждой строки результата.
Тип возвращаемого значения может быть любым:
integer, text, date, boolean и т.д.
Табличная функция (Table-Valued Function):
Возвращает набор строк (таблицу) с определенной структурой колонок.
Может возвращать 0, 1 или множество строк.

  Возьмем в качестве примера функцию, выбирающую фамилию пассажира из его полного имени
*/

create or replace function get_lastname(fullname text)
returns text as
    $$
    select substr(fullname, strpos(fullname,' ')+1);
    ---Шаг 2: strpos(fullname, ' ') + 1 Добавляет 1, чтобы начать с символа после пробела
    ---5 + 1 = 6 (начинаем с 6-го символа)
    $$ LANGUAGE sql IMMUTABLE;



CREATE OR REPLACE FUNCTION get_lastname_1(fullname text)
    RETURNS text AS
$$
SELECT
    CASE
        WHEN fullname ~ '.* .*'  -- проверка, что есть минимум два слова
            THEN regexp_replace(fullname, '^.* ', '')  -- удаляем все до последнего пробела
        ELSE ''
        END;
$$ LANGUAGE sql IMMUTABLE;


/*Обратите внимание, что код скалярной функции оказался подставленном
  в текст запроса. Чтобы такая подстановка стала возможной, требуется
  выполнить ряд условий, описанных в документе inlining of sql functions*
  В частности функция должна быть написана на языке SQL, она должна
  возвращать один столбец, тело функции должно состоять из единственной команды
  select выражение
  В этой команде не допускаются другие предложения, такие как from where group by
  и т.д. Возвращаемое значение функции не должно быть определено как
  returns record, returns setof или returns table.
  А какой выигрыш в скорости выполнения запроса мы получили при подстановке в него
  кода функции? Для ответа на вопрос нужно каким-то образом запретить подстановку
  кода.

  У функций есть еще одна характеристика, которую мы не рассматривали, поскольку она
  выходит за рамки данной книги. Эта характеристика связана с привиллегиями доступа к объектам
  базы данных и по умолчанию имеет значение security invoker: функция будет исполняться
  с привиллегиями пользователя, который ее вызвал. Такое значение не препятствует
  встраиванию кода функции в запрос. Однако если его изменить на security definer(тот
  пользователь который создал данную функцию), встраивание станет невозмоожным.

 */
explain(analyze, costs off)
select count(*)
from tickets
where get_lastname(passenger_name) = 'NOVIKOV';

/*C регулярным выражением
  Выражение (expression) в SQL - это комбинация одного или
  нескольких значений, операторов и функций,
  которая вычисляется и возвращает значение.
"Одно выражение" = один вычисляемый результат, который может состоять из:
Одного значения
Одной функции (с параметрами)
Комбинации значений и операторов
Условного оператора CASE
Но в итоге это должно вычисляться в ОДНО значение для каждой строки

Выражение - это синтаксическая конструкция языка программирования или запросов, которая:
Вычисляется (evaluated)
Возвращает значение (returns a value)
Не изменяет состояние системы (не имеет побочных эффектов)
Математическая аналогия:
2 + 3 ← выражение (результат: 5)
x * y ← выражение (если x=4, y=5, результат: 20)
sin(π/2) ← выражение (результат: 1)

В SQL:
1. Простые (литералы и идентификаторы):
42                    -- числовой литерал
'Иван'               -- строковый литерал
TRUE                 -- булевый литерал
passenger_name       -- идентификатор столбца

2.составные комбинации:
price * quantity                     -- арифметическое
name || ' ' || surname              -- строковое
age >= 18 AND status = 'active'     -- логическое
COUNT(*)                            -- агрегатное
COALESCE(value, 0)                  -- функциональное

3.Условные:
CASE WHEN score > 90 THEN 'A' ELSE 'B' END
*/
explain(analyze, costs off)
select count(*)
from tickets
where get_lastname_1(passenger_name) = 'NOVIKOV';


alter function get_lastname security definer;


/*Aggregate (actual time=753.810..753.810 rows=1 loops=1)
  ->  Seq Scan on tickets (actual time=0.458..753.270 rows=2278 loops=1)
        Filter: (get_lastname(passenger_name) = 'NOVIKOV'::text)
        Rows Removed by Filter: 364455
Planning Time: 0.205 ms
Execution Time: 753.893 ms

Подстановка кода не выполнилась и времени для ее выполнения запроса
  потребовалось значительно больше
*/
explain(analyze, costs off)
select count(*)
from tickets
where get_lastname(passenger_name) = 'NOVIKOV';

/*Возвращаем обратно значение security INVOKER*/

ALTER FUNCTION get_lastname SECURITY INVOKER;

/*Aggregate (actual time=79.142..79.142 rows=1 loops=1)
  ->  Seq Scan on tickets (actual time=0.071..78.968 rows=2278 loops=1)
        Filter: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Rows Removed by Filter: 364455
Planning Time: 0.310 ms
Execution Time: 79.191 ms
*/
explain(analyze, costs off)
select count(*)
from tickets
where get_lastname(passenger_name) = 'NOVIKOV';

/*А если мы создадим индекс по passenger_name, будет ли он использоваться
  при выполнении запроса? Ведь в коде функции этот столбец используется
  только в качестве параметра функций substr и strpos*/

CREATE INDEX ON tickets ( passenger_name );


ANALYZE tickets;

/*Как посмотреть размеры индексов, размеры таблиц!!!*/
SELECT nspname || '.' || relname                                               AS "table",
       PG_SIZE_PRETTY(PG_TOTAL_RELATION_SIZE(c.oid))                           AS "total_size",
       PG_SIZE_PRETTY(PG_RELATION_SIZE(c.oid))                                 AS "data_size",
       PG_SIZE_PRETTY(PG_TOTAL_RELATION_SIZE(c.oid) - PG_RELATION_SIZE(c.oid)) AS "index_size",
       reltuples::bigint                                                       AS "rows"
FROM pg_class c
         LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname NOT IN ( 'pg_catalog', 'information_schema' )
  AND c.relkind = 'r'
ORDER BY PG_TOTAL_RELATION_SIZE(c.oid) DESC;

/*Проверяем после того как сделан индекс
  Aggregate (actual time=65.329..65.330 rows=1 loops=1)
  ->  Index Only Scan using tickets_passenger_name_idx on tickets (actual time=0.136..65.235 rows=2278 loops=1)
        Filter: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Rows Removed by Filter: 364455
        Heap Fetches: 17
Planning Time: 0.736 ms
Execution Time: 65.375 ms
  */
EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';

/*Все индексы в PostgreSQL являются вторичными, что значит, что каждый индекс хранится
  вне области основных данных таблицы (которая в терминологии PostgreSQL называется кучей
  таблицы). Это значит, что при обычном сканировании индекса для извлечения каждой строки
  необходимо прочитать данные и из индекса, и из кучи. Более того, тогда как элементы индекса,
  соответствующие заданному условию WHERE, обычно находятся в индексе рядом, строки таблицы
  могут располагаться в куче произвольным образом. Таким образом, обращение к куче при поиске
  по индексу влечёт множество операций произвольного чтения кучи, которые могут обойтись
  недёшево, особенно на традиционных вращающихся носителях. (Как описано в Разделе 11.5,
  сканирование по битовой карте пытается снизить стоимость этих операций, упорядочивая
  доступ к куче, но не более того.


  Чтобы решить эту проблему с производительностью, PostgreSQL поддерживает сканирование
  только индекса, при котором результат запроса может быть получен из самого индекса,
  без обращения к куче. Основная идея такого сканирования в том, чтобы выдавать значения
  непосредственно из элемента индекса, и не обращаться к соответствующей записи в куче.
  Для применения этого метода есть два фундаментальных ограничения:

Тип индекса должен поддерживать сканирование только индекса. Индексы-B-деревья
  поддерживают его всегда. Индексы GiST и SP-GiST могут поддерживать его с одними
  классами операторов и не поддерживать с другими. Другие индексы такое сканирование
  не поддерживают. Суть нижележащего требования в том, что индекс должен физически
  хранить или каким-то образом восстанавливать исходное значение данных для каждого
  элемента индекса. В качестве контрпримера, индексы GIN неспособны поддерживать
  сканирование только индекса, так как в элементах индекса обычно хранится только
  часть исходного значения данных.

Запрос должен обращаться только к столбцам, сохранённым в индексе. Например, если
в таблице построен индекс по столбцам x и y, и в ней есть также столбец z, такие
запросы будут использовать сканирование только индекса:

SELECT x, y FROM tab WHERE x = 'key';
SELECT x FROM tab WHERE x = 'key' AND y < 42;

А эти запросы не будут:
SELECT x, z FROM tab WHERE x = 'key';
SELECT x FROM tab WHERE x = 'key' AND z < 42;

https://postgrespro.ru/docs/postgresql/current/indexes-index-only-scans
*/

CREATE INDEX idx_tickets_lastname ON tickets
    USING btree ( SUBSTR(passenger_name, STRPOS(passenger_name, ' ') + 1) );

ANALYZE tickets;

/*Aggregate (actual time=2.375..2.376 rows=1 loops=1)
  ->  Bitmap Heap Scan on tickets (actual time=0.621..2.283 rows=2278 loops=1)
        Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Heap Blocks: exact=1897
        ->  Bitmap Index Scan on idx_tickets_lastname (actual time=0.424..0.424 rows=2278 loops=1)
              Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.388 ms
Execution Time: 2.414 ms
*/

ANALYZE tickets;
VACUUM FULL tickets;
---REINDEX TABLE tickets;
-- Перестроить конкретный индекс
REINDEX INDEX idx_tickets_lastname;
-- Перестроить все индексы таблицы
REINDEX TABLE tickets;
-- Перестроить все индексы в схеме
REINDEX SCHEMA public;
-- Перестроить все индексы в БД (требует прав суперпользователя)
REINDEX DATABASE demo_one;

---Где хранится config postgresql.conf
SHOW config_file;


EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';

/*Создайте перегруженную функцию, имеющие два параметра и другое возвращаемое значение*/

CREATE OR REPLACE FUNCTION get_lastname( fullname text, lastname text )
    RETURNS bool AS
$$
SELECT SUBSTR(fullname, STRPOS(fullname, ' ') + 1) = lastname;
$$ LANGUAGE sql IMMUTABLE;

/*
Aggregate (actual time=1.797..1.798 rows=1 loops=1)
  ->  Bitmap Heap Scan on tickets (actual time=0.343..1.731 rows=2278 loops=1)
        Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Heap Blocks: exact=1897
        ->  Bitmap Index Scan on idx_tickets_lastname (actual time=0.176..0.177 rows=2278 loops=1)
              Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.118 ms
Execution Time: 1.826 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name, 'NOVIKOV');


/*Пользовательские функции в индексных выражениях

Индекс можно создать не только по столбцу нижележащей таблицы, но и по функции или
скалярному выражению с одним или несколькими столбцами таблицы. Это позволяет
быстро находить данные в таблице по результатам вычислений.

Например, для сравнений без учёта регистра символов часто используется функция lower:
SELECT * FROM test1 WHERE lower(col1) = 'value';
Этот запрос сможет использовать индекс, определённый для результата функции lower(col1) так:

CREATE INDEX test1_lower_col1_idx ON test1 (lower(col1));
Если мы объявим этот индекс уникальным (UNIQUE), он не даст добавить строки,
в которых значения col1 различаются только регистром, как и те, в которых значения
col1 действительно одинаковые.
Таким образом, индексы по выражениям можно использовать
ещё и для обеспечения ограничений, которые нельзя записать
как простые ограничения уникальности.

https://postgrespro.ru/docs/postgresql/current/indexes-expressional

*/

CREATE INDEX ON tickets ( get_lastname(passenger_name) );
CREATE INDEX IF NOT EXISTS ticket_passenger_name_idx ON tickets ( passenger_name );
ANALYZE tickets;
---VACUUM FULL tickets;


EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';


/*Если искомой фамилии нет, то подходящий индекс позволяет вовсе избежать обращений
  к таблице (в плане теперь нет строки с меткой Heap Blocks)
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name) = 'KRESOV';

/*В дополнении к двум предыдущим индексам создадим еще один индекс
  по выражению, которое фигурирует в коде функции get_lastname*/

CREATE INDEX ON tickets(SUBSTR(passenger_name, STRPOS(passenger_name, ' ') + 1));
ANALYZE tickets;

/*Провести эксперименты с разными условиями в выражении Select
  с функцией get_lastname*/


/*Aggregate (actual time=1.893..1.894 rows=1 loops=1)
  ->  Bitmap Heap Scan on tickets (actual time=0.381..1.825 rows=2278 loops=1)
        Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Heap Blocks: exact=1897
        ->  Bitmap Index Scan on tickets_substr_idx (actual time=0.211..0.211 rows=2278 loops=1)
              Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.139 ms
Execution Time: 1.921 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';


/*Aggregate (actual time=1.720..1.720 rows=1 loops=1)
  ->  Bitmap Heap Scan on tickets (actual time=0.315..1.658 rows=2278 loops=1)
        Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
        Heap Blocks: exact=1897
        ->  Bitmap Index Scan on tickets_substr_idx (actual time=0.167..0.167 rows=2278 loops=1)
              Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.116 ms
Execution Time: 1.743 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT COUNT(*)
FROM tickets
WHERE SUBSTR(passenger_name, STRPOS(passenger_name, ' ') + 1) = 'NOVIKOV';


/*Bitmap Heap Scan on tickets (actual time=0.314..1.690 rows=2278 loops=1)
  Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
  Heap Blocks: exact=1897
  ->  Bitmap Index Scan on tickets_substr_idx (actual time=0.168..0.168 rows=2278 loops=1)
        Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.133 ms
Execution Time: 1.747 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT passenger_name
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';

/*Bitmap Heap Scan on tickets (actual time=0.796..3.246 rows=2278 loops=1)
  Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
  Heap Blocks: exact=1897
  ->  Bitmap Index Scan on tickets_substr_idx (actual time=0.408..0.408 rows=2278 loops=1)
        Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.246 ms
Execution Time: 3.357 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT get_lastname(passenger_name)
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';

/*Bitmap Heap Scan on tickets (actual time=0.330..1.714 rows=2278 loops=1)
  Recheck Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
  Heap Blocks: exact=1897
  ->  Bitmap Index Scan on tickets_substr_idx (actual time=0.173..0.173 rows=2278 loops=1)
        Index Cond: (substr(passenger_name, (strpos(passenger_name, ' '::text) + 1)) = 'NOVIKOV'::text)
Planning Time: 0.124 ms
Execution Time: 1.775 ms
*/
EXPLAIN(ANALYZE, COSTS OFF)
SELECT ticket_no
FROM tickets
WHERE get_lastname(passenger_name) = 'NOVIKOV';


/*Иллюстрация использования системного каталога pg_depend
  Функции и зависимости между объектами базы данных*/

select
    oid,
    proname,
    proargtypes,
    proargtypes::regtype[],
    oid::regprocedure
from pg_proc
where proname = 'get_lastname'

/*Создадим индекс на таблице Билеты tickets по дной из этих функций*/

create index tickets_func_idx on tickets(get_lastname(passenger_name));

/*Зная имя индекса, выберем из системного каталога pg_depend все строки, описывающие
  зависимости этого индекса от других объектов базы данных

  В столбце attname выьорки показано имя столбца таблицы tickets, от которого
  зависит наш индекс. Обратите внимание, что хотя индекс был создан
  на основе функции, здесь указывается столбец, который передавался ей в качестве
  аргумента в команде создания индекса. Номер этого столбца хранится в столбце
  refobjsubid а для вывода его имени мы воспользовались подзапросом к системному
  каталогу pg_attribute. Он представлен в разделе документации 51.7., 51.26
  https://postgrespro.ru/docs/postgresql/17/catalogs */

select
pd.classid::regclass as classname,
pd.objid::regclass as objname,
pd.refclassid::regclass as refclassname,
pd.refobjid::regproc as refobjname,
(select pa.attname
from pg_attribute pa
where pa.attrelid = pd.refobjid
and pa.attnum = pd.refobjsubid),
case pd.deptype
when 'n' then 'normal'
when 'a' then 'auto'
else 'other'
end as deptype
from pg_depend pd
where pd.objid::regclass::text = 'tickets_func_idx'
and refclassid::regclass::text = 'pg_proc';

/*Функция выводит описание объекта базы данных*/
SELECT
    n.nspname as schema,
    c.relname as name,
    CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'i' THEN 'index'
        WHEN 'S' THEN 'sequence'
        WHEN 'v' THEN 'view'
        WHEN 'm' THEN 'materialized view'
        WHEN 'c' THEN 'composite type'
        WHEN 't' THEN 'TOAST table'
        WHEN 'f' THEN 'foreign table'
        WHEN 'p' THEN 'partitioned table'
        WHEN 'I' THEN 'partitioned index'
        END as type,
        obj_description(c.oid) as description
FROM pg_class c
         LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname = 'tickets_func_idx';

/*Подстановка кода функций в запрос: детальные эксперименты
  Создадим расширенную версию функции count_passengers, подсчитывающую
  пассажиров, перевезенных по каждому маршруту за весь период
  времени, представленный в базе данных.

SETOF - "множество", "набор" (много строк)
RECORD - "запись" (одна строка с неопределенными колонками)
SETOF RECORD - "набор строк произвольной структуры"*/

CREATE OR REPLACE FUNCTION count_passengers_2(
    OUT sched_dep date,
    OUT f_no      char,
    OUT pass_num  bigint
) RETURNS setof record AS
$$
SELECT scheduled_departure::date,
       flight_no,
       COUNT(*)
FROM flights AS f
         JOIN boarding_passes AS bp ON bp.flight_id = f.flight_id
WHERE status IN ( 'Departed', 'Arrived' )
GROUP BY scheduled_departure::date, flight_no;
$$ LANGUAGE sql STABLE;


EXPLAIN ANALYZE
SELECT sched_dep, f_no, pass_num
FROM count_passengers_2()
WHERE f_no IN ( 'PG0149', 'PG0148' )
  AND sched_dep > '2017-08-05'::date
  AND sched_dep < '2017-08-10'::date
ORDER BY sched_dep, f_no;


EXPLAIN ANALYZE
SELECT sched_dep, f_no, pass_num
FROM count_passengers_2() as cp
WHERE EXISTS (
SELECT 1
WHERE ROW(cp.f_no, cp.sched_dep) IN (
                                      ROW('PG0149', '2017-08-07'),
                                      ROW('PG0148', '2017-08-08')
)
)
ORDER BY sched_dep, f_no;

EXPLAIN ANALYZE
SELECT sched_dep, f_no, pass_num
FROM count_passengers_2() as cp
WHERE EXISTS (
    SELECT 1
    WHERE ROW(cp.f_no) IN (
                                          ROW('PG0149'),
                                          ROW('PG0148')
        )
)
  AND sched_dep > '2017-08-05'::date
  AND sched_dep < '2017-08-10'::date
ORDER BY sched_dep, f_no;


EXPLAIN ANALYZE
SELECT sched_dep, f_no, pass_num
FROM count_passengers_2() as cp
WHERE cp.f_no = ANY(ARRAY['PG0149', 'PG0148'])
  AND cp.sched_dep = ANY(
    ARRAY(
            SELECT generate_series(
                           '2017-08-06'::date,
                           '2017-08-09'::date,
                           '1 day'::interval
                   )
    )
    )
ORDER BY sched_dep, f_no;


/*Как отобрать из Парето - оптимального множества единственную альтернативу?

  Из теории принятия решений известно, что формирование множества Парето,
  рассмотрение в тексте главы, является лишь первым этапом выбора из множества альтернатив.
  Для определения единственной оптимальной альтернативы из оставшихся используются
  различные способы:
  1.Указание нижних(верхних) границ критериев. Для позитивных критериев задаются нижние границы,
  а для негативных - верхние. Все Парето-оптимальные альтернативы подвергаются проверке
  на соответствие этим границам. Чем более жесткими будут границы, тем меньшее число альтернатив
  будет им удовлетворять!!!
  Стремятся отобрать единственную альтернативу.
  2.Субоптимизация. Выделяется один из критериев в качестве главного, а по всем остальным назначают
  нижние(верхние) границы. Оптимальной считается альтернатива, имеющая максимальное (для негативного
  критерия - минимальное) значение выделенного критерия среди всех альтернатив, удовлетворяющих
  назначенным границам.
  Фактически задача многокритериальной оптимизации превращается в задачу скалярной оптимизации
  на суженном допустимом множестве.
  3.Лексикографическая оптимизация. Критерии упорядочиваются по их относительной важности.
  На первом шаге отбираются альтернативы, имеющую максимальную оценку по важнейшему критерию.
  Если такая альтернатива всего одна, то ее и считают оптимальной, если же их несколько,
  то из них отбираются те, которые имеют максимальную оценку по следующему важности критерию.
  Оставшаяся альтернатива будет оптимальной. При этом подходе слишком преувеличивается роль
  первого по важности критерия: если по нему отбирается всего одна альтернатива, то остальные
  критерии вообще не учитываются.

  Конечно, окончательное решение при использовании этих методов имеет субъективный характер,
  так как относительную важность критериев и значения границ задает лицо, принимающее решение.

Метод границ - самый демократичный, но требует точного знания "приемлемых" значений
Субоптимизация - практичный, когда есть явный KPI
Лексикографический - самый субъективный, может игнорировать важные аспекты

  */

CREATE TABLE projects_pareto (
                          project_id SERIAL PRIMARY KEY,
                          project_name VARCHAR(100),
                          cost NUMERIC(15,2),          -- негативный критерий (меньше = лучше)
                          profit NUMERIC(15,2),        -- позитивный критерий (больше = лучше)
                          risk_level INTEGER,          -- негативный критерий (1-10, меньше = лучше)
                          duration_days INTEGER,       -- негативный критерий
                          quality_score INTEGER,       -- позитивный критерий (1-100)
                          success_probability DECIMAL(3,2) -- позитивный критерий (0-1)
);

INSERT INTO projects_pareto (project_name, cost, profit, risk_level, duration_days, quality_score, success_probability)
VALUES ('Project Alpha', 100000, 50000, 8, 180, 85, 0.7),
       ('Project Beta', 150000, 75000, 6, 150, 90, 0.8),
       ('Project Gamma', 80000, 40000, 9, 200, 80, 0.6),
       ('Project Delta', 120000, 60000, 7, 120, 88, 0.75),
       ('Project Epsilon', 90000, 35000, 5, 100, 92, 0.9),
-- Случай 1: Одинаковая прибыль, разный риск
       ('Project Alpha', 100000, 50000, 8, 180, 85, 0.7),  -- Высокий риск
       ('Project Beta', 150000, 50000, 6, 150, 90, 0.8),   -- Средний риск
       ('Project Gamma', 120000, 50000, 4, 120, 88, 0.75), -- Низкий риск

-- Случай 2: Разная прибыль, одинаковый риск
       ('Project Delta', 80000, 40000, 7, 200, 80, 0.6),   -- Низкая прибыль
       ('Project Epsilon', 90000, 75000, 7, 100, 92, 0.9), -- Высокая прибыль
       ('Project Zeta', 110000, 60000, 7, 150, 85, 0.8),   -- Средняя прибыль

-- Случай 3: Уникальная максимальная прибыль
       ('Project Eta', 130000, 80000, 9, 220, 75, 0.5),    -- Максимальная прибыль, но высокий риск

-- Случай 4: Более сбалансированные варианты
       ('Project Theta', 95000, 55000, 5, 110, 89, 0.85),
       ('Project Iota', 105000, 52000, 6, 130, 87, 0.78),

-- Случай 5: Одинаковые по первым двум критериям
       ('Project Kappa', 115000, 58000, 5, 140, 91, 0.82),
       ('Project Lambda', 115000, 58000, 5, 135, 88, 0.84);


-- Удалим дубликаты имён для чистоты
DELETE FROM projects_pareto
WHERE project_id IN (
    SELECT project_id
    FROM (
             SELECT project_id,
                    ROW_NUMBER() OVER (PARTITION BY project_name, cost, profit, risk_level
                        ORDER BY project_id) as rn
             FROM projects_pareto
         ) t
    WHERE rn > 1
);

---1. Метод нижних/верхних границ
/*
Особенности:
Все критерии равноправны
Жесткость определяется значениями границ
Может отсечь все альтернативы, если границы слишком строгие
Пример субъективности: руководитель решает, что cost <= 120000
*/

-- Задаем границы для каждого критерия
WITH pareto_set AS (
    -- Сначала находим Парето-оптимальные проекты
    SELECT p1.*
    FROM projects_pareto p1
    WHERE NOT EXISTS (
        SELECT 1
        FROM projects_pareto p2
        WHERE p2.cost <= p1.cost
          AND p2.profit >= p1.profit
          AND p2.risk_level <= p1.risk_level
          AND (p2.cost < p1.cost OR p2.profit > p1.profit OR p2.risk_level < p1.risk_level)
    )
)
SELECT *
FROM pareto_set
WHERE cost <= 120000            -- Верхняя граница для негативного критерия (стоимость)
  AND profit >= 40000           -- Нижняя граница для позитивного критерия (прибыль)
  AND risk_level <= 7           -- Верхняя граница для негативного критерия (риск)
  AND duration_days <= 150      -- Верхняя граница для негативного критерия
  AND quality_score >= 85       -- Нижняя граница для позитивного критерия
  AND success_probability >= 0.7; -- Нижняя граница для позитивного критерия

----2. Субоптимизация (главный критерий)

-- Главный критерий: максимизировать profit
-- Вспомогательные критерии: ограничения
WITH filtered_projects AS (
    SELECT *
    FROM projects_pareto
    WHERE cost <= 100000          -- Ограничение 1: стоимость не более 100к
      AND risk_level <= 20         -- Ограничение 2: риск не более 7

)
SELECT *
FROM filtered_projects
WHERE profit = (SELECT MAX(profit) FROM filtered_projects);


---3. Лексикографическая оптимизация
-- Шаг 1: Максимизируем самый важный критерий (profit)
WITH step1 AS (
    SELECT *
    FROM projects_pareto
    WHERE profit = (SELECT MAX(profit) FROM projects_pareto)
),
-- Шаг 2: Среди оставшихся максимизируем следующий критерий (success_probability)
     step2 AS (
         SELECT *
         FROM step1
         WHERE success_probability = (
             SELECT MAX(success_probability)
             FROM step1
         )
     ),
-- Шаг 3: Среди оставшихся минимизируем cost
     step3 AS (
         SELECT *
         FROM step2
         WHERE cost = (
             SELECT MIN(cost)
             FROM step2
         )
     )
-- Шаг 4: Если осталось несколько, минимизируем risk_level
SELECT *
FROM step3
WHERE risk_level = (
    SELECT MIN(risk_level)
    FROM step3
);


-- Самый элегантный вариант, соответствующий теоретическому описанию
WITH ranked AS (SELECT *,
                       -- Приоритет 1: profit (максимизировать)
                       DENSE_RANK() OVER (ORDER BY profit DESC) AS r1,
                       -- Приоритет 2: risk (минимизировать) - считается только если r1=1
                       DENSE_RANK() OVER (PARTITION BY
                           CASE WHEN profit = (SELECT MAX(profit) FROM projects_pareto) THEN 1 ELSE 0 END
                           ORDER BY risk_level ASC)             AS r2,
                       -- Приоритет 3: cost (минимизировать) - считается только если r1=1 и r2=1
                       DENSE_RANK() OVER (PARTITION BY
                           CASE
                               WHEN profit = (SELECT MAX(profit) FROM projects_pareto)
                                   AND risk_level = (SELECT MIN(risk_level)
                                                     FROM projects_pareto
                                                     WHERE profit = (SELECT MAX(profit) FROM projects_pareto))
                                   THEN 1
                               ELSE 0 END
                           ORDER BY cost ASC)                   AS r3
                FROM projects_pareto)
SELECT project_id,
       project_name,
       cost,
       profit,
       risk_level,
       duration_days,
       quality_score,
       success_probability,
       CASE
           WHEN r1 = 1 AND (SELECT COUNT(*) FROM ranked WHERE r1 = 1) = 1 THEN 1
           WHEN r1 = 1 AND r2 = 1 AND (SELECT COUNT(*) FROM ranked WHERE r1 = 1 AND r2 = 1) = 1 THEN 2
           WHEN r1 = 1 AND r2 = 1 AND r3 = 1 THEN 3
           ELSE 0
           END AS steps_used
FROM ranked
WHERE r1 = 1
  AND (r2 = 1 OR (SELECT COUNT(*) FROM ranked WHERE r1 = 1) = 1)
  AND (r3 = 1 OR (SELECT COUNT(*) FROM ranked WHERE r1 = 1 AND r2 = 1) = 1)
ORDER BY project_id;


/*Результат попарного сравнения альтернатив в другой форме*/

select m1.meal_code               as alt1,
       m2.meal_code               as al2,
       m1.price                   as price1,
       m2.price                   as price2,
       m1.calories                as calories1,
       m2.calories                as calories2,
       m1.variety                 as variety1,
       m2.variety                 as variety2,
       compare_pairwise_2(m1, m2) as score
from meal as m1,
     meal as m2
where m1.meal_code = 'D'
order by m2.meal_code, score;


-- Проверка, какая альтернатива лучше
SELECT
    m1.meal_code               as alt1,
    m2.meal_code               as al2,
    m1.price                   as price1,
    m2.price                   as price2,
    m1.calories                as calories1,
    m2.calories                as calories2,
    m1.variety                 as variety1,
    m2.variety                 as variety2,
    compare_pairwise_2(m1, m2) as comparison_result,
    CASE compare_pairwise_2(m1, m2)
        WHEN 0 THEN 'Равны'
        WHEN 1 THEN 'meal1 лучше'
        WHEN 2 THEN 'meal2 лучше'
        WHEN 3 THEN 'Нет доминирования (Парето)'
        ELSE 'Ошибка'
        END as interpretation
FROM meal m1, meal m2
WHERE m1.meal_code <> m2.meal_code;


/*Составные значения в качестве аргументов функций*/
/*Составные значения в качестве аргументов функций
  Ранее была представлена функция compare_pairwise для попарного сравнения альтернатив, ее параметрами
  являются составные значения типа meal.
  Проведем эксперимент, в котором функция будет получать один из аргументов как результаты выполнения
  подзапроса. В качестве базовой альтернативы возьмем альтернативу D.

  */


select
    m.*,
    cp.score
from meal as m
         cross join lateral
    compare_pairwise(
            (select meal from meal where meal_code='D'),
            m
    ) as cp(score)
where m.meal_code <> 'D'
order by m.meal_code;

/*
select
    m.*
from meal m
*/

/*ROWS - характеристика количества строк, возвращаемых функцией
  Планировщик строит план выполнения запроса, исходя из предположений о количестве строк,
  отбираемых на каждом узле плана!!! Если оченки будут неточными, то и план получится
  неоптимальным. Функции, возвращающие множество строк, усложняют планирование.
  Функция код которой не строен в запрос - черный ящик для планировщика, но он обязан как-то
  оценить число строк, возвращаемых ею.
  По уомлчанию он считает это число 1000.
  К сожалению, не всегда этот выбор оказывается наилучшим. Но у программиста есть возможность
  помочь планировщику, задавая функции характеристику ROWS*/

CREATE OR REPLACE FUNCTION generate_flight_ids( ids_count integer )
    RETURNS table
            (
                id integer
            )
AS
$$
SELECT random(1, (SELECT max(flight_id) FROM flights))
FROM generate_series(1, ids_count);
$$ LANGUAGE sql;

select *
from generate_flight_ids(1000);

---Давайте сформируем 100 идентификаторов рейсов;


explain ANALYZE
SELECT
    f.flight_id,
    f.flight_no,
    f.scheduled_departure as dep,
    f.departure_airport as da,
    f.arrival_airport as aa
from flights as f
         join generate_flight_ids(100) as gfi on f.flight_id = gfi.id
order by dep;

alter function generate_flight_ids rows 100;
---выполнение функции ускорилось на порядок

/*Увидеть значение характеристики rows можно в системном каталоге pg_proc
 */

select proname, prorows, procost
from pg_proc
where proname = 'generate_flight_ids';

/*Характеристика стоимости вычисления функции
  Существует еще одна характеристика, которую можно задать в функции и настроить таким образом план запроса - cost.
  Эта характеристика задает примерную стоимость выполнения функции в единицах cpu_operator_cost.
  Точнее говоря первая оценка cost в узле, в котором вызывается функция, равна произведению значения cost на значение
  параметра планировщика cpu_operator_cost, которое по умолчанию равно 0.0025. Значение cost для функций написанных
  не на языке С, по умолчанию составляет 100 */

-- Для быстрых функций (генерация серий, простые вычисления)
COST 1    -- Очень дешево
ROWS 100  -- Примерное количество строк

-- Для функций средней сложности (запросы к малым таблицам)
COST 10
ROWS 1000

-- Для "дорогих" функций (сложные вычисления, запросы к большим таблицам)
COST 100
ROWS 10000

-- Для очень дорогих функций (агрегации, рекурсии)
COST 1000
ROWS 100000

ALTER FUNCTION generate_flight_ids COST 10;

/*Если количество строк, возвращаемых функцией, более ли менее стабильно и заранее известно, можно попытаться
  ускорить выполнение запроса, изменяя эту характеристику. Конечно если количество строк при многократных вызовах количества
  может отличаться, скажем, на порядок, то трудно выбрать обоснованное значение характеристики COST*/
explain ANALYZE
SELECT
    f.flight_id,
    f.flight_no,
    f.scheduled_departure as dep,
    f.departure_airport as da,
    f.arrival_airport as aa
from flights as f
         join generate_flight_ids(100) as gfi on f.flight_id = gfi.id
order by dep;

/*Вычисляемые столбцы, сохраняемые в таблице
  В тексте главы было рассмотрено множество примеров использования функций в запросах. Однако этим применение
  не исчерпывается. С помощью постоянных immutable функций можно определить вычисляемый (генерируемый) столбец
  при создании или модификации таблиц. Подробно о вычисляемых столбцах можно прочитать в
  описании и команды create table, приведенном в документации
  Давайте сделаем копию таблицы Билеты tickets. Во временной таблице не будем создавать первичный и внешний ключи,
  поскольку это не влияет на наши эксперименты*/

CREATE TEMP TABLE tickets_2 AS
SELECT *
FROM tickets;

/*Предположим что при эксплуатации базы данных часто выполняются запросы, в которых имя и фамилия выводятся в виде
  отдельных значений. Если бы эти значения хранились в отдельных столбцах, такие запросы выполнялись бы значительно
  быстрее.
  Время, затраченное на заполнение этих столбцов при вводе данных, многократно компенсировалось бы при выборках
  большого числа строк.
  Давайте напишем две функции, которые будут извлекать эти элементы данных из единого значения
  Эти функции будут автоматически вызываться как при создании вычисляемых столбцов, так и при добавлении и обновлении
  табличных строк.*/