SELECT * 
FROM sales ORDER BY product, quarter;


SELECT * FROM crosstab(
    'SELECT product, quarter, revenue 
     FROM sales 
     ORDER BY 1,2',
    'VALUES (''Q1''), (''Q2''), (''Q3''), (''Q4'')'
) AS ct(product text, q1_revenue int, q2_revenue int, q3_revenue int, q4_revenue int);




SELECT * FROM crosstab(
    '-- Основные данные
     SELECT product, quarter, revenue 
     FROM sales 
     
     UNION ALL
     
     -- Итоги по продуктам
     SELECT product, ''Total'', SUM(revenue)
     FROM sales 
     GROUP BY product
     
     UNION ALL
     
     -- Общий итог
     SELECT ''Total'', ''Total'', SUM(revenue)
     FROM sales
     
     ORDER BY 1,2',
    
    'VALUES (''Q1''), (''Q2''), (''Q3''), (''Q4''), (''Total'')'
) AS ct(product text, q1 int, q2 int, q3 int, q4 int, total int);





SELECT * FROM crosstab(
    '-- Основные данные по кварталам
     SELECT product, quarter, revenue 
     FROM sales 
     
     UNION ALL
     
     -- Итоги по продуктам (строка "Total" для каждого продукта)
     SELECT product, ''Total'', SUM(revenue)
     FROM sales 
     GROUP BY product
     
     UNION ALL
     
     -- ПОДИТОГИ ПО КАЖДОМУ КВАРТАЛУ (продукт "Total" для каждого квартала)
     SELECT ''Total'', quarter, SUM(revenue)
     FROM sales
     GROUP BY quarter
     
     UNION ALL
     
     -- Общий итог
     SELECT ''Total'', ''Total'', SUM(revenue)
     FROM sales
     
     ORDER BY 1,2',
    
    'VALUES (''Q1''), (''Q2''), (''Q3''), (''Q4''), (''Total'')'
) AS ct(product text, q1 int, q2 int, q3 int, q4 int, total int);