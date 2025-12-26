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
order by ordered;

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
  сочетании с предикатом not exists подзапрос называется - коррелированным подзапросом по той причине, что он
  обращается к строкам из внешнего запроса.

 Внешний запрос берет первую строку из dept (например, deptno=10)

Подзапрос проверяет: "Есть ли в emp сотрудники с deptno=10?"
Если ДА → EXISTS вернет TRUE → NOT EXISTS = FALSE → строка НЕ включается в результат
Если НЕТ → EXISTS вернет FALSE → NOT EXISTS = TRUE → строка включается в результат
Переход к следующей строке dept
  */

EXPLAIN ANALYZE
SELECT d.deptno
FROM dept d
WHERE NOT EXISTS(SELECT 1 FROM emp e WHERE d.deptno = e.deptno); ---корелированный подзапрос

EXPLAIN ANALYZE
SELECT d.deptno
FROM dept d
WHERE NOT EXISTS(SELECT 1 FROM new_dept e WHERE d.deptno = e.deptno);

/*Извлечение строк таблицы, не соответствующих строкам в другой таблице
это решение выполняет операцию внешнего объединения, из результатов
  которого отфильтровываются строки с разными значениями общего столбца,
  такие операции называются антиобъединением anti-join*/

SELECT d.*,
       e.deptno ---40, OPERATIONS, BOSTON в отделе 40 никто из персонала компании не работает
FROM dept d
         LEFT OUTER JOIN emp e
                         ON (d.deptno = e.deptno)
WHERE e.deptno IS NULL;

/*Добавление в запрос независимых объединений.
Требуется модифицировать запрос, чтобы он возвращал дополнительную информаацию,
но в результате попытки выполнить такую модификацию теряются данные из первоначального
результирующего множества
*/

SELECT e.ename, d.loc, eb.received
FROM emp e
         JOIN dept d ON e.deptno = d.deptno
         LEFT JOIN emp_bonus eb ON e.empno = eb.empno
ORDER BY d.loc;

/*Внешнее объединение можно также эмулировать посредством скалярного подзапроса в списке
  оператора SELECT
  Скалярные подзапросы должны возвращать только одно (скалярное) значение, возвращение в списке
  select более чем одной строки вызовет ошибку*/
SELECT e.ename,
       d.loc,
       (SELECT eb.received
        FROM emp_bonus eb
        WHERE eb.empno = e.empno) AS received
FROM emp e,
     dept d
WHERE e.deptno = d.deptno
ORDER BY 2;

/*Проверка двух таблиц на идентичность
  требуется проверить две таблицы или представления на идентичность по количеству
  и значению строк*/

create view x as
    SELECT *
from emp where deptno != 10
UNION ALL
select * from emp where ename = 'WARD';

select *
from x;

/*Нам нужно определить, содержит ли это представление точно такие же данные, как и таблица
  EMP. Мы намеренно продублировали строку для служащего WARD, чтобы продемонстрироваь, что
  решение выявит не только разные данные, но также и дубликаты строк*/

(SELECT x.empno,
        x.ename,
        x.job,
        x.mgr,
        x.hiredate,
        x.sal,
        x.comm,
        x.deptno,
        COUNT(*) AS cnt
 FROM x
 GROUP BY x.empno,
          x.ename,
          x.job,
          x.mgr,
          x.hiredate,
          x.sal,
          x.comm,
          x.deptno
EXCEPT
 SELECT e.empno,
        e.ename,
        e.job,
        e.mgr,
        e.hiredate,
        e.sal,
        e.comm,
        e.deptno,
        COUNT(*) AS cnt
 FROM emp e
 GROUP BY e.empno,
          e.ename,
          e.job,
          e.mgr,
          e.hiredate,
          e.sal,
          e.comm,
          e.deptno
)
UNION ALL
(
    SELECT e.empno,
           e.ename,
           e.job,
           e.mgr,
           e.hiredate,
           e.sal,
           e.comm,
           e.deptno,
           COUNT(*) AS cnt
    FROM emp e
    GROUP BY e.empno,
             e.ename,
             e.job,
             e.mgr,
             e.hiredate,
             e.sal,
             e.comm,
             e.deptno

EXCEPT

SELECT x.empno,
        x.ename,
        x.job,
        x.mgr,
        x.hiredate,
        x.sal,
        x.comm,
        x.deptno,
        COUNT(*) AS cnt
 FROM x
 GROUP BY x.empno,
          x.ename,
          x.job,
          x.mgr,
          x.hiredate,
          x.sal,
          x.comm,
          x.deptno
);

/*Выполнение объединений при использовании агрегатных функций
  ваш запрос охватывает несколько таблиц, поэтому требуется убедиться,
  что объединения не нарушат агрегацию
  Например нужно вычислить суммы зарплат и премий всех служащих отдела 10
  Но некоторые служащие получили несколько премий, и объединение таблицы
  emp с таблицей emp_bonus3_9, содержащей данные о премиях сотрудников
  для этой задачи, вызывает возвращение неправильных значений
  агрегатной функции sum*/

select *
from emp_bonus3_9;

/*Рассмотрим запрос, который возвращает данные о зарплате и премиях всех служащих отдела 10.
  Размер премии определятся по таблице bonus.type Премия типа 1 составляет 10% зарплаты
  служащего, типа 2 - 20% и типа 3 - 30%*/

SELECT e.empno,
       e.ename,
       e.sal,
       e.deptno,
       e.sal * CASE
                   WHEN eb.type = 1 THEN 0.1
                   WHEN eb.type = 2 THEN 0.2
                   ELSE 0.3
           END AS bonus
FROM emp e,
     emp_bonus3_9 eb
WHERE e.empno = eb.empno
  AND e.deptno = 10;
/*Пока что все хорошо, но при попытке присоединить таблицу emp_bonus3_9, чтобы вычислить
  сумму премий, возникают проблемы
  сумма total_sal вычисляется некорректно*/

select x1.deptno,
       sum(x1.sal) as total_sal,
       sum(x1.bonus) as total_nonus
from (SELECT e.empno,
             e.ename,
             e.sal,
             e.deptno,
             e.sal * CASE
                         WHEN eb.type = 1 THEN 0.1
                         WHEN eb.type = 2 THEN 0.2
                         ELSE 0.3
                 END AS bonus
      FROM emp e,
           emp_bonus3_9 eb
      WHERE e.empno = eb.empno
        AND e.deptno = 10) as x1
GROUP BY x1.deptno; ---10050

select sum(sal) as total_sal2
from emp where deptno = 10; --- 8750

/*Но почему total_sal вычисляется неправильно, потому что объединение
  создает дубликаты строк в столбце sal*/

SELECT e.ename, ---два раза учитывается MILLER
       e.sal
FROM emp e,
     emp_bonus3_9 eb
WHERE e.empno = eb.empno
  AND e.deptno = 10;

/*Решение.
  Вычисление общих сумм в объединенных таблицах требует осторожного подхода
  Избежать неправильных результатов вычислений, вызываемых дублированием строк
  при объединении таблиц с помощью агрегатных функций можно двумя способами.
  Первый - просто используя в вызове агрегатной функции ключевое слово distinct,
  обеспечивающее обработку только однозначных экземпляров каждого значения.
  Второй - выполняя агрегирование во вложенном запросе, прежде чем выполнять объединение - агрегация
  будет вычислена еще до объединения, что полностью устраняет проблему*/

EXPLAIN ANALYZE
select x1.deptno,
       sum(distinct x1.sal) as total_sal, ---добаввляем dictinct
       sum(x1.bonus) as total_nonus
from (SELECT e.empno,
             e.ename,
             e.sal,
             e.deptno,
             e.sal * CASE
                         WHEN eb.type = 1 THEN 0.1
                         WHEN eb.type = 2 THEN 0.2
                         ELSE 0.3
                 END AS bonus
      FROM emp e,
           emp_bonus3_9 eb
      WHERE e.empno = eb.empno
        AND e.deptno = 10) as x1
GROUP BY x1.deptno; ---10050

EXPLAIN ANALYZE
---второй вариант
SELECT e.deptno,
       SUM(e.sal) AS total_sal,
       SUM(e.sal * (SELECT SUM(CASE
                                   WHEN type = 1 THEN 0.1
                                   WHEN type = 2 THEN 0.2
                                   ELSE 0.3
           END)
                    FROM emp_bonus3_9 eb
                    WHERE eb.empno = e.empno)
       ) AS total_bonus
FROM emp e
WHERE e.deptno = 10
GROUP BY e.deptno;

/*Выполнение внешних объединений при использовании агрегатных функций
  Постановка задачи та же что и для рецепта 3_9 с тем отличием, что не
  все служащие отдела 10 получили премии, что отражено в таблице
  emp_bonus_3_10

Таблица A = множество строк {a1, a2, a3}
Таблица B = множество строк {b1, b2, b3}
INNER JOIN A и B по условию =
{ (a1,b1), (a2,b2) } где каждая пара удовлетворяет условию
Это НОВОЕ множество пар, "объединенных" по условию.

*/

SELECT deptno,
       SUM(sal)   AS total_sal, ---2600
       SUM(bonus) AS total_bonus
FROM (SELECT e.empno,
             e.ename,
             e.sal,
             e.deptno,
             e.sal * CASE
                         WHEN type = 1 THEN 0.1
                         WHEN type = 2 THEN 0.2
                         ELSE 0.3
                 END AS bonus
      FROM emp e,
           emp_bonus3_10 eb
      WHERE e.empno = eb.empno
        AND e.deptno = 10)
GROUP BY deptno;

/*Два раза в итоговую сумму попадает Миллер, остальные служащие
  отдела 10 не попадают в выборку, а это является некорректным расчетом*/
SELECT e.empno,
       e.ename,
       e.sal,
       e.deptno,
       e.sal * CASE
                   WHEN type = 1 THEN 0.1
                   WHEN type = 2 THEN 0.2
                   ELSE 0.3
           END AS bonus
FROM emp e,
     emp_bonus3_10 eb
WHERE e.empno = eb.empno
  AND e.deptno = 10;


/*Корректное решение*/
EXPLAIN ANALYZE
SELECT e.deptno,
       SUM(e.sal) AS total_sal,
       SUM(e.sal * (SELECT SUM(CASE
                                   WHEN type = 1 THEN 0.1
                                   WHEN type = 2 THEN 0.2
                                   ELSE 0.3
           END)
                    FROM emp_bonus3_10 eb
                    WHERE eb.empno = e.empno)
       )          AS total_bonus
FROM emp e
WHERE e.deptno = 10
GROUP BY e.deptno;


/*Чем плох
Проблема: Коррелированный подзапрос выполняется для каждой строки из filtered_emp!
Если в 10-м отделе 100 сотрудников:
Подзапрос выполнится 100 раз
Каждый раз - поиск в таблице emp_bonus3_10*/
EXPLAIN ANALYZE
WITH filtered_emp AS (
    SELECT e.empno, e.sal, e.deptno
    FROM emp e
    WHERE e.deptno = 10
),
     bonus_calc AS (
         SELECT fe.*,
                (SELECT SUM(CASE
                                WHEN eb.type = 1 THEN 0.1
                                WHEN eb.type = 2 THEN 0.2
                                ELSE 0.3
                    END)
                 FROM emp_bonus3_10 eb
                 WHERE eb.empno = fe.empno) AS bonus_rate
         FROM filtered_emp fe
     )
SELECT deptno,
       SUM(sal) AS total_sal,
       SUM(sal * COALESCE(bonus_rate, 0)) AS total_bonus
FROM bonus_calc
GROUP BY deptno;


/*Вариант оптимизированный:
Заменяет коррелированный подзапрос на JOIN
Обычно дает лучший план выполнения
Легче читается и поддерживается*/
EXPLAIN ANALYZE
SELECT e.deptno,
       SUM(e.sal) AS total_sal,
       SUM(e.sal * COALESCE(eb.total_rate, 0)) AS total_bonus
FROM emp e
 LEFT JOIN (
    SELECT empno,
           SUM(CASE
                   WHEN type = 1 THEN 0.1
                   WHEN type = 2 THEN 0.2
                   ELSE 0.3
               END) AS total_rate
    FROM emp_bonus3_10
    GROUP BY empno
) eb ON e.empno = eb.empno
WHERE e.deptno = 10
GROUP BY e.deptno;


/*Возвращение отсутствующих данных из нескольких таблиц
  Это можно сделать с помощью полного внешнего объединения
  полное внешнее объединение это комбинация двух типов объединений
  левого и правого.
*/

insert into emp(empno, ename, job, mgr, hiredate, sal, comm,deptno)
select 1111,'YODA','JEDI',null,hiredate,sal,comm,null
    from emp
where ename = 'KING';


SELECT d.deptno, d.dname, e.ename
FROM dept d
         FULL OUTER JOIN emp e ON d.deptno = e.deptno;

/*Значения null в вычислениях и сравнениях
  значение null не может быть равным или не равным любому значению, даже другому значению null
  Но нам нужно выполнить операции со значениями столбца, который может содержать значения
  null также, как и операции с действительными значениями.
  Например, необходимо найти в таблице EMP всех служащих, для которых значение премии comm меньше
  чем размер премии служащего ward
  Результирующее множество также должно содержать служащих для которых значение
  премии равно null*/

select
ename,
comm,
coalesce(comm,0)
from emp
where coalesce(comm,0) < (SELECT comm from emp where ename = 'WARD');


/*
Вставка, обновление и удаление записей
копирование строк одной таблицы в другую
*/

create table dept_east(deptno numeric(2) ,dname varchar(10),loc varchar(10));

insert into dept_east (deptno,dname,loc)
select *
from dept
where loc in ('NEW YORK','BOSTON');

/*Копирование определения таблицы
  требуется создать таблицу с набором столбцов как и в существующей
  таблице.
  Например, создать копию dept присвоив ей название dept_2
  Копировать строки в новую таблицу не нужно, только структуру столбцов
*/

CREATE TABLE dept_2
AS
SELECT *
FROM dept
where 1 = 0;


CREATE TABLE dept_west
AS
SELECT *
FROM dept
where 1 = 0;


CREATE TABLE dept_mid
AS
SELECT *
FROM dept
where 1 = 0;

DROP table dept_2;

CREATE TABLE dept_2 (LIKE dept
                         INCLUDING DEFAULTS      -- Значения по умолчанию
                         INCLUDING CONSTRAINTS   -- Ограничения (CHECK)
                         INCLUDING IDENTITY      -- Identity/Serial столбцы
                         INCLUDING INDEXES       -- Индексы
                         INCLUDING STORAGE       -- Настройки хранения
                         INCLUDING COMMENTS      -- Комментарии
                         INCLUDING GENERATED     -- Генерируемые столбцы
                         INCLUDING STATISTICS);  -- Статистики

-- 3. Создаём копию "хорошим" способом
CREATE TABLE dept_good_copy (LIKE dept INCLUDING ALL);

/*Если нужны не все столбцы*/
CREATE TABLE new_table (LIKE original_table INCLUDING ALL);
ALTER TABLE new_table DROP COLUMN column_to_remove;

select *
from dept_2;

/*Вставка строк одновременно в несколько таблиц
Решение заключаается во вставке строк результирующего множества запроса
в таблицы назначения
Через CTE будет ошибка, потому как CTE в PostgreSQL действует
только для следующего за ним оператора.
После первого INSERT CTE source_data_dept  больше не доступен.
*/

CREATE TEMP TABLE source_data_dept AS
SELECT deptno, dname, loc
FROM dept;

-- Используем временную таблицу
INSERT INTO dept_east(deptno, dname, loc)
SELECT deptno, dname, loc FROM source_data_dept
WHERE loc IN ('NEW YORK', 'BOSTON');

INSERT INTO dept_mid(deptno, dname, loc)
SELECT deptno, dname, loc FROM source_data_dept
WHERE loc = 'CHICAGO';

INSERT INTO dept_west(deptno, dname, loc)
SELECT deptno, dname, loc FROM source_data_dept
WHERE loc NOT IN ('NEW YORK', 'BOSTON', 'CHICAGO');

-- Очищаем временную таблицу (автоматически удалится при завершении сессии)
DROP TABLE source_data_dept;

/*Блокировка вставки данных в определенные столбцы
  требуется предотвратить вставку пользователями или программами значения в определенные столбцы
  таблицы. Например, нужно решить вставку значений программой только в столбцы empno, ename, job
  Создаем представление таблицы, содержащее только таблицы, в которые разрешена вставка и позволяет вам все вставки
  только через это представление.
*/

create view new_emps as
select empno, ename, job
from emp;

/*Пользователям предоставляем доступ к этому представлению
GRANT SELECT ON new_emps TO username;
GRANT INSERT, UPDATE, DELETE ON new_emps TO username;

Тогда пользователи могут вставлять новые записи в таблицу EMP, создавая новые записи в представлении
NEW_EMP, но при этом заполняя только те три столбца таблицы, которые указаны в определении представления.
*/

insert into new_emps
(empno, ename, job)
VALUES(1,'Jonathan', 'Editor');

/*В таблице emp новая запись*/
select *
from emp;

/*Изменение записей в таблице требуется изменить значения некоторых столбцов таблицы. Например, надо повысить
  зарплату служащих отдела 20 на 10%. В следующем результирующем множестве отображены отображены данные
  столбцов DEPTNO, ENAME, SAL
*/

select deptno, ename, sal
from emp
where deptno = 20
order by 1,2;

/*Нам нужно повысить все значения sal на 10%*/

update emp
set sal = sal* 1.10
where deptno = 20;


/*Обновление при условии наличия соответствующих строк*/
update emp
set sal = sal * 1.20
where empno in (select empno from emp_bonus);

/*Обновление значениями из другой таблицы*/
create table new_sal
(
    deptno int,
    sal numeric(10, 2)
);
insert into new_sal(deptno, sal)
values(10,4000);

/*Изменим тип данных*/
ALTER TABLE new_sal
ALTER COLUMN  sal TYPE numeric(15,2);

select *
from new_sal;

update emp
set sal = ns.sal
from new_sal ns
where ns.deptno = emp.deptno;

/*Слияние записей
  требуется выполнить, вставку, обновление, удаление записи в таблице, в зависимости от наличия или состояния
  соответствующей записи.
  В частности, если запись существует, обновить ее, если нет - вставить, а если обновленная запись не отвечает
  определенному условию - удалить ее.

*/
