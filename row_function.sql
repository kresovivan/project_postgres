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
Рейтинг сотрудников по заработной платe.
Составим рейтинг сотрудников по размеру заработной платы
dense_rank() считает ранг по указанному окну, начинет с 1
и увеличивает ранг каждый раз, когда очереденое значение из окна
отличается от предыдущего.

Движок выполняет следующим образом запрос:
-выбирает из нее все записи
-для каждой записи рассчитывает значение dense_rank() с помощью окна w.
-cортирует результат как указано в order by

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
 * Для каждого сотрудникак хотим увидеть сколько процентов
 * составляет его зарплата от макисмальной в городе*/

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
7.Отсортироровать то, что получилось order by
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


/*Скользящие агрегаты*/







