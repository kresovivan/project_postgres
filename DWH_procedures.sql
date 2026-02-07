-- Удалить все таблицы в схеме dwh_training
DROP SCHEMA IF EXISTS dwh_training CASCADE;

-- Пересоздать схему (если нужно)
CREATE SCHEMA dwh_training;

-- Установить схему по умолчанию для текущей сессии
SET search_path TO dwh_training;
-- Проверить текущий search_path
SHOW search_path;

-- Генерируем и выполняем команды DROP TABLE для всех таблиц в схеме
DO $$
    DECLARE
        v_table_name TEXT;
    BEGIN
        FOR v_table_name IN
            SELECT tablename
            FROM pg_tables
            WHERE schemaname = 'dwh_training'
            LOOP
                EXECUTE format('DROP TABLE IF EXISTS dwh_training.%I CASCADE', v_table_name);
                RAISE NOTICE 'Удалена таблица: %', v_table_name;
            END LOOP;
    END $$;


-- 1. Таблица покупателей (Customers)
CREATE TABLE IF NOT EXISTS customers (
                                         customer_id SERIAL PRIMARY KEY,
                                         first_name VARCHAR(50) NOT NULL,
                                         last_name VARCHAR(50) NOT NULL,
                                         email VARCHAR(100) UNIQUE NOT NULL,
                                         phone VARCHAR(20),
                                         city VARCHAR(50),
                                         country VARCHAR(50) DEFAULT 'Россия',
                                         registration_date DATE DEFAULT CURRENT_DATE,
                                         customer_segment VARCHAR(30) CHECK (customer_segment IN ('VIP', 'Standard', 'Basic')),
                                         total_purchases DECIMAL(15,2) DEFAULT 0,
                                         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                         updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Таблица продавцов (Sellers)
CREATE TABLE IF NOT EXISTS sellers (
                                       seller_id SERIAL PRIMARY KEY,
                                       seller_name VARCHAR(100) NOT NULL,
                                       email VARCHAR(100) UNIQUE NOT NULL,
                                       phone VARCHAR(20),
                                       department VARCHAR(50),
                                       hire_date DATE NOT NULL,
                                       salary DECIMAL(10,2),
                                       commission_rate DECIMAL(5,2) DEFAULT 0.05,
                                       region VARCHAR(50),
                                       is_active BOOLEAN DEFAULT TRUE,
                                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Таблица продуктов (Products)
CREATE TABLE IF NOT EXISTS products (
                                        product_id SERIAL PRIMARY KEY,
                                        product_name VARCHAR(200) NOT NULL,
                                        category VARCHAR(100) NOT NULL,
                                        subcategory VARCHAR(100),
                                        brand VARCHAR(100),
                                        supplier VARCHAR(100),
                                        cost_price DECIMAL(10,2) NOT NULL CHECK (cost_price > 0),
                                        retail_price DECIMAL(10,2) NOT NULL CHECK (retail_price > 0),
                                        margin DECIMAL(10,2) GENERATED ALWAYS AS (retail_price - cost_price) STORED,
                                        margin_percent DECIMAL(5,2) GENERATED ALWAYS AS (
                                            CASE
                                                WHEN cost_price > 0 THEN ((retail_price - cost_price) / cost_price * 100)
                                                ELSE 0
                                                END
                                            ) STORED,
                                        stock_quantity INTEGER DEFAULT 0,
                                        min_stock_level INTEGER DEFAULT 10,
                                        is_active BOOLEAN DEFAULT TRUE,
                                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Таблица продаж (Sales) - основная транзакционная таблица
CREATE TABLE IF NOT EXISTS sales (
                                     sale_id SERIAL PRIMARY KEY,
                                     sale_date DATE NOT NULL,
                                     sale_time TIME,
                                     customer_id INTEGER REFERENCES customers(customer_id) ON DELETE SET NULL,
                                     seller_id INTEGER REFERENCES sellers(seller_id) ON DELETE SET NULL,
                                     product_id INTEGER REFERENCES products(product_id) ON DELETE RESTRICT,
                                     quantity INTEGER NOT NULL CHECK (quantity > 0),
                                     unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),
                                     discount DECIMAL(5,2) DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
                                     total_amount DECIMAL(15,2) GENERATED ALWAYS AS (
                                         quantity * unit_price * (1 - discount/100)
                                         ) STORED,
                                     cost_amount DECIMAL(15,2),
                                     profit DECIMAL(15,2) GENERATED ALWAYS AS (
                                         (quantity * unit_price * (1 - discount/100)) - cost_amount
                                         ) STORED,
                                     payment_method VARCHAR(30) CHECK (payment_method IN ('Cash', 'Card', 'Online', 'Invoice')),
                                     order_status VARCHAR(30) DEFAULT 'Completed' CHECK (
                                         order_status IN ('Pending', 'Processing', 'Completed', 'Cancelled', 'Refunded')
                                         ),
                                     invoice_number VARCHAR(50) UNIQUE,
                                     notes TEXT,
                                     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Таблица возвратов (Returns) - для анализа качества продаж
CREATE TABLE IF NOT EXISTS returns (
                                       return_id SERIAL PRIMARY KEY,
                                       sale_id INTEGER REFERENCES sales(sale_id) ON DELETE CASCADE,
                                       return_date DATE DEFAULT CURRENT_DATE,
                                       return_reason VARCHAR(100) CHECK (
                                           return_reason IN ('Defective', 'Wrong Item', 'Size Issue', 'Color Issue', 'Customer Changed Mind', 'Late Delivery')
                                           ),
                                       quantity INTEGER NOT NULL CHECK (quantity > 0),
                                       refund_amount DECIMAL(15,2),
                                       refund_method VARCHAR(30) CHECK (refund_method IN ('Cash', 'Card', 'Credit', 'Exchange')),
                                       processed_by INTEGER REFERENCES sellers(seller_id),
                                       notes TEXT,
                                       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Таблица промо-акций (Promotions) - для анализа эффективности акций
CREATE TABLE IF NOT EXISTS promotions (
                                          promotion_id SERIAL PRIMARY KEY,
                                          promotion_name VARCHAR(200) NOT NULL,
                                          promotion_type VARCHAR(50) CHECK (promotion_type IN ('Discount', 'BOGO', 'Bundle', 'Cashback', 'Loyalty')),
                                          product_id INTEGER REFERENCES products(product_id),
                                          discount_percent DECIMAL(5,2) CHECK (discount_percent >= 0 AND discount_percent <= 100),
                                          start_date DATE NOT NULL,
                                          end_date DATE NOT NULL,
                                          min_purchase_amount DECIMAL(10,2) DEFAULT 0,
                                          max_discount_amount DECIMAL(10,2),
                                          is_active BOOLEAN DEFAULT TRUE,
                                          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                          CHECK (end_date >= start_date)
);

-- 7. Таблица связи продаж с промо-акциями
CREATE TABLE IF NOT EXISTS sale_promotions (
                                               sale_promotion_id SERIAL PRIMARY KEY,
                                               sale_id INTEGER REFERENCES sales(sale_id) ON DELETE CASCADE,
                                               promotion_id INTEGER REFERENCES promotions(promotion_id) ON DELETE CASCADE,
                                               discount_applied DECIMAL(10,2),
                                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                               UNIQUE(sale_id, promotion_id)
);

-- Индексы для таблицы customers
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_city ON customers(city);
CREATE INDEX IF NOT EXISTS idx_customers_segment ON customers(customer_segment);

-- Индексы для таблицы sellers
CREATE INDEX IF NOT EXISTS idx_sellers_region ON sellers(region);
CREATE INDEX IF NOT EXISTS idx_sellers_active ON sellers(is_active);

-- Индексы для таблицы products
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);

-- Индексы для таблицы sales (самая важная для оптимизации)
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_seller ON sales(seller_id);
CREATE INDEX IF NOT EXISTS idx_sales_product ON sales(product_id);
CREATE INDEX IF NOT EXISTS idx_sales_status ON sales(order_status);
CREATE INDEX IF NOT EXISTS idx_sales_date_customer ON sales(sale_date, customer_id);

-- Индексы для таблицы returns
CREATE INDEX IF NOT EXISTS idx_returns_date ON returns(return_date);
CREATE INDEX IF NOT EXISTS idx_returns_reason ON returns(return_reason);

-- Индексы для таблицы promotions
CREATE INDEX IF NOT EXISTS idx_promotions_dates ON promotions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_promotions_active ON promotions(is_active);


-- Триггер для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Применяем триггер к таблицам
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Триггер для автоматического расчета cost_amount при вставке продажи
CREATE OR REPLACE FUNCTION calculate_sale_cost()
    RETURNS TRIGGER AS $$
BEGIN
    -- Получаем себестоимость продукта
    SELECT cost_price INTO NEW.cost_amount
    FROM products
    WHERE product_id = NEW.product_id;

    -- Умножаем на количество
    NEW.cost_amount = NEW.cost_amount * NEW.quantity;

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trg_calculate_sale_cost
    BEFORE INSERT OR UPDATE OF product_id, quantity ON sales
    FOR EACH ROW EXECUTE FUNCTION calculate_sale_cost();

-- Триггер для обновления total_purchases покупателя
CREATE OR REPLACE FUNCTION update_customer_total_purchases()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE customers
        SET total_purchases = total_purchases + NEW.total_amount
        WHERE customer_id = NEW.customer_id;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE customers
        SET total_purchases = total_purchases - OLD.total_amount + NEW.total_amount
        WHERE customer_id = NEW.customer_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE customers
        SET total_purchases = total_purchases - OLD.total_amount
        WHERE customer_id = OLD.customer_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trg_update_customer_total
    AFTER INSERT OR UPDATE OF total_amount OR DELETE ON sales
    FOR EACH ROW EXECUTE FUNCTION update_customer_total_purchases();


-- 1. Заполняем таблицу покупателей
INSERT INTO customers (first_name, last_name, email, phone, city, customer_segment, registration_date)
VALUES ('Иван', 'Иванов', 'ivanov@mail.com', '+79161234567', 'Москва', 'VIP', '2022-01-15'),
       ('Мария', 'Петрова', 'petrova@mail.com', '+79162345678', 'Санкт-Петербург', 'Standard', '2022-03-20'),
       ('Алексей', 'Сидоров', 'sidorov@mail.com', '+79163456789', 'Екатеринбург', 'Standard', '2022-05-10'),
       ('Елена', 'Кузнецова', 'kuznetsova@mail.com', '+79164567890', 'Новосибирск', 'VIP', '2022-02-28'),
       ('Дмитрий', 'Васильев', 'vasiliev@mail.com', '+79165678901', 'Казань', 'Basic', '2022-07-05'),
       ('Ольга', 'Николаева', 'nikolaeva@mail.com', '+79166789012', 'Ростов-на-Дону', 'Standard', '2022-04-12'),
       ('Сергей', 'Федоров', 'fedorov@mail.com', '+79167890123', 'Краснодар', 'Basic', '2022-06-30'),
       ('Анна', 'Морозова', 'morozova@mail.com', '+79168901234', 'Воронеж', 'VIP', '2022-08-15'),
       ('Павел', 'Волков', 'volkov@mail.com', '+79169012345', 'Самара', 'Standard', '2022-09-20'),
       ('Юлия', 'Алексеева', 'alekseeva@mail.com', '+79160123456', 'Уфа', 'Basic', '2022-11-25');

-- 2. Заполняем таблицу продавцов
INSERT INTO sellers (seller_name, email, phone, department, hire_date, salary, region)
VALUES ('Александр Белов', 'belov@company.com', '+79161111111', 'Электроника', '2020-03-15', 85000, 'Центральный'),
       ('Екатерина Смирнова', 'smirnova@company.com', '+79162222222', 'Бытовая техника', '2021-06-20', 75000,
        'Северо-Западный'),
       ('Максим Орлов', 'orlov@company.com', '+79163333333', 'Спорттовары', '2019-11-10', 90000, 'Приволжский'),
       ('Наталья Зайцева', 'zaitseva@company.com', '+79164444444', 'Одежда', '2022-01-05', 70000, 'Южный'),
       ('Артем Павлов', 'pavlov@company.com', '+79165555555', 'Электроника', '2020-08-30', 82000, 'Уральский'),
       ('Виктория Семенова', 'semenova@company.com', '+79166666666', 'Мебель', '2021-02-14', 78000, 'Сибирский'),
       ('Игорь Голубев', 'golubev@company.com', '+79167777777', 'Спорттовары', '2018-09-25', 95000, 'Центральный'),
       ('Татьяна Виноградова', 'vinogradova@company.com', '+79168888888', 'Одежда', '2022-04-18', 72000,
        'Северо-Западный'),
       ('Роман Ковалев', 'kovalev@company.com', '+79169999999', 'Электроника', '2019-05-22', 88000, 'Приволжский'),
       ('Светлана Лебедева', 'lebedeva@company.com', '+79160000000', 'Бытовая техника', '2020-12-03', 80000, 'Южный');

-- 3. Заполняем таблицу продуктов
INSERT INTO products (product_name, category, subcategory, brand, supplier, cost_price, retail_price, stock_quantity)
VALUES ('Ноутбук ASUS VivoBook', 'Электроника', 'Ноутбуки', 'ASUS', 'DigitalTech', 45000, 59990, 25),
       ('Смартфон Samsung Galaxy S23', 'Электроника', 'Смартфоны', 'Samsung', 'MobileWorld', 65000, 84990, 40),
       ('Холодильник Bosch Serie 6', 'Бытовая техника', 'Холодильники', 'Bosch', 'HomeTech', 55000, 72990, 15),
       ('Телевизор LG OLED 55"', 'Электроника', 'Телевизоры', 'LG', 'DigitalTech', 80000, 109990, 12),
       ('Кроссовки Nike Air Max', 'Одежда и обувь', 'Обувь', 'Nike', 'SportStyle', 5000, 8990, 100),
       ('Фитнес-браслет Xiaomi Mi Band', 'Спорттовары', 'Гаджеты', 'Xiaomi', 'ActiveLife', 1500, 2990, 200),
       ('Диван угловой Milano', 'Мебель', 'Мягкая мебель', 'IKEA', 'ComfortHome', 30000, 44990, 8),
       ('Кофемашина DeLonghi Magnifica', 'Бытовая техника', 'Кофемашины', 'DeLonghi', 'HomeTech', 25000, 34990, 20),
       ('Куртка зимняя The North Face', 'Одежда и обувь', 'Верхняя одежда', 'The North Face', 'OutdoorGear', 12000,
        19990, 35),
       ('Велосипед горный Stels Navigator', 'Спорттовары', 'Велосипеды', 'Stels', 'ActiveLife', 18000, 25990, 10),
       ('Наушники Sony WH-1000XM4', 'Электроника', 'Аксессуары', 'Sony', 'DigitalTech', 22000, 29990, 50),
       ('Микроволновка Panasonic NN-ST', 'Бытовая техника', 'Микроволновки', 'Panasonic', 'HomeTech', 7000, 9990, 30),
       ('Рюкзак Deuter Futura', 'Спорттовары', 'Туризм', 'Deuter', 'OutdoorGear', 4000, 6990, 60),
       ('Джинсы Levi''s 501', 'Одежда и обувь', 'Джинсы', 'Levi''s', 'FashionLine', 3500, 5990, 80),
       ('Монитор Dell 27" 4K', 'Электроника', 'Мониторы', 'Dell', 'DigitalTech', 28000, 37990, 18);

-- 4. Заполняем таблицу промо-акций
INSERT INTO promotions (promotion_name, promotion_type, product_id, discount_percent, start_date, end_date,
                        min_purchase_amount)
VALUES ('Летняя распродажа электроники', 'Discount', NULL, 15, '2024-06-01', '2024-08-31', 0),
       ('Черная пятница - смартфоны', 'Discount', 2, 20, '2024-11-25', '2024-11-30', 0),
       ('Купи 2 - получи скидку 25%', 'BOGO', 5, 25, '2024-05-01', '2024-12-31', 0),
       ('Акция на бытовую технику', 'Bundle', 3, 10, '2024-03-01', '2024-12-31', 50000),
       ('Кэшбэк 5% на всё', 'Cashback', NULL, 5, '2024-01-01', '2024-12-31', 10000),
       ('Новогодние скидки', 'Discount', NULL, 10, '2024-12-15', '2025-01-15', 0),
       ('Акция для VIP клиентов', 'Loyalty', NULL, 15, '2024-01-01', '2024-12-31', 0);

-- 5. Заполняем таблицу продаж (генерируем продажи за последние 6 месяцев)
TRUNCATE TABLE sales CASCADE;----
-- Сначала создадим продажи для каждого менеджера и поставщика
-- 1. Сначала очистим таблицы если нужно
INSERT INTO sales (
    sale_date, sale_time, customer_id, seller_id, product_id,
    quantity, unit_price, discount, payment_method, order_status, invoice_number
)
WITH manager_sales AS (
    SELECT
        s.seller_id,
        p.product_id,
        p.retail_price,
        'INV-MGR-' || LPAD(s.seller_id::text, 3, '0') || '-' ||
        LPAD(row_number() OVER (PARTITION BY s.seller_id ORDER BY random())::text, 3, '0') as invoice_number
    FROM sellers s
             CROSS JOIN generate_series(1, 3) as gs
             CROSS JOIN LATERAL (
        SELECT product_id, retail_price
        FROM products
        ORDER BY random()
        LIMIT 1
        ) p
    WHERE s.is_active = TRUE
)
SELECT
            CURRENT_DATE - (random() * 180)::integer as sale_date,
            TIME '09:00' + (random() * 12 * 60 * 60) * INTERVAL '1 second' as sale_time,
            (SELECT customer_id FROM customers ORDER BY random() LIMIT 1) as customer_id,
            ms.seller_id,
            ms.product_id,
            (1 + floor(random() * 2))::integer as quantity,
            ms.retail_price * (0.9 + random() * 0.2) as unit_price,
            floor(random() * 20)::integer as discount,
            CASE floor(random() * 3)
                WHEN 0 THEN 'Cash'
                WHEN 1 THEN 'Card'
                ELSE 'Online'
                END as payment_method,
            CASE
                WHEN random() > 0.1 THEN 'Completed'
                ELSE (ARRAY['Pending', 'Processing', 'Cancelled'])[floor(random() * 3)::integer + 1]
                END as order_status,
            ms.invoice_number
FROM manager_sales ms;

-- Часть 2: Гарантированные продажи для каждого поставщика через продукты
INSERT INTO sales (
    sale_date, sale_time, customer_id, seller_id, product_id,
    quantity, unit_price, discount, payment_method, order_status, invoice_number
)
WITH supplier_sales AS (
    SELECT
        p.product_id,
        p.retail_price,
        p.supplier,
        'INV-SUP-' || REPLACE(p.supplier, ' ', '_') || '-' ||
        LPAD(row_number() OVER (PARTITION BY p.supplier ORDER BY random())::text, 3, '0') as invoice_number
    FROM products p
             CROSS JOIN generate_series(1, 2) as gs
    WHERE p.supplier IS NOT NULL
)
SELECT
            CURRENT_DATE - (random() * 180)::integer as sale_date,
            TIME '09:00' + (random() * 12 * 60 * 60) * INTERVAL '1 second' as sale_time,
            (SELECT customer_id FROM customers ORDER BY random() LIMIT 1) as customer_id,
            (SELECT seller_id FROM sellers ORDER BY random() LIMIT 1) as seller_id,
            ss.product_id,
            (1 + floor(random() * 2))::integer as quantity,
            ss.retail_price * (0.9 + random() * 0.2) as unit_price,
            floor(random() * 20)::integer as discount,
            CASE floor(random() * 3)
                WHEN 0 THEN 'Cash'
                WHEN 1 THEN 'Card'
                ELSE 'Online'
                END as payment_method,
            CASE
                WHEN random() > 0.1 THEN 'Completed'
                ELSE (ARRAY['Pending', 'Processing', 'Cancelled'])[floor(random() * 3)::integer + 1]
                END as order_status,
            ss.invoice_number
FROM supplier_sales ss;

-- Часть 3: Дополнительные случайные продажи для объема
INSERT INTO sales (
    sale_date, sale_time, customer_id, seller_id, product_id,
    quantity, unit_price, discount, payment_method, order_status, invoice_number
)
SELECT
            CURRENT_DATE - (random() * 180)::integer as sale_date,
            TIME '09:00' + (random() * 12 * 60 * 60) * INTERVAL '1 second' as sale_time,
            c.customer_id,
            sel.seller_id,
            p.product_id,
            (1 + floor(random() * 2))::integer as quantity,
            p.retail_price * (0.9 + random() * 0.2) as unit_price,
            floor(random() * 20)::integer as discount,
            CASE floor(random() * 3)
                WHEN 0 THEN 'Cash'
                WHEN 1 THEN 'Card'
                ELSE 'Online'
                END as payment_method,
            CASE
                WHEN random() > 0.1 THEN 'Completed'
                ELSE (ARRAY['Pending', 'Processing', 'Cancelled'])[floor(random() * 3)::integer + 1]
                END as order_status,
            'INV-RND-' || LPAD(row_number() OVER (ORDER BY random())::text, 6, '0') as invoice_number
FROM generate_series(1, 400) as gs
         CROSS JOIN LATERAL (
    SELECT customer_id FROM customers ORDER BY random() LIMIT 1
    ) c
         CROSS JOIN LATERAL (
    SELECT seller_id FROM sellers ORDER BY random() LIMIT 1
    ) sel
         CROSS JOIN LATERAL (
    SELECT product_id, retail_price FROM products ORDER BY random() LIMIT 1
    ) p;

-- 3. Заполняем таблицу возвратов (5% от продаж)
INSERT INTO returns (sale_id, return_date, return_reason, quantity, refund_amount, refund_method, processed_by)
SELECT
    s.sale_id,
    s.sale_date + (1 + random() * 14)::integer, -- Возврат в течение 2 недель
    (CASE floor(random() * 5)
         WHEN 0 THEN 'Defective'
         WHEN 1 THEN 'Wrong Item'
         WHEN 2 THEN 'Size Issue'
         WHEN 3 THEN 'Color Issue'
         ELSE 'Customer Changed Mind'
        END) as return_reason,
    LEAST(s.quantity, (1 + floor(random() * s.quantity))::integer) as quantity, -- Возврат части или всей покупки
    s.total_amount * (0.5 + random() * 0.5) as refund_amount, -- Возврат 50-100% суммы
    (CASE floor(random() * 3)
         WHEN 0 THEN 'Cash'
         WHEN 1 THEN 'Card'
         ELSE 'Credit'
        END) as refund_method,
    (SELECT seller_id FROM sellers ORDER BY random() LIMIT 1) as processed_by
FROM sales s
WHERE s.order_status = 'Completed'
  AND random() < 0.05 -- 5% возвратов от выполненных заказов
LIMIT 25;


-- 7. Связываем некоторые продажи с промо-акциями
-- Вариант 1: Используем существующие даты и подгоняем акции
-- Обновляем даты продаж на 2024 год
UPDATE sales
SET sale_date = DATE '2024-06-01' + (random() * 180)::integer
WHERE sale_id IN (
    SELECT sale_id
    FROM sales
    ORDER BY random()
    LIMIT 300  -- 300 продаж в период акций
);

-- Добавляем продажи за разные периоды 2024 года
UPDATE sales
SET sale_date = DATE '2024-11-25' + (random() * 5)::integer
WHERE sale_id IN (
    SELECT sale_id
    FROM sales
    WHERE sale_id NOT IN (
        SELECT sale_id FROM sales WHERE EXTRACT(YEAR FROM sale_date) = 2024
    )
    ORDER BY random()
    LIMIT 50  -- 50 продаж в Черную пятницу
);

UPDATE sales
SET sale_date = DATE '2024-12-20' + (random() * 25)::integer
WHERE sale_id IN (
    SELECT sale_id
    FROM sales
    WHERE sale_id NOT IN (
        SELECT sale_id FROM sales WHERE EXTRACT(YEAR FROM sale_date) = 2024
    )
    ORDER BY random()
    LIMIT 50  -- 50 продаж в новогодний период
);

-- Теперь связываем продажи с акциями
INSERT INTO sale_promotions (sale_id, promotion_id, discount_applied)
SELECT
    s.sale_id,
    p.promotion_id,
    CASE
        WHEN p.promotion_type = 'BOGO' THEN
            -- Для BOGO: скидка применяется только если количество >= 2
            CASE WHEN s.quantity >= 2 THEN s.total_amount * p.discount_percent / 100 ELSE 0 END
        ELSE s.total_amount * p.discount_percent / 100
        END as discount_applied
FROM sales s
         CROSS JOIN promotions p
WHERE s.order_status = 'Completed'
  AND p.is_active = TRUE
  AND s.sale_date BETWEEN p.start_date AND p.end_date
  AND (
    -- Для акций с минимальной суммой
    (p.min_purchase_amount > 0 AND s.total_amount >= p.min_purchase_amount)
        OR
        -- Для акций без минимальной суммы
    (p.min_purchase_amount = 0 OR p.min_purchase_amount IS NULL)
    )
  AND (
    -- Для акций на конкретный товар
    (p.product_id IS NOT NULL AND s.product_id = p.product_id)
        OR
        -- Для общих акций
    (p.product_id IS NULL)
    )
  AND random() < 0.4  -- 40% продаж с акциями
LIMIT 150;

-- Проверяем результат
SELECT
    p.promotion_name,
    COUNT(sp.sale_promotion_id) as applied_count,
    SUM(sp.discount_applied) as total_discount
FROM sale_promotions sp
         JOIN promotions p ON sp.promotion_id = p.promotion_id
GROUP BY p.promotion_id, p.promotion_name
ORDER BY applied_count DESC;





-- Проверяем статистику
SELECT
    'Всего продаж' as metric,
    COUNT(*) as value
FROM sales

UNION ALL

SELECT
    'Продаж на менеджера (среднее)',
    ROUND(COUNT(*)::numeric / COUNT(DISTINCT seller_id), 1)
FROM sales

UNION ALL

SELECT
    'Уникальных менеджеров с продажами',
    COUNT(DISTINCT seller_id)
FROM sales

UNION ALL

SELECT
    'Уникальных поставщиков с продажами',
    COUNT(DISTINCT p.supplier)
FROM sales s
         JOIN products p ON s.product_id = p.product_id

UNION ALL

SELECT
    'Возвраты',
    COUNT(*)
FROM returns;



-- Проверка целостности данных и связей
SELECT 'Покупатели' as table_name, COUNT(*) as row_count FROM customers
UNION ALL
SELECT 'Продавцы', COUNT(*) FROM sellers
UNION ALL
SELECT 'Продукты', COUNT(*) FROM products
UNION ALL
SELECT 'Продажи', COUNT(*) FROM sales
UNION ALL
SELECT 'Возвраты', COUNT(*) FROM returns
UNION ALL
SELECT 'Промо-акции', COUNT(*) FROM promotions
UNION ALL
SELECT 'Связи продаж с акциями', COUNT(*) FROM sale_promotions
ORDER BY table_name;



-- Добавляем поле для уровня должности и ссылку на руководителя
ALTER TABLE sellers
    ADD COLUMN IF NOT EXISTS position_level INTEGER CHECK (position_level BETWEEN 1 AND 4),
    ADD COLUMN IF NOT EXISTS manager_id INTEGER REFERENCES sellers(seller_id),
    ADD COLUMN IF NOT EXISTS position_title VARCHAR(50);

-- Комментарии к полям
COMMENT ON COLUMN sellers.position_level IS '1 - Директор, 2 - Руководитель отдела, 3 - Менеджер, 4 - Стажер';
COMMENT ON COLUMN sellers.manager_id IS 'ID непосредственного руководителя';
COMMENT ON COLUMN sellers.position_title IS 'Название должности';

-- Вставляем директора
INSERT INTO sellers (seller_name, email, phone, department, hire_date, salary,
                     commission_rate, region, position_level, position_title, manager_id)
VALUES
    ('Сергей Николаев', 'nikolaev@company.com', '+79161110001', 'Администрация',
     '2018-01-15', 250000, 0.1, 'Москва', 1, 'Директор по продажам', NULL);

-- Вставляем руководителей отделов
INSERT INTO sellers (seller_name, email, phone, department, hire_date, salary,
                     commission_rate, region, position_level, position_title, manager_id)
VALUES
    ('Анна Воронова', 'voronova@company.com', '+79161110002', 'Электроника',
     '2019-03-10', 180000, 0.08, 'Москва', 2, 'Руководитель отдела', 11),
    ('Дмитрий Соловьев', 'soloviev@company.com', '+79161110003', 'Бытовая техника',
     '2019-06-20', 170000, 0.08, 'Санкт-Петербург', 2, 'Руководитель отдела', 11),
    ('Павел Гришин', 'grishin@company.com', '+79161110004', 'Спорттовары',
     '2018-11-05', 190000, 0.08, 'Екатеринбург', 2, 'Руководитель отдела', 11),
    ('Ольга Медведева', 'medvedeva@company.com', '+79161110005', 'Одежда',
     '2020-02-15', 160000, 0.08, 'Ростов-на-Дону', 2, 'Руководитель отдела', 11),
    ('Илья Тихонов', 'tikhonov@company.com', '+79161110006', 'Мебель',
     '2019-09-25', 165000, 0.08, 'Новосибирск', 2, 'Руководитель отдела', 11);

-- Обновляем существующих менеджеров, назначаем им руководителей отделов
UPDATE sellers
SET
    position_level = 3,
    position_title = CASE
                         WHEN department = 'Электроника' THEN 'Менеджер по продажам'
                         WHEN department = 'Бытовая техника' THEN 'Менеджер по продажам'
                         WHEN department = 'Спорттовары' THEN 'Менеджер по продажам'
                         WHEN department = 'Одежда' THEN 'Менеджер по продажам'
                         WHEN department = 'Мебель' THEN 'Менеджер по продажам'
                         ELSE 'Менеджер'
        END,
    manager_id = CASE
                     WHEN department = 'Электроника' THEN 12 -- Анна Воронова
                     WHEN department = 'Бытовая техника' THEN 13 -- Дмитрий Соловьев
                     WHEN department = 'Спорттовары' THEN 14 -- Павел Гришин
                     WHEN department = 'Одежда' THEN 15 -- Ольга Медведева
                     WHEN department = 'Мебель' THEN 16 -- Илья Тихонов
                     ELSE NULL
        END
WHERE seller_id BETWEEN 1 AND 10;



-- Удаляем представление если существует
DROP VIEW IF EXISTS v_employee_hierarchy CASCADE;

-- Создаем заново с явным приведением типов ВЕЗДЕ
CREATE OR REPLACE VIEW v_employee_hierarchy AS
WITH RECURSIVE employee_tree AS (
    -- Начинаем с директора (уровень 1) - ВСЕ поля как TEXT
    SELECT
        seller_id,
        seller_name::TEXT,
        email::TEXT,
        department::TEXT,
        position_level,
        position_title::TEXT,
        manager_id,
        salary,
        1 as hierarchy_level,
        ARRAY[seller_name::TEXT] as path,
        seller_name::TEXT as hierarchy_path
    FROM sellers
    WHERE position_level = 1 AND is_active = TRUE

    UNION ALL

    -- Добавляем подчиненных - ТАКИЕ ЖЕ типы
    SELECT
        s.seller_id,
        s.seller_name::TEXT,
        s.email::TEXT,
        s.department::TEXT,
        s.position_level,
        s.position_title::TEXT,
        s.manager_id,
        s.salary,
        et.hierarchy_level + 1,
        et.path || s.seller_name::TEXT,
        et.hierarchy_path || ' → ' || s.seller_name
    FROM sellers s
             INNER JOIN employee_tree et ON s.manager_id = et.seller_id
    WHERE s.is_active = TRUE
)
SELECT
    seller_id,
    seller_name,
    email,
    department,
    position_level,
    position_title,
    manager_id,
    salary,
    hierarchy_level,
    path,
    hierarchy_path
FROM employee_tree
ORDER BY path;


select *
from v_employee_hierarchy


--- 1. Создадим схемы и таблицы DWH
-- Создаем схему DWH если её нет
CREATE SCHEMA IF NOT EXISTS dwh;

-- Создаем таблицы DWH (разделим на Staging, Core и Marts)

-- 1.1 Staging таблицы (полная копия из OLTP)
CREATE TABLE IF NOT EXISTS dwh.stg_customers (
                                                 customer_id INTEGER PRIMARY KEY,
                                                 first_name VARCHAR(50),
                                                 last_name VARCHAR(50),
                                                 email VARCHAR(100),
                                                 phone VARCHAR(20),
                                                 city VARCHAR(50),
                                                 country VARCHAR(50),
                                                 registration_date DATE,
                                                 customer_segment VARCHAR(30),
                                                 total_purchases DECIMAL(15,2),
                                                 created_at TIMESTAMP,
                                                 updated_at TIMESTAMP,
                                                 load_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS dwh.stg_products (
                                                product_id INTEGER PRIMARY KEY,
                                                product_name VARCHAR(200),
                                                category VARCHAR(100),
                                                subcategory VARCHAR(100),
                                                brand VARCHAR(100),
                                                supplier VARCHAR(100),
                                                cost_price DECIMAL(10,2),
                                                retail_price DECIMAL(10,2),
                                                margin DECIMAL(10,2),
                                                margin_percent DECIMAL(5,2),
                                                stock_quantity INTEGER,
                                                min_stock_level INTEGER,
                                                is_active BOOLEAN,
                                                created_at TIMESTAMP,
                                                updated_at TIMESTAMP,
                                                load_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS dwh.stg_sales (
                                             sale_id INTEGER PRIMARY KEY,
                                             sale_date DATE,
                                             sale_time TIME,
                                             customer_id INTEGER,
                                             seller_id INTEGER,
                                             product_id INTEGER,
                                             quantity INTEGER,
                                             unit_price DECIMAL(10,2),
                                             discount DECIMAL(5,2),
                                             total_amount DECIMAL(15,2),
                                             cost_amount DECIMAL(15,2),
                                             profit DECIMAL(15,2),
                                             payment_method VARCHAR(30),
                                             order_status VARCHAR(30),
                                             invoice_number VARCHAR(50),
                                             notes TEXT,
                                             created_at TIMESTAMP,
                                             load_date DATE DEFAULT CURRENT_DATE
);

-- 1.2 Core таблицы (инкрементальная загрузка с SCD)
CREATE TABLE IF NOT EXISTS dwh.dim_customers (
                                                 customer_key SERIAL PRIMARY KEY,
                                                 customer_id INTEGER NOT NULL,
                                                 first_name VARCHAR(50),
                                                 last_name VARCHAR(50),
                                                 email VARCHAR(100),
                                                 phone VARCHAR(20),
                                                 city VARCHAR(50),
                                                 country VARCHAR(50),
                                                 registration_date DATE,
                                                 customer_segment VARCHAR(30),
                                                 current_total_purchases DECIMAL(15,2),
                                                 start_date DATE NOT NULL,
                                                 end_date DATE,
                                                 is_current BOOLEAN DEFAULT TRUE,
                                                 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh.dim_products (
                                                product_key SERIAL PRIMARY KEY,
                                                product_id INTEGER NOT NULL,
                                                product_name VARCHAR(200),
                                                category VARCHAR(100),
                                                subcategory VARCHAR(100),
                                                brand VARCHAR(100),
                                                supplier VARCHAR(100),
                                                cost_price DECIMAL(10,2),
                                                retail_price DECIMAL(10,2),
                                                current_margin_percent DECIMAL(5,2),
                                                is_active BOOLEAN,
                                                start_date DATE NOT NULL,
                                                end_date DATE,
                                                is_current BOOLEAN DEFAULT TRUE,
                                                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh.dim_sellers (
                                               seller_key SERIAL PRIMARY KEY,
                                               seller_id INTEGER NOT NULL,
                                               seller_name VARCHAR(100),
                                               email VARCHAR(100),
                                               phone VARCHAR(20),
                                               department VARCHAR(50),
                                               position_title VARCHAR(50),
                                               position_level INTEGER,
                                               manager_id INTEGER,
                                               region VARCHAR(50),
                                               is_active BOOLEAN,
                                               start_date DATE NOT NULL,
                                               end_date DATE,
                                               is_current BOOLEAN DEFAULT TRUE,
                                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                               updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dwh.dim_date (
                                            date_key INTEGER PRIMARY KEY,
                                            full_date DATE NOT NULL,
                                            year INTEGER NOT NULL,
                                            quarter INTEGER NOT NULL,
                                            month INTEGER NOT NULL,
                                            month_name VARCHAR(20) NOT NULL,
                                            day_of_month INTEGER NOT NULL,
                                            day_of_week INTEGER NOT NULL,
                                            day_name VARCHAR(20) NOT NULL,
                                            is_weekend BOOLEAN NOT NULL,
                                            is_holiday BOOLEAN DEFAULT FALSE,
                                            week_of_year INTEGER NOT NULL
);

-- 1.3 Fact таблица
CREATE TABLE IF NOT EXISTS dwh.fct_sales (
                                             sale_key BIGSERIAL PRIMARY KEY,
                                             date_key INTEGER REFERENCES dwh.dim_date(date_key),
                                             customer_key INTEGER REFERENCES dwh.dim_customers(customer_key),
                                             product_key INTEGER REFERENCES dwh.dim_products(product_key),
                                             seller_key INTEGER REFERENCES dwh.dim_sellers(seller_key),
                                             original_sale_id INTEGER NOT NULL,
                                             sale_date DATE NOT NULL,
                                             sale_time TIME,
                                             quantity INTEGER NOT NULL,
                                             unit_price DECIMAL(10,2) NOT NULL,
                                             discount DECIMAL(5,2) DEFAULT 0,
                                             total_amount DECIMAL(15,2) NOT NULL,
                                             cost_amount DECIMAL(15,2),
                                             profit DECIMAL(15,2) NOT NULL,
                                             payment_method VARCHAR(30),
                                             order_status VARCHAR(30),
                                             load_date DATE DEFAULT CURRENT_DATE,
                                             created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.4 Индексы для производительности
CREATE INDEX IF NOT EXISTS idx_fct_sales_date ON dwh.fct_sales(date_key);
CREATE INDEX IF NOT EXISTS idx_fct_sales_customer ON dwh.fct_sales(customer_key);
CREATE INDEX IF NOT EXISTS idx_fct_sales_product ON dwh.fct_sales(product_key);
CREATE INDEX IF NOT EXISTS idx_fct_sales_seller ON dwh.fct_sales(seller_key);
CREATE INDEX IF NOT EXISTS idx_fct_sales_status ON dwh.fct_sales(order_status);

CREATE INDEX IF NOT EXISTS idx_dim_customers_current ON dwh.dim_customers(customer_id, is_current);
CREATE INDEX IF NOT EXISTS idx_dim_products_current ON dwh.dim_products(product_id, is_current);
CREATE INDEX IF NOT EXISTS idx_dim_sellers_current ON dwh.dim_sellers(seller_id, is_current);


CREATE OR REPLACE PROCEDURE dwh.drop_all_procedures()
    LANGUAGE plpgsql
AS $$
DECLARE
    v_proc_name TEXT;
    v_schema_name TEXT := 'dwh';
BEGIN
    RAISE NOTICE 'Начинаем удаление всех процедур в схеме %...', v_schema_name;

    -- Удаляем все процедуры в схеме dwh
    FOR v_proc_name IN (
        SELECT p.proname
        FROM pg_proc p
                 JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = v_schema_name
          AND p.prokind = 'p'  -- 'p' означает процедуру (вместо функции 'f')
    ) LOOP
            BEGIN
                EXECUTE format('DROP PROCEDURE IF EXISTS %I.%I CASCADE', v_schema_name, v_proc_name);
                RAISE NOTICE 'Удалена процедура: %', v_proc_name;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Не удалось удалить процедуру %: %', v_proc_name, SQLERRM;
            END;
        END LOOP;

    RAISE NOTICE 'Все процедуры в схеме % удалены', v_schema_name;
END;
$$;


----удаляем процедуру по имени процедуры
CREATE OR REPLACE PROCEDURE dwh.drop_procedure_by_name(
    p_procedure_name TEXT
)
    LANGUAGE plpgsql
AS $$
DECLARE
    v_schema_name TEXT := 'dwh';
    v_full_procedure_name TEXT;
    v_exists BOOLEAN;
BEGIN
    RAISE NOTICE 'Попытка удаления процедуры: %', p_procedure_name;

    -- Проверяем существование процедуры
    SELECT EXISTS (
        SELECT 1
        FROM pg_proc p
                 JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = v_schema_name
          AND p.proname = p_procedure_name
          AND p.prokind = 'p'
    ) INTO v_exists;

    IF v_exists THEN
        -- Формируем полное имя процедуры
        v_full_procedure_name := v_schema_name || '.' || p_procedure_name;

        -- Удаляем процедуру
        EXECUTE format('DROP PROCEDURE IF EXISTS %I CASCADE', v_full_procedure_name);
        RAISE NOTICE '✅ Процедура "%" успешно удалена', p_procedure_name;
    ELSE
        RAISE NOTICE '⚠ Процедура "%" не найдена в схеме %', p_procedure_name, v_schema_name;
    END IF;
END;
$$;

----Вызов процедур
CALL dwh.drop_procedure_by_name('sp_run_full_load');
CALL dwh.drop_all_procedures();

