create table aircrafts
(aircraft_code char(3) not null,
model text not null,
range integer not null,
check (range > 0),
primary key (aircraft_code)
);

insert into aircrafts (aircraft_code, model, range)
values ('SU9', 'Sukhoi SuperJet-100', 3000);

SELECT *
FROM aircrafts  



insert into aircrafts (aircraft_code, model, range)
values ('773', 'Boeing 777-300', 11100),
('763', 'Boeing 767-300', 7900),
('733', 'Boeing 737-300', 4200),
('320', 'Airbus A320-200', 5700),
('321', 'Airbus A321-200', 5600),
('319', 'Airbus A319-100', 6700),
('CN1', 'Cessna 208 Caravan', 1200),
('CN2', 'Bombardier CRJ-200', 2700)


SELECT aircraft_code, model, range
FROM aircrafts
ORDER BY model

/*где максимальная дальность полетов в пределах от
 * 4 до 6 тыс. км*/
SELECT aircraft_code, model, range
FROM aircrafts
WHERE RANGE >=400 AND RANGE <=6000
ORDER BY model
/*Суперджет немного улучшили и его характиристик дальности стади 3500*/

UPDATE aircrafts SET RANGE = 3500
WHERE aircraft_code = 'SU9'

/*Удалим информацию о самолетах с дальностью полета более 10000 км
 * а также с дальностью полета менее 3000*/
DELETE 
FROM aircrafts 
WHERE RANGE > 10000 OR RANGE <3000;

SELECT aircraft_code, model, range
FROM aircrafts
ORDER BY model

TRUNCATE TABLE aircrafts;

insert into aircrafts (aircraft_code, model, range)
values ('773', 'Boeing 777-300', 11100),
('763', 'Boeing 767-300', 7900),
('733', 'Boeing 737-300', 4200),
('320', 'Airbus A320-200', 5700),
('321', 'Airbus A321-200', 5600),
('319', 'Airbus A319-100', 6700),
('CN1', 'Cessna 208 Caravan', 1200),
('CN2', 'Bombardier CRJ-200', 2700)

CREATE table seats (
aircraft_code char(3) NOT NULL,
seat_no varchar(4) NOT NULL,
fare_conditions varchar(10) NOT NULL,
CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')
),
PRIMARY KEY (aircraft_code, seat_no),
FOREIGN KEY (aircraft_code)
REFERENCES aircrafts(aircraft_code) ON DELETE cascade
);


INSERT INTO seats 
VALUES 
('SU9', '1A','Business'), 
('SU9', '1B','Business'),
('SU9', '10A','Economy'),
('SU9', '10B','Economy'),
('SU9', '10F','Economy'),
('SU9', '20F','Economy'),

('773', '1A','Business'), 
('773', '1B','Business'),
('773', '10A','Economy'),
('773', '10B','Economy'),
('773', '10F','Economy'),
('773', '20F','Economy'),

('763', '1A','Business'), 
('763', '1B','Business'),
('763', '10A','Economy'),
('763', '10B','Economy'),
('763', '10F','Economy'),
('763', '20F','Economy'),

('733', '1A','Business'), 
('733', '1B','Business'),
('733', '10A','Economy'),
('733', '10B','Economy'),
('733', '10F','Economy'),
('733', '20F','Economy'),

('320', '1A','Business'), 
('320', '1B','Business'),
('320', '10A','Economy'),
('320', '10B','Economy'),
('320', '10F','Economy'),
('320', '20F','Economy'),

('321', '1A','Business'), 
('321', '1B','Business'),
('321', '10A','Economy'),
('321', '10B','Economy'),
('321', '10F','Economy'),
('321', '20F','Economy'),

('319', '1A','Business'), 
('319', '1B','Business'),
('319', '10A','Economy'),
('319', '10B','Economy'),
('319', '10F','Economy'),
('319', '20F','Economy'),

('CN1', '1A','Business'), 
('CN1', '1B','Business'),
('CN1', '10A','Economy'),
('CN1', '10B','Economy'),
('CN1', '10F','Economy'),
('CN1', '20F','Economy'),

('CN2', '1A','Business'), 
('CN2', '1B','Business'),
('CN2', '10A','Economy'),
('CN2', '10B','Economy'),
('CN2', '10F','Economy'),
('CN2', '20F','Economy');


/*Информаця о количестве мест в салонах*/

SELECT count(*) 
FROM seats WHERE aircraft_code = 'SU9'

SELECT count(*) 
FROM seats WHERE aircraft_code = 'CN1'

SELECT aircraft_code, count(*)
FROM seats 
GROUP BY aircraft_code
ORDER BY count;

/*Подсчитать количество мест в салонах для всех моделей самолетов,
 * но теперь с учетом класса обслуживания
 */

SELECT aircraft_code, fare_conditions, count(*)
FROM seats
GROUP BY aircraft_code, fare_conditions
ORDER BY aircraft_code, fare_conditions

/*Типы данных в СУБД
 * Типы данных это одно из базовых понятий любого языка программирования
 * */

/*Числовые типы при выборе конкретного целочислллленного типа принимают
 * во внимание диапазон допувстимых значений и затраты памяти
 * Зачастую integer считается оптималльным выбором с точки зрения 
 * достижения компромисса между этими показателями
 * 
 * nimeric и decimal являются идентичными по своим возможностям
 * для хранения затрачивается больше памяти чем в случае целых чисел
 * ти данных стоит выбирать для хранения денежных сумм и когда требуется
 * соблюдать точность вычислений
 * 
 * представителями типов данных с плавающей точкой служат типы
 * real и double
 * При работе с такими типами данных следует помнить, что 
 * сравнение двух числек с плавающей точкой на предмет их равенства их
 * значений может привести в неожиданным результатам
 * 
 * тип serial удобен в тех случаях когда потребуется в какой-либюо
 * столбец вставить уникальные значения, например значения суррогатного
 * первичного ключа
 * */

SELECT 0.1::REAL * 10 = 1.0::REAL; --- значения не равны


/*Символьные (строкове типы)
 * Стандартные типы character varying(n) и character(n), где
 * n это параметр который указывает на мамксимальное число символов в строке
 * которую можно сохранить в столбце такого тиипа.
 * в character (char)строка дополняется пробелами если строка короче максимальной 
 * длины
 * Также существует тип text - вводятся большие символьные значения 
 * $$ выполняют туже роь что и кавычки когда в них закллючается текстовая константа
 * при использовании $$ в качестве ограничителей уже не нужно удваивать никакие символы,
 * содержащиеся в самой константе.
 */
SELECT $$PGDAY\n17$$

SELECT E'PGDAY\n17'

/*Тип дата время
 * date при вводе значений необходимо заключать даты в одинарные кавычки
 * 
 */
SELECT current_timestamp

SELECT '1 year 2 months ago'::INTERVAL; --- продолжительность отрезка времени
--между двумя моментами времени

/*Вычислим количество дней вычитаем одну дату из другой*/
SELECT('2016-09-16'::timestamp - '2016-09-01'::timestamp)::interval 

/*Можно усекать даты с той или иной точность*/
SELECT(date_trunc('day', current_timestamp))

/*Можно из дат извлекать поля*/
SELECT extract('mon' FROM date_trunc('day', current_timestamp))

/*Логический тип boolean может принимать истина или ложь,
 * а также неопределенное состояние которое можно представить значением
 * null*/

CREATE TABLE databases (is_open_source boolean, dbms_name text);
INSERT INTO databases 
values
(TRUE, 'PostgreSQL'),
(FALSE, 'Oracle'),
(TRUE, 'MySQL'),
(FALSE, 'MS SQL Server')

SELECT *
FROM databases 
WHERE NOT is_open_source


/*Массивы могут быть многомерными и содержать значения
 * любого из встроенных типов а также пользовательских типов данных
 * Массивы переменной длины
 *
 *
 *Например нам необходимо сформировать и сохранить в бд граифик пилотов 
 *авикомпании когда они совершают полеты, сохраним из в БД ввиде массивов
 */
CREATE TABLE pilots 
(
pilot_name text,
schedule integer[] ---указание массива
);

INSERT INTO pilots
VALUES ('Ivan', '{1,3,5,6,7}'::integer[]),
('Petr', '{1,2,5,7}' ::integer[]),
('Pavel','{2,5}'      ::integer[]),
('Boris','{3,5,6}'    ::integer[])

/*Предполложим, что руководство решило, что каждый
 * пилот доллжен летать 4 раза в неделю, значит нам придется добавить
 * пилотам недоставющие дни полета в расписание
 */

/*Павлу добавим один день в конец списка*/

UPDATE pilots
SET schedule = schedule || 7
WHERE pilot_name = 'Boris'

/*Павлу добавил один день в конец списка*/

UPDATE pilots 
SET schedule = array_append(schedule, 6)
WHERE pilot_name = 'Pavel'

/*Павлу добавил один день в начало списка*/

UPDATE pilots 
SET schedule = array_prepend(1, schedule)
WHERE pilot_name = 'Pavel'

/*У пилота Иван имеется один лишний день в графике, удалим один день
 * из графика*/

UPDATE pilots 
SET schedule = array_remove(schedule,5) ---значение эдемента массива
WHERE pilot_name = 'Ivan'

/*У пилота по имени Петр изменим дни полетов не изменяя
 * их общего количества
 *К элементам одного и того же массива можно обращаться по отдельности в 
 *set, как буд-то это разные столбцы
 */

UPDATE pilots
SET schedule[1] = 2, schedule[2] = 3
WHERE pilot_name = 'Petr'

/*Также можно сделать это действие используя срез массива slice*/

UPDATE pilots
SET schedule[1:2] = ARRAY[2,3] ---1 и 2 это индексы первого и послледнего элемента массива
WHERE pilot_name = 'Petr'

/*Основные операции которые можно применять к выборкам из таблиц*/

--список пилотов летающих по средам
SELECT *
FROM pilots
WHERE array_position(schedule, 3) IS NOT NULL
---возвращает индекс первого вхождения элемента с указанным значнием в массив
---если такого элемента нет, то она возвратит null

/*Выберем пилотов летающих по понедельникам и воскресеньям*/
SELECT * 
FROM pilots
WHERE schedule @> '{1,7}'::integer[];---в левом элементе содержатся все элементы правого массива

/*Выберем пилотов, которые летают по вторникам и/или по пятницам*/

SELECT * 
FROM pilots
WHERE schedule && ARRAY[2,5] ---проверяем общие элементы у массива


/*Выберем пилотов, которые не летают по вторникам и/или по пятницам*/
SELECT * 
FROM pilots
WHERE NOT (schedule && ARRAY[2,5]) ---проверяем общие элементы у массива

/*Типы json предназначены для сохранения в столбцах базы данных
 * таких значений которые представлены в формате json и jsonb
 * рекомендуется испоьзовать jsonb если нет особых аргументов
 * к использованию json
 */

CREATE TABLE pilot_hobbies
(
pilot_name text,
hobbies jsonb
);


INSERT INTO pilot_hobbies
VALUES ('Ivan', '{"sports":["футбол","плавание"],
"home_lib": true,"trips":3}'::jsonb),

('Petr', '{"sports":["теннис","плавание"],
"home_lib": true,"trips":2}'::jsonb),

('Pavel', '{"sports":["плавание"],
"home_lib": false,"trips":4}'::jsonb),

('Boris', '{"sports":["плавание","футбол","теннис"],
"home_lib": true,"trips":0}'::jsonb)

/*Предположим, что нам нужно сформировать футбольную командж нашей
 * авакомпании для участия в турнире. Мы можем выбрать всех футболистов
 * таким способом
 * SELECT * - выбирает все столбцы
 * FROM pilot_hobbies - из таблицы pilot_hobbies
 * hobbies -> 'sports' - извлекает значение ключа 'sports' из JSON-поля hobbies
 * @> '["футбол"]'::jsonb - проверяет, содержит ли извлеченное значение массив ["футбол"]
 * */
SELECT *
FROM pilot_hobbies
WHERE hobbies ->'sports' @> '["футбол"]'::jsonb
---операция -> служит для обращения к конкретному ключу json-объекта

/*Проверка используется ли кюч sports
 * SELECT * - выбирает все столбцы из таблицы
FROM pilot_hobbies - из таблицы с именем pilot_hobbies
WHERE hobbies ? 'sports' - фильтрует строки, где JSON-поле hobbies 
содержит ключ 'sports'
*/
SELECT *
FROM pilot_hobbies
WHERE hobbies ? 'sports' 

/*Обновениев json-объектов в строках таблицы
 * Например пилот Борис захотел заниматься только хоккеем
 * 
 * Что делает каждая часть:
 * UPDATE pilot_hobbies - обновляет данные в таблице pilot_hobbies
 * WHERE pilot_name = 'Boris' - только для пилота с именем Boris
 * hobbies = hobbies || '{"sports":["хоккей"]}' - объединяет (merge) существующий 
 * JSON с новым JSON
 * Как работает оператор || (JSON merge):
 * Оператор || объединяет два JSON-документа:
 * Если ключ существует - заменяет значение
 * Если ключа нет - добавляет новый ключ
 */

UPDATE pilot_hobbies
SET hobbies = hobbies || '{"sports":["хоккей"]}'
WHERE pilot_name = 'Boris'

/*Если Борис щазорчет возобновить занятия футболом с помощью
 * функции jsonb_set можно будет обновить сведения о нем в таблице
 * 
 * Что делает каждая часть:
 * jsonb_set(hobbies, '{sports, 1}', '"футбол"') - функция, которая:
 * Берет JSON-поле hobbies
 * Находит путь {sports, 1} (массив sports, индекс 1)
 * Заменяет элемент на значение "футбол"
 * Как работают индексы в JSON массивах:
 * В PostgreSQL индексы массивов начинаются с 0:
 * {sports, 0} - первый элемент
 * {sports, 1} - второй элемент
 * {sports, 2} - третий элемент
 * и т.д.
 */

UPDATE pilot_hobbies
SET hobbies = jsonb_set(hobbies, '{sports, 1}', '"футбол"')
WHERE pilot_name = 'Boris';

/*Текущее значение параметра первый управляет форматом вывода даты, а 
 * второй регуирует порядок следования составных частей даты*/

SELECT to_char(current_timestamp, 'mi:ss')
SELECT to_char(current_timestamp, 'yyyy-mm-dd')
SHOW datestyle

/*На момент выполнения запроса достиг возараста 40 лет*/

CREATE TABLE birthdays(
person text NOT  NULL,
birthday date NOT NULL 
)

INSERT INTO birthdays VALUES 
('Ken Thompson', '1966-03-23'),
('Ben Johnson', '1971-03-19'),
('Andy Gibson', '1987-08-12');

SELECT *, birthday + '40 years'::interval
FROM birthdays
WHERE birthday + '40 years'::INTERVAL < current_timestamp

/*Выберем всех людей родившихся в марте*/
SELECT
	*
FROM
	birthdays
WHERE
	EXTRACT('mon' FROM birthday) = 3;

/*Основы языка определения данных
 * Вставка строк в таблицы, выполнение запросов к ним, обновление,
 * удаление строк из таблиц, создание объектов баз данных*/


/*🎯 Значения по умолчанию (DEFAULT)
Синтаксис:*/
CREATE TABLE table_name (
    column_name data_type DEFAULT default_value
);

-- Простые значения по умолчанию
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    status VARCHAR(20) DEFAULT 'pending',
    login_count INTEGER DEFAULT 0
);

-- Выражения как значения по умолчанию
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_date DATE DEFAULT CURRENT_DATE,
    order_number VARCHAR(20) DEFAULT 'ORD-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' || lpad(nextval('orders_id_seq'::regclass)::text, 6, '0'),
    total_amount DECIMAL(10,2) DEFAULT 0.00
);


/*Добавление DEFAULT к существующей таблице:*/
ALTER TABLE users 
ALTER COLUMN updated_at SET DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE products 
ALTER COLUMN price SET DEFAULT 0.00;



/*🛡️ Ограничения целостности (Constraints)
1. NOT NULL - Запрет NULL значений
sql*/
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NULL  -- явное указание NULL (не обязательно)
);
Добавление NOT NULL:
sql
ALTER TABLE employees 
ALTER COLUMN department SET NOT NULL;
2. UNIQUE - Уникальные значения
sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(50) UNIQUE,
    phone VARCHAR(20) UNIQUE
);

-- Составной UNIQUE
CREATE TABLE user_roles (
    user_id INTEGER,
    role_id INTEGER,
    UNIQUE(user_id, role_id)
);
3. PRIMARY KEY - Первичный ключ
sql
-- Простой первичный ключ
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Составной первичный ключ
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    PRIMARY KEY (order_id, product_id)
);
4. FOREIGN KEY - Внешний ключ
sql
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- С опциями действий
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
Опции FOREIGN KEY:
ON DELETE/UPDATE CASCADE - каскадное удаление/обновление

ON DELETE/UPDATE RESTRICT - запрет удаления/обновления

ON DELETE/UPDATE SET NULL - установить NULL

ON DELETE/UPDATE SET DEFAULT - установить значение по умолчанию

ON DELETE/UPDATE NO ACTION - действие по умолчанию

5. CHECK - Проверочные ограничения
sql
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INTEGER CHECK (age >= 18 AND age <= 65),
    salary DECIMAL(10,2) CHECK (salary > 0),
    email VARCHAR(100) CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    status VARCHAR(20) CHECK (status IN ('active', 'inactive', 'suspended'))
);

-- Именованное CHECK ограничение
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    discount_price DECIMAL(10,2),
    CONSTRAINT valid_price CHECK (price > 0),
    CONSTRAINT valid_discount CHECK (discount_price IS NULL OR discount_price < price)
);
/*🔧 Работа с ограничениями
Просмотр ограничений:
sql*/
-- Все ограничения таблицы
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    consrc as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass;

-- Через information_schema
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users';
Добавление ограничений к существующей таблице:
sql
-- Добавить PRIMARY KEY
ALTER TABLE users ADD PRIMARY KEY (id);

-- Добавить FOREIGN KEY
ALTER TABLE orders 
ADD CONSTRAINT fk_orders_users 
FOREIGN KEY (user_id) REFERENCES users(id);

-- Добавить CHECK
ALTER TABLE employees 
ADD CONSTRAINT chk_employee_age 
CHECK (age BETWEEN 18 AND 65);

-- Добавить UNIQUE
ALTER TABLE users 
ADD CONSTRAINT uk_users_email UNIQUE (email);
Удаление ограничений:
sql
ALTER TABLE table_name DROP CONSTRAINT constraint_name;

-- Пример
ALTER TABLE employees DROP CONSTRAINT chk_employee_age;
ALTER TABLE users DROP CONSTRAINT uk_users_email;

/*💡 Практические примеры
Полная таблица с ограничениями:
sql*/
CREATE TABLE bank_accounts (
    account_id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL,
    account_type VARCHAR(10) DEFAULT 'checking' CHECK (account_type IN ('checking', 'savings', 'business')),
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    opened_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(10) DEFAULT 'active' CHECK (status IN ('active', 'closed', 'frozen')),
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
        
    CONSTRAINT valid_account_number 
        CHECK (account_number ~ '^[A-Z]{2}[0-9]{10}$')
);
Пример с датами и временем:
sql
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    room_id INTEGER NOT NULL,
    guest_id INTEGER NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    FOREIGN KEY (guest_id) REFERENCES guests(guest_id),
    
    CONSTRAINT valid_dates CHECK (check_out > check_in),
    CONSTRAINT future_check_in CHECK (check_in >= CURRENT_DATE)
);

/*🚀 Продвинутые возможности
Условные UNIQUE ограничения:
sql*/
CREATE TABLE subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service_type VARCHAR(20) NOT NULL,
    status VARCHAR(10) DEFAULT 'active',
    UNIQUE NULLS NOT DISTINCT (user_id, service_type) 
    WHERE (status = 'active')
);
Ограничения на уровне таблицы:
sql
CREATE TABLE project_assignments (
    project_id INTEGER,
    employee_id INTEGER,
    start_date DATE,
    end_date DATE,
    
    PRIMARY KEY (project_id, employee_id),
    FOREIGN KEY (project_id) REFERENCES projects(id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    
    CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT no_overlap EXCLUDE USING gist (
        employee_id WITH =,
        daterange(start_date, end_date) WITH &&
    )
);

/*📊 Управление значениями по умолчанию*/
Изменение DEFAULT:
sql
-- Установить новое значение по умолчанию
ALTER TABLE users 
ALTER COLUMN status SET DEFAULT 'new';

-- Удалить значение по умолчанию
ALTER TABLE users 
ALTER COLUMN status DROP DEFAULT;
Использование в INSERT:
sql
-- Использовать значения по умолчанию
INSERT INTO users (username, email) 
VALUES ('john_doe', 'john@example.com');

-- Явно указать DEFAULT
INSERT INTO products (name, price, created_at) 
VALUES ('Product A', 19.99, DEFAULT);

/*🎯 Best Practices
Всегда используйте NOT NULL где это логично
Именуйте ограничения для удобства управления
Используйте CHECK для бизнес-правил
Внешние ключи для поддержания ссылочной целостности
Значения по умолчанию для автоматизации
Эти механизмы обеспечивают целостность данных и согласованность вашей базы данных! 🛡️*/



/*Запросы
 * 
 *Сивол _ соответствует в точности одному любому сиволу*/

SELECT *
FROM airports
WHERE airport_name LIKE '___';

Select *
from aircrafts
where model like 'Airbus%'

/*Существует ряд операторов с регулярным выражением posix
 * 
 * ~ оператор ищет совпадение с шаблоном с учетом регистра символов
 * ^ означает что поиск совпадения будет привязан к наччалу строки
 * если же следует проверить наличие такого символла в составе
 * строки то нужен символ обратной черты \.
 * Выражение в кругых скобках означает аллтернитивный выбор междду
 * значениями разделлляемые символом |. Поэтому в выборку попадут
 * самоеты начинающиеся ибо на A либо на Boe
 * */

SELECT
	*
FROM
	aircrafts
WHERE
	model ~ '^(A|Boe)';

/*
 *Для инвертирования оператора нужно перед ним добавить знак !
 *Отыщем модели самолелтов, которые нзавершаются числлом 300
 *$ означает привязку поискового шабшлона к концу строки
 *Если же требуется проверить наличие символа в составе строки, то
 *перед ним нужно поставить символ обратной косой черты \ */

SELECT *
FROM  aircrafts
WHERE model !~ '300$';

/*Между Between*/
SELECT
	*
FROM
	aircrafts
WHERE
	RANGE BETWEEN 3000 AND 6700
	--включительно

/*Вычисяемые стобцы*/

SELECT
	model,
	round(RANGE / 1.609, 2) AS miles,
	RANGE
FROM
	aircrafts
ORDER BY RANGE DESC;

/*Distinct неповторяющиеся значения*/
SELECT
	DISTINCT timezone
FROM
	airports
ORDER BY 1;

/*Ограничение числа строк Limit и Offset - пропуск строк*/
SELECT airport_name,city,longitude
FROM airports
ORDER BY longitude
LIMIT 3
OFFSET 3;

/*Условные выражения, позволяют вывести то илли иное значение 
 *в зависимости от условий*/

SELECT
	MODEL,
	RANGE,
	CASE 
	WHEN RANGE < 2000 THEN 'БЛИЖНЕМАГИСТРАЛЬНЫЙ'
	WHEN RANGE < 5000 THEN 'СРЕДНЕМАГИСТРАЛЬНЫЙ'
	ELSE 'ДАЛЬНЕМАГИСТРАЛЬНЫЙ'
	END AS TYPE
FROM
	aircrafts
	
/*Соединение двух таблиц на основе равенства значений атрибутов
 * псевдонимы используются в предложениях:
 *  -where, 
 *  -group by
 *  -order by
 *  -having
 *  -select
 * Можно упрощенно объяснить механизм построения соединения:
 * сначала формируются все попарные комбинации строк из
 * обеих таблиц, то есть декартово произведение множеств строк этих таблиц.
 * Эти комбинированные строки вкючают в себя все аттрибуты обеих таблиц
 * затем в дело вступает условие s.aircraft_code = a.aircraft_code
 * это означает, что в резуьтирующем ножестве строк останутся тоько те из
 * них, в которых значение атрибута aicraft_code взятые из таблицы 
 * aircrafts и из таблицы seats одинаковые.
 * Сроки не удовлетрворяющие этому критерию отфильтруются.
 * 
 * 
 * Планировщик строит план выполнения запроса, который явлляется гораздо
 * более эффективным, чем упрощенный пллан, представленный выше.
 * 
 * */
SELECT
	a.aircraft_code,
	a.model,
	s.seat_no,
	s.fare_conditions
FROM
	seats AS s
JOIN aircrafts AS a ON
	s.aircraft_code = a.aircraft_code
WHERE
	a.model ~ '^Cessn'
ORDER BY
	s.seat_no
	
/*Также данный запрос можно переписать по-другому
 * без использования join
 * простые запросы обычно пишут именно таким образом
 * без использования join, в предложении where указывают
 * критерии, которым должны удовлетворять результирующие
 * строки*/

	
SELECT
	a.aircraft_code,
	a.model,
	s.seat_no,
	s.fare_conditions
FROM
	seats s,
	aircrafts a 
WHERE s.aircraft_code = a.aircraft_code
AND a.model ~ '^Cessn'
ORDER BY
	s.seat_no;
	
/*!!! Результатом любых реляционных операций над отношениями (таблицами
 * представлениями) также является отношение!!!
 * Поэтому такие операции можно произвольно комбинировать друг
 * с другом*/

--CREATE OR REPLACE VIEW flights_v AS 
SELECT 
f.flight_id,
f.flight_no,
f.scheduled_departure,
timezone(dep.timezone, f.scheduled_departure) AS scheduled_departure_local,
f.scheduled_arrival,
timezone(arr.timezone, f.scheduled_departure) AS scheduled_arrival_local,
f.scheduled_arrival - f.scheduled_departure AS scheduled_duration,
f.departure_airport,
dep.airport_name AS departure_airport_name,
dep.city AS departure_city,
f.arrival_airport,
arr.airport_name AS arrival_airport_name,
arr.city AS arrival_city,
f.status,
f.aircraft_code,
f.actual_departure,
timezone(dep.timezone, f.actual_departure) AS actual_departure_local,
f.actual_arrival

FROM flights f,
airports dep,
airports arr
WHERE f.departure_airport = dep.airport_code
AND   f.arrival_airport   = arr.airport_code

/*Три способа выпонения соединения табицы с самой собой
 * рейсов одного города в тот же самый город быть не дожно
 */

SELECT count(*)
FROM airports a1, airports a2
WHERE a1.city <> a2.city;

SELECT count(*)
FROM airports a1
JOIN airports a2 ON a1.city <> a2.city;

SELECT count(*)
FROM airports a1
CROSS JOIN airports a2 
WHERE a1.city <> a2.city;


UPDATE boarding_passes
SET seat_no = '1A'
WHERE flight_id = 2
AND seat_no = '17A'


/*Пассажир выбрал класс Business, а при регистрации ему выдаллли посадочный
 * на эконом*/
SELECT *
FROM boarding_passes b
JOIN ticket_flights tf
ON b.ticket_no = tf.ticket_no AND b.flight_id = tf.flight_id
JOIN tickets t ON tf.ticket_no = t.ticket_no
JOIN flights f ON tf.flight_id = f.flight_id
JOIN seats s   ON b.seat_no = s.seat_no AND f.aircraft_code = s.aircraft_code
WHERE tf.fare_conditions <> s.fare_conditions
ORDER BY f.flight_no, f.scheduled_departure

/*Для выработки финансовой стратегии на требуется распределение коичества
 * бронирований по диапазонам сумм с шагом в 100 тысяч рублей, максимальная
 * сумма в одном бронировании составляет 1 204 500 рублей. Учтем это при
 * формировани диапазона
 * Виртуалльной табоице создаваемой с помощью ключевого слова values присваивают
 * имя с помощью ключевого слова AS, после имени в круглых скобках 
 * приводится список имен столбцов.
 * 
 */

SELECT 
r.min_sum, 
r.max_sum,
count(b.*)
FROM bookings b
RIGHT OUTER JOIN (
VALUES 
(0, 100000),       (100000, 200000),
(200000, 300000),  (300000, 400000),
(400000, 500000),  (500000, 600000),
(600000, 700000),  (700000, 800000),
(800000, 900000),  (900000, 1000000),
(1000000,1100000), (1100000, 1200000),
(1200000,1300000)
) AS r (min_sum, max_sum)
ON  b.total_amount >= r.min_sum
AND b.total_amount < r.max_sum
GROUP BY r.min_sum, r.max_sum
ORDER BY r.min_sum

/*Объединение множеств строк UNION строки дубликаты удаляются*/

SELECT arrival_city 
FROM routes
WHERE departure_city = 'Москва'

UNION

SELECT arrival_city 
FROM routes
WHERE departure_city = 'Санкт-Петербург'
ORDER by  arrival_city 


/*Пересечение множеств строк intersect
 * строка включается в итоговое множество 
 * если присутствует в каждом из них
 * строки-дубликаты не включаются в результирубщее
 * множество для их включения необходимо использовать
 * intersect all*/

SELECT arrival_city 
FROM routes
WHERE departure_city = 'Москва'

intersect

SELECT arrival_city 
FROM routes
WHERE departure_city = 'Санкт-Петербург'
ORDER by  arrival_city 

/*Расзность множества строк
 * строка включается в итоговое множество, если она присутсвует в первом
 * множестве, но отсутствует во втором, для отображения строк дубликатов 
 * используется except all*/
SELECT arrival_city 
FROM routes
WHERE departure_city = 'Москва'

except

SELECT arrival_city 
FROM routes
WHERE departure_city = 'Санкт-Петербург'
ORDER by  arrival_city 

/*Согасно документации intersect связывает свои подзапросы сильнее
 * чем union, а except связывает свои подзапросы также сильно,
 * как union*/

/*Агрегирование и группировка
 * среди множества функций, имеющихся в Postgresql важно место занимают 
 * агрегированные функции. С одной из них функцией count, мы уже работали 
 * довольно много.
 * */

SELECT round(avg(total_amount),2) AS avg_total_amount
FROM bookings

SELECT max(total_amount) AS avg_total_amount
FROM bookings

SELECT min(total_amount) AS avg_total_amount
FROM bookings

/*Сколько маршрутов предусмотрено из Москвы в другие города*/

SELECT arrival_city, count(*)
FROM routes
WHERE departure_city = 'Москва'
GROUP BY arrival_city 
ORDER BY count DESC;

/*Найти информацию о том сколько рейсов выполлняется ежедневно, сколлько
 * рейсов шесть дней в неделю, пять и т.д.
 * 
 * array_length(days_of_week, 1) 
 * возвращает количество элементовв указанном измерении массива,
 * поскольку массив одномерный, то вторым параметром функции будет 
 * число 1 -первое измерение
 * cardinality() - это функция в PostgreSQL, которая возвращает 
 * общее количество элементов в массиве.*/

SELECT array_length(days_of_week, 1) AS day_per_week,
cardinality(days_of_week) as day_per_week_2,
count(*) AS num_routes-- массив дней недели
FROM routes
WHERE departure_city = 'Москва'
GROUP BY day_per_week, day_per_week_2 
ORDER BY day_per_week  DESC;


/*При выполнении выборок можно с помощью услловий, заданных
 * в предлложении where сузить множество выбираемых строк
 * Аналогичная возможность существует и при выполнении группировок -
 * можно включить в результирующее множество не все строки,
 * а лишь те, которые удовлетворяют определенным усллловиям,
 * это условие можно создать в предложении having
 *
 *Определить, сколько существует маршрутов из каждого города в другие города
 *и вывести названия городов из которых в другие города существет не менее 15 
 *маршрутов
 */

SELECT departure_city, count(*)
FROM routes
GROUP BY departure_city
HAVING count(*) >=15
ORDER BY count DESC;

/*Найдем города, где больше одного аэпропорта*/
SELECT city, count(*)
FROM airports 
GROUP BY city
HAVING count(*) > 1;

/*Оконные функции позволяют производить вычисления на множестве строк, логически
связанных с текущей строкой, т.е. имеющих то или иное отношение к ней
 * Эти функции предоставлляют возможность производить вычисления на 
 * множестве строк, логически связанных с текущей строкой, 
 * т.е. имеющих то или иное отношение к ней*
 * При работе с оконными функциями используется концепция раздела partition
 * и оконного кадра window frame
 * Partition задет правило разбиения строк на разделы, предложение order by
 * предписывает порядок сортировки строк в разделах
 * 
 * Количество билетов долллжно выводиться ввиде накопленного показателя,
 * суммирование должно производиться в пределах каждого календарного месяца
 * Если в запросе присутствуют Group by и having, тогда оконные функции вызываются
 * уже после них, оконные функции будут работать со строками, являющимися 
 * результатом группировки
 */
SELECT
b.book_ref,
b.book_date,
EXTRACT('month' FROM b.book_date) AS MONTH,
EXTRACT('day' FROM b.book_date) AS day,
count(*) OVER (PARTITION BY date_trunc('month', b.book_date) ORDER BY b.book_date) AS count
FROM ticket_flights tf
JOIN tickets  t ON tf.ticket_no = t.ticket_no
JOIN bookings b ON t.book_ref = b.book_ref
WHERE tf.flight_id = 2
ORDER BY b.book_date;

SELECT *
FROM tickets b
WHERE b.book_ref = '9DC422'

/*Как можно ранжировать аэроппорты в пределах часвого пояса на основе 
 * их географической широты*/

SELECT airport_name,
city,
round(latitude::NUMERIC, 2) AS ltd,
timezone,
rank() OVER (PARTITION BY timezone ORDER BY latitude desc)
FROM airports
WHERE timezone IN ('Asia/Irkutsk', 'Asia/Krasnoyarsk')
ORDER BY timezone, rank;

/*Самый серверный аэропорт это первая строка в каждом разделе, выбирается
 * с помощью оконной функции first_value
 * Строго говоря эта функция получает доступ к первой строке оконного кадра, а не раздела
 * Однако, когда используются правила формирования оконного кадра по умоллчанию, тогда его начало 
 * совпадает с началом раздела
 * 
 * Вызов оконной функции всегда содержит предложение OVER, 
 * следующее за названием и аргументами оконной функции. 
 * Это синтаксически отличает её от обычной, не оконной агрегатной функции. Предложение OVER определяет, как именно нужно разделить строки запроса для обработки оконной функцией. Предложение PARTITION BY, дополняющее OVER, разделяет строки по группам, или разделам, объединяя одинаковые значения выражений PARTITION BY. Оконная функция вычисляется по строкам, попадающим в один раздел с текущей строкой.
 * Вы можете также определять порядок, в котором строки будут обрабатываться оконными функциями, используя ORDER BY в OVER. (Порядок ORDER BY для окна может даже не совпадать с порядком, в котором выводятся строки.) 
 */
---https://postgrespro.ru/docs/postgresql/17/tutorial-window

SELECT 
airport_name,
city,
timezone,
latitude,
first_value(latitude) OVER tz AS first_in_timezone,
latitude - first_value(latitude) OVER tz AS delta,
rank() OVER tz
FROM airports 
WHERE timezone IN ('Asia/Irkutsk', 'Asia/Krasnoyarsk')
WINDOW tz AS (PARTITION BY timezone ORDER BY latitude desc)
ORDER BY timezone, rank;

/*Подзапросы
 * 
 * Порядок выполнения SQL запроса
🔄 Логический порядок выполнения (от начала до конца):
1. FROM - определение источников данных
Определяются все таблицы и представления, участвующие в запросе

Выполняется декартово произведение, если не указаны JOIN условия

2. JOIN - соединение таблиц
Выполняются все JOIN операции (INNER, LEFT, RIGHT, FULL, CROSS)

Применяются условия соединения ON/USING

Формируется временный результирующий набор

3. WHERE - фильтрация строк
Применяются условия фильтрации к результирующему набору

Удаляются строки, не удовлетворяющие условиям

Нельзя использовать алиасы столбцов из SELECT

4. GROUP BY - группировка данных
Данные разделяются на группы по указанным столбцам

Для каждой уникальной комбинации значений создается одна строка

Подготавливаются данные для агрегатных функций

5. HAVING - фильтрация групп
Фильтруются группы, созданные в GROUP BY

Применяются условия к результатам агрегатных функций

Можно использовать алиасы из SELECT

6. SELECT - выбор столбцов
Вычисляются выражения и функции

Присваиваются алиасы столбцам

Определяется окончательный набор столбцов результата

7. DISTINCT - удаление дубликатов
Удаляются дублирующиеся строки из результата

Применяется после вычисления всех выражений в SELECT

8. ORDER BY - сортировка результата
Результирующие данные сортируются по указанным столбцам

Можно использовать алиасы из SELECT

Можно указывать порядок сортировки (ASC/DESC)

9. OFFSET/LIMIT/FETCH - ограничение результата
LIMIT/FETCH - ограничение количества возвращаемых строк

OFFSET - пропуск указанного количества строк

Применяется после сортировки

ПИШЕМ:    SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
ВЫПОЛНЯЕМ: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT


Области видимости:
- WHERE - видит только исходные столбцы таблиц
- HAVING - видит результаты GROUP BY и агрегатные функции
- SELECT - видит все предыдущие этапы
- ORDER BY - видит алиасы из SELECT
 * 
Производительность:
Наиболее селективные условия следует размещать в WHERE
HAVING должен использоваться только для фильтрации групп
JOIN с большими таблицами лучше выполнять после фильтрации!!!

Селективность = (Количество подходящих строк) / (Общее количество строк) * 100%
Высокая селективность:
WHERE id = 123
-- Возвращает 1 строку из 1,000,000 → селективность 0.0001%
-- ОЧЕНЬ ВЫСОКАЯ селективность

Средняя селективность:
WHERE status = 'active'
-- Возвращает 50,000 строк из 1,000,000 → селективность 5%
-- СРЕДНЯЯ селективность

Низкая селективность:
WHERE gender = 'male'
-- Возвращает 500,000 строк из 1,000,000 → селективность 50%
-- НИЗКАЯ селективность


Процесс выполнения запроса:
SELECT *
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.total_amount > 1000        -- высокоселективное условие
  AND c.country = 'USA'            -- низкоселективное условие
  
Правильный порядок оптимизации:
Сначала применяется WHERE к таблице orders:
o.total_amount > 1000 → отбирает 500 строк из 100,000 (0.5%)
Остается всего 500 строк для JOIN
Затем выполняется JOIN с отфильтрованными данными:
JOIN делается только для 500 строк, а не для 100,000
Экономия ресурсов: в 200 раз меньше операций


💡 Селектьивность ключевые выводы:
Селективность в базах данных — это мера уникальности значений в столбце 
или комбинации столбцов. Она показывает, насколько эффективно индекс 
может фильтровать данные при выполнении запросов.

Селективность - это процент строк, которые удовлетворяют условию 
от общего количества строк в таблице.
Формально селективность определяется как отношение количества уникальных значений 
в столбце к общему количеству строк в таблице. Например, если в таблице 
с 1000 строк столбец содержит 900 уникальных значений, то его селективность 
будет 900/1000 = 0,9 или 90%. 
Селективность выражается значением от 0 до 1, где 0 означает отсутствие 
селективности, а 1 — идеальную селективность. 

Низкий selectivity_pct = лучше для индексов
Высокий selectivity_pct = хуже для индексов
most_common_val и most_common_count показывают распределение данных
Рекомендация помогает быстро оценить полезность колонки для условий WHERE


🎯 Простое правило для запоминания:
Делайте индекс если:
< 5% - ОТЛИЧНО (обязательно индекс)
5%-30% - ХОРОШО (рекомендуется индекс)
30%-60% - НОРМАЛЬНО (можно индекс)
> 60% - ПЛОХО (индекс обычно не нужен)
Ваш случай: 40% → "НОРМАЛЬНО" → индекс СТОИТ сделать

selectivity = (COUNT(DISTINCT column_name) / COUNT(*)) * 100%

-- Колонки с рекомендациями:
-- 🔥 HIGH: Отличная селективность
-- ✅ UNIQUE: Все значения уникальны
Пример: ID, email, хэши - где селективность < 5%
Приоритет 2 (средний):
sql
-- 🟢 GOOD: Хорошая селективность
-- 🟡 MEDIUM: Средняя селективность
Пример: category_id, status, type - где селективность 5-20%
Приоритет 3 (низкий):
sql
-- 🟠 LOW: Низкая селективность
-- 🔴 POOR: Очень низкая селективность*
***/


SELECT * FROM analyze_selectivity_fixed('bookings', 'flights');

CREATE OR REPLACE FUNCTION analyze_selectivity_fixed(
    p_table_schema TEXT DEFAULT 'public',
    p_table_name TEXT DEFAULT NULL
)
RETURNS TABLE(

    col_name TEXT,                -- Название колонки
    col_type TEXT,                -- Тип данных колонки
    total_rows BIGINT,            -- Общее количество строк в таблице
    distinct_vals BIGINT,         -- Количество уникальных значений
    null_vals BIGINT,             -- Количество NULL значений
    selectivity_pct NUMERIC,      -- Процент селективности
    most_common_val TEXT,         -- Самое частое значение
    most_common_count BIGINT,     -- Количество самого частого значения
    recommendation TEXT           -- Рекомендация по селективности

) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql TEXT;
    v_rec RECORD;
BEGIN
    -- Если не указана таблица - анализируем все таблицы схемы
    IF p_table_name IS NULL THEN
        FOR v_rec IN 
            SELECT DISTINCT table_name
            FROM information_schema.columns 
            WHERE table_schema = p_table_schema
              AND table_name NOT LIKE 'pg_%'
              AND table_name NOT LIKE 'sql_%'
            ORDER BY table_name
        LOOP
            RETURN QUERY 
            SELECT * FROM analyze_selectivity_fixed(p_table_schema, v_rec.table_name);
        END LOOP;
        RETURN;
    END IF;

    -- Проверяем существование таблицы
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = p_table_schema 
          AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Таблица %.% не существует', p_table_schema, p_table_name;
    END IF;

    -- Анализируем каждую колонку
    FOR v_rec IN 
        SELECT 
            column_name as col_n,
            data_type as col_t
        FROM information_schema.columns 
        WHERE table_schema = p_table_schema 
          AND table_name = p_table_name
        ORDER BY ordinal_position
    LOOP
        -- Строим SQL запрос правильно
        v_sql := '
        WITH column_data AS (
            SELECT ' || quote_ident(v_rec.col_n) || ' as col_value
            FROM ' || quote_ident(p_table_schema) || '.' || quote_ident(p_table_name) || '
        ),
        mode_calc AS (
            SELECT 
                col_value,
                COUNT(*) as frequency
            FROM column_data
            WHERE col_value IS NOT NULL
            GROUP BY col_value
            ORDER BY frequency DESC
            LIMIT 1
        ),
        stats AS (
            SELECT 
                COUNT(*) as total,
                COUNT(DISTINCT col_value) as distinct_cnt,
                COUNT(*) FILTER (WHERE col_value IS NULL) as null_cnt,
                (SELECT col_value FROM mode_calc) as mode_val,
                (SELECT frequency FROM mode_calc) as mode_count
            FROM column_data
        )
        SELECT 
            ' || quote_literal(v_rec.col_n) || ' as col_name,
            ' || quote_literal(v_rec.col_t) || ' as col_type,
            total as total_rows,
            distinct_cnt as distinct_vals,
            null_cnt as null_vals,
            CASE 
                WHEN total - null_cnt = 0 THEN 0
                ELSE ROUND((distinct_cnt::numeric / (total - null_cnt)) * 100, 2)
            END as selectivity_pct,
            COALESCE(mode_val::text, ''NULL'') as most_common_val,
            COALESCE(mode_count, 0) as most_common_count,
            CASE 
                WHEN distinct_cnt = 1 THEN ''❌ CONSTANT: Все значения одинаковы''
                WHEN distinct_cnt = total AND null_cnt = 0 THEN ''✅ UNIQUE: Все значения уникальны''
                WHEN (distinct_cnt::numeric / NULLIF(total - null_cnt, 0)) < 0.01 THEN ''🔥 HIGH: Отличная селективность''
                WHEN (distinct_cnt::numeric / NULLIF(total - null_cnt, 0)) < 0.05 THEN ''🟢 GOOD: Хорошая селективность''
                WHEN (distinct_cnt::numeric / NULLIF(total - null_cnt, 0)) < 0.2 THEN ''🟡 MEDIUM: Средняя селективность''
                WHEN (distinct_cnt::numeric / NULLIF(total - null_cnt, 0)) < 0.5 THEN ''🟠 LOW: Низкая селективность''
                ELSE ''🔴 POOR: Очень низкая селективность''
            END as recommendation
        FROM stats';
        
        RETURN QUERY EXECUTE v_sql;
    END LOOP;
END;
$$;

/*Подзапросы
 * Подсчитаем количество операций бронирования, в которых общая сумма 
 * превышает среднюю величину по всей выборке
 * 
 * !!! Подзапросы могут присутствовать в предложениях:
 * -select 
 * -from
 * -where
 * -having
 * а также в предложении WITH
 * 
 * 
*/

SELECT count(*) --количество операций бронирования
FROM bookings ---главный хапрос
WHERE total_amount > (SELECT avg(total_amount) FROM bookings)

/*Если через СTE*/
WITH bookings_with_avg AS (
    SELECT 
        *,
        AVG(total_amount) OVER () as overall_avg_amount
    FROM bookings
)
SELECT COUNT(*) as booking_count
FROM bookings_with_avg
WHERE total_amount > overall_avg_amount;

--подзапрос
/*скалярный позапрос, в результате его вполнения возвращается одно
 * скалярное значение (один столбец, одна строка), с которым можно
 * сравнивать и дургие скалярные значения
 * Если подзапрос выдает множество значений, можно использовать
 * такой подзапрос в предикате in. Этот предикат позволяет ограничивать
 * проверку на предмет принадлежности какого-либо значения определенному
 * множеству значений.
 * 
 * Найдем какие маршруты существуют между городами часового пояса Asia/Krasnoyarsk
 * Подзапрос будет выдавать список городов из этого часвого пояса, а 
 * в предложении where главного запроса с помощью предиката in , будет выполняться
 * проверка на принадлежность города к этому списку. При этом подзапрос будет 
 * выполняется только один раз для всего внешнего запроса, а не при обработке 
 * каждой строки из таблицы routes во внешнем запросе. 
 * Повторное выполнение запроса не потребуется, так как его результат
 * не зависит от значений, хранящихся в табллице routes.
 * Такие подзапросы называются некоррелированными
 * */

SELECT flight_no, departure_city, arrival_city
FROM routes 
WHERE departure_city IN 
(SELECT city
FROM airports
WHERE timezone ~ 'Krasnoyarsk') --Это условие отбирает строки, где значение колонки timezone содержит подстроку 'Krasnoyarsk'.
AND arrival_city IN (
SELECT city
FROM airports
WHERE timezone ~ 'Krasnoyarsk'
);



/*Хотим найти самый западный аэропорт и самый восточный аэпропорт*/

SELECT airport_name, city, longitude
FROM airports
WHERE longitude IN (
(SELECT max(longitude) FROM airports), 
(SELECT min(longitude) FROM airports) 
)
ORDER BY longitude

/*Иногда требуется  чтобы подзапрос установил факт наличия или отсутствия строк
 * в конкретной таблице, удовлетовряющих определенному услловию, а само значение
 * аттрибутов в этих строках интереса не представляет
 * В подобных случаях используют предикат exists
 * 
 * Выясним в какие города нет рейсов из Москвы
 * 
 * коррелированный связанный подзапрос выполняется для каждой строки, 
 * обрабатываемой во внешнем запросе
 */

SELECT DISTINCT 
a.city
FROM airports a
WHERE NOT EXISTS (
SELECT r.departure_city
FROM routes r
WHERE r.departure_city = 'Москва'
AND r.arrival_city = a.city
)
AND a.city <> 'Москва'
ORDER BY city


WITH all_cities AS (
    SELECT DISTINCT city 
    FROM airports 
    WHERE city <> 'Москва'
),
moscow_destinations AS (
    SELECT DISTINCT arrival_city as city
    FROM routes 
    WHERE departure_city = 'Москва'
)
SELECT city
FROM all_cities
EXCEPT
SELECT city
FROM moscow_destinations
ORDER BY city;


WITH all_cities AS (
    SELECT DISTINCT city 
    FROM airports 
    WHERE city <> 'Москва'
),
moscow_routes AS (
    SELECT DISTINCT arrival_city
    FROM routes 
    WHERE departure_city = 'Москва'
)

SELECT ac.city,mr.arrival_city,ac.city
FROM all_cities ac
LEFT JOIN moscow_routes mr ON ac.city = mr.arrival_city
WHERE mr.arrival_city IS NULL
ORDER BY ac.city;

/*Предполложим, что для выработки ценовой политики
 * необходимо знать как распределляются места разных классов 
 * в самолетах всех типов
 * 
 * кореллированые подзапросы
 */

SELECT a.model,
(SELECT count(*)
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Business') AS business,
(SELECT count(*)
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Comfort') AS comfort,
(SELECT count(*)
FROM seats s
WHERE s.aircraft_code = a.aircraft_code
AND s.fare_conditions = 'Economy') AS economy
FROM aircrafts a
ORDER BY a.model

/*FILTER - это условное агрегирование в PostgreSQL, которое 
 * позволяет применять условия к агрегатным функциям без использования 
 * CASE WHEN.
 * Через FILTER (современный способ):
 * sql
 * COUNT(*) FILTER (WHERE fare_conditions = 'Comfort') AS comfort
 * Через CASE WHEN (классический способ):
 * sql
 * SUM(CASE WHEN fare_conditions = 'Comfort' THEN 1 ELSE 0 END) AS comfort
 * Преимущества FILTER:
 * Читаемость - код более понятный
 * Производительность - часто работает быстрее, чем CASE WHEN
 * Удобство - не нужно писать сложные CASE конструкции
 * Стандарт SQL - является частью SQL стандарта
 */
WITH seat_counts AS (
    SELECT 
        aircraft_code,
        COUNT(*) FILTER (WHERE fare_conditions = 'Business') AS business,
        COUNT(*) FILTER (WHERE fare_conditions = 'Comfort') AS comfort,
        COUNT(*) FILTER (WHERE fare_conditions = 'Economy') AS economy
    FROM seats
    GROUP BY aircraft_code
)
SELECT 
    a.model,
    COALESCE(sc.business, 0) AS business,
    COALESCE(sc.comfort, 0) AS comfort,
    COALESCE(sc.economy, 0) AS economy
FROM aircrafts a
LEFT JOIN seat_counts sc ON a.aircraft_code = sc.aircraft_code
ORDER BY a.model;


WITH seat_aggregation AS (
    SELECT 
        aircraft_code,
        SUM(CASE WHEN fare_conditions = 'Business' THEN 1 ELSE 0 END) AS business,
        SUM(CASE WHEN fare_conditions = 'Comfort' THEN 1 ELSE 0 END) AS comfort,
        SUM(CASE WHEN fare_conditions = 'Economy' THEN 1 ELSE 0 END) AS economy
    FROM seats
    GROUP BY aircraft_code
)
SELECT 
    a.model,
    sa.business,
    sa.comfort,
    sa.economy
FROM aircrafts a
JOIN seat_aggregation sa ON a.aircraft_code = sa.aircraft_code
ORDER BY a.model;

/*Еще один варинат подсчета*/

SELECT 
s2.model,
string_agg(s2.fare_conditions || ' = ' || s2.num, ', ')
FROM (
SELECT a.model,
s.fare_conditions,
count(*) AS num
FROM aircrafts a
JOIN seats s ON a.aircraft_code = s.aircraft_code
GROUP BY 
a.model,
s.fare_conditions
ORDER BY 
a.model,
s.fare_conditions) AS s2
GROUP BY s2.model
ORDER BY s2.model

/*Получить перечень аэропортов в тех городах, 
 * в которых больше одного аэропорта*/

SELECT b.city, b.airport_code, b.airport_name
FROM
(
SELECT city, count(*)
FROM airports
GROUP BY city
HAVING count(*) > 1
)  AS a
JOIN airports AS b ON a.city = b.city
ORDER BY b.city, b.airport_name

/*Переводим логику запроса в CTE */
WITH cities_with_multiple_airports AS (
    SELECT city
    FROM airports
    GROUP BY city
    HAVING COUNT(*) > 1
)
SELECT 
    a.city, 
    a.airport_code, 
    a.airport_name
FROM airports a
JOIN cities_with_multiple_airports c ON a.city = c.city
ORDER BY a.city, a.airport_name;

/*Задача: определить число маршрутов, исходящих из тех аэпропртов,
 * которые расположены восточнее географической долготы 150 градусов *
 *
 *подзапрос формирует список аэропортов, которые и будут отобраны с помощью
 *предложения having
 */
SELECT 
departure_airport,
departure_city,
count(*)
FROM routes
GROUP BY 
departure_airport,
departure_city
HAVING departure_airport IN 
---аэропорты оторые расположены восточнее географической долготы 150 градусов
(SELECT airport_code
FROM airports
WHERE longitude > 150)
ORDER BY count DESC; 


WITH eastern_airports AS (
    SELECT airport_code
    FROM airports
    WHERE longitude > 150
)
SELECT 
    r.departure_airport,
    r.departure_city,
    COUNT(*) as flight_count
FROM routes r
JOIN eastern_airports ea ON r.departure_airport = ea.airport_code
GROUP BY r.departure_airport, r.departure_city
ORDER BY flight_count DESC;

/*В сложных запросах могут использоваться вложенные подзапросы, это означает
 * что один подзапрос находится внутри дургого
 * 
 * Руководство авиакомпании хочет выяснить степень заполнения самолетов
 * на рейсах, ведь отправлять полупустые самолеты не очень
 * выгодно. 
 * Таким образом запрос должен не только выдавать число билетов,
 * проданных на данный рейс и общее число мест в самолете, но должен
 * также вычислять отношение этих двух показателей*/

SELECT 
ts.flight_id,
ts.flight_no,
ts.scheduled_departure_local,
ts.departure_city,
ts.arrival_city,
ts.aircraft_code,
ts.fact_passengers,
ts.total_seats,
round(ts.fact_passengers / ts.total_seats::NUMERIC, 2) AS fraction

FROM(
SELECT 
f.flight_id,
f.flight_no,
f.scheduled_departure_local,
f.departure_city,
f.arrival_city,
f.aircraft_code,
count(tf.ticket_no) AS fact_passengers,

(SELECT count(s.seat_no)
FROM seats s
WHERE s.aircraft_code = f.aircraft_code) AS total_seats

FROM flights_v f
JOIN ticket_flights tf ON f.flight_id = tf.flight_id
WHERE f.status = 'Arrived'
GROUP BY 
f.flight_id,
f.flight_no,
f.scheduled_departure_local,
f.departure_city,
f.arrival_city,
f.aircraft_code) AS ts
JOIN aircrafts AS a ON ts.aircraft_code = a.aircraft_code
ORDER BY ts.scheduled_departure_local;

/*Перепишем на отдельные CTE общие табличные выражения
 * 1. Вычисление и материализация
По умолчанию CTE материализуются - результат вычисляется один раз и сохраняется 
во временной таблице
Это может быть полезно для оптимизации, если CTE используется несколько раз
2. Область видимости
CTE существуют только во время выполнения запроса

Типы CTE
1. Обычные CTE
2. Рекурсивные

Улучшенная читаемость - сложные запросы разбиваются на логические части
Исключение дублирования - один CTE можно использовать несколько раз
Рекурсивные запросы - обработка иерархических данных
Отладка - можно тестировать каждую часть отдельно


 * */

WITH 
flights_filtered AS MATERIALIZED  (
SELECT * 
FROM flights_v WHERE status = 'Arrived'
),
ticket_counts AS (
    SELECT 
        flight_id, 
        COUNT(ticket_no) AS passenger_count 
    FROM ticket_flights 
    GROUP BY flight_id
),
seat_counts AS (
    SELECT 
        aircraft_code, 
        COUNT(*) AS total_seats 
    FROM seats 
    GROUP BY aircraft_code
),
aircrafts_list AS (
    SELECT aircraft_code FROM aircrafts
)

SELECT 
    f.flight_id,
    f.flight_no,
    f.scheduled_departure_local,
    f.departure_city,
    f.arrival_city,
    f.aircraft_code,
    tc.passenger_count AS fact_passengers,
    sc.total_seats,
    ROUND(tc.passenger_count / sc.total_seats::NUMERIC, 2) AS fraction
FROM flights_filtered f
JOIN ticket_counts tc ON f.flight_id = tc.flight_id
JOIN seat_counts sc ON f.aircraft_code = sc.aircraft_code
JOIN aircrafts_list a ON f.aircraft_code = a.aircraft_code
ORDER BY f.scheduled_departure_local;

/*Ранее мы делали распределение с помощью виртуальной табицы values
 * по сумме бронирования по диапазонам значений с шагом 100 тыс. рублей, но
 * можно решить задачу более рационально
 * с помощью рекурсивного общего табличного выражения
 * 
 * Рекурсивное CTE - это мощный инструмент для обработки иерархических данных и 
 * последовательностей. Оно работает по принципу "расширяющегося результата", 
 * где каждая итерация добавляет новые данные на основе предыдущих, пока не 
 * выполнится условие остановки.
 *
 * Сначала выпоняется предложение values (0,100000) и реузльтат записывается
 * во временную область памяти;
 * Затем к этой временной обасти памяти применяется запрос:
 * SELECT min_sum + 100000, max_sum + 100000;
 * и в резуьтате его выполнения формируется одна строка
 * Вновь сформированная строка вместе с исходной строкой помещается
 * в другую временную область, в которой происходит накапливание
 * резулльтирующих строк;
 * к той строке, которая быа на предыдущем шаге сформирована с помощью 
оманды Select опять применяется эта же команда и т.д.
 * работа завершится когда перестанет выполняться условие
 * max_sum < (SELECT max(total_amount) FROM bookings)
 * Важную роль играет UNION ALL , бллагодаря которому происходит объединение
 * сформированных строк в единую таблицу
 * в предложении where исполльузется скалярный подзапрос с результатом его выполнения
 * сравнивается значение столбца max_sum
 */

WITH RECURSIVE ranges (min_sum, max_sum) AS
(
VALUES(0, 100000)
UNION ALL 
SELECT min_sum + 100000, max_sum + 100000
FROM ranges
WHERE max_sum < (SELECT max(total_amount) FROM bookings)
)

SELECT *
FROM ranges;

/*Еще один пример с подчинением сотрудников*/
WITH RECURSIVE employee_hierarchy AS (
    -- Якорь рекурсии (начало иерархии)
    SELECT 
        employee_id,
        manager_id,
        name,
        position,
        1 as level,
        name::TEXT as hierarchy_path
    FROM employees
    WHERE manager_id IS NULL  -- Начинаем с CEO (у него нет менеджера)
    
    UNION ALL
    
    -- Рекурсивная часть (расширяем иерархию вниз)
    SELECT 
        e.employee_id,
        e.manager_id,
        e.name,
        e.position,
        eh.level + 1 as level,
        eh.hierarchy_path || ' -> ' || e.name as hierarchy_path
    FROM employees e
    JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT 
    employee_id,
    manager_id,
    name,
    position,
    level,
    hierarchy_path
FROM employee_hierarchy
ORDER BY hierarchy_path;


/*Теперь скомбинируем рекурсивное общее таболичное выражение с выборкой из таблицы bookings
 * 
 * */


WITH RECURSIVE ranges (min_sum, max_sum) AS
(
VALUES(0, 100000)
UNION ALL 
SELECT min_sum + 100000, max_sum + 100000
FROM ranges
WHERE max_sum < (SELECT max(total_amount) FROM bookings)
)

SELECT r.min_sum, r.max_sum, count(b.*)
FROM bookings b
RIGHT OUTER JOIN ranges r
ON b.total_amount >= r.min_sum
AND b.total_amount < r.max_sum
GROUP BY r.min_sum, r.max_sum
ORDER BY r.min_sum;

/*Материализованное представление
 * Физическое - данные хранятся на диске
Снимок данных на момент последнего обновления
Быстрее - данные готовы к чтению
REFRESH MATERIALIZED VIEW наименование представлления;
 *
🎯 Идеальные сценарии использования
Отчеты и дашборды - сложные агрегации
Кэширование дорогих запросов - JOIN 5+ таблиц
Денормализация - данные из разных источников
Аналитика в реальном времени - предварительные вычисления
Снижение нагрузки - на рабочих таблицах

 */
--REFRESH MATERIALIZED VIEW routes
-- bookings.routes исходный текст
CREATE MATERIALIZED VIEW routes
AS WITH f3 AS (
         SELECT f2.flight_no,
            f2.departure_airport,
            f2.arrival_airport,
            f2.aircraft_code,
            f2.duration,
            array_agg(f2.days_of_week) AS days_of_week
           FROM ( SELECT f1.flight_no,
                    f1.departure_airport,
                    f1.arrival_airport,
                    f1.aircraft_code,
                    f1.duration,
                    f1.days_of_week
                   FROM ( SELECT flights.flight_no,
                            flights.departure_airport,
                            flights.arrival_airport,
                            flights.aircraft_code,
                            flights.scheduled_arrival - flights.scheduled_departure AS duration,
                            to_char(flights.scheduled_departure, 'ID'::text)::integer AS days_of_week
                           FROM flights) f1
                  GROUP BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week
                  ORDER BY f1.flight_no, f1.departure_airport, f1.arrival_airport, f1.aircraft_code, f1.duration, f1.days_of_week) f2
          GROUP BY f2.flight_no, f2.departure_airport, f2.arrival_airport, f2.aircraft_code, f2.duration
        )
 SELECT f3.flight_no,
    f3.departure_airport,
    dep.airport_name AS departure_airport_name,
    dep.city AS departure_city,
    f3.arrival_airport,
    arr.airport_name AS arrival_airport_name,
    arr.city AS arrival_city,
    f3.aircraft_code,
    f3.duration,
    f3.days_of_week
   FROM f3,
    airports dep,
    airports arr
  WHERE f3.departure_airport = dep.airport_code AND f3.arrival_airport = arr.airport_code;


SELECT airport_name
FROM airports
WHERE airport_name SIMILAR TO  '%[еЕ][нН]%'


/*Имена пассажиров состоящих из трех букв*/
SELECT passenger_name
FROM tickets
WHERE passenger_name LIKE '___ %'


/*Функции GREATEST и LEAST выбирают наибольшее или наименьшее значение из 
списка выражений. Все эти выражения должны приводиться к общему типу данных, 
который станет типом результата (подробнее об этом в Разделе 10.5).
Значения NULL в этом списке игнорируются, так что результат выражения 
будет равен NULL, только если все его аргументы равны NULL. 
(Это отклонение от стандарта SQL. Согласно стандарту, возвращается 
значение NULL, если какой-либо аргумент равен NULL. 
Подобным образомведут себя и некоторые другие базы данных.)*/

SELECT GREATEST(1,2,3,120)
SELECT LEAST(1,2,3,120)


/*Функция NULLIF выдаёт значение NULL, если значение1 равно значение2; 
 * в противном случае она 
 * возвращает значение1. Это может быть полезно для реализации 
 * обратной операции к COALESCE. В частности, для примера, показанного 
 * выше:*/
SELECT nullif(10,10) -- выдаст null ЕСЛИ значение 1 равно значению 2. В пртивном
слкчае возвращает значение 1.
SELECT  10 / NULLIF(0, 0.00) as safe_division --- не будет ошибки деления на ноль


SELECT DISTINCT departure_city, arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
ORDER BY departure_city;

/*к сожалению в этой выборке информация дублируется.Пары городов приведены 
 * по два раза для рейса туда и рейса обратно. Модифицируйте запрос таким 
 * образом, чтобы каждая пара городов была выведена только один раз.*/

SELECT DISTINCT 
    GREATEST(departure_city, arrival_city) AS departure_city,
    LEAST   (departure_city, arrival_city) AS arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
ORDER BY departure_city, arrival_city;

/*Сколько рейсов выполяентся из Москвы в Санкт - Петербург*/
SELECT count(*),departure_city,arrival_city  
FROM  routes
WHERE departure_city = 'Москва'
AND arrival_city = 'Санкт-Петербург'
GROUP BY departure_city,arrival_city 

/*Выяснить сколько рейсов летает из каждого города, без учета частоты
 * рейсов в неделю
 */

SELECT  departure_city, count(*)
FROM routes
GROUP BY departure_city
ORDER BY count DESC;


SELECT 
    LEAST(departure_city, arrival_city) || ' - ' || GREATEST(departure_city, arrival_city) AS city_pair,
    COUNT(*) as directions_count
FROM routes
GROUP BY 
    LEAST(departure_city, arrival_city),
    GREATEST(departure_city, arrival_city)
ORDER BY directions_count DESC;



SELECT 
    departure_city,
    COUNT(DISTINCT 
        CASE 
            WHEN departure_city < arrival_city 
            THEN departure_city || '->' || arrival_city
            ELSE arrival_city || '->' || departure_city
        END
    ) as unique_directions_count
FROM routes
GROUP BY departure_city
ORDER BY unique_directions_count DESC;



/*array_length в PostgreSQL — это функция, которая возвращает длину (количество элементов) 
указанного измерения массива.*/

SELECT 
    departure_city,
    arrival_city,
    COUNT(*) as daily_flights_count
FROM routes 
WHERE departure_city = 'Москва'
  AND array_length(days_of_week, 1) = 7  -- Рейсы, выполняющиеся КАЖДЫЙ день
GROUP BY arrival_city, departure_city
ORDER BY daily_flights_count DESC
LIMIT 5;

/*UNNEST в PostgreSQL — это функция, которая "разворачивает" массив в
 * набор строк. Она преобразует массив в таблицу, 
 * где каждый элемент массива становится отдельной строкой*/

/*Число рейсов которые вылетают из москвы каждый день недели
 *days_of_week это массив дней недели */
SELECT departure_city, UNNEST(days_of_week) AS day_of_week,
count(*) AS num_flight
FROM routes
WHERE departure_city = 'Москва'
group BY day_of_week,departure_city
ORDER BY  day_of_week


/*Если нам нужно превратить days of week находящиеся в массиве
 * в список более читаемых дней недели*/

SELECT
dw.name_of_day, 
count(*) AS num_flights
from(SELECT UNNEST(days_of_week) AS num_of_day
FROM routes
WHERE departure_city = 'Москва') AS r,
UNNEST ('{1,2,3,4,5,6,7}'::integer[], 
'{"Пн.","Вт.", "Ср.","Чт.","Пт.","Сб.","Вс." }'::text[]) AS dw(num_of_day, name_of_day)
WHERE r.num_of_day = dw.num_of_day
GROUP BY r.num_of_day, dw.name_of_day
ORDER BY r.num_of_day



SELECT
    dw.name_of_day, 
    COUNT(*) AS num_flights
FROM routes,
UNNEST(days_of_week) WITH ORDINALITY AS r (num_of_day, r_position)
JOIN UNNEST(
    '{1,2,3,4,5,6,7}'::integer[], 
    '{"Пн.","Вт.", "Ср.","Чт.","Пт.","Сб.","Вс."}'::text[]
) WITH ORDINALITY AS dw (num_of_day, name_of_day, dw_position) 

ON r.num_of_day = dw.num_of_day
WHERE departure_city = 'Москва'
GROUP BY dw.name_of_day, dw.dw_position
ORDER BY dw.dw_position;



SELECT
    SUM(CASE WHEN r.num_of_day = 1 THEN 1 ELSE 0 END) AS "Пн.",
    SUM(CASE WHEN r.num_of_day = 2 THEN 1 ELSE 0 END) AS "Вт.", 
    SUM(CASE WHEN r.num_of_day = 3 THEN 1 ELSE 0 END) AS "Ср.",
    SUM(CASE WHEN r.num_of_day = 4 THEN 1 ELSE 0 END) AS "Чт.",
    SUM(CASE WHEN r.num_of_day = 5 THEN 1 ELSE 0 END) AS "Пт.",
    SUM(CASE WHEN r.num_of_day = 6 THEN 1 ELSE 0 END) AS "Сб.",
    SUM(CASE WHEN r.num_of_day = 7 THEN 1 ELSE 0 END) AS "Вс."
FROM (
    SELECT UNNEST(days_of_week) AS num_of_day
    FROM routes
    WHERE departure_city = 'Москва'
) AS r;


WITH flight_days AS (
    SELECT UNNEST(days_of_week) AS num_of_day
    FROM routes
    WHERE departure_city = 'Москва'
)
SELECT
    COUNT(*) FILTER (WHERE num_of_day = 1) AS "Пн.",
    COUNT(*) FILTER (WHERE num_of_day = 2) AS "Вт.", 
    COUNT(*) FILTER (WHERE num_of_day = 3) AS "Ср.",
    COUNT(*) FILTER (WHERE num_of_day = 4) AS "Чт.",
    COUNT(*) FILTER (WHERE num_of_day = 5) AS "Пт.",
    COUNT(*) FILTER (WHERE num_of_day = 6) AS "Сб.",
    COUNT(*) FILTER (WHERE num_of_day = 7) AS "Вс."
FROM flight_days;


----CREATE EXTENSION IF NOT EXISTS tablefunc
-- Основной запрос с crosstab
/**Функция crosstab() принимает этот результат и преобразует его:
Логика преобразования:
Берет все строки с одинаковым row_id (у нас только 1)
Для каждой уникальной num_of_day создает отдельный столбец
Значения flights_count помещает в соответствующие столбцы
3. AS clause - определение структуры результата:
sql
AS ct(
    row_id int,           -- Первая колонка из исходных данных
    "Пн." int,           -- Столбец для num_of_day = 1
    "Вт." int,           -- Столбец для num_of_day = 2  
    "Ср." int,           -- Столбец для num_of_day = 3
    "Чт." int,           -- Столбец для num_of_day = 4
    "Пт." int,           -- Столбец для num_of_day = 5
    "Сб." int,           -- Столбец для num_of_day = 6
    "Вс." int            -- Столбец для num_of_day = 7
)

🔧 Ключевые правила crosstab:
1. Три колонки в исходном запросе:
row_id - идентификатор строки в результате
category - определяет имя столбца
value - значение для ячейки
2. Порядок важен:
Категории должны быть отсортированы в запросе
Столбцы в AS clause должны быть в том же порядке
*/

SELECT *
FROM crosstab(
    'SELECT 
        flight_no as row_id,    -- Разные рейсы = разные строки
        num_of_day,
        COUNT(*)::integer as flights_count
     FROM (
         SELECT flight_no , UNNEST(days_of_week) AS num_of_day
         FROM routes
         WHERE departure_city = ''Москва''
     ) AS r
     GROUP BY flight_no , num_of_day
     ORDER BY flight_no , num_of_day'
) AS ct(
    flight_no character(6),
    "Пн." int, "Вт." int, "Ср." int, "Чт." int, "Пт." int, "Сб." int, "Вс." int
);

/*Каковы максимальные и минимальные цены билетов на все направления*/
SELECT
	f.departure_city,
	f.arrival_city,
	max(tf.amount),
	min(tf.amount)
FROM
	flights_v f
JOIN ticket_flights tf ON
	f.flight_id = tf.flight_id
GROUP BY
	f.departure_city,
	f.arrival_city
ORDER BY
	f.departure_city,
	f.arrival_city
	
	
/*Выявить все направления где не было продано ни одного билета*/	
SELECT
	f.departure_city,
	f.arrival_city,
	f.flight_no,
	max(tf.amount),
	min(tf.amount)
FROM
	flights_v f
lEFT JOIN ticket_flights tf ON
	f.flight_id = tf.flight_id
GROUP BY
	f.departure_city,
	f.arrival_city,
	f.flight_no
HAVING 	max(tf.amount) IS NULL AND min(tf.amount) IS NULL 
ORDER BY
	f.departure_city,
	f.arrival_city
	
/*Как часто встречаются различные имена среди пассажиров,
 * получить распределение имен
 * 
 * Как работает:
 * strpos(passenger_name, ' ') - находит позицию первого 
 * пробела в строке - 1 - вычитает 1, чтобы не включать сам пробел
 * LEFT(..., n) - берет n символов с начала строки
 * passenger_name = 'Иван Петров'
 * strpos('Иван Петров', ' ') = 5  -- пробел на 5-й позиции
 * LEFT('Иван Петров', 5-1) = LEFT('Иван Петров', 4) = 'Иван'
 */

SELECT 
left(passenger_name, 
strpos(passenger_name, ' ')-1) AS first_name,
count(*) AS count
FROM tickets
GROUP BY first_name
ORDER BY count DESC


/*Функция split_part работает так:
Разбивает строку по пробелам на части
Возвращает часть под указанным номером (1 - первая часть)
Примеры:
split_part('Иван Петров', ' ', 1) → 'Иван'
split_part('Анна-Мария Сидорова', ' ', 1) → 'Анна-Мария'
split_part('Smith', ' ', 1) → 'Smith' (если пробела нет, 
возвращает всю строку)
*/

SELECT 
    split_part(passenger_name, ' ', 1) AS first_name,
    COUNT(*) AS count
FROM tickets
WHERE passenger_name IS NOT NULL
GROUP BY first_name
ORDER BY count DESC;


/*🔍 В чем разница между COUNT(*) и COUNT(b.*):

-COUNT(*)
Считает все строки в результате JOIN, включая те, где b.* полностью NULL
Включает пустые строки (диапазоны, где нет бронирований)

-COUNT(b.*)
Считает только строки, где хотя бы один столбец из b не NULL
Исключает пустые строки (будет показывать 0 вместо пропуска диапазона)*/
WITH RECURSIVE ranges (min_sum, max_sum) AS
(
VALUES(0, 100000)
UNION ALL 
SELECT min_sum + 100000, max_sum + 100000
FROM ranges
WHERE max_sum < (SELECT max(total_amount) FROM bookings)
)

SELECT r.min_sum, r.max_sum, count(*)
FROM bookings b
RIGHT OUTER JOIN ranges r
ON b.total_amount >= r.min_sum
AND b.total_amount < r.max_sum
GROUP BY r.min_sum, r.max_sum
ORDER BY r.min_sum;

/*Отсортируем строки по имени и фамилии пассажиров*/

SELECT 
t.passenger_name,
substr(t.passenger_name, strpos(t.passenger_name,' ')+1) AS lastname,
LEFT(t.passenger_name, strpos(t.passenger_name,' ')-1) AS firstname
FROM
ticket_flights tf
JOIN tickets t ON tf.ticket_no = t.ticket_no
JOIN boarding_passes b ON tf.ticket_no = b.ticket_no
AND tf.flight_id =b.flight_id 
WHERE tf.flight_id = 27584


/*Парсинг адресов по столбцам*/
WITH address_components AS (
    SELECT 
        'г. Краснодар р-н. Прикубанский, ул. Авиагородок, д. 20, кв. 39' as full_address
),
parsed_address AS (
    SELECT 
        full_address,
        -- Город
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'г\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'город\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'г\s*([^,]+)'), '')
        ) as city,
        
        -- Район
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'р-н\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'район\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'р-н\s*([^,]+)'), '')
        ) as district,
        
        -- Улица
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'ул\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'улица\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'ул\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'проспект\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'пр-т\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'проезд\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'шоссе\s*([^,]+)'), '')
        ) as street,
        
        -- Дом
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'д\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'дом\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'д\s*([^,]+)'), '')
        ) as house,
        
        -- Квартира
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'кв\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'квартира\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'кв\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'к\.\s*([^,]+)'), '')
        ) as apartment,
        
        -- Корпус/строение
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM 'корп\.\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'корпус\s*([^,]+)'), ''),
            NULLIF(SUBSTRING(full_address FROM 'кorp\.\s*([^,]+)'), '')
        ) as building,
        
        -- Индекс (если есть)
        COALESCE(
            NULLIF(SUBSTRING(full_address FROM '^\d{6}'), ''),
            NULLIF(SUBSTRING(full_address FROM '\b\d{6}\b'), '')
        ) as postal_code
        
    FROM address_components
)
SELECT 
    full_address as "Полный адрес",
    city as "Город",
    district as "Район", 
    street as "Улица",
    house as "Дом",
    apartment as "Квартира",
    building as "Корпус",
    postal_code as "Индекс"
FROM parsed_address;


/*Изменение данных*/

/*Содадим первую временную таблицу без копирования данных 
*
*наложим на поля ограничения
*/

DROP TABLE IF EXISTS aircrafts_tmp;
CREATE TEMP TABLE aircrafts_tmp AS
SELECT * FROM aircrafts WITH NO DATA 

SELECT *
FROM  aircrafts_tmp

/*При массовом вводе данных гораздо более эффективно сначала добавить строки
 * в таблицу а уже потом нкаллладывать ограничения на нее.*/
ALTER TABLE aircrafts_tmp
ADD PRIMARY KEY(aircraft_code);

ALTER TABLE aircrafts_tmp
ADD UNIQUE (model);


CREATE TEMP TABLE aircrafts_log AS
SELECT * FROM aircrafts WITH NO DATA 

ALTER TABLE aircrafts_log
ADD COLUMN when_add timestamp;

ALTER TABLE aircrafts_log
ADD COLUMN operation text;

/*Создать таблицу по образу и подобию CREATE TEMP TABLE aircrafts_tmp
(LIKE aircrafts INCLUDING CONSTRAINTS INCLUDING INDEXES)
*/


WITH add_row AS (
insert INTO aircrafts_tmp
SELECT *
FROM aircrafts
RETURNING * ---обязательно
)
INSERT INTO aircrafts_log
SELECT a.aircraft_code, a.model, a.range, 'insert',current_timestamp 
FROM add_row a

/*Пи вставке строк могут возникать ситуации, когда нарушетс ограничение 
 * первичного или уникального ключей, поскольку вставляемые строки могут 
 * иметь значения ключевых аттрибутов, совпадающие с теми, что уже имеются 
 * в таблице. Для таких случаев предусмотрено специальное средство - 
 * предложение on conflict оно предусматривает два варианта действий на 
 * выбор программиста
 * Первый вариант - отменять добавление новой строки, для которой имеет место конфликт значений 
 * ключевых атрибуетов, и при этом не порождать сообщения об ошибке.
 * Второй вариант - заключается в замене операции добавления новой строки 
 * операцией обновления существующей строки, с которой конфликтует 
 * добавляемая строка.*/

WITH add_row AS (
insert INTO aircrafts_tmp
values('SU9', 'Sukhoi SuperJet-100', 3000)
ON CONFLICT DO NOTHING 
RETURNING * ---обязательно
)
INSERT INTO aircrafts_log
SELECT a.aircraft_code, a.model, a.range, 'insert',current_timestamp 
FROM add_row a

/*Результат insert 0 строк*/

insert INTO aircrafts_tmp
values('S99', 'Sukhoi SuperJet-100', 3000)
ON CONFLICT (aircraft_code) DO NOTHING ---укажем столбец проверки
RETURNING *;
/*Проверяется уникальность model 
 * SQL Error [23505]: ERROR: duplicate key value violates unique constraint "aircrafts_tmp_model_key"
  Подробности: Key (model)=(Sukhoi SuperJet-100) already exists.*/

/*
Теперь рассмотрим вариант номер 2 on  conflict когда операция вставки 
* заменяется операцией обновления действующей строки, с которой возник 
* конфликт значений столбцов
* для реализации этой возможности служит do update
*/
insert INTO aircrafts_tmp
values('SU9', 'Sukhoi SuperJet', 4000)
ON CONFLICT ON CONSTRAINT aircrafts_tmp_pkey
DO UPDATE SET 
              model = excluded.model,
              range = excluded.range
RETURNING *;

/*Здесь произошло обновление model c Sukhoi SuperJet-100 на Sukhoi SuperJet*/
SELECT *
FROM  aircrafts_tmp

/*Как посмотреть constraint_name  и constraint_type
SELECT 
    conname as constraint_name,
    contype as constraint_type
FROM pg_constraint 
WHERE conrelid = 'pg_temp.aircrafts_tmp'::regclass
*/

---Скопировать из таблицы в файл
COPY aircrafts_tmp TO 'D:/aircrafts_tmp.txt' WITH (format csv)
--если формат не указывать то разделители будут с таубляцией
---Скопировать в таблицу из файла
---TRUNCATE TABLE aircrafts_tmp
COPY aircrafts_tmp FROM 'D:/aircrafts_tmp.txt'

/*Обновление строк в таблицах
* Команда update предназначена для обновления данных в табицах
* начнем с того, как можно организовать запись выполненных операций
* в журнальную таблицу
*/

EXPLAIN (ANALYZE, TIMING ON) 
SELECT a.aircraft_code, f.flight_no
FROM aircrafts a
JOIN flights f ON a.aircraft_code = f.aircraft_code
WHERE a.range > 5000;


EXPLAIN SELECT * FROM aircrafts WHERE aircraft_code = 'SU9';


SELECT 
    attname as column_name,
    n_distinct as distinct_values,
    most_common_vals as common_values,
    most_common_freqs as frequencies
FROM pg_stats 
WHERE tablename = 'aircrafts';


SET random_page_cost = 4.0;

SELECT name, setting, unit, context, vartype
FROM pg_settings 
WHERE name IN ('random_page_cost', 'seq_page_cost');


EXPLAIN (ANALYZE, TIMING ON) 
SELECT *
FROM aircrafts;


EXPLAIN SELECT *
FROM aircrafts
WHERE model ~ 'Air';


EXPLAIN (ANALYZE, TIMING ON) SELECT *
FROM aircrafts
ORDER BY aircraft_code;


EXPLAIN SELECT *
FROM bookings
ORDER BY book_ref --индексируемый столбец


EXPLAIN SELECT *
FROM bookings
WHERE book_ref > '0000FF' AND book_ref < '000FFF'
ORDER BY book_ref;


EXPLAIN SELECT *
FROM seats
WHERE aircraft_code = 'SU9';

/*Да, ваш запрос WHERE aircraft_code = 'SU9' будет использовать составной 
индекс (aircraft_code, seat_no), потому что поиск идет по первому столбцу 
индекса. 
Это один из самых эффективных сценариев использования составных индексов! ✅
Составные индексы в PostgreSQL работают по принципу "префиксного поиска" 
- можно использовать любое начало индекса, но нельзя пропускать столбцы.
*/

-- Точное совпадение по первому полю
WHERE aircraft_code = 'SU9'
-- Точное совпадение по обоим полям  
WHERE aircraft_code = 'SU9' AND seat_no = '1A'
-- Диапазон по первому полю
WHERE aircraft_code BETWEEN 'SU9' AND 'SU100'
-- IN по первому полю
WHERE aircraft_code IN ('SU9', 'SU10')


EXPLAIN SELECT book_ref
FROM bookings
WHERE book_ref < '000FFF'
ORDER BY book_ref;


EXPLAIN SELECT *
FROM seats
WHERE aircraft_code = 'SU9';

EXPLAIN SELECT count( * )
FROM seats
WHERE aircraft_code = 'SU9';


EXPLAIN SELECT avg( total_amount )
FROM bookings;


EXPLAIN 
SELECT avg(total_amount) as exact_avg,
(SELECT avg(total_amount) 
FROM bookings TABLESAMPLE SYSTEM(1)
) as approx_avg
FROM bookings;



CREATE INDEX CONCURRENTLY idx_bookings_total_amount 
ON bookings(total_amount) 
WHERE total_amount IS NOT NULL;

-- Тогда возможен Index Only Scan
EXPLAIN SELECT avg(total_amount) FROM bookings;


CREATE EXTENSION IF NOT EXISTS pg_stat_statements;


SELECT avg(total_amount) FROM bookings;

SELECT *
FROM pg_stat_statements 
WHERE query LIKE '%avg(total_amount)%';

EXPLAIN SELECT a.aircraft_code,
a.model,
s.seat_no,
s.fare_conditions
FROM seats s
JOIN aircrafts a ON s.aircraft_code = a.aircraft_code
WHERE a.model ~ '^Air'
ORDER BY s.seat_no;




EXPLAIN
SELECT
	r.flight_no,
	r.departure_airport_name,
	r.arrival_airport_name,
	a.model
FROM
	routes r
JOIN aircrafts a ON
	r.aircraft_code = a.aircraft_code
ORDER BY
	flight_no;





EXPLAIN SELECT t.ticket_no,
t.passenger_name,
tf.flight_id,
tf.amount
FROM tickets t
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
ORDER BY t.ticket_no
LIMIT 40;



EXPLAIN ANALYZE
SELECT t.ticket_no,
t.passenger_name,
tf.flight_id,
tf.amount
FROM tickets t
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
ORDER BY t.ticket_no;



EXPLAIN ANALYZE
SELECT t.ticket_no,
t.passenger_name,
tf.flight_id,
tf.amount
FROM tickets t
JOIN ticket_flights tf ON t.ticket_no = tf.ticket_no
WHERE amount > 50000
ORDER BY t.ticket_no;



EXPLAIN (ANALYZE, COSTS OFF)
SELECT a.aircraft_code,
a.model,
s.seat_no,
s.fare_conditions
FROM seats s
JOIN aircrafts a ON s.aircraft_code = a.aircraft_code
WHERE a.model ~ '^Air'
ORDER BY s.seat_no;

/*Как можно посмотреть план транзакции*/

BEGIN;
EXPLAIN (ANALYZE, COSTS OFF)
UPDATE aircrafts
SET range = range + 100
WHERE model ~ '^Air';
ROLLBACK;


EXPLAIN (ANALYZE, COSTS OFF)
SELECT *
FROM aircrafts
WHERE model ~ '^Air';




SHOW join_collapse_limit


-- СЛУЧАЙ 1: Вы знаете оптимальный порядок
SET join_collapse_limit = 1;

SELECT *
FROM tiny_dimension td      -- 10 строк
JOIN small_filtered_table s -- 1K строк после WHERE
  ON td.id = s.dim_id
JOIN large_fact_table l     -- 10M строк
  ON s.id = l.small_id
WHERE s.date > '2023-01-01';

-- СЛУЧАЙ 2: Для дебаггинга планов запросов
SET join_collapse_limit = 1;
EXPLAIN ANALYZE YOUR_QUERY; -- Предсказуемый порядок
SET join_collapse_limit = 8; -- Вернуть по умолчанию


-- Жесткая фиксация плана выполнения
SET join_collapse_limit = 1;
SET from_collapse_limit = 1;

WITH 
filtered_orders AS (
    SELECT * FROM orders WHERE total_amount > 1000
),
active_customers AS (
    SELECT * FROM customers WHERE status = 'active'
)
SELECT *
FROM active_customers ac
JOIN filtered_orders fo ON ac.id = fo.customer_id
JOIN products p ON fo.product_id = p.id;

-- Гарантированный порядок:
-- 1. active_customers (фильтрация)
-- 2. filtered_orders (фильтрация) 
-- 3. products
-- 4. Соединение в строгом порядке



SET join_collapse_limit = 1;

-- Выполнить запросы
SELECT a.aircraft_code,
a.model,
s.seat_no,
s.fare_conditions
FROM seats s
JOIN aircrafts a ON s.aircraft_code = a.aircraft_code
WHERE a.model ~ '^Air'
ORDER BY s.seat_no;

-- Проверить значение
SHOW join_collapse_limit;
-- Вернуть значение по умолчанию (когда закончите)
SET join_collapse_limit TO DEFAULT;




ANALYZE aircrafts


-- Вся статистика по таблице aircrafts
SELECT *
FROM pg_stats 
WHERE tablename = 'aircrafts'
ORDER BY attname;


-- Размер таблицы и оценка количества строк
SELECT 
    schemaname,
    relname as table_name,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    n_mod_since_analyze as modified_since_analyze,
    last_analyze,
    last_autoanalyze,
    analyze_count
FROM pg_stat_all_tables 
WHERE relname = 'aircrafts';


-- Когда собиралась статистика
SELECT 
    schemaname,
    relname as table_name,
    last_analyze,
    last_autoanalyze,
    analyze_count,
    now() - last_analyze as since_last_analyze
FROM pg_stat_all_tables 
WHERE relname = 'aircrafts';


-- Статистика использования индексов
SELECT 
    schemaname,
    relname as table_name,
    indexrelname as index_name,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_all_indexes 
WHERE relname = 'aircrafts'
AND schemaname ='bookings';



SELECT 
    attname as table_name,
    n_distinct as "Уникальных значений",
    round(null_frac::numeric, 4) as "Доля NULL",
    case 
        when n_distinct = -1 then 'Все значения уникальны'
        when n_distinct = 1 then 'Все значения одинаковы' 
        else n_distinct::text
    end as "Анализ уникальности"
FROM pg_stats 
WHERE tablename = 'aircrafts';

/*Сравнение данных статистики*/
-- Создаем временную таблицу для сравнения
CREATE TEMP TABLE stats_before AS 
SELECT * FROM pg_stats WHERE tablename = 'aircrafts';

-- Выполняем ANALYZE
ANALYZE aircrafts;

-- Сравниваем изменения
SELECT 
    b.attname,
    b.n_distinct as before_distinct,
    a.n_distinct as after_distinct,
    b.null_frac as before_null_frac,
    a.null_frac as after_null_frac
FROM stats_before b
JOIN pg_stats a ON b.tablename = a.tablename AND b.attname = a.attname
WHERE b.tablename = 'aircrafts';


-- Полный отчет по статистике aircrafts
SELECT 
    'Таблица: ' || relname as info,
    'Живых строк: ' || n_live_tup as live_tuples,
    'Мертвых строк: ' || n_dead_tup as dead_tuples,
    'Изменено после анализа: ' || n_mod_since_analyze as modified,
    'Последний ANALYZE: ' || coalesce(last_analyze::text, 'НИКОГДА') as last_analyze
FROM pg_stat_all_tables 
WHERE relname = 'aircrafts'
AND schemaname ='bookings'

UNION ALL

SELECT 
    'Колонка: ' || attname,
    'Уникальных значений: ' || n_distinct,
    'NULL: ' || round((null_frac * 100)::numeric, 2) || '%',
    'Корреляция: ' || round(correlation::numeric, 4),
    'Гистограмма: ' || CASE WHEN histogram_bounds IS NOT NULL THEN 'ЕСТЬ' ELSE 'НЕТ' END
FROM pg_stats 
WHERE tablename = 'aircrafts'
AND schemaname ='bookings';






CREATE OR REPLACE FUNCTION get_table_stats(
    p_table_name TEXT,
    p_schema_name TEXT DEFAULT 'public'
) 
RETURNS TABLE(
    section_type TEXT,
    metric_name TEXT,
    metric_value TEXT,
    additional_info TEXT,
    last_updated TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Проверяем существование таблицы
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = p_schema_name 
        AND table_name = p_table_name
    ) THEN
        RAISE EXCEPTION 'Таблица %.% не существует', p_schema_name, p_table_name;
    END IF;

    -- Возвращаем статистику по таблице
    RETURN QUERY
    -- Статистика таблицы
    SELECT 
        'TABLE_STATS'::TEXT as section_type,
        'Основная статистика'::TEXT as metric_name,
        'Таблица: ' || p_table_name as metric_value,
        'Схема: ' || p_schema_name as additional_info,
        'Размер: ' || pg_size_pretty(pg_total_relation_size(p_schema_name || '.' || p_table_name)) as last_updated
    
    UNION ALL
    
    SELECT 
        'TABLE_STATS'::TEXT,
        'Живых строк',
        n_live_tup::TEXT,
        'Активные записи',
        'Мертвых: ' || n_dead_tup::TEXT
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    SELECT 
        'TABLE_STATS'::TEXT,
        'Изменения',
        n_mod_since_analyze::TEXT,
        'После последнего ANALYZE',
        CASE 
            WHEN n_mod_since_analyze > n_live_tup * 0.1 THEN 'ТРЕБУЕТ ANALYZE!'
            ELSE 'В пределах нормы'
        END
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    SELECT 
        'TABLE_STATS'::TEXT,
        'Последний ANALYZE',
        COALESCE(last_analyze::TEXT, 'НИКОГДА'),
        'Авто-ANALYZE: ' || COALESCE(last_autoanalyze::TEXT, 'НИКОГДА'),
        CASE 
            WHEN last_analyze IS NULL THEN 'Рекомендуется ANALYZE'
            WHEN now() - last_analyze > interval '7 days' THEN 'Старая статистика'
            ELSE 'Актуально'
        END
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    -- Статистика по колонкам - часть 1
    SELECT 
        'COLUMN_STATS'::TEXT,
        'Колонка: ' || attname,
        CASE 
            WHEN n_distinct = -1 THEN 'Все уникальны'
            WHEN n_distinct < 0 THEN round((n_distinct * -100)::numeric, 1) || '% уникальных'
            ELSE n_distinct::TEXT || ' уникальных'
        END,
        'NULL: ' || round((null_frac * 100)::numeric, 2) || '%',
        CASE 
            WHEN correlation IS NULL THEN 'Корр: N/A'
            ELSE 'Корр: ' || round(correlation::numeric, 4)
        END
    FROM pg_stats 
    WHERE tablename = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    -- Статистика по колонкам - часть 2 (исправленная)
    SELECT 
        'COLUMN_STATS'::TEXT,
        'Колонка: ' || attname,
        CASE 
            WHEN most_common_vals IS NOT NULL THEN 
                'Топ значений: ' || array_length(most_common_vals, 1)::TEXT
            ELSE 'Нет частых значений'
        END,
        CASE 
            WHEN histogram_bounds IS NOT NULL THEN 
                'Гистограмма: ЕСТЬ (' || 
                (array_length(histogram_bounds, 1) - 1)::TEXT || ' корзин)'
            ELSE 'Гистограмма: НЕТ'
        END,
        'Тип: ' || (
            SELECT data_type 
            FROM information_schema.columns 
            WHERE table_schema = p_schema_name 
            AND table_name = p_table_name 
            AND column_name = attname
        )
    FROM pg_stats 
    WHERE tablename = p_table_name AND schemaname = p_schema_name;

END;
$$;




CREATE OR REPLACE FUNCTION get_table_stats_clear(
    p_table_name TEXT,
    p_schema_name TEXT DEFAULT 'public'
) 
RETURNS TABLE(
    category TEXT,           -- Категория информации
    item_name TEXT,          -- Название элемента
    item_value TEXT,         -- Значение элемента
    details TEXT,            -- Дополнительные детали
    distribution TEXT        -- Информация о распределении
) 
LANGUAGE plpgsql
AS $$
DECLARE
    total_rows BIGINT;
BEGIN
    -- Получаем общее количество строк в таблице
    SELECT n_live_tup INTO total_rows
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name;
    
    IF total_rows IS NULL THEN
        RAISE EXCEPTION 'Таблица %.% не существует или не имеет статистики', p_schema_name, p_table_name;
    END IF;

    RETURN QUERY
    -- ОБЩАЯ ИНФОРМАЦИЯ О ТАБЛИЦЕ
    SELECT 
        '📊 ТАБЛИЦА'::TEXT,
        'Размер таблицы',
        pg_size_pretty(pg_total_relation_size(p_schema_name || '.' || p_table_name)),
        'Схема: ' || p_schema_name,
        'Таблица: ' || p_table_name
    
    UNION ALL
    
    SELECT 
        '📊 ТАБЛИЦА'::TEXT,
        'Количество строк',
        total_rows::TEXT,
        'Активные записи',
        'Мертвых строк: ' || n_dead_tup::TEXT || ' (' || 
        ROUND((n_dead_tup * 100.0 / GREATEST(total_rows + n_dead_tup, 1))::numeric, 1) || '%)'
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    SELECT 
        '📊 ТАБЛИЦА'::TEXT,
        'Статистика ANALYZE',
        CASE 
            WHEN last_analyze IS NULL THEN 'НИКОГДА'
            ELSE to_char(last_analyze, 'DD.MM.YYYY HH24:MI')
        END,
        'Авто-ANALYZE: ' || CASE 
            WHEN last_autoanalyze IS NULL THEN 'НИКОГДА'
            ELSE to_char(last_autoanalyze, 'DD.MM.YYYY HH24:MI')
        END,
        CASE 
            WHEN n_mod_since_analyze > total_rows * 0.1 THEN '⚠️ ТРЕБУЕТ ANALYZE!'
            WHEN last_analyze IS NULL THEN '🔴 Статистики нет'
            WHEN now() - last_analyze > interval '7 days' THEN '🟡 Старая статистика'
            ELSE '✅ Актуально'
        END
    FROM pg_stat_all_tables 
    WHERE relname = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    -- СТАТИСТИКА ПО КОЛОНКАМ
    SELECT 
        '🎯 КОЛОНКА'::TEXT,
        attname,
        CASE 
            WHEN n_distinct = -1 THEN '100% уникальных'
            WHEN n_distinct < 0 THEN ROUND((n_distinct * -100)::numeric, 1) || '% уникальных'
            ELSE n_distinct::TEXT || ' уникальных'
        END,
        'NULL: ' || ROUND((null_frac * 100)::numeric, 2) || '%',
        CASE 
            WHEN correlation IS NULL THEN 'Корреляция: N/A'
            ELSE 'Корреляция: ' || ROUND(correlation::numeric, 3)
        END
    FROM pg_stats 
    WHERE tablename = p_table_name AND schemaname = p_schema_name
    
    UNION ALL
    
    -- ИНФОРМАЦИЯ О ГИСТОГРАММАХ
    SELECT 
        '📈 ГИСТОГРАММА'::TEXT,
        attname,
        (array_length(histogram_bounds, 1) - 1)::TEXT || ' корзин',
        '≈' || ROUND((100.0 / (array_length(histogram_bounds, 1) - 1))::numeric, 1) || '% на корзину',
        CASE 
            WHEN most_common_vals IS NOT NULL THEN 
                'Топ-' || array_length(most_common_vals, 1)::TEXT || ' значений'
            ELSE 'Нет частых значений'
        END
    FROM pg_stats 
    WHERE tablename = p_table_name AND schemaname = p_schema_name
      AND histogram_bounds IS NOT NULL;

END;
$$;

/*статитика*/
SELECT * FROM get_table_stats_clear('aircrafts', 'bookings')

SELECT * FROM get_table_stats('aircrafts', 'bookings')


EXPLAIN
SELECT num_tickets, count( * ) AS num_bookings
FROM
( SELECT b.book_ref,

( SELECT count( * ) FROM tickets t
WHERE t.book_ref = b.book_ref
) AS num_tickets

FROM bookings b
WHERE date_trunc( 'mon', book_date ) = '2016-09-01'
) AS count_tickets( book_ref, num_tickets )
GROUP by num_tickets
ORDER BY num_tickets DESC;


CREATE INDEX tickets_book_ref_key
ON tickets ( book_ref );


EXPLAIN ANALYZE 
SELECT date_trunc('mon', book_date), num_tickets, count( * ) AS num_bookings
FROM
( SELECT b.book_ref, date_trunc('mon', b.book_date) AS book_date,

( SELECT count( * ) FROM tickets t
WHERE t.book_ref = b.book_ref
) AS num_tickets

FROM bookings b
--WHERE date_trunc( 'mon', book_date ) = '2016-09-01'
) AS count_tickets( book_ref, book_date, num_tickets )
GROUP by book_date, num_tickets
ORDER BY book_date, num_tickets DESC;


SELECT num_tickets, count( * ) AS num_bookings
FROM
( SELECT b.book_ref,

( SELECT count( * ) FROM tickets t
WHERE t.book_ref = b.book_ref
) AS num_tickets

FROM bookings b
WHERE date_trunc( 'mon', book_date ) = '2016-09-01'
) AS count_tickets( book_ref, num_tickets )
GROUP by num_tickets
ORDER BY num_tickets DESC;


EXPLAIN ANALYZE
SELECT num_tickets, count( * ) AS num_bookings
FROM
( SELECT b.book_ref, count( * )
FROM bookings b, tickets t
WHERE date_trunc( 'mon', b.book_date ) = '2016-09-01'
AND t.book_ref = b.book_ref
GROUP BY b.book_ref
) AS count_tickets( book_ref, num_tickets )
GROUP by num_tickets
ORDER BY num_tickets DESC;




EXPLAIN ANALYZE 
SELECT num_tickets, count( * ) AS num_bookings
FROM
( SELECT b.book_ref, count( * )
FROM bookings b 
INNER JOIN tickets t on t.book_ref = b.book_ref
WHERE date_trunc( 'mon', b.book_date ) = '2016-09-01'
GROUP BY b.book_ref
) AS count_tickets( book_ref, num_tickets )
GROUP by num_tickets
ORDER BY num_tickets DESC;



/*Index Scan using bookings_pkey on bookings  (cost=0.43..45531.98 rows=1625803 width=21) (actual time=0.036..112.045 rows=1632187 loops=1)
  Index Cond: (book_ref > '3A26EF'::bpchar)
Planning Time: 0.377 ms
Execution Time: 142.635 ms*/
EXPLAIN  ANALYZE 
SELECT *
FROM bookings
WHERE book_ref > '3A26EF'
ORDER BY book_ref;



EXPLAIN ANALYZE 
WITH book AS (
    SELECT *
    FROM bookings b
    WHERE b.book_ref > '3A26EF'
    ORDER BY b.book_ref
)
SELECT * 
FROM book b
 INNER JOIN bookings c ON b.book_ref= c.book_ref; 


SHOW shared_buffers

SHOW work_mem;



EXPLAIN ANALYZE
SELECT a.aircraft_code AS a_code,
a.model,

( SELECT count( r.aircraft_code )
FROM routes r
WHERE r.aircraft_code = a.aircraft_code
) AS num_routes
ircrafts a
GROUP BY 1, 2
ORDER BY 3 DESC;



EXPLAIN ANALYZE
SELECT a.aircraft_code AS a_code,
a.model,
count( r.aircraft_code ) AS num_routes
FROM aircrafts a
LEFT OUTER JOIN routes r
ON r.aircraft_code = a.aircraft_code
GROUP BY 1, 2



EXPLAIN ANALYZE
SELECT b.book_ref, sum( tf.amount )
FROM bookings b, tickets t, ticket_flights tf
WHERE b.book_ref = t.book_ref
AND t.ticket_no = tf.ticket_no
GROUP BY 1
ORDER BY 1;


EXPLAIN ANALYZE
SELECT book_ref, total_amount
FROM bookings
ORDER BY 1;

ORDER BY 3 DESC;


DROP TABLE nulls
CREATE TABLE nulls AS
SELECT num::integer, 'TEXT' || num::text AS txt
FROM generate_series( 1, 30000000 ) AS gen_ser( num );

CREATE INDEX nulls_ind
ON nulls ( num );

ANALYZE nulls 


INSERT INTO nulls
VALUES ( NULL, 'TEXT' );


EXPLAIN
SELECT *
FROM nulls
ORDER BY num;


SELECT *
FROM nulls
ORDER BY num
OFFSET 29999999;



EXPLAIN
SELECT *
FROM nulls
ORDER BY num NULLS FIRST;


EXPLAIN
SELECT *
FROM nulls
ORDER BY num DESC NULLS FIRST;

CREATE INDEX nulls_ind_desc_nulls_first ON nulls (num DESC NULLS FIRST);

EXPLAIN
SELECT count(*)
FROM nulls 


CREATE INDEX nulls_num_nulls_first ON nulls (num NULLS FIRST);

EXPLAIN
SELECT *
FROM nulls
ORDER BY num NULLS FIRST;

SELECT * FROM nulls  WHERE txt = 'TEXT' OFFSET 0

/*Бизнес-требование: "Найти менеджеров, у которых средняя сумма заказов 
их подчиненных превышает среднюю по компании"*/
SELECT m.name
FROM Employees m
WHERE m.position = 'manager'
AND (SELECT AVG(o.amount) 
       FROM Employees e 
       JOIN Orders o ON e.id = o.employee_id 
       WHERE e.manager_id = m.id) > 
      (SELECT AVG(amount) FROM Orders);


WITH 
-- 1. Средняя сумма заказов по компании
company_avg AS (
    SELECT AVG(amount) AS avg_amount
    FROM Orders
),

-- 2. Средняя сумма заказов по каждому менеджеру (по его подчиненным)
manager_team_avg AS (
    SELECT 
        e.manager_id,
        AVG(o.amount) AS team_avg_amount
    FROM Employees e
    JOIN Orders o ON e.id = o.employee_id
    WHERE e.manager_id IS NOT NULL
    GROUP BY e.manager_id
)

-- 3. Основной запрос
SELECT 
    m.name AS manager_name,
    mta.team_avg_amount,
    ca.avg_amount AS company_avg_amount
FROM Employees m
JOIN manager_team_avg mta ON m.id = mta.manager_id
CROSS JOIN company_avg ca
WHERE m.position = 'manager'
AND mta.team_avg_amount > ca.avg_amount;

WITH 
manager_performance AS (
    SELECT 
        e.manager_id,
        AVG(o.amount) AS team_avg_amount,
        (SELECT AVG(amount) FROM Orders) AS company_avg_amount
    FROM Employees e
    JOIN Orders o ON e.id = o.employee_id
    WHERE e.manager_id IS NOT NULL
    GROUP BY e.manager_id
)

SELECT 
    m.name AS manager_name,
    mp.team_avg_amount,
    mp.company_avg_amount
FROM Employees m
JOIN manager_performance mp ON m.id = mp.manager_id
WHERE m.position = 'manager'
  AND mp.team_avg_amount > mp.company_avg_amount;
