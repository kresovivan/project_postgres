


SELECT DATE_PART('dow', date '2025-10-13'); --- день недели
 
SELECT TO_CHAR(date '2025-10-13', 'day'); --- день недели

SELECT DATE_TRUNC('month', DATE '2025-10-13'); ---к началу месяца

SELECT CAST('2020-10-15' AS TIMESTAMP);

SELECT TO_DATE('10-15-22','MM-DD-YY');

SELECT TO_TIMESTAMP('1030','HH24MI');

SELECT EXTRACT(YEAR FROM TO_DATE('01-02-2024','MM/DD/YYYY'))



/*ОКРАЩЕНИЕ СПИСКА GROUP BY ДЛЯ ПОВЫШЕНИЯ ЭФФЕКТИВНОСТИ
Если известно, что каждый идентификатор связан с одним именем, то можно 
исключить столбец name из предложения GROUP BY и  получить те  же 
результаты, которые дал предыдущий запрос:
SELECT id,
 MAX(name) AS name,
 COUNT(date) AS workouts,
 SUM(calories) AS calories
FROM daily_workouts 
GROUP BY id;
Этот механизм работает более эффективно, будучи скрытым, так как GROUPBY
должно выполняться только для одного столбца.
Чтобы компенсировать исключение имени из предложения GROUP BY, можно 
заметить, что к столбцу name в предложении SELECT была применена произвольная агрегатная функция (MAX). Поскольку в каждой группе идентификаторов 
существует только одно значение имени, MAX(name) просто вернет имя, 
связанное с каждым идентификатором.
*/

/*
Используем GROUP_CONCAT в MySQL, чтобы создать список 
калорий:
SELECT name,
 GROUP_CONCAT(calories) AS calories_list
FROM workouts
GROUP BY name;
+------+---------------+
| name | calories_list |
+------+---------------+
| ally | 80,75,90 |
| jess | 100,92 |
+------+---------------+
*/

/*
 *Сортированный список
 * PostgreSQL ARRAY_AGG(calories ORDER
 * BY calories)
 * Уникальный список
 * ARRAY_AGG(DISTINCT
 * calories)
 * */

/*
Строки 2019, 2020 и суммарных расходов добавляются с помощью ROLLUP:
SELECT year, month,
 SUM(amount) AS total
FROM spendings
GROUP BY ROLLUP(year, month)
ORDER BY year, month;
*/


/*
Oracle, PostgreSQL и SQL Server поддерживают функцию CUBE, 
которая расширяет ROLLUP за счет добавления дополнительных 
строк, в которых показываются все возможные комбинации 
столбцов, по которым производится группировка, а также 
общий итог.
С помощью CUBE также можно отображать ежемесячные расходы (один месяц за несколько лет). Строки расходов за январь 
и февраль вставляются при добавлении CUBE:
SELECT year, month,
 SUM(amount) AS total
FROM spendings
GROUP BY CUBE(year, month)
ORDER BY year, month;
 YEAR MONTH TOTAL
----- ------ ------
 2019 1        50
 2019          50
              256  
 2020 1        42
 2020 2       137
 2020         179
      1       92 -- January spendings
      2       137 -- February spendings
              229
Приведенный выше синтаксис работает в Oracle, PostgreSQL 
и SQL Server. Кроме того, SQL Server поддерживает синтаксис 
GROUP BY year, month WITH CUBE.
*/



/*
 * GROUPING SETS
 * Oracle, PostgreSQL и SQL Server поддерживают GROUPING
 * SETS, позволяющие указать конкретные группы, которые необходимо отобразить.
 * Эти данные представляют собой подмножество результатов, 
 * сгенерированных функцией CUBE, и содержат группировки 
 * лишь по одному столбцу. В данном случае возвращаются 
 * только общие годовые и общие ежемесячные расходы:
 * SELECT year, month,
 * SUM(amount) AS total
 * FROM spendings
 * GROUP BY GROUPING SETS(year, month)
 * ORDER BY year, month;
*/

/*
 * Агрегатная функция
 * Функция SUM() является агрегатной. Этот запрос суммирует 
 * продажи для каждого человека и возвращает каждое имя вместе с его значением total_sales:
 * SELECT name,
 * SUM(sales) AS total_sales
 * FROM sales
 * GROUP BY name;
+-------+-------------+
| name | total_sales |
+-------+-------------+
| David | 13 |
| Laura | 25 |
 * 
 * 
 * 
 * Оконная функция
 * Функция ROW_NUMBER() OVER (PARTITION BY name ORDER BY month)
 * является оконной. В части этого запроса, выделенной жирным 
 * шрифтом, для каждого человека генерируется номер строки, 
 * обозначающий первый месяц, второй и т. д., в которые этот 
 * человек что-то продал. Запрос возвращает каждую строку 
 * вместе со значением sale_month.
 * SELECT name,
 * ROW_NUMBER() OVER (PARTITION BY name
 * ORDER BY month) AS sale_month
 * FROM sales;
+-------+------------+
| name | sale_month |
+-------+------------+
| David | 1 |
| David | 2 |
| Laura | 1 |
| Laura | 2 |
| Laura | 3 |
| Laura | 4 |
+-------+------------+

 * РАЗБОР ОКОННОЙ ФУНКЦИИ
 * ROW_NUMBER() OVER (PARTITION BY name ORDER BY month)
 * Окно представляет собой группу строк. В предыдущем примере было два окна. 
 * Окно имени David состояло из двух строк, а окно имени Laura — из четырех.
 * ROW_NUMBER() — функция, которую необходимо применить к каждому 
 * окну. Она обязательна. Другие широко используемые функции содержат 
 * RANK(), FIRST_VALUE(), LAG() и т. д.
 * OVER означает, что вы указываете оконную функцию. Это предложение 
 * обязательно.
 * PARTITIONBY name. Здесь указывается, как вы хотите разделить данные на 
 * окна. Они могут быть разделены по одному или нескольким столбцам. 
 * Этот параметр необязателен. Если он исключен, то окно представляет собой 
 * всю таблицу ORDER BY month. В этом предложении указывается, как должно 
 * быть отсортировано каждое окно перед применением функции. 
 * В MySQL, PostgreSQL 
 * и SQLite это предложение необязательно, в отличие от Oracle и SQL Server.
 */



/*
 * Возврат первого значения 
 * в каждой группе
 * С помощью FIRST_VALUE и LAST_VALUE можно вернуть первую 
 * и последнюю строки окна соответственно.
 * В показанных ниже запросах этот двухэтапный процесс разбивается на две части, 
 * чтобы можно было получить наиболее 
 * популярные имена для каждого пола.
 * Этап 1. Отображение наиболее популярных имен для каждого пола.
 * SELECT gender, name, babies,
 * FIRST_VALUE(name) OVER (PARTITION BY gender
 * ORDER BY babies DESC) AS top_name
 * FROM baby_names;
 * +--------+--------+--------+----------+
| gender | name | babies | top_name |
+--------+--------+--------+----------+
| F | Olivia | 100 | Olivia |
| F | Emma | 92 | Olivia |
| F | Mia | 88 | Olivia |
| M | Noah | 110 | Noah |
| M | Liam | 105 | Noah |
| M | Mateo | 95 | Noah |
+--------+--------+--------+----------+
Используем полученный результат в качестве подзапроса 
для следующего шага, который выполняет фильтрацию 
по подзапросу.
* 
* Этап 2. Возврат только двух строк, содержащих наиболее
* популярные имена.
* SELECT * FROM
* (SELECT gender, name, babies,
* FIRST_VALUE(name) OVER (PARTITION BY gender
* ORDER BY babies DESC) AS top_name
* FROM baby_names) AS top_name_table
* WHERE name = top_name;
* 
* +--------+--------+--------+----------+
*| gender | name | babies | top_name |
*+--------+--------+--------+----------+
*| F | Olivia | 100 | Olivia |
*| M | Noah | 110 | Noah |
*+--------+--------+--------+----------+
*В Oracle необходимо исключить часть AS top_name_table.
* 
* */


/*
Этап 2. Отфильтруем строки, содержащие ранги 1 и 2.
SELECT * FROM
(SELECT gender, name, babies,
 ROW_NUMBER() OVER (PARTITION BY gender
 ORDER BY babies DESC) AS popularity
FROM baby_names) AS popularity_table
WHERE popularity IN (1,2);
+--------+--------+--------+------------+
| gender | name | babies | popularity |
+--------+--------+--------+------------+
| F | Olivia | 100 | 1 |
| F | Emma | 92 | 2 |
| M | Noah | 110 | 1 |
| M | Liam | 105 | 2 |
+--------+--------+--------+------------+
*/


/*
 * Для каждого человека найдем трехмесячное скользящее 
 * среднее значение продаж за два месяца, предшествующих 
 * текущему:
 * SELECT name, month, sales,
 * AVG(sales) OVER (PARTITION BY name
 * ORDER BY month
 * ROWS BETWEEN 2 PRECEDING AND
 * CURRENT ROW) three_month_ma
 * FROM sales;
 * 
 * В примере выше рассматриваются две строки, предшествующие текущей строке:
 * ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
 * Вы можете просмотреть и следующие строки, используя 
 * ключевое слово FOLLOWING:
 * ROWS BETWEEN 2 PRECEDING AND 3 FOLLOWING
 * Такие диапазоны иногда называют скользящими окнами
 */



/*
 * Вычисление промежуточного итога
 * Чтобы выполнить это действие, используем комбинацию 
 * функции SUM и предложения ROWS BETWEEN UNBOUNDED.
 * Для каждого сотрудника найдем промежуточную сумму продаж до текущего месяца:
 * SELECT name, month, sales,
 * SUM(sales) OVER (PARTITION BY name
 * ORDER BY month
 * ROWS BETWEEN UNBOUNDED PRECEDING AND
 * CURRENT ROW) running_total
 * FROM sales;
 * +-------+-------+-------+---------------+
| name | month | sales | running_total |
+-------+-------+-------+---------------+
| David | 1 | 2 | 2 |
| David | 2 | 11 | 13 |
| David | 3 | 6 | 19 |
| David | 4 | 8 | 27 |
| Laura | 1 | 3 | 3 |
| Laura | 2 | 14 | 17 |
| Laura | 3 | 7 | 24 |
| Laura | 4 | 1 | 25 |
| Laura | 5 | 20 | 45 |
+-------+-------+-------+---------------+
 * 
 * Здесь мы вычисляем промежуточную сумму для каждого 
 * человека. Чтобы вычислить такую сумму по всей таблице, 
 * можно удалить часть кода PARTITION BY name.
 */


/*
АЛЬТЕРНАТИВА PIVOT — CASE
В PostgreSQLиспользуется ручной способ выполнения операции 
PIVOT. Он заключается в применении оператора CASE, поскольку эти РСУБД 
не поддерживают PIVOT.
SELECT name,
 SUM(CASE WHEN fruit = 'strawberries'
 THEN 1 ELSE 0 END) AS strawberries,
 SUM(CASE WHEN fruit = 'grapefruit'
 THEN 1 ELSE 0 END) AS grapefruit,
 SUM(CASE WHEN fruit = 'watermelon'
 THEN 1 ELSE 0 END) AS watermelon
FROM fruits
GROUP BY name
ORDER BY name;



SELECT 
    product,
    SUM(revenue) FILTER (WHERE quarter = 'Q1') AS q1_revenue,
    SUM(revenue) FILTER (WHERE quarter = 'Q2') AS q2_revenue,
    SUM(revenue) FILTER (WHERE quarter = 'Q3') AS q3_revenue,
    SUM(revenue) FILTER (WHERE quarter = 'Q4') AS q4_revenue
FROM sales
GROUP BY product;

*/

/*Агрегатные функции применяются для значений, не равных NULL. 
Исключением является функция COUNT(*).*/

/*Отнимаем секунды
Select plane, avg(EXTRACT(EPOCH FROM (time_in - time_out))) as time */