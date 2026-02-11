/*Структура программы PL/pgSQL
  является процедурным языком
  позволяет использовать средства процедурных языков
  программирования:
  переменные,
  условные операторы,
  операторы циклов

  совместно с операторами SQL

  Используя эти средства можно создавать функции, хранимые процедуры, триггеры!!!

  - Процедуры необходимы в тех случаях, когда нужно внести изменения в данные.
  - Функции необходимы когда нужно выполнить задачу по обработке данных и вернуть в
  вызывающую среду результат этой обработки, результат может представлять как скалярное значение,
  так и таблицу.
  - Триггеры необходимы для обеспечения выполнения бизнес-правил, реализации правил безопасности, контроля
  изменений, которые пользователи вносят в таблицы базы данных.

  Основные конструкции языка
*/


/*1. Структура блока PL/pgSQL
  все программы PL/pgSQL состоят из блоков, блок определяет операторы, предназначенные для
  решения определенной задачи
Одна программа может содержать несколько блоков, которые могут выполняться один за другим
  или быть вложенными
  Блоки могу быть анонимными или именованными
  Анонимные блоки не имеют имени, они не могут быть сохранены в базе данных и на низ нельзя ссылаться.
  Именованные блоки используют при создании подпрограмм, эти блоки представляют собой процедуры которые
  хранятся в базе данных и которые можно вызвать по имени.


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


/*2. Анонимные блоки
  Блоки, которые являются приложением, взаимодействующим с базой данных
  Они могут создаваться в клиентских программах для вызова хранимых процедур, функций,
  содержащихся в БД, для автоматизации административных задач в БД
  Они:
  -Не имеют имени
  -Не хранятся в базе данных
  -Компилируются при каждом выполнении
  -Передаются PL/pgSQL Engine для выполнения в реальном времени
  -Не могут быть вызваны
  */

set search_path = "hr_poc";

DO
$$
    DECLARE
        a         real := -1;
        b         real := -1;
        c         real := -6;
        d         real;
        x1        real;
        x2        real;
        text_var1 text;
        text_var2 text;
    BEGIN

        d := SQRT(b * b - 4 * a * c);
        x1 := (-b - d) / (2 * a);
        x2 := (-b + d) / (2 * a);
        RAISE NOTICE 'Результат: ';
        RAISE NOTICE 'Корни уравнения: a*x*x + b*x + c = 0';
        RAISE NOTICE ' x1 = %', x1;
        RAISE NOTICE ' x2 = %', x2;

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS text_var1 = MESSAGE_TEXT,
                text_var2 = RETURNED_SQLSTATE;
            RAISE NOTICE 'Причина ошибки = %', text_var1;
            RAISE NOTICE 'Код ошибки = %', text_var2;

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

/*Переменные, константы и типы данных
  Переменная это именованная область памяти, которая может содержать данные
  определенного типа.
  Все используемые переменные должны быть объявлены
  Если при объявлении указано служебное слово CONSTANT, то этот идентификатор является константой,
  ему нужно при объявлении присвоить значение, которое нельзя будет менять.
  При объявлении ей можно задать значение - это называется иницииализацией.
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
  компонент текущей даты, а с помощью функций extract и AGE определяется текущий возраст
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

/*Неявное объявление типа переменной
  можно объявить переменную, тип которой совпадает либо с типом ранее объявленной переменной,
  либо с типом столбца таблицы
Синтаксис:
  {имя переменной} {базовая переменная}%Type
  {имя переменной} {таблица.столбец}%Type
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

/*Можно создать переменную, содержащую несколько полей, структура которой совпадает со структурой
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

/*Область видимости действия переменных
  Это часть программы, в которой можно получить доступ к переменной.
  Эта область начинается с момента объявления переменной и заканчивается
  в конце блока, в котором она была объявлена.
*/