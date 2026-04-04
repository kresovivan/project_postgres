CREATE SCHEMA IF NOT EXISTS row_function;

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
  строковый фрейм на предыдущю текущую и следующую записи
  avg для расчета скользящего среднего*/

