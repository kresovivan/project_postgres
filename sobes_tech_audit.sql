
/*
Задание 1
Написать SQL-запрос,
который вернет в группировке по месяцам
для каждой категории товаров
ТОП-5 товаров по объему продаж.
Вывести месяц, категорию товара, товар и объем продаж.
Таблица: test_sales_dataset

Поля таблицы:
dttm — дата и время продажи
category — категория товара
name — наименование товара
summ — сумма продажи
*/


WITH monthly_base AS (
    SELECT
        DATE_TRUNC('month', dttm) AS month_trunc,
        category,
        name,
        SUM(summ) AS total_sales
    FROM test_sales_dataset
    GROUP BY DATE_TRUNC('month', dttm), category, name
),
     monthly_sales AS (
         SELECT
             month_trunc,
             category,
             name,
             total_sales,
             ROW_NUMBER() OVER (
                 PARTITION BY month_trunc, category
                 ORDER BY total_sales DESC
                 ) AS rn
         FROM monthly_base
     )
SELECT
    to_char(month_trunc, 'YYYY-MM') AS dttm,
    category,
    name,
    total_sales
FROM monthly_sales
WHERE rn <= 5
ORDER BY month_trunc, category, rn;




/*
Задание 2
Вывести:
Наименование и объем продаж в рублях
для всех товаров,
которые продавались каждый день недели с
понедельника, 1.04.2024, до воскресенья, 7.04.2024, включительно.

Ключевые условия:
Каждый день = все 7 дней подряд
Если товар не продавался хотя бы один день из этого периода — он не попадает в результат
*/

WITH daily_sales AS (
SELECT
t.name,
o.date_check,
SUM(o.quantity * t.price) AS daily_revenue

FROM test_orders_dataset o
JOIN test_tovari_dataset t ON o.tov_id = t.tov_id
WHERE o.date_check BETWEEN '2024-04-01' AND '2024-04-07'
GROUP BY t.name, o.date_check
)


SELECT
    name AS "Наименование товара",
    SUM(daily_revenue) AS "Объем продаж за неделю (руб)"
FROM daily_sales
GROUP BY name
HAVING COUNT(DISTINCT date_check) = 7
ORDER BY SUM(daily_revenue) DESC;


/*
Задание №3
Для каждой категории нарастающим итогом рассчитать количество проданного товара в штуках
в разрезе месяцев.
Под количеством понимается количество единиц, а не количество артикулов.

*/


WITH monthly_category_sales AS (
/*1. Группируем продажи по месяцам и категориям*/
SELECT
DATE_TRUNC('month', o.date_check) AS month,
 c.cat_name AS category,
 SUM(o.quantity) AS monthly_quantity
FROM test_orders_dataset o
JOIN test_tovari_dataset t ON o.tov_id = t.tov_id
JOIN test_categories_dataset c ON t.cat_id = c.cat_id
GROUP BY DATE_TRUNC('month', o.date_check), c.cat_name
)

/*2.Рассчитываем нарастающую сумма продаж по месяцам для каждой категории.*/
SELECT
    to_char(month, 'YYYY-MM'),
    category,
    monthly_quantity,
    SUM(monthly_quantity) OVER (PARTITION BY category ORDER BY month) AS сum_totaal_sum
FROM monthly_category_sales
ORDER BY category, month;


/*
Определить:
средний чек и валовую маржу в течение 2022 г.
во всех покупательских сегментах
в разрезе online/offline.

Если какой-нибудь сегмент будет не определен (значение null),
то представить его в виде “Новый участник”.
Валовая маржа - это разница между ценой товара и его себестоимостью
*/

WITH order_details AS (
    SELECT
        o.check_id,
        CASE WHEN o.ord_id IS NOT NULL THEN 'online' ELSE 'offline' END AS order_type,
        CASE
            WHEN c.segment = 1 THEN 'Часто покупают'
            WHEN c.segment = 2 THEN 'Покупают иногда'
            ELSE 'Новый участник'
            END AS customer_segment,
        SUM(o.quantity * t.price) AS check_amount,
        SUM(o.quantity * (t.price - t.sebest)) AS check_margin
FROM test_orders_dataset o
LEFT JOIN test_customers_dataset c ON o.cust_id = c.cust_id
JOIN test_tovari_dataset t ON o.tov_id = t.tov_id
WHERE EXTRACT(YEAR FROM o.date_check) = 2022
GROUP BY o.check_id, order_type, customer_segment
)
SELECT
    order_type,
    customer_segment,
    COUNT(*) AS count_check,
    ROUND(AVG(check_amount), 2) AS "avg_check_rub",
    ROUND(SUM(check_margin), 2) AS "gross_margin_rub",
    ROUND(AVG(check_margin), 2) AS "avg_margin_per_check",
    ROUND(SUM(check_margin) / NULLIF(SUM(check_amount), 0) * 100, 2) AS "profitability_percent"

FROM order_details
GROUP BY order_type, customer_segment
ORDER BY order_type,
         CASE customer_segment
             WHEN 'Часто покупают' THEN 1
             WHEN 'Покупают иногда' THEN 2
             ELSE 3
             END;
