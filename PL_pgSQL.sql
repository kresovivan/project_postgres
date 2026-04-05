/*Обозначения:

[ ] = "Можно не писать" (как опция в меню)

{ } = "Обязательно что-то написать" (как пустое поле, которое надо заполнить)

| — выбрать ОДИН из вариантов

; = "Точка в конце предложения"

< > — замените на реальное значение

(<Список столбцов первичного ключа родительской таблицы>) - перечисление столбцов в круглых скобках


Структура программы PL/pgSQL - является процедурным языком и
  позволяет использовать средства процедурных языков программирования:
  1.переменные,
  2.условные операторы,
  3.операторы циклов

  совместно с операторами SQL

  Используя эти средства можно создавать:
  - функции,
  - хранимые процедуры,
  - триггеры!!!

  - Процедуры необходимы в тех случаях, когда нужно внести изменения в данные.
  - Функции необходимы когда нужно выполнить задачу по обработке данных и вернуть в
  вызывающую среду результат этой обработки, результат может представлять как скалярное значение,
  так и таблицу.
  - Триггеры необходимы для обеспечения выполнения бизнес-правил, реализации правил безопасности, контроля
  изменений, которые пользователи вносят в таблицы базы данных.
*/


/*1. Основные конструкции языка.
  Структура блока PL/pgSQL
  все программы PL/pgSQL состоят из блоков, блок определяет операторы, предназначенные для
  решения определенной задачи.
  Одна программа может содержать несколько блоков, которые могут выполняться один за другим
  или быть вложенными.

  Блоки могу быть анонимными или именованными.
  Анонимные блоки не имеют имени, они не могут быть сохранены в базе данных и на них нельзя ссылаться.
  Именованные блоки используют при создании подпрограмм, эти блоки представляют собой процедуры, которые
  хранятся в базе данных, и которые можно вызвать по имени.

  DECLARE
  -Раздел объявлений - определения типов, переменных, курсоров, локальных подпрограмм и исключений
  BEGIN
  -Выполняемый раздел может содержать:
  - операторы присваивания
  - операторы управления
  - операторы SQL
  EXCEPTION
  -Раздел обработки ошибок
  END;
*/


/*2. Анонимные блоки.
  Блоки, которые являются приложением, взаимодействующим с базой данных
  Они могут создаваться в клиентских программах для вызова хранимых процедур, функций,
  содержащихся в БД, для автоматизации административных задач в БД
  Они:
  -Не имеют имени.
  -Не хранятся в базе данных.
  -Компилируются при каждом выполнении.
  -Передаются PL/pgSQL Engine для выполнения в реальном времени.
  -Не могут быть вызваны.
*/

set search_path = "hr_poc";

DO
$$
    DECLARE
        a         real := -1;  -- Коэффициент a квадратного уравнения (при x²), инициализирован -1
        b         real := -1;  -- Коэффициент b квадратного уравнения (при x), инициализирован -1
        c         real := -6;  -- Свободный член c квадратного уравнения, инициализирован -6
        d         real;        -- Переменная для хранения дискриминанта (будет вычислена позже)
        x1        real;        -- Переменная для первого корня уравнения (будет вычислена позже)
        x2        real;        -- Переменная для второго корня уравнения (будет вычислена позже)
        text_var1 text;        -- Переменная для текста сообщения об ошибке (используется в EXCEPTION)
        text_var2 text;        -- Переменная для кода SQLSTATE ошибки (используется в EXCEPTION)
    BEGIN

        d := SQRT(b * b - 4 * a * c);  -- Вычисляем дискриминант: d = √(b² - 4ac) = √((-1)² - 4*(-1)*(-6)) = √(1 - 24) = √(-23) → будет ошибка!
        x1 := (-b - d) / (2 * a);      -- Вычисляем первый корень по формуле: x1 = (-b - √d) / 2a
        x2 := (-b + d) / (2 * a);      -- Вычисляем второй корень по формуле: x2 = (-b + √d) / 2a
        RAISE NOTICE 'Результат: ';    -- Выводим заголовок результата
        RAISE NOTICE 'Корни уравнения: a*x*x + b*x + c = 0';  -- Выводим вид уравнения
        RAISE NOTICE ' x1 = %', x1;    -- Выводим значение первого корня
        RAISE NOTICE ' x2 = %', x2;    -- Выводим значение второго корня

    EXCEPTION
        WHEN OTHERS THEN  -- Перехватываем ЛЮБУЮ возникшую ошибку
            GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,  -- Получаем текст сообщения об ошибке
                text_var2 = RETURNED_SQLSTATE;                 -- Получаем код SQLSTATE ошибки
            RAISE NOTICE 'Причина ошибки = %', text_var1;       -- Выводим причину ошибки
            RAISE NOTICE 'Код ошибки = %', text_var2;           -- Выводим код ошибки

    END
$$;

/*Где это возможно необходимо делать обработку ошибок, проверку ошибок,
  а не обработку исключений*/

DO
$$
    DECLARE
        a         real :=  1;
        b         real := -1;
        c         real := -6;
        d         real;
        x1        real;
        x2        real;
    BEGIN
        IF (b * b - 4 * a * c) >= 0
        THEN

            d := SQRT(b * b - 4 * a * c);
            x1 := (-b - d) / (2 * a);
            x2 := (-b + d) / (2 * a);
            RAISE NOTICE 'Результат: ';
            RAISE NOTICE 'Корни уравнения: a*x*x + b*x + c = 0';
            RAISE NOTICE ' x1 = %', x1;
            RAISE NOTICE ' x2 = %', x2;

        ELSE
            RAISE NOTICE 'Результат: ';
            RAISE NOTICE 'Действительных корней нет';
        END IF;

    END
$$;

/*Переменные, константы и типы данных.
  Переменная - это именованная область памяти, которая может содержать данные определенного типа.
  Все используемые переменные должны быть объявлены.
  Если при объявлении указано служебное слово CONSTANT, то этот идентификатор является константой,
  ему нужно при объявлении присвоить значение, которое нельзя будет менять!!!
  При объявлении ей можно задать значение - это называется инициализацией.
*/

/*3.1. Использование переменных числового типа*/

DO
$$
    DECLARE
        a         real;
        b         real;
        c         real;
        p         real;
        s         real;
    BEGIN

            a:= 3;
            b:= 4;
            c := SQRT(a*a + b*b);
            p := a+b+c;
            s := a*b/2;
            RAISE NOTICE 'Результат: ';
            RAISE NOTICE 'Параметры прямоугольного треугольника ';
            RAISE NOTICE 'Катет a= %', a;
            RAISE NOTICE 'Катет b= %', b;
            RAISE NOTICE 'Гипотенуза c= %',c;
            RAISE NOTICE 'Периметр p= %',c;
            RAISE NOTICE 'Площадь s= %',s;


    END
$$;

----Если не объявить переменные значения будут равны NULL
DO
$$
    DECLARE
        a         real;
        b         real;
        c         real;
        p         real;
        s         real;
    BEGIN

        c := SQRT(a*a + b*b);
        p := a+b+c;
        s := a*b/2;
        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'Параметры прямоугольного треугольника ';
        RAISE NOTICE 'Катет a= %', a;
        RAISE NOTICE 'Катет b= %', b;
        RAISE NOTICE 'Гипотенуза c= %',c;
        RAISE NOTICE 'Периметр p= %',c;
        RAISE NOTICE 'Площадь s= %',s;


    END
$$;

/*3.2. Использование переменных символьного типа*/

DO
$$
    DECLARE
        v_f_name varchar(10);
        v_l_name varchar(10);
        v_name varchar(20);
    BEGIN

        RAISE NOTICE 'Результат: ';
        v_f_name :='Ivan';
        v_l_name :='Petrov';
        v_name :=  v_f_name ||' '|| v_l_name;
        RAISE NOTICE 'Меня зовут: %', v_name;

    END
$$;


DO
$$
    DECLARE
        v_f_name varchar(10);
        v_l_name varchar(10);
        v_m_name varchar(20) := 'Ivan Petrov';
        v_w_name varchar(20) := 'Olga Titova';

    BEGIN

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'Имена молодоженов ';
        RAISE NOTICE 'Он: %',  v_m_name;
        RAISE NOTICE 'Она: %', v_w_name;
        v_f_name := substr(v_w_name, 1, (strpos(v_w_name,' ')-1));
        -- Функция strpos(v_w_name, ' '):
        -- Ищет позицию первого пробела в строке 'Olga Titova'
        -- Возвращает число: 5 (пробел между "Olga" и "Titova")
        -- Выражение (strpos(v_w_name,' ')-1):
        -- 5 - 1 = 4 (позиция последнего символа перед пробелом)
        -- Функция substr(v_w_name, 1, ...):
        --Извлекает подстроку из v_w_name
        -- Начиная с позиции 1 (первый символ)
        -- Длиной 4 символа (результат из шага strpos)
        -- Результат: 'Olga'
        v_l_name := substr(v_m_name, (strpos(v_m_name, ' ')+1));
        v_w_name :=v_f_name||' '||v_l_name||'a';
          RAISE NOTICE 'Имена супругов: ';
        RAISE NOTICE 'Муж: %', v_m_name;
        RAISE NOTICE 'Жена: %', v_w_name;
    END
$$;


/*3.3 Использование переменных типа DATE
  Объявление и обработка переменных типа DATE
  Используя функцию to_char, выделяются и выводятся значения различных
  компонент текущей даты, а с помощью функций EXTRACT и AGE определяется текущий возраст
*/

DO
$$
    DECLARE
        v_m_name          varchar(20) := 'Ivan Kresov';
        v_m_date_of_birth date        := '10.12.1984';
        v_diff            integer;
        v_date            date;
        v_day             text;
        v_time            text;
    BEGIN
        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'Меня зовут: %', v_m_name;
        RAISE NOTICE 'Я родился: %', v_m_date_of_birth;
        v_date := TO_CHAR(CURRENT_DATE, 'DD-MM-YYYY');
        v_day := TO_CHAR(CURRENT_DATE, 'DAY');
        v_time := TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS');
        v_diff := EXTRACT(YEAR FROM AGE(v_m_date_of_birth)); ---текущая дата
        RAISE NOTICE 'Сегодня: %', v_date;
        RAISE NOTICE 'День недели %', v_day;
        RAISE NOTICE 'Время: %', v_time;
        RAISE NOTICE 'Мне: % ', (v_diff||'год');
    END
$$;

/*!!!
  Неявное объявление типа переменной.
  Можно объявить переменную, тип которой совпадает либо с типом ранее объявленной переменной,
  либо с типом столбца таблицы:
Синтаксис:
  {имя переменной} {базовая переменная}%Type
  {имя переменной} {таблица.столбец}%Type

DO $$
DECLARE
base_salary NUMERIC(10,2) := 50000.00;  -- Базовая переменная с явным типом
bonus       base_salary%TYPE;            -- Неявное объявление: тип как у base_salary (NUMERIC(10,2))
tax         base_salary%TYPE;              -- Ещё одна переменная того же типа

DO $$
DECLARE
 -- Переменные наследуют типы из структуры таблицы employees
v_emp_id    employees.employee_id%TYPE;   -- INTEGER (из-за SERIAL)
v_fname     employees.first_name%TYPE;    -- VARCHAR(50)
v_lname     employees.last_name%TYPE;     -- VARCHAR(50)
v_salary    employees.salary%TYPE;        -- NUMERIC(10,2)
v_hired     employees.hire_date%TYPE;     -- DATE
*/

/*
Переключается на схему hr_poc.
Берет сотрудника с ID = 106.
Запоминает его текущую зарплату в переменную v_old_sal.
Увеличивает этому сотруднику зарплату на 10%.
Запоминает новую зарплату в переменную v_new_sal.
Выводит в консоль (NOTICE) ID, старую и новую зарплату.
*/
set search_path = "hr_poc";
DO
$$
    DECLARE
        v_emp_id  employees.employee_id%type := 106;
        v_old_sal employees.salary%type;
        v_new_sal v_old_sal%type;
    BEGIN
        SELECT salary
        INTO v_old_sal
        FROM employees
        WHERE employee_id = v_emp_id;

        ---
        UPDATE employees
        SET salary = employees.salary * 1.1
        WHERE employees.employee_id = v_emp_id;
        ---

        SELECT salary
        INTO v_new_sal
        FROM employees
        WHERE employee_id = v_emp_id;

        ---
        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'employee_id= %', v_emp_id;
        RAISE NOTICE 'Старая зарплата =: %', v_old_sal;
        RAISE NOTICE 'Новая зарплата =: %' , v_new_sal;
    END
$$;

/*!!!
  Можно создать переменную, содержащую несколько полей, структура которой совпадает со структурой
  определенной таблицы
  Синтаксис:
  {имя переменной} {имя таблицы}%ROWTYPE
  обращение к определенному полю такой переменной имеет следующий вид:
  {имя переменной}.{имя поля}

  Здесь объявляем переменные v_1 и v_2 которые совпадают со структурой таблицы Cusromers.
  Полям c_name и credit_limit присваиваем значения. Вычисляется суммарный кредитный лимит и полученные
  результат выводится.
  Это очень востребованный способ неявного объявления переменных.
*/

do $$
DECLARE
    v_1 customers%rowtype;
    v_2 customers%rowtype;
    v_sum_limit numeric(10,2);
begin
    v_1.c_name :='Ivan Petrov';
    v_1.credit_limit := 200000;
    v_2.c_name := 'Sergey Ivanov';
    v_2.credit_limit := 300000;
    v_sum_limit := v_1.credit_limit + v_2.credit_limit;
    RAISE NOTICE 'Результат: ';
    RAISE NOTICE 'Имя клиента 1: % % %', v_1.c_name,
                 'Кредитный лимит: ', v_1.credit_limit;
    RAISE NOTICE 'Имя клиента 2: % % %', v_2.c_name,
                 'Кредитный лимит: ', v_2.credit_limit;
    RAISE NOTICE 'Суммарный кредитный лимит: %', v_sum_limit;
END $$;

/*!!!
  Область видимости действия переменных.
  Это часть программы, в которой можно получить доступ к переменной.
  Эта область начинается с момента объявления переменной и заканчивается
  в конце блока, в котором она была объявлена.

  1. Если блок содержит вложенные блоки, то переменные, объявленные во внешнем блоке,
  можно использовать во вложенных блоках.
  2. Если во внешнем и вложенном блоке объявлены переменные, имеющие одинаковое имя,
  то это разные переменные!!!
  3. Значение переменной, объявленной во внешнем блоке, не передается во внутренний блок,
  а изменение значения переменной во внутреннем блоке не изменяет значение,
  которое она имела во внешнем блоке.
*/

DO
$$

    DECLARE
        v_product_name  varchar(20)   := 'HP C2J95AT';
        v_product_price numeric(7, 2) := 2000;

    BEGIN
        DECLARE
            v_product_name varchar(20)   := 'AMD 100-5056062';
            v_product_price numeric(7, 2) := 1000;
        BEGIN
            RAISE NOTICE 'Имя товара: %', v_product_name;
            RAISE NOTICE 'Цена товара %', v_product_price;
        END;
        RAISE NOTICE 'Имя товара: %', v_product_name;
        RAISE NOTICE 'Цена товара %', v_product_price;
    END
$$;

/* Результат:
Имя товара: AMD 100-5056062
Цена товара 1000.00
Имя товара: HP C2J95AT
Цена товара 2000.00
[2026-02-11 21:25:46] completed in 8 ms
*/


/*Во внутреннем блоке можно использовать одноименные переменные из внешнего блока,
  для этого необходимо установить метки блоков, которые имеют следующий синтаксис:
  {метка блока}.{имя переменной}
*/

DO
$$
    <<a>>
        DECLARE
        v_name          varchar(30) := 'Анатолий Иванов';
        v_date_of_birth date        := TO_DATE('06.JAN.1968', 'DD.MON.YYYY');
    BEGIN
        <<b>>
            DECLARE
            v_name          varchar(30) := 'Надежда Иванова';
            v_date_of_birth date        := TO_DATE('06.AUG.1997', 'DD.MON.YYYY');
            v_age_father    integer;
            v_age_children  integer;
            v_age_ftch      integer;
        BEGIN
            v_age_father := EXTRACT(YEAR FROM AGE(a.v_date_of_birth));
            v_age_children := EXTRACT(YEAR FROM AGE(v_date_of_birth));
            v_age_ftch := v_age_father - v_age_children;

            ----
            RAISE NOTICE 'Результат: ';
            RAISE NOTICE 'Сегодня: %', CURRENT_DATE;
            RAISE NOTICE 'Имя моего отца: %', a.v_name;
            RAISE NOTICE 'Он родился: %', a.v_date_of_birth;
            RAISE NOTICE 'Сейчас моему отцу: %', b.v_age_father;
            RAISE NOTICE 'Меня зовут: %', b.v_name;
            RAISE NOTICE 'Я родилась: %', b.v_date_of_birth;
            RAISE NOTICE 'Когда я родилась, отцу было %', b.v_age_ftch;

        END;

    END
$$;


/*Операторы SQL PL/SQL стро 269.
Операторы манипулирования данными - select, insert, update, delete, merge
Операторы управления транзакциями - commit, rollback, savepoint

Если нужно выполнить несколько операторов манипулирования данными, то каждый оператор
является отдельным запросом к базе данных и отправляется на сервер отдельно от других операторов.
Результаты выполнения каждого оператора отправляются обратно клиенту.
Выполнение нескольких операторов манипулирования данными приводит к множественным передачам в обоих направлениях,
значительно увеличивая сетевой трафик.

Если операторы объединить в блок, то они отправляются на сервер как единое целое. Сервер выполняет эти операторы
и отправляет их результаты обратно клиенту - как единое целое.
Этот процесс более эффективен и занимает существенно меньшее время, чем выполнение каждого оператора независимо
от других.

Оператор select можно использовать для присвоения значений переменным
Синтаксис:

Select {список столбцов или выражений}
into [strict] {список переменных}
  from {список источников данных}
  where {условие выражения}

Запрос должен возвращать одну строку.
Список столбцов и список переменных должны содержать
 одинаковое количество элементов с совместимыми типами данных!!!

Если слово strict будет отсутствовать, то в случае если запрос не вернет строк, переменным
  будет присвоено значение null, а если запрос вернет несколько строк, то переменным будет
  присвоено значение первой строки.
Ошибки no_data_found и too_many_rows в этом случае не возникнет.
*/


/*
Извлечение значения одного столбца
*/

SET search_path = "hr_poc";

DO
$$
    DECLARE
        v_emp_id     employees.employee_id%type := 120;
        v_emp_salary employees.salary%type;
    BEGIN
        SELECT salary
        INTO v_emp_salary
        FROM employees
        WHERE employee_id = v_emp_id;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'employee_id = %', v_emp_id;
        RAISE NOTICE 'salary = %', v_emp_salary;

    END
$$;

/*Значение переменной может быть результатом обработки данных, например значением,
  возвращаемым агрегатной функцией*/

DO
$$
    DECLARE
        v_dep_id     employees.department_id%type := 80;
        v_max_salary employees.salary%type;
    BEGIN
        SELECT max(salary)
        INTO v_max_salary
        FROM employees
        WHERE department_id = v_dep_id;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'department_id = %', v_dep_id;
        RAISE NOTICE 'MAX(salary) = %', v_max_salary;

    END
$$;

/*Можно извлечь и присвоить переменные значения нескольких столбцов*/

DO
$$
    DECLARE
        v_emp_id     employees.employee_id%type := 120;
        v_first_n    employees.first_name%type;
        v_last_n     employees.last_name%type;
        v_job        employees.job_id%type;
        v_emp_salary employees.salary%type;
    BEGIN
        select employee_id, first_name, last_name, job_id, salary
        into v_emp_id, v_first_n, v_last_n, v_job, v_emp_salary
        from employees
        where employee_id = v_emp_id;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE '%', format('%-12s %-12s %-12s %-10s %-10s',
                                 'employee_id', 'first_name', 'last_name', 'job_id', 'salary');
        RAISE NOTICE '%', format('%-12s %-12s %-12s %-10s %-10s',
                                 v_emp_id, v_first_n, v_last_n, v_job, v_emp_salary);
    END
$$;

/*В подобных случаях удобно использовать переменную, использующую
  тип ROWTYPE */


DO
$$
    DECLARE
        v_emp_id     employees.employee_id%type := 120;
        v_emp employees%ROWTYPE;
    BEGIN
        select *
        into v_emp
        from employees
        where employee_id = v_emp_id;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE '%', format('%-12s %-12s %-12s %-10s %-10s',
                                 'employee_id', 'first_name', 'last_name', 'job_id', 'salary');
        RAISE NOTICE '%', format('%-12s %-12s %-12s %-10s %-10s',
                                 v_emp_id, v_emp.first_name, v_emp.last_name, v_emp.job_id, v_emp.salary);
    END
$$;

/*Использование оператора insert

Правила использования оператора insert в блоках PL/PgSQL соответствуют правилам использования DML
операторов Postgresql, но в условных выражениях и списке значений можно использовать переменные,
которые были определены и инициализированы в блоке
Используя последовательность в этих примерах позволяет обеспечить уникальность значений ключевого столбца product_id
*/

-- 1. Создание структуры с ограничениями
drop table  products_1;
CREATE TABLE IF NOT EXISTS products_1
(
    LIKE products
        INCLUDING DEFAULTS
        INCLUDING INDEXES
);

-- 2. Копирование данных
INSERT INTO products_1
SELECT *
FROM products;

-- 3. Проверка
SELECT COUNT(*)
FROM products_1;

/*Для присвоения значений столбцу product_id создадим последовательность*/
CREATE SEQUENCE prod_1_id_seq
    START WITH 1
    INCREMENT BY 1;
/*
Вставка новой строки в таблицу Products_1
*/

DO $$                 -- Начало анонимного блока PL/pgSQL (DO выполняет код без создания функции)
DECLARE               -- Секция объявления переменных
v_next_id INT;        -- Объявляем переменную v_next_id типа INTEGER для хранения следующего ID
BEGIN                 -- Начало исполняемой части блока
                      -- Синхронизируем последовательность (на всякий случай)
    PERFORM setval('prod_1_id_seq',  -- PERFORM выполняет запрос без возврата результата; setval() устанавливает значение последовательности 'prod_1_id_seq'
                   COALESCE(         -- COALESCE возвращает первое не-NULL значение из списка аргументов
                           (SELECT MAX(product_id)  -- Подзапрос: находим максимальное значение product_id в таблице products_1
                            FROM products_1),       -- из таблицы products_1
                           0                        -- если таблица пуста (MAX вернёт NULL), используем 0 как значение по умолчанию
                   ),
                   true                 -- третий параметр setval(): true = следующий nextval() вернёт именно это значение + 1 (is_called = true)
            );

    -- Теперь вставляем
    v_next_id := nextval('prod_1_id_seq');  -- Присваиваем переменной v_next_id следующее значение из последовательности 'prod_1_id_seq' (гарантированно уникальное)

    INSERT INTO products_1(product_id, product_name, rating_p)  -- Команда вставки данных в таблицу products_1, указываем три колонки
    VALUES (v_next_id,           -- Первое значение: ID из переменной v_next_id (получен из последовательности)
            'ASUS Z12DE A5',     -- Второе значение: строка с названием продукта
            2                    -- Третье значение: числовой рейтинг продукта
           );

    RAISE NOTICE 'Вставлено с ID: %', v_next_id;  -- Вывод информационного сообщения в консоль; % заменяется на значение v_next_id

END $$;                             -- Конец блока PL/pgSQL; $$ закрывает блок

/*Вставка в таблицу Products_1 результатов выполнения оператора SELECT*/

do $$
    BEGIN
        INSERT INTO products_1(product_id, product_name, rating_p, price)
        SELECT nextval('prod_1_id_seq'), products.product_name, products.rating_p, products.price
        from products
        where rating_p = 3;
    END
    $$;

/*
Вставка даннных о новом заказе и его содержимом.
В этом примере показано как можно реализовать автоматическую нумерацию товаров
в заказе.
Для этого используется переменная v_oi_id.
Этой переменной сначала присваивается максимальное значение столбца item_id для
данного заказа, потом ее значение увеличивается на 1, и это значение
используется в операторе insert.
*/

CREATE SEQUENCE Orders_Id_Seq
    START WITH 1
    INCREMENT BY 1;

DO $$
    DECLARE
        v_oi_id integer;
        v_new_order_id integer;  -- ← добавили переменную для нового ID
    BEGIN
        -- СИНХРОНИЗИРУЕМ последовательность перед вставкой
        PERFORM setval('orders_id_seq',
                       COALESCE((SELECT MAX(order_id) FROM orders), 0),
                       true);

        -- Теперь получаем гарантированно уникальный ID
        v_new_order_id := nextval('orders_id_seq');

        INSERT INTO orders
        (order_id, customer_id, status, salesman_id, order_date)
        VALUES(v_new_order_id, 12, 'Pending', 148, current_date);

        -- Используем переменную вместо currval
        SELECT COALESCE(MAX(item_id), 0) INTO v_oi_id
        FROM order_items
        WHERE order_id = v_new_order_id;  -- ← используем переменную

        v_oi_id := v_oi_id + 1;

        INSERT INTO order_items
        (order_id, item_id, product_id, quantity, unit_price)
        VALUES (v_new_order_id, v_oi_id, 79, 300, 30060);  -- ← используем переменную

        RAISE NOTICE 'Создан заказ % с позицией %', v_new_order_id, v_oi_id;
    END
$$;


SELECT *
from orders;

SELECT *
from order_items;


/*
Использование оператора UPDATE.
Правила использования оператора update в блоках PL/PgSQL соответствуют правилам использования DML
операторов Postgresql, но в условных выражениях и операторах присваивания можно использовать переменные,
которые были определены и инициализированы в блоке
*/

/*Изменение значения столбца rating_p в таблице Products_1*/

ALTER TABLE products_1
DROP CONSTRAINT IF EXISTS product_r;

DO
$$

    DECLARE
        v_prod_id products_1.product_id%type :=6;
        v_add_rating products_1.rating_p%type :=2;
        v_prod products_1%ROWTYPE;

    BEGIN
        /*
         Выполняется:
        rating_p = rating_p + v_add_rating
         = 3 + 2 = 5
         */
        UPDATE products_1
        set rating_p = rating_p + v_add_rating
        where product_id = v_prod_id;

        select *
        INTO v_prod
        from products_1
        where product_id = v_prod_id;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'Product_id = %', v_prod.product_id;
        RAISE NOTICE 'Rating_p = %', v_prod.rating_p;

    END
$$;

/*Изменение регистра столбца product_name*/

DO $$
BEGIN
UPDATE products_1
    set product_name = initcap(product_name);
END
$$;

/*
Рассмотрим следующую задачу:
Необходимо изменить зарплату сотрудников 115 и 116, работающих в отделе 30.
Так, чтобы после этого изменения суммарная зарплата сотрудников отдела 30 была
равна 30 000, а разница между зарплатами сотрудников 115 и 116 была равна 290.

Особенность этой задачи является необходимость решения системы двух линейных уравнений.
Введем обозначения:
s1 - зарплата сотрудника 115 до повышения
s2 - зарплата сотрудника 116 до повышения
sum1 - суммарная зарплата сотрудников отдела 30 до повышения
sum2 - суммарная зарплата сотрудников отдела 30 после повышения
ds - разница между зарплатами сотрудников 115 и 116 после повышения
x1 - размер повышения зарплаты сотрудника 115
x2 - размер повышения зарплаты сотрудника 116


В отделе стало 30000
Значит: (s1 + x1) + (s2 + x2) = 30000
Условие 2 (про разницу):
115-й на 290 больше 116-го
Значит: (s1 + x1) - (s2 + x2) = 290
x1 + x2 = 30000 - sum1
Шаг 2: Какая разница в добавках?
Нам нужно, чтобы 115-й стал на 290 больше 116-го.
Текущая разница: s1 - s2 (сейчас)
Нужная разница: 290 (после)
Значит разница должна увеличиться на 290 - (s1 - s2)

Значения sum2 и ds заданы, значения s1,s2, sum1 можно определить с помощью запросов.
Составим систему из двух линейных уравнений:
sum2 - sum1 = x1 + x2
(s1 + x1) - (s2 + x2) = ds
Шаг 3: Это и есть формула:
x1 - x2 = 290 - s1 + s2

-- Разница в зарплатах сейчас
raznica_seychas = s1 - s2;
-- На сколько нужно изменить разницу
nuzhno_dobavit_k_raznice = 290 - raznica_seychas;
-- Тогда:
x1 = ( (30000 - sum1) + nuzhno_dobavit_k_raznice ) / 2
x2 = (30000 - sum1) - x1

Решение системы уравнений имеет следующий вид:

x2=(sum2 - sum1 + s1 - s2)/2
x1=sum2 - sum1 - x2
*/



DO $$
    DECLARE
        s1 employees.salary%TYPE;
        s2 employees.salary%TYPE;
        sum1 employees.salary%TYPE;
        sum2 CONSTANT employees.salary%TYPE := 30000;
        ds CONSTANT employees.salary%TYPE := 290;
        x1 employees.salary%TYPE;
        x2 employees.salary%TYPE;
    BEGIN
        -- Получаем текущие зарплаты
        SELECT salary INTO s1 FROM employees WHERE employee_id = 115;
        SELECT salary INTO s2 FROM employees WHERE employee_id = 116;

        -- Получаем текущую сумму отдела 30
        SELECT SUM(salary) INTO sum1 FROM employees WHERE department_id = 30;

        -- Решаем систему уравнений
        x1 := (sum2 - sum1 + ds + s2 - s1) / 2;
        x2 := (sum2 - sum1 - x1);

        -- Проверка
        RAISE NOTICE 's1=%, s2=%, sum1=%, sum2=%, ds=%', s1, s2, sum1, sum2, ds;
        RAISE NOTICE 'x1=%, x2=%', x1, x2;
        RAISE NOTICE 'Проверка суммы: % + % = % (должно быть %)',
            x1, x2, x1 + x2, sum2 - sum1;
        RAISE NOTICE 'Проверка разницы: (% + %) - (% + %) = % (должно быть %)',
            s1, x1, s2, x2, (s1 + x1) - (s2 + x2), ds;

        -- Выполняем обновление
        UPDATE employees SET salary = salary + x1 WHERE employee_id = 115;
        UPDATE employees SET salary = salary + x2 WHERE employee_id = 116;

        RAISE NOTICE '✅ Обновление выполнено';
    END
$$;



/*
Текущие зарплаты:
115 = 3695.00,
116 = 4405.00.
Текущая сумма отдела 30 = 27000.00
Изменения: +2000.00 для 115, +1000.00 для 116
Новые зарплаты: 115 = 5695.00, 116 = 5405.00
Новая сумма отдела = 30000.00
Новая разница = 290.00
✅ Обновление выполнено
[2026-02-28 18:37:33] completed in 12 ms
*/
DO $$
    DECLARE
        s1 employees.salary%TYPE;
        s2 employees.salary%TYPE;
        sum1 employees.salary%TYPE;
        x1 employees.salary%TYPE;
        x2 employees.salary%TYPE;
    BEGIN
        -- Получаем текущие значения
        SELECT salary INTO s1 FROM employees WHERE employee_id = 115;
        SELECT salary INTO s2 FROM employees WHERE employee_id = 116;
        SELECT SUM(salary) INTO sum1 FROM employees WHERE department_id = 30;

        -- Вычисляем изменения
        x1 := (30000 - sum1 + 290 - s1 + s2) / 2;
        x2 := (30000 - sum1 - x1);

        -- Выводим информацию
        RAISE NOTICE 'Текущие зарплаты: 115 = %, 116 = %', s1, s2;
        RAISE NOTICE 'Текущая сумма отдела 30 = %', sum1;
        RAISE NOTICE 'Изменения: +% для 115, +% для 116', x1, x2;
        RAISE NOTICE 'Новые зарплаты: 115 = %, 116 = %', s1 + x1, s2 + x2;
        RAISE NOTICE 'Новая сумма отдела = %', sum1 + x1 + x2;
        RAISE NOTICE 'Новая разница = %', (s1 + x1) - (s2 + x2);

        RAISE NOTICE '✅ Обновление выполнено';
    END
$$;


/*
Использование оператора DELETE
Правила использования этого оператора в блоках pgSQL соответствует правилам использования
DML операторов PostgreSQL.
*/

/*Удаление из таблицы Products_1 данных о товарах, имеющих рейтинг 2*/

DO
$$
    DECLARE
        v_prod_rating products_1.rating_p%type := 2;
    BEGIN
        DELETE
        FROM products_1
        WHERE rating_p = v_prod_rating;
    END
$$;

select products_1.rating_p
from products_1
where rating_p = 2;

/*
Удаление из таблицы Products_1 данных о товарах имеющих рейтинг совпадающий с рейтингом
 товара 6
*/

DO
$$
    DECLARE

        v_prod_id products_1.product_id%type := 6;
    BEGIN
        DELETE
        FROM products_1
        WHERE rating_p = (SELECT rating_p FROM products_1 WHERE product_id = v_prod_id);
    END
$$;

/*Использование оператора merge.
  Merge осуществляет слияние двух таблиц
  У строк таблицы Product_1 для которых выполняется условие слияния, обновляется
  значение цены товара. Слияние осуществляется по столбцу product_name
  Слияние таблицы Products_1 с результатом выполнения запроса
*/

DO $$
    DECLARE
        v_rating products_1.rating_p%type := 2;  -- Фильтр: только товары с рейтингом 3
    BEGIN
        MERGE INTO products_1 AS target           -- Целевая таблица (куда вставляем/обновляем)
        USING (
            -- Источник данных (откуда берём информацию)
            SELECT
                product_id,
                product_name,
                rating_p,
                price
            FROM products
            WHERE rating_p = v_rating              -- Только товары с нужным рейтингом
        ) AS source
        ON (
            -- Условие сопоставления: сравниваем названия (без учёта регистра)
            INITCAP(target.product_name) = INITCAP(source.product_name)
            )

            -- Если товар с таким названием УЖЕ ЕСТЬ в target (products_1)
        WHEN MATCHED THEN
            UPDATE SET
                price = source.price               -- Обновляем цену

        -- Если товара с таким названием НЕТ в target (products_1)
        WHEN NOT MATCHED THEN
            INSERT (product_id, product_name, rating_p, price)
            VALUES (
                       source.product_id,                  -- Берём ID из источника
                       INITCAP(source.product_name),       -- Название с заглавной буквы
                       source.rating_p,                    -- Рейтинг из источника
                       source.price                         -- Цена из источника
                   );

        -- Сообщаем о завершении
        RAISE NOTICE '✅ Синхронизация товаров с рейтингом % завершена', v_rating;
    END
$$;




SELECT *
from products_1
where rating_p = 2
order by product_id desc;

Select *
from products
where rating_p = 2
order by product_id desc;


/*Проверка расхождений*/
SELECT
    COALESCE(p.product_id, p1.product_id) as product_id,

    -- Статус записи
    CASE
        WHEN p.product_id IS NULL THEN '❌ Только в products_1'
        WHEN p1.product_id IS NULL THEN '❌ Только в products'
        ELSE '✅ В обеих'
        END as record_status,


    -- По колонкам: Совпадает / Разные / Нет в таблице
    CASE WHEN p.product_id IS NULL THEN 'нет в products'
         WHEN p1.product_id IS NULL THEN 'нет в products_1'
         WHEN p.product_name = p1.product_name THEN '✅'
         ELSE '❌' END as name_match,

    CASE WHEN p.product_id IS NULL THEN 'нет в products'
         WHEN p1.product_id IS NULL THEN 'нет в products_1'
         WHEN p.rating_p = p1.rating_p THEN '✅'
         ELSE '❌' END as rating_match,

    CASE WHEN p.product_id IS NULL THEN 'нет в products'
         WHEN p1.product_id IS NULL THEN 'нет в products_1'
         WHEN p.price = p1.price THEN '✅'
         ELSE '❌' END as price_match,

    -- Значения для проверки
    p.product_name as p_name,
    p1.product_name as p1_name,
    p.rating_p as p_rating,
    p1.rating_p as p1_rating,
    p.price as p_price,
    p1.price as p1_price

FROM products p
         FULL OUTER JOIN products_1 p1
                         ON p.product_id = p1.product_id
                             AND p.rating_p = 2
                             AND p1.rating_p = 2
WHERE p.rating_p = 2
  OR p1.rating_p = 2
ORDER BY product_id;

/*Условные операторы
  Как правило процесс выполнения команд программы не является последовательным,
  а содержит ветвления, которые должны выполняться в том случае, если заданные условия
  принимают определенные значения

  Условные операторы позволяют управлять процессом выполнения программы
  и содержат условия выполнения ветвей программы.

  Для управления ходом выполнения команд в pg/sql используется оператор IF который имеет
  следующий синтаксис

  IF {условное выражение A} THEN {Блок операторов};
        [ELSEIF {условное выражение B1} THEN {Блок операторов B1};]
        ......
        [ELSEIF {условное выражение BN} THEN {Блок операторов BN};]
        [ELSE {Блок операторов C};]
  END IF;

  Условное выражение может принимать TRUE, FALSE, NULL
  Блоки могут содержать один или несколько операторов pg/SQL или SQL

  Условный оператор IF выполняет первый блок операторов для которого
  заданное условное выражение имеет значение TRUE, после этого управление
  передается следующему оператору IF.
  Может содержать одну или несколько секций ELSEIF
  Условный оператор IF может содержать секцию ELSE.
  В простейшем случае оператор IF выглядит следующим образом

  IF {условное выражение} THEN {Блок операторов};
  END IF;

  1.Если условное выражение будет иметь значение TRUE, то будут выполнены операторы, входящие в блок
  операторов, после чего управление будет передано оператору,
  расположенному после оператора END IF.
  2.Если условное выражение будет иметь значение FALSE или NULL, то управление будет передано оператору,
  расположенному после оператора END IF.
*/

/*
Пример простого IF
*/

DO
$$
    DECLARE
        v_sum_sal numeric(10, 2) := 900000;
        v_bonus   numeric(10, 2);

    BEGIN
        IF v_sum_sal > 1000000
        THEN
            v_bonus := 5000;
        ELSE v_bonus := 100;
        END IF;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'v_sum_sal = %', v_sum_sal;
        RAISE NOTICE 'v_bonus = %', v_bonus;
    END
$$;


DO
$$
    DECLARE
        v_sum_sal numeric(10, 2);
        v_bonus   numeric(10, 2);

    BEGIN
        IF v_sum_sal < 1000000
        THEN
            v_bonus := 0;
        ELSE v_bonus := 50000;
        END IF;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'v_sum_sal = %', v_sum_sal;
        RAISE NOTICE 'v_bonus = %', v_bonus;
    END
$$;


DO
$$
    DECLARE
        v_sum_sal numeric(10, 2);
        v_bonus   numeric(10, 2);

    BEGIN
        IF coalesce(v_sum_sal,0) < 1000000
        THEN
            v_bonus := 0;
        ELSE v_bonus := 50000;
        END IF;

        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'v_sum_sal = %', v_sum_sal;
        RAISE NOTICE 'v_bonus = %', v_bonus;
    END
$$;

/*Команда CASE.
Существует две разновидности CASE:
  1.Простая команда CASE с селектором, выполняет последовательность команд, для которой
  значение селектора совпадает с заданным значением
  2.Поисковая команда CASE с условием, выполняет последовательность команд, для которой
  значений заданного условного выражения
  имеет значение TRUE
*/

