WITH ranked AS (
    SELECT 
        department,
        employee,
        salary,
        DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) as rank
    FROM employees
)
SELECT * FROM ranked WHERE rank <= 3;