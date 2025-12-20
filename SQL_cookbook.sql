/*Проверка тестовых таблиц*/

SELECT *
FROM dept;

SELECT *
FROM emp;

SELECT *
FROM t1;

SELECT *
FROM t10;

SELECT *
FROM t100;

SELECT *
FROM t500;

/*Извлечение из таблицы всех строк и столбцов
Предикат WHERE — это условие фильтрации строк в SQL-запросах, которое определяет,
какие строки должны быть включены в результирующий набор. Это одно из самых важных
и фундаментальных понятий в SQL.
Предикат — это выражение, которое:
Работает с данными (обычно со значениями столбцов)
Возвращает одно из трёх логических значений:
TRUE (истина)
FALSE (ложь)
UNKNOWN (неизвестно, для NULL значений)
Является ядром условия WHERE (а также HAVING, ON, CHECK)

Символ "*" имеет специальное значение - задает возвращение каждого столбца указанной таблицы,
поскольку в приведенном примере не используется предикат where, будут возращены все строки таблицы*/

SELECT *
FROM emp;


/*Указываем все столбцы*/
SELECT empno, job, hiredate, sal, comm
FROM emp;


/*Извлечение из таблицы подмножества строк,
  посмотреть те строки, которые отвечают определенному условию*/

SELECT *
FROM emp
WHERE deptno = 10;

/*Возвращение строк оп нескольким условиям
Приоритет операторов в SQL:
AND — высший приоритет (выполняется первым)
OR — низший приоритет (выполняется последним)
NOT — обычно между ними
Интерпретируется как:
WHERE (deptno = 10)
OR (comm is not null)
OR (sal <= 2000 AND deptno = 20)
  */

SELECT *
FROM emp
WHERE deptno = 10
   OR comm IS NOT NULL
   OR sal <= 2000 AND deptno = 20


/*(deptno = 10 OR comm IS NOT NULL OR sal <= 2000)
Это выражение вернет TRUE, если выполняется ЛЮБОЕ из трех условий внутри скобок.
Затем результат из шага 1 объединяется через AND с deptno = 20:
(результат_из_скобок) AND (deptno = 20)
Ключевой момент:
Даже если условие в скобках вернет TRUE, строка будет выбрана ТОЛЬКО если deptno = 20 тоже TRUE.
Только сотрудники, которые:
Работают в отделе 20 (deptno = 20)
И при этом удовлетворяют хотя бы одному из условий:
ИЛИ работают в отделе 10 (но это невозможно при deptno=20)
ИЛИ имеют комиссионные (не NULL)
ИЛИ имеют зарплату ≤ 2000
*/
SELECT *
FROM emp
WHERE (deptno = 10 OR comm IS NOT NULL OR sal <= 2000)
  AND deptno = 20;

/*Извлечение из таблицы подмножества столбцов
  это важно, если мы хотим избежать пустой траты времени и ресурсов, которые будут тратиться
  на извлечение лишних данных*/

SELECT ename, deptno, sal
FROM emp;

/*Задание столбцам значимых имен - псевдонимов,
  качественные псевдонимы улучшают понимание запроса и его результатов пользователями*/

SELECT sal AS salary, comm AS comission
FROM emp;

/*Обращение по столбцу where по его псевдониму
  Из результирующего множества, столбцам которого присвоены псевдонимы, требуется исключить
  некоторые строки с помощью предиката where
[2025-12-21 01:23:58] [42703] ERROR: column "salary" does not exist
[2025-12-21 01:23:58] Подсказка: Perhaps you meant to reference the column "emp.sal".
[2025-12-21 01:23:58] Позиция: 60
*/

SELECT sal as salary, comm as comission
from emp
where salary < 5000;

/*Эту ошибку можно устранить с помощью вложенного запроса
  приведенное рещение необходимо в тех случаях, когда в
  предикате where нужно обращаться к любому из следующих
  элементов:
  -агрегатные функции,
  -скалярные подзапросы,
  -оконные функции,
  -псевдонимы*/

/*Seq Scan on emp  (cost=0.00..13.30 rows=183 width=28) (actual time=0.016..0.020 rows=13 loops=1)
  Filter: (sal < '5000'::numeric)
  Rows Removed by Filter: 1
Planning Time: 0.076 ms
Execution Time: 0.035 ms
*/
EXPLAIN ANALYZE
select *
from (SELECT sal as salary, comm as comission
      from emp) x
where salary < 5000;


/*Seq Scan on emp  (cost=0.00..13.30 rows=183 width=28) (actual time=0.013..0.015 rows=13 loops=1)
  Filter: (sal < '5000'::numeric)
  Rows Removed by Filter: 1
Planning Time: 0.055 ms
Execution Time: 0.027 ms
*/
EXPLAIN ANALYZE
SELECT sal as salary, comm as comission
from emp
where sal < 5000;

/*Конкатенация значений столбцов*/

select ename || ' works a ' || job as msg
from emp
WHERE deptno = 10;

select concat(ename,' works a ', job) as msg
from emp
WHERE deptno = 10;

/*Использование условной логики в операторе Select
  при отсутствии оператора else выражение case возвращает
  занчение null для любой строки, не удовлетворяющей проверяемому условию*/

SELECT ename,
       sal,
       CASE
           WHEN sal <= 2000 THEN 'UNDERPAID'
           WHEN sal >= 4000 THEN 'OVERPAID'
           ELSE 'OK'
           END AS status
FROM emp;

/*Ограничение числа возвращаемых строк*/

SELECT *
FROM emp FETCH FIRST 5 ROWS ONLY;

SELECT *
FROM emp limit 5;

/*Извлечение произвольных записей
  количество строк ограничивается поле исполнения функции в операторе order by*/
SELECT ename, job
from emp
order by random() limit 5;

/*Поиск значений null
сущность null не бывает равной или не равной како-либо другой сущности, даже
самой себе*/

SELECT *
FROM emp
WHERE comm IS NULL;

/*преобразования значений null в реальные значения
 в качестве аргументов функции coalesce передается одно или несколько значений,
функция возвращает первое не null значение в этом списке*/

EXPLAIN ANALYZE
select coalesce(comm,0)
    from emp;

EXPLAIN ANALYZE
SELECT CASE
           WHEN comm IS NOT NULL THEN comm
           ELSE 0
           END
FROM emp;

/*Поиск по шаблону.
  Требуется извлечь из таблицы строки, соответствующие заданной подстроке
  или шаблону*/

SELECT ename, job
FROM emp
WHERE deptno IN (10, 20);

/*Из этого результирующего множества нужно извлечь только тех служащих, в именах которых
  есть буква I или чье название должности заканчивается на ER*/

SELECT ename, job
FROM emp
WHERE deptno IN (10, 20)
and (ename LIKE '%I%' or job like '%ER');
