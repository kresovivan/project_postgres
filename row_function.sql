CREATE SCHEMA IF NOT EXISTS row_function;


-- Создать таблицу
CREATE TABLE numbers (
                         num INTEGER
);

-- Вставить значения
INSERT INTO numbers (num) VALUES
                              (51),
                              (52),
                              (53),
                              (55),
                              (56),
                              (59);

create table employees (
    id integer primary key,
    name varchar(50),
    city varchar(50),
    department varchar(50),
    salary integer
);

insert into employees
(id, name, city, department, salary)
values
(24, 'Марина', 'Москва', 'it', 104),
(21, 'Елена', 'Самара', 'it', 84),
(22, 'Ксения', 'Москва', 'it', 90),
(25, 'Иван', 'Москва', 'it', 120),
(23, 'Леонид', 'Самара', 'it', 104),
(11, 'Дарья', 'Самара', 'hr', 70),
(12, 'Борис', 'Самара', 'hr', 78),
(31, 'Вероника', 'Москва', 'sales', 96),
(33, 'Анна', 'Москва', 'sales', 100),
(32, 'Григорий', 'Самара', 'sales', 96);



create table expenses (
    year integer,
    month integer,
    income integer,
    expense integer
);

insert into expenses
(year, month, income, expense)
values
(2020, 1, 94, 82),
(2020, 2, 94, 75),
(2020, 3, 94, 104),
(2020, 4, 100, 94),
(2020, 5, 100, 99),
(2020, 6, 100, 105),
(2020, 7, 100, 95),
(2020, 8, 100, 110),
(2020, 9, 104, 104),
(2020, 10, 104, 100),
(2020, 11, 104, 98),
(2020, 12, 104, 106);


/*Ранжирование
Рейтинг сотрудников по заработной плате.
Составим рейтинг сотрудников по размеру заработной платы
dense_rank() считает ранг по указанному окну, начинает с 1
и увеличивает ранг каждый раз, когда очередное значение из окна
отличается от предыдущего.

Движок выполняет следующим образом запрос:
-выбирает из нее все записи.
-для каждой записи рассчитывает значение dense_rank() с помощью окна w.
-cортирует результат, как указано в order by.

order by в окне сортирует данные
order by после from сортирует результаты уже после того как отработало окно


зачем сортировать по еще и по id а не только по полю rank
Чтобы понимать как сортировать сотрудников с одинаковым раногом.
Без id порядок записей не определен и СУБД может расположить их в любом порядке
А с id сортировка будет однозначно в порядке id.


Как создавать несколько окон в одном запросе
*/

SET search_path TO row_function;

select
            dense_rank()       OVER (order by salary desc) as rank, ---rank
            sum(salary)        OVER (order by salary desc) as sum,  ---нарастающий итог
            sum(salary)        OVER () as sum_total,                ---общая сумма
            salary,
            lag(salary)        OVER () as lag,
            lag(salary)        OVER (PARTITION BY department order by salary DESC) as lag_order_w_part,
            lag(salary)        OVER (order by salary DESC) as lag_order_w,
            lead(salary)       OVER () as lead,
            lead(salary)        OVER (PARTITION BY department order by salary DESC) as lag_order_w_part,
            lead(salary)       OVER (order by salary DESC) as lead_order_w,

            name,
            department
from employees
order by rank, id;




/*Аналогично запрос можно переписать в Postgresql*/
select
            dense_rank() OVER w1 as rank_desc,
            dense_rank() OVER w2 as rank_asc,
            name,
            department,
            salary
from employees
window
    w1 as (order by salary desc),
    w2 as (order by salary asc)
order by salary, id;

/*Секции окна
 *
 * Составим рейтинг сотрудников по размеру заработной платы независимо
 * по каждому департаменту
 *
 * partition by указывает как следует разбить окно на секции
 * order by задает сортировку внутри секции
 */

SELECT
            dense_rank()  OVER (PARTITION BY department order by salary desc) as rank,
            department,
            name,
            salary
from employees
order by department, salary DESC, id;

/*Рейтинг по зарплатам сотрудников по городам*/
SELECT
            dense_rank()  OVER (PARTITION BY city order by salary desc) as rank,
            city,
            name,
            salary
from employees
order BY city, salary DESC, id;

/*
Основная цель NTILE — квантование или разделение данных на равные части для сравнения.
Это полезно, когда вам нужно:
Разделить сотрудников на группы по уровню зарплаты (например, топ-10%, средние, низкие).
Создать квартили (4 группы), децили (10 групп) или перцентили.
Провести анализ распределения (A/B тестирование, сегментация клиентов).
Найти "середнячков" или экстремальные значения относительно всей выборки.
 *
 *
 * */
SELECT
            ntile(3)  OVER (order by salary desc) as rank,
            department,
            name,
            salary
from employees
order BY salary DESC, id;

/*
 *
 * Часто нужно сравнивать сотрудников не со всеми в компании, а только внутри их отдела.
 * Например, разбить каждый отдел на 2 группы (лучшие и худшие внутри отдела).
 *
 * */
SELECT
    name,
    department,
    salary,
    NTILE(2) OVER (PARTITION BY department ORDER BY salary DESC) as dept_performance_group
FROM employees
ORDER BY department, salary DESC;


/*
Сценарий 1: Выделение топ-3 сотрудников для премии в каждом отделе
Допустим, бюджет позволяет выдать премию только трем лучшим сотрудникам в каждом отделе, но
отделы разные по размеру (IT — 5 чел, HR — 2 чел, Sales — 3 чел).
Если мы просто возьмем "топ-3", то в маленьком отделе HR мы возьмем всех, а
это может быть невыгодно.
Задача: Разбить каждый отдел на группы так, чтобы выделить верхнюю треть
(или максимально близкую к ней группу) лучших.
Используем NTILE(3) внутри каждого департамента.
Группа 1 будет содержать самых высокооплачиваемых (так как сортируем DESC).
*/

WITH  tt AS (
    SELECT
        name,
        department,
        salary,
        NTILE(3)     OVER (PARTITION BY department ORDER BY salary DESC)     AS performance_group,
        row_number() OVER (PARTITION BY department ORDER BY salary DESC) AS rownum
    FROM employees
    ORDER BY department, performance_group, salary DESC)

SELECT *
FROM tt
WHERE performance_group = 1
  AND rownum = 1;

/*Самые дорогие коллеги в отделе по зарплате*/

WITH DATA AS (
    SELECT
        id,
        name,
        department,
        salary,
        dense_rank() OVER (PARTITION BY department ORDER BY salary DESC) AS emp_rank
    FROM employees
)

SELECT *
FROM DATA
WHERE emp_rank = 1;



WITH DATA AS (
    SELECT
        id,
        name,
        department,
        salary,
        row_number() OVER (PARTITION BY department ORDER BY salary DESC) AS rownums
    FROM employees
)

SELECT *
FROM DATA
WHERE rownums = 1;

/*Сравнение со смещением
 * Это когда мы смотрим в чем разница между соседними значениями
 * Например сравниваем страны которые занимают 5 и 6 место в мировом
 * рейтинеге ВВП - сильно ли отличаются? А если сравнить 1 и 6 место.
 * Сюда же попдают задачи если мы сравниваем значение из набора
 *  с границами набора.
*/

WITH emp AS (
    SELECT
        id,
        name,
        department,
        salary,
        lag(salary) OVER (ORDER BY salary, id)  AS prev,
        lead(salary) OVER (ORDER BY salary, id) AS next
    FROM employees
)

SELECT *,
       round((salary - prev) * 100.0 / prev) AS diff_prev,
       round((next - salary) * 100.0 / next) AS diff_next
FROM emp;

/*Сравнение с границами
 зарплата сотрудников соотносится с минимальной и макисмальной зарплатой в его
 отделе

UNBOUNDED PRECEDING: Начать фрейм с самой первой строки в отсортированной группе (партиции)!!!
UNBOUNDED FOLLOWING: Закончить фрейм самой последней строкой в этой группе!!!
Итог: Фрейм включает ВСЕ строки текущего департамента, независимо от того,
на какой строке сейчас находится курсор при выводе результата.
По умолчанию фрейм стал бы ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
Тогда для Ксении (вторая строка в списке) фрейм включал бы только [84, 90].
конструкция ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING критически важна
здесь, чтобы заставить LAST_VALUE (и FIRST_VALUE)
работать как глобальные агрегаты (MAX/MIN) внутри группы, а не как скользящие функции.



Анализ работы фрейма для отдела IT:

Сотрудник | Зарплата | Фрейм по умолчанию (до текущей) | LAST_VALUE (ошибка!) | Ваш фрейм (весь ряд)      | LAST_VALUE (правильно)
----------|----------|---------------------------------|----------------------|---------------------------|------------------------
Елена     | 84       | [84]                            | 84                   | [84, 90, 104, 104, 120]   | 120
Ксения    | 90       | [84, 90]                        | 90                   | [84, 90, 104, 104, 120]   | 120
Марина    | 104      | [84, 90, 104]                   | 104                  | [84, 90, 104, 104, 120]   | 120
Леонид    | 104      | [84, 90, 104, 104]              | 104                  | [84, 90, 104, 104, 120]   | 120
Иван      | 120      | [84, 90, 104, 104, 120]         | 120                  | [84, 90, 104, 104, 120]   | 120

Без явного указания "AND UNBOUNDED FOLLOWING", LAST_VALUE возвращает
значение текущей строки,
так как фрейм обрывается на ней.

Что такое фрейм?
Представьте, что у вас есть бинокль или фонарик.
Партиция (PARTITION BY) — это вся комната (например, весь отдел it).
Сортировка (ORDER BY) — это то, как люди выстроились в ряд в этой комнате (по зарплате).
Фрейм (ROWS BETWEEN...) — это свет вашего фонарика.
Функция (FIRST_VALUE, LAST_VALUE, SUM) видит и обрабатывает только тех людей,
на которых светит фонарик  в данный момент.
Ваш запрос явно говорит: "Свети фонариком на ВСЕХ людей в ряду одновременно,
от первого до последнего".
*/
SELECT
    name,
    department,
    salary,
    FIRST_VALUE(salary) OVER (PARTITION BY department
        ORDER BY
            salary ROWS
            BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS low,
    LAST_VALUE(salary) OVER (PARTITION BY department
        ORDER BY
            salary ROWS
            BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS high
FROM
    employees
ORDER BY
    department,
    salary,
    id;

/*Процент от максимальной зарплаты в городе
 * Для каждого сотрудника хотим увидеть сколько процентов
 * составляет его зарплата от макисимальной в городе*/

SELECT
    salary,
    city,
    LAST_VALUE(salary) OVER (PARTITION BY city
        ORDER BY
            salary ROWS BETWEEN
            UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_sal_city,
    salary * 100 / LAST_VALUE(salary) OVER (PARTITION BY city
        ORDER BY
            salary ROWS BETWEEN
            UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS PERCENT
FROM
    employees
ORDER BY
    city,
    salary,
    id;


/*Чтобы границы фрейма совпадали с границами секции или всего окна, если секция одна -
  rows between unbounded preceding and unbounded following*/


/*Агрегация - когда мы считаем суммарные показатели или агрегаты
  Агрегат по секции
  Посмотрим какой процент от фонда оплаты труда по департаменту составляет каждая зарплата сотрудника
  в департаменте*/

select name,
       department,
       salary,
       sum(salary) over (partition by department) as fot,
       round((salary * 100.0) /  sum(salary) over (partition by department),2) as percent
    from employees
order by department, salary, id;


/*Фонд оплаты труда по городу
  Посчитать сколько процентов составляет зарплата сотрудника от общего фонда оплаты
  труда по городу*/


select name,
       city,
       salary,
       sum(salary) over (partition by city) as fot,
       round((salary * 100.0) /  sum(salary) over (partition by city),2) as percent
from employees
order by city, salary, id;

/*Средняя зарплата по департаменту
  сколько человек трудится в отделе
  какая средняя зарплата по отделу
  на сколько процентов отклоняется средняя зарплата от среднего по отделу
  Отклонение = (зарплата сотрудника - средняя зарплата) * 100 / средняя_зарплата
*/



select name,
       department,
       round(salary,2) as salary,
       count(*)    over (partition by department) as emp_cnt,
       round(avg(salary) over (partition by department),2) as sal_avg,
       round(
               ((salary - AVG(salary) OVER (PARTITION BY department)) * 100.00 /
                          avg(salary) OVER (PARTITION BY department)
               )
            ,2) as diff
from employees
order by department, salary, id;

/*Фильтрация и порядок выполнения
Допустим мы хотим оставить в отчете только самарских сотрудников

1.Взять нужны таблицы from
2.Отфильтровать строки where
3.Сгруппировать строки group by
4.Отфильтровать результат группировки having
5.Взять конкретные столбцы из результата select
6.Рассчитать значения оконных функций
7.Отсортировать то, что получилось order by
*/

with emp as (
    select
        name,
        city,
        salary,
        sum(salary) over (partition by department) as fund
        from employees
order by department, salary, id
)

select
    name,
    salary,
    fund
from emp
where city = 'Самара';

/*Описание окна
  Без partition и order считается вся сумма по окну*/

select
    name,
    salary,
    count(*)    over() as emp_count, ---общее количество строк по окну
    sum(salary) over() as fund,       ---общая сумма по окну
    sum(salary) over(partition by city) as fund_city, ---общая сумма по городу
    sum(salary) over(order by salary) as accumulate_fund,  ---Накопительная сумма по Salary по всему окну
    sum(salary) over(partition by city order by salary) as accumulate_fund_city ------Накопительная сумма salary по City
from employees
order by city, salary, id;

/*Внутренний SUM SUM(salary) — это агрегация внутри GROUP BY.
  Она считает сумму зарплат для каждой группы (city, department).
Внешний SUM SUM(...) OVER (...) — это оконная функция,
которая работает уже над результатом группировки. Она считает сумму полученных значений.
Без двойного SUM это не работает
Вернется ошибка, потому что SUM(salary) — агрегатная функция, а оконная OVER не может быть применена
к агрегатной функции без GROUP BY.
Двойной SUM решает эту проблему: первый SUM — агрегация (результат группировки),
второй SUM — оконная функция.
Двойной SUM нужен, чтобы:
Сначала агрегировать данные внутри группы (GROUP BY city, department)
Затем применить оконную функцию к агрегированным значениям
Это сокращает запись, избавляя от необходимости использовать подзапрос или CTE.



  */
select
    city,
    department,
    sum(sum(salary)) over() as fund,       ---общая сумма по окну
    sum(sum(salary)) over(partition by city) as fund_city,
    sum(salary) as dep_salary,
    SUM(SUM(salary)) OVER (
        PARTITION BY city
        ORDER BY SUM(salary) DESC, city
        ) AS accumulate_fund_city ---накопительный итог по городу
from employees
GROUP BY city, department
ORDER BY city, dep_salary DESC;


SELECT
    city,
    department,
    STRING_AGG(salary::TEXT, ', ') AS dep_salary_list,
    sum(salary) as salary
FROM employees
GROUP BY city, department
ORDER BY city, department;


/*Скользящие агрегаты это те же сумма, среднее и прочие сводные показатели.

Скользящее среднее обычно применяется для того чтобы понять, например, растут ли доходы или нет
Проблема: Ежедневные данные могут сильно скакать (выходные, праздники, случайные всплески).
Решение: Скользящее среднее сглаживает колебания, показывая реальный тренд.
Скользящее среднее для каждого месяца рассчитывают средний расход с учетом предыдущего и
следующего месяца.
*/

-- Продажи с 7-дневным скользящим средним
SELECT
    year,
    month,
    AVG(expense) OVER (ORDER BY year, month ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7days
FROM expenses
ORDER BY year, month;

/*Фрейм выглядит следующим образом:
  1.rows between x preceding and y following, где X количество строк перед текущей,
  а Y количество строк после текущей
  2.Если указать вместо X или Y значение unbounded это значит от/до границы секции
  Если указать вместо X preceding или Y following значение current row
  - это значит текущая запись.



┌─────┬─────────┬─────────────────────┬───────────────────────────┬───────┬───────┐
│month│ expense │    что в окне       │          расчет           │  avg  │ round │
├─────┼─────────┼─────────────────────┼───────────────────────────┼───────┼───────┤
│  1  │   82    │ [82, 75]            │ (82+75)/2 = 78.50         │ 78.50 │  79   │
│  2  │   75    │ [82, 75, 104]       │ (82+75+104)/3 = 87.00     │ 87.00 │  87   │
│  3  │   104   │ [75, 104, 94]       │ (75+104+94)/3 = 91.00     │ 91.00 │  91   │
│  4  │   94    │ [104, 94, 99]       │ (104+94+99)/3 = 99.00     │ 99.00 │  99   │
│  5  │   99    │ [94, 99, 105]       │ (94+99+105)/3 = 99.33     │ 99.33 │  99   │
│  6  │   105   │ [99, 105, 95]       │ (99+105+95)/3 = 99.67     │ 99.67 │ 100   │
│  7  │   95    │ [105, 95, 110]      │ (105+95+110)/3 = 103.33   │103.33 │ 103   │
│  8  │   110   │ [95, 110, 104]      │ (95+110+104)/3 = 103.00   │103.00 │ 103   │
│  9  │   104   │ [110, 104]          │ (110+104)/2 = 107.00      │107.00 │ 107   │
└─────┴─────────┴─────────────────────┴───────────────────────────┴───────┴───────┘
*/
select
year,
month,
round(avg(expense) over (ORDER BY year, month rows between 1 preceding and 1 following)) as roll_avg
from expenses
where year=2020 and month between 1 and 9
ORDER BY year, month;

/*Rows between UNBOUNDED preceding and UNBOUNDED following
  Это означает, что окно для вычисления среднего включает
  ВСЕ строки результата запроса (с 1 по 9 месяц).
┌─────┬─────────┬─────────────────────────────────────────────────────────────────────────────┬───────────────────────────┬───────┬───────┐
│month│ expense │                              что в окне                                     │          расчет           │  avg  │ round │
├─────┼─────────┼─────────────────────────────────────────────────────────────────────────────┼───────────────────────────┼───────┼───────┤
│  1  │   82    │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  2  │   75    │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  3  │   104   │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  4  │   94    │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  5  │   99    │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  6  │   105   │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  7  │   95    │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  8  │   110   │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
│  9  │   104   │ [82,75,104,94,99,105,95,110,104] (все строки)                               │ 868 / 9 = 96.44           │ 96.44 │  96   │
└─────┴─────────┴─────────────────────────────────────────────────────────────────────────────┴───────────────────────────┴───────┴───────┘

UNBOUNDED PRECEDING	«Бесконечно до начала» — окно начинается с самой первой строки в секции (PARTITION BY)
UNBOUNDED FOLLOWING	«Бесконечно после конца» — окно заканчивается на самой последней строке в секции
Комбинация: UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING = окно включает ВСЕ строки секции.

*/
select
    year,
    month,
    round(avg(expense) over (ORDER BY year, month rows between UNBOUNDED preceding and UNBOUNDED following)) as roll_avg,
    expense
from expenses
where year=2020 and month between 1 and 9
ORDER BY year, month, expense;


/*Rows between UNBOUNDED preceding and CURRENT ROW
Это означает, что окно для вычисления среднего включает все строки от начала
и до текущей строки (накопительное среднее).
Как работает накопительное среднее (UNBOUNDED PRECEDING AND CURRENT ROW)

┌─────┬─────────┬─────────────────────────────────────────────────────┬───────────────────────────┬───────┬───────┐
│month│ expense │                    что в окне                       │          расчет           │  avg  │ round │
├─────┼─────────┼─────────────────────────────────────────────────────┼───────────────────────────┼───────┼───────┤
│  1  │   82    │ [82]                                                │ 82 / 1 = 82.00            │ 82.00 │  82   │
│  2  │   75    │ [82, 75]                                            │ (82+75)/2 = 78.50         │ 78.50 │  79   │
│  3  │   104   │ [82, 75, 104]                                       │ (82+75+104)/3 = 87.00     │ 87.00 │  87   │
│  4  │   94    │ [82, 75, 104, 94]                                   │ (82+75+104+94)/4 = 88.75  │ 88.75 │  89   │
│  5  │   99    │ [82, 75, 104, 94, 99]                               │ сумма/5 = 90.80           │ 90.80 │  91   │
│  6  │   105   │ [82, 75, 104, 94, 99, 105]                          │ сумма/6 = 93.17           │ 93.17 │  93   │
│  7  │   95    │ [82, 75, 104, 94, 99, 105, 95]                      │ сумма/7 = 93.43           │ 93.43 │  93   │
│  8  │   110   │ [82, 75, 104, 94, 99, 105, 95, 110]                 │ сумма/8 = 95.50           │ 95.50 │  96   │
│  9  │   104   │ [82, 75, 104, 94, 99, 105, 95, 110, 104]            │ сумма/9 = 96.44           │ 96.44 │  96   │
└─────┴─────────┴─────────────────────────────────────────────────────┴───────────────────────────┴───────┴───────┘

Формула: roll_avg(month_N) = (expense_1 + expense_2 + ... + expense_N) / N
*/


SELECT year,
       month,
       ROUND(AVG(expense) OVER (ORDER BY year, month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS roll_avg,
       expense
FROM expenses
WHERE year = 2020
  AND month BETWEEN 1 AND 9
ORDER BY year, month, expense;


/*Фрейм от предыдущей до текущей строки
функция avg считает средний доход
┌─────────┬────────┬───────────────────────────────────┬──────────────────────┬─────┬───────┐
│  month  │ income │         Какие строки в окне       │        Расчет        │ avg │ round │
├─────────┼────────┼───────────────────────────────────┼──────────────────────┼─────┼───────┤
│    1    │   94   │ [94] (только текущая)             │ 94 / 1 = 94          │ 94  │   94  │
│    2    │   94   │ [94 (пред.), 94 (тек.)]           │ (94 + 94) / 2 = 94   │ 94  │   94  │
│    3    │   94   │ [94 (пред.), 94 (тек.)]           │ (94 + 94) / 2 = 94   │ 94  │   94  │
│    4    │  100   │ [94 (пред.), 100 (тек.)]          │ (94 + 100) / 2 = 97  │ 97  │   97  │
│    5    │  100   │ [100 (пред.), 100 (тек.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    6    │  100   │ [100 (пред.), 100 (тек.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    7    │  100   │ [100 (пред.), 100 (тек.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    8    │  100   │ [100 (пред.), 100 (тек.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    9    │  104   │ [100 (пред.), 104 (тек.)]         │ (100 + 104) / 2 = 102│ 102 │  102  │
└─────────┴────────┴───────────────────────────────────┴──────────────────────┴─────┴───────┘
*/

SELECT year,
       month,
       income,
       round(avg(income) over (order by year, month rows between 1 preceding and current row))
from expenses
where year = 2020 and month <=9
order by year, month;


/*
┌─────────┬────────┬───────────────────────────────────┬──────────────────────┬─────┬───────┐
│  month  │ income │         Какие строки в окне       │        Расчет        │ avg │ round │
├─────────┼────────┼───────────────────────────────────┼──────────────────────┼─────┼───────┤
│    1    │   94   │ [94 (тек.), 94 (след.)]           │ (94 + 94) / 2 = 94   │ 94  │   94  │
│    2    │   94   │ [94 (тек.), 94 (след.)]           │ (94 + 94) / 2 = 94   │ 94  │   94  │
│    3    │   94   │ [94 (тек.), 100 (след.)]          │ (94 + 100) / 2 = 97  │ 97  │   97  │
│    4    │  100   │ [100 (тек.), 100 (след.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    5    │  100   │ [100 (тек.), 100 (след.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    6    │  100   │ [100 (тек.), 100 (след.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    7    │  100   │ [100 (тек.), 100 (след.)]         │ (100 + 100) / 2 = 100│ 100 │  100  │
│    8    │  100   │ [100 (тек.), 104 (след.)]         │ (100 + 104) / 2 = 102│ 102 │  102  │
│    9    │  104   │ [104] (только текущая)            │ 104 / 1 = 104        │ 104 │  104  │
└─────────┴────────┴───────────────────────────────────┴──────────────────────┴─────┴───────┘
*/

SELECT year,
       month,
       income,
       ROUND(AVG(income) OVER (ORDER BY year, month ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING)) AS roll_avg
FROM expenses
WHERE year = 2020
  AND month <= 9
ORDER BY year, month;


/*
Сумма нарастающим итогом:
Посчитаем доходы и расходы по месяцам нарастающим итогом (кумулятивно)
кумулятивный доход за январь = январь
за февраль = январь + февраль
за март = январь + февраль + март
и так далее

---доходы (t_income)
---расходы(t_expense)
---прибыль(t_profit)
---t_profit = t_income - t_expense


Рамка на каждом шаге охватывает строки от начала таблицы до текущей записи.
UNBOUNDED PRECEDING	«Бесконечно до начала» — окно начинается с самой первой строки в секции
CURRENT ROW - текущая строка

┌─────┬────────┬─────────┬─────────────────────────┬───────────────────────────┬─────────────────────┐
│month│ income │ expense │       t_income          │        t_expense          │      t_profit       │
├─────┼────────┼─────────┼─────────────────────────┼───────────────────────────┼─────────────────────┤
│  1  │   94   │   82    │ 94                      │ 82                        │ 94 - 82 = 12        │
│  2  │   94   │   75    │ 94 + 94 = 188           │ 82 + 75 = 157             │ 188 - 157 = 31      │
│  3  │   94   │   104   │ 188 + 94 = 282          │ 157 + 104 = 261           │ 282 - 261 = 21      │
│  4  │   100  │   94    │ 282 + 100 = 382         │ 261 + 94 = 355            │ 382 - 355 = 27      │
│  5  │   100  │   99    │ 382 + 100 = 482         │ 355 + 99 = 454            │ 482 - 454 = 28      │
│  6  │   100  │   105   │ 482 + 100 = 582         │ 454 + 105 = 559           │ 582 - 559 = 23      │
│  7  │   100  │   95    │ 582 + 100 = 682         │ 559 + 95 = 654            │ 682 - 654 = 28      │
│  8  │   100  │   110   │ 682 + 100 = 782         │ 654 + 110 = 764           │ 782 - 764 = 18      │
│  9  │   104  │   104   │ 782 + 104 = 886         │ 764 + 104 = 868           │ 886 - 868 = 18      │
└─────┴────────┴─────────┴─────────────────────────┴───────────────────────────┴─────────────────────┘
*/
select
    year,
    month,
    income,
    expense,
    sum(income)  over w as t_income,
    sum(expense) over w as t_expense,
    sum(income)  over w - sum(expense) over w as t_profit
from expenses
    where year = 2020 and month <=9
window w as (order by year, month rows between UNBOUNDED PRECEDING and CURRENT ROW)
order by year, month


/*Фонд оплаты труда нарастающим итогом независимо для каждого департамента*/

SELECT id,
       name,
       department,
       salary,
       SUM(salary) OVER w AS total
FROM employees
WINDOW w AS (
        PARTITION BY department
        ORDER BY salary, id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
ORDER BY department, salary, id;

/*Эквивалентен запросу*/
SELECT id,
       name,
       department,
       salary,
       SUM(salary) OVER w AS total
FROM employees
WINDOW w AS (
        PARTITION BY department
        ORDER BY salary, id
        )
ORDER BY department, salary, id;

/*Фрейм по умолчанию
нарастающим итогом*/

select
    year,
    month,
    expense,
    sum(expense) over w as total
from expenses
where year = 2020 and month <= 9
window w as (order by year, month rows between unbounded preceding and current row)
order by year, month;

/*Уберем из него определение фрейма
  Запрос без фрейма посчитал кумулятивные суммы расходов - в точности как запрос
  с фреймом, как так?
  Все дело в наличии сортировки в окне.
  Правило такое - если в окне есть order by и используется функция агрегации и не указано определение
  фрейма, то используем фрейм по умолчанию
  Фрейм по умолчанию распространяется от первой до текущей записи.
  Но так бывает не всегда, поэтому лучше всего указывать фрейм явно, если добавили в окно order by
  сразу добавьте фрейм
  */

select
    year,
    month,
    expense,
    sum(expense) over w as total
from expenses
where year = 2020 and month <= 9
window w as (order by year, month)
order by year, month;

/*Если убрать order by из окна, то агрегат превратится в обычный
  и в каждой строке отобразится сумма всех строк
*/
select
    year,
    month,
    expense,
    sum(expense) over () total
from expenses
where year = 2020 and month <= 9
order by year, month;

/*Функции для скользящих агрегатов
  скользящие агрегаты используют те же самые функции, что и агрегаты обычные

  min()
  max()
  count()
  avg()
  sum()
  group_concat()
*/


/*Статистика
  Когда речь идет о числовых показателях, например: зарплата сотрудников, температура воздуха,
  время ответа сервиса, нам часто интересно понять место отдельного значения в ряду других -
  чтобы понять насколько оно "хорошее" или "плохое".

  Кумулятивное распределение - возьмем зарплату каждого сотрудника и определим, какой процент людей получает
  столько же или меньше.
  Рассчитать поможет функция cume_dist()

  CUME_DIST = (количество строк <= текущая строка) / (общее количество строк)

perc
1.0 ┤                                        ● Иван (120)
0.9 ┤                                   ● Марина ● Леонид (104)
0.8 ┤
0.7 ┤                              ● Анна (100)
0.6 ┤                         ● Григорий ● Вероника (96)
0.5 ┤
0.4 ┤                    ● Ксения (90)
0.3 ┤               ● Елена (84)
0.2 ┤          ● Борис (78)
0.1 ┤     ● Дарья (70)
0.0 ┼────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────
     70   78   84   90   96  100  104       120
                         ↑         ↑
                    скачок     скачок

┌─────────────┬────────────────────────────────────────────────────────────────────────────────┐
│   perc      │                              вывод                                             │
├─────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ 0.1 - 0.4   │ Зарплаты растут равномерно (70 → 78 → 84 → 90)                                 │
│ 0.4 → 0.6   │ СКАЧОК: между 90 и 96 нет сотрудников                                          │
│ 0.6         │ 60% сотрудников получают ≤ 96                                                  │
│ 0.6 → 0.7   │ Анна (100) — единственный в этом диапазоне                                     │
│ 0.7 → 0.9   │ СКАЧОК: между 100 и 104                                                        │
│ 0.9         │ 90% сотрудников получают ≤ 104                                                 │
│ 0.9 → 1.0   │ БОЛЬШОЙ СКАЧОК: Иван (120) значительно опережает всех                          │
└─────────────┴────────────────────────────────────────────────────────────────────────────────┘
*/

select
    name,
    salary,
    cume_dist() over (order by salary) as perc
    from employees;

/*Относительный ранг
  зададимся похожим вопросом: какой процент людей получает строго меньше, чем
  конкретный сотрудник
  ответить поможешь функция percent_rank()

  Формула PERCENT_RANK: (количество строк со значением < текущее) / (всего строк - 1)

Когда что использовать
Задача	Какую функцию использовать
"Сколько процентов сотрудников получают МЕНЬШЕ меня?"           PERCENT_RANK
"Сколько процентов сотрудников получают СТОЛЬКО ЖЕ ИЛИ МЕНЬШЕ?"	CUME_DIST


┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                    ЧТО ГОВОРЯТ ПОКАЗАТЕЛИ ДЛЯ ГРИГОРИЯ                                      │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  Зарплата: 96                                                                               │
│                                                                                             │
│  PERCENT_RANK = 0.44  → 44% сотрудников получают МЕНЬШЕ 96                                  │
│                         (Дарья, Борис, Елена, Ксения)                                       │
│                                                                                             │
│  CUME_DIST = 0.60     → 60% сотрудников получают 96 ИЛИ МЕНЬШЕ                              │
│                         (Дарья, Борис, Елена, Ксения, Григорий, Вероника)                   │
│                                                                                             │
│  Разница = 0.16       → это доля Григория + Вероники (2 человека из 10)                     │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

  Функции имеют смысл только при заданном order by окна.
*/

SELECT
    name,
    salary,
    round(percent_rank() OVER (ORDER BY salary)::numeric, 2) AS perc_rank,
    cume_dist() over (order by salary) as cume_dist
FROM employees
ORDER BY salary;


/*Жаркий март
  Нужно вернуть пять дней с самой высокой температурой в марте
*/

SELECT
    wdate,
    wtemp,
    round(percent_rank() OVER (order by wtemp)::numeric, 2) AS perc_rank,
    round(cume_dist()    OVER (order by wtemp)::numeric, 2) AS cume_dist
FROM weather
where wdate between '2020-03-01' and '2020-03-31'
ORDER BY wtemp DESC
limit 5;


WITH temps AS (SELECT wdate,    -- Дата измерения погоды
                      wtemp,    -- Температура воздуха
                      ROUND(
                                      CUME_DIST() OVER (
                                  PARTITION BY EXTRACT(MONTH FROM wdate) -- Группировка по месяцу (1-12)
                                  ORDER BY wtemp -- Сортировка внутри месяца по температуре
                                  )::numeric,
                                      2
                      ) AS perc -- Перцентиль температуры (0.00 - 1.00)
               FROM weather -- Исходная таблица с данными о погоде
)

SELECT wdate, -- Дата измерения
       wtemp, -- Температура
       perc   -- Перцентиль температуры в месяце
FROM temps -- Ссылка на CTE (временный результат)
WHERE EXTRACT(DAY FROM wdate) = 7 -- Фильтр: только 7-е число каждого месяца
ORDER BY wdate; -- Сортировка по дате возрастания

/*Чтобы посчитать среднее значение устойчивое к выбросам, вместо среднего значения используют медиану
  Чтобы получить медиану, нужно упорядочить элементы по возрастанию и взять тот элемент, что посередине.
  Среднее врет, когда есть выбросы в данных.
*/



/*
Процентили характеризуют конкретный процент выборки, отвечает на вопрос, например, как охарактеризовать
большинство посетителей?
Можно ли сказать, что у большинства посетителей доход <= 96K? Нет: по определению медианы, у половины доход
меньше 96K, а у половины больше. Говоря о большинстве, используют процентили.
Процентиль характеризует конкретный процент выборки.
Вот некоторые распространенные процентили:
25 = X, то у 25% элементов значение =< X
50 = X, то у 50% элементов значение =< X
75 = X, то у 75% элементов значение =< X
90 = X, то у 90% элементов значение =< X
*/

select
    extract(month from wdate) as wmonth,
    round(avg(wtemp)::decimal, 2) as t_avg,
    percentile_disc(0.5) within group (ORDER BY wtemp) as t_med,
    percentile_disc(0.9) within group (order by wtemp) as t_p90
from weather
group by extract(month from wdate)
order by wmonth;


/*Фреймы rows и groups
  Фреймы это группа записей, с которой в данный момент работает оконная функция.
  Фрейм (окно, рамка) — это подмножество строк внутри партиции,
  которое используется для вычисления оконной функции для текущей строки.

  rows between frame_start and frame_end

  Начало фрейма (frame_start) может быть:
  * current row - фрейм начинается с текущей строки
  * N preceding - фрейм начинается с N-й строки перед текущей
  * N following - фрейм начинается с N-й строки после текущей
  * unbounded preceding - фрейм начинается с начала секции.


   Конец фрейма (frame_end) может быть:
  * current row - фрейм продолжается до текущей строки
  * N preceding - фрейм продолжается до N-й строки перед текущей
  * N following - фрейм продолжается до N-й строки после текущей
  * unbounded following - фрейм продолжается до конца секции.

Только у некоторых функций фрейм настраивается:
  *функции смещения fist_value(), last_value(), nth_value();
  *функции агрегации: count(), avg(), sum()

  у прочих функций фрейм всегда равен секции, а если секция не задана то окну в целом.
*/


/*Из таблицы сотрудников employees необходимо вывести
  -размер зарплаты предыдущего сотрудника (не использовать lag и lead)
  -максимальную з.п по департаменту
  */

SELECT id,
       name,
       department,
       salary,
       FIRST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary, id
           ROWS BETWEEN 1 PRECEDING AND UNBOUNDED FOLLOWING) AS prev_salary,
       LAST_VALUE(salary) OVER (PARTITION BY department ORDER BY salary, id
           ROWS BETWEEN 1 PRECEDING AND UNBOUNDED FOLLOWING) AS max_salary
FROM employees
ORDER BY department, id, salary;


SELECT id, name, department, salary,
       LAG(salary, 1) OVER (PARTITION BY department ORDER BY salary) AS prev_salary,
       MAX(salary) OVER (PARTITION BY department) AS max_salary
FROM employees
ORDER BY department, id, salary;



/*Кроме фреймов по строкам бывают еще фреймы по группам groups и диапазонам range

  rows between frame_start and frame_end
  groups between frame_start and frame_end
  range between frame_start and frame_end

Практические рекомендации
Используйте ROWS, когда вам нужно чёткое количество строк (например, «предыдущие 5 заказов»).
Используйте GROUPS, когда вы работаете с категориями или хотите, чтобы дубликаты не разрывались
(например, «предыдущий тарифный план»).
Используйте RANGE, когда логика основана на разнице значений (даты, температуры, цены).
По умолчанию (если фрейм не указан явно) в PostgreSQL действует RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
Это часто приводит к «неправильному» поведению LAST_VALUE (возвращает текущую строку),
поэтому профессионалы всегда указывают фрейм явно, когда используют FIRST_VALUE/LAST_VALUE.
*/

SELECT name,
       department,
       COUNT(*) OVER (ORDER BY department, id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cnt
FROM employees
ORDER BY department, id;

/*Rows фрейм оперирует индивидуальными записями, а groups фрейм - группами записей, у которых одинаковое
  значение столбца order by - в данном случае одинаковый департамент
  В обоих случаях запрос считает количество записей нарастающим итогом от начала до конца фрейма,
  но у rows фрейм заканчивается на текущей записи, а у groups - на последней записи текущей группы!!!
  Поскольку групп всего три, то фрейм смещается рывками.
  */
SELECT name,
       department,
       COUNT(*) OVER (ORDER BY department GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cnt
FROM employees
ORDER BY department, id;


SELECT name,
       department,
       COUNT(*) OVER (ORDER BY department GROUPS BETWEEN CURRENT ROW AND CURRENT ROW) AS cnt
FROM employees
ORDER BY department, id;

/*Фрейм от текущей до следующей группы*/
SELECT name,
       department,
       COUNT(*) OVER (ORDER BY department GROUPS BETWEEN CURRENT ROW AND 1 FOLLOWING) AS cnt
FROM employees
ORDER BY department, id;

/*
Итог
Этот запрос показывает, сколько всего строк в таблице имеют зарплату, не меньшую, чем у текущего сотрудника
(с учётом того, что все строки с одинаковой зарплатой считаются вместе, и их все включают).
По сути, это «ранг» в обратном порядке: самая низкая зарплата получает максимальное количество строк,
самая высокая — минимальное (1).
*/
SELECT name,
       department,
       salary,
       COUNT(*) OVER (ORDER BY salary GROUPS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS cnt
FROM employees
ORDER BY salary, id;

/*Сотрудники с ближайшей большей зарплатой


Когда может пригодиться
Такой запрос полезен, когда нужно для каждой категории (зарплаты, цены, веса) найти следующую отличную категорию
– например, «следующий тарифный план», «следующий уровень скидки», «ближайший более высокий балл».
Это альтернатива DENSE_RANK и самосоединению, но более компактная и эффективная.
Ключевой вывод:
GROUPS BETWEEN 1 FOLLOWING AND 1 FOLLOWING создаёт окно из одной следующей группы целиком,
а FIRST_VALUE извлекает значение из этой группы.
Таким образом, запрос отображает соответствие между
текущей зарплатой и следующей по величине уникальной зарплатой.


Когда может пригодиться
Такой запрос полезен, когда нужно для каждой категории (зарплаты, цены, веса) найти следующую отличную
категорию – например, «следующий тарифный план», «следующий уровень скидки», «ближайший более высокий балл».
Это альтернатива DENSE_RANK и самосоединению, но более компактная и эффективная.

Ключевой вывод
GROUPS BETWEEN 1 FOLLOWING AND 1 FOLLOWING создаёт окно из одной следующей группы целиком,
а FIRST_VALUE извлекает значение из этой группы. Таким образом, запрос отображает соответствие между
текущей зарплатой и следующей по величине уникальной зарплатой.
*/

SELECT id,
       name,
       salary,
       FIRST_VALUE(salary) OVER (ORDER BY salary GROUPS BETWEEN 1 FOLLOWING AND 1 FOLLOWING)
FROM employees
ORDER BY salary, id;


/*Range фреймы это фреймы по диапазону
range оперирует группами строк, которые попадают в диапазон
Посчитаем количество сотрудников по каждому диапазону
*/

SELECT name, salary,
       salary - 10 AS lower_bound,
       salary + 10 AS upper_bound,
       ARRAY_AGG(salary) OVER (ORDER BY salary RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING) AS salaries_in_range,
       COUNT(*) OVER (ORDER BY salary RANGE BETWEEN 10 PRECEDING AND 10 FOLLOWING) AS cnt
FROM employees
ORDER BY salary, id;


SELECT
    wdate,
    wtemp,
    (wdate - interval '1 day')::date AS lower_bound,
    wdate AS upper_bound,
    COUNT(*) OVER (ORDER BY wdate RANGE BETWEEN '1 day' PRECEDING AND CURRENT ROW) AS cnt
FROM weather
ORDER BY wdate;

/*Exclude при применении оконных функций
Используется, когда необходимо исключить часть записей из фрейма

Мы хотим понять как изменится средняя зарплата одного из сотрудников, если уволить
того или иного сотрудника.
Здесь фрейм включает все записи кроме текущей, а функция считает среднюю зарплату для
всех коллег сотрудника, исключая его самого.
*/

SELECT name,
       salary,
       ROUND(AVG(salary) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
           EXCLUDE CURRENT ROW ), 2)
FROM employees
ORDER BY salary, id

/*
Посчитаем среднюю зарплату по сотрудникам которые получают
столько же или больше, чем он, но не более чем 20 тыс.
Сортировка по зарплате
фрейм по диапазону от текущей зарплаты до +20K руб.,
кроме текущего сотрудника.
*/

SELECT id,
       name,
       salary,
       ROUND(AVG(salary) OVER w) AS p20_sal
FROM employees
WINDOW w AS (
        ORDER BY salary
        RANGE BETWEEN CURRENT ROW AND 20 FOLLOWING
            EXCLUDE CURRENT ROW
        )
ORDER BY salary, id;

/*Filter
FILTER — это предложение, которое позволяет применить условную агрегацию
внутри агрегатной функции. Она агрегирует только те строки, которые удовлетворяют условию,
а остальные игнорирует.
aggregate_function(...) FILTER (WHERE условие)
Основное преимущество: несколько агрегатов за одно сканирование
Без FILTER вам пришлось бы делать несколько подзапросов или CASE внутри агрегата.
Как это работает физически
При выполнении запроса PostgreSQL:
Сканирует таблицу (или идёт по индексу) один раз.
Для каждой строки проверяет все условия FILTER параллельно.
Накапливает агрегаты только для тех строк, где условие истинно.
Без FILTER с CASE происходит то же самое физически, но код менее читаемый.
С несколькими подзапросами было бы несколько сканирований.


Примеры:
sql
SELECT
    product_id,
    SUM(revenue) FILTER (WHERE date >= '2024-01-01') AS revenue_jan,
    SUM(revenue) FILTER (WHERE date >= '2024-02-01' AND date < '2024-03-01') AS revenue_feb,
    SUM(revenue) FILTER (WHERE date >= '2024-03-01') AS revenue_mar
FROM sales
GROUP BY product_id;

SELECT
    department,
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE salary > 100000) AS high_paid,
    ROUND(100.0 * COUNT(*) FILTER (WHERE salary > 100000) / COUNT(*), 2) AS high_paid_pct
FROM employees
GROUP BY department;

SELECT
    category,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) AS median_all,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) FILTER (WHERE discount > 0) AS median_discounted
FROM products
GROUP BY category;

SELECT
    sensor_id,
    AVG(temperature) FILTER (WHERE temperature BETWEEN -10 AND 40) AS avg_normal,
    COUNT(*) FILTER (WHERE temperature < -10 OR temperature > 40) AS anomalies
FROM sensor_data
GROUP BY sensor_id;

FILTER работает только с агрегатными функциями
(COUNT, SUM, AVG, MIN, MAX, STRING_AGG, ARRAY_AGG, PERCENTILE_CONT и др.).

Посчитаем как изменится фонд оплаты труда, если кого-то одного уволить, а остальным
  поднять зарплату на 10%

-- Для Ивана (120): +0% = 822 (все остальные)
-- Т.е. если Иван уйдёт, ФОТ сократится с 942 до 822
*/

select
    name,
    department,
    salary,
    sum(salary) over () as "база",
    sum(salary) over w as "+0%",
    sum(salary * 1.1) over w as "+10%"
    from employees
    window w as (
        rows between unbounded preceding and unbounded following
        exclude current row
            )
order by id;

/*А если уволить всех айтишников и отдать ИТ на аустсорс*/

select
    name,
    department,
    salary,
    sum(salary) over () as "база",
    sum(salary) over w as "+0%",
    sum(salary * 1.1) over w as "+10%",
    sum(salary * 1.5) filter(where department <> 'it') OVER () as "+50% без ИТ"

from employees
window w as (
        rows between unbounded preceding and unbounded following
            exclude current row
        )
order by id;

/*Сравнить з.п со средней по городу, мы посчитали сколько процентов составляет
  его зарплата от средней по компании
*/

select
    id,
    name,
    salary,
    round(avg(salary) over ()) as avg,
    round((salary * 100)) as salary_100,
    round(salary * 100 / avg(salary) over ()) as perc
from employees
order by id;

/*Хотим посчитать, сколько процентов составляет зарплата сотрудника от средней по Москве и средней
  по Самаре*/

select
    id,
    name,
    salary,
    round(avg(salary) over ()) as avg,
    round((salary * 100)) as salary_100,
    round(salary * 100 / avg(salary) over ()) as perc,
    round(avg(salary) filter (where city = 'Москва') over ()) as avg_msk,
    round(salary * 100 / avg(salary) filter (where city = 'Москва') over ()) as perc_msk,
    round(avg(salary) filter (where city = 'Самара') over ()) as avg_sam,
    round(salary * 100 / avg(salary) filter (where city = 'Самара') over ()) as perc_sam
from employees
order by id;

/*CASE как альтернатива FILTER
Нас интересует вариант:
- увольняем кого-то из сотрудников
- остальным повышаем зарплату на 10%
- а айтишникам з.п не повышаем и так большая и здесь не получится использовать filter,
так как он совсем отсеивает айтишников, а нам нужно учесть их зарплаты в фонде оплаты труда,
но без повышения на 10%.
*/

SELECT name,
       department,
       salary,
       SUM(salary) OVER ()      AS "база",
       SUM(salary) OVER w       AS "+0%",
       SUM(salary * 1.1) OVER w AS "+10%",
       SUM(
       CASE
           WHEN department = 'it'
               THEN salary
           ELSE salary * 1.1
           END
          ) OVER w              AS "+10% кроме ИТ"

FROM employees
WINDOW w AS (
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            EXCLUDE CURRENT ROW
        )
ORDER BY id;

/*Зарплата меньше IT, но больше HR
для сотрудников отдела hr умножаем зарплату на 2
для сотрудников отдела it делим зарплату    на 2
для сотрудников отдела sales не меняем зарплату

Запрос вычисляет для каждого сотрудника три суммы с
разбивкой по городам (PARTITION BY city)
и с разными весами для отделов внутри CASE.


┌─────────────────────────────────────────────────────────────────────────────┐
│                         ВСЯ ТАБЛИЦА (total = 942)                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
        ┌───────────────────┐           ┌───────────────────┐
        │     МОСКВА        │           │     САМАРА        │
        │   base = 510      │           │   base = 432      │
        ├───────────────────┤           ├───────────────────┤
        │ it: 90→45         │           │ hr: 70→140        │
        │ it: 104→52        │           │ hr: 78→156        │
        │ it: 120→60        │           │ it: 84→42         │
        │ sales: 96→96      │           │ it: 104→52        │
        │ sales: 100→100    │           │ sales: 96→96      │
        ├───────────────────┤           ├───────────────────┤
        │ alt = 353         │           │ alt = 486         │
        └───────────────────┘           └───────────────────┘

Вывод по городам:
Москва: alt = 353 < base = 510 (IT-специалистов много, их вес уменьшили)
Самара: alt = 486 > base = 432 (HR-специалистов много, их вес увеличили)
В окне w нет ORDER BY, поэтому фрейм по умолчанию включает все строки партиции (от первой до последней)
Eсли бы был ORDER BY, то фрейм был бы RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.
*/

select
    name,
    city,
    salary,
    sum(salary) over() as total,
    sum(salary) over w as base,
    sum(
    case when department = 'hr' then salary * 2
         when department = 'it' then salary / 2
    else salary
    end
    ) over w as alt
FROM employees
window w as (partition by city)
order by city, id

/*Практика
  Оконные функции используются в продуктовой и финансовой аналитике

Сначала агрегация, затем окна
Допустим мы хотим сначала посмотреть как выручка за каждый год соотносится с выручкой за два года
Сначала считаем агрегаты по годам
*/
select
    year,
    sum(revenue) as revenue
    from sales
group by year

/*Теперь с помощью оконных функций считаем общую выручку на агрегированных результатах:
*/

WITH data AS (SELECT year,
                     SUM(revenue) AS revenue
              FROM sales
              GROUP BY year)

SELECT year,
       revenue,
       SUM(revenue) OVER () AS total_revenue
FROM data


/*Можно написать короче
GROUP BY year — группирует данные по годам
SUM(revenue) — вычисляет сумму выручки за каждый год (агрегат первого уровня)
SUM(SUM(revenue)) OVER () — берёт результат первого агрегата (годовые суммы)
и суммирует их через оконную функцию по всей таблице
Ошибка: Нельзя смешивать оконную функцию SUM OVER с GROUP BY, если в SELECT нет агрегации.
PostgreSQL не поймёт, что делать.
*/

SELECT year,
       SUM(revenue),
       SUM(SUM(revenue)) OVER () AS total_revenue
FROM sales
GROUP BY year
ORDER BY year;

/*Сначала окна потом фильтрация
  Мы хотим посмотреть как соотносится месячная выручка по тарифам silver и gold
*/

SELECT month,
       (CASE WHEN plan = 'silver' THEN revenue END)   AS silver,
       (CASE WHEN plan = 'gold'   THEN revenue END)   AS gold
FROM sales
WHERE year = 2020
  AND plan IN ('gold', 'silver')
ORDER BY month, plan;

/*Все хорошо только нужные нам значения оказались в различных строках
  max выбирает не null значение, он схлопывает две строчи по каждому
  месяцу в одну*/
SELECT month,
       MAX(CASE WHEN plan = 'silver' THEN revenue END) AS silver,
       MAX(CASE WHEN plan = 'gold'   THEN revenue END) AS gold
FROM sales
WHERE year = 2020
  AND plan IN ('gold', 'silver')
GROUP BY month
ORDER BY month;

/*Посчитайте выручку по тарифу gold по месяцам 202 года
  выручка за предыдущий месяц
  процент который составляет выручка текущего месяца от предыдущего
  сортировка по month
*/

select
    year,
    month,
    revenue,
    sum(revenue) over w as acc_sum,
    lag(revenue) over w as prev,
    round(revenue * 100 / lag(revenue) over w) as perc
from sales
where year = 2020 and plan = 'gold'
window w as (order by month)
order by month;

/*Посчитайте выручку нарастающим итогом по каждому тарифному плану за первые три месяца 2020 года
секции по тарифам
сортировка по месяцам
sum() для выручки нарастающим итогом
*/

select
plan,
year,
month,
revenue,
sum(revenue) over w as total
from sales
where year = 2020 and quarter = 1
window w as (partition by plan order by month)
order by plan, month;

/*Скользящее среднее по тарифу platinum
  посчитайте скользящее среднее за 3 месяца для тарифа platinum в 2020 году
  округлите выручку до целого

  сортировка по месяцам
  строковый фрейм на предыдущую текущую и следующую записи
  avg для расчета скользящего среднего*/

SELECT year,
       month,
       revenue,
       AVG(revenue) OVER (ORDER BY month ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS "avg3"
FROM sales
WHERE year = 2020
  AND plan = 'platinum'
ORDER BY month;

/*Сравнение с декабрем, есть таблица продаж sales посчитайте выручку по месяцам для тарифа silver
  для каждого месяца дополнительно укажите
  выручку за декабрь этого же года
  процент, который составляет выручка текущего месяца от декабря 2026

  фрейм равен секции год
  last_value чтобы получить выручку за декабрь
*/

select
    year,
    month,
    revenue,
    last_value(revenue) over w as decembr,
    round(revenue * 100 / last_value(revenue) OVER w) as perc

    from sales
where plan = 'silver'
window w as (
    PARTITION BY year
    ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING
        )
order by year, month;

/*Как работает: NTH_VALUE(revenue, 3)
берёт значение из третьей строки окна
(при ORDER BY month это месяц=3)

Партиция для year=2020 (plan='silver'):

┌───────┬─────────┬─────────┐
│ month │ revenue │ позиция │
├───────┼─────────┼─────────┤
│   1   │  14400  │    1    │
│   2   │  61200  │    2    │
│   3   │  42000  │    3    │ ← NTH_VALUE(..., 3) = 42000
│   4   │  42000  │    4    │
│   5   │  39000  │    5    │
│  ...  │   ...   │   ...   │
│  12   │  28800  │   12    │
└───────┴─────────┴─────────┘

Для каждой строки в этой партиции:
march_revenue = 42000 (одинаково для всех строк)
perc = revenue * 100 / 42000


NULLIF(NULL, 0)   -- возвращает NULL (первый аргумент)
NULLIF(0, 0)      -- возвращает NULL (аргументы равны)
NULLIF(5, 0)      -- возвращает 5 (аргументы не равны)
NULLIF(NULL, NULL) -- возвращает NULL (аргументы равны, оба NULL)

Если NTH_VALUE вернёт 0:
NULLIF(0, 0) → NULL
100.0 / NULL → NULL (нет ошибки)
ROUND(NULL, 2) → NULL


SELECT NULLIF(trim(phone), '') AS phone FROM users;
-- '' (пустая строка) становится NULL

SELECT NULLIF(temperature, -999) AS temp FROM sensors;
-- -999 (признак отсутствия данных) становится NULL

┌─────────────────────────────────────────────────────────────────┐
│                      Функция NULLIF(x, 0)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ x = 42000 ──→ 42000 != 0 ──→ возвращаем 42000                   │
│                                                                 │
│ x = 0 ──────→ 0 == 0 ──────→ возвращаем NULL                    │
│                                                                 │
│ x = NULL ───→ NULL != 0? Сравнение даёт NULL ──→ возвращаем NULL│
│                 (по правилам SQL, NULL не равно 0)              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
*/

SELECT
    year,
    month,
    revenue,
    NTH_VALUE(revenue, 3) OVER w AS march_revenue,
    ROUND(revenue * 100.0 / NULLIF(NTH_VALUE(revenue, 3) OVER w, 0), 2) AS percent_of_march
FROM sales
WHERE plan = 'silver'
WINDOW w AS (
        PARTITION BY year
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )
ORDER BY year, month;

SELECT
    year,
    month,
    revenue,
    MAX(revenue) FILTER (WHERE month = 3) OVER (PARTITION BY year) AS march,
    ROUND(revenue * 100 / NULLIF(MAX(revenue) FILTER (WHERE month = 3) OVER (PARTITION BY year), 0), 2) AS perc
FROM sales
WHERE plan = 'silver'
ORDER BY year, month;

/*Вклад тарифов
  запрос агрегируем выручку по тарифам внутри года
  затем берем окно с секцией по годам
  считаем выручку за год через sum() по секции.
*/


with data as (
    select
        year,
        plan,
        sum(revenue) as revenue
    from sales
group by year, plan
)

select
    year,
    plan,
    revenue,
    sum(revenue) OVER w as total,
    round(revenue * 100 / sum(revenue) OVER w) as perc
from data
window w as (PARTITION BY year)
order by year, plan;

/*Высокая, средняя и низкая выручка
  агрегируем выручку по месяцам
  разбиваем на группы через ntile()
*/


with data as (
    select
        year,
        month,
        sum(revenue) as revenue
    from sales
    where year = 2020
    group by year, month
)

select
    year,
    month,
    revenue,
    ntile(3) over (order by revenue desc)
from data
order by revenue desc, month;


/*Выручка по кварталам 2020 года против 2019 года
  -выручка за аналогичный квартал 2019 года prev
  -процент, который составляет выручка текущего квартала от prev
*/

SELECT
    quarter,
    SUM(CASE WHEN year = 2020 THEN revenue END) AS revenue_2020,
    SUM(CASE WHEN year = 2019 THEN revenue END) AS revenue_2019,
    ROUND(
            100.0 * SUM(CASE WHEN year = 2020 THEN revenue END) /
            NULLIF(SUM(CASE WHEN year = 2019 THEN revenue END), 0)
    ) AS yoy_percent
FROM sales
WHERE year IN (2019, 2020)
GROUP BY quarter
ORDER BY quarter;


SELECT
    quarter,
    SUM(revenue) FILTER (WHERE year = 2020) AS revenue_2020,
    SUM(revenue) FILTER (WHERE year = 2019) AS revenue_2019,
    ROUND(100.0 * SUM(revenue) FILTER (WHERE year = 2020) /
          NULLIF(SUM(revenue) FILTER (WHERE year = 2019), 0)) AS yoy_percent
FROM sales
WHERE year IN (2019, 2020)
GROUP BY quarter
ORDER BY quarter;

WITH quarterly AS (
    SELECT
        quarter,
        SUM(revenue) FILTER (WHERE year = 2020) AS revenue_2020,
        SUM(revenue) FILTER (WHERE year = 2019) AS revenue_2019
    FROM sales
    WHERE year IN (2019, 2020)
    GROUP BY quarter
)
SELECT
    quarter,
    revenue_2020,
    revenue_2019,
    ROUND(100.0 * revenue_2020 / NULLIF(revenue_2019, 0)) AS yoy_percent
FROM quarterly
ORDER BY quarter;



SELECT
    month,
    SUM(revenue) FILTER (WHERE year = 2020) AS revenue_2020,
    SUM(revenue) FILTER (WHERE year = 2019) AS revenue_2019,
    ROUND(100.0 * SUM(revenue) FILTER (WHERE year = 2020) /
          NULLIF(SUM(revenue) FILTER (WHERE year = 2019), 0), 2) AS yoy_percent
FROM sales
WHERE year IN (2019, 2020)
GROUP BY month
ORDER BY month;


SELECT * FROM pg_extension WHERE extname = 'tablefunc';
SELECT
    proname,
    pronamespace::regnamespace AS schema_name
FROM pg_proc
WHERE proname = 'crosstab';

-- Удалить расширение
DROP EXTENSION IF EXISTS tablefunc CASCADE;
SHOW search_path;
SELECT pronamespace::regnamespace FROM pg_proc WHERE proname = 'crosstab';

SELECT *
FROM public.crosstab(
             $$
        SELECT month, year, SUM(revenue)
        FROM sales
        WHERE year BETWEEN 2019 AND 2020
        GROUP BY month, year
        ORDER BY 1, 2
    $$,
             $$
        SELECT generate_series(2019, 2020)::int
    $$
     ) AS ct(month INT, y2019 NUMERIC, y2020 NUMERIC);

SELECT *
FROM public.crosstab(
             $$
        SELECT month, year, SUM(revenue)
        FROM sales
        WHERE year BETWEEN 2019 AND 2020
        GROUP BY month, year
        ORDER BY 1, 2
    $$,
    $$ SELECT 2019 UNION SELECT 2020 ORDER BY 1 $$
     ) AS ct(month INT, y2019 NUMERIC, y2020 NUMERIC);



/*Crosstab

Шаг 1: Исходные данные (первый аргумент)
sql
SELECT month, year, SUM(revenue)
FROM sales
WHERE year IN (2019, 2020)
GROUP BY month, year
ORDER BY month, year

  Результат (длинный формат):
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   month │ year │ revenue                                    │
│   ──────┼──────┼─────────                                   │
│     1   │ 2019 │   12000  ←──┐                              │
│     1   │ 2020 │   14400     │                              │
│     2   │ 2019 │   58000     │  Каждый месяц повторяется    │
│     2   │ 2020 │   61200     │  для каждого года            │
│     3   │ 2019 │   44000     │                              │
│     3   │ 2020 │   42000     │                              │
│     4   │ 2019 │   38000     │                              │
│     4   │ 2020 │   40000     │                              │
│    ...  │ ...  │    ...      │                              │
│    12   │ 2019 │   60000     │                              │
│    12   │ 2020 │   66000     │                              │
└─────────────────────────────────────────────────────────────┘

Три колонки:
month — идентификатор строки (row_name)
year — категория (category), которая станет колонками
revenue — значение (value)

Шаг 2: Второй аргумент — какие колонки создавать
sql
SELECT generate_series(2019, 2020)

Результат:

text
┌─────────────────────────────────────────────────────────────┐
│   generate_series                                           │
│   ─────────────────                                         │
│   2019  ←── станет первой колонкой                          │
│   2020  ←── станет второй колонкой                          │
└─────────────────────────────────────────────────────────────┘

Это говорит crosstab: "Создай две колонки.
В первую положи значения для year=2019, во вторую — для year=2020".


Шаг 3: Процесс «поворота» (визуализация)
text
ИСХОДНЫЕ ДАННЫЕ                          РЕЗУЛЬТАТ (после поворота)
(длинный формат)                         (широкий формат)

┌─────┬──────┬─────────┐                ┌─────┬──────────┬──────────┐
│month│ year │ revenue │                │month│  revenue │ revenue  │
├─────┼──────┼─────────┤                │     │ for 2019 │ for 2020 │
│  1  │ 2019 │  12000  │                ├─────┼──────────┼──────────┤
│  1  │ 2020 │  14400  │      ──→       │  1  │  12000   │  14400   │
├─────┼──────┼─────────┤                ├─────┼──────────┼──────────┤
│  2  │ 2019 │  58000  │                │  2  │  58000   │  61200   │
│  2  │ 2020 │  61200  │      ──→       ├─────┼──────────┼──────────┤
├─────┼──────┼─────────┤                │  3  │  44000   │  42000   │
│  3  │ 2019 │  44000  │      ──→       ├─────┼──────────┼──────────┤
│  3  │ 2020 │  42000  │                │  4  │  38000   │  40000   │
├─────┼──────┼─────────┤                ├─────┼──────────┼──────────┤
│  4  │ 2019 │  38000  │                │ ... │   ...    │   ...    │
│  4  │ 2020 │  40000  │      ──→       ├─────┼──────────┼──────────┤
└─────┴──────┴─────────┘                │ 12  │  60000   │  66000   │
                                        └─────┴──────────┴──────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                          АЛГОРИТМ CROSSTAB                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Прочитать данные из первого запроса                                     │
│     (отсортированные по row_name и category)                                │
│                                                                             │
│  2. Прочитать список категорий из второго запроса                           │
│     (порядок определяет порядок колонок)                                    │
│                                                                             │
│  3. Для каждой уникальной row_name:                                         │
│     ┌─────────────────────────────────────────────────────────────────┐     │
│     │  a) Создать новую строку результата                             │     │
│     │  b) В первой колонке записать row_name (month)                  │     │
│     │  c) Для каждой категории из второго запроса (по порядку):       │     │
│     │     - Найти значение из исходных данных, где category совпадает │     │
│     │     - Положить в соответствующую колонку                        │     │
│     │     - Если значения нет → NULL                                  │     │
│     └─────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  4. Вернуть результат                                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Шаг 6: Визуализация соответствия колонок
text
Второй аргумент:                          Определение колонок в AS ct(...):
generate_series(2019, 2020)               AS ct(month INT, y2019 NUMERIC, y2020 NUMERIC)

┌──────────────────────┐                  ┌──────────────────────────────────────────┐
│                      │                  │                                          │
│  Строка 1: 2019  ────┼──────┐           │  Колонка 1: month (row_name)             │
│                      │      │           │  Колонка 2: y2019 ←── соответствует 2019 │
│  Строка 2: 2020  ────┼──────┼──────┐    │  Колонка 3: y2020 ←── соответствует 2020 │
│                      │      │      │    │                                          │
└──────────────────────┘      │      │    └──────────────────────────────────────────┘
                              │      │
                              ▼      ▼
                    ┌─────────────────────────────────┐
                    │  РЕЗУЛЬТИРУЮЩАЯ ТАБЛИЦА         │
                    ├─────────────────────────────────┤
                    │ month │ y2019  │ y2020          │
                    ├───────┼────────┼────────────────┤
                    │   1   │ 12000  │ 14400          │
                    │   2   │ 58000  │ 61200          │
                    │   3   │ 44000  │ 42000          │
                    │  ...  │  ...   │  ...           │
                    └───────┴────────┴────────────────┘


Итоговая схема работы
text
┌────────────────────────────────────────────────────────────────────────────┐
│                                                                            │
│   ДЛИННЫЙ ФОРМАТ                      ШИРОКИЙ ФОРМАТ                       │
│   (нормализованные данные)            (отчёт/сводная таблица)              │
│                                                                            │
│   ┌─────┬──────┬─────────┐           ┌─────┬──────────┬──────────┐         │
│   │ряд  │катего│значение │           │ряд  │категория1│категория2│         │
│   │     │рия   │         │           │     │          │          │         │
│   ├─────┼──────┼─────────┤           ├─────┼──────────┼──────────┤         │
│   │ 1   │ A    │  100    │           │ 1   │   100    │   200    │         │
│   │ 1   │ B    │  200    │           ├─────┼──────────┼──────────┤         │
│   │ 2   │ A    │  300    │    →      │ 2   │   300    │   400    │         │
│   │ 2   │ B    │  400    │           ├─────┼──────────┼──────────┤         │
│   │ 3   │ A    │  500    │           │ 3   │   500    │   NULL   │         │
│   │ 3   │ B    │  NULL   │           └─────┴──────────┴──────────┘         │
│   └─────┴──────┴─────────┘                                                 │
│                                                                            │
│   crosstab = "поворот" строк в колонки                                     │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
*/


/*Рейтинг месяцев по продажам
- секции по тарифам, чтобы рассчитать рейтинг месяцев по тарифам
- сортировка по убыванию количества продаж, чтобы с большим количества продаж
  занимали более высокие места;
- rank() для расчета рейтинга;
- через sum() + case выносим рейтинг по каждому тарифу в отдельный столбец.
*/

WITH data AS (SELECT year,
                     month,
                     plan,
                     revenue,
                     RANK() OVER w AS qrank
              FROM sales
              WHERE year = 2020
              WINDOW w AS (PARTITION BY plan ORDER BY revenue DESC
                      ))

SELECT year,
       month,
       MAX(CASE WHEN plan = 'silver'   THEN qrank ELSE 0 END)   AS silver_qrank,
       MAX(CASE WHEN plan = 'gold'     THEN qrank ELSE 0 END)   AS gold_qrank,
       MAX(CASE WHEN plan = 'platinum' THEN qrank ELSE 0 END)   AS platinum_qrank
FROM data
GROUP BY year, month
ORDER BY month;


SELECT *
FROM (VALUES
          (1, 51, 'первое'),
          (2, 52, 'второе'),
          (3, 53, 'третье'),
          (4, 55, 'четвёртое'),
          (5, 56, 'пятое'),
          (6, 59, 'шестое')
     ) AS numbers1(id, num, description);


CREATE TEMP TABLE numbers1 (
                               id INTEGER,
                               num INTEGER,
                               description TEXT
);

-- Затем вставить данные
INSERT INTO numbers1 (id, num, description) VALUES
                                                (1, 51, 'первое'),
                                                (2, 52, 'второе'),
                                                (3, 53, 'третье'),
                                                (4, 55, 'четвёртое'),
                                                (5, 56, 'пятое'),
                                                (6, 59, 'шестое');

/*Кластеризация
  При анализе данных бывает удобно разбить dataset на группы близких значений
  частный случай такой задачи - поиск островов в данных (islands)

┌──────────────┬────────────┬───────────────┐
│ island_start │ island_end │ island_length │
├──────────────┼────────────┼───────────────┤
│      1       │     3      │       3       │
│      5       │     7      │       3       │
│     10       │     12     │       3       │
└──────────────┴────────────┴───────────────┘


  num | ROW_NUMBER() | num - ROW_NUMBER() | island_id
----|--------------|--------------------|----------
1   | 1            | 0                  | 0
2   | 2            | 0                  | 0
3   | 3            | 0                  | 0
5   | 4            | 1                  | 1  ← изменилось!
6   | 5            | 1                  | 1
7   | 6            | 1                  | 1
10  | 7            | 3                  | 3  ← изменилось!
11  | 8            | 3                  | 3
12  | 9            | 3                  | 3
*/


CREATE TABLE numbers2 (num INT);
INSERT INTO numbers2 VALUES (1),(2),(3),(5),(6),(7),(10),(11),(12);

-- Найти острова (непрерывные последовательности)
WITH grp AS (
    SELECT
        num,
        num - ROW_NUMBER() OVER (ORDER BY num) AS island_id
    FROM numbers2
)
SELECT
    MIN(num) AS island_start,
    MAX(num) AS island_end,
    COUNT(*) AS island_length
FROM grp
GROUP BY island_id
ORDER BY island_start;




-- Данные о посещениях пользователя
CREATE TABLE visits (
                        user_id INT,
                        visit_date DATE
);

INSERT INTO visits VALUES
                       (1, '2024-01-01'),
                       (1, '2024-01-02'),
                       (1, '2024-01-03'),
                       (1, '2024-01-05'),  -- пропуск
                       (1, '2024-01-06'),
                       (1, '2024-01-07'),
                       (1, '2024-01-10'),  -- пропуск
                       (1, '2024-01-11');

-- Поиск непрерывных серий (островов)
WITH numbered AS (
    SELECT
        user_id,
        visit_date,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY visit_date) AS rn
    FROM visits
),
     islands AS (
         SELECT
             user_id,
             visit_date,
             visit_date - (rn * INTERVAL '1 day') AS grp  -- ключевая формула
         FROM numbered
     )
SELECT
    user_id,
    MIN(visit_date) AS series_start,
    MAX(visit_date) AS series_end,
    COUNT(*) AS days_count
FROM islands
GROUP BY user_id, grp
ORDER BY user_id, series_start;

/*Аналитические запросы обычно используют оконные функции
  Но и в кластеризации тоже
  Идентифицируем острова
  для начала пронумеруем записи по возрастанию значений
*/

select
    num,
    row_number() over(order by num)
from numbers
/*Сам по себе номер строки не очень интересен, но у него есть полезное свойство - пока значения num
  идут подряд то разность num p rownum постоянна
*/

select
    num,
    row_number() over (order by num) as rownum,
    num - row_number() over (order by num) as diff_id
from numbers;

/*diff_id можно считать идентификатором острова, осталось только сгруппировать по нему,
  чтобы получить границы островов и количество записей в каждом
*/

with ngropus as (
    select
        num,
        row_number() over (order by num) as rownum,
        num - row_number() over (order by num) as diff_id
    from numbers
)

select
    min(num) as n_start,
    max(num) as n_end,
    count(*) as n_count
from ngropus
GROUP BY diff_id
order by 1;


/*Если у еас повторяющиеся значения, например два значения 52, то необходимо использовать
  функцию ранжирования, она выдает одинаковые значения rownum для одних и тех же
  значений num*/
with ngropus as (
    select
        num,
        dense_rank() over (order by num) as rownum,
        num - dense_rank() over (order by num) as diff_id
    from numbers
)
select
    min(num) as n_start,
    max(num) as n_end,
    count(*) as n_count
from ngropus
GROUP BY diff_id
order by 1;

/*Острова на датах
  представьте себе обучающую платформу, на которой люди выполняют задания и получают
  за это баллы.
  В базе данных может быть таблица activity, которая хранит баллы, набранные пользователем
  в конкретные дни.

  Допустим нас интересуют острова по датам для пользователя 51 - то есть периоды времени, когда он
  занимался каждый день без перерыва.

  Как преобразовать дату в количество дней
*/

with agroups as (
    select adate,
           extract(epoch from adate)/86400  - dense_rank() over (order by adate) as group_id
    from activity
    where user_id = 51
)

select
    min(adate) as day_start,
    max(adate) as day_end,
    count(*) as day_count
from agroups
group by group_id;

/*Нужно найти серию без перерывов
  посчитать периоды в которые пользователь набирал
  хотя бы один балл каждый день без перерыва
  Серия из одного дня тоже считается
*/

WITH agroups AS (SELECT user_id,
                        adate,
                        EXTRACT(EPOCH FROM adate) / 86400 -
                        DENSE_RANK() OVER (PARTITION BY user_id ORDER BY adate) AS group_id
                 FROM activity
)

select
    user_id,
    min(adate) as day_start,
    max(adate) as day_end,
    count(*) as day_count
from agroups
group by user_id, group_id
ORDER BY user_id, day_start,day_end;


/*Только серии ≥ 3 дней*/
WITH agroups AS (SELECT user_id,
                        adate,
                        EXTRACT(EPOCH FROM adate) / 86400 -
                        DENSE_RANK() OVER (PARTITION BY user_id ORDER BY adate) AS group_id
                 FROM activity
)

SELECT
    user_id,
    MIN(adate) AS day_start,
    MAX(adate) AS day_end,
    COUNT(*) AS day_count
FROM agroups
GROUP BY user_id, group_id
HAVING COUNT(*) >= 3   -- только серии от 3 дней и более
ORDER BY user_id, day_start,day_end;

/*Кластеры значений
  Мы начали главу с того, что при анализе данных бывает удобно разбить датасет на группы
  близких значений
  Но близкие не означает того, что они идут подряд
  Например есть числа 51.52.53.55.56.59.61.72
включим в одну и ту же группу значения которые могут отличаться друг от друга на один или на два

Кластер 1: 51-56 (5 элементов: 51,52,53,55,56)
Кластер 2: 59-61 (2 элемента: 59,61)
Кластер 3: 72-72 (1 элемент: 72)

Ключевые наблюдения:

Дубликат 52 не разрывает кластер (расстояние 0 не > 2)
59 и 61 попали в один кластер (расстояние 2)
72 — отдельный кластер (расстояние 11)
*/

--расстояния между соседями
WITH distinct_numbers AS (
    SELECT DISTINCT num FROM numbers
),
nlags AS (
    SELECT
        num,
        num - LAG(num) OVER (ORDER BY num) AS n_lag
    FROM distinct_numbers
),

--границы кластеров
ngroups as (SELECT num,
                   sum(CASE WHEN n_lag > 2 THEN 1 ELSE 0 END) over (order by num)  AS group_id
            FROM nlags)
--сами кластеры

SELECT
    MIN(num) AS n_start,
    MAX(num) AS n_end,
    COUNT(*) AS n_count
FROM ngroups
GROUP BY group_id;

