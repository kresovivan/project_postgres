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

/*Сортировка по ключу, зависящему от данных
  Требуется отсортировать данные с применением некоего логического условия. Например,
  если значение job равно salesman, сортировка выполняется по столбцу comm в противном
  случае по столбцу - sal

  Критерий          CASE                                 Подзапрос
───────────────── ──────────────────────────────────── ───────────────────────────────────────────
Основная задача   Условная логика внутри строки        Получить данные из другого набора
Аналогия          Оператор IF в программировании       Вызов функции / обращение к переменной
Зависимость       Данные текущей строки запроса        Результат целого другого запроса
Типичное место    SELECT, WHERE, ORDER BY, UPDATE SET  WHERE (с IN, >, EXISTS), SELECT, FROM
*/

SELECT ename, job, sal, comm
FROM emp
ORDER BY CASE WHEN job = 'SALESMAN' THEN comm ELSE sal END;

/*Для динамического способа управления сортировкой можно использовать выражение CASE


| ename | sal | job | comm | ordered |
| :--- | :--- | :--- | :--- | :--- |
| TURNER | 1500.00 | SALESMAN | 0.00 | 0.00 |
| ALLEN | 1600.00 | SALESMAN | 300.00 | 300.00 |
| WARD | 1250.00 | SALESMAN | 500.00 | 500.00 |
| SMITH | 800.00 | CLERK | null | 800.00 |
| JAMES | 950.00 | CLERK | null | 950.00 |
| ADAMS | 1100.00 | CLERK | null | 1100.00 |
| MILLER | 1300.00 | CLERK | null | 1300.00 |
| MARTIN | 1250.00 | SALESMAN | 1400.00 | 1400.00 |
| CLARK | 2450.00 | MANAGER | null | 2450.00 |
| BLAKE | 2850.00 | MANAGER | null | 2850.00 |
| JONES | 2975.00 | MANAGER | null | 2975.00 |
| SCOTT | 3000.00 | ANALYST | null | 3000.00 |
| FORD | 3000.00 | ANALYST   | null | 3000.00 |
| KING | 5000.00 | PRESIDENT | null | 5000.00 |

*/

select ename, sal,job, comm, case when job = 'SALESMAN' then comm else sal end as ordered
from emp
order by ordered

/*Работа с несколькими таблицами
  Размещение одного набора строк над другим
  Наличие общего ключа для таблиц не является обязательным, но их столбцы должны иметь
  одинаковые типы данных. Например, необходимо отобразить номера и имена отдела служащих отдела 10
  из таблицы emp и названия и номера отделов из таблицы dept.
*/

SELECT ename AS ename_and_dname, deptno
FROM emp
WHERE deptno = 10
UNION ALL

SELECT '_________', NULL
FROM t1

UNION ALL
SELECT dname, deptno
FROM dept;

/*Количество и тип данных элементов в списках операторов select должны быть одинаковыми.
  Например, следующий запрос возвратит ошибку:
[2025-12-21 20:06:16] [42804] ERROR: UNION types numeric and character varying cannot be matched
[2025-12-21 20:06:16] Позиция: 43
*/

EXPLAIN ANALYZE
select deptno
from dept
union all
select  ename
from emp;

/*В union all попадут все дубликаты строк, если необходимо
  исключить дубликаты строк необходимо использовать union
  будет выполнена операция distinct, устраняющая дубликаты*/

SELECT deptno
from emp
UNION
select deptno
from dept;

/*Проблемы:
Полная сортировка данных - O(N log N) сложность
Большой расход памяти/диска для временных данных
Блокирующая операция - нужно обработать все данные прежде чем вернуть первую строку
DISTINCT и UNION без ALL дорогие операции - O(N log N) или O(N) с большим коэффициентом

Влияние растет нелинейно - на 100К строк могут работать мгновенно, на 10М - минуты
Основные затраты:
Сортировка больших объемов данных
Временное хранение промежуточных результатов
Множественные проходы по данным
*/

EXPLAIN ANALYZE
select distinct deptno
from (
select deptno
from dept
union all
select  deptno
from emp);

EXPLAIN ANALYZE
select deptno
from dept
union
select  deptno
from emp;

/*Объединение взаимосвязанных строк
  Операция внутреннего объединения*/

SELECT e.ename, d.loc,d.deptno,e.deptno
FROM emp e,
     dept d
WHERE e.deptno = d.deptno
  AND d.deptno = 10;

/*Декартово произведение - все возможные комбинации строк таблиц, указанных в операции
  from*/
select e.ename, d.loc
from emp e, dept d
where e.deptno = 10;

/*Альтернативное решение операции внутреннего объединения
  заключается в явном использовании оператора join

Принципиальная разница (для разных типов JOIN):
Для INNER JOIN - результат одинаковый.
Для INNER JOIN нет разницы где размещать дополнительные условия соединения.
-- Вариант 1: условие в ON
SELECT *
FROM emp e
INNER JOIN dept d ON e.deptno = d.deptno AND e.deptno = 10;

-- Вариант 2: условие в WHERE
SELECT *
FROM emp e
INNER JOIN dept d ON e.deptno = d.deptno
WHERE e.deptno = 10;

Для LEFT/RIGHT OUTER JOIN - результат РАЗНЫЙ:
-- ВАРИАНТ A: условие в ON
SELECT e.ename, d.loc, d.deptno
FROM emp e
LEFT JOIN dept d ON e.deptno = d.deptno AND e.deptno = 10;

-- Результат: ВСЕ сотрудники из emp
-- Для сотрудников не из 10-го отдела: loc = NULL, deptno = NULL
-- Для сотрудников из 10-го отдела: нормальная информация об отделе

-- ВАРИАНТ B: условие в WHERE
SELECT e.ename, d.loc, d.deptno
FROM emp e
LEFT JOIN dept d ON e.deptno = d.deptno
WHERE e.deptno = 10;  -- ИЛИ d.deptno = 10

-- Результат: ТОЛЬКО сотрудники из 10-го отдела
-- WHERE преобразует LEFT JOIN в INNER JOIN!


                                    Правило для запоминания:
Размещение условия	Для LEFT JOIN	                           Для INNER JOIN
В ON	Фильтрует правую таблицу	                           То же самое, что WHERE
В WHERE	Фильтрует конечный результат (превращает в INNER)	   Фильтрует конечный результат

Для LEFT JOIN:
ON = "при каких условиях ПРИСОЕДИНЯТЬ правую таблицу"
WHERE = "какие строки ПОКАЗАТЬ в результате"
Вот почему ваш второй запрос (WHERE e.deptno = 10) фактически превращает LEFT JOIN в INNER JOIN
для сотрудников не из 10-го отдела.
*/

select e.ename, d.loc, d.deptno
from emp e
inner join dept d on e.deptno = d.deptno
where e.deptno = 10;

/*Поиск общих строк с общими данными в двух таблицах
  требуется найти и объединить строки с одинаковыми данными в двух таблицах
  Объединение необходимо выполнять по нескольким столбцам*/

create view C AS
select ename,job,sal
from emp
where job = 'CLERK';

select *
from c;

explain ANALYZE
select e.empno, e.ename, e.job, e.sal, e.deptno, e.hiredate
from emp e, c
where e.ename = c.ename
and e.job = c.job
and e.sal = c.sal;

EXPLAIN ANALYZE
SELECT e.empno, e.ename, e.job, e.sal, e.deptno, e.hiredate
FROM emp e
         INNER JOIN c ON e.ename = c.ename
    AND e.job = c.job
    AND e.sal = c.sal;

explain ANALYZE
SELECT e.empno, e.ename, e.job, e.sal, e.deptno, e.hiredate
FROM emp e
WHERE (ename, job, sal) IN (SELECT g.ename, g.job, g.sal
                            FROM emp g
                            INTERSECT
                            SELECT ename, job, sal
                            FROM c);

/*Извлечение из одной таблицы значений, отсутствующих в другой
требуется в исходной таблице найти значения, которых нет в другой таблице (таблица назначения).
Оператору except передается первое результирующее множество из которого он удаляет все строи,
присутствующие во втором результирующем множестве.
Он не возвращает дубликатов в отличие от not in*/


EXPLAIN ANALYZE
select deptno
from dept
EXCEPT
SELECT deptno
from emp;


EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE deptno NOT IN (SELECT deptno FROM emp);

/*При использовании оператора not in не нужно упускать из виду значения null*/

create table new_dept(deptno integer);
insert into new_dept VALUES(10);
insert into new_dept VALUES(50);
insert into new_dept VALUES(null);

/*Почему такой запрос не выдал ни одной строки.
  Операторы in и not in являются по сути операторами OR (ИЛИ) и вследствие особенностей
  обработки значений null логическими операциями or возвращают разные результаты*/
EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE deptno NOT IN (SELECT deptno FROM new_dept);

EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE deptno IN (SELECT deptno FROM new_dept);

EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE  (deptno = 10 or deptno = 50 or deptno = null);

EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE deptno in (10, 50, null);

EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE deptno not in (10, 50, null);

EXPLAIN ANALYZE
SELECT deptno
FROM dept
WHERE not (deptno = 10 or deptno = 50 or deptno = null);

/*В выражении SQL:
  - true  или null равно true,
  - false или null равно null !!!
  Этой проблемы с not in и значениями null можно избежать, используя связанный подзапрос в
  сочетании с предикатом not exists подзапрос называется связанным по той причине, что он
  обращается к строкам из внешнего запроса.*/



