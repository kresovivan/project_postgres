SELECT ename, sal, deptno,
  RANK() OVER (PARTITION BY deptno ORDER BY sal DESC) AS rank,
  lag(sal) OVER (PARTITION BY deptno ORDER BY sal DESC) AS dept_lag,
  lead(sal) OVER (PARTITION BY deptno) AS dept_lead,
  sum(sal) OVER (PARTITION BY deptno) AS dept_avg
FROM emp
ORDER BY deptno, sal;