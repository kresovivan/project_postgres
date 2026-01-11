-- Создание таблицы DEPT

---truncate table dept;
CREATE TABLE dept (
                      deptno INTEGER PRIMARY KEY,
                      dname  VARCHAR(14),
                      loc    VARCHAR(13)
);

-- Вставка данных в DEPT
INSERT INTO dept VALUES (10, 'ACCOUNTING', 'NEW YORK');
INSERT INTO dept VALUES (20, 'RESEARCH',   'DALLAS');
INSERT INTO dept VALUES (30, 'SALES',      'CHICAGO');
INSERT INTO dept VALUES (40, 'OPERATIONS', 'BOSTON');

----truncate table emp;
-- Создание таблицы EMP
CREATE TABLE emp (
                     empno    INTEGER PRIMARY KEY,
                     ename    VARCHAR(10),
                     job      VARCHAR(9),
                     mgr      INTEGER,
                     hiredate DATE,
                     sal      DECIMAL(7,2),
                     comm     DECIMAL(7,2),
                     deptno   INTEGER REFERENCES dept(deptno)
);

-- Вставка данных в EMP
INSERT INTO emp VALUES
    (7369, 'SMITH',  'CLERK',     7902, '1980-12-17',  800, NULL, 20);
INSERT INTO emp VALUES
    (7499, 'ALLEN',  'SALESMAN',  7698, '1981-02-20', 1600,  300, 30);
INSERT INTO emp VALUES
    (7521, 'WARD',   'SALESMAN',  7698, '1981-02-22', 1250,  500, 30);
INSERT INTO emp VALUES
    (7566, 'JONES',  'MANAGER',   7839, '1981-04-02', 2975, NULL, 20);
INSERT INTO emp VALUES
    (7654, 'MARTIN', 'SALESMAN',  7698, '1981-09-28', 1250, 1400, 30);
INSERT INTO emp VALUES
    (7698, 'BLAKE',  'MANAGER',   7839, '1981-05-01', 2850, NULL, 30);
INSERT INTO emp VALUES
    (7782, 'CLARK',  'MANAGER',   7839, '1981-06-09', 2450, NULL, 10);
INSERT INTO emp VALUES
    (7788, 'SCOTT',  'ANALYST',   7566, '1982-12-09', 3000, NULL, 20);
INSERT INTO emp VALUES
    (7839, 'KING',   'PRESIDENT', NULL, '1981-11-17', 5000, NULL, 10);
INSERT INTO emp VALUES
    (7844, 'TURNER', 'SALESMAN',  7698, '1981-09-08', 1500,    0, 30);
INSERT INTO emp VALUES
    (7876, 'ADAMS',  'CLERK',     7788, '1983-01-12', 1100, NULL, 20);
INSERT INTO emp VALUES
    (7900, 'JAMES',  'CLERK',     7698, '1981-12-03',  950, NULL, 30);
INSERT INTO emp VALUES
    (7902, 'FORD',   'ANALYST',   7566, '1981-12-03', 3000, NULL, 20);
INSERT INTO emp VALUES
    (7934, 'MILLER', 'CLERK',     7782, '1982-01-23', 1300, NULL, 10);


-- Создание таблицы EMP_BONUS
CREATE TABLE emp_bonus (
                           empno INTEGER,
                           received DATE,
                           type INTEGER
);

-- Пример 1: Данные из рецепта 10.1 (Chapter 10)
INSERT INTO emp_bonus VALUES
                          (7369, '2005-03-14', 1),
                          (7900, '2005-03-14', 2),
                          (7788, '2005-03-14', 3);

-- Пример 2: Дополнительные данные из других рецептов
INSERT INTO emp_bonus VALUES
                          (7934, '2005-03-14', 1),
                          (7934, '2005-03-15', 2),
                          (7839, '2005-03-15', 3),
                          (7782, '2005-03-15', 1);


-- Создание таблицы CUSTOMERS
CREATE TABLE customers (
                           cust_id INTEGER PRIMARY KEY,
                           cust_name VARCHAR(50) NOT NULL,
                           cust_city VARCHAR(50),
                           cust_state CHAR(2),
                           cust_zip VARCHAR(10),
                           cust_email VARCHAR(100)
);

-- Вставка данных в CUSTOMERS (из рецептов книги)
INSERT INTO customers (cust_id, cust_name, cust_city, cust_state, cust_zip, cust_email)
VALUES (1001, 'JOHN SMITH', 'NEW YORK', 'NY', '10001', 'john.smith@email.com'),
       (1002, 'MARY JONES', 'LOS ANGELES', 'CA', '90001', 'mary.jones@email.com'),
       (1003, 'BOB JOHNSON', 'CHICAGO', 'IL', '60601', 'bob.johnson@email.com'),
       (1004, 'SARA LEE', 'HOUSTON', 'TX', '77001', 'sara.lee@email.com'),
       (1005, 'MIKE BROWN', 'PHILADELPHIA', 'PA', '19019', 'mike.brown@email.com'),
       (1006, 'LISA WHITE', 'PHOENIX', 'AZ', '85001', 'lisa.white@email.com'),
       (1007, 'DAVID MILLER', 'SAN ANTONIO', 'TX', '78201', 'david.miller@email.com'),
       (1008, 'JENNIFER DAVIS', 'SAN DIEGO', 'CA', '92101', 'jennifer.davis@email.com'),
       (1009, 'TOM WILSON', 'DALLAS', 'TX', '75201', 'tom.wilson@email.com'),
       (1010, 'AMANDA TAYLOR', 'SAN JOSE', 'CA', '95101', 'amanda.taylor@email.com');




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

select deptno, empno, ename, comm
    from emp
    order by 1;

create table emp_comission
(
    deptno  int,
    empno   int,
    ename   varchar(50),
    comm    numeric(7,2)
);

insert into emp_comission(deptno,  empno, ename,  comm)
values
(10,7782, 'CLARK', null),
(10,7839, 'KING', null),
(10,7934, 'MILLER', null);

select deptno, empno, ename, comm
from emp_comission
order by 1;

MERGE INTO emp_comission AS ec
USING emp ON (ec.empno = emp.empno)
/*
Условие: зарплата < 2000
WHEN MATCHED AND emp.sal < 2000 THEN DELETE
Пример: если emp.sal = 1500 → запись удаляется*/
WHEN MATCHED AND emp.sal < 2000 THEN
    DELETE
WHEN MATCHED THEN
/*Для остальных совпадений
WHEN MATCHED THEN UPDATE SET comm = 1000
Пример: если emp.sal = 2500 → comm устанавливается в 1000
empno | ename  | sal    | Что произойдет?
------|--------|--------|-----------------
1     | John   | 1500   → DELETE (sal < 2000)
2     | Jane   | 1999.99 → DELETE (sal < 2000)
3     | Bob    | 2000    → UPDATE (comm = 1000)
4     | Alice  | 2000.01 → UPDATE (comm = 1000)
5     | Mark   | 3000    → UPDATE (comm = 1000)
6     | Tom    | NULL    → UPDATE (comm = 1000)
*/
    UPDATE SET comm = 1000
WHEN NOT MATCHED THEN
/*
-- Пример: сотрудник есть в emp, но нет в emp_comission
-- Добавляется с комиссией = 1000
*/
    INSERT (empno, ename, deptno, comm)
    VALUES (emp.empno, emp.ename, emp.deptno, 1000);


-- Выполняем MERGE
MERGE INTO emp_comission AS ec
USING emp ON (ec.empno = emp.empno)
WHEN MATCHED AND emp.sal < 2000 THEN
    DELETE
WHEN MATCHED THEN
    UPDATE SET comm = 1000
WHEN NOT MATCHED THEN
    INSERT (empno, ename, deptno, comm)
    VALUES (emp.empno, emp.ename, emp.deptno, 1000);

-- Затем подсчитываем результаты
WITH stats AS (
    SELECT
        e.empno,
        ec.empno as existed,
        e.sal,
        CASE
            WHEN ec.empno IS NULL THEN 'INSERTED'
            WHEN e.sal < 2000 THEN 'DELETED'
            ELSE 'UPDATED'
            END as action
    FROM emp e
             LEFT JOIN emp_comission ec ON e.empno = ec.empno
)
SELECT *
FROM stats
ORDER BY action;


select *
from emp_comission;

/*Удаление записей таблицы*/
truncate emp_comission;

/*Удаление определенных записей*/
delete from emp_comission where deptno = 10;

/*Удаление строк, нарушающих ссылочную целостность
  Например требуется удалить записи, ссылающиеся на несуществующие
  записи в какой-то таблице. Например, для некоторых служащих может
  быть указан несуществующий номер отдела. Запись таких служащих нужно удалить*/

delete
from emp
where not exists (select *
from dept
where dept.deptno = emp.deptno)

/*Также можно использовать такой запрос*/

delete from emp
where deptno not in (select deptno from dept);

/*Удаление дубликатов записей, при удалении дубликатов необходимо
  точно определить, что именно делает строки дублирующимися. В рассматриваемом
  примере дубликатами являются записи, содержащие одинаковые значения столбца name
  Смысл решения состоит в группировке записей по дубликатам значений с последующим
*/
truncate table dupes;
create table dupes (id integer, name varchar(10));

insert into dupes values (1,'NAPOLEON');
insert into dupes values (2,'DYNAMO');
insert into dupes values (3,'DYNAMO');
insert into dupes values (4,'SHE SELLS');
insert into dupes values (5,'SHE SELLS');
insert into dupes values (6,'SEA SHELLS');
insert into dupes values (7,'SEA SHELLS');
insert into dupes values (8,'SEA SHELLS');
insert into dupes values (9,'SEA SHELLS');


select *
from dupes
order by 1;


-- Удалить дубликаты, оставляя первую запись
DELETE FROM dupes
WHERE id IN (
    SELECT id
    FROM (
             SELECT
                 id,
                 ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) as rn
             FROM dupes
         ) t
    WHERE rn > 1
);


delete from dupes
where id not in (select min(id) from dupes group by name);
/*-- Создать новую таблицу без дубликатов
CREATE TABLE dupes_new AS
SELECT DISTINCT ON (name) *
FROM dupes
ORDER BY name, id;

-- Удалить старую и переименовать
DROP TABLE dupes;
ALTER TABLE dupes_new RENAME TO dupes;
*/

/*Удаление записей, на которые есть ссылки из другой таблицы*/
CREATE TABLE dept_accidents
(
    deptno integer,
    accident_name varchar(20)
);
INSERT INTO dept_accidents (deptno, accident_name)
VALUES (10, 'BROKEN FOOT'),
       (10, 'FLESH WOUND'),
       (20, 'FIRE'),
       (20, 'FIRE'),
       (20, 'FLOOD'),
       (30, 'BRUISED GLUTE');

select *
from dept_accidents;

/*Нужно удалить записи EMP для служащих работающих в отделах в которых произошло три и более несчастных случая*/

delete
from emp
where deptno in (select deptno from dept_accidents
                               group by deptno
                               having count(*) >=3);

select *
from emp;

/*Запросы на получение метаданных
  Информация о конкретной схеме базы данных, о созданных таблицах, о проиндексированных ключах*/

SELECT *
FROM information_schema.tables
WHERE table_schema = 'SMEAGOL';

CREATE SCHEMA IF NOT EXISTS smeagol;

CREATE TABLE smeagol.emp (
                             empno    INTEGER PRIMARY KEY,
                             ename    VARCHAR(10),
                             job      VARCHAR(9),
                             mgr      INTEGER,
                             hiredate DATE,
                             sal      DECIMAL(7,2),
                             comm     DECIMAL(7,2),
                             deptno   INTEGER
);

-- Устанавливаем схему по умолчанию
SET search_path TO smeagol, public;

CREATE TABLE smeagol.emp (
                             empno    INTEGER PRIMARY KEY,
                             ename    VARCHAR(10),
                             job      VARCHAR(9),
                             mgr      INTEGER,
                             hiredate DATE,
                             sal      DECIMAL(7,2),
                             comm     DECIMAL(7,2),
                             deptno   INTEGER
);

INSERT INTO smeagol.emp
VALUES (7369, 'SMITH', 'CLERK', 7902, '1980-12-17', 800, NULL, 20),
       (7499, 'ALLEN', 'SALESMAN', 7698, '1981-02-20', 1600, 300, 30),
       (7521, 'WARD', 'SALESMAN', 7698, '1981-02-22', 1250, 500, 30),
       (7566, 'JONES', 'MANAGER', 7839, '1981-04-02', 2975, NULL, 20),
       (7654, 'MARTIN', 'SALESMAN', 7698, '1981-09-28', 1250, 1400, 30),
       (7698, 'BLAKE', 'MANAGER', 7839, '1981-05-01', 2850, NULL, 30),
       (7782, 'CLARK', 'MANAGER', 7839, '1981-06-09', 2450, NULL, 10),
       (7788, 'SCOTT', 'ANALYST', 7566, '1982-12-09', 3000, NULL, 20),
       (7839, 'KING', 'PRESIDENT', NULL, '1981-11-17', 5000, NULL, 10),
       (7844, 'TURNER', 'SALESMAN', 7698, '1981-09-08', 1500, 0, 30),
       (7876, 'ADAMS', 'CLERK', 7788, '1983-01-12', 1100, NULL, 20),
       (7900, 'JAMES', 'CLERK', 7698, '1981-12-03', 950, NULL, 30),
       (7902, 'FORD', 'ANALYST', 7566, '1981-12-03', 3000, NULL, 20),
       (7934, 'MILLER', 'CLERK', 7782, '1982-01-23', 1300, NULL, 10);

CREATE TABLE smeagol.dept (
                              deptno INTEGER PRIMARY KEY,
                              dname  VARCHAR(14),
                              loc    VARCHAR(13)
);

INSERT INTO smeagol.dept VALUES
                             (10, 'ACCOUNTING', 'NEW YORK'),
                             (20, 'RESEARCH',   'DALLAS'),
                             (30, 'SALES',      'CHICAGO'),
                             (40, 'OPERATIONS', 'BOSTON');


CREATE TABLE smeagol.emp_bonus (
                                   empno INTEGER,
                                   received DATE,
                                   type INTEGER
);

INSERT INTO smeagol.emp_bonus VALUES
                                  (7369, '2005-03-14', 1),
                                  (7900, '2005-03-14', 2),
                                  (7788, '2005-03-14', 3),
                                  (7934, '2005-03-14', 1);


CREATE TABLE smeagol.dupes (
                               id INTEGER,
                               name VARCHAR(10)
);

INSERT INTO smeagol.dupes
VALUES (1, 'NAPOLEON'),
       (2, 'DYNAMO'),
       (3, 'DYNAMO'),
       (4, 'SHE SELLS'),
       (5, 'SHE SELLS'),
       (6, 'SEA SHELLS'),
       (7, 'SEA SHELLS'),
       (8, 'SEA SHELLS'),
       (9, 'SEA SHELLS');

CREATE TABLE smeagol.emp_comission (
                                       empno INTEGER,
                                       ename VARCHAR(10),
                                       deptno INTEGER,
                                       comm DECIMAL(7,2)
);

INSERT INTO smeagol.emp_comission VALUES
                                      (1, 'JOHN', 10, 500),
                                      (2, 'JANE', 20, 300),
                                      (4, 'ALICE', 30, 400);


CREATE TABLE smeagol.dept_accidents (
                                        deptno INTEGER,
                                        accident_name VARCHAR(50)
);

INSERT INTO smeagol.dept_accidents VALUES
                                       (10, 'BROKEN FOOT'),
                                       (10, 'FLESH WOUND'),
                                       (20, 'FIRE'),
                                       (20, 'FIRE'),
                                       (20, 'FLOOD'),
                                       (30, 'BRUISED GLUTE');

CREATE TABLE smeagol.t1 (
                            id INTEGER PRIMARY KEY
);

INSERT INTO smeagol.t1 VALUES (1);

CREATE TABLE smeagol.t10 (
                             id INTEGER PRIMARY KEY
);

INSERT INTO smeagol.t10
SELECT generate_series(1, 10);


CREATE TABLE smeagol.t100 (
                              id INTEGER PRIMARY KEY
);

INSERT INTO smeagol.t100
SELECT generate_series(1, 100);


CREATE TABLE smeagol.emp2
(
    empno INTEGER PRIMARY KEY,
    ename VARCHAR(10),
    job VARCHAR(9),
    sal DECIMAL(7, 2),
    deptno INTEGER
);

INSERT INTO smeagol.emp2
VALUES (7369, 'SMITH', 'CLERK', 800, 20),
       (7499, 'ALLEN', 'SALESMAN', 1600, 30),
       (7521, 'WARD', 'SALESMAN', 1250, 30),
       (7566, 'JONES', 'MANAGER', 2975, 20),
       (7654, 'MARTIN', 'SALESMAN', 1250, 30);

CREATE TABLE smeagol.v (
                           id INTEGER PRIMARY KEY,
                           val INTEGER
);

INSERT INTO smeagol.v VALUES
                          (1, 100),
                          (2, 200),
                          (3, 300),
                          (4, 400);


CREATE TABLE smeagol.emp_sales
(
    empno INTEGER,
    sales_date DATE,
    sales_amount DECIMAL(10, 2)
);

INSERT INTO smeagol.emp_sales
VALUES (7499, '2024-01-15', 1000),
       (7499, '2024-01-20', 1500),
       (7499, '2024-02-01', 800),
       (7521, '2024-01-18', 1200),
       (7521, '2024-02-05', 900),
       (7654, '2024-01-25', 2000),
       (7654, '2024-02-10', 1100);


CREATE TABLE smeagol.orders (
                                order_id INTEGER PRIMARY KEY,
                                customer_id INTEGER,
                                order_date DATE,
                                ship_date DATE,
                                amount DECIMAL(10,2)
);

INSERT INTO smeagol.orders VALUES
                               (1, 101, '2024-01-15', '2024-01-18', 150.00),
                               (2, 102, '2024-01-16', '2024-01-19', 225.50),
                               (3, 103, '2024-01-17', '2024-01-20', 300.00),
                               (4, 101, '2024-02-01', '2024-02-03', 180.00),
                               (5, 102, '2024-02-05', '2024-02-07', 275.25),
                               (6, 104, '2024-02-10', '2024-02-12', 420.75),
                               (7, 101, '2024-02-15', '2024-02-17', 190.00);


select *
from information_schema.tables
where table_schema = 'smeagol'

/*Создание списка столбцов таблицы*/

SELECT column_name, ordinal_position, data_type, udt_name,
       numeric_precision,  -- общее количество цифр
       numeric_scale,      -- количество цифр после запятой
       is_nullable         -- может ли столбец содержать NULL значения.
FROM information_schema.columns
WHERE table_schema = 'smeagol'
  AND table_name = 'emp';

/*Создание списка индексированных столбцов таблицы*/

select a.tablename, a.indexname, a.indexdef, b.column_name
from  pg_catalog.pg_indexes a,
      information_schema.columns b
where a.schemaname = 'smeagol'
and a.tablename = b.table_name
and a.tablename='emp';

/*Создание списка ограничений, наложенных на таблицу*/

select a.table_name, a.constraint_name, b.column_name, a.constraint_type
from information_schema.table_constraints a,
information_schema.key_column_usage b
where a.table_name = 'emp'
and a.table_schema= 'smeagol'
and a.table_name = b.table_name
and a.table_schema = b.table_schema
and a.constraint_name = b.constraint_name

/*Создание списка внешних ключей без соответствующих индексов
  Требуется создать список таблиц, содержащих непроиндексированные
  столбцы внешних ключей, например нужно узнать проиндексированы
  ли внешние ключи таблицы emp*/

WITH foreign_key_info AS (
    SELECT
        a.constraint_schema,
        a.table_name,
        a.constraint_name,
        a.column_name
    FROM information_schema.key_column_usage a
             INNER JOIN information_schema.referential_constraints b
                        ON a.constraint_name = b.constraint_name
                            AND a.constraint_schema = b.constraint_schema
    WHERE a.constraint_schema = 'smeagol'
      AND a.table_name = 'emp'
),
     index_info AS (
         SELECT
             a.schemaname,
             a.tablename,
             a.indexname,
             b.column_name
         FROM pg_catalog.pg_indexes a
                  INNER JOIN information_schema.columns b
                             ON a.tablename = b.table_name
                                 AND a.schemaname = b.table_schema
     )
SELECT
    fk.table_name,
    fk.constraint_name,
    fk.column_name,
    idx.indexname
FROM foreign_key_info fk
         LEFT JOIN index_info idx
                   ON fk.constraint_schema = idx.schemaname
                       AND fk.table_name = idx.tablename
                       AND fk.column_name = idx.column_name
WHERE idx.indexname IS NULL;

/*Установка DBLINK*/
SELECT * FROM pg_extension WHERE extname = 'dblink';
CREATE EXTENSION IF NOT EXISTS dblink;

/*Как выполнить запрос через db_link*/
SELECT * FROM dblink(
                      'host=localhost dbname=demo_one user=postgres password=M*******900',
                      'SELECT * FROM bookings'
              ) AS t(
                     book_ref char(6),
                     book_date timestamp with time zone,
                     total_amount numeric(10,2)
    );

/*Функции
  Любой оператор в выполняемой секции блока может быть вложенным блоком. Вложенные блоки используются для логической группировки
  нескольких операторов или локализации области действия переменных для группы операторов. Во время выполнения вложенного блока
  переменные, объявленные в нём, скрывают переменные внешних блоков с такими же именами. Чтобы получить доступ к внешним
  переменным, нужно дополнить их имена меткой блока. Например:*/
CREATE FUNCTION somefunc() RETURNS integer AS $$
<< outerblock >>
    DECLARE
    quantity integer := 30;
BEGIN
    RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 30
    quantity := 50;
    --
    -- Вложенный блок
    --
    DECLARE
        quantity integer := 80;
    BEGIN
        RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 80
        RAISE NOTICE 'Во внешнем блоке quantity = %', outerblock.quantity;  -- Выводится 50
    END;

    RAISE NOTICE 'Сейчас quantity = %', quantity;  -- Выводится 50

    RETURN quantity;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION sales_tax(real) RETURNS real AS $$
DECLARE
    subtotal ALIAS FOR $1;
BEGIN
    RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION sales_tax(subtotal real) RETURNS real AS $$
BEGIN
    RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION sales_tax(subtotal real DEFAULT 0.0) RETURNS real AS $$
BEGIN
    RETURN subtotal * 0.06;
END;
$$ LANGUAGE plpgsql;



/*Скалярная функция*/
---Функция, возвращающая приветствие
CREATE OR REPLACE FUNCTION greet(name TEXT)
    RETURNS TEXT AS $$
BEGIN
    RETURN 'Привет, ' || name || '!';
END;
$$ LANGUAGE plpgsql;

-- Использование:
SELECT greet('Иван');  -- 'Привет, Иван!'

/*Функция, возвращающая таблицу*/
---
---Возвращает таблицу сотрудников по отделу
CREATE OR REPLACE FUNCTION get_employees_by_dept(p_dept_id INT)
    RETURNS TABLE(
                     ename TEXT,
                     job TEXT,
                     sal NUMERIC(7,2),
                     deptno INT
                 ) AS $$
BEGIN
    RETURN QUERY
        SELECT
            emp.ename::TEXT,  -- Явное приведение к TEXT
            emp.job::TEXT,    -- Приведение и для job на всякий случай
            emp.sal,
            emp.deptno
        FROM emp
        WHERE emp.deptno = p_dept_id;
END;
$$ LANGUAGE plpgsql;

-- Использование:
SELECT * FROM get_employees_by_dept(10);

/*Функции без возвращаемого значения (процедуры)*/
-- Создаем процедуру (функция с VOID)
CREATE OR REPLACE FUNCTION log_message(msg TEXT)
    RETURNS VOID AS $$
BEGIN
    INSERT INTO logs(message, created_at)
    VALUES (msg, NOW());
END;
$$ LANGUAGE plpgsql;

-- Использование:
SELECT log_message('Система запущена');

/*Способы передачи параметров*/

-- 1. Позиционные параметры (как в примере выше)
CREATE FUNCTION func1(a INT, b INT) RETURNS INT ...

-- 2. Параметры с значениями по умолчанию
    CREATE FUNCTION func2(a INT DEFAULT 10, b INT DEFAULT 20) ...

-- 3. Именованные параметры (рекомендуется для читаемости)
    CREATE FUNCTION func3(a INT, b INT) ...
    -- Вызов: SELECT func3(a => 10, b => 20);

-- 4. VARIADIC - переменное число параметров
    CREATE FUNCTION sum_all(VARIADIC nums INT[]) RETURNS INT AS $$
DECLARE
    total INT := 0;
    num INT;
BEGIN
    FOREACH num IN ARRAY nums LOOP
        total := total + num;
    END LOOP;
    RETURN total;
END;
$$ LANGUAGE plpgsql;

/*Условные операторы*/
CREATE OR REPLACE FUNCTION get_discount(amount DECIMAL, is_regular BOOLEAN)
    RETURNS DECIMAL AS $$
DECLARE
    discount DECIMAL := 0;
BEGIN
    IF amount > 10000 THEN
        discount := 0.15;  -- 15%
    ELSIF amount > 5000 THEN
        discount := 0.10;  -- 10%
    ELSE
        discount := 0.05;  -- 5%
    END IF;

    -- Дополнительная скидка для постоянных клиентов
    IF is_regular THEN
        discount := discount + 0.05;
    END IF;

    RETURN amount * (1 - discount);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_grade(score INT)
    RETURNS TEXT AS $$
DECLARE
    grade TEXT;
BEGIN
    CASE
        WHEN score >= 90 THEN grade := 'A';
        WHEN score >= 80 THEN grade := 'B';
        WHEN score >= 70 THEN grade := 'C';
        WHEN score >= 60 THEN grade := 'D';
        ELSE grade := 'F';
        END CASE;

    RETURN grade;
END;
$$ LANGUAGE plpgsql;



/*Циклы LOOP c EXIT*/

CREATE OR REPLACE FUNCTION factorial(n INT)
    RETURNS INT AS $$
DECLARE
    result INT := 1;
    counter INT := 1;
BEGIN
    LOOP
        EXIT WHEN counter > n;
        result := result * counter;
        counter := counter + 1;
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

/*While*/

CREATE OR REPLACE FUNCTION sum_to_n(n INT)
    RETURNS INT AS $$
DECLARE
    total INT := 0;
    i INT := 1;
BEGIN
    WHILE i <= n LOOP
            total := total + i;
            i := i + 1;
        END LOOP;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

/*FOR LOOP*/

-- FOR по результату запроса
CREATE OR REPLACE FUNCTION get_employee_names()
    RETURNS TEXT AS $$
DECLARE
    emp_record RECORD;
    names TEXT := '';
BEGIN
    FOR emp_record IN
        SELECT ename, deptno
        FROM emp
        ORDER BY ename
        LOOP
            names := names || emp_record.ename || ', ' ||
                     emp_record.deptno || E'\n';
        END LOOP;

    RETURN names;
END;
$$ LANGUAGE plpgsql;

select *
from get_employee_names()

/*FOR EACH по массиву*/

CREATE OR REPLACE FUNCTION array_to_string(arr TEXT[])
    RETURNS TEXT AS $$
DECLARE
    element TEXT;
    result TEXT := '';
BEGIN
    FOREACH element IN ARRAY arr LOOP
            result := result || element || ', ';
        END LOOP;

    -- Убираем последнюю запятую и пробел
    RETURN TRIM(TRAILING ', ' FROM result);
END;
$$ LANGUAGE plpgsql;

/*Работа со строками
  Проход строки, требуется выполнить проход по строке, чтобы выполнить каждый ее символ в отдельной строке таблицы,
  хотя  операции SQL нет цикла.
  Нужно отобразить вместо king
  k
  i
  n
  g
  */

EXPLAIN ANALYZE
  select substr(e.ename, iter.pos, 1) as c
  from (select ename from emp where ename = 'KING') e,
       (select id as pos from t10) iter
  where iter.pos <= length(e.ename);

EXPLAIN ANALYZE
SELECT substr(e.ename, iter.pos, 1) as c --- e.ename, iter.pos,
FROM (SELECT ename FROM emp WHERE ename = 'KING') e
         CROSS JOIN LATERAL (
    SELECT generate_series(1, length(e.ename)) as pos
    ) iter;

EXPLAIN ANALYZE
SELECT  iter.c -----e.ename ----, iter.pos,
FROM (SELECT ename FROM emp WHERE ename = 'MILLER') e
         CROSS JOIN LATERAL (
    SELECT ordinality as pos, c
/*WITH ORDINALITY — это расширение SQL в PostgreSQL, которое добавляет порядковый номер (начиная с 1)
  к каждой строке, возвращаемой функцией, возвращающей набор (set-returning function).
-- Результат:
-- letter | pos
-- -------|----
-- A      | 1
-- B      | 2
-- C      | 3
  */
    FROM unnest(string_to_array(e.ename, NULL)) WITH ORDINALITY AS t(c, ordinality)
    ) iter;

/*Вставка кавычек в строковые константы
Количество кавычек в любой строке должно быть четным
Нужно помнить что строковая константа из двух кавычек,
не содержащая ничего между ними, представляет значение null*/

select 'g''day mate' qmarks from t1
UNION ALL
select 'beavers'' teeth' from t1
UNION ALL
select '''' from t1;

/*Подсчет количества вхождений в строку определенного символа.
  Требуется подсчитать количество вхождений символа или подстроки в заданную строку*/

/*Объяснение формулы:
LENGTH('10, CLARK, MANAGER') = длина всей строки = 19 символов
REPLACE('10, CLARK, MANAGER', ',', '') = удаляем все запятые → '10 CLARK MANAGER'
LENGTH('10 CLARK MANAGER') = длина без запятых = 17 символов
Разница: 19 - 17 = 2 символа (это запятые);
Длина разделителя LENGTH(',') = 1;

Результат: 2 / 1 = 2 запятых*/
SELECT (LENGTH('10, CLARK, MANAGER') - LENGTH(REPLACE('10, CLARK, MANAGER', ',', ''))) / LENGTH(',') AS cnt
FROM t1

/*Удаление символа из строки
  Требуется удалить из данных определенные символы*/

SELECT ename,
       REPLACE(TRANSLATE(ename, 'AEIOU', 'aeiou'), 'a', '') AS stripped1,
       ---TRANSLATE Заменяет заглавные гласные на строчные:
       ---REPLACE(..., 'a', '') Удаляет все буквы 'a' (только строчные!) из результата TRANSLATE.
       sal,
       REPLACE(CAST(sal AS char(4)), '0', '')               AS stripper2
FROM emp;

/*Разделение цифровых и символьных данных*/

SELECT
    REPLACE(
            TRANSLATE(data, '0123456789', '00000000000'),
            '0',
            ''
    ) as ename,
    CAST(
            REPLACE(
                    TRANSLATE(LOWER(data),
                              'abcdefghijklmnopqrstuvwxyz',
                              RPAD('z', 26, 'z')),
                    'z',
                    ''
            ) AS NUMERIC  -- или DECIMAL вместо INTEGER
    ) as sal
FROM (
         SELECT ename || sal as data
         FROM emp
     ) x;

----можно использовать регулярные выражения
SELECT
    REGEXP_REPLACE(data, '[0-9\.]', '', 'g') as ename,
    CAST(REGEXP_REPLACE(data, '[^0-9\.]', '', 'g') AS NUMERIC) as sal
FROM (
         SELECT ename || sal as data
         FROM emp
     ) x;

/*Содержит ли строка только буквенно-цифровые символы
  Вы хотите вернуть строки из таблицы только в том случае, когда заданный столбец не содержит никаких иных
  символов, кроме цифр и букв*/

  create view D as
      select ename as data
  from emp
  where deptno = 10
  union all
  select ename||', $'|| cast(sal as char(4)) ||'0.00' as data
  from emp
  where deptno = 20
  union all
  select ename|| cast(deptno as char(4)) as data
  from emp
  where deptno = 30;
/*
data
CLARK
KING
MILLER
SMITH, $800.0.00
JONES, $29750.00
SCOTT, $30000.00
ADAMS, $11000.00
FORD, $30000.00
ALLEN30
WARD30
MARTIN30
BLAKE30
TURNER30
JAMES30
*/
select *
from D;

select data
from d
where translate(lower(data),
    '0123456789abcdefghijklmnopqrstuvwxyz',
      rpad('a', 36, 'a')) = rpad('a', length(data),'a');

SELECT data
FROM d
WHERE data ~ '^[A-Za-z]+$';  -- только буквы от начала до конца

SELECT data
FROM d
WHERE REGEXP_REPLACE(data, '[A-Za-z]', '', 'g') = '';  -- после удаления букв ничего не осталось

/*

Оператор	Описание
~	Совпадает с регулярным выражением (регистрозависимый)
~*	Совпадает с регулярным выражением (регистронезависимый)
!~	НЕ совпадает с регулярным выражением (регистрозависимый)
!~*	НЕ совпадает с регулярным выражением (регистронезависимый)
*/

SELECT data
FROM d
WHERE data ~* '[^0-9a-z]';  -- только буквы от начала до конца

SELECT data
FROM d
WHERE data ~ '[^0-9a-zA-Z]';

SELECT data
FROM d
WHERE data !~ '[^0-9a-zA-Z]';

SELECT data
FROM d
WHERE regexp_match(data, '[^0-9a-zA-Z]') IS NOT NULL;

/*Извлечение инициалов из имен*/

SELECT REPLACE('banana', 'a', 'o');
SELECT REPLACE('Hello World', 'World', 'PostgreSQL');

-- Замена гласных
SELECT TRANSLATE('Hello World', 'aeiou', 'AEIOU');
SELECT TRANSLATE('800.00', '.', '');
-- Если строка замены короче - лишние символы удаляются!
SELECT TRANSLATE('Hello', 'Helo', '12');
-- Порядок важен!
SELECT TRANSLATE('12345', '123', 'abc');  -- 1→a, 2→b, 3→c

SELECT RPAD('Hello', 10, '*');
-- Результат: 'Hello*****'
-- Дополнение пробелами (по умолчанию)
SELECT RPAD('Hello', 10);
-- Результат: 'Hello
SELECT RPAD('Hello World', 15, '*');
-- Результат: 'Hello' (обрезается!)

-- Создание строки из повторяющихся символов
SELECT RPAD('*', 10, '*');

/*
SELECT oid, datname
FROM pg_database
WHERE oid = 16388;
*/

/*Сортировка по подстрокам необходимо упорядочить
  по последним двум символам каждой записи

Разберем выражение:
length(ename) - возвращает длину строки
length(ename)-1 - возвращает позицию предпоследнего символа
substr(ename, length(ename)-1) - извлекает подстроку, начиная с предпоследнего символа до конца строки, то есть последние два симво

*/

select ename,substr(ename, length(ename)-1)
from emp
order by substr(ename, length(ename)-1);

/*Сортировка по числу в строке*/

create view a as
select e.ename ||' '|| cast(e.empno as char(4)) ||' '|| d.dname as data
from emp e, dept d
where e.deptno = d.deptno;

select *
from a;

SELECT data,
       CAST(
               REPLACE(
                       TRANSLATE(data,
                                 REPLACE(
                                         TRANSLATE(data, '0123456789', '##########'),
                                         '#', ''), RPAD('#', 20, '#'))
                   , '#', '') AS integer) AS int
FROM v
ORDER BY CAST(
                 REPLACE(
                         TRANSLATE(data,
                                   REPLACE(
                                           TRANSLATE(data, '0123456789', '##########'),
                                           '#', ''), RPAD('#', 20, '#'))
                     , '#', '') AS integer);

/*Создание из строк таблицы списка с разделителями*/

SELECT deptno,
       STRING_AGG(ename, ',' ORDER BY empno) as emps
FROM emp
GROUP BY deptno;

/*Упорядочивание строки по алфавиту
  требуется отсортировать символы строк таблицы в алфавитном порядке*/


SELECT
    a.ename,
    string_agg(c, '' ORDER BY c) as sorted_chars
FROM emp a
         CROSS JOIN LATERAL (
    SELECT generate_series(1, length(a.ename)) as pos
    ) iter
         CROSS JOIN LATERAL (
    SELECT substr(a.ename, iter.pos, 1) as c
    ) char_extract
GROUP BY a.ename
ORDER BY a.ename;

/*Парсинг IP-адреса требуется произвести парсинг адреса
  и поместить значения полей в отдельные столбцы таблицы

Функция split_part(text, delimiter, field_number):
y.ip - исходная строка (IP-адрес)
'.' - разделитель (точка в IP-адресе)
1 - номер части (нумерация с 1)
Возвращает: первую часть строки после разбиения по разделителю

*/

select
    split_part(y.ip,'.',1) as a,
    split_part(y.ip,'.',2) as b,
    split_part(y.ip,'.',3) as c,
    split_part(y.ip,'.',4) as d
from (select cast('92.111.0.2' as text) as ip from t1) as y

/*Операции с числами*/

select  avg(sal) as avg_sal
from emp;

select deptno, avg(sal) as avg_sal
from emp
group by deptno;

/*Определение минимального или максимального значения столбца*/

select deptno, min(sal) as min_sal, max(sal) as max_sal,  round(avg(sal),2) as avg_sal
from emp
group by deptno;

/*Суммирование значений столбца когда группой или окном является вся таблица
*/

select sum(sal) as total_for_dept
from emp;

/*Вычисление подсумм или нескольких групп или окон данных*/
select deptno, sum(sal) as total_for_dept
from emp
group by deptno;

/*Подсчет строк в таблице
  Функция count игнорирует null если к качестве аргумента передается столбце, но учитывает null, если
  в качестве аргумента в count передается "*"  или любая константа */

select deptno,comm
from emp;

select count(*), count(deptno), count(comm), count('hello')
from emp;


select deptno, count(*)
from emp
group by deptno;

/*Подсчет значений столбца подсчитаем количество комиссионных в каждом отделе, если указывается
  столбец,то null значения не рассчитываются*/

select deptno, count(comm)
from emp
group by deptno;

/*Вычисление текущей суммы
  заработной платы для всех служащих
  c нарастающим итогом
*/

select ename,
       sal,
       sum(sal) over (order by sal, empno) as running_total, ----указываем столбец первичного ключа empno чтобы не было дублей!!!
       sum(sal) over (order by sal) as running_total_2
from emp
order by sal;


/*Сглаживание последовательности значений,
  необходимо определить общую тенденцию продаж, то есть
  убрать колебания, которые усложняют выявления скрытых тенденций
  можно применить метод скользящего среднего, складывая n-значение с предыдущим n-1 и разделив
  полученную сумму на n*/


-- Таблица для расчета скользящего среднего
drop table sales;
CREATE TABLE sales (
                       date1 DATE PRIMARY KEY,
                       sales DECIMAL(10,2) NOT NULL
);

INSERT INTO sales (date1, sales) VALUES
                                          ('2023-01-01', 647),
                                          ('2023-01-02', 561),
                                          ('2023-01-03', 741),
                                          ('2023-01-04', 978),
                                          ('2023-01-05', 1062),
                                          ('2023-01-06', 1072),
                                          ('2023-01-07', 805),
                                          ('2023-01-08', 662),
                                          ('2023-01-09', 1083),
                                          ('2023-01-10', 970);

select date1, sales, lag(sales,1) over(order by date1) as salesLagOne,
       lag(sales,2) over(order by date1) as salesLagTwo,
       (sales + (lag(sales, 1) over(order by date1))
     +  lag(sales, 2) over(order by date1)) / 3 as MovingAverage
from sales;

/*Вычисление моды
  мода - это элемент с наибольшим количеством вхождений в рассматриваемый набор данных
  например моду зарплат отдела 20

sal
800.00
1100.00
2975.00
3000.00
3000.00

В этом наборе данных модой является 3000.00, так как это значение встречается чаще всего (2 раза),
в то время как остальные значения уникальным*/

  select sal
  from emp
  where deptno = 20
  order by sal;

SELECT MODE() WITHIN GROUP (ORDER BY sal) as modal_salary
FROM emp
WHERE deptno = 20;


SELECT sal
FROM (
         SELECT
             sal,
             DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) as rnk
         FROM emp
         WHERE deptno = 20
         GROUP BY sal
     ) t
WHERE rnk = 1;


/*Вычисление медианы (значение среднего элемента
упорядоченного множества)*/

SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sal) as median_salary
FROM emp
WHERE deptno = 20;

WITH dept20 AS (
    SELECT sal FROM emp WHERE deptno = 20
)
SELECT 'Среднее' as metric, AVG(sal) as value FROM dept20
UNION ALL
SELECT 'Медиана (CONT)', PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sal) FROM dept20
UNION ALL
SELECT 'Медиана (DISC)', PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY sal) FROM dept20
UNION ALL
SELECT 'Мода', MODE() WITHIN GROUP (ORDER BY sal) FROM dept20;


/*Вычисление процентной доли от целого
определить процентную долю суммы определенной группы значений столбца от общей суммы столбца
*/

select
    (sum(
             case when deptno = 10 then sal end) / sum(sal)
        ) * 100 as pct,
    sum(sal) as sum_sal_total,
    sum(case when deptno = 10 then sal end) as sum_sal_d10,
    round(sum(case when deptno = 10 then sal end) / sum(sal) * 100,2) as pct_rasch
    from emp;

/*Агрегация столбцов, содержащих значения null*/

select
    avg(coalesce(comm,0)) as avg_comm,
    avg(comm) as avg_comm_no_correct ----игнорируются значения null
from emp
WHERE deptno = 30;

/*Вычисление среднего без учета крайних значений
требуется вычислить среднее значение не учитывая наибольшее и наименьшее значение, чтобы
попытаться уменьшить ассиметрию распределения
Такое среднее называется усеченным*/

select avg(sal)
from emp
where sal not in (
    (select min(sal) from emp),
    (select max(sal) from emp)
);


/*если нужно исключить все min/max */
SELECT AVG(sal) as avg_without_min_max
FROM emp
WHERE sal NOT IN (
    SELECT MIN(sal) FROM emp
    UNION ALL
    SELECT MAX(sal) FROM emp
);


-- Исключаем по одному минимальному и максимальному значению
SELECT AVG(sal)
FROM (
         SELECT sal,
                ROW_NUMBER() OVER (ORDER BY sal ASC)  as rn_asc,
                ROW_NUMBER() OVER (ORDER BY sal DESC) as rn_desc
         FROM emp
     ) t
WHERE rn_asc > 1 AND rn_desc > 1;


/*Изменение значений в текущей сумме*/

create view e (id, amt, trx)
as
select 1, 100, 'PR'
from t1
union all

select 2, 100, 'PR'
from t1
union all

select 3, 50, 'PY'
from t1
union all

select 4, 100, 'PR'
from t1
union all

select 5, 200, 'PY'
from t1
union all

select 6, 50, 'PY'
from t1;


select
    case when trx = 'PY'
then 'PAYMENT'
else 'PURCHASE'
end as trx_type,
amt,
case when trx = 'PY'
    then (-amt)
    else amt end as balance
from e;


select
    case when trx = 'PY'
             then 'PAYMENT'
         else 'PURCHASE'
        end as trx_type,
    amt,
    sum(case when trx = 'PY'
             then (-amt)
         else amt end) over (order by id,amt) as balance,
    case when trx = 'PY'
             then (-amt)
         else amt end as amt_real
from e;


/*Обнаруживаем аномальные значения используя закон Бенфорда
  Закон Бенфорда — это закономерность распределения первых цифр в реальных наборах числовых данных.
  Он гласит, что в естественно возникающих наборах
  чисел цифра 1 встречается на первом месте примерно в 30% случаев,
  а каждая последующая цифра встречается реже.
*/

WITH
first_digits(first_digit) as
    (select left(cast(sal as char),1 ) as first_digit
     from emp),



select *
from emp

total_count(total) as
(select count(*) as total
 from emp),

expected_benford (digit, expected) as
    (select id as digit, (log10(id+1) - log10(id)) as expected
         from t10
         where id < 10)

select count(first_digit),
       digit,
       COALESCE(COUNT(fd.first_digit)::DECIMAL / NULLIF(tc.total, 0), 0) as actual_proportion,
       eb.expected
    FROM first_digits fd
    cross JOIN total_count tc
    RIGHT JOIN  expected_benford eb on fd.first_digit::INTEGER = eb.digit
group by eb.digit, eb.expected,tc.total
order by eb.digit;


-- Хи-квадрат тест для ваших данных
WITH
    first_digits(first_digit) as
        (select left(cast(sal as char),1 ) as first_digit
         from emp),

    total_count(total) as
        (select count(*) as total
         from emp),

    expected_benford (digit, expected) as
        (select id as digit, (log10(id+1) - log10(id)) as expected
         from t10
         where id < 10),

observed AS (
    SELECT digit, COUNT(fd.first_digit) as observed
    FROM expected_benford eb
             LEFT JOIN first_digits fd ON fd.first_digit::INTEGER = eb.digit
    GROUP BY digit
),
     expected AS (
         SELECT digit, expected * 14 as expected_count  -- 14 = общее количество записей
         FROM expected_benford
     )
SELECT
    SUM(POWER(o.observed - e.expected_count, 2) / e.expected_count) as chi_square,
    CASE
        WHEN SUM(POWER(o.observed - e.expected_count, 2) / e.expected_count) > 15.51
            THEN 'Отклоняем гипотезу (p < 0.05)'
        ELSE 'Не отклоняем гипотезу'
        END as conclusion
FROM observed o
         JOIN expected e ON o.digit = e.digit;



-- ЗАКОН БЕНФОРДА ДЛЯ ЗАРПЛАТ (SAL) ИЗ ТАБЛИЦЫ EMP
WITH
    first_digits AS (
        SELECT LEFT(CAST(sal AS VARCHAR), 1)::INTEGER as first_digit
        FROM emp
        WHERE sal >= 1 AND sal IS NOT NULL
    ),
    total_count AS (
        SELECT COUNT(*) as total_records FROM first_digits
    ),
    digit_stats AS (
        SELECT
            first_digit,
            COUNT(*) as frequency,
            COUNT(*)::NUMERIC / (SELECT total_records FROM total_count) as actual_proportion
        FROM first_digits
        GROUP BY first_digit
    ),
    benford_law AS (
        SELECT
            digit,
            -- Явно приводим к NUMERIC здесь
            (LOG(1 + 1.0/digit) / LOG(10))::NUMERIC as expected_proportion
        FROM generate_series(1, 9) digit
    )
SELECT
    bl.digit as "Первая цифра",
    COALESCE(ds.frequency, 0) as "Частота",
    tc.total_records as "Всего записей",
    ROUND(COALESCE(ds.actual_proportion, 0) * 100, 2) as "Факт %",
    ROUND(bl.expected_proportion * 100, 2) as "Бенфорд %",
    ROUND(ABS(COALESCE(ds.actual_proportion, 0) - bl.expected_proportion) * 100, 2) as "Отклонение %",
    CASE
        WHEN COALESCE(ds.frequency, 0) = 0 THEN '❌ Отсутствует'
        WHEN ABS(COALESCE(ds.actual_proportion, 0) - bl.expected_proportion) * 100 < 5 THEN '✅ Норма'
        WHEN ABS(COALESCE(ds.actual_proportion, 0) - bl.expected_proportion) * 100 < 10 THEN '⚠ Внимание'
        ELSE '❌ Сильное отклонение'
        END as "Оценка"
FROM benford_law bl
         CROSS JOIN total_count tc
         LEFT JOIN digit_stats ds ON bl.digit = ds.first_digit
ORDER BY bl.digit;

/*Арифметические операции с датами*/

/*Сложение и вычитание дней месяцев и лет*/

select hiredate,
       hiredate - interval '5 day' as hd_minus_5d,
       hiredate + interval '5 day' as hd_plus_5d,
       hiredate - interval '5 month' as hd_minus_5M,
       hiredate + interval '5 month' as hd_plus_5M,
       hiredate - interval '5 year' as hd_minus_5Y,
       hiredate + interval '5 year' as hd_plus_5Y
from emp
where deptno = 10;

/*Вычисление количества дней между двумя датами*/

SELECT x.ward_hd - y.allen_hd
FROM (SELECT hiredate AS ward_hd
      FROM emp
      WHERE ename = 'WARD') AS x
         CROSS JOIN
     (SELECT hiredate AS allen_hd
      FROM emp
      WHERE ename = 'ALLEN') AS y;

SELECT x.ward_hd - y.allen_hd
FROM (SELECT hiredate AS ward_hd
      FROM emp
      WHERE ename = 'WARD') AS x,
     (SELECT hiredate AS allen_hd
      FROM emp
      WHERE ename = 'ALLEN') AS y;

/*Вычисление рабочих дней между двумя датами*/


WITH dates AS (
    SELECT
        (SELECT hiredate FROM emp WHERE ename = 'BLAKE') as end_date,
        (SELECT hiredate FROM emp WHERE ename = 'JONES') as start_date
),
     working_days AS (
         SELECT COUNT(*) as workdays_count
         FROM generate_series(
                      (SELECT start_date FROM dates),
                      (SELECT end_date FROM dates),
                      '1 day'::interval
              ) as day
         WHERE EXTRACT(DOW FROM day) NOT IN (0, 6)  -- Не воскресенье (0) и не суббота (6)
     )
SELECT workdays_count FROM working_days;


SELECT COUNT(*) as working_days
FROM generate_series(
             (SELECT hiredate FROM emp WHERE ename = 'JONES'),
             (SELECT hiredate FROM emp WHERE ename = 'BLAKE'),
             '1 day'
     ) as day
WHERE EXTRACT(DOW FROM day) NOT IN (0, 6);

/*Вычисление количества месяцев или лет между двумя датами*/

SELECT
    mnth as total_months,
    mnth / 12 as total_years
FROM (
         SELECT
             (EXTRACT(YEAR FROM max_hd) - EXTRACT(YEAR FROM min_hd)) * 12
                 +
             (EXTRACT(MONTH FROM max_hd) - EXTRACT(MONTH FROM min_hd)) as mnth
         FROM (
                  SELECT
                      MIN(hiredate) as min_hd,
                      MAX(hiredate) as max_hd
                  FROM emp
              ) x
     ) y;


SELECT
    MIN(hiredate) as first_hire,
    MAX(hiredate) as last_hire,
    DATE_PART('year', AGE(MAX(hiredate), MIN(hiredate))) as years_diff,
    DATE_PART('month', AGE(MAX(hiredate), MIN(hiredate))) as months_diff,
    DATE_PART('year', AGE(MAX(hiredate), MIN(hiredate))) * 12 + DATE_PART('month', AGE(MAX(hiredate), MIN(hiredate))) as total_months
FROM emp;


/* Находим самого первого и самого последнего сотрудника */
WITH first_last AS (
    SELECT
        MIN(hiredate) as first_hire_date,
        MAX(hiredate) as last_hire_date
    FROM emp
)

/* Считаем разницу в годах и месяцах */
SELECT
    first_hire_date,
    last_hire_date,
    -- Используем функцию AGE для расчета разницы
    AGE(last_hire_date, first_hire_date) as time_difference,
    -- Извлекаем отдельно годы и месяцы
    EXTRACT(YEAR FROM AGE(last_hire_date, first_hire_date)) as years,
    EXTRACT(MONTH FROM AGE(last_hire_date, first_hire_date)) as months
FROM first_last;


/* ШАГ 1: Кто был нанят первым, а кто последним? */
SELECT
    'Самый первый сотрудник' as info,
    ename as имя,
    hiredate as дата_найма
FROM emp
WHERE hiredate = (SELECT MIN(hiredate) FROM emp)

UNION ALL

SELECT
    'Самый последний сотрудник',
    ename,
    hiredate
FROM emp
WHERE hiredate = (SELECT MAX(hiredate) FROM emp)

ORDER BY дата_найма;

/* ШАГ 2: Сколько времени между ними? */
SELECT
    first_hire.имя as первый_сотрудник,
    first_hire.дата_приема as дата_первого,
    last_hire.имя as последний_сотрудник,
    last_hire.дата_приема as дата_последнего,
    last_hire.дата_приема - first_hire.дата_приема as дней_между,
    CONCAT(
            EXTRACT(YEAR FROM AGE(last_hire.дата_приема, first_hire.дата_приема)), ' лет ',
            EXTRACT(MONTH FROM AGE(last_hire.дата_приема, first_hire.дата_приема)), ' месяцев ',
            EXTRACT(DAY FROM AGE(last_hire.дата_приема, first_hire.дата_приема)), ' дней'
    ) as разница_во_времени
FROM
    (SELECT ename as имя, hiredate as дата_приема
     FROM emp WHERE hiredate = (SELECT MIN(hiredate) FROM emp)) first_hire,
    (SELECT ename as имя, hiredate as дата_приема
     FROM emp WHERE hiredate = (SELECT MAX(hiredate) FROM emp)) last_hire;



WITH data AS (
    SELECT
        MIN(hiredate) as min_date,
        MAX(hiredate) as max_date
    FROM emp
)
SELECT
    (SELECT ename FROM emp WHERE hiredate = min_date) as "Первый",
    min_date as "Дата первого",
    (SELECT ename FROM emp WHERE hiredate = max_date) as "Последний",
    max_date as "Дата последнего",
    max_date - min_date as "Дней между",
    -- Секунды
    (max_date - min_date) * 24 * 60 * 60 as "Секунд",
    -- Минуты
    (max_date - min_date) * 24 * 60 as "Минут",
    -- Часы
    (max_date - min_date) * 24 as "Часов"
FROM data;

/*Вычисление разницы в днях между датами двух записей*/

SELECT x.*, x.next_hd - x.hiredate AS diff
FROM (SELECT e.deptno,
             e.ename,
             e.hiredate,
             LEAD(e.hiredate) OVER (ORDER BY e.hiredate) AS next_hd
      FROM emp e
      WHERE e.deptno = 10) x;

/*Определение високосного года*/

SELECT MAX(TO_CHAR(tmp2.dy + x.id, 'DD')) AS dy
FROM (SELECT dy, TO_CHAR(dy, 'MM') AS mth
      FROM (SELECT CAST(CAST(DATE_TRUNC('year', CURRENT_DATE) AS date) + INTERVAL '1 month' AS date) AS dy
            FROM t1)
          tmp1) tmp2
    CROSS JOIN GENERATE_SERIES(0, 29) x(id)
WHERE TO_CHAR(tmp2.dy + x.id, 'MM') = tmp2.mth;

/*Определение количества дней в году
  это разница между первым днем следующего года и первым днем текущего года*/

SELECT CAST((x.curr_year + INTERVAL '1 year') AS date) - x.curr_year
FROM (SELECT CAST(DATE_TRUNC('year', CURRENT_DATE) AS date) AS curr_year
      FROM t1) x

/*Извлечение из даты единиц времени*/
with
    dt as (
        select current_timestamp as tsm
    ),
   extractdt as (
       select to_number(to_char(dt.tsm,'hh24'),'99')   as hh,
              to_number(to_char(dt.tsm,'mi'),'99')     as min,
              to_number(to_char(dt.tsm,'ss'),'99')     as sec,
              to_number(to_char(dt.tsm,'dd'),'99')     as day,
              to_number(to_char(dt.tsm,'mm'),'99')     as mth,
              to_number(to_char(dt.tsm,'yyyy'),'9999') as yr
       FROM dt
   )

select *
from extractdt
