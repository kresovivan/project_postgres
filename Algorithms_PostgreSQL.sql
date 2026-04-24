-- =============================================================================
-- ИДЕАЛЬНАЯ БАЗА ДЛЯ ДЕМОНСТРАЦИИ АЛГОРИТМОВ POSTGRESQL (v5.0 — FINAL)
-- Все примеры гарантированно показывают нужный алгоритм
-- =============================================================================

-- 0. СТАНДАРТНЫЕ НАСТРОЙКИ (без RESET ALL!)
SET enable_indexscan = on;
SET enable_bitmapscan = on;
SET enable_seqscan = on;
SET enable_hashjoin = on;
SET enable_mergejoin = on;
SET enable_nestloop = on;
SET cpu_tuple_cost = 0.01;
SET cpu_index_tuple_cost = 0.005;
SET cpu_operator_cost = 0.0025;
SET random_page_cost = 4.0;
SET seq_page_cost = 1.0;
SET work_mem = '4MB';
SET effective_cache_size = '4GB';

-- 1. Очистка
DROP TABLE IF EXISTS orders, customers, products, orders_scattered CASCADE;

-- 2. Таблицы
CREATE TABLE products
(
    product_id INT PRIMARY KEY,
    name       VARCHAR(100),
    category   VARCHAR(50),
    price      NUMERIC
);

CREATE TABLE customers
(
    customer_id SERIAL PRIMARY KEY,
    email       VARCHAR(100),
    city        VARCHAR(50),
    signup_date DATE
);

CREATE TABLE orders
(
    order_id    SERIAL PRIMARY KEY,
    customer_id INT,
    product_id  INT,
    order_date  DATE,
    amount      INT,
    status      VARCHAR(20)
);

-- 3. Товары (100 строк)
INSERT INTO products (product_id, name, category, price)
SELECT id,
       'Product_' || id,
       CASE WHEN random() < 0.3 THEN 'Electronics' ELSE 'Clothes' END,
       (random() * 1000)::NUMERIC(10, 2)
FROM generate_series(1, 100) AS id;

-- 4. Клиенты
INSERT INTO customers (email, city, signup_date)
SELECT 'moscow_' || g || '@mail.com', 'Moscow', DATE '2020-01-01' + (random() * 1500)::INT
FROM generate_series(1, 5000) AS g;

INSERT INTO customers (email, city, signup_date)
SELECT 'spb_' || g || '@mail.com', 'SPB', DATE '2020-01-01' + (random() * 1500)::INT
FROM generate_series(1, 5000) AS g;

INSERT INTO customers (email, city, signup_date)
SELECT 'vip_' || g || '@mail.com', 'Sochi', DATE '2023-01-01'
FROM generate_series(1, 50) AS g;

-- 5. Заказы ХРОНОЛОГИЧЕСКИ (1M строк)
INSERT INTO orders (customer_id, product_id, order_date, amount, status)
SELECT (random() * 10049 + 1)::INT,
       (random() * 99 + 1)::INT,
       day,
       (random() * 10 + 1)::INT,
       CASE WHEN random() < 0.7 THEN 'Completed' ELSE 'Returned' END
FROM generate_series('2022-01-01'::date, '2024-12-31'::date, '1 day') AS day
         CROSS JOIN generate_series(1, 913);

-- 6. Перемешанные заказы для Bitmap Scan
CREATE TABLE orders_scattered
(
    LIKE orders INCLUDING ALL
);
INSERT INTO orders_scattered
SELECT *
FROM orders
ORDER BY random();

-- 7. Индексы
CREATE INDEX idx_orders_date ON orders (order_date);
CREATE INDEX idx_orders_cust ON orders (customer_id);
CREATE INDEX idx_cust_city ON customers (city);
CREATE INDEX idx_products_price ON products (price);
CREATE INDEX idx_orders_scattered_date ON orders_scattered (order_date);

-- 8. CLUSTER для Index Scan!
CLUSTER orders USING idx_orders_date;

-- 9. Статистика
ANALYZE products;
ANALYZE customers;
ANALYZE orders;
ANALYZE orders_scattered;

/*
=============================================================================
Глава 1. СКАНИРОВАНИЕ (Access Methods)
=============================================================================
Как PostgreSQL читает данные из таблицы.
Выбор алгоритма зависит от того, сколько строк нужно вернуть.
*/

-- =============================================================================
-- ПРИМЕР 1.1: Seq Scan (Последовательное сканирование)
-- =============================================================================
-- АЛГОРИТМ: Читаем ВСЮ таблицу страница за страницей, от корки до корки.
--           Каждую прочитанную строку проверяем фильтром WHERE.
--           Неподходящие строки отбрасываются (Rows Removed by Filter).
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Нужно > 30-50% всех строк таблицы
--   • Таблица очень маленькая (< 10-50 страниц)
--   • Нет подходящего индекса
--   • Нужны все строки таблицы (SELECT * без WHERE)
--
-- АНАЛОГИЯ: Читать книгу от корки до корки, чтобы найти все упоминания слова "война".
--          Если слово встречается на каждой второй странице — это быстрее,
--          чем смотреть в указатель и прыгать туда-сюда.
--
-- ПЛЮСЫ:  Последовательное чтение — самый быстрый способ чтения с диска.
--          Не требует индексов. Предсказуемый I/O.
-- МИНУСЫ: Читает ВООБЩЕ ВСЁ, даже ненужные строки.
--          На больших таблицах с маленькой выборкой — ОГРОМНЫЕ накладные расходы.

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE status = 'Completed';

/*
Seq Scan on orders  (cost=0.00..19866.10 rows=698732 width=29) (actual time=0.011..67.901 rows=700408 loops=1)
  Filter: ((status)::text = 'Completed'::text)
  Rows Removed by Filter: 300240
  Buffers: shared hit=7358
Planning:
  Buffers: shared hit=29 read=3
Planning Time: 0.197 ms
Execution Time: 82.319 ms

*/

-- =============================================================================
-- ПРИМЕР 1.2: Index Scan (Индексное сканирование)
-- =============================================================================
-- АЛГОРИТМ: Сначала читаем индекс (B-дерево), находим ТОЧНЫЕ адреса (TID) нужных
--           строк. Затем идём в таблицу (heap) и читаем ТОЛЬКО эти строки.
--           Каждая строка читается ОТДЕЛЬНО (рандомный I/O).
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Нужно < 5% строк таблицы (высокая селективность)
--   • Данные ФИЗИЧЕСКИ скучены (CLUSTER) — тогда чтение почти последовательное
--   • Точечный запрос: WHERE id = 123, WHERE date = '2024-06-15'
--   • Index Only Scan: все нужные столбцы ЕСТЬ в индексе (не требует чтения heap)
--
-- АНАЛОГИЯ: Предметный указатель в конце учебника.
--          "Москва — стр. 42, 56, 128". Открываем ТОЛЬКО эти страницы.
--
-- ПЛЮСЫ:  Читаем ТОЛЬКО нужные строки. Для точечных запросов — молниеносно.
-- МИНУСЫ: Если строки РАЗБРОСАНЫ по таблице — получаем random I/O (медленно!).
--          Если данных > 10% — может быть МЕДЛЕННЕЕ Seq Scan.
--
-- ВАЖНО:  Мы сделали CLUSTER orders USING idx_orders_date.
--         Теперь строки за одну дату лежат НА ОДНИХ И ТЕХ ЖЕ страницах.
--         Index Scan превращается в почти последовательное чтение!

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders
WHERE order_date = '2024-06-15';

/*
Index Scan using idx_orders_date on orders  (cost=0.17..16.11 rows=911 width=29) (actual time=0.028..0.115 rows=913 loops=1)
  Index Cond: (order_date = '2024-06-15'::date)
  Buffers: shared hit=11
Planning:
  Buffers: shared hit=138
Planning Time: 0.710 ms
Execution Time: 0.159 ms


*/

-- =============================================================================
-- ПРИМЕР 1.3: Bitmap Scan (Сканирование битовой карты)
-- =============================================================================
-- АЛГОРИТМ: ГИБРИД Index Scan и Seq Scan.
--   Шаг 1: Bitmap Index Scan — сканируем ТОЛЬКО индекс, собираем адреса страниц.
--   Шаг 2: Сортируем адреса страниц по возрастанию.
--   Шаг 3: Bitmap Heap Scan — читаем страницы ПОСЛЕДОВАТЕЛЬНО (как Seq Scan!).
--   Шаг 4: Recheck Cond — перепроверяем условие (на странице могут быть лишние строки).
--
-- КОГДА ПРИМЕНЯЕТСЯ (ЗОЛОТАЯ СЕРЕДИНА):
--   • Нужно 5-30% строк таблицы (средняя селективность)
--   • Данные физически РАЗБРОСАНЫ по таблице (нет CLUSTER)
--   • Несколько индексов можно скомбинировать: BitmapAnd, BitmapOr
--   • Index Scan слишком дорог (много random I/O), Seq Scan — слишком много лишнего
--
-- АНАЛОГИЯ: Фотографируем книжные полки и отмечаем на фото нужные книги.
--          Потом идём и снимаем их ПОДРЯД, а не прыгаем туда-сюда.
--
-- ПЛЮСЫ:  Превращает random I/O в sequential I/O.
--          Можно комбинировать несколько индексов (BitmapAnd / BitmapOr).
-- МИНУСЫ: Требует память под битмап (work_mem).
--          Если данных ОЧЕНЬ много — битмап не влезает в память.
--
-- СРАВНЕНИЕ С INDEX SCAN:
--   Index Scan: 1000 строк на 1000 разных страницах → 1000 random reads
--   Bitmap Scan: 1000 строк на 300 страницах → битмап + 300 sequential reads
--   Bitmap Scan ВЫГОДНЕЕ, если random_page_cost > seq_page_cost (обычно 4.0 > 1.0)

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM orders_scattered
WHERE order_date BETWEEN '2024-06-01' AND '2024-06-30';

/*
Bitmap Heap Scan on orders_scattered  (cost=154.44..7707.03 rows=27798 width=29) (actual time=2.926..212.125 rows=27390 loops=1)
  Recheck Cond: ((order_date >= '2024-06-01'::date) AND (order_date <= '2024-06-30'::date))
  Heap Blocks: exact=7170
  Buffers: shared hit=7170 read=26 dirtied=7170
  ->  Bitmap Index Scan on idx_orders_scattered_date  (cost=0.00..151.66 rows=27798 width=0) (actual time=2.208..2.208 rows=27390 loops=1)
        Index Cond: ((order_date >= '2024-06-01'::date) AND (order_date <= '2024-06-30'::date))
        Buffers: shared read=26
Planning:
  Buffers: shared hit=65 read=1
Planning Time: 8.349 ms
Execution Time: 213.275 ms
*/

/*
=============================================================================
Глава 2. СОЕДИНЕНИЯ (Join Algorithms)
=============================================================================
Как PostgreSQL соединяет строки из двух таблиц по условию.
Порядок таблиц в SQL НЕ ВАЖЕН — планировщик сам выберет оптимальный.
*/

-- =============================================================================
-- ПРИМЕР 2.1: Nested Loop (Вложенные циклы)
-- =============================================================================
-- АЛГОРИТМ: Для КАЖДОЙ строки из внешней таблицы (outer) ищем соответствующие
--           строки во внутренней таблице (inner) через ИНДЕКС.
--
--           Псевдокод:
--           for each outer_row in outer_table:
--               inner_rows = index_search(inner_table, outer_row.key)
--               for each inner_row in inner_rows:
--                   emit(outer_row, inner_row)
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Внешняя таблица ОЧЕНЬ маленькая (< 100-500 строк)
--   • На внутренней таблице есть ИНДЕКС по ключу соединения
--   • Нужны первые N строк (LIMIT) — можно прервать цикл досрочно
--
-- АНАЛОГИЯ: 50 VIP-клиентов. Для каждого идём на склад и ищем ЕГО коробку
--          по штрих-коду (индексу).
--
-- ПЛЮСЫ:  Не требует памяти для хеша. Может работать с ОГРОМНЫМИ таблицами.
--          Хорош для LIMIT (можно остановиться).
-- МИНУСЫ: Каждая итерация — поиск в индексе. 1000×1 = 1000 поисков.
--          Если внешняя таблица большая — ОЧЕНЬ МНОГО итераций.
--
-- ВАЖНО:  Мы ОТКЛЮЧАЕМ Bitmap Scan внутри цикла (enable_bitmapscan=off),
--         чтобы показать ЧИСТЫЙ Nested Loop + Index Scan.

EXPLAIN (ANALYZE, BUFFERS)
SELECT c.email, SUM(o.amount)
FROM customers       c
         JOIN orders o ON c.customer_id = o.customer_id
WHERE c.city = 'Sochi'
GROUP BY c.email;



/*
Ожидаемый план:
HashAggregate  (cost=4248.37..4248.62 rows=50 width=27) (actual time=5.362..5.366 rows=50 loops=1)
  Group Key: c.email
  Batches: 1  Memory Usage: 24kB
  Buffers: shared hit=5067
  ->  Nested Loop  (cost=0.28..4238.41 rows=4978 width=23) (actual time=0.022..4.822 rows=4955 loops=1)
        Buffers: shared hit=5067
        ->  Index Scan using idx_cust_city on customers c  (cost=0.11..3.34 rows=50 width=23) (actual time=0.014..0.020 rows=50 loops=1)
              Index Cond: ((city)::text = 'Sochi'::text)
              Buffers: shared hit=3
        ->  Index Scan using idx_orders_cust on orders o  (cost=0.17..84.20 rows=100 width=8) (actual time=0.002..0.089 rows=99 loops=50)
              Index Cond: (customer_id = c.customer_id)
              Buffers: shared hit=5064
Planning:
  Buffers: shared hit=14
Planning Time: 0.215 ms
Execution Time: 5.400 ms

*/

-- =============================================================================
-- ПРИМЕР 2.2: Hash Join (Хеш-соединение)
-- =============================================================================
-- АЛГОРИТМ: Строим ХЕШ-ТАБЛИЦУ в памяти из МЕНЬШЕЙ таблицы (inner).
--           Затем сканируем БОЛЬШУЮ таблицу (outer) и для каждой строки
--           делаем O(1) lookup в хеш-таблице.
--
--           Псевдокод:
--           hash_table = {}
--           for inner_row in inner_table:
--               hash_table[hash(inner_row.key)] = inner_row
--           for outer_row in outer_table:
--               if hash(outer_row.key) in hash_table:
--                   emit(outer_row, hash_table[hash(outer_row.key)])
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Одна таблица ЗНАЧИТЕЛЬНО меньше другой
--   • Нет подходящего индекса для Nested Loop
--   • Обе таблицы средние/большие
--   • Хеш-таблица ВЛЕЗАЕТ в work_mem (иначе уходит в Batches — медленно!)
--
-- АНАЛОГИЯ: У нас 100 товаров (products). Выписываем их на листочек (хеш).
--          Берём 1 000 000 заказов и для каждого смотрим в листочек.
--
-- ПЛЮСЫ:  ОЧЕНЬ быстрый (O(N+M) в идеале). Не требует индексов.
--          Отлично для средних и больших таблиц.
-- МИНУСЫ: Требует ПАМЯТЬ (work_mem). Если хеш не влезает — сливается на диск.
--          Не может вернуть первую строку, пока хеш не построен.
--
-- ВАЖНО:  Планировщик ВСЕГДА строит хеш из МЕНЬШЕЙ таблицы.
--          Порядок таблиц во FROM НЕ ВАЖЕН!
--          В примере: products (100 строк) → хеш, orders (1M) → сканирование.

EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, p.name, p.category
FROM orders            o
         JOIN products p ON o.product_id = p.product_id;

/*
Hash Join  (cost=2.10..13468.55 rows=1000648 width=23) (actual time=0.057..148.405 rows=1000648 loops=1)
  Hash Cond: (o.product_id = p.product_id)
  Buffers: shared hit=7359
  ->  Seq Scan on orders o  (cost=0.00..12361.24 rows=1000648 width=8) (actual time=0.019..39.237 rows=1000648 loops=1)
        Buffers: shared hit=7358
  ->  Hash  (cost=1.50..1.50 rows=100 width=23) (actual time=0.027..0.029 rows=100 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 14kB
        Buffers: shared hit=1
        ->  Seq Scan on products p  (cost=0.00..1.50 rows=100 width=23) (actual time=0.007..0.013 rows=100 loops=1)
              Buffers: shared hit=1
Planning:
  Buffers: shared hit=54 read=1
Planning Time: 0.661 ms
Execution Time: 169.800 ms

*/

-- =============================================================================
-- ПРИМЕР 2.3: Merge Join (Соединение слиянием)
-- =============================================================================
-- АЛГОРИТМ: Обе таблицы должны быть ОТСОРТИРОВАНЫ по ключу соединения.
--           Идём двумя указателями (как расчёска), сравниваем ключи:
--           - Ключи равны → emit + двигаем оба указателя
--           - Ключ левой меньше → двигаем левый
--           - Ключ правой меньше → двигаем правый
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Обе таблицы УЖЕ отсортированы по ключу (индексы, CLUSTER, ORDER BY)
--   • Таблицы ОГРОМНЫЕ, хеш не влезает в work_mem
--   • Нужен результат в отсортированном порядке (экономия на сортировке)
--
-- АНАЛОГИЯ: Две стопки счетов, отсортированных по номеру.
--          Кладём рядом и идём пальцами — где совпало, скрепка.
--
-- ПЛЮСЫ:  Не требует памяти для хеша.
--          Работает с ОГРОМНЫМИ таблицами (может использовать диск).
--          Результат уже отсортирован.
-- МИНУСЫ: Обе таблицы должны быть отсортированы.
--          Если сортировки нет — дорогая операция Sort.
--
-- ВАЖНО:  Здесь сортировка БЕСПЛАТНАЯ — индексы уже дают порядок.
--          customers_pkey — индекс по customer_id (PK).
--          idx_orders_cust — индекс по customer_id.

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM customers       c
         JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;

/*
Merge Join  (cost=0.28..22757.35 rows=1000648 width=61) (actual time=0.008..674.272 rows=1000648 loops=1)
  Merge Cond: (c.customer_id = o.customer_id)
  Buffers: shared hit=994024 read=858 dirtied=79
  ->  Index Scan using customers_pkey on customers c  (cost=0.11..187.59 rows=10050 width=32) (actual time=0.003..2.311 rows=10050 loops=1)
        Buffers: shared hit=108 dirtied=79
  ->  Index Scan using idx_orders_cust on orders o  (cost=0.17..16555.82 rows=1000648 width=29) (actual time=0.002..569.134 rows=1000648 loops=1)
        Buffers: shared hit=993916 read=858
Planning:
  Buffers: shared hit=23 dirtied=1
Planning Time: 0.222 ms
Execution Time: 696.713 ms
*/

/*
=============================================================================
Глава 3. АГРЕГАЦИЯ И СОРТИРОВКА (GroupBy & OrderBy)
=============================================================================
*/

-- =============================================================================
-- ПРИМЕР 3.1: HashAggregate (Агрегация через хеш-таблицу)
-- =============================================================================
-- АЛГОРИТМ: Строим ХЕШ-ТАБЛИЦУ: ключ = значение GROUP BY, значение = агрегат.
--           Для каждой строки вычисляем hash(group_key), находим бакет,
--           обновляем агрегат (COUNT++, SUM+=value, ...).
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Много уникальных групп (тысячи/миллионы)
--   • Данные НЕ отсортированы по ключу группы
--   • Количество групп влезает в work_mem
--
-- АНАЛОГИЯ: Раскладываем заказы по кучкам: "Completed" в одну, "Returned" в другую.
--          В конце считаем, сколько в каждой кучке.
--
-- ПЛЮСЫ:  Не требует сортировки данных.
--          Хорош для большого числа групп.
-- МИНУСЫ: Требует ПАМЯТЬ (work_mem). Если групп много — уходит в Batches (диск).
--          Не выдаёт результат, пока не обработаны ВСЕ строки.
--
-- ВАЖНО:  Мы отключаем параллелизм (max_parallel_workers_per_gather=0),
--         чтобы показать ЧИСТЫЙ HashAggregate без Gather Merge.

SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT status, COUNT(*)
FROM orders
GROUP BY status;

---SET max_parallel_workers_per_gather = 2;

/*
HashAggregate  (cost=14362.54..14362.55 rows=2 width=17) (actual time=147.605..147.606 rows=2 loops=1)
  Group Key: status
  Batches: 1  Memory Usage: 24kB
  Buffers: shared hit=7358
  ->  Seq Scan on orders  (cost=0.00..12361.24 rows=1000648 width=9) (actual time=0.023..39.811 rows=1000648 loops=1)
        Buffers: shared hit=7358
Planning Time: 0.097 ms
Execution Time: 147.650 ms
*/

-- =============================================================================
-- ПРИМЕР 3.2: GroupAggregate (Стримовая агрегация)
-- =============================================================================
-- АЛГОРИТМ: Данные УЖЕ отсортированы по ключу группы.
--           Идём по строкам подряд, накапливаем агрегат.
--           Как только ключ сменился → выдаём результат для предыдущей группы.
--
--           Псевдокод:
--           current_key = None; agg = 0
--           for row in sorted_data:
--               if row.key != current_key:
--                   if current_key is not None: emit(current_key, agg)
--                   current_key = row.key; agg = 0
--               agg += row.value
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • Данные УЖЕ отсортированы по ключу группы (Index Scan, Merge Join, CLUSTER)
--   • Объединение результатов параллельных воркеров (Gather Merge)
--   • ORDER BY + GROUP BY с одинаковым ключом
--
-- АНАЛОГИЯ: Ежедневник с заказами по дням. Ведём пальцем:
--          "1 июня... 1 июня... 1 июня... О, 2 июня! Записываю итог 1 июня."
--
-- ПЛЮСЫ:  НЕ требует памяти для хеша (почти 0 памяти!).
--          Начинает выдавать результат СРАЗУ (не ждёт конца).
-- МИНУСЫ: Данные ДОЛЖНЫ быть отсортированы.
--
-- ВАЖНО:  Мы сделали CLUSTER + Index Scan → данные идут в порядке дат.
--         GroupAggregate "бесплатно" агрегирует их на лету.

EXPLAIN (ANALYZE, BUFFERS)
SELECT order_date, SUM(amount)
FROM orders
WHERE order_date BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY order_date;

/*
GroupAggregate  (cost=0.17..551.25 rows=1096 width=12) (actual time=0.182..4.883 rows=30 loops=1)
  Group Key: order_date
  Buffers: shared hit=228
  ->  Index Scan using idx_orders_date on orders  (cost=0.17..490.80 rows=27487 width=8) (actual time=0.024..2.452 rows=27390 loops=1)
        Index Cond: ((order_date >= '2024-06-01'::date) AND (order_date <= '2024-06-30'::date))
        Buffers: shared hit=228
Planning Time: 0.118 ms
Execution Time: 4.915 ms
*/

-- =============================================================================
-- ПРИМЕР 3.3: Index Scan Backward (Обратное сканирование индекса)
-- =============================================================================
-- АЛГОРИТМ: B-дерево индекса ДВУНАПРАВЛЕННОЕ.
--           Для ORDER BY ... DESC LIMIT N идём С КОНЦА индекса.
--           Берём первые N строк — и всё! Никакой сортировки!
--
-- КОГДА ПРИМЕНЯЕТСЯ:
--   • ORDER BY col DESC LIMIT N
--   • Есть индекс по col
--   • Индекс покрывает все нужные столбцы (или это Index Only Scan)
--
-- АНАЛОГИЯ: Телефонный справочник. Найти 10 последних по алфавиту?
--          Открываем конец и списываем 10 фамилий. ВСЁ!
--
-- ПЛЮСЫ:  МГНОВЕННО! Даже таблицу не читаем (если нужно только поле из индекса).
--          Не требует памяти для сортировки.
-- МИНУСЫ: Только для ORDER BY по ИНДЕКСИРОВАННОМУ полю.
--
-- СРАВНЕНИЕ С Top-N Heapsort:
--   Index Scan Backward: просто идём по индексу → читаем N строк → ГОТОВО.
--   Top-N Heapsort:      сканируем ВСЮ таблицу → держим кучу из N строк.
--   Index Scan Backward работает в 100-1000 раз быстрее!

EXPLAIN (ANALYZE)
SELECT *
FROM products
ORDER BY price DESC
LIMIT 10;

/*
Ожидаемый план:
Limit
  ->  Index Scan Backward using idx_products_price on products
*/

/*
=============================================================================
СВОДНАЯ ТАБЛИЦА: КАКОЙ АЛГОРИТМ КОГДА ИСПОЛЬЗОВАТЬ
=============================================================================

┌──────────────────────┬─────────────────────┬──────────────────────────────────────────────────────────────────────┐
│ ЗАДАЧА               │ АЛГОРИТМ            │ КОГДА ВЫБРАТЬ (условия, цифры, примеры)                              │
├──────────────────────┼─────────────────────┼──────────────────────────────────────────────────────────────────────┤
│                      │                     │                                                                      │
│ ПОИСК СТРОК          │ Seq Scan            │ ✓ Нужно > 30% всех строк таблицы                                     │
│ (чтение таблицы)     │ (читает всё подряд) │ ✓ Таблица < 10 страниц (маленькая)                                   │
│                      │                     │ ✓ Нет подходящего индекса                                            │
│                      │                     │ ✗ Пример: SELECT * FROM orders WHERE status = 'Completed'            │
│                      │                     │   (вернёт 70% таблицы → Seq Scan оптимален)                          │
│                      │                     │                                                                      │
│                      │ Index Scan          │ ✓ Нужно < 5% таблицы (точечный запрос)                               │
│                      │ (индекс → таблица)  │ ✓ Данные ФИЗИЧЕСКИ скучены (correlation > 0.8 после CLUSTER)         │
│                      │                     │ ✓ WHERE с = (равенство, не диапазон)                                 │
│                      │                     │ ✗ Пример: SELECT * FROM orders WHERE order_date = '2024-06-15'       │
│                      │                     │   (913 строк из 1M = 0.09% → Index Scan)                             │
│                      │                     │                                                                      │
│                      │ Bitmap Scan         │ ✓ Нужно 5-30% таблицы (средняя селективность)                        │
│                      │ (индекс → битмап    │ ✓ Данные РАЗБРОСАНЫ физически (correlation < 0.3, нет CLUSTER)       │
│                      │  страниц → таблица) │ ✓ Комбинация 2+ индексов: BitmapAnd / BitmapOr                       │
│                      │                     │ ✗ Пример: SELECT * FROM orders_scattered                             │
│                      │                     │   WHERE order_date BETWEEN '2024-06-01' AND '2024-06-30'             │
│                      │                     │   (27K строк = 2.7% таблицы, но разбросаны → Bitmap)                 │
│                      │                     │                                                                      │
│                      │ Index Only Scan     │ ✓ Все колонки из SELECT есть в индексе                               │
│                      │ (только индекс,     │ ✓ Таблица не обновлялась после VACUUM (visibility map свежая)        │
│                      │  без чтения heap)   │ ✗ Пример: SELECT order_date FROM orders                              │
│                      │                     │   WHERE order_date = '2024-06-15'                                    │
│                      │                     │   (индекс idx_orders_date содержит order_date → Index Only Scan)     │
├──────────────────────┼─────────────────────┼──────────────────────────────────────────────────────────────────────┤
│                      │                     │                                                                      │
│ СОЕДИНЕНИЕ ТАБЛИЦ    │ Nested Loop         │ ✓ Внешняя таблица < 500 строк                                        │
│ (JOIN)               │ (внешний цикл ×     │ ✓ На внутренней таблице есть ИНДЕКС по ключу JOIN                    │
│                      │  поиск во внутренней│ ✓ Нужны первые N строк (LIMIT) — можно прервать досрочно             │
│                      │  через индекс)      │ ✗ Пример: JOIN customers (50 строк Sochi) ⋈ orders (1M)              │
│                      │                     │   50 × Index Scan = 50 итераций × 0.1ms = 5ms (быстро!)              │
│                      │                     │                                                                      │
│                      │ Hash Join           │ ✓ Одна таблица ЗНАЧИТЕЛЬНО меньше другой (в 100+ раз)                │
│                      │ (строим хеш из      │ ✓ Хеш-таблица ВЛЕЗАЕТ в work_mem (Batches = 1)                       │
│                      │  меньшей таблицы,   │ ✓ Нет индекса для Nested Loop                                        │
│                      │  сканируем большую) │ ✗ Пример: JOIN products (100) ⋈ orders (1M)                          │
│                      │                     │   Хеш из 100 строк (14KB) + сканирование 1M = 169ms                  │
│                      │                     │ ⚠ Если Batches > 1 → увеличить work_mem!                             │
│                      │                     │                                                                      │
│                      │ Merge Join          │ ✓ Обе таблицы УЖЕ отсортированы (индексы, CLUSTER)                   │
│                      │ (слияние двух       │ ✓ Таблицы ОГРОМНЫЕ и хеш не влезает в work_mem                       │
│                      │  отсортированных    │ ✓ Нужен результат в отсортированном виде (ORDER BY)                  │
│                      │  потоков)           │ ✗ Пример: JOIN customers ⋈ orders + ORDER BY customer_id             │
│                      │                     │   Оба индекса дают сортировку → слияние без памяти                   │
│                      │                     │ ⚠ Если нет сортировки → дорогая операция Sort → лучше Hash Join      │
├──────────────────────┼─────────────────────┼──────────────────────────────────────────────────────────────────────┤
│                      │                     │                                                                      │
│ ГРУППИРОВКА          │ HashAggregate       │ ✓ Много уникальных групп (тысячи и больше)                           │
│ (GROUP BY)           │ (хеш-таблица:       │ ✓ Данные НЕ отсортированы по GROUP BY                                │
│                      │  ключ → агрегат)    │ ✓ Хеш влезает в work_mem (Batches = 1)                               │
│                      │                     │ ✗ Пример: SELECT status, COUNT(*) FROM orders GROUP BY status        │
│                      │                     │   2 группы, хеш 24KB → быстро                                        │
│                      │                     │ ⚠ Если Batches > 1 → увеличить work_mem ИЛИ GroupAggregate           │
│                      │                     │                                                                      │
│                      │ GroupAggregate      │ ✓ Данные УЖЕ отсортированы по GROUP BY (CLUSTER, Index Scan,         │
│                      │ (стримовая: идём    │   Merge Join, ORDER BY)                                              │
│                      │  по строкам,        │ ✓ Нужна экономия памяти (0 байт!)                                    │
│                      │  копим агрегат)     │ ✓ Объединение параллельных потоков (Gather Merge)                    │
│                      │                     │ ✗ Пример: SELECT order_date, SUM(amount) FROM orders                 │
│                      │                     │   WHERE ... GROUP BY order_date (после CLUSTER по дате)              │
│                      │                     │   Index Scan даёт отсортированные данные → GroupAggregate            │
├──────────────────────┼─────────────────────┼──────────────────────────────────────────────────────────────────────┤
│                      │                     │                                                                      │
│ СОРТИРОВКА + LIMIT   │ Index Scan Backward │ ✓ Есть индекс по колонке из ORDER BY                                 │
│ (TOP-N)              │ (идём с конца       │ ✓ Направление индекса совпадает с ORDER BY (ASC/DESC)                │
│                      │  индекса, берём N)  │ ✗ Пример: SELECT * FROM products ORDER BY price DESC LIMIT 10        │
│                      │                     │   Индекс по price → идём с конца → 0.04ms (МГНОВЕННО!)               │
│                      │                     │                                                                      │
│                      │ Top-N Heapsort      │ ✓ НЕТ подходящего индекса для ORDER BY                               │
│                      │ (куча из N строк,   │ ✓ Фильтр WHERE не по индексу ORDER BY                                │
│                      │  один проход        │ ✗ Пример: SELECT * FROM orders WHERE status = 'Returned'             │
│                      │  по таблице)        │   ORDER BY order_date DESC LIMIT 10 (индекс по date,                 │
│                      │                     │   но фильтр по status → просматриваем много строк)                   │
│                      │                     │ ⚠ Если нашли много строк с Returned → быстро.                        │
│                      │                     │   Если Returned редкий → может просмотреть всю таблицу.              │
└──────────────────────┴─────────────────────┴──────────────────────────────────────────────────────────────────────┘

ВАЖНЫЕ ПОРОГИ ДЛЯ ПРИНЯТИЯ РЕШЕНИЙ:

  ПЕРЕКЛЮЧЕНИЕ МЕТОДОВ ДОСТУПА (по селективности s):
    s < 1%        → Index Scan (если correlation > 0.7) или Bitmap Scan (если correlation < 0.3)
    1% < s < 5%   → Index Scan (после CLUSTER) или Bitmap Scan (без CLUSTER)
    5% < s < 30%  → Bitmap Scan (оптимально)
    s > 30%       → Seq Scan

  ПЕРЕКЛЮЧЕНИЕ МЕТОДОВ JOIN (по размеру внешней таблицы N_outer):
    N_outer < 100          → Nested Loop (если есть индекс на inner)
    100 < N_outer < 10 000 → Hash Join или Nested Loop (зависит от индекса)
    N_outer > 10 000       → Hash Join (если хватает work_mem) или Merge Join

  ПЕРЕКЛЮЧЕНИЕ МЕТОДОВ GROUP BY (по числу уникальных групп G):
    G < 1000      → HashAggregate (быстрее, требует память)
    G > 10000     → GroupAggregate (если данные отсортированы) или HashAggregate
    Данные отсортированы → ВСЕГДА GroupAggregate (0 памяти!)

  КРИТИЧЕСКИЕ ЗНАЧЕНИЯ work_mem:
    Batches = 1  → всё в памяти (ОТЛИЧНО)
    Batches = 2-5 → на грани (увеличь work_mem в 2-4 раза)
    Batches > 10 → КАТАСТРОФА (срочно увеличить work_mem или сменить алгоритм)
*/


/*
=============================================================================
ПОЛНОЕ ДЕРЕВО РЕШЕНИЙ ДЛЯ ОСНОВНЫХ АЛГОРИТМОВ POSTGRESQL
С ДОПОЛНИТЕЛЬНЫМИ ПРИЗНАКАМИ ДЛЯ ЛУЧШЕГО ПОНИМАНИЯ
=============================================================================
*/

/*
═════════════════════════════════════════════════════════════════════════════
1. МЕТОД ДОСТУПА К ДАННЫМ (Seq Scan / Index Scan / Bitmap Scan / Index Only Scan)
═════════════════════════════════════════════════════════════════════════════

КАК ОПРЕДЕЛИТЬ В ПЛАНЕ:
  Seq Scan on t            — читает всю таблицу страница за страницей
  Index Scan using idx     — читает индекс → heap (таблицу)
  Index Only Scan using idx — читает ТОЛЬКО индекс (heap не трогает)
  Bitmap Heap Scan         — битмап страниц → heap
    -> Bitmap Index Scan   — построение битмапа из индекса

═════════════════════════════════════════════════════════════════════════════

WHERE использует колонку с индексом?
│
├─ НЕТ → Seq Scan
│   │
│   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
│   │   • Filter + Rows Removed by Filter > 70%? → СОЗДАТЬ ИНДЕКС
│   │   • Таблица < 10 страниц? → Seq Scan ОПТИМАЛЕН (индекс не нужен)
│   │   • Parallel Seq Scan? → читается в N потоков (Gather вверху)
│   │
│   └─ НЕТ индекса, но s < 5%? → СОЗДАТЬ ИНДЕКС (точечные запросы)
│
└─ ДА → Селективность s = строк_из_WHERE / всего_строк?
    │
    │   КАК ОЦЕНИТЬ s:
    │   • EXPLAIN: rows в верхней строке / reltuples в pg_class
    │   • pg_stats.most_common_freqs для частых значений
    │   • SELECT count(*) FROM t WHERE условие — точный подсчёт
    │
    ├─ s > 30% → Seq Scan
    │   │
    │   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
    │   │   • Планировщик НЕ ошибся! 30%+ = sequential read быстрее random I/O
    │   │   • Исключение: Index Only Scan может быть быстрее (если heap не читаем)
    │   │   • Bitmap Scan здесь НЕ оптимлен (построение битмапа дороже Seq Scan)
    │   │
    │   └─ WHERE с частым значением (most_common_freqs > 0.3)? → Seq Scan ОПТИМАЛЕН
    │
    ├─ 5% ≤ s ≤ 30% → Bitmap Scan
    │   │
    │   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
    │   │   • Heap Blocks: exact=X → X >> rows? → данные разбросаны
    │   │   • Recheck Cond → перепроверка на странице (нормально для Bitmap)
    │   │   • BitmapOr/BitmapAnd → комбинация 2+ индексов
    │   │   • work_mem влияет: битмап строится в памяти
    │   │
    │   └─ correlation > 0.8? (pg_stats) → Index Scan
    │       │
    │       │   ПОЧЕМУ: данные скучены → Index Scan = почти sequential read
    │       │   ПРОВЕРИТЬ: SELECT correlation FROM pg_stats
    │       │   ГДЕ: correlation → 1.0 = идеальный порядок, 0.0 = хаос
    │       │
    │       └─ УЖЕ сделали CLUSTER? → correlation ≈ 1.0 → Index Scan
    │
    └─ s < 5% → correlation > 0.7? (pg_stats)
        │
        ├─ ДА → Index Scan
        │   │
        │   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
        │   │   • buffers / rows > 1.0? → CLUSTER (каждая строка на своей странице!)
        │   │   • buffers / rows < 0.1? → ОТЛИЧНО (много строк на странице)
        │   │   • Index Cond (не Filter!) → поиск по индексу (хорошо)
        │   │   • Filter поверх Index Cond → фильтрация после чтения heap (хуже)
        │   │
        │   └─ Все колонки SELECT есть в индексе? → Index Only Scan
        │       │
        │       │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
        │       │   • Heap Fetches: 0 → идеально (heap не читали)
        │       │   • Heap Fetches > 0 → visibility map устарела → VACUUM
        │       │   • indexdef в pg_indexes → проверь INCLUDE колонки
        │       │   • n_tup_upd/del в pg_stat_user_tables → много после VACUUM?
        │       │
        │       └─ НЕТ Index Only Scan, хотя колонки в индексе?
        │           → VACUUM таблица; (обновить visibility map)
        │
        └─ НЕТ → Bitmap Scan
            │
            │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
            │   • correlation < 0.3 → данные РАЗБРОСАНЫ → Bitmap выгоднее Index Scan
            │   • Heap Blocks: exact ≈ rows → КАЖДАЯ строка на своей странице!
            │   • Хочешь Index Scan? → CLUSTER
            │
            └─ После CLUSTER: correlation ≈ 1.0 → план переключится на Index Scan


═════════════════════════════════════════════════════════════════════════════
2. МЕТОД СОЕДИНЕНИЯ (Nested Loop / Hash Join / Merge Join)
═════════════════════════════════════════════════════════════════════════════

КАК ОПРЕДЕЛИТЬ В ПЛАНЕ:
  Nested Loop              — внешний цикл × внутренний поиск
  Hash Join                — Hash (inner) + Scan (outer)
  Merge Join               — два отсортированных потока
  Hash Semi Join           — EXISTS с хешом
  Hash Anti Join           — NOT EXISTS с хешом

КАК ОПРЕДЕЛИТЬ N_outer И N_inner:
  • Первый дочерний узел (меньше отступ) = outer (внешняя таблица)
  • Второй дочерний узел (больше отступ) = inner (внутренняя таблица)
  • В EXPLAIN: читай СЛЕВА НАПРАВО и СВЕРХУ ВНИЗ по отступам

═════════════════════════════════════════════════════════════════════════════

N_outer = строк во внешней таблице (смотри actual ... rows=Y loops=1)
N_inner = строк во внутренней таблице (смотри actual ... rows=Y loops=N)

N_outer < 100?
│
├─ ДА → Индекс на inner по ключу JOIN?
│   │
│   │   ПРОВЕРИТЬ:
│   │   • EXPLAIN: внутренний узел = Index Scan? → хорошо
│   │   • EXPLAIN: внутренний узел = Seq Scan? → КАТАСТРОФА!
│   │   • pg_indexes: indexdef содержит ключ JOIN?
│   │
│   ├─ ДА → Nested Loop
│   │   │
│   │   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
│   │   │   • loops=N во внутреннем узле → N итераций
│   │   │   • loops до 500 → ОТЛИЧНО (мгновенно)
│   │   │   • loops 500-5000 → НОРМАЛЬНО (терпимо)
│   │   │   • loops > 5000 → Hash Join может быть лучше
│   │   │   • buffers_inner / loops ≈ 1? → каждая итерация = 1 страница
│   │   │   • buffers_inner / loops ≈ 100? → каждая итерация = 100 страниц (дорого!)
│   │   │
│   │   └─ ЕСЛИ loops > 1000 И buffers/rows > 1.0 для inner?
│   │       → Может, Hash Join лучше (сравнить: loops × cost vs cost_hash)
│   │
│   └─ НЕТ → Hash Join
│       │
│       │   ПОЧЕМУ: Nested Loop без индекса = O(N_outer × N_inner) = КАТАСТРОФА
│       │   ПРИМЕР: 50 × 1M = 50M чтений (vs Hash Join: 1M + 50)
│       │
│       └─ ЕСЛИ N_outer = 1 и нужна 1 строка → Nested Loop (Seq Scan 1 раз)
│
└─ НЕТ → N_outer < 10 000?
    │
    ├─ ДА → Индекс на inner?
    │   │
    │   ├─ ДА → Nested Loop ИЛИ Hash Join (планировщик сравнивает стоимость)
    │   │   │
    │   │   │   КАК ПЛАНИРОВЩИК ВЫБИРАЕТ:
    │   │   │   • cost_nl = cost_outer + N_outer × cost_index_search
    │   │   │   • cost_hash = cost_outer + cost_hash_build + N_outer × cost_probe
    │   │   │   • Если N_outer × cost_index > cost_hash_build → Hash Join
    │   │   │
    │   │   └─ НЕТ явного победителя? → см. actual time в EXPLAIN
    │   │
    │   └─ НЕТ → Hash Join
    │
    └─ НЕТ → Hash Join
        │
        │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
        │   • Hash (inner) — какая таблица в хеше?
        │   • МЕНЬШАЯ → ОТЛИЧНО (Batches = 1, Memory Usage мало)
        │   • БОЛЬШАЯ → Планировщик ОШИБСЯ!
        │     → ANALYZE обе таблицы; (уточнить reltuples в pg_class)
        │     → Проверить: SELECT relname, reltuples FROM pg_class WHERE ...
        │   • Batches = 1? → всё в памяти
        │   • Batches > 1? → УВЕЛИЧИТЬ work_mem
        │   • Batches > 10? → КАТАСТРОФА (диск!)
        │
        └─ Batches всё ещё > 1 после увеличения work_mem?
            │
            ├─ ДА → Merge Join (если есть индексы/ORDER BY по ключу JOIN)
            │   │
            │   │   УСЛОВИЯ ДЛЯ Merge Join:
            │   │   • Индексы по ключу JOIN на ОБЕИХ таблицах → 0 сортировки
            │   │   • ORDER BY по ключу JOIN → сортировка уже сделана
            │   │   • НЕТ индексов? → Sort + Merge Join (дорого! 2 сортировки)
            │   │
            │   └─ НЕТ сортировки? → Sort + Merge Join
            │       └─ Стоимость: 2 × O(N log N) + O(N+M)
            │
            └─ НЕТ → УВЕЛИЧИТЬ work_mem ещё

ОСОБЫЕ СЛУЧАИ:
  • ORDER BY по ключу JOIN + индексы → Merge Join (0 памяти, идеально!)
    ПРИЗНАК: Merge Cond совпадает с ORDER BY
  • Hash выбрал БОЛЬШУЮ таблицу как inner → ANALYZE (ошибка reltuples)
    ПРИЗНАК: Hash над таблицей с бОльшим reltuples
  • Nested Loop + loops > 1000 + Seq Scan на inner → ИНДЕКС НА INNER!
    ПРИЗНАК: внутренний узел = Seq Scan, loops=5000 → 5000 × полное сканирование
  • EXISTS → Hash Semi Join / Nested Loop Semi
    ПРИЗНАК: останавливается на ПЕРВОМ совпадении
  • NOT EXISTS → Hash Anti Join
    ПРИЗНАК: ищет ОТСУТСТВИЕ совпадений


═════════════════════════════════════════════════════════════════════════════
3. МЕТОД ГРУППИРОВКИ (HashAggregate / GroupAggregate)
═════════════════════════════════════════════════════════════════════════════

КАК ОПРЕДЕЛИТЬ В ПЛАНЕ:
  HashAggregate            — Group Key, Batches, Memory Usage
  GroupAggregate            — Group Key (без Batches, без Memory Usage)
  Partial HashAggregate     — внутри параллельного воркера
  Finalize GroupAggregate   — финализация после Gather Merge

═════════════════════════════════════════════════════════════════════════════

Данные отсортированы по ключу GROUP BY?
│
│   КАК ПОНЯТЬ ЧТО ОТСОРТИРОВАНЫ:
│   • Дочерний узел = Index Scan по GROUP BY → ДА (индекс = порядок)
│   • Дочерний узел = Merge Join по GROUP BY → ДА
│   • Дочерний узел = Sort по GROUP BY → ДА (но дорого!)
│   • Дочерний узел = Seq Scan → НЕТ (данные в разнобой)
│   • CLUSTER по GROUP BY + Index Scan → ДА (идеально!)
│
├─ ДА → GroupAggregate (0 памяти, стримовая агрегация)
│   │
│   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
│   │   • НЕТ Batches, НЕТ Memory Usage → 0 памяти!
│   │   • Выдаёт результат СРАЗУ (не ждёт все строки)
│   │   • Идеально для потоковой обработки
│   │   • correlation > 0.7 для GROUP BY → Index Scan → GroupAggregate
│   │
│   └─ Дочерний узел = Sort? → HashAggregate может быть лучше
│       │
│       │   ПОЧЕМУ: Sort дорогой (O(N log N)), HashAggregate может быть дешевле
│       │   СРАВНИ: cost_sort vs cost_hash_aggregate
│       │
│       └─ НО ЕСЛИ Sort уже нужен для ORDER BY → GroupAggregate БЕСПЛАТНО!
│
└─ НЕТ → HashAggregate
    │
    │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
    │   • Group Key — ключ группировки
    │   • Batches = 1 → всё в памяти (ОПТИМАЛЕН)
    │   • Memory Usage → сколько памяти занял хеш
    │   • Число уникальных групп G = n_distinct в pg_stats
    │   • G < 1000 → Memory Usage мало → ОТЛИЧНО
    │   • G > 10 000 → Memory Usage может превысить work_mem → Batches > 1
    │
    ├─ Batches = 1? → ОПТИМАЛЕН
    │
    └─ Batches > 1? → УВЕЛИЧИТЬ work_mem
        │
        │   СКОЛЬКО УВЕЛИЧИТЬ:
        │   • Batches = 2 → work_mem × 2
        │   • Batches = 5 → work_mem × 5
        │   • Batches = N → work_mem × N (чтобы Batches стало 1)
        │
        └─ Не помогло? → GroupAggregate (ORDER BY + индекс по GROUP BY)
            │
            │   КАК ПЕРЕКЛЮЧИТЬ:
            │   • CREATE INDEX ON t (group_key);
            │   • Добавь ORDER BY group_key в запрос
            │   • План переключится на GroupAggregate
            │
            └─ G > 100 000? → GroupAggregate ЕДИНСТВЕННЫЙ выход

ПАРАЛЛЕЛЬНЫЙ HashAggregate:
  • Parallel Seq Scan → Partial HashAggregate (в каждом воркере)
    → Gather Merge → Finalize GroupAggregate
  • ПРИЗНАК: Workers Planned > 0
  • Workers Launched = 0? → закончились воркеры → пункт 16
  • Параллельный план МЕДЛЕННЕЕ? → SET max_parallel_workers_per_gather = 0

DISTINCT:
  • Работает как GROUP BY без агрегата
  • HashAggregate (G мало) ИЛИ Unique + Sort (G много)


═════════════════════════════════════════════════════════════════════════════
4. СОРТИРОВКА И TOP-N (Sort / Index Scan Backward / Top-N Heapsort)
═════════════════════════════════════════════════════════════════════════════

КАК ОПРЕДЕЛИТЬ В ПЛАНЕ:
  Sort                      — Sort Key, Sort Method, Memory/Disk
  Index Scan Backward       — чтение индекса с конца (DESC)
  Index Scan                — чтение индекса (ASC)
  Limit                     — обрезает результат до N строк

═════════════════════════════════════════════════════════════════════════════

ORDER BY + LIMIT?
│
├─ ДА → Индекс по ORDER BY?
│   │
│   │   ПРОВЕРИТЬ:
│   │   • pg_indexes: indexdef содержит колонку из ORDER BY?
│   │   • Направление: ASC → Index Scan, DESC → Index Scan Backward
│   │   • Index Only Scan? → все колонки SELECT в индексе
│   │
│   ├─ ДА → Index Scan (ASC) / Index Scan Backward (DESC)
│   │   │
│   │   │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
│   │   │   • actual time → 0.04ms (МГНОВЕННО!)
│   │   │   • rows = LIMIT (не больше!)
│   │   │   • buffers → только страницы индекса (очень мало)
│   │   │   • Ускорение vs Top-N Heapsort: в 100-1000 раз!
│   │   │
│   │   └─ Все колонки SELECT есть в индексе? → Index Only Scan
│   │       (вообще не читаем heap!)
│   │
│   └─ НЕТ → Top-N Heapsort
│       │
│       │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
│       │   • Sort Method: top-N heapsort → куча из N строк
│       │   • Память: O(N) — очень мало
│       │   • Время: O(N_total × log N) — один проход по таблице
│       │   • Фильтр WHERE + оценка строк → если фильтр селективный → быстро
│       │   • Фильтр НЕ селективный → может прочитать всю таблицу
│       │
│       └─ СОЗДАТЬ ИНДЕКС ПО ORDER BY (ускорение в 100-1000 раз!)
│
└─ НЕТ (ORDER BY без LIMIT) → Индекс по ORDER BY?
    │
    │   ДОПОЛНИТЕЛЬНЫЕ ПРИЗНАКИ:
    │   • Sort Key — колонка сортировки
    │   • Sort Method: quicksort → в памяти (ОК)
    │   • Sort Method: external merge Disk: XXXkB → на диске (ПЛОХО!)
    │
    ├─ ДА → Index Scan
    │   │
    │   │   ПОЧЕМУ: индекс УЖЕ содержит отсортированные данные
    │   │   ПЛЮС: 0 памяти, sequential read
    │   │
    │   └─ Все колонки SELECT есть в индексе? → Index Only Scan
    │
    └─ НЕТ → Sort
        │
        ├─ quicksort (в памяти) → ОК
        │   └─ Memory: XkB → < work_mem → отлично
        │
        └─ external merge Disk: XXXkB → УВЕЛИЧИТЬ work_mem ИЛИ ИНДЕКС
            │
            │   ПОЧЕМУ НА ДИСКЕ:
            │   • Объём данных > work_mem
            │   • Сортировка разбивается на куски, сливается с диска
            │   • Время: O(N log N) + disk I/O → МЕДЛЕННО!
            │
            └─ РЕШЕНИЕ:
                ├─ SET work_mem = 'XXXMB'; (увеличь до объёма данных)
                └─ CREATE INDEX ON t (order_col); (0 сортировки!)

ОКОННЫЕ ФУНКЦИИ (OVER):
  • Требуют Sort по PARTITION BY + ORDER BY
  • ПРИЗНАК: WindowAgg + Sort
  • Индекс покрывает (PARTITION BY, ORDER BY)? → Index Scan (без Sort!)
  • ПРИМЕР: SUM() OVER (PARTITION BY dept ORDER BY date)
    → CREATE INDEX ON t (dept, date);
*/






*/



=============================================================================
ПОЛНЫЙ ЧЕК-ЛИСТ ОПТИМИЗАЦИИ ЗАПРОСОВ POSTGRESQL (21 ПУНКТ)
СГРУППИРОВАН ПО ЭТАПАМ С КОММЕНТАРИЯМИ КО ВСЕМ СТОЛБЦАМ
=============================================================================
*/

/*
═════════════════════════════════════════════════════════════════════════════
ЭТАП 1: ДИАГНОСТИКА ПЛАНА ЗАПРОСА (пункты 1-6)
═════════════════════════════════════════════════════════════════════════════
*/

--============================================================================
-- 1. ПОЛУЧАЕМ ПЛАН МЕДЛЕННОГО ЗАПРОСА
--============================================================================

EXPLAIN (ANALYZE, BUFFERS);
ТВОЙ_ЗАПРОС;

/*
КОММЕНТАРИИ К ВЫВОДУ EXPLAIN:

  Ключевые метрики в плане:
  • cost=начало..конец         — оценка стоимости (чем меньше, тем лучше)
  • actual time=начало..конец  — реальное время в мс (первое число — до первой строки)
  • rows=X                     — количество возвращённых строк
  • loops=N                    — сколько раз выполнен узел (для Nested Loop — число итераций)
  • Buffers: shared hit=X      — страниц прочитано из кеша (ОЗУ, быстро)
  • Buffers: read=X            — страниц прочитано с диска (медленно)
  • Rows Removed by Filter     — строк отброшено фильтром WHERE
  • Batches: N                 — на сколько пакетов разбит хеш (>1 = не влезло в work_mem)
  • Sort Method                — quicksort (в памяти) / external merge (на диске)

  АНАЛИЗ ПЛАНА:
  1. Найди узел с МАКСИМАЛЬНЫМ buffers → это узкое место.
  2. Определи АЛГОРИТМ в этом узле:
     • Seq Scan      → пункт 2 (нужен индекс?)
     • Index Scan    → пункт 3 (данные разбросаны?)
     • Bitmap Scan   → пункт 3 (можно ускорить?)
     • Nested Loop   → пункт 4 (много итераций?)
     • Hash Join     → пункт 5 (влезает в память?)
     • HashAggregate → пункт 5 (влезает в память?)
     • Sort          → пункт 6 (сортировка на диске?)
  3. Сравни estimated rows (cost=..rows=X) и actual rows (actual..rows=Y).
     Большая разница? → Этап 4, пункт 13 (ошибка кардинальности).
*/


--============================================================================
-- 2. Seq Scan → НУЖЕН ЛИ ИНДЕКС?
--============================================================================

SELECT COUNT(*) FROM таблица WHERE твоё_условие;

/*
  Если строк > 30% от ВСЕХ строк таблицы:
    → Seq Scan оптимален. Ничего не делай.

  Если строк < 30%:
    → CREATE INDEX ON таблица (колонки_из_WHERE);
*/


--============================================================================
-- 3. Index Scan / Bitmap Scan → ДАННЫЕ РАЗБРОСАНЫ?
--============================================================================

SELECT
    attname     AS колонка,       -- имя колонки в таблице
    correlation AS корреляция     -- физическая упорядоченность данных на диске:
                                  --  1.0 = идеальный порядок (строки идут подряд)
                                  --  0.0 = полный хаос (строки разбросаны)
                                  -- -1.0 = обратный порядок
FROM pg_stats                    -- системная таблица со статистикой по колонкам
WHERE tablename = 'имя_таблицы'  -- имя таблицы (pg_stats.tablename)
  AND attname  = 'индексированная_колонка';  -- имя колонки (pg_stats.attname)

/*
  correlation = 0.9..1.0 → отлично, Index Scan быстр.
  correlation = 0.0..0.3 → данные разбросаны, Index Scan медленный.

  Если correlation < 0.3 и buffers > 1000:
    → CLUSTER таблица USING имя_индекса;
    → После CLUSTER correlation станет ≈ 1.0.
    → Запрос ускорится в 10-100 раз.
*/


--============================================================================
-- 4. Nested Loop → МНОГО ИТЕРАЦИЙ?
--============================================================================

-- Найди в плане loops у ВНУТРЕННЕГО узла:
-- -> Index Scan ... (loops=5000) ← если loops > 1000

/*
  loops — сколько раз выполнился внутренний узел.
  Каждая итерация = один поиск по индексу (O(log N)).

  Если loops > 1000 И внутри НЕТ Seq Scan:
    → Nested Loop оптимален. Ничего не делай.

  Если loops > 1000 И внутри Seq Scan:
    → Полный перебор на каждой итерации (O(N_outer × N_inner))!
    → CREATE INDEX ON внутр_таблица (ключ_соединения);
*/


--============================================================================
-- 5. Hash Join / HashAggregate → ХВАТАЕТ ЛИ ПАМЯТИ?
--============================================================================

-- Найди в плане Batches:
-- Hash  ...  Batches: 5  ← если > 1

/*
  Batches — на сколько пакетов разбит хеш.
  Batches = 1: вся хеш-таблица поместилась в work_mem.
  Batches ≥ 2: данные не влезли, каждый пакет сбрасывается на диск → медленно!

  РЕШЕНИЕ:
    SET work_mem = '200MB';  -- увеличь в 2-4 раза и выполни запрос заново.

  Если Batches всё ещё > 1:
    → Для HashAggregate: замени на GroupAggregate
      (добавь ORDER BY по GROUP BY + индекс).
    → Для Hash Join: увеличь work_mem ещё.
*/


--============================================================================
-- 6. Sort → СОРТИРОВКА НА ДИСКЕ?
--============================================================================

-- Найди в плане:
-- Sort Method: external merge  Disk: 1024kB  ← сортировка на диске!

/*
  Sort Method = quicksort → сортировка в памяти (хорошо).
  Sort Method = external merge → данные не влезли в work_mem, сортировка на диске (плохо).

  РЕШЕНИЕ (выбери одно):
    1. SET work_mem = '100MB';
    2. CREATE INDEX ON таблица (колонка_из_ORDER_BY);
       → план переключится на Index Scan (без сортировки).
*/


/*
═════════════════════════════════════════════════════════════════════════════
ЭТАП 2: ИНДЕКСЫ — СОЗДАНИЕ, ТИП, СОСТОЯНИЕ (пункты 8,9,11,12,18,19,20,21)
═════════════════════════════════════════════════════════════════════════════
*/

--============================================================================
-- 8. ПРОВЕРКА НЕИСПОЛЬЗУЕМЫХ ИНДЕКСОВ
--============================================================================

SELECT
    indexrelname AS индекс,    -- имя индекса (pg_stat_user_indexes.indexrelname)
    idx_scan     AS использований  -- сколько раз индекс был использован
                                   -- (pg_stat_user_indexes.idx_scan)
FROM pg_stat_user_indexes      -- системная таблица со статистикой использования индексов
WHERE relname = 'имя_таблицы'  -- имя таблицы (pg_stat_user_indexes.relname)
  AND idx_scan = 0;            -- ни разу не использовался!

/*
  Если idx_scan = 0 → индекс не нужен:
    → DROP INDEX имя_индекса;
    → Освободит место и ускорит INSERT/UPDATE.
*/


--============================================================================
-- 9. ПРОВЕРКА РАЗМЕРА ТАБЛИЦЫ
--============================================================================

SELECT
    relname  AS имя,            -- имя таблицы/индекса (pg_class.relname)
    relpages AS страниц_8kb,    -- количество страниц по 8KB (pg_class.relpages)
    pg_size_pretty(             -- функция: переводит байты в читаемый вид (KB/MB/GB)
        pg_relation_size(oid)   -- размер таблицы/индекса на диске в байтах
    ) AS размер
FROM pg_class                  -- системный каталог: все таблицы, индексы, последовательности
WHERE relname = 'имя_таблицы';

/*
  relpages (страниц):
    < 10 и размер < 1 MB → таблица маленькая, Seq Scan всегда оптимален.
    > 100000 (таблица > 1 GB) → рассмотри партицирование.
*/


--============================================================================
-- 11. ПОКРЫВАЮЩИЙ ИНДЕКС (Index Only Scan)
--============================================================================

SELECT
    indexname,                 -- имя индекса (pg_indexes.indexname)
    indexdef                   -- полное определение индекса (pg_indexes.indexdef)
                               -- содержит CREATE INDEX ... (колонки)
FROM pg_indexes                -- системное представление: список всех индексов
WHERE tablename = 'имя_таблицы';  -- имя таблицы (pg_indexes.tablename)

/*
  Сравни колонки в SELECT с колонками в indexdef:
    SELECT col1, col2 FROM t WHERE col1 = X;
    Индекс: (col1) → Index Scan (читает heap — таблицу)
    Индекс: (col1) INCLUDE (col2) → Index Only Scan (НЕ читает heap!)

  Если все колонки из SELECT есть в индексе, но план = Index Scan:
    → Таблица недавно обновлялась (visibility map устарела) → пункт 12.
*/


--============================================================================
-- 12. ПРОВЕРКА VISIBILITY MAP (для Index Only Scan)
--============================================================================

SELECT
    relname,                   -- имя таблицы (pg_stat_user_tables.relname)
    n_tup_upd    AS обновлений, -- сколько строк обновлено (pg_stat_user_tables.n_tup_upd)
    n_tup_del    AS удалений,   -- сколько строк удалено (pg_stat_user_tables.n_tup_del)
    last_vacuum,                -- когда был последний ручной VACUUM
    last_autovacuum             -- когда был последний автоматический VACUUM
FROM pg_stat_user_tables        -- системная таблица со статистикой использования таблиц
WHERE relname = 'имя_таблицы';

/*
  Если много UPDATE/DELETE после последнего VACUUM:
    → VACUUM таблица;  (обновит visibility map)
    → Index Only Scan станет возможен.
    → Экономия: не читаем heap вообще!
*/


--============================================================================
-- 18. ПРОВЕРКА РАЗДУТЫХ ИНДЕКСОВ (Index Bloat)
--============================================================================

SELECT
    indexrelname   AS индекс,   -- имя индекса (pg_stat_user_indexes.indexrelname)
    idx_scan       AS использований,  -- сколько раз использован (pg_stat_user_indexes.idx_scan)
    pg_size_pretty(
        pg_relation_size(indexrelid)  -- размер индекса на диске в байтах (pg_stat_user_indexes.indexrelid — OID индекса)
    ) AS размер,
    idx_tup_read   AS строк_прочитано,  -- сколько строк прочитано из индекса (pg_stat_user_indexes.idx_tup_read)
    idx_tup_fetch  AS строк_получено    -- сколько строк получено из heap (pg_stat_user_indexes.idx_tup_fetch)
FROM pg_stat_user_indexes
WHERE relname = 'имя_таблицы'
ORDER BY pg_relation_size(indexrelid) DESC;

/*
  idx_tup_fetch ≈ idx_tup_read → Index Only Scan (хорошо).
  idx_tup_fetch << idx_tup_read → много Heap Fetches (читаем heap).

  Если размер индекса НЕПРОПОРЦИОНАЛЬНО большой:
    → REINDEX INDEX имя_индекса;
    → Уменьшит размер и ускорит сканирование.
*/


--============================================================================
-- 19. ПРОВЕРКА СОСТАВНЫХ ИНДЕКСОВ
--============================================================================

SELECT
    indexname,                 -- имя индекса (pg_indexes.indexname)
    indexdef                   -- определение индекса (pg_indexes.indexdef)
FROM pg_indexes
WHERE tablename = 'имя_таблицы';

/*
  Если WHERE содержит 2+ колонок через AND:
    → Нужен СОСТАВНОЙ индекс: (col1, col2)
    → Порядок колонок ВАЖЕН!
      • Сначала: колонки с РАВЕНСТВОМ (a = 1)
      • Потом: колонки с ДИАПАЗОНОМ (b BETWEEN, b >, b <)
      • Потом: колонки из ORDER BY (c)

  Пример:
    WHERE a = 1 AND b BETWEEN 2 AND 3 ORDER BY c
    → Индекс: (a, b, c)
*/


--============================================================================
-- 20. ПРОВЕРКА ЧАСТИЧНЫХ ИНДЕКСОВ
--============================================================================

/*
  Проблема: Индекс большой, но запросы только по подмножеству строк.
  Пример: 90% строк имеют status='Active', запросы только по status='Deleted'.

  РЕШЕНИЕ: ЧАСТИЧНЫЙ ИНДЕКС
    CREATE INDEX idx_deleted ON orders (order_date)
    WHERE status = 'Deleted';

  → Индекс МЕНЬШЕ (только 10% строк).
  → Быстрее сканировать, меньше памяти, быстрее обновлять.
*/


--============================================================================
-- 21. ПРОВЕРКА УНИКАЛЬНЫХ ИНДЕКСОВ
--============================================================================

/*
  Проблема: Медленный INSERT/UPDATE из-за проверки уникальности.
  При каждой вставке/обновлении PostgreSQL проверяет UNIQUE-индекс.

  Если уникальность НЕ НУЖНА, а индекс уникальный:
    → DROP INDEX unique_index;
    → CREATE INDEX plain_index ON t (col);  (простой индекс)
    → Ускорит вставки в 2-3 раза.
*/


/*
═════════════════════════════════════════════════════════════════════════════
ЭТАП 3: ПАМЯТЬ И РЕСУРСЫ (пункты 5,6,16,17)
═════════════════════════════════════════════════════════════════════════════
*/

-- 5. Hash * Aggregate + Batches > 1 → SET work_mem = '200MB';
--    (см. Этап 1, пункт 5)

-- 6. Sort external merge → SET work_mem ИЛИ индекс.
--    (см. Этап 1, пункт 6)

--============================================================================
-- 16. ПРОВЕРКА ПАРАЛЛЕЛИЗМА
--============================================================================

SHOW max_parallel_workers_per_gather;  -- макс. число воркеров на один запрос Gather
SHOW max_parallel_workers;             -- макс. число параллельных воркеров всего
SHOW max_worker_processes;             -- макс. число фоновых процессов (включая воркеры)

/*
  Если в плане Workers Launched: 0 при Workers Planned > 0:
    → Закончились воркеры (все заняты другими запросами).
    → Увеличь max_parallel_workers в postgresql.conf.

  Если параллельный план МЕДЛЕННЕЕ однопоточного:
    → SET max_parallel_workers_per_gather = 0; (для этого запроса).
*/


--============================================================================
-- 17. JIT-КОМПИЛЯЦИЯ
--============================================================================

SHOW jit;  -- Just-In-Time компиляция запросов: on/off

/*
  JIT компилирует выражения WHERE, JOIN, агрегаты в машинный код.
  Выгоден только для ДОЛГИХ аналитических запросов (> 100ms).

  Если JIT = on и запросы короткие (< 100ms):
    → SET jit = off;  (для сессии).
    → JIT добавляет задержку при планировании, но не окупается на коротких запросах.

  Для OLTP (много коротких запросов): jit = off в postgresql.conf.
*/


/*
═════════════════════════════════════════════════════════════════════════════
ЭТАП 4: СТАТИСТИКА И ОБСЛУЖИВАНИЕ (пункты 7,10,13,14)
═════════════════════════════════════════════════════════════════════════════
*/

--============================================================================
-- 7. ПРОВЕРКА СТАТИСТИКИ (МУСОР И АНАЛИЗ)
--============================================================================

SELECT
    relname       AS таблица,    -- имя таблицы (pg_stat_user_tables.relname)
    n_live_tup    AS живых_строк, -- живых строк (pg_stat_user_tables.n_live_tup)
    n_dead_tup    AS мёртвых_строк,  -- мёртвых строк: удалены/обновлены,
    -- но не очищены VACUUM (pg_stat_user_tables.n_dead_tup)
    ROUND(
            100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0),
            1
    ) AS мусор_процент,          -- доля мёртвых строк в процентах
    last_analyze AS последний_анализ,  -- когда был последний ANALYZE (pg_stat_user_tables.last_analyze)
    last_vacuum  AS последний_вакуум   -- когда был последний VACUUM (pg_stat_user_tables.last_vacuum)
FROM pg_stat_user_tables
WHERE relname = 'имя_таблицы';

/*
  n_dead_tup — "мёртвые" строки после UPDATE/DELETE.
  Они занимают место, Seq Scan читает их впустую.

  Если мусор_процент > 20%:
    → VACUUM таблица;  (очистит мёртвые строки → меньше страниц → быстрее Seq Scan).

  Если последний_анализ > 1 недели (при активных вставках/обновлениях):
    → ANALYZE таблица;  (обновит статистику для планировщика).
*/


--============================================================================
-- 10. ПРОВЕРКА СЕЛЕКТИВНОСТИ ЗНАЧЕНИЙ
--============================================================================

SELECT
    attname           AS колонка,       -- имя колонки (pg_stats.attname)
    most_common_vals  AS частые_значения,  -- самые частые значения (pg_stats.most_common_vals)
    most_common_freqs AS частота           -- их частота (pg_stats.most_common_freqs)
FROM pg_stats
WHERE tablename = 'имя_таблицы'
  AND attname  = 'имя_колонки';

/*
  Пример:
    частые_значения = '{Completed, Returned}'
    частота         = '{0.70, 0.30}'

  Интерпретация:
    WHERE колонка = 'Completed' → 70% таблицы → Seq Scan (правильно!).
    WHERE колонка = 'Returned'  → 30% таблицы → Bitmap/Seq Scan (нормально).
    WHERE колонка = 'RareValue' → значения НЕТ в списке → Index Scan (редкое).
*/


--============================================================================
-- 13. ОШИБКА ОЦЕНКИ КАРДИНАЛЬНОСТИ
--============================================================================

/*
  Проблема: estimated_rows (cost=..rows=X) СИЛЬНО отличается от
            actual_rows (actual..rows=Y) в плане EXPLAIN.
  Признак: планировщик ожидал 100 строк, а вернулось 50000.

  Причины и решения:
    1. Статистика устарела → ANALYZE таблица;
    2. Скошенное распределение (много уникальных, не влезли в MCV):
       → ALTER TABLE таблица ALTER COLUMN колонка SET STATISTICS 1000;
         ANALYZE таблица;
    3. Коррелированные колонки в WHERE:
       планировщик считает их НЕЗАВИСИМЫМИ и перемножает селективности.
       → Нужна расширенная статистика:
*/

SELECT
    stxname AS имя,       -- имя расширенной статистики (pg_statistic_ext.stxname)
    stxkeys AS колонки,   -- номера колонок (pg_statistic_ext.stxkeys)
    stxkind AS тип         -- тип статистики: mcv = многомерная (pg_statistic_ext.stxkind)
FROM pg_statistic_ext     -- системная таблица: расширенная статистика
WHERE stxrelid = 'имя_таблицы'::regclass;  -- OID таблицы (pg_statistic_ext.stxrelid)

/*
  Если WHERE содержит НЕСКОЛЬКО коррелированных колонок:
    → CREATE STATISTICS stat_name (mcv) ON col1, col2 FROM таблица;
    → ANALYZE таблица;
    → Планировщик будет точнее оценивать селективность.
*/


--============================================================================
-- 14. JOINS — ОШИБКА В РАЗМЕРЕ ТАБЛИЦ
--============================================================================

SELECT
    relname,       -- имя таблицы (pg_class.relname)
    reltuples      -- оценочное количество строк (pg_class.reltuples)
FROM pg_class
WHERE relname IN ('t1', 't2');

/*
  Проблема: Hash Join выбрал БОЛЬШУЮ таблицу как inner (строит хеш из неё).
  Признак: Hash Join → Hash на большой таблице → Batches > 10.

  reltuples — оценка количества строк (обновляется ANALYZE).
  Если планировщик ошибся в размерах:
    → ANALYZE t1; ANALYZE t2;
*/


/*
═════════════════════════════════════════════════════════════════════════════
ЭТАП 5: БЛОКИРОВКИ И ВНЕШНИЕ ФАКТОРЫ (пункт 15)
═════════════════════════════════════════════════════════════════════════════
*/

--============================================================================
-- 15. ПРОВЕРКА БЛОКИРОВОК
--============================================================================

-- Шаг 1: Найти ожидающие запросы
SELECT
    pid,                    -- ID процесса (pg_stat_activity.pid)
    wait_event_type,        -- тип ожидания: Lock, IO, CPU (pg_stat_activity.wait_event_type)
    wait_event,             -- конкретное событие ожидания (pg_stat_activity.wait_event):
    --   'relation' — ждёт блокировку таблицы
    --   'tuple'    — ждёт блокировку строки
    state,                  -- состояние: active, idle (pg_stat_activity.state)
    LEFT(query, 100) AS запрос  -- текст запроса (pg_stat_activity.query)
FROM pg_stat_activity       -- системная таблица: текущие процессы
WHERE state = 'active'
  AND wait_event IS NOT NULL
  AND pid <> pg_backend_pid();  -- исключаем свой собственный процесс

/*
  Если wait_event = 'relation' или 'tuple':
    → Запрос ждёт ОСВОБОЖДЕНИЯ БЛОКИРОВКИ!

  Шаг 2: Найти блокирующий процесс:
*/

SELECT
    blocked.pid            AS заблокирован,    -- PID заблокированного процесса
    blocked.query          AS запрос_ждёт,     -- его запрос
    blocking.pid           AS блокирует,       -- PID блокирующего процесса
    blocking.query         AS запрос_блокиратор, -- его запрос
    blocked.wait_event_type,                   -- тип ожидания
    blocked.wait_event                         -- событие ожидания
FROM pg_stat_activity blocked
         JOIN pg_stat_activity blocking
         ON blocked.wait_event = 'relation'
             AND blocking.pid <> blocked.pid
WHERE blocked.wait_event IS NOT NULL;

/*
  РЕШЕНИЕ:
    → Дождаться снятия блокировки.
    → Или принудительно завершить блокиратор:
      SELECT pg_terminate_backend(pid_блокиратора);
*/


/*
═════════════════════════════════════════════════════════════════════════════
СВОДКА: 21 ПУНКТ ПО ЭТАПАМ
═════════════════════════════════════════════════════════════════════════════

ЭТАП 1: ДИАГНОСТИКА ПЛАНА
  1. EXPLAIN (ANALYZE, BUFFERS)                — получи план
  2. Seq Scan + < 30% строк                    — СОЗДАТЬ ИНДЕКС
  3. Index Scan + correlation < 0.3            — CLUSTER
  4. Nested Loop + loops > 1000 + Seq Scan     — ИНДЕКС на inner
  5. Hash * Aggregate + Batches > 1            — work_mem
  6. Sort (external merge Disk)                — work_mem ИЛИ индекс

ЭТАП 2: ИНДЕКСЫ
  8.  idx_scan = 0                             — УДАЛИТЬ ИНДЕКС
  9.  Таблица < 10 страниц                     — индексы не нужны
  11. Index Scan вместо Index Only Scan        — проверить indexdef
  12. Много UPDATE/DELETE после VACUUM         — VACUUM (visibility map)
    18. Индекс раздут                            — REINDEX
    19. WHERE с 2+ колонками                     — СОСТАВНОЙ ИНДЕКС
    20. Запросы по подмножеству                  — ЧАСТИЧНЫЙ ИНДЕКС
    21. Медленный INSERT/UPDATE                  — убрать UNIQUE

    ЭТАП 3: ПАМЯТЬ И РЕСУРСЫ
    5.  Hash * Aggregate Batches > 1             — work_mem
    6.  Sort external merge                      — work_mem ИЛИ индекс
    16. Workers Launched: 0                      — max_parallel_workers
    17. Planning Time > 10ms + JIT               — jit = off

    ЭТАП 4: СТАТИСТИКА И ОБСЛУЖИВАНИЕ
    7.  n_dead_tup > 20%                         — VACUUM
    7.  last_analyze старый                      — ANALYZE
    10. Селективность значений                   — понять выбор планировщика
  13. Оценка строк ≠ реальность                — ANALYZE / STATISTICS / CREATE STATISTICS
  14. Hash Join выбрал большую таблицу         — ANALYZE (уточнить reltuples)

ЭТАП 5: БЛОКИРОВКИ
  15. Запрос висит (wait_event)                — pg_terminate_backend

*/







