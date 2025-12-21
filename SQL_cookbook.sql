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
   OR sal <= 2000 AND deptno = 20;


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

--SELECT sal as salary, comm as comission
--from emp
--where salary < 5000;

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
  есть буква I или чье название должности заканчивается на ER
  символ подчеркнивания _ возвращает любой отдельный символ*/

SELECT ename, job
FROM emp
WHERE deptno IN (10, 20)
and (ename LIKE '%I%' or job like '%ER');

/*Сортировка результатов запросов
  возвращение результатов запроса в заданном порядке*/

SELECT ename, job, sal
FROM emp
WHERE deptno = 10
ORDER BY sal; -- по возрастанию

SELECT ename, job, sal
FROM emp
WHERE deptno = 10
ORDER BY sal DESC; -- по убыванию

---также можно указать номер столбца сортировки
SELECT ename, job, sal
FROM emp
WHERE deptno = 10
ORDER BY 3 DESC; -- по убыванию

/*Сортировка по нескольким столбцам
  требуется отсортировать строки результирующего набора по столбцу deptno по возрастанию,
  а затем по столбцу зарплат sal по убыванию
  Сортировка осуществляется слева направо*/

SELECT ename, job, deptno, sal
FROM emp
ORDER BY deptno, sal DESC;

/*сортировка по подстрокам.
  Требуется отсортировать результаты запросы по определенным частям строки
  Например извлечь из таблицы emp столбцы имен ename и должностей job и упорядочить
  их по последним двум символам столбца должностей job
  Наглядная таблица:
job	    length(job)	length-1	Символы (позиции)	            Результат
MANAGER	    7	      6	       M(1)A(2)N(3)A(4)G(5)E(6)R(7)	        ER
CLERK	    5	      4	       C(1)L(2)E(3)R(4)K(5)          	    RK
SALESMAN	8	      7	       S(1)A(2)L(3)E(4)S(5)M(6)A(7)N(8)	    AN
ANALYST	    7	      6	       A(1)N(2)A(3)L(4)Y(5)S(6)T(7)	        ST
PRESIDENT	9	      8	       P(1)R(2)E(3)S(4)I(5)D(6)E(7)N(8)T(9)	NT
*/

EXPLAIN ANALYZE
SELECT ename, job, SUBSTR(job, LENGTH(job) - 1) AS las_two_symbols
FROM emp
ORDER BY SUBSTR(job, LENGTH(job) - 1);

EXPLAIN ANALYZE
SELECT ename, job, right(job,2) AS las_two_symbols
FROM emp
ORDER BY right(job,2);

/*Сортировка смешанных буквенно-цифровых данных
требуется упорядочить буквенно-цифровые данные таблицы либо по цифровым либо по
по буквенным данным  */
create view V as
select ename||' '||deptno as data
from emp;

select *
from v;

/*Нужно упорядочить эти столбцы по deptno либо по столбцу ename*/

/*Сортировка by deptno
Что происходит:
translate(data, '0123456789','##########') - заменяет все цифры на #
replace(...,'#','') - удаляет все #, оставляя только текст.
Внешний replace(data, ..., '') - удаляет этот текст из исходной строки,
оставляя только цифры.
Упрощенный эквивалент: regexp_replace(data, '[^0-9]', '', 'g')
*/
SELECT data,
       REPLACE(data, REPLACE(
               TRANSLATE(data, '0123456789', '##########'), '#', ''), ''
       ) AS replace_data
FROM v
ORDER BY REPLACE(data, REPLACE(
        TRANSLATE(data, '0123456789', '##########'), '#', ''), ''
         );

SELECT data, CAST(
        substring(data from '[0-9]+') AS INTEGER
             )
FROM v
ORDER BY CAST(
                 substring(data from '[0-9]+') AS INTEGER
         );

/*Сортировка по ename*/
SELECT data, REPLACE(TRANSLATE(data, '0123456789', '##########'), '#', '') AS replace_num
FROM v
ORDER BY REPLACE(TRANSLATE(data, '0123456789', '##########'), '#', '');


SELECT data, substring(data from '^[A-Za-z]+')
FROM v
ORDER BY substring(data from '^[A-Za-z]+');

/*Обработка значения null при сортировке
  значения null можно пометить специальным флагом с помощью выражения case.
  При этом такой флаг должен иметь два значения: одно из которых (0) обозначает
  значение null, а другое (1) - значение не null

  Значения не null столбца comm сортируются по возрастанию, все значения null
  размещаются в конце списка
  */

select ename, sal, comm
from (
    select ename, sal, comm, case when comm is null then 0 else 1 end as is_null
    from emp) x
order by is_null desc, comm;

/*Значения не null столбца comm сортируются по убыванию, все значения null размещаются в
  конце списка*/
select ename, sal, comm
from (
         select ename, sal, comm, case when comm is null then 0 else 1 end as is_null
         from emp) x
order by is_null desc, comm desc;

/*Значения не NULL cтолбца comm сортируются по возрастанию, все значения null распологаются
  вначале списка*/


select ename, sal, comm
from (
         select ename, sal, comm, case when comm is null then 0 else 1 end as is_null
         from emp) x
order by is_null, comm;

/*Значения не null столбца comm сортируются по возрастанию, все значения null размещаются
  в конце списка
*/

SELECT ename, sal, comm
FROM emp
ORDER BY comm NULLS LAST;


/*Значения не null столбца comm сортируются по возрастанию, все значения null размещаются
  в начале списка
*/
SELECT ename, sal, comm
FROM emp
ORDER BY comm NULLS FIRST;



