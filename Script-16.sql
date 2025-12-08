WITH ranked AS (
    SELECT 
        deptno,
        empno,
        sal,
        DENSE_RANK() OVER (PARTITION BY deptno ORDER BY sal DESC) as rank
    FROM emp
)
SELECT * FROM ranked WHERE rank <= 3;

SELECT
    deptno,
	ename,
	LAG(sal) OVER (PARTITION BY deptno ORDER BY hiredate) AS prev_amount,
	sal,
	LEAD(sal) OVER (PARTITION BY deptno ORDER BY hiredate) AS next_amount
FROM
	emp;


SELECT 
    COALESCE(deptno::text, 'Все отделы')     AS отдел,
    COALESCE(job::text, 'Все должности')     AS должность,
    SUM(sal)                                 AS сумма_зарплат,
    CASE 
        WHEN deptno IS NULL AND job IS NULL THEN 'ИТОГО по компании'
        WHEN deptno IS NULL THEN 'ИТОГО по должности'
        WHEN job IS NULL THEN 'ИТОГО по отделу' 
        ELSE 'Детализация'
    END                                      AS уровень_агрегации
FROM emp
GROUP BY GROUPING SETS (
    (deptno, job),  -- Детальная информация по отделу и должности
    (deptno),       -- Итоги по отделам
    (job),          -- Итоги по должностям  
    ()              -- Общий итог
)
ORDER BY 
    deptno NULLS LAST,
    job NULLS LAST;








WITH grouped_data AS (
    SELECT 
        deptno,
        job,
        SUM(sal) AS total_salary,
        -- Флаг для определения уровня агрегации
        GROUPING(deptno) AS dept_grouped,
        GROUPING(job) AS job_grouped
    FROM emp
    GROUP BY GROUPING SETS (
        (deptno, job),  -- Детализация: отдел + должность
        (deptno),       -- Итоги по отделам
        (job),          -- Итоги по должностям
        ()              -- Общий итог по компании
    )
)
SELECT 
    -- Красивое отображение отделов
    CASE 
        WHEN dept_grouped = 1 THEN '▓ ВСЕ ОТДЕЛЫ'
        ELSE 'Отдел ' || deptno::text
    END AS отдел,
    
    -- Красивое отображение должностей
    CASE 
        WHEN job_grouped = 1 THEN '▓ ВСЕ ДОЛЖНОСТИ'
        ELSE job
    END AS должность,
    
    -- Сумма зарплат с форматированием
    TO_CHAR(total_salary, '999,999,999') AS сумма_зарплат,
    
    -- Процент от общего итога
    CASE 
        WHEN dept_grouped = 1 AND job_grouped = 1 THEN '100.0%'
        ELSE TO_CHAR(
            (total_salary * 100.0 / NULLIF(SUM(total_salary) FILTER (WHERE dept_grouped = 1 AND job_grouped = 1) OVER (), 0)), 
            '999.9%'
        )
    END AS процент_от_общего,
    
    -- Уровень детализации с иконками
    CASE 
        WHEN dept_grouped = 0 AND job_grouped = 0 THEN '📊 Детализация'
        WHEN dept_grouped = 0 AND job_grouped = 1 THEN '🏢 ИТОГО по отделу'
        WHEN dept_grouped = 1 AND job_grouped = 0 THEN '👨‍💼 ИТОГО по должности'
        WHEN dept_grouped = 1 AND job_grouped = 1 THEN '🏛️  ОБЩИЙ ИТОГ'
    END AS уровень_агрегации

FROM grouped_data
ORDER BY 
    dept_grouped,           -- Сначала детализация, потом итоги
    deptno NULLS FIRST,     -- В рамках отделов - по номеру
    job_grouped,            -- В рамках отдела: детализация, потом итог
    job NULLS FIRST;



SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sal) 
FROM emp;


SELECT  sum(sal) OVER(), count(sal) OVER()
FROM emp;


SELECT 
    e.empno,
    e.ename,
    nums.*
FROM emp e
CROSS JOIN LATERAL generate_series(1, 3) AS nums(n);


SELECT 
    d.deptno,
    d.dname,
    top_emps.ename,
    top_emps.sal
FROM dept d
LEFT JOIN LATERAL (
    SELECT e.ename, e.sal
    FROM emp e
    WHERE e.deptno = d.deptno
    ORDER BY e.sal DESC
) AS top_emps ON true;


SELECT d.dname, top_emps.*
FROM dept d
INNER JOIN (
    SELECT e.ename, e.sal, e.deptno
    FROM emp e
    WHERE e.deptno = d.deptno  -- НЕВОЗМОЖНО!
    ORDER BY e.sal DESC
    LIMIT 2
) AS top_emps ON d.deptno = top_emps.deptno;


EXPLAIN ANALYZE
SELECT d.dname, top_emps.*
FROM dept d
INNER JOIN LATERAL (
    SELECT e.ename, e.sal
    FROM emp e
    WHERE e.deptno = d.deptno  -- МОЖЕТ использовать d.deptno!
    ORDER BY e.sal DESC
) AS top_emps ON TRUE;



sql
SELECT *
FROM (
  SELECT department, job_title, salary
  FROM Employees
) AS src
PIVOT (
  AVG(salary)
  FOR job_title IN ('Manager', 'Engineer', 'Analyst')
) AS pvt;

CREATE EXTENSION IF NOT EXISTS tablefunc

SELECT *
FROM crosstab(
    'SELECT deptno, job, AVG(sal)::numeric(10,2)
     FROM emp 
     WHERE job IN (''SALESMAN'', ''MANAGER'', ''CLERK'')
     GROUP BY deptno, job
     ORDER BY 1, 2',
    'VALUES (''SALESMAN''), (''MANAGER''), (''CLERK'')'
) AS final_result (
    deptno int,
    "SALESMAN" numeric,
    "MANAGER" numeric, 
    "CLERK" numeric
);



SELECT 
    deptno,
    AVG(sal) FILTER (WHERE job = 'SALESMAN')  AS "SALESMAN",
    AVG(sal) FILTER (WHERE job = 'MANAGER')   AS "MANAGER",
    AVG(sal) FILTER (WHERE job = 'CLERK')     AS "CLERK"
FROM emp
GROUP BY deptno

UNION ALL

SELECT 
    deptno,
    AVG(CASE WHEN job = 'SALESMAN'  THEN sal END) AS "SALESMAN",
    AVG(CASE WHEN job = 'MANAGER' THEN sal END) AS "MANAGER",
    AVG(CASE WHEN job = 'CLERK'  THEN sal END) AS "CLERK"
FROM emp
GROUP BY deptno
ORDER BY deptno;


SELECT ename, sal, deptno
FROM Emp e
WHERE sal > (
  SELECT AVG(a.sal) 
  FROM Emp a
  WHERE a.deptno = e.deptno
)
ORDER BY deptno;


SELECT ename, sal, deptno
FROM (
    SELECT 
        ename,
        sal,
        deptno,
        AVG(sal) OVER (PARTITION BY deptno) as avg_dept_sal
    FROM Emp
) e
WHERE sal > avg_dept_sal
ORDER BY deptno;


SELECT deptno, AVG(sal) OVER(PARTITION BY deptno ORDER BY deptno)
 FROM emp
 
 
SELECT 
hiredate, 
sal,
SUM(sal) OVER (ORDER BY hiredate) AS cumulative_sum
FROM emp;



WITH RankedOrders AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY deptno
      ORDER BY hiredate DESC
    ) AS rn
  FROM emp
)

SELECT * 
FROM RankedOrders WHERE rn <= 5




SELECT e1.deptno,e2.deptno, e1.ename, e2.ename, e1.sal
FROM emp e1
JOIN emp e2 
ON e1.sal = e2.sal
AND e1.empno < e2.empno;


EXTRACT(QUARTER FROM hiredate) AS quarter,
SUM(sal) AS total_sales
FROM emp
GROUP BY EXTRACT(QUARTER FROM hiredate);



SELECT 
    EXTRACT(QUARTER FROM CAST(hiredate AS DATE)) AS quarter,
    SUM(sal) AS total_sales
FROM emp
GROUP BY EXTRACT(QUARTER FROM CAST(hiredate AS DATE))
ORDER BY quarter;


SELECT mgr AS manager_id, COUNT(*) AS employees_count
FROM emp
WHERE mgr IS NOT NULL
GROUP BY mgr
ORDER BY employees_count DESC
LIMIT 1;




Найти интервалы > 1 часа между событиями
sql

SELECT 
    L1.hiredate AS start_time,
    MIN(L2.hiredate) AS end_time
FROM emp L1
JOIN emp L2 ON L1.hiredate < L2.hiredate
    AND L2.hiredate - L1.hiredate > 3600  -- Разница > 1 часа в секундах
GROUP BY L1.hiredate;


SELECT UNNEST(STRING_TO_ARRAY('A,B,C', ',')) AS value;

WITH RECURSIVE Hierarchy AS (
  SELECT id, manager_id, name, 1 AS depth
  FROM Employees
  WHERE manager_id IS NULL
  
  UNION ALL
  
  SELECT e.id, e.manager_id, e.name, h.depth + 1
  FROM Employees e
  JOIN Hierarchy h ON e.manager_id = h.id
)
SELECT * 
FROM Hierarchy

