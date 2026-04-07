/******************************************************************************/
/*** Create DataBase ***/
/******************************************************************************/
CREATE DATABASE "abonent" WITH OWNER "postgres" ENCODING 'UTF8';


DO $$
    DECLARE
        tables_to_drop TEXT[] := ARRAY[
            'street',
            'services',
            'disrepair',
            'executor',
            'abonent',
            'nachislsumma',
            'paysumma',
            'request'
            ];
        seqs_to_drop TEXT[] := ARRAY[
            'gen_street',
            'gen_services',
            'gen_disrepair',
            'gen_executor',
            'gen_nachislsumma',
            'gen_paysumma',
            'gen_request'
            ];
        t TEXT;
    BEGIN
        FOREACH t IN ARRAY tables_to_drop LOOP
                EXECUTE format('DROP TABLE IF EXISTS %s CASCADE', t);
            END LOOP;
        FOREACH t IN ARRAY seqs_to_drop LOOP
                EXECUTE format('DROP SEQUENCE IF EXISTS %s CASCADE', t);
            END LOOP;
    END;
$$;

CREATE SCHEMA IF NOT EXISTS abonent;
/******************************************************************************/
/*** Domains ***/
/******************************************************************************/
CREATE DOMAIN Currency AS
    NUMERIC(15,2);
CREATE DOMAIN Pkfield AS
    INTEGER -- NOT NULL;
CREATE DOMAIN Tmonth AS
    SMALLINT
    CHECK (VALUE BETWEEN 1 AND 12);
CREATE DOMAIN Tyear AS
    SMALLINT
    CHECK (VALUE BETWEEN 1990 AND 2100);
/******************************************************************************/
/*** Generators ***/
/******************************************************************************/
CREATE SEQUENCE Gen_disrepair START WITH 13 INCREMENT BY 1;
CREATE SEQUENCE Gen_executor START WITH 7 INCREMENT BY 1;
CREATE SEQUENCE Gen_nachislsumma START WITH 80 INCREMENT BY 1;
CREATE SEQUENCE Gen_paysumma START WITH 79 INCREMENT BY 1;
CREATE SEQUENCE Gen_request START WITH 24 INCREMENT BY 1;
CREATE SEQUENCE Gen_services START WITH 5 INCREMENT BY 1;
CREATE SEQUENCE Gen_street START WITH 9 INCREMENT BY 1;
/******************************************************************************/
/*** Tables ***/
/******************************************************************************/
CREATE TABLE Abonent (
                         Accountid VARCHAR(6),
                         Streetid SMALLINT,
                         Houseno SMALLINT,
                         Flatno SMALLINT,
                         Fio VARCHAR(20),
                         Phone VARCHAR(15)
);
CREATE TABLE Disrepair (
                           Failureid PKFIELD,
                           Failurenm VARCHAR(50)
);
CREATE TABLE Executor (
                          Executorid  PKFIELD,
                          FIO VARCHAR(20)
);
CREATE TABLE Nachislsumma (
                              Nachislfactid PKFIELD,
                              Accountid VARCHAR(6) NOT NULL,
                              Serviceid PKFIELD NOT NULL,
                              Nachislsum CURRENCY,
                              Nachislmonth TMONTH,
                              Nachislyear TYEAR
);
CREATE TABLE Paysumma (
                          Payfactid PKFIELD,
                          Accountid VARCHAR(6) NOT NULL,
                          Serviceid PKFIELD NOT NULL,
                          Paysum CURRENCY,
                          Paydate DATE,
                          Paymonth TMONTH,
                          Payyear TYEAR
);
CREATE TABLE Request (
                         Requestid PKFIELD,
                         Accountid VARCHAR(6) NOT NULL,
                         Executorid INTEGER,
                         Failureid INTEGER NOT NULL,
                         Incomingdate DATE DEFAULT CURRENT_DATE NOT NULL,
                         Executiondate DATE,
                         Executed BOOLEAN DEFAULT FALSE NOT NULL
);
CREATE TABLE Services (
                          Serviceid PKFIELD,
                          Servicenm VARCHAR(30)
);
CREATE TABLE Street (
                        Streetid SMALLINT,
                        Streetnm VARCHAR(30)
);
INSERT INTO Street (Streetid, Streetnm) VALUES (1, 'ЦИОЛКОВСКОГО УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (2, 'НОВАЯ УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (3, 'ВОЙКОВ ПЕРЕУЛОК');
INSERT INTO Street (Streetid, Streetnm) VALUES (4, 'ТАТАРСКАЯ УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (5, 'ГАГАРИНА УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (6, 'МОСКОВСКАЯ УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (7, 'КУТУЗОВА УЛИЦА');
INSERT INTO Street (Streetid, Streetnm) VALUES (8, 'МОСКОВСКОЕ ШОССЕ');

INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('005488', 3, 4, 1, 'Аксенов С. А.', '556893');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('115705', 3, 1, 82, 'Мищенко Е. В.', '769975');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('015527', 3, 1, 65, 'Конюхов В. С.', '761699');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('443690', 7, 5, 1, 'Тулупова М. И.', '214833');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('136159', 7, 39, 1, 'Свирина З. А.', NULL);
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('443069', 4, 51, 55, 'Стародубцев Е. В.', '683014');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('136160', 4, 9, 15, 'Шмаков С. В.', NULL);
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('126112', 4, 7, 11, 'Маркова В. П.', '683301');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('136169', 4, 7, 13, 'Денисова Е. К.', '680305');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('080613', 8, 35, 11, 'Лукашина Р. М.', '254417');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('080047', 8, 39, 36, 'Шубина Т. П.', '257842');
INSERT INTO Abonent (Accountid, Streetid, Houseno, Flatno, FIO, Phone) VALUES ('080270', 6, 35, 6, 'Тимошкина Н. Г.', '321002');

INSERT INTO Disrepair (Failureid, Failurenm) VALUES (1, 'Засорилась водогрейная колонка');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (2, 'Не горит АГВ');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (3, 'Течет из водогрейной колонки');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (4, 'Неисправна печная горелка');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (5, 'Неисправен газовый счетчик');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (6, 'Плохое поступление газа на горелку плиты');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (7, 'Туго поворачивается пробка крана плиты');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (8, 'При закрытии краника горелка плиты не гаснет');
INSERT INTO Disrepair (Failureid, Failurenm) VALUES (12, 'Неизвестна');

INSERT INTO Executor (Executorid , FIO) VALUES (1, 'Стародубцев Е. М.');
INSERT INTO Executor (Executorid , FIO) VALUES (2, 'Булгаков Т. И.');
INSERT INTO Executor (Executorid , FIO) VALUES (3, 'Шубин В. Г.');
INSERT INTO Executor (Executorid , FIO) VALUES (4, 'Шлюков М. К.');
INSERT INTO Executor (Executorid , FIO) VALUES (5, 'Школьников С. М.');
INSERT INTO Executor (Executorid , FIO) VALUES (6, 'Степанов А. В.');

INSERT INTO Services (Serviceid, Servicenm) VALUES (1, 'Газоснабжение');
INSERT INTO Services (Serviceid, Servicenm) VALUES (2, 'Электроснабжение');
INSERT INTO Services (Serviceid, Servicenm) VALUES (3, 'Теплоснабжение');
INSERT INTO Services (Serviceid, Servicenm) VALUES (4, 'Водоснабжение');

INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (1, '136160', 2, 656, 1, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (2, '005488', 2, 646, 12, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (3, '005488', 2, 656, 4, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (4, '115705', 2, 640, 1, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (5, '115705', 2, 850, 9, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (6, '136160', 1, 518.3, 1, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (7, '080047', 2, 680, 10, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (8, '080047', 2, 680, 10, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (9, '080270', 2, 646, 12, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (10, '080613', 2, 656, 6, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (11, '115705', 2, 850, 9, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (12, '115705', 2, 658.7, 8, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (13, '136160', 2, 620, 5, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (15, '136169', 2, 620, 5, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (16, '136169', 2, 658.7, 11, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (17, '443069', 2, 680, 9, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (18, '443069', 2, 638.5, 8, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (19, '005488', 2, 658.7, 12, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (20, '015527', 1, 528.32, 7, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (21, '080047', 1, 519.56, 3, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (22, '080613', 1, 510.6, 9, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (23, '443069', 1, 538.28, 12, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (24, '015527', 1, 538.32, 4, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (25, '115705', 1, 537.15, 10, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (26, '080613', 1, 512.6, 8, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (27, '136169', 1, 525.32, 1, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (28, '080270', 1, 557.1, 2, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (29, '136159', 1, 508.3, 8, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (30, '005488', 1, 562.13, 4, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (31, '115705', 1, 537.8, 5, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (32, '443690', 1, 517.8, 6, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (33, '080047', 1, 522.56, 5, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (34, '126112', 1, 515.3, 8, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (35, '080047', 1, 532.56, 9, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (36, '080613', 1, 512.6, 4, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (37, '115705', 1, 537.15, 11, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (38, '080270', 1, 558.1, 12, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (39, '136169', 1, 528.32, 1, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (40, '015527', 1, 518.32, 2, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (41, '443690', 1, 521.67, 3, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (42, '080613', 1, 522.86, 4, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (43, '080270', 1, 560.1, 5, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (44, '136169', 1, 528.32, 2, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (45, '080047', 1, 522.2, 7, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (46, '126112', 1, 525.3, 8, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (47, '443069', 1, 538.32, 9, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (48, '136159', 1, 508.3, 10, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (49, '115705', 1, 537.15, 6, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (50, '136160', 1, 518.3, 12, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (51, '005488', 3, 2279.8, 5, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (52, '005488', 3, 2266.7, 2, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (53, '015527', 3, 2343.36, 11, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (54, '080047', 3, 2271.6, 2, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (55, '080270', 3, 2278.25, 11, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (56, '080613', 3, 2254.4, 7, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (57, '080613', 3, 2258.8, 2, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (58, '080613', 3, 2239.33, 5, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (59, '126112', 3, 2179.9, 4, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (60, '136159', 3, 2180.13, 9, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (61, '136160', 3, 2238.8, 3, 2022);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (62, '136160', 3, 2237.38, 3, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (63, '136169', 3, 2349.19, 6, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (64, '136169', 3, 2346.18, 7, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (65, '443690', 3, 2290.33, 3, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (66, '015527', 4, 280.1, 7, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (67, '015527', 4, 311.3, 10, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (68, '080270', 4, 144.34, 3, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (69, '080270', 4, 153.43, 6, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (70, '080270', 4, 154.6, 4, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (71, '115705', 4, 253.85, 1, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (72, '126112', 4, 135.5, 6, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (73, '136159', 4, 49.38, 4, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (74, '136159', 4, 118.88, 6, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (75, '136169', 4, 228.44, 10, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (76, '443069', 4, 166.69, 5, 2024);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (77, '443069', 4, 144.45, 10, 2025);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (78, '443690', 4, 180.88, 8, 2023);
INSERT INTO Nachislsumma (Nachislfactid, Accountid, Serviceid, Nachislsum, Nachislmonth, Nachislyear) VALUES (79, '443690', 4, 200.13, 9, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (1, '005488', 2, 658.7, '2024-01-08', 12, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (2, '005488', 2, 640, '2023-01-06', 12, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (3, '005488', 2, 656, '2025-05-06', 4, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (4, '115705', 2, 640, '2022-02-10', 1, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (5, '115705', 2, 850, '2023-10-03', 9, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (6, '136160', 2, 620, '2023-06-13', 5, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (7, '136160', 2, 656, '2025-02-12', 1, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (8, '136169', 2, 620, '2023-06-22', 5, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (9, '080047', 2, 680, '2024-11-26', 10, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (10, '080047', 2, 680, '2023-11-21', 10, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (11, '080270', 2, 630, '2024-01-03', 12, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (12, '080613', 2, 658.5, '2023-07-19', 6, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (13, '115705', 2, 850, '2022-10-06', 9, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (14, '115705', 2, 658.7, '2023-09-04', 8, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (15, '136169', 2, 658.7, '2023-12-01', 11, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (16, '443069', 2, 680, '2023-10-03', 9, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (17, '443069', 2, 638.5, '2023-09-13', 8, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (18, '136160', 1, 518, '2024-02-05', 1, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (19, '015527', 1, 530, '2024-08-03', 7, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (20, '080047', 1, 519.56, '2024-04-02', 3, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (21, '080613', 1, 511, '2024-10-03', 9, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (22, '443069', 1, 538.28, '2025-02-04', 12, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (23, '015527', 1, 540, '2025-05-07', 4, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (24, '115705', 1, 537.15, '2025-11-04', 10, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (25, '080613', 1, 512, '2022-09-20', 8, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (26, '136169', 1, 525.32, '2025-02-03', 1, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (27, '080270', 1, 560, '2024-03-05', 2, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (28, '136159', 1, 508.3, '2025-09-10', 8, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (29, '005488', 1, 565, '2022-05-03', 4, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (30, '115705', 1, 537.8, '2023-07-12', 5, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (31, '443690', 1, 520, '2024-07-10', 6, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (32, '080047', 1, 522.56, '2025-06-25', 5, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (33, '126112', 1, 515.3, '2022-09-08', 8, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (34, '080047', 1, 532.56, '2023-10-18', 9, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (35, '080613', 1, 512.6, '2024-05-22', 4, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (36, '115705', 1, 537.15, '2025-12-23', 11, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (37, '080270', 1, 558.1, '2023-01-07', 12, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (38, '136169', 1, 528.32, '2023-02-08', 1, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (39, '015527', 1, 520, '2024-03-18', 2, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (40, '443690', 1, 519.47, '2025-04-10', 3, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (41, '080613', 1, 522.86, '2022-05-04', 4, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (42, '080270', 1, 560, '2023-06-07', 5, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (43, '136169', 1, 528.32, '2024-03-05', 2, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (44, '080047', 1, 522.2, '2025-08-10', 7, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (45, '126112', 1, 525.3, '2023-09-10', 8, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (46, '443069', 1, 538.32, '2023-10-09', 9, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (47, '136159', 1, 508.3, '2024-11-14', 10, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (48, '115705', 1, 537.15, '2025-08-10', 6, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (49, '136160', 1, 516, '2023-01-07', 12, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (50, '005488', 3, 2280, '2024-06-10', 5, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (51, '005488', 3, 2260, '2025-03-11', 2, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (52, '015527', 3, 2345, '2025-12-15', 11, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (53, '080047', 3, 2271.6, '2025-03-12', 2, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (54, '080270', 3, 2278, '2025-12-06', 11, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (55, '080613', 3, 2254.4, '2023-08-10', 7, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (56, '080613', 3, 2258.8, '2025-03-08', 2, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (57, '080613', 3, 2239.35, '2025-06-11', 5, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (58, '126112', 3, 2179.9, '2024-05-01', 4, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (59, '136159', 3, 2180.13, '2025-10-21', 9, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (60, '136160', 3, 2240, '2022-04-04', 3, 2022);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (61, '136160', 3, 2200, '2023-04-06', 3, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (62, '136169', 3, 2349.19, '2024-07-14', 6, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (63, '136169', 3, 2346.18, '2024-08-13', 7, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (64, '443690', 3, 2295, '2025-04-09', 3, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (65, '015527', 4, 280.1, '2024-08-08', 7, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (66, '015527', 4, 311.3, '2025-11-03', 10, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (67, '080270', 4, 144.5, '2023-04-18', 3, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (68, '080270', 4, 150, '2024-07-14', 6, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (69, '080270', 4, 160, '2025-05-12', 4, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (70, '115705', 4, 253.85, '2024-02-02', 1, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (71, '126112', 4, 135.5, '2024-07-12', 6, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (72, '136159', 4, 49.38, '2023-05-18', 4, 2023);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (73, '136159', 4, 120, '2024-07-09', 6, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (74, '136169', 4, 228.44, '2025-11-26', 10, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (75, '443069', 4, 166.69, '2024-06-03', 5, 2024);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (76, '443069', 4, 144.45, '2025-11-16', 10, 2025);
INSERT INTO Paysumma (Payfactid, Accountid, Serviceid, Paysum, Paydate, Paymonth, Payyear) VALUES (77, '443690', 4, 185, '2023-09-05', 8, 2023);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (1, '005488', 1, 1, '2023-12-17', '2023-12-20', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (2, '115705', 3, 1, '2023-08-07', '2023-08-12', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (3, '015527', 1, 12, '2024-02-28', '2024-03-08', FALSE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (5, '080270', 4, 1, '2023-12-31', NULL, FALSE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (6, '080613', 1, 6, '2023-06-16', '2023-06-24', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (7, '080047', 3, 2, '2024-10-20', '2024-10-24', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (9, '136169', 2, 1, '2023-11-06', '2023-11-08', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (10, '136159', 3, 12, '2023-04-01', '2023-04-03', FALSE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (11, '136160', 1, 6, '2025-01-12', '2025-01-12', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (12, '443069', 5, 2, '2023-08-08', '2023-08-10', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (13, '005488', 5, 8, '2022-09-04', '2022-12-05', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (14, '005488', 4, 6, '2025-04-04', '2025-04-13', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (15, '115705', 4, 5, '2022-09-20', '2022-09-23', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (16, '115705', NULL, 3, '2023-12-28', NULL, FALSE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (17, '115705', 1, 5, '2023-08-15', '2023-09-06', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (18, '115705', 2, 3, '2024-12-28', '2025-01-04', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (19, '080270', 4, 8, '2023-12-17', '2023-12-27', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (20, '080047', 3, 2, '2023-10-11', '2023-10-11', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (21, '443069', 1, 2, '2023-09-13', '2023-09-14', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (22, '136160', 1, 7, '2023-05-18', '2023-05-25', TRUE);
INSERT INTO Request (Requestid, Accountid, Executorid , Failureid, Incomingdate, Executiondate, Executed) VALUES (23, '136169', 5, 7, '2023-05-07', '2023-05-08', TRUE);
/******************************************************************************/
/*** Primary keys ***/
/******************************************************************************/
ALTER TABLE Abonent ADD PRIMARY KEY (Accountid);
ALTER TABLE Disrepair ADD PRIMARY KEY (Failureid);
ALTER TABLE Executor ADD PRIMARY KEY (Executorid );
ALTER TABLE Nachislsumma ADD PRIMARY KEY (Nachislfactid);
ALTER TABLE Paysumma ADD PRIMARY KEY (Payfactid);
ALTER TABLE Request ADD PRIMARY KEY (Requestid);
ALTER TABLE Services ADD PRIMARY KEY (Serviceid);
ALTER TABLE Street ADD PRIMARY KEY (Streetid);
/******************************************************************************/
/*** Foreign keys ***/
/******************************************************************************/
ALTER TABLE Abonent ADD FOREIGN KEY (Streetid) REFERENCES Street (Streetid) ON UPDATE CASCADE;
ALTER TABLE Nachislsumma ADD FOREIGN KEY (Accountid) REFERENCES Abonent (Accountid) ON UPDATE CASCADE;
ALTER TABLE Nachislsumma ADD FOREIGN KEY (Serviceid) REFERENCES Services (Serviceid) ON UPDATE CASCADE;
ALTER TABLE Paysumma ADD FOREIGN KEY (Accountid) REFERENCES Abonent (Accountid) ON UPDATE CASCADE;
ALTER TABLE Paysumma ADD FOREIGN KEY (Serviceid) REFERENCES Services (Serviceid) ON UPDATE CASCADE;
ALTER TABLE Request ADD FOREIGN KEY (Accountid) REFERENCES Abonent (Accountid)  ON UPDATE CASCADE;
ALTER TABLE Request ADD FOREIGN KEY (Executorid ) REFERENCES Executor (Executorid ) ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE Request ADD FOREIGN KEY (Failureid) REFERENCES Disrepair (Failureid) ON UPDATE CASCADE;


/*Имена столбцов*/
SELECT fio, accountid, phone
FROM abonent;

/*Константы*/
SELECT 'номер телефона', phone
FROM abonent;

/*Выражения (мет. операции, функции, логические операции,
  конкатенация), вычисляемые производные столбцы
  Длина псевдонима не должна превышать 63 байта, русская буква
  до 2 байт
*/
select accountid as "AccountIdRyazan",
       (Fio || 'имеет телефон ' || '9-4912-' || Phone) "ФИО+Телефон"
    from abonent;

SELECT accountid,
       paysum,
       15 * paysum + 20      "15 * Paysum + 20",
       15 * (paysum + 20) AS "15 * (Paysum + 20)"
FROM paysumma;

/*Математические операции в Postgresql могут применяться и к
  столбцами с типами данных DATE или INTERVAL*/

SELECT requestid,
       executiondate - incomingdate AS      "Дней",
       (executiondate - incomingdate) / 7.0 "Недель"
FROM request;

/*Количество выводимых строк
  начиная с 3 строки*/

SELECT *
FROM street
LIMIT 4 OFFSET 2;

/*Вывести 4 строки, начиная со второй строки*/

select *
from abonent
offset 1 rows fetch next 4 rows only;

/*Выборка из таблицы 50 процентов строк случайным образом*/

SELECT *
FROM paysumma
         TABLESAMPLE bernoulli(50.0);

/*Удалить повторяющиеся строки в таблице.
  Вывести идентификаторы улиц, на которых проживают абоненты*/

select distinct streetid
    from abonent;

/*При выполнении запрос с distinct обрабатываемые неопределенные
  значения считаются равными друг другу
  Запрос ниже 11 строк и только одна будет содержать null*/

SELECT DISTINCT phone
FROM abonent;

/*Нежелательно использовать distinct если изначально не ожидается
  избыточности данных
  Запрос демонстрирует проблему того что все ФИО абонентов различны,
  при этом использование distinct сократит количество реальных абонентов*/

  select distinct fio
  from abonent;

/*В Postgresql опция distinct on
Группирует строки по выражению в скобках (здесь accountid)
Для каждой группы возвращает первую строку в порядке сортировки
Если сортировка не указана — порядок строк не определён (может быть любым)*/

SELECT DISTINCT ON (accountid) accountid, paydate, paysum
FROM paysumma;

/*Для вывода кобинаций нескольких столбцов можно обмернут
  выражение из них в distinct
  Следующий запрос возвращает список уникальных комбиннаций
  Streetid/Houseno


  Группировка и выбор
DISTINCT ON группирует строки по вычисленному ключу
Каждая уникальная комбинация (streetid, houseno) — это одна группа
Без ORDER BY выбирается первая случайная строка из каждой группы
Выводятся: accountid, streetid, houseno
Проблема без умножения.
Если бы было просто streetid + houseno:
streetid	houseno	streetid + houseno
3	4	7
4	3	7
❌ Коллизия! Разные улицы с разными номерами дают одинаковый ключ.
С умножением на 100
streetid	houseno	streetid * 100 + houseno
3	4	304
4	3	403
*/

SELECT DISTINCT ON (streetid * 100 + houseno) accountid,
                                              streetid,
                                              houseno
FROM abonent;

SELECT DISTINCT ON (streetid, houseno) accountid,
                                       streetid,
                                       houseno
FROM abonent;

/*Псевдонимы таблицы
  Имена псевдонимов таблиц и столбцов в рамках одного
  запроса и подзапроса должны быть уникалыными
*/

SELECT a.accountid, a.fio, a.phone
FROM abonent a;

SELECT a.*
from abonent a;

/*В качестве исходной таблицы в Postgresql может использоваться
  инструкция values
*/

select
R.*
    from (
        values
                ('X', 50)
               ,('Y', 60)
               ,('X', 60)
               ,('Y', 80)

         ) As R(a,b);

/*В СУБД Postgresql поддерживается запрос, содержащий только
  функцию select */

  select 27+5*2-10


/*Запросы, возвращающие текущие дату и время, могут быть такими*/

select current_timestamp; --текущие дата и время, часовой пояс
select localtimestamp; --текущие дата и время
select (current_date - '2026-01-01') -- число дней между датами

select distinct localtimestamp
from abonent;

select distinct localtimestamp
from street
limit 1;

/*
FETCH	ВЗЯТЬ / ИЗВЛЕЧЬ / ВЫБРАТЬ
NEXT	СЛЕДУЮЩИЕ
1	    ОДНУ
ROWS	СТРОК(У)
ONLY	ТОЛЬКО

*/
select localtimestamp
from request
fetch next 1 rows only;

/*Postgresql поддерживает булев тип данных, примерами запросов
  на вывод значений логических выражений могут быть такие
*/

select
4 = 2 * 2 AS "Равно", --true
5 = 2 * 2 AS "Не равно"; --false


/*Запрос находит заявки, которые были выполнены в тот же день,
  когда поступили, и при этом были погашены (executed = true).*/
SELECT requestid,
       executiondate,
       incomingdate,
       executed,
       incomingdate = executiondate AND executed AS flag
FROM request;

select *
from request

/*Секция where при построении запроса очень часто возникает необходимость
  вывести не все строки из таблицы, а только те, данные которых
  соответствуют определенному условию. Отобрать нужные строки
  позволяет фильтрация строк, для которой используется секция
  where.
  Таким образом применение where является вторым способом ограничения
  количества строк помимо использования секции ограничения
  и смещения строк (FETCH NEXT 10 ROWS ONLY)

  Порядок выполнения секций в запросе select не позволяет использовать
  в условии поиска секции where псевдонимы возвращаемых элементов.
  Фильтр where выполняется до секции select и AS , поэтому столбец
  псевдонима фактически не существует на момент выполнения where.
*/



/*Простое сравнение*/

select *
from request
where executiondate >= '01.01.2025';

select *,to_date('01.01.2025', 'DD.MM.YYYY') as todate
from request
where executiondate >= to_date('01.01.2025', 'DD.MM.YYYY')

/*Преобразует строку '01.01.2025' в дату 2025-01-01
Что произошло:
Функция прочитала строку '01.01.2025'
По формату 'DD.MM.YYYY' поняла:
DD = день = 01
MM = месяц = 01
YYYY = год = 2025
Собрала это в дату 2025-01-01


Следует отметить что строки с неопределенной датой не выводятся
*/
select *,to_date('01.01.2025', 'DD.MM.YYYY') as todate
from request
where executiondate >= to_date('01.01.2025', 'DD.MM.YYYY')


SELECT *
FROM request
WHERE executiondate >= '20250101';

/*Сравнение строк, учитывающее их расположение в алфавитном порядке
  Здесь строки сравниваются посимвольно, используя лексикографический
  порядок*/

SELECT *
FROM services
WHERE servicenm < 'Услуга';

/*Также при сравнении строк нужно учитывать регистр
  Например в таблице street названия всех улиц указаны в верхнем
  регистре. Если попытаться сопоставить нижний регистр, результаты
  будут отличаться.
*/

select *
from street
where streetnm = 'Московская улица';

select *
from street
where streetnm = 'МОСКОВСКАЯ УЛИЦА';

/*Условие в секции where вообще не обязательно должно велючать какие-либо
  столбцы в таблице. Например, допустимым являются следующие:
*/

/*Возврат всех строк, такие условия полезны для тестирования
  самого условия, а не для получения фактических результатов*/
SELECT *
FROM abonent
WHERE 'a' = 'a';

/*Не вернется ни одной строки, потому ка условие не является истинным*/
SELECT *
FROM abonent
WHERE 1 = 0;

/*При определении условий поиска не обходимо помнить об обработки
  null, в результаты запроса попадают только те строки, для которых условие
  поиска имеет значение true
  1.Применение not к null возвращает в качестве результата unknown
  2.Если сравнение истинно, то результаты имеет значение true
  3.Если сравнение ложно то результат проверки имеет значение false
  4.Если хотя бы одно значение из двух сравниваемых значений установлено в null,
  то результатом будет unknown

  В следующем запросе результат будет неполным, потому как имеются
  значения null
  */

select *
from request
where incomingdate <> executiondate;

/*Проверка на логическое значение
  При работе с СУБД может возникнуть необходимость выполнить проверку
  значения логического выражения на соответствие одному из значений
  техзначной логики (true, false, unknown)

  Например, для вывода номеров лицевых счетов абонентов и дат подачи ими
  непогашенных ремонтных заявок можно использовать такие запроосы:
*/

SELECT accountid, incomingdate,executed
FROM request
WHERE executed IS FALSE;

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = 'FALSE';

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = 'NO';

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = 'OFF';

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = '0';


SELECT accountid, incomingdate,executed
FROM request
WHERE executed != '1';

SELECT accountid, incomingdate,executed
FROM request
WHERE not executed;

/*А для погашенных заявок*/

SELECT accountid, incomingdate,executed
FROM request
WHERE executed IS TRUE ;

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = 'YES';

SELECT accountid, incomingdate,executed
FROM request
WHERE executed = '1';

SELECT accountid, incomingdate,executed
FROM request
WHERE executed != '0';

/*Проверка на принадлежность диапазону значений
  Меньшее из двух значений всегда должно быть записано первым
границы включительно*/

SELECT accountid, nachislsum
FROM nachislsumma
WHERE nachislsum BETWEEN 60 AND 200.13;

/*Инвертированная проверка на принадлежность
*/
SELECT accountid, nachislsum
FROM nachislsumma
WHERE nachislsum NOT BETWEEN 60 AND 200.13;

/*Не рекомендуется использовать с датами в которых содержится дата и время
  -- Хотим найти все платежи за 15 марта 2025 года
SELECT * FROM paysumma
WHERE paydate BETWEEN '2025-03-15' AND '2025-03-15';

  Что происходит на самом деле
Когда вы пишете '15.03.2025', компьютер понимает
это как 15 марта 2025 года в 00:00:00 (полночь, самое начало суток).

Ваш запрос становится таким WHERE paydate >= '15.03.2025 00:00:00'   -- от начала суток
  AND paydate <= '15.03.2025 00:00:00'   -- до начала суток

Получается: ищем записи, которые одновременно и больше или равны полуночи,
и меньше или равны полуночи.


15 марта 2025 года
│
├── 00:00 (полночь) ← сюда BETWEEN попадает
├── 01:00
├── 02:00
├── ...
├── 10:30
├── 12:00
├── 15:00
├── 18:45
├── 23:59
└── 24:00 (следующая полночь)

BETWEEN берёт только точку ровно в 00:00.
А ваши платежи были в 10:30, 15:00, 18:45 — они НЕ попадают в результат.

Что делать?
Используйте не BETWEEN, а вот такую конструкцию:
SELECT * FROM paysumma
WHERE paydate >= '15.03.2025'      -- от начала суток
  AND paydate < '16.03.2025';      -- до начала следующих суток

BETWEEN с датами не рекомендуют, потому что он не захватывает весь день — только полночь.
Вместо этого пишите >= начало дня AND < следующий день.
*/


/*Проверка like на соответствие шаблону
Оператор	Чувствительность к регистру	Что ищет
LIKE	✅ Чувствителен	Ищет точно с учётом заглавных и строчных букв
ILIKE	❌ Не чувствителен	Ищет без учёта регистра
%	Любое количество любых символов	'С%' — начинается с С
_	Один любой символ	'С_' — С + один символ
\%	Поиск символа % (экранирование)	'100\%'
\_	Поиск символа _ (экранирование)	'A\_B'
  */

SELECT fio
FROM abonent
WHERE fio LIKE 'С%';

SELECT fio
FROM abonent
WHERE fio ILIKE 'с%';

SELECT *
FROM abonent
WHERE fio LIKE 'Т__у%'; --Тулупова М. И.

/*fio имеет тип varchar(30) из чего следует что пробелы в конце строки
  отрезаются автоматически, можно сделать вывод что в конце слова можно
  было применить шаблон 'Шлык_ов М.К.' без знака процента в конце
Однако если столбец имеет тип CHAR(n)? использование знака процента в конце
  строки шаблона необходимо для того, чтобы строки с такими столбцами
  дополненными справа пробелами до общего количества символов n были
  включены в результат выполнения запроса*/

select *
from abonent
where fio like '%ина%' and phone like '25%';

select fio
from abonent
where fio like '\%%';

select fio
from abonent
where fio like '$%%' ESCAPE '$';

/*Проверка на членство во множестве*/

-- Вместо SELECT * берите только нужные столбцы
SELECT failureid, failurenm
FROM disrepair
WHERE failureid IN (1, 5, 12);

-- Создаём покрывающий индекс
CREATE INDEX idx_disrepair_covering
    ON disrepair (failureid, failurenm);

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM disrepair
WHERE failureid = 12
   OR failureid = 1
   OR failureid = 5;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM disrepair
WHERE failureid IN (1, 5, 12);

/*С помощью not in можно убедиться в том, что значение данных не является
членом заданного множества
Если результатом проверяемого выражения является null,
то проверка in также возвращает null
Все значения в списке заданных значений должны иметь один и тот же тип дпнных,
который должен быть сравним с типом данных проверяемого выражения
При работе со строковыми данными значения с пи ске in необходимо заключать
в одинарные кавычки и как следствие требуется учитывать регистр букв.
*/


/*Проверка null обеспечивает возможность применения трехзначной логики у словиях
поиска
Null никогда не равен ничему и даже другому null
Однако несмотря на это в СУБД реализуется только двухзначная логика
Поэтому условие с null должно интерпретироваться либо как true
либо как false
Часто необходимо явно проверять згначения столбцов на null и непосредственно обрабатывать
их, для выявления имеется специальная проверка is null работающая с любым типом данных


Необходимо вывести номера лицевых счетов абонентов и даты подачи ими заявок, по
  которым не выполнены ремонтные работы, то есть столбце executiondate равен null.
Что делает IS NOT NULL
executiondate IS NOT NULL — это логическая проверка, которая возвращает:
Значение executiondate
Результат проверки
Есть дата (не NULL)	true
Нет даты (NULL)	false
*/

SELECT accountid, incomingdate, executiondate
FROM request
WHERE executiondate IS NULL;

/*Пример запроса с логическим выражением, признак выполнения заявки*/
SELECT accountid, incomingdate, executiondate, executiondate IS NOT NULL AS "Выполнена?"
FROM request

/*Предикаты like, between, in а также <,>, =, != не позволяют обнаружить null*/


/*Проверка двух значений на отличие
  is [not] distinct from <значение1>
  Предикат distinct аналогичен предикату равенства с тем лишь различием, что считает
  два признака null не различающимися (возвращает true если оба значения не определены)
  Поскольку предикат distinct считакт, что два признака null не различаются, то он никогда
  не возвращает неизвестное значение
  он возвращает либо truе или false.
  */

select null is distinct from null; --false
select null is not distinct from null; --true
select 1 is not distinct from 1; --true
select 1 is  distinct from 1; --false

/*Вывести все данные по ремонтным заявкам у которых дата
  регистрации отличается от даты выполнения, можно следующим запросом
  IS DISTINCT FROM — это NULL-безопасное сравнение. Оно работает так:
Значение 1	Значение 2	=	IS DISTINCT FROM
2023-01-01	2023-01-01	TRUE	FALSE (не отличаются)
2023-01-01	2023-01-15	FALSE	TRUE (отличаются)
2023-01-01	    NULL	NULL	TRUE (отличаются)
NULL	    2023-01-01	NULL	TRUE (отличаются)
NULL	        NULL	NULL	FALSE (не отличаются)

-- Обычное сравнение <> (НЕ работает с NULL)
WHERE incomingdate <> executiondate
-- Результат: NULL не попадают (сравнение с NULL даёт NULL)
-- NULL-безопасное сравнение (работает с NULL)
WHERE incomingdate IS DISTINCT FROM executiondate
-- Результат: NULL считаются отличными от любой даты

Построчный разбор ваших данных
requestid	incomingdate	executiondate	<>	IS DISTINCT FROM	Попадает?
1	2023-12-17	2023-12-20	TRUE	TRUE	✅ ДА
2	2023-08-07	2023-08-12	TRUE	TRUE	✅ ДА
3	2024-02-28	2024-03-08	TRUE	TRUE	✅ ДА
5	2023-12-31	   NULL	    NULL	TRUE	✅ ДА
6	2023-06-16	2023-06-24	TRUE	TRUE	✅ ДА
7	2024-10-20	2024-10-24	TRUE	TRUE	✅ ДА
9	2023-11-06	2023-11-08	TRUE	TRUE	✅ ДА
10	2023-04-01	2023-04-03	TRUE	TRUE	✅ ДА
11	2025-01-12	2025-01-12	FALSE	FALSE	❌ НЕТ
12	2023-08-08	2023-08-10	TRUE	TRUE	✅ ДА
13	2022-09-04	2022-12-05	TRUE	TRUE	✅ ДА
14	2025-04-04	2025-04-13	TRUE	TRUE	✅ ДА
15	2022-09-20	2022-09-23	TRUE	TRUE	✅ ДА
16	2023-12-28	NULL	    NULL	TRUE	✅ ДА
17	2023-08-15	2023-09-06	TRUE	TRUE	✅ ДА
18	2024-12-28	2025-01-04	TRUE	TRUE	✅ ДА
19	2023-12-17	2023-12-27	TRUE	TRUE	✅ ДА
20	2023-10-11	2023-10-11	FALSE	FALSE	❌ НЕТ
21	2023-09-13	2023-09-14	TRUE	TRUE	✅ ДА
22	2023-05-18	2023-05-25	TRUE	TRUE	✅ ДА
23	2023-05-07	2023-05-08	TRUE	TRUE	✅ ДА

*/

select *
from request
where incomingdate is distinct from executiondate;
/* Не попадут строки
incomingdate | executiondate
2023-10-11   |2023-10-11
2025-01-12   |2025-01-12
*/


/*Проверка на соответствие регулярному выражению
  Если один из операндов имеет null, то и результат
  будет null */

SELECT * FROM Abonent WHERE Fio ~'^[МШ].*к*В.$';

SELECT * FROM Abonent WHERE Fio ~'^[М|Ш].*к*В.$';

/*Исключить ремонтные заявки, зарегистрированные в 2023 году, можно таким образом:*/

SELECT * FROM Request WHERE Incomingdate::TEXT != '^2023';

SELECT * FROM Request
WHERE Incomingdate::TEXT NOT SIMILAR TO '2023 %';

/*Регулярные выражения, помимо использования в секции WHERE, могут применяться в ограничении
CHECK запросов на создание домена и таблицы БД (см. лекц. 6.1) и в логическом
условии оператора ветвления IF.
Также в PostgreSQL регулярные выражения могут
использоваться в качестве аргументов функции SUBSTRING
*/

/*Составные условия поиска*/
SELECT *
FROM paysumma
WHERE (paydate > '13.06.2025' AND paysum > 120)
   OR (paydate < '01.01.2024' AND accountid = '005488');

SELECT *
FROM Paysumma
WHERE Accountid = '005488' AND Payyear = 2025;

SELECT *
FROM Paysumma
WHERE (Accountid, Payyear) = ('005488', 2025);

/*Например, требуется вывести всю информацию о ремонтных заявках,
дата выполнения которых отличается от 20.12.2023. Запрос
выдаст неверный результат.
В него не попадут данные о невыполненных заявках.*/

SELECT *
FROM Request
WHERE Executiondate != '2023.12.20';

/*Добавив проверку на NULL:*/

SELECT *
FROM Request
WHERE Executiondate != '2023.12.20' OR Executiondate IS NULL;

/*или применив проверку на отличие:
Таблица истинности
Executiondate	IS DISTINCT FROM '20.12.2023'	       Результат
20.12.2023	    FALSE (не отличается)	               ❌ НЕ попадает
21.12.2023	    TRUE (отличается)	                   ✅ Попадает
19.12.2023	    TRUE (отличается)	                   ✅ Попадает
NULL	        TRUE (NULL отличается от любой даты)   ✅ Попадает
*/

SELECT *
FROM Request
WHERE Executiondate IS DISTINCT FROM '20.12.2023';

/*Функции для обработки данных скалярные функции
Встроенными (системными) являются функции, предопределенные
в диалекте языка SQL конкретной СУБД.
В SQL определено множество встроенных функций различных категорий.
Эти функции делятся на следующие основные группы:
-скалярные функции - обрабатывают входные данные и возвращаю одно значение
-функции, возвращающие множество;
-агрегатные функции;
-условные выражения и функции;
-функции полнотекстового поиска;
-оконные (аналитические) функции.

Для вызова функции необходимо указать ее имя и перечислить список аргументов
в скобках через запятую
*/

select *
from pg_proc;

/*Скалярные функции
  подразделяются на строковые математические, функции даты и времени, функции преобразования
  типов и форматирования данных
*/

SELECT accountid, SUBSTRING(fio FROM 1 FOR 3) AS "Fio3"
FROM abonent;

SELECT accountid, SUBSTR(fio, 1, 3) AS "Fio3"
FROM abonent;

SELECT SUBSTRING(fio, 1, 3) AS "Fio3"
FROM abonent;

/*Функции left и right используются для выделения нужного
  количества символов соотвественно из начала или конца
  определенной строки
*/

SELECT fio,
       LEFT(accountid, 5),
       RIGHT(accountid, 5),
       accountid
FROM abonent
WHERE streetid = 3;


/*Существует ряд функций для замены исходной строки
  на другую последовательность символов
  Функция overlay заменяет в исходной строке подстроку, начинающуюся с номера,
  позиция, и имеющую размер длина, на значение строка_для_замены
*/

select overlay(phone placing '66' from 1), phone --666893|556893
from abonent;

/*Функция replace заменяет все вхождения подстрока в сровое_выражение
  на указанную строка_для_замены*/

SELECT replace(failurenm,'плиты', 'газовой плиты'),failurenm
FROM disrepair
where replace(failurenm,'плиты', 'газовой плиты') != failurenm



/*Убрать пробелы из начала и конца строки
  Также можно удалять символы из начала и конца строки, из конца строки, наибольшую
  подстроку из начала строки

  leading - удалить указанную наибольшую подстроку их начала строки.
  trailing - из конца строки.
  both - из начала и конца строки.
  Если удаляемая строка не определена, то по умолчанию определяется пробел
*/

/*Убрать слово улица из названия улицы*/
select streetid,
       trim(TRAILING 'УЛИЦА' FROM streetnm) as Str_Name,
       streetnm
from street;

/*Убрать ведущий ноль слева*/
SELECT streetid, TRIM(LEADING '0' FROM accountid) AS accountid, fio
FROM abonent;


/*Вывод: RTRIM сработал одинаково, потому что оба аргумента задают один и тот
  же набор символов (просто в разном порядке). Для удаления целого слова
  RTRIM не подходит.
*/
select streetid,
       rtrim(streetnm, 'УЛИЦА') as Str_Name,
       streetnm
from street;

select streetid,
       rtrim(streetnm, 'АИЛЦУ') as Str_Name,
       streetnm
from street;


/*LPAD и RPAD дополняют строки указанной последовательность симвлов
  до заданного размера длина*/


SELECT accountid, RPAD(fio, 20, '*')
FROM abonent;

/*Для объединения двух или более строковых значений можно использовать функцию
  concat
*/

SELECT accountid                                        AS accointidryazan,
       CONCAT(fio, ' имеет телефон ', '8-4912-', phone) AS fiotelephone
FROM abonent;

/*concat_ws - объединение строк через разделитель*/

SELECT accountid                                        AS accointidryazan,
       CONCAT_WS(' / ',fio, ' имеет телефон ', '8-4912-', phone) AS fiotelephone
FROM abonent;


/*Функция repeat повторяет значение строки указанное количество раз*/

SELECT REPEAT('SQL', 3);

/*Функция вывода строки в обратной последовательонсти */

SELECT *,SUBSTR(REVERSE(fio), 1, 5), REVERSE('Е. В.')
FROM abonent
WHERE SUBSTR(REVERSE(fio), 1, 5) = REVERSE('Е. В.');


/*Перевод строки в зашлавные буквы*/

select *
from abonent
where upper(fio)='ШМАКОВ С. В.';

/*Преобразование строки в нижний регистр букв*/

select *
from abonent
where lower(fio)='шмаков с. в.';

/*initcap - каждая первая буква слова превращается в заглавную*/

select initcap(streetnm) ---Циолковского Улица
from street;


/*Для определения функции первого вхождения заданной подcтроки
  в строку можно использовать функцию position
  Например вывести всех абонентов у которых в фамилии вторая
  бука "у".
*/

SELECT accountid, fio
FROM abonent
WHERE POSITION('у' IN fio) = 2

/*Найти позицию слова select в строке inwert update delete =
  select merge@create можно следющим образом*/

SELECT POSITION('select' IN 'insert, update; delete = select merge@create') AS position;

--strpos(строка, подстрока)

SELECT STRPOS(fio, 'к'), fio
FROM abonent;


/*Функция для определения размера строки
  bit_length - в битах
  octet_length - в байтах
  char_length в символах

Проверить что тип varchar предусматривает автоматическое отбрасование символов
  пробела можно с помощью данного запроса
*/

SELECT failurenm,
       CHAR_LENGTH(failurenm)  AS f1,
       LENGTH(TRIM(failurenm)) AS f2
FROM disrepair;


/*Рассмотрим пример запроса, который позволяет подсчитать,
  сколько раз сивол или подстрока встречается в заданной строке,
  для подсчета количества букв "и" в ФИО абонентов можно использовать
  такой запрос

В этом запросе при вычитании из длины строки длины строки без подстроки получаетя разгница,
  которая соответствует количеству букв "И" в ФИО*/

SELECT fio, 'и', (LENGTH(fio) - LENGTH(REPLACE(fio, 'и', ''))) / LENGTH('и')
FROM abonent;

/*аналог вычисления с  regexp_count*/
select fio, 'и', regexp_count(Fio,'и')
from abonent;

/*Для нахождения позиций первой и последней буквы "и" можно применить
  функцию регулярных выражений*/

SELECT fio,
       REGEXP_INSTR(fio, 'и') AS first_position,
       LENGTH(fio) - REGEXP_INSTR(REVERSE(fio), 'и') + 1
                              AS last_position

FROM abonent
WHERE REGEXP_INSTR(fio, 'и') > 0;

/*Запрос, выводящий позицию последней буквы «и» в фамилии абонентов, может быть таким:
  */
SELECT fio,
       LENGTH(fio) + 1 - POSITION('и' IN REVERSE(fio)) "Позиция и"
FROM abonent
WHERE LENGTH(fio) + 1 - POSITION('и' IN REVERSE(fio)) <= LENGTH(fio);

/*Функции для работы с датой и временем
  функция extract используется для извлечения
  различных частей даты и времени

  можно извлекать век, квартал, год, месяц, номер недели,
  день недели, дня, часа, минуты, секунды и имеет формат
  numeric.
*/

SELECT
    Requestid,
    Incomingdate,
    -- Основные
    EXTRACT(DAY FROM Incomingdate) AS "Day",
    EXTRACT(MONTH FROM Incomingdate) AS "Month",
    EXTRACT(YEAR FROM Incomingdate) AS "Year",
    -- Дни
    EXTRACT(DOW FROM Incomingdate) AS "DOW",
    EXTRACT(ISODOW FROM Incomingdate) AS "ISODOW",
    EXTRACT(DOY FROM Incomingdate) AS "DOY",
    -- Недели и кварталы
    EXTRACT(WEEK FROM Incomingdate) AS "Week",
    EXTRACT(QUARTER FROM Incomingdate) AS "Quarter",
    -- Десятилетия, века, тысячелетия
    EXTRACT(DECADE FROM Incomingdate) AS "Decade",
    EXTRACT(CENTURY FROM Incomingdate) AS "Century",
    EXTRACT(MILLENNIUM FROM Incomingdate) AS "Millennium",
    -- Время (приводим к TIMESTAMP)
    EXTRACT(HOUR FROM Incomingdate::TIMESTAMP) AS "Hour",        -- всегда 0
    EXTRACT(MINUTE FROM Incomingdate::TIMESTAMP) AS "Minute",    -- всегда 0
    EXTRACT(SECOND FROM Incomingdate::TIMESTAMP) AS "Second",    -- всегда 0
    EXTRACT(EPOCH FROM Incomingdate::TIMESTAMP) AS "Epoch"
FROM Request
WHERE EXTRACT(YEAR FROM Incomingdate) <> 2025;


/*Например, требуется вывести даты регистрации ремонтных
  заявок с кодом неисправности, равным 1, и даты через 14
  дней после их регистрации
  Запрос будет выглядеть следующим образом:*/
SELECT Incomingdate,
       DATE(Incomingdate + 14) AS "Exec_Limit"
FROM Request
WHERE Failureid = 1;


SELECT Incomingdate,
       DATE(Incomingdate + INTERVAL '14 DAY') AS "Exec_Limit"
FROM Request WHERE Failureid = 1;

/*Найти и обрезать переданное значение*/

SELECT DATE_TRUNC('HOUR', CURRENT_TIMESTAMP); -- время до часа

SELECT COUNT(Paysum) -- количество платежей в месяце 3 года назад
FROM Paysumma
WHERE DATE_TRUNC('MONTH', Paydate)= DATE_TRUNC('MONTH', NOW() - INTERVAL '3 YEAR');

SELECT Incomingdate, Incomingdate + 14 AS "Exec_Limit"
FROM Request
WHERE Failureid = 1;

/*Функция age используется для вычисления разницы
  в годах месяцах и днях
*/


SELECT Requestid, (executiondate - Incomingdate) AS "Interval"
FROM Request
WHERE Accountid = '115705';


SELECT Requestid, AGE(executiondate , Incomingdate)
    AS "Interval"
FROM Request WHERE Accountid = '115705';

/*Явное преобразование типов*/

select *,CAST('yesterday' as date)
from paysumma
where paydate < CAST('yesterday' as date);--явное преобразование

SELECT distinct nachislmonth, nachislyear,
                cast('1.' || nachislmonth || '.' || nachislyear as date) as "firstday"
FROM nachislsumma
WHERE serviceid = 2;

SELECT DISTINCT nachislmonth,
                nachislyear,
                CAST(CONCAT('1.', nachislmonth, '.', nachislyear) AS DATE) AS "firstday"
FROM nachislsumma
WHERE serviceid = 2;

/*Можно преобразовывать числовые типы в строку и наоборот,
  такие преобразования необходимы когда значения, которые должны
  быть целыми, получаются из строки, а затем к ним нужно применить математические
  или агрегатные функции
*/


/*144 страница*/

SELECT nachislfactid, nachislsum,
       CAST(nachislsum AS INTEGER) AS "RoundSum"
FROM nachislsumma
WHERE Accountid='115705';

SELECT
    CAST(1.5 AS INTEGER) AS cast_result,    -- 2
    ROUND(1.5, 0) AS round_result;          -- 2

/*Операция преобразования типов
  ::DATE*/

SELECT distinct nachislmonth, nachislyear,
                ('1.' || nachislmonth || '.' || nachislyear)::DATE as "firstday"
FROM nachislsumma
WHERE serviceid = 2;

/*Рассмотрим популярные функции
  to_char, to_date, to_number
*/


SELECT
    Requestid,
    Incomingdate,
    TO_CHAR(Incomingdate, 'DD.MM.YYYY') AS "Дата_российская",
    TO_CHAR(Incomingdate, 'YYYY-MM-DD') AS "Дата_ISO",
    TO_CHAR(Incomingdate, 'DD Month YYYY') AS "Дата_прописью",
    TO_CHAR(Incomingdate, 'Day, DD.MM.YYYY') AS "Дата_с_днем_недели",
    TO_CHAR(Incomingdate, 'HH24:MI:SS') AS "Время"
FROM Request
WHERE Requestid <= 5;

SELECT
    TO_DATE('25.12.2025', 'DD.MM.YYYY') AS "Дата1",
    TO_DATE('2025-12-25', 'YYYY-MM-DD') AS "Дата2",
    TO_DATE('25 December 2025', 'DD Month YYYY') AS "Дата3";

SELECT DISTINCT
    nachislmonth,
    nachislyear,
    TO_DATE(CONCAT_WS('.', '01', nachislmonth, nachislyear), 'DD.MM.YYYY') AS "firstday"
FROM nachislsumma
WHERE serviceid = 2;

SELECT
    TO_NUMBER('1,234.56', '9,999.99') AS "Число1",
    TO_NUMBER('1 234,56', '9,999D99') AS "Число2",
    TO_NUMBER('$1,234.56', 'L9,999.99') AS "Число3";


/*Функцию to_char удобно использщовать для выделения
  из текущей даты однозначного номера дня недели*/
select to_char(current_date, 'D');--1воскресенье-7;

---полного названия дня недели в верхнем регистре
select  to_char(current_date, 'DAY'); --TUESDAY

---номер квартала
select  to_char(current_date, 'Q'); ---2

SELECT
    TO_NUMBER('1593480.829', '$9,999,999.99') AS "Pay";


/*Возможность совместного использования функции CAST (для формирования строки)
  и функции TO_DATE (для преобразования строки в дату) иллюстрирует следующий запрос:
  */

SELECT TO_DATE('January 10, 2023', 'Month DD, YYYY');
SELECT TO_TIMESTAMP('10/17/2023 10:27:48',
                    'MM/DD/YYYY HH24:MI:SS');
SELECT TO_DATE('7.14.12', 'MM. DD. YY');
SELECT TO_DATE('2009/9/14', 'YYYY/MM/DD');

SELECT DISTINCT nachislmonth,
                nachislyear,
                TO_DATE(CAST('1.' AS VARCHAR(2))
                            || CAST(nachislmonth AS VARCHAR(2))
                            || '.'
                            || CAST(nachislyear AS VARCHAR(4)), 'DD.MM.YYYY')
                    AS "FirstDay"

FROM nachislsumma
WHERE serviceid = 2;


SELECT *
FROM Request
WHERE Incomingdate <= TO_DATE('31-12-2023', 'DD-MM-YYYY');

/*Функция PG_TYPEOF в PostgreSQL позволяет определить тип данных.*/
SELECT PG_TYPEOF(100);
--выдаст INTEGER, запрос
SELECT PG_TYPEOF(PI());
--DOUBLE PRECISION, а запрос
SELECT PG_TYPEOF('postgres');
--UNKNOWN.


/*Агрегатные и другие функции обработки даннных

Для подведения итогов по данным, содержащимся в БД, в языке SQL предусмотрены агрегатные (статистические) функции. Агрегатная функция использует в качестве аргумента какой-либо столбец.

---

**Сообщить об ошибке в тесте**

(для множества строк), а возвращает одно значение, определяемое типом функции. Основные агрегатные функции, поддерживаемые СУБД PostgreSQL:

- **AVG** — арифметическое среднее входных значений;
- **SUM** — сумма всех входных значений, отличных от NULL;
- **MAX** — максимальное из всех значений, отличных от NULL;
- **MIN** — минимальное из всех значений, отличных от NULL;
- **COUNT** — количество входных строк;
- **STDDEV_POP** — стандартное отклонение по генеральной совокупности входных значений;
- **STDDDEV_SAMP** — стандартное отклонение по выборке входных значений.

 Функция EVERY возвращает TRUE, если все входные значения, отличные от NULL, равны TRUE, и FALSE в противном случае.
Объединение всех входных значений в массив осуществляет функция ARRAY_AGG.

Аргументами агрегатных функций могут быть как столбцы таблицы,
так и результаты выражений над ними.
При этом выражение может быть сколь угодно сложным.
Агрегатные функции могут использоваться:
1) сами по себе для вывода результирующего значения;
2) с группировкой по столбцам для получения результирующих значений в каждой группе (см. лекц. 3.5).
Для функций SUM и AVG столбец должен содержать числовые значения. Специальная функция COUNT (*) служит для подсчета
всех без исключения строк в таблице (включая дубликаты). Результатом функции COUNT не может быть NULL.
Она может вернуть только натуральное число (положительное целое) или ноль. Все другие агрегатные функции
могут дать на выходе NULL, если аргумент не содержит ни одной строки или содержит строки, включающие только NULL.
Аргументу всех функций, кроме COUNT (*), может предшествовать опция DISTINCT (различный), указывающая, что избыточные
дублирующие значения должны быть исключены перед тем, как будет применяться функция.

Агрегатные функции могут использоваться только в секциях
SELECT, HAVING и ORDER BY.

Функция count(*) служит для подсчета всех без исключения строк в
таблице включая дубликаты, результатом count не может быть null.
Она может вернуть только натуральное число (положительное целое) или ноль.

Аргументом агрегатной функции может быть как простое имя столбца,так
  и выражение как например с ледующем запросе
*/

SELECT AVG(nachislsum + 2) AS avg
FROM nachislsumma;

SELECT AVG(paysum)
FROM paysumma;

/*Найти среднее количество целых дней, прошелших с даты подачи
  ремотных заявок до даты их выполнения*/

SELECT AVG(executiondate - incomingdate)
FROM request;

SELECT AVG(executiondate - incomingdate)
       FILTER (WHERE executiondate IS NOT NULL)
FROM request;

/*Выислить средднее значение всех плат за услугу с
  идентификатором 1 и сумму всех плат за услугу с идентификатором 2*/

SELECT AVG(paysum) FILTER (WHERE serviceid = 1),
       SUM(paysum) FILTER (WHERE serviceid = 2)
FROM paysumma;

/*Подсчитать количество невыполненных ремонтных заявок*/
SELECT SUM((executiondate IS NULL)::int)
FROM request;

/*Вычисление экстремумов
  использование функций max и min
  Столбце может содержать числовые и строковые значения,
  значения даты.времени,
  неопределенные значения null функциями vin и max не учитываются
MIN( { [[ALL] | DISTINCT] столбец | [DISTINCT] <выражение> } )
MAX( { [[ALL] | DISTINCT] столбец | [DISTINCT] <выражение> } )
Символ	Значение
{}	Фигурные скобки группируют элементы (обязательная часть)
[]	Квадратные скобки означают необязательный элемент
|	Вертикальная черта означает ИЛИ (выбор одного из вариантов)
...	Многоточие означает повторение (обычно для списка столбцов)
< >	Угловые скобки содержат описание того, что должно быть написано
*/


SELECT MIN(paysum), MAX(paysum)
FROM paysumma;


/*Вычисление количества
  вычислим количество абонентов, которые подавали заявки на ремонт
  газового оборудования,
  общее количество заявок, сколько из них выполнено и погашено

В SQL функции COUNT(*) и COUNT(1) выполняют похожие действия, но существуют небольшая разница:
- COUNT(*): эта функция считает количество всех строк в результирующем наборе, включая строки с
  NULL значениями. Она не пропускает ни одной строки, даже если все значения в строке являются NULL;
- COUNT(1): эта функция также считает количество строк в результирующем наборе, но она не учитывает
  значения столбцов!!! Вместо этого она просто учитывает наличие строк, а значения игнорируются.
  Это делает ее немного более эффективной, чем COUNT(*), когда важно только количество строк, а значения несущественны.
Выбор между COUNT(*) и COUNT(1) может зависеть от конкретной задачи и оптимизации запроса.
В большинстве случаев разница в производительности будет незначительной, но COUNT(1) может быть предпочтительным, если не нужно учитывать значения столбцов.

*/

SELECT
    COUNT(DISTINCT Accountid) AS "Число абонентов с заявками",
    COUNT(*) AS "Всего заявок",
    COUNT(executiondate) AS "из них выполнено",  -- считает не-NULL даты
    COUNT(Requestid) FILTER (WHERE Executed = TRUE) AS "погашено"  -- или просто WHERE Executed
FROM Request;


/*В качестве аргумента string_agg могут быть заданы столбец таблицы,
  переменная, выражение, константа, числовые значения, значения типа
  дата.время, которые в процессе работы функции преобразуются строку
  Для вывода строк в одну строку вех улсгу, разделенных запятой
  можео использовать такой запрос*/

---Газоснабжение,Электроснабжение,Теплоснабжение,Водоснабжение
SELECT STRING_AGG(servicenm, ',') AS "Список услуг"
FROM services;

/*Вызов функции создания массива ARRAY_AGG выглядит следующим
  образом:
*/

select array_agg(servicenm) as array_service
from services;

select array_agg(servicenm order by servicenm) as array_service
from services;

/*Функция EVERY
проверить все ли ремонтные заявки погашены можно запросом
EVERY() — это агрегатная логическая функция, которая возвращает TRUE,
если все значения в группе равны TRUE, и FALSE в противном случае.
*/

select every(executed)
from request;

/*Функция возвращающая множество
  generate_series(начало, конец [,шаг])*/

SELECT *
FROM GENERATE_SERIES(1, 15);
--числа от 1 до 15 с шагом 1

SELECT GENERATE_SERIES(3, 1000, 2);
--числа от 3 до 1000 с шагом 2

-- даты от завтрашней до конца месяца с шагом 5 дней
SELECT CURRENT_DATE + d.dt AS Dat
FROM GENERATE_SERIES(1, 31, 5) AS d(dt);

/*все месяцы с подачи первой до последней заявки, независимо
от того, подал ли абонент заявку в этом месяце */
SELECT TO_CHAR(GENERATE_SERIES(MIN(incomingdate),
                               MAX(incomingdate), INTERVAL '1 MONTH'), 'MM/YYYY') "Месяц/Год"
FROM request;

/*Если для функции в секции FROM указать WITH ORDINALITY,
то к столбцам результата функции добавляется столбец типа BIGINT,
числа в котором начинаются с 1 и увеличиваются на 1 для каждой
строки, выданной функцией, например*/

-- Добавление порядкового номера к каждой строке
--GENERATE_SERIES(10, 15) создаёт 6 строк со значениями: 10, 11, 12, 13, 14, 15
--WITH ORDINALITY добавляет второй столбец с номером строки
--AS t(value, ordinality) даёт имена столбцам:
--value — значения из GENERATE_SERIES
--ordinality — порядковые номера (1, 2, 3...)
SELECT *
FROM GENERATE_SERIES(10, 15)
    WITH ORDINALITY AS t(value, ordinality);

/*Условные выражения
  Необходимы для выбора вариантов действий взависимости от значений данных
Например CASE.

Средства выбора вариантов могут использоваться в списке возвращаемых
  столбцов секции select, в секции where, а также в качестве элементов
  списка группировки group by и сортировки order by.
Также они применимы в запросах языков  DDL и DML/

CASE,COALESCE, NULLIF, GREATEST, LEAST
*/


/*
Пусть необходимо вывести следующую информацию о ремонтных заявках абонента,
имеющего лицевой счет с номером '115705': номер заявки, номер лицевого счета абонента,
подавшего заявку, код неисправности. Необходимо также пометить, погашена ли заявка,
что определяется значением столбца Executed. Запрос будет выглядеть таким образом:
*/

SELECT requestid,
       ' № л/с абонента ' || accountid    AS "Ab_Info",
       ' Код неисправности ' || failureid AS "Failure",
       CASE executed
           WHEN FALSE THEN 'Не погашена'
           ELSE 'Погашена'
           END                               "Гашение"
FROM request
WHERE accountid = '115705';

/*
Такое использование CASE удобно для оценки того, насколько широко распространен определенный атрибут,
в данном случае признак гашения ремонтных заявок. Важно отметить, что типы возвращаемых и
проверяемых данных могут отличаться.
В данном примере сравниваются логические значения и возвращаются строки.
*/


/*Пусть необходимо вывести информацию о платежах со значением от 530 до 600 включительно
  с указанием срока давности оплаты: если оплата была произведена до 2023 г., то вывести
  'Давно', если оплата была произведена в 2023 г. или 2024 г., то вывести 'Не очень давно',
  если позднее — 'Недавно'. Запросы с использованием операций CASE с поиском
*/
SELECT Payfactid, Accountid, Paysum, Paydate,
       CASE WHEN Paydate < '01.01.2023'
                 THEN 'Давно'
            WHEN Paydate
                 BETWEEN '01.01.2023' AND '31.12.2024'
                 THEN 'Не очень давно'
            ELSE 'Недавно'
       END AS "OpIata"
FROM Paysumma
WHERE Paysum BETWEEN 530 AND 600;


/*
При выводе номера лицевого счета абонента заменить цифру 6
на случайную можно следующим запросом:
*/

SELECT accountid,
       REPLACE(accountid,
               '6',
               CASE
                   WHEN RANDOM() * 10 < 6 THEN
                       6 - RANDOM() * 6
                   ELSE
                       RANDOM() * 3 + 7
                   END :: CHAR(1)
       ) AS new_accountid,
       fio
FROM abonent;


/*
Операции CASE могут быть вложены друг в друга и в другие функции. Следующий запрос
выведет дату оплаты и соответствующий ей рабочий день или расшифровку выходного дня:
*/

SELECT paydate,
       CASE
           WHEN EXTRACT(ISODOW FROM paydate) NOT IN (6, 7)
               THEN 'Рабочий'
           ELSE
               CASE
                   WHEN EXTRACT(ISODOW FROM paydate) = 7
                       THEN 'Воскресенье'
                   ELSE 'Суббота'
               END
           END "День"
FROM paysumma;

/*или получить тоже самое без вложения:*/

SELECT Paydate,
       CASE TRIM(TO_CHAR(Paydate, 'day'))
           WHEN 'saturday' THEN 'Суббота'
           WHEN 'sunday' THEN 'Воскресенье'
           ELSE 'Рабочий'
           END AS "День"
FROM Paysumma;

/*CASE может использоваться в качестве аргумента агрегатных
  функций для «свертывания» данных в виде флага со значением 1 или
  0 в качестве возвращаемого значения. Примером использования
  агрегатной функции SUM по CASE может быть такой запрос.

Он возвращает общее число ремонтных заявок,
число невыполненных и непогашенных заявок.
  */

SELECT COUNT(*)                                               AS "Всего заявок",
       SUM(CASE WHEN executiondate IS NULL THEN 1 ELSE 0 END) AS "невыполненных",
       SUM(CASE WHEN NOT executed THEN 1 ELSE 0 END)          AS "непогашенных"
FROM request;



SELECT Requestid,
       (' Номер л/с абонента ' || Accountid) AS "Ab_Info",
       (' Код неисправности ' || Failureid) AS "Failure",
       CASE WHEN Executiondate IS NOT NULL
                THEN 'Выполнена'
            ELSE 'Не выполнена'
           END AS "Выполнение",
       CASE WHEN Executed ---CASE WHEN Executed = TRUE THEN 'Погашена' ELSE 'Не погашена' END
                THEN 'Погашена'
            ELSE 'Не погашена'
           END AS "Гашение"
FROM Request WHERE Accountid='115705';


SELECT requestid,
       executiondate,
       executed,
       CASE
           WHEN executiondate IS NOT NULL AND executed     THEN 'Выполнена и погашена'
           WHEN executiondate IS NOT NULL AND NOT executed THEN 'Выполнена и не погашена'

           ELSE 'Не выполнена и не погашена'
           END "Статус"
FROM request;



-- Исправленный вариант

/*Здесь производится выборка всех данных о заявках из таблицы
  Request при различных условиях:
- с неисправностями с идентификаторами 1, 3, 6, 7, 8
  (в том числе невыполненных), со сроком выполнения более 30 дней;
- с неисправностью 5 со сроком выполнения более 13 дней.*/
SELECT r.*
FROM request r
WHERE (COALESCE(executiondate, CURRENT_DATE) - incomingdate) >=
      CASE
          WHEN failureid IN (1, 3, 6, 7, 8) THEN 31
          WHEN failureid = 5                THEN 14
          ELSE NULL
          END;



/*Завершая предметное изучение операции CASE, приведем еще
один пример запроса, демонстрирующего логические результаты
условий поиска с AND и OR:
*/

/*
3. Здесь ремонтные заявки разделяются на назначенные исполнителям с идентификаторами меньше
4 и больше 3, а также на исполненные раньше 01.01.2024 и позже 31.12.2023. Учитывая то,
что в БД имеются только не назначенная на исполнение
(NULL в столбце Executorid для Requestid, равного 16) и (или) не выполненные
(NULL в столбце Executiondate для Requestid, равного 5 и 16) ремонтные заявки,
то удается получить лишь пять из шести возможных вариантов

*/

SELECT requestid,
       executorid,
       executiondate,
       CASE
           WHEN executorid > 3 AND executiondate > '31.12.2023'
               THEN 'TRUE'
           WHEN executorid < 4 OR executiondate < '01.01.2024'
               THEN 'FALSE'
           ELSE 'UNKNOWN'
           END " > 3 AND > 31.12.2023",
       CASE
           WHEN executorid >= 4 OR executiondate > '31.12.2023'
                               THEN 'TRUE'
           WHEN executorid < 4 THEN 'FALSE'
           ELSE 'UNKNOWN'
           END " > 3 OR > 31.12.2023"
FROM request;

/*Если заявка не выполнена, то установить дату поступления заявки,
  если ни дата поступления ни дата выполнения неизвестны,
  то написать что дата неизвестна
*/
SELECT RequestId,
       COALESCE(
               CAST(executiondate AS TEXT),
               CAST(Incomingdate AS TEXT),
               'Дата неизвестна'
       ) AS "Date_Info"
FROM Request
WHERE Accountid IN ('005488', '115705', '080270');

/*
Рассмотрим проблему использования COALESCE с конкатенацией.
Пусть требуется вывести ФИО и через пробел номер телефона,
если он есть. Если нет — вывести «Нет телефона». Решение с функцией CONCAT может быть таким:
*/
SELECT COALESCE(CONCAT(fio || ' ', phone), fio || ' Нет телефона')
FROM abonent;

/*
Но вместо ожидаемого результата выводится либо только ФИО,
либо результат конкатенации. А все потому,
что CONCAT игнорирует NULL
следовательно, результат получается отличным
от NULL и COALESCE не отрабатывает.
Чтобы избежать такой ситуации, выполним конкатенацию
с помощью «||»:
*/
SELECT COALESCE(Fio||' ' || Phone, Fio ||' Нет телефона')
FROM Abonent;



/*Запрос, возвращающий всю информацию по заявкам, у которых равны
даты регистрации и выполнения, или такой:*/

SELECT *
FROM Request
WHERE NULLIF(Executiondate, Incomingdate) IS NULL;


/*Запрос выбирающий для указанных абонентов
  значения их платежей за заданные услуги*/
SELECT accountid, serviceid, paysum
FROM paysumma
WHERE serviceid =
      CASE
          WHEN accountid = '136169' THEN 1
          WHEN accountid = '136160' THEN 3
          WHEN accountid = '080270' THEN 4
          ELSE null
          END;


/*
Функцию NULLIF полезно использовать для обратного преобразования значений
в NULL, если известно значение по умолчанию.
Так в таблице заявок на ремонт Request с датой регистрации
заявки по умолчанию можно при выводе изменить значения обратно
на NULL, используя

Во всех заявках, зарегистрированных в текущий день,
значение столбца Incomingdate отобразится как NULL.
*/

SELECT NULLIF(incomingdate, CURRENT_DATE)
FROM request;


/*
Например, поставить в соответствие ремонтным заявкам, принятым исполнителем с кодом 1,
дату их выполнения или 1 января 2024 г., если соответствующая
заявка была выполнена раньше этой даты, можно запросом
GREATEST() возвращает наибольшее (максимальное)
значение из списка аргументов.
*/


SELECT requestid,executiondate, GREATEST(executiondate, '01.01.2024')
FROM request
WHERE executorid = 1;


/*
Шаг 1: GREATEST(Incomingdate, Executondate) → выбираем бОльшую дату
Шаг 2: GREATEST(результат_шага1, '2024-01-01') → выбираем максимум

*/
SELECT requestid,
       GREATEST(GREATEST(incomingdate, executiondate), '2024-01-01')
FROM request
WHERE executorid = 4;


SELECT requestid,
       GREATEST(incomingdate, executiondate, '2024-01-01')
FROM request
WHERE executorid = 4;


SELECT executorid,
       MIN(LEAST(incomingdate,
                 COALESCE(executiondate, CURRENT_DATE))
          )
FROM request
GROUP BY executorid;

/*Функции полнотекстового поиска*/

/*178*/