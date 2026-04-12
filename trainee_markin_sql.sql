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

/*Функции полнотекстового поиска

Основными компонентами полнотекстового поиска являются:
анализатор. Процесс разбивки текста на отдельные токены (слова или фразы). PostgreSQL использует
  конфигурации словаря для определения, как текст будет разбит на токены,
  например как слова, или числа, или url-адрес, или e-mail;
словари. Приведение токенов к стандартной форме (лексемам).
  Например, слова могут быть приведены к начальной форме (лемматизация)
  или уменьшены до корня (стемминг), удалены стоп-слова;
TSVECTOR. Специальный тип данных для хранения токенизированного текста.
  Он хранит слова (лексемы) и их позиции в документе,
  что позволяет эффективно выполнять поиск;
TSQUERY. Тип данных, используемый для представления поискового запроса.

индексация. Для повышения эффективности полнотекстового поиска
  рекомендуется использовать индексы GIN (Generalized Inverted Index)
  или GiST (Generalized Search Tree). Это позволяет
  ускорить поиск, особенно при работе с большими объёмами данных.
  Индекс GIN рассчитан на случай, когда чаще выполняется чтение,
  чем запись, а GiST — наоборот, когда нужно больше записывать в БД,
  чем читать.
  Как правило, используют GIN. Он хранит не строки целиком,
  а отдельные лексемы со списком мест их вхождения.
*/

select to_tsvector('RUSSIAN', failurenm)
from disrepair;


/*
Для проверки TSQUERY соответствия созданному TSVECTOR используется бинарный
оператор @@. Он сравнивает два значения: одно из них должно быть типа
TSVECTOR, представляющего документ, а другое — типа TSQUERY,
представляющего поисковый запрос.
Оператор возвращает логическое значение TRUE,
если TSVECTOR соответствует запросу TSQUERY.

Рассмотрим пример.
В таблице неисправностей с текстовым столбцом
требуется найти наименования, содержащие определенные слова:
*/
SELECT Failurenm FROM Disrepair
WHERE TO_TSVECTOR('RUSSIAN', Failurenm) @@ TO_TSQUERY('RUSSIAN', 'водогрейная & колонка');

/*
функция TO_TSVECTOR('RUSSIAN', Failurenm) преобразует содержимое столбца
Failurenm в тип TSVECTOR с использованием русской конфигурации;
функция TO_TSQUERY('RUSSIAN', 'водогрейная & колонка') создает запрос
типа TSQUERY, ищущий документы, содержащие оба слова «водогрейная» и
«колонка»;
оператор @@ сравнивает TSVECTOR с TSQUERY и возвращает TRUE для строк,
где они соответствуют друг другу.

*/

SELECT Failurenm FROM Disrepair
WHERE TO_TSVECTOR('RUSSIAN', Failurenm) @@ PLAINTO_TSQUERY('RUSSIAN', 'водогрейная колонка');

SELECT Failurenm FROM Disrepair
WHERE TO_TSVECTOR('RUSSIAN', Failurenm) @@ PHRASETO_TSQUERY('RUSSIAN', 'водогрейная колонка');

/*
Кроме того, PostgreSQL предоставляет всю необходимую функциональность
для упорядочивания и представления результатов текстового поиска
в удобной форме. Для ранжирования используется функция TS_RANK,
которая вычисляет степень релевантности документа на основе частоты
совпадения лексем: TS_RANK(TSVECTOR, TSQUERY)
Альтернативная функция TS_RANK_CD дополнительно учитывает не только частоту,
но и близость расположения совпадающих лексем: TS_RANK_CD(TSVECTOR, TSQUERY)

Ранжирование позволяет отсортировать найденные документы по степени их
соответствия поисковому запросу.
Пример запроса, возвращающего упорядоченные результаты:
*/

SELECT Failurenm,
       TS_RANK(TO_TSVECTOR('RUSSIAN', Failurenm),
               TO_TSQUERY('RUSSIAN', 'водогрейная & колонка')) AS Rank
FROM Disrepair
WHERE TO_TSVECTOR('RUSSIAN', Failurenm) @@ TO_TSQUERY('RUSSIAN', 'водогрейная & колонка')
ORDER BY Rank DESC;



/*
В запросах можно задавать веса для различных лексем,
чтобы управлять значимостью отдельных компонентов текста.
В PostgreSQL предусмотрены четыре уровня важности: 'A', 'B', 'C' и 'D'
(от самой высокой к низшей).
Для задания весов используется функция SETWEIGHT:
SETWEIGHT(TO_TSVECTOR(['язык'], 'текст'), 'уровень_важности')

Это позволяет точнее управлять результатами поиска, акцентируя внимание на
более значимых полях. Если текст для поиска состоит из нескольких полей,
им можно назначать разные веса важности.
Для этого используется функция SETWEIGHT, которая применяется
к каждому полю отдельно.
Затем результирующие векторы объединяются оператором ||, например:

В этом примере большее значение (вес 'A') присваивается названию
Failurenm, а меньшее (вес 'B') — идентификатору Failureid.
Это позволяет ранжировать строки так, чтобы совпадения в названии
имели больший приоритет, чем в идентификаторе.

Дополнительно в PostgreSQL имеются возможности подсветки искомых
слов в тексте, сбора статистики поиска, написания собственных словарей,
поиска слов с опечатками и многое другое.


*/

SELECT Failurenm, Failureid,
       TS_RANK(
               SETWEIGHT(TO_TSVECTOR('RUSSIAN', Failurenm), 'A') ||
               SETWEIGHT(TO_TSVECTOR('RUSSIAN', Failureid::TEXT), 'B'),
               TO_TSQUERY('RUSSIAN', 'горелка | (плита &! кран)')
       ) AS Rank
FROM Disrepair
WHERE (
          SETWEIGHT(TO_TSVECTOR('RUSSIAN', Failurenm), 'A') ||
          SETWEIGHT(TO_TSVECTOR('RUSSIAN', Failureid::TEXT), 'B')
          ) @@ TO_TSQUERY('RUSSIAN', 'горелка | (плита &! кран)')
ORDER BY Rank DESC;


/*Секция GROPU BY

Данные, хранящиеся в БД, часто состоят из огромного
количества строк, что делает сложным получение ценной
информации непосредственно из необработанных данных.
SQL предоставляет различные методы обработки, анализа
и манипулирования данными, позволяя преобразовывать
необработанные данные в значимую информацию, которая
может быть использована для принятия решений,
составления отчетов и оптимизации. Ключевыми методами
в SQL, которые помогают превратить данные в информацию,
являются группировка, фильтрация ее результатов и
агрегатные функции.

Запрос, включающий в себя секцию GROUP BY, называется
запросом с группировкой, поскольку он объединяет строки
с одинаковыми значениями в указанных столбцах исходной
таблицы в одну строку (группу) и для каждой группы строк
генерирует соответствующую строку НД. Агрегатные функции,
такие как COUNT, SUM, AVG, MIN и MAX, могут быть
применены к каждой группе строк для выполнения
вычислений и анализа данных.

Элементы, указанные в секции GROUP BY, называются
элементами группировки, и именно они определяют, по
какому признаку строки делятся на группы. При этом
группой называется набор строк, имеющих одинаковое
значение в элементе (элементах) группировки. Синтаксис
секции GROUP BY имеет вид

GROUP BY [[ALL] | DISTINCT] <элемент_группировки> [, ...]

где

<элемент_группировки> ::= {[<таблица>.]столбец
| порядковый_номер_столбца
| псевдоним_столбца
| <выражение>}

Фактически в качестве элемента группировки может
выступать любой возвращаемый элемент, указанный в
секции SELECT, кроме значений агрегатных функций. В
выражение, представляющее собой <элемент_группировки>,
могут входить скалярные функции из различных контекстов,
или это может быть любая CASE-операция

  Использование секции GROUP BY имеет смысл только при
наличии в списке возвращаемых элементов секции SELECT
хотя бы одного вычисляемого столбца или агрегатной
функции. Агрегатная функция берет столбец значений и
возвращает одно значение (агрегатный показатель). В
качестве агрегатных функций используются COUNT, SUM,
MIN, MAX, AVG, STRING_AGG и EVERY, рассмотренные в
предыдущей лекции. Секция GROUP BY указывает, что
результаты запроса следует разделить на группы,
применить агрегатную функцию по отдельности к каждой
группе и получить для каждой группы одну строку
результатов.

Примечание
Стандарты SQL:2011 и новее разрешают
опускать столбцы в GROUP BY, если они функционально
зависят от столбцов группировки. PostgreSQL (начиная с
версии 9.1) реализует эту возможность. Если столбец
группировки — первичный ключ, зависимые столбцы можно
не включать в GROUP BY.

*/


SELECT serviceid, COUNT(*)
FROM paysumma
GROUP BY serviceid;



/*Вычислить средние значения начислений за каждый год

1.Сортировка и группировка данных разделить все начисления
  на четыре группы годов - 2022б 2023б 2024б 2025;
2.агрегация данных по группам: найти среднее значение
  начислений в каждой группе

  */

SELECT nachislyear, ROUND(AVG(nachislsum), 2)
FROM nachislsumma
GROUP BY nachislyear;


/*Подсчет количества фактов начилаений для каждого значения, которое больше
  520 и меньше 550*/

SELECT nachislsum AS "Summa_550", COUNT(*)
FROM nachislsumma
WHERE nachislsum > 530
  AND nachislsum < 550
GROUP BY "Summa_550";

SELECT nachislsum
FROM nachislsumma
WHERE nachislsum =537.15;

/*Если для каждого абонента требуется вывести общее количество
  платежей с указанным в этой же строке максимальным для него
  значением платы, то можно сгруппировать результат по номеру
  лицевого счета и использовать в качестве второго возвращаемого
  элемента выражение с агрегатными функциями count и max */

SELECT accountid, (COUNT(*) || ', максимальное значение = ' || MAX(paysum)) AS "PayCount"
FROM paysumma
GROUP BY accountid;

/*Для каждого из абонентов вывести наименьшее значение платы за 2023 и 2024 год,
  вывести первые 10 строк*/


SELECT accountid, payyear, MIN(paysum)
FROM paysumma
WHERE payyear IN (2023, 2024)
GROUP BY accountid, payyear
FETCH NEXT 10 ROWS ONLY;

/*В качестве элемента группировки допускается определение выражений,
  в которых разрешено использовать различные скалярные sql - функции,
  а также средства выбора вариантов

Например для каждой группы лицевых счетов, начинающихся с одинаковых трех
  символов, вывести количество абонентов имеющих такие счета.
  */

SELECT ('Начало счета ' || SUBSTRING(accountid FROM 1 FOR 3)) AS acc_3
FROM abonent
GROUP BY 1;

/*Элементами группировки могут выступать существующте столбцы, не
  входящие в секцию select

Вывести годы за которые абонент с лицевым счетом 005488 оплачивал услуги*/

SELECT payyear
FROM paysumma
WHERE accountid = '005488'
GROUP BY accountid, payyear;

/*Следуте учесть что нельзя выводить по отдельности столбцы, участвующие в выражении
  группировки, например, в результате попытки выполнить следующий
  запрос будет выдано сообщение об ошибке, так как столбец accountid,
  участвующий в выражении группировки присутствует в списке возвращаемых
  элементов select
*/

SELECT accountid, COUNT(*)
FROM abonent
GROUP BY SUBSTRING(accountid FROM 1 FOR 3)

SELECT SUBSTRING(accountid FROM 1 FOR 3), COUNT(*)
FROM abonent
GROUP BY SUBSTRING(accountid FROM 1 FOR 3)

/*Рассмотрим пример использования case в качестве элемента
  группировки, например необходимо вывести средние значения
  начислений за годы 2024 и за годы после 2023*/

SELECT 'В среднем начислено ' || (
    CASE
        WHEN nachislyear < 2024
            THEN 'до 2024 года'
        ELSE 'после 2023 года'
        END)                     AS "Year",
       ROUND(AVG(nachislsum), 2) AS "Average_Sum"
FROM nachislsumma
GROUP BY "Year";

/*Пример count по case может служить пример подсчитывающий
  для каждого абонента общее количество платежей большее 300
*/

SELECT accountid,
       COUNT(*) AS "Всего платежей",
       COUNT(CASE
                 WHEN paysum > 300
                     THEN 1
                 ELSE NULL
           END) AS "Из них больше 300"
FROM paysumma
GROUP BY accountid;

/*Если нужно, например, получить общую сумму всех платежей
  и сумму только тех, которые больше 300:*/
SELECT accountid,
       SUM(paysum) AS "Общая сумма",
       SUM(CASE
               WHEN paysum > 300
                   THEN paysum
               ELSE 0
           END) AS "Сумма платежей > 300"
FROM paysumma
GROUP BY accountid;

/*Функция rollup формирует статистические строки в секции group by
  и строки подытогов или строки со статистическими вычислениями выского уровня,
  а также строки общего итога
  Количество возвращаемых группирований равно количеству выражений в списке
  элементов функции плюс один.

  SELECT a, b, c, SUM (<выражение>)
FROM t
GROUP BY ROLLUP (a,b,c);

Для каждого уникального сочетания значений (a, b, c), (a, b) и (a)
формируется одна строка с подытогом.
Вычисляется также строка общего итога.
Столбцы свертываются справа налево.
Последовательность расположения столбцов влияет
на выходное группирование ROLLUP и может отразиться
  на количестве строк в результирующем наборе.
*/


/* Вывод сумм значений платежей в разрезе оплачиваемых услуг и
абонентов с подытогами по услугам и итоговой суммой значений
платежей всех абонентов */
SELECT Serviceid, Accountid, SUM(Paysum)
FROM Paysumma
GROUP BY ROLLUP (Serviceid, Accountid)
ORDER BY Serviceid, Accountid;

/* Вывод сумм значений платежей в разрезе абонентов, оплачиваемых
ими услуг и годов с подытогами по услугам и по абоненту, а также
итоговой суммой значений платежей всех абонентов*/
SELECT Accountid, Serviceid, Payyear, SUM(Paysum)
FROM Paysumma
GROUP BY ROLLUP (Accountid, Serviceid, Payyear)
ORDER BY Accountid, Serviceid, Payyear;

/*Если задается несколько элементов группировки, то окончательный
  список наборов группировки может содержить дублирующиеся
  результаты:*/

SELECT accountid, serviceid, payyear, SUM(paysum)
FROM paysumma
GROUP BY ROLLUP (serviceid, accountid),
    ROLLUP ( serviceid, payyear)
ORDER BY accountid, serviceid, payyear;

/*Устранить можно использование distinct непосредственно в секции
  group by
  */

SELECT accountid, serviceid, payyear, SUM(paysum)
FROM paysumma
GROUP BY distinct ROLLUP (serviceid, accountid),
    ROLLUP ( serviceid, payyear)
ORDER BY accountid, serviceid, payyear;

/*
Вот текст целиком, разбитый на строки не более 90 знаков (с пробелами):

Функция CUBE формирует статистические строки секции GROUP BY, строки
со статистическими вычислениями высокого уровня функции ROLLUP и
строки с результатами перекрестных вычислений. Выходные данные CUBE
являются группированием для всех перестановок выражений в списке
элементов оператора.

Количество формируемых группирований равно
2
n
2n, где
n
n —
количество выражений в списке элементов оператора. Например, имеется
запрос следующего вида:

SELECT a, b, c, SUM (<выражение>)
FROM t
GROUP BY CUBE (a, b, c);

Формируется одна строка для каждого уникального сочетания значений
(a, b, c), (a, b), (a, c), (b, c), (a), (b) и (c) с подбитогом для
каждой строки и строкой общего итога.

Выходные данные CUBE не зависят от порядка столбцов. Примеры запросов:

*/

SELECT Serviceid, Accountid, SUM(Paysum)
FROM Paysumma
GROUP BY CUBE (Serviceid, Accountid)
ORDER BY Serviceid, Accountid;

SELECT accountid, serviceid, payyear, SUM(paysum)
FROM paysumma
GROUP BY CUBE (accountid, serviceid, payyear)
ORDER BY accountid, serviceid, payyear;


/*Функция GROUPING SETS указывает несколько группирований данных в
одном запросе. Выполняется статистическая обработка только указанных
групп, а не полного набора статистических данных, формируемых с
помощью функций CUBE или ROLLUP. Результаты эквивалентны тем, что
формируются с применением оператора UNION ALL к указанным группам.
В частности, следующий запрос

SELECT a, b, SUM(<выражение>)
FROM t
GROUPING SETS ((a), (a,b));

вернет группировку по (a) и по (a, b). А такой, например, запрос:

Группировка по (Serviceid, Accountid) — детальные суммы по
каждой паре «услуга + абонент».
Группировка только по (Serviceid) — суммы по каждой услуге
в целом (все абоненты вместе)
В отличие от ROLLUP или CUBE, GROUPING SETS не добавляет автоматически «общий
итог по всем данным». Если нужен ещё и общий итог,
нужно добавить () в список:

*/


SELECT Serviceid, Accountid, SUM(Paysum)
FROM Paysumma
GROUP BY GROUPING SETS ((Serviceid), (Serviceid, Accountid), ())
ORDER BY Serviceid, Accountid;



SELECT serviceid, payyear, accountid, SUM(paysum)
FROM paysumma
GROUP BY
    GROUPING SETS
    ((serviceid, payyear, accountid),
     (serviceid, accountid),
     (payyear, accountid)
    )
ORDER BY serviceid, payyear, accountid;


/*
Чтобы улучшить обработку значений NULL в строках, созданных функциями
ROLLUP или CUBE, в секции SELECT запросов с группировкой доступно
использование специальной функции GROUPING. Функция GROUPING
возвращает значение 1, если строка — это подитог, созданный функцией
ROLLUP или CUBE, и 0 — в противном случае. Столбцы с функцией
GROUPING позволяют определить строки итогов (это может потребоваться
для обработки значений NULL в основных столбцах итоговых строк).
Выполним следующий запрос:
*/


SELECT Serviceid, Accountid, SUM(Paysum) "Sum",
       GROUPING(Serviceid) "Gs",
       GROUPING(Accountid) "Ga"
FROM Paysumma
GROUP BY ROLLUP (Serviceid, Accountid)
ORDER BY Serviceid, Accountid;


SELECT
    CASE WHEN GROUPING(Serviceid) = 1 AND GROUPING(Accountid) = 1
              THEN 'Итого по всем услугам'
         ELSE Serviceid::TEXT
    END AS Serviceid,
    CASE WHEN GROUPING(Serviceid) = 0 AND GROUPING(Accountid) = 1
             THEN 'Итого по услуге'
         ELSE COALESCE(Accountid::TEXT, '')
    END AS Accountid,
    SUM(Paysum) AS Sum,
    GROUPING(Serviceid) "Gs",
    GROUPING(Accountid) "Ga"
FROM Paysumma
GROUP BY ROLLUP (Serviceid, Accountid)
ORDER BY
    GROUPING(Serviceid),
    Serviceid NULLS LAST,
    GROUPING(Accountid),
    Accountid NULLS LAST;


/*
Как следует из всех предыдущих примеров, на запросы с группировкой
накладываются некоторые ограничения:
в секции GROUP BY должны быть указаны столбцы или выражения,
которые используются в качестве возвращаемых элементов секции SELECT
(за исключением агрегатных функций);
все элементы списка возвращаемых столбцов должны иметь одно
значение для каждой группы строк. Это означает, что возвращаемый
элементом в секции SELECT может быть:
константа,
агрегатная функция, возвращающая одно значение для всех строк,
входящих в группу,
элемент группировки, который по определению имеет одно и то же
значение во всех строках группы,
функция, которая используется в качестве элемента группировки,
выражение, включающее в себя перечисленные выше элементы.
Вместе с тем PostgreSQL предоставляет возможность указывать в списке
вывода имена столбцов, не участвующих в группировке,

Второе изображение:

но являющихся функционально зависимыми от столбцов группировки.
Например, следующий запрос выведет значения всех столбцов
таблицы при группировке только по одному столбцу:


*/

SELECT A.*, COUNT(*) AS Ab_count
FROM Abonent A
GROUP BY A.Accountid;


/*
В данном примере достаточно сгруппировать строки по Accountid,
так как адрес, ФИО и номер телефона функционально зависят от номера
лицевого счета и можно однозначно определить,
какие значения этих атрибутов возвращать для каждой группы.

Кроме того, для решения определенных задач можно вообще не указывать
элемент группировки. Например, для вычисления всех агрегатов следует
использовать следующий запрос:

*/
SELECT
COUNT(*) AS Pay_count,
SUM(Paysum) AS Total_pay,
MAX(Paysum) AS Max_pay,
MIN(Paysum) AS Min_pay,
ROUND(AVG(Paysum), 2) AS Avg_pay
FROM Paysumma;

/*На практике в Posgresql по умолчанию строки возвращаются в
  неопределенном порядке. Изменить этот порядок можно с
  помощью секции ORDER BY*/
SELECT
    serviceid,
    COUNT(*) AS Pay_count,
    SUM(Paysum) AS Total_pay,
    MAX(Paysum) AS Max_pay,
    MIN(Paysum) AS Min_pay,
    ROUND(AVG(Paysum), 2) AS Avg_pay
FROM Paysumma
group by serviceid
order by serviceid;


/*
Секция HAVING
Секция HAVING используется в сочетании с секцией GROUP BY для
фильтрации результатов запроса на основе условия, которое, как
правило, включает агрегатную функцию. Это позволяет извлекать
группы, соответствующие определенным критериям. Секция состоит
из ключевого слова HAVING, за которым следует
<условие_поиска_групп_строк>:

<условие_поиска_групп_строк> ::= [NOT] <условие_поиска1>
[[AND|OR][NOT] <условие_поиска2>]...

где условие_поиска позволяет исключить из результата группы,
не удовлетворяющие заданным условиям. Условие поиска совпадает
с условием поиска, рассмотренным выше для секции WHERE, однако
в качестве значения часто используется значение, возвращаемое
агрегатными функциями.
В секции HAVING могут использоваться и
группирующие выражения, и выражения, не участвующие в группировке
(в этом случае это должны быть агрегатные функции).

Результат совместной работы HAVING с GROUP BY аналогичен результату
работы запроса SELECT с секцией WHERE с той разницей, что HAVING
выполняет те же функции фильтрации над строками (группами)
возвращаемого набора данных, а не над строками исходной таблицы.
Из этого следует, что секция HAVING начинает свою работу после того,
как секция GROUP BY разделит базовую таблицу на группы. В
противоположность этому использование секции WHERE приводит к
тому, что сначала отбираются строки из базовой таблицы и только
после этого отобранные строки начинают использоваться.

Например, чтобы для каждого из абонентов, которые подавали более
одной ремонтной заявки, вывести количество заявок и дату самой
ранней из них, нужно выполнить запрос
*/

SELECT accountid, COUNT(*), MIN(incomingdate)
FROM request
GROUP BY accountid
HAVING COUNT(*) > 1;

/*
Работа этого запроса заключается в следующем. Сначала GROUP BY
из таблицы Request формирует группы, состоящие из одинаковых
значений столбца AccountId. После этого в секции HAVING происходит
подсчет числа строк, входящих в каждую группу, и в НД включаются
все группы, которые содержат более одной строки.

Необходимо отметить, что если задать условие COUNT(*) > 1 в секции
WHERE, то такой запрос потерпит неудачу, так как секция WHERE
производит оценку в терминах одиночной строки, а агрегатные функции
оцениваются в терминах групп строк. В то же время из этого не
следует, что секция WHERE не используется с секцией HAVING.

Следует учесть, что секция HAVING должна ссылаться только на
агрегатные функции и элементы, выбранные GROUP BY, т. е. должны
использоваться аргументы, которые имеют одно значение на группу
вывода. Например, такой запрос потерпит неудачу:

*/


SELECT AccountId, MAX(Incomingdate) FROM Request
GROUP BY AccountId
HAVING Failureid = 1;
--ERROR: column "request.failureid" must appear in
--the GROUP BY clause or be used in an aggregate function
/*
Столбец Failureid не может быть использован в секции HAVING, потому
что он может иметь (и действительно имеет) больше, чем одно значение
на группу вывода. Таким образом, следующий запрос является
корректным:
*/

SELECT Accountid, MAX(Incomingdate) FROM Request
WHERE Failureid = 1
GROUP BY Accountid;

/*
Если необходимо узнать максимальные значения начислений для абонентов
с лицевыми счетами '005488' и '080047' (рис. 3.63), то можно выполнить
запрос, в котором секция HAVING ссылается на элемент, указанный в
GROUP BY.
Данный запрос является корректным:
*/

SELECT accountid, MAX(nachislsum)
FROM nachislsumma
GROUP BY accountid
HAVING accountid IN ('005488', '080047');

/*
Вывести номер лицевого счета абонентов и сумму их значений оплаты,
если она находится в диапазоне от 3000 до 5000 включительно, можно
следующим запросом:
*/

SELECT Accountid, SUM(Paysum) AS "Общая сумма оплаты"
FROM Paysumma
GROUP BY Accountid
HAVING SUM(Paysum) BETWEEN 3000 AND 5000;

/*
Получить только номера лицевых счетов абонентов, у которых значения
всех платежей превышают 500, можно таким запросом:
*/

SELECT Accountid
FROM Paysumma
GROUP BY Accountid
HAVING EVERY(Paysum > 500);

/*
Предположим, необходимо для каждой неисправности, с которой последняя
заявка поступила позднее 31.08.2023, вывести:
- дату поступления последней заявки;
- общее количество заявок;
- число выполненных заявок.
Для решения этой задачи запрос будет выглядеть таким
образом:
*/

SELECT failureid,
       MAX(incomingdate),
       COUNT(*)                                     "Всего заявок",
       ' из них выполнено ' || COUNT(executiondate) "Выполнение"
FROM request
GROUP BY failureid
HAVING MAX(incomingdate) > '31.08.2023'
order by  MAX(incomingdate);

/*
В следующем примере в секции HAVING используется оператор CASE,
чтобы ограничить строки, возвращаемые запросом SELECT.
Запрос возвращает для каждого абонента максимальное значение оплаты по
каждой услуге.
Секция HAVING ограничивает услуги, оставляя только услугу с кодом 2
и максимальной оплатой более 600
или услугу с кодом 4 и максимальной оплатой более 300:
*/

SELECT accountid, serviceid, MAX(paysum)
FROM paysumma
GROUP BY accountid, serviceid
HAVING (MAX(CASE
                WHEN serviceid = 2
                    THEN paysum
                ELSE NULL END) > 600
    OR MAX(CASE
               WHEN serviceid = 4
                   THEN paysum
               ELSE NULL END) > 300);

/*
Как и условие поиска в секции WHERE, условие поиска в секции HAVING
может дать один из трех перечисленных результатов:
если условие поиска имеет значение TRUE, то группа строк остается,
и для нее генерируется одна строка в результате запроса;
если условие поиска имеет значение FALSE, то группа строк
исключается, и строка в результате запроса для нее не генерируется;
если условие поиска NULL, то группа строк исключается, и строка
в результате запроса для нее не генерируется.
Правила обработки NULL в условиях поиска для секции HAVING точно
такие же, как и для секции WHERE.
Секцию HAVING имеет смысл использовать в сочетании с секцией
GROUP BY, хотя синтаксис запроса SELECT не требует этого. Если
базовая таблица интерпретируется одной группой, как, например,
в следующем запросе
*/

SELECT MAX(Incomingdate)
FROM Request
HAVING MAX(Incomingdate) > '31.08.2023';

/*
то использование HAVING возможно без GROUP BY. В этом случае все
строки, получаемые запросом, группируются в одну единственную
строку. С помощью HAVING можно проанализировать общие данные
группы, определить, нужно ли её выбирать.

В заключение следует рассмотреть типичные ошибки, возникающие при
построении запросов с группировкой данных.
Пусть требуется вывести
список номеров лицевых счетов абонентов с общей суммой оплат больше
3000. Если попытаться эту задачу решить так:
*/


SELECT Accountid, SUM(Paysum) AS Summa
FROM Paysumma
WHERE Paysum > 3000
GROUP BY Accountid;

/*то запрос возвратит пустой набор. Это происходит потому, что фильтр
секции WHERE оценивается построчно, а строк со значением отдельных
оплат больше 3000 нет.
Поэтому нужно применить фильтр по группе
оплат, а не по каждой оплате:*/


SELECT Accountid, SUM(Paysum) AS Summa
FROM Paysumma
GROUP BY Accountid
HAVING Summa > 3000;

/*
Однако этот запрос не выполнится из-за ошибки — псевдоним Summa
невидим для секции HAVING, так как она оценивается перед секцией
SELECT. Для устранения ошибки в секции HAVING следует обратиться
к самому столбцу:
*/

SELECT accountid, SUM(paysum) AS summa
FROM paysumma
GROUP BY accountid
HAVING SUM(paysum) > 3000;


/*
В следующем запросе используются два фильтра: один отбирает строки
(WHERE AccountID IN ('005488', '080047')),
а второй — группы строк
(HAVING SUM(Paysum) > 3000)
*/

SELECT accountid, SUM(paysum) AS summa
FROM paysumma
WHERE accountid IN ('005488', '080047')
GROUP BY accountid
HAVING SUM(paysum) > 3000;

/*
Секция ORDER BY
Строки НД, как и строки таблиц БД, не имеют определенного порядка.
Включив в запрос SELECT секцию ORDER BY, можно отсортировать
результаты запроса.

Секция ORDER BY состоит из ключевого слова
ORDER BY, за которым следует через запятую список элементов
сортировки, каждый из которых имеет такой синтаксис:

<элемент_сортировки> ::= {[<таблица>.] столбец
| порядковый_номер_столбца
| псевдоним_столбца
| <выражение>
| <скалярный_подзапрос>
[ASC] | DESC] [NULLS {FIRST | LAST}]....

Преимущество ORDER BY в том, что ее можно применять и к числовым,
и к строковым столбцам.

Опция DESC означает сортировку по убыванию. Если указать необязательную
и используемую по умолчанию опцию ASC, то сортировка будет произведена
по возрастанию.
Например, для вывода начислений абонентам за декабрь 2018 г.,
упорядоченных по убыванию значений, следует использовать запрос
*/

SELECT nachislfactid, accountid, nachislsum
FROM nachislsumma
WHERE nachislmonth = 12
  AND nachislyear = 2022
ORDER BY nachislsum DESC;

/*Запрос выборки пяти платежей с упорядоченными наименьшими значениями:*/
SELECT accountid, paysum
FROM paysumma
ORDER BY paysum
    FETCH FIRST 5 ROWS ONLY; --ерём первые 5 строк из отсортированного результата

/*По умолчанию сортировка производится по возрастанию чисел и дат,
а для текстовых значений — по алфавиту.
В качестве примера запроса
с сортировкой по дате, например, данных таблицы Paysumma по дате
платежа, может быть следующий:
*/

SELECT *
FROM Paysumma
ORDER BY Paydate;

/*
Язык SQL позволяет при отсутствии секции группировки упорядочивать
строки НД не только по тем столбцам, которые в нем присутствуют,
но и по столбцам исходной таблицы и выражениям над ними.
Например, запрос
*/

SELECT paysum
FROM paysumma
WHERE accountid IN ('136169', '005488', '443690')
ORDER BY accountid, paysum DESC;


/*
В качестве выражения сортировки можно использовать функцию,
в том числе агрегатную. В этом случае сортировке подвергается
результат, возвращаемый функцией для каждой строки. Например,
для вывода информации о первых пяти абонентах, имеющих наиболее
длинные ФИО, можно использовать запрос
В данном случае строки НД сортируются в порядке уменьшения
количества символов в ФИО абонентов, а внутри них — по алфавиту.
*/

SELECT *
FROM abonent
ORDER BY LENGTH(fio) DESC, fio
    FETCH FIRST 5 ROWS ONLY;

/*
Для возврата из таблицы Abonent одной или всех строк, выбранных
случайным образом, можно использовать соответственно следующие
запросы:
*/
SELECT * FROM Abonent ORDER BY RANDOM() FETCH NEXT 1 ROW ONLY;
SELECT * FROM Abonent ORDER BY RANDOM();

/*
Если при поиске одной строки отказаться от полного сканирования
большой таблицы, то запрос может быть менее затратным по времени:
Здесь используется уникальный идентификатор Payfactid.
Сначала определяется его максимальное значение,
генерируется случайное число в пределах этого диапазона
и затем находится строка с соответствующим Payfactid.
*/

SELECT *
FROM paysumma
WHERE payfactid >=
      (SELECT FLOOR(1 + RANDOM() *
                        (SELECT MAX(payfactid) FROM paysumma)
              ))
LIMIT 1;

/*
Иногда при сортировке может оказаться важным расположение в выходном
НД NULL-маркеров.
По умолчанию в PostgreSQL при сортировке по возрастанию значения NULL
располагаются в конце списка, а при сортировке по убыванию — в начале.
В соответствии со стандартом SQL существует возможность определить
положение NULL в выходном НД.
PostgreSQL поддерживает такую возможность. Результаты могут быть
отсортированы таким образом, что NULL будут располагаться выше
(NULLS FIRST)
или ниже (NULLS LAST) остальных результатов запроса, отличных от NULL.
*/

SELECT requestid, executiondate, accountid
FROM request
WHERE (accountid LIKE '08%')
   OR (accountid LIKE '11%')
ORDER BY executiondate DESC NULLS FIRST;

/*
Возможна сортировка НД по частям строки. Например, следующий
запрос возвратит абонентов из таблицы Abonent, упорядоченных по
инициалам:
*/
SELECT *
FROM abonent
ORDER BY RIGHT(fio, 5);



/*
Для сортировки по ключу, зависящему от данных, можно использовать
условные выражения.

Пусть требуется вывести все данные о неисправностях, упорядоченных
по названию.
При этом неисправности, содержащие в названии слово
«плиты», вывести первыми. Для этого можно использовать оператор
CASE, например так:

Когда СУБД сортирует строки, она сначала сортирует их по первому
критерию — в данном случае это результат выражения CASE, который
возвращает либо 0, либо 1.
Поскольку 0 меньше 1, строки с неисправностями, названия которых
не содержат слово «плиты», будут выведены первыми.
После того как строки разделены на две группы (сначала со значением 0,
затем со значением 1), каждая группа будет
отсортирована по алфавиту с помощью второго критерия Failurenm.
*/

SELECT *
FROM disrepair
ORDER BY CASE
             WHEN failurenm LIKE '%плиты%' THEN 0
             ELSE 1
             END,
         failurenm;

/*
Например, если код улицы равен 4, то следующий запрос возвратит строки
таблицы Abonent, упорядоченные по ФИО, а в противном случае — по
номеру телефона:
*/

SELECT *
FROM abonent
ORDER BY CASE
             WHEN streetid = 4 THEN fio
             ELSE phone
             END;

/*
Следующий запрос осуществляет сортировку строк таблицы Request
сначала по столбцу Executed,
а затем по убыванию даты выполнения заявки.
Если она не определена, то рассматривается столбец даты
поступления заявки:
*/

SELECT requestid, executed, incomingdate, executiondate
FROM request
ORDER BY executed,
         COALESCE(executiondate, incomingdate) DESC


/*
Весьма поучительным является способ сортировки при решении следующей
задачи.
Требуется для каждого абонента вывести все данные. При этом
в начале списка вывести абонентов с неопределенным номером телефона,
упорядоченными по ФИО.
После вывести данные абонентов, имеющих телефон, упорядоченными
по его номеру. Запрос может быть следующим.

В результате сортировки ORDER BY (Phone IS NOT NULL):
строки с Phone IS NULL → FALSE (0) → идут первыми;
строки с Phone IS NOT NULL → TRUE (1) → располагаются после.
Далее:
внутри группы NULL строки сортируются по ФИО;
внутри группы NOT NULL строки упорядочиваются по номеру телефона.

*/

SELECT *
FROM abonent
ORDER BY (phone IS NOT NULL),
         CASE
             WHEN phone IS NULL THEN fio
             ELSE phone
             END;

/*
Последующий запрос сортирует строки таблицы Abonent по идентификатору
улицы и номеру дома. При сортировке по первому столбцу функция
NULLIF позволяет вывести строки с Streetid = 4 в конце списка:
*/

SELECT *
FROM abonent
ORDER BY NULLIF(streetid, 4), houseno;


/*
Секция ORDER BY является последней в запросе SELECT. Следовательно,
НД можно упорядочивать по группам, например, так:
*/

SELECT accountid, SUM(nachislsum)
FROM nachislsumma
GROUP BY accountid
ORDER BY 1;

SELECT accountid, SUM(nachislsum)
FROM nachislsumma
GROUP BY accountid
ORDER BY 2;

/*с секцией HAVING, например, следующим образом:*/

SELECT Accountid, SUM(nachislsum)
FROM nachislsumma
GROUP BY Accountid
HAVING SUM(nachislsum) > :Par
ORDER BY 2;


/*
При попытке удаления дубликатов без применения опции
DISTINCT, а путем группировки

возникает ошибка из-за имеющейся неоднозначности

*/

SELECT paysum
FROM paysumma
WHERE accountid IN ('136169', '005488', '443690')
GROUP BY paysum
ORDER BY accountid, paysum DESC;

/*
Ошибку можно
устранить, выполнив сортировку по какому-либо агрегатному значению
для группы следующим запросом:
*/

SELECT paysum
FROM paysumma
WHERE accountid IN ('136169', '005488', '443690')
GROUP BY paysum
ORDER BY MAX(accountid), paysum DESC;

/*
Приведем пример запроса с сортировкой по значению агрегатной функции
для решения более практической задачи: вывести по каждой услуге
количество и среднее значение плат по ней, результат упорядочить
по количеству плат
*/

SELECT serviceid, COUNT(serviceid), ROUND(AVG(paysum), 2)
FROM paysumma
GROUP BY serviceid
ORDER BY COUNT(serviceid);

/*
Например, если для вывода номеров месяцев, количество оплат за которые
больше всего, использовать такой простой запрос:
*/

SELECT Paymonth AS "Месяц"
FROM Paysumma
GROUP BY Paymonth
ORDER BY COUNT(1) DESC
LIMIT 1;

/*
то результат будет неполным. Использование конструкции WITH TIES
позволяет избежать потери данных при извлечении экстремальных
значений, гарантируя получение всех строк, которые имеют одинаковое
значение, что очень удобно в подходах, связанных с анализом данных

WITH TIES возвращает все строки, которые имеют такое же значение
сортировки, как и последняя взятая строка.
LIMIT 1 → получите только ОДНОГО «победителя»
FETCH FIRST 1 ROW WITH TIES → получите ВСЕХ «победителей» (при ничьей)
*/

SELECT Paymonth AS "Месяц"
FROM Paysumma
GROUP BY Paymonth
ORDER BY COUNT(1) DESC
FETCH FIRST ROWS WITH TIES;

/*

В PostgreSQL опция DISTINCT ON обрабатывается по тем
же правилам, что и секция ORDER BY.
DISTINCT ON — мощный инструмент
для выборки «первых» или «последних» строк в группах,
особенно когда нужна простая и производительная реализация.
Базовый синтаксис:
SELECT DISTINCT ON (Column_name) *
FROM Table_name
ORDER BY Column_name, Sort_column DESC;

возвращает для каждого абонента все данные самого последнего платежа.
Заменив в этом запросе сортировку на обратную, легко можно получить
данные самого первого платежа.

Логика работы:

DISTINCT ON (accountid) — для каждого уникального accountid
оставляет только одну строку
ORDER BY accountid, paydate DESC — определяет, какую именно
строку оставить для каждого accountid:
Сначала строки группируются по accountid
Внутри каждой группы строки сортируются по paydate DESC
(от самой поздней даты к самой ранней)
DISTINCT ON берёт первую строку из каждой группы

*/

SELECT DISTINCT ON (accountid) *
FROM paysumma
ORDER BY accountid, paydate DESC;

/*Самый ранний платеж*/
SELECT DISTINCT ON (accountid) *
FROM paysumma
ORDER BY accountid, paydate ASC;  -- ASC вместо DESC

SELECT *
FROM paysumma
where accountid = '005488'
ORDER BY accountid, paydate ASC;

/*Массив из ФИО абонентов, проживающих в нем
  для задания порядка элементов в массиве используется
  секуция order by, ФИО в массиве сортируется
  в алфавиотном порядке*/

SELECT streetid, houseno, ARRAY_AGG(fio ORDER BY fio)
FROM abonent
GROUP BY streetid, houseno;

/*Вывести для каждого абонента его номер лицевого счета
  и последнюю оплату
Отличный вопрос! Конструкция [1] в PostgreSQL означает обращение
к первому элементу массива (индексация с 1, а не с 0).
Берёт первый элемент массива (индекс 1) — то есть самую
новую запись для данного accountid.
.* — разворачивание строки.
Превращает строку-запись в отдельные столбцы.
*/
SELECT (ARRAY_AGG(paysumma ORDER BY paydate DESC))[1].*
FROM paysumma
GROUP BY accountid;

/*Аналог*/
SELECT DISTINCT ON (accountid) *
FROM paysumma
ORDER BY accountid, paydate DESC;

/*Аналог через оконную функцию*/

WITH ranked AS (SELECT *,
                       ROW_NUMBER() OVER (PARTITION BY accountid
                           ORDER BY paydate DESC) AS rn
                FROM paysumma)
SELECT *
FROM ranked
WHERE rn = 1;

/*качестве следующего примера сортировки следует привести запросы
  на выборку пяти платежей с упорядоченными наименьшими значениями
*/


/*
Этот запрос возвращает первые 5 строк из отсортированного
результата, пропуская 0 строк (т.е. не пропуская ничего,
начинаем с самой первой строки).
После OFFSET 0 ROWS — начинаем с позиции 1
После FETCH FIRST 5 ROWS ONLY — берём строки 1, 2, 3, 4, 5

*/
SELECT accountid, paysum
FROM paysumma
ORDER BY paysum
OFFSET 0 ROWS FETCH FIRST 5 ROWS ONLY;

/*
FROM paysumma — берём все строки из таблицы
ORDER BY paysum — сортируем все строки по полю paysum по
возрастанию (от меньшего к большему)
FETCH FIRST 5 ROWS ONLY — возвращаем только первые 5 строк
из отсортированного результата
*/
SELECT accountid, paysum
FROM paysumma
ORDER BY paysum
    FETCH FIRST 5 ROWS ONLY;


/*
FROM paysumma — берём все строки из таблицы
LIMIT 5 — обрезаем результат, оставляя только 5 строк
Нет ORDER BY — строки не сортируются
Без ORDER BY база данных возвращает строки в том порядке,
в котором они физически хранятся (или читаются из индекса
*/

SELECT accountid, paysum
FROM paysumma
LIMIT 5;

/*
В заключение изучения сортировки рассмотрим пример неалфавитного
упорядочивания строк. Дело в том, что в реальном мире много вещей
расположены не в алфавитном порядке: цвета радуги, дни недели,
элементы периодической системы Менделеева, станции на линии метро и
времена года расположены не в алфавитном порядке, и сортировка их по
алфавиту неудобна.
В SQL нет встроенного метода неалфавитного
упорядочения строк.
Однако имеется несколько приемов решения такой
задачи обходным путем, например, путем создания строки со значениями
в требуемом порядке и определения положения каждого значения в строке


POSITION(подстрока IN строка) — функция, которая возвращает позицию (номер символа),
с которого начинается искомая подстрока.

В ней дни недели перечислены в правильном порядке (от понедельника к воскресенью),
а разделители (-, =, ,, !, пробел, ") — произвольные символы, которые не встречаются
в названиях дней.

*/

SELECT s.*
FROM (VALUES ('Воскресенье'),
             ('Вторник'),
             ('Понедельник'),
             ('Пятница'),
             ('Среда'),
             ('Суббота'),
             ('Четверг')) AS s ("День недели")
ORDER BY POSITION("День недели" IN
                  'ПонедельникВторникСредаЧетвергПятницаСубботаВоскресенье'
         );

/*Аналог*/
SELECT s.*
FROM (VALUES ('Воскресенье'),
             ('Вторник'),
             ('Понедельник'),
             ('Пятница'),
             ('Среда'),
             ('Суббота'),
             ('Четверг')) AS s("День недели")
ORDER BY CASE "День недели"
             WHEN 'Понедельник' THEN 1
             WHEN 'Вторник'     THEN 2
             WHEN 'Среда'       THEN 3
             WHEN 'Четверг'     THEN 4
             WHEN 'Пятница'     THEN 5
             WHEN 'Суббота'     THEN 6
             WHEN 'Воскресенье' THEN 7
             END;

/*
UNNEST разворачивает массив в строки:
['Воскресенье', 'Вторник', 'Понедельник', 'Пятница', 'Среда',
'Суббота', 'Четверг']

После UNNEST
Воскресенье
Вторник
Понедельник
Пятница
Среда
Суббота
Четверг

*/
SELECT s.*
FROM UNNEST(
             ARRAY[
                 'Воскресенье',
                 'Вторник',
                 'Понедельник',
                 'Пятница',
                 'Среда',
                 'Суббота',
                 'Четверг'
                 ]
     ) AS s("День недели")
ORDER BY
    ARRAY_POSITION(
            ARRAY['Понедельник','Вторник','Среда','Четверг',
                'Пятница','Суббота','Воскресенье'],
            s."День недели"
    );


/*Подготовленные запросы с параметрами

В PostgreSQL имеется возможность путем предварительной подготовки
запроса сократить время его выполнения. Создание подготовленного
запроса производится с помощью следующего синтаксиса:
PREPARE имя_запроса [(тип_данных [, ...])] AS <запрос>;
где в качестве запроса может использоваться SELECT, любой DML-запрос
или VALUES.
  При выполнении PREPARE указанный запрос разбирается и трансформируется.
Выполняется подготовленный запрос командой EXECUTE в формате:
EXECUTE имя_запроса;
При выполнении подготовленных запросов пропускаются такие этапы,
как разбор и трансформация, увеличив тем самым производительность.
Удаляется подготовленный запрос следующей командой:
DEALLOCATE имя_запроса;
Примерами работы с подготовленными запросами SELECT могут быть
следующие.

Подготовленные запросы доступны для использования только в рамках
одной сессии.
Предварительная подготовка может выполняться и для других
запросов SQL.

*/


PREPARE Abon AS
-- подготовка запроса Abon
SELECT * FROM Abonent;
-- выполнение запроса Abon
EXECUTE Abon;
-- удаление запроса Abon
DEALLOCATE Abon;

-- подготовка запроса Work
PREPARE Work AS
SELECT * FROM Paysumma
WHERE Payyear = :P1;
-- выполнение запроса Work
EXECUTE Work (2023);
-- удаление запроса Work
DEALLOCATE Work;

-- подготовка запроса Prep
PREPARE Prep (TYear, TMonth) AS
SELECT * FROM Paysumma WHERE Payyear = $1 AND Paymonth = $2;
-- выполнение запроса Prep
EXECUTE Prep (2023, 12);
-- выполнение запроса Prep
-- удаление запроса Prep
DEALLOCATE Prep;


/*
Запросы с параметрами

Разновидностью запроса-выборки является запрос с параметром. Такой
запрос при выполнении отображает в собственном диалоговом окне
приглашение на ввод интересующего пользователя значения критерия
отбора строк. Однотипные повторяющиеся запросы рекомендуется делать
параметризованными, так как это позволит не тратить время на их
подготовку и улучшить производительность системы. Кроме того,
параметризованные запросы исключают эксплуатацию SQL-инъекций.

Поэтому в общем случае секции могут быть параметризированными, т. е.
содержать переменные, значения которых определяются во время
выполнения клиентского приложения. Использование параметров
существенно повышает гибкость запросов за счет возможности ввода
пользователем или передачи из другого набора данных значений
параметров.

Параметрам перед выполнением запросов необходимо присвоить
определенные значения. Правила определения параметров и метод ввода
значений зависят от приложения. Имени переменной, например, в DBeaver
должен предшествовать символ двоеточия «:» или «$». При этом обращение
к параметрам осуществляется по имени или по номеру: $1 — первый
параметр, $2 — второй параметр и т. д. В приложениях, используемых в
настоящем курсе, для этого автоматически вызывается соответствующая
форма, в которой запрашиваются для ввода значения параметров.
Простыми примерами запроса с параметром в секции SELECT может быть
запрос, вычисляющий длину окружности заданного радиуса:

*/

SELECT 2 * PI() * :Par AS "Длина окружности";
SELECT 2 * PI() * $P AS "Длина окружности";
SELECT 2 * PI() * $1 AS "Длина окружности";

/*
В условии поиска секции HAVING, как и в условии поиска секции WHERE,
могут использоваться параметры.

*/

SELECT accountid, SUM(paysum) AS summa
FROM paysumma
WHERE accountid IN (:P1, :P2)
GROUP BY accountid
HAVING SUM(paysum) > $1;


/*
Примером использования параметров в других секциях может быть такой
запрос:
*/
SELECT *
FROM :Table
-- задать имя таблицы
ORDER BY :P DESC
-- задать имя столбца
    FETCH FIRST :N ROWS ONLY;
-- задать число выводимых строк

/*
Примерами использования CASE в параметризированном запросе могут быть
следующие запросы-валидаторы строки на соответствие шаблону ФИО
(Фамилия И. О.):
*/

SELECT CASE
           WHEN :Par SIMILAR TO '[A-ЯЁ][a-яё]*([A-ЯЁ].){2}'
               THEN 'Да'
           ELSE 'Нет'
           END
           AS "ФИО валидны";

/*
С помощью предиката SIMILAR TO и регулярных выражений проверяется
наличие допустимых символов в каждой из частей адреса электронной
почты. Кроме того, проверяется отсутствие некоторых символов.
Или, с применением функции регулярных выражений:

Здесь:
^[A-Za-z0-9._%+-]+ — начало строки, допустимые символы перед «@»;
@[A-Za-z0-9.-]+ — символ «@» и доменная часть;
.[A-Za-z]{2,}$ — точка и домен верхнего уровня из минимум 2 букв.
*/


SELECT
    CASE
        WHEN REGEXP_LIKE(:Email,
                         '^[A-z0-9._%+-]+@[A-z0-9.-]+.[A-z]{2,}$')
            THEN 'Да'
        ELSE 'Нет'
        END;

/*Многотабличные и вложенные запросы
4.1. Соединения таблиц
Системы управления базами данных предоставляют три основных способа
для извлечения данных из нескольких таблиц в рамках одного SQL-
запроса [12]: соединения (JOIN), вложенные запросы (подзапросы)
и составные запросы (UNION, INTERSECT, EXCEPT). Каждый из этих
подходов представляет собой отдельную стратегию, предназначенную для
решения специфических задач, и различается по своей логике, структуре
и области применения.

Соединения — одна из наиболее востребованных операций в процессе
SELECT. В нормализованных базах данных постоянно возникает
необходимость получать связанные данные из разных таблиц. Соединения
позволяют формировать результирующий набор из столбцов двух или более
таблиц, объединяя их в единый поток данных.

Стандарты SQL поддерживают два варианта синтаксиса соединения:

неявное соединение, соответствующее более старому стандарту, где
таблицы перечисляются в секции FROM через запятую, а условия их
связи задаются вместе с условиями фильтрации в секции WHERE.

явное соединение, введенное стандартом SQL:92 с использованием
конструкции JOIN ... ON. Этот синтаксис является более универсальным
и строго отделяет условие соединения таблиц от условий поиска.

Вложенным запросом (подзапросом) является запрос, заключенный в
круглые скобки и встроенный в основную команду (как правило, в
секции:
  SELECT,
  FROM,
  WHERE
  или
  HAVING).

Оба метода — и соединения, и подзапросы — работают со слиянием
потоков данных.
В некоторых случаях их роли пересекаются.

!!! Рационально
придерживаться следующего принципа:
1. Для сравнения значений с результатами агрегатных функций оптимально
  использовать подзапросы.

SELECT accountid, paysum, paydate
FROM paysumma
WHERE paysum > (SELECT AVG(paysum) FROM paysumma);

SELECT accountid, SUM(paysum) AS total
FROM paysumma
GROUP BY accountid
HAVING SUM(paysum) > (SELECT AVG(total)
                       FROM (SELECT SUM(paysum) AS total
                             FROM paysumma
                             GROUP BY accountid) t);

--Найти заявки с датой выполнения позже самой ранней даты по услуге
SELECT r.requestid, r.accountid, r.executiondate, r.failureid
FROM request r
WHERE r.executiondate > (SELECT MIN(executiondate)
                         FROM request
                         WHERE failureid = r.failureid);

2. В то время как для выборки информации из нескольких связанных
таблиц — соединения.

SELECT p.payfactid, p.accountid, a.fio, p.paysum, p.paydate
FROM paysumma p
JOIN abonent a ON p.accountid = a.accountid;

SELECT r.requestid, r.accountid, r.incomingdate, d.failurenm
FROM request r
JOIN disrepair d ON r.failureid = d.failureid;

Кроме того, подзапросы позволяют оперировать
данными, которые могут быть и не связаны напрямую.
--Найти абонентов, у которых нет платежей за 2025 год

SELECT a.accountid, a.fio
FROM abonent a
WHERE a.accountid NOT IN (SELECT DISTINCT accountid
                          FROM paysumma
                          WHERE payyear = 2025);


Составные запросы, реализуемые операторами
  UNION,
  INTERSECT,
  EXCEPT,
позволяют комбинировать строки из структурно совместимых наборов
данных в единый результирующий набор.
Эти подмножества не обязаны быть логически связаны —
они должны лишь иметь согласованные типы данных в соответствующих столбцах.

Иногда соединения называют горизонтальным объединением (столбцы
добавляются друг к другу),
а объединения — вертикальным (строки добавляются друг к другу).
Важно понимать, что эти методы не являются взаимоисключающими:
- соединения и объединения могут включать подзапросы;
- а многие подзапросы, в свою очередь, содержат соединения.

При проектировании базы данных данные обычно разбиваются на несколько
связанных таблиц, чтобы поддерживать хорошо структурированную и
организованную схему. Этот процесс известен как нормализация, и он
помогает уменьшить избыточность данных и улучшить их целостность,
чтобы добиться лучшей организации, гибкости и производительности.

Соединения вступают в игру, когда нужно извлечь данные из нескольких
связанных таблиц.
В SQL соединения используются для объединения данных из двух или
более таблиц на основе связанного столбца, обычно внешнего ключа.
Соединения позволяют объединять и фильтровать данные
из разных таблиц для создания значимого результирующего набора,
предоставляя мощный способ запрашивать и анализировать данные!!!

По умолчанию PostgreSQL 17 (как и предыдущие версии) позволяет 100
одновременных соединений. Этот параметр можно изменить в файле
postgresql.conf, но увеличение требует учета доступных системных
ресурсов.


Освоив соединение нескольких таблиц, можно обрабатывать сложные
взаимосвязи данных и извлекать ценную информацию из БД.

Неявное соединение
Как уже отмечалось, различные виды соединений используются для
получения составных наборов данных, содержащих столбцы из нескольких
таблиц.
Формат секций FROM и WHERE при неявном внутреннем соединении
таблиц имеет вид

FROM <таблица1> [AS] [псевдоним1], <таблица2> [AS] [псевдоним2]...
[WHERE <условие_соединения> [AND <условие_поиска>]]


операторы сравнения: =, <, >, <=, >=, <>, !=;

диапазоны BETWEEN;

шаблоны: (I)LIKE, NOT (I)LIKE;

логические операторы: AND, OR, NOT;

функции: UPPER(), EXTRACT(), CAST() и т.д.;

арифметические операции: +, -, *, /.

Такое соединение называют внутренним
Особенности синтаксиса неявных соединений:

использование более одной таблицы в секции FROM (список таблиц с
разделяющими запятыми);

среди остальных условий поиска секции WHERE применяется операция
сравнения для создания выражения, которое определяет столбцы,
используемые для соединения указанных таблиц (<условие_соединения>).
При этом соединение на основе точного равенства между двумя столбцами
называется соединением по равенству (эквивалентности).

Алгоритм выполнения запросов на неявное соединение таблиц включает
несколько этапов:
1.вычисляется декартово произведение таблиц, входящих в соединение,
т.е. для каждой строки одной из таблиц берутся все возможные
сочетания строк из других таблиц;
2.производится отбор строк из полученной таблицы согласно условиям
в секции WHERE;
3.осуществляется проекция (вывод) по столбцам, указанным в списке
вывода.

Среди запросов на соединение таблиц наиболее распространены запросы к
таблицам, которые связаны с помощью отношения «родитель-потомок».
Чтобы использовать в запросе отношение «родитель-потомок», необходимо
задать <условие_соединения>, в котором первичный ключ родительской
таблицы сравнивается с внешним ключом таблицы-потомка (обычно имена
этих столбцов совпадают в связанных таблицах). Несмотря на то, что
в языке определения данных присутствует возможность декларативного
задания первичных и внешних ключей таблиц, связь, о которой идёт речь,
должна всегда явно указываться в секции WHERE запроса SELECT.

Например, необходимо вывести для всех абонентов названия улиц,
на которых они проживают/ Для этого нужно каждую строку
из таблицы Abonent соединить по столбцу внешнего ключа (столбец
Streetid в таблице Abonent) с таблицей улиц (столбец Streetid
в таблице Street).
*/

SELECT abonent.fio, street.streetnm
FROM abonent,
     street
WHERE abonent.streetid = street.streetid;

SELECT a.fio, s.streetnm
FROM abonent a,
     street s
WHERE a.streetid = s.streetid;

/*
Вот извлечённый текст с исправлением опечатки (лишний пробел в N. NachisIsum → N.NachisIsum) и разбивкой на строки не более 90 знаков (с пробелами):

WHERE A.StreetId = S.StreetId;

В многотабличном запросе можно комбинировать условие соединения,
в котором задаются связанные столбцы, с условиями поиска. Например,
для вывода ФИО абонентов, у которых за 2025 г. значения начислений
превышают 2050, можно использовать запрос:

*/


SELECT a.fio, n.nachislsum
FROM abonent a,
     nachislsumma n
WHERE a.accountid = n.accountid
  AND nachislyear = 2025
  AND nachislsum > 2050;

/*
Термин «соединение» применяется к любому запросу, который объединяет
данные нескольких таблиц БД путём сравнения значений в парах столбцов
этих таблиц.
Самыми распространёнными являются соединения по равенству.
*/


/*
Кроме того, имеется возможность соединять таблицы с помощью других
операций сравнения.
Например, чтобы вывести все комбинации ФИО
абонентов и исполнителей ремонтных заявок так, чтобы ФИО абонентов
были различными при сравнении,
можно использовать следующий запрос
с соединением таблиц по неравенству:
*/

SELECT a.fio, e.fio
FROM abonent a,
     executor e
WHERE a.fio != e.fio;

/*
Как следует из данного примера, соединения таблиц по условиям,
отличающимся от равенства, во многом искусственны.
Поэтому в подавляющем большинстве случаев таблицы соединяются по равенству,
а другие операции сравнения используются для дополнительного отбора
строк в условии поиска.

Необходимо отметить ещё одну важную
особенность предыдущего запроса. Он реализует динамическую связь между
таблицами Abonent и Executor.

Пример запроса для вывода
всех данных абонентов, проживающих на улицах с отличающимися на 5
значениями идентификаторов:
*/
SELECT DISTINCT a.*
FROM abonent a
         JOIN abonent b ON ABS(a.streetid - b.streetid) = 5;


/*
Язык SQL позволяет соединять три таблицы и более, используя ту же
самую методику, что и при соединении данных из двух таблиц. Например,
чтобы в предыдущем запросе вместе со значениями начислений вывести
и значения плат за тот же период и за ту же услугу, можно
использовать соединение трёх таблиц:
*/


SELECT a.fio, n.nachislsum, p.paysum
FROM abonent a,
     nachislsumma n,
     paysumma p
WHERE a.accountid = n.accountid
  AND a.accountid = p.accountid
  AND n.serviceid = p.serviceid
  AND n.nachislmonth = p.paymonth
  AND n.nachislyear = p.payyear
  AND n.nachislyear = 2025
  AND n.nachislsum > 2050;

/*
Следует отметить, что результат выполнения запроса на неявное соединение
более двух таблиц не зависит от порядка перечисления этих таблиц в
секции FROM и от порядка указания условий соединения в секции WHERE.
В таблицах соединяются только те строки, для которых выполняется
<условие_соединения>, и независимо от порядка соединения результат
будет одинаковый.

Например, чтобы определить исполнителей, которым назначены ремонтные
заявки абонентов, необходимо соединить таблицы Abonent, Request и
Executor.
Для этого нужно каждую строку из таблицы Request соединить
по полю внешнего ключа Accountid со справочником абонентов (столбец
Accountid в таблице Abonent),
а по полю внешнего ключа Executorid — со справочником исполнителей
(столбец Executorid в таблице Executor).
Для этого можно использовать такой запрос.

Таким образом, при выполнении операции неявного соединения данные из
двух таблиц комбинируются с образованием пар соединённых строк,
в которых значения сопоставляемых столбцов являются одинаковыми.

Если одно из значений в сопоставляемом столбце одной таблицы не
совпадает ни с одним из значений в сопоставляемом столбце другой
таблицы, то соответствующая строка удаляется из результирующей
таблицы!!! ВАЖНО
*/

SELECT DISTINCT a.fio AS fio_abonent, e.fio AS fio_executor
FROM abonent a,
     executor e,
     request r
WHERE r.accountid = a.accountid
  AND r.executorid = e.executorid
ORDER BY a.fio;

/*
Явное соединение
Другим способом связывания, а точнее, присоединения таблиц, является
явное соединение, осуществляемое с помощью оператора JOIN. Этот способ
позволяет, во-первых, избежать выполнения декартова произведения
таблиц, а во-вторых, получить более полную информацию. Формат секции
FROM при таком соединении таблиц имеет вид

FROM
<таблица1> [псевдоним1] <тип_соединения1>
{<таблица2> [псевдоним2]
[{ON <условие_соединения1> | USING (<список_столбцов>)}]}
[<тип_соединения2> <таблица3> [псевдоним3]
[{ON <условие_соединения2> | USING (<список_столбцов>)}]...
| [LATERAL] (табличный_подзапрос) [AS] псевдоним
[(псевдоним_столбца [, ...])]]

где
<тип_соединения> ::=
{CROSS JOIN
| [NATURAL] [{INNER | {LEFT | RIGHT | FULL} [OUTER]}] JOIN}

Здесь указываются:
-имена соединяемых таблиц;
-типы соединений между таблицами;
-условия соединений.

Существуют различные типы явного соединения таблиц.

Перекрестное соединение CROSS JOIN используется без конструкции
ON <условие_соединения>. CROSS JOIN эквивалентно декартовому
произведению таблиц. Иными словами, конструкция ... FROM A CROSS JOIN
B полностью эквивалентна конструкции ... FROM A, B.

Перекрестное (полное) соединение группирует строки таблиц по правилу
«каждая с каждой». Первая строка первой таблицы соединяется с первой
строкой второй таблицы, потом первая строка первой таблицы соединяется
со второй строкой второй таблицы и так до тех пор, пока в первой
таблице не закончатся строки.

Уточненные соединения, которые предполагают явное задание
условия соединения после ON или имён столбцов, по которым производится
соединение, после USING.

Для визуального представления различных типов соединения часто
используются диаграммы Эйлера — Венна (также используется сокращённое
название — диаграммы Венна). Диаграммы Венна представляют собой
схематичное изображение всех возможных пересечений нескольких множеств.
Необходимо отметить, что хотя таблицы реляционной базы данных не
являются множествами, но с определённой степенью условности диаграммы
Венна можно считать достаточно полезными для понимания, как происходит
выбор данных из таблиц с использованием соединений.

Среди уточненных соединений выделяют основные:

INNER JOIN — «внутреннее» соединение. В таблицах
соединяются только те строки, для которых выполняется
<условие_соединения>: все значения соединяемых столбцов одной
таблицы попарно находятся в заданном оператором сравнения отношении
с соответствующими значениями соединяемых столбцов другой таблицы
(является аналогом неявного соединения). Остальные строки из
соединения исключаются. Этот вид соединения используется чаще всего;

OUTER JOIN — «внешнее» соединение. Ключевое слово OUTER является
необязательным и имеет смысл только в комбинации с ключевым словом
определения типа внешнего соединения. Отличие внешнего соединения
от внутреннего заключается в том, что при внешнем строка одной
таблицы может соединяться с «пустой строкой» из другой таблицы.
Несмотря на кажущуюся странность такого действия, оно отражает
определённый смысл, имеющийся в бизнес-логике. Внешние соединения
бывают трёх типов:

LEFT [OUTER] JOIN — «левое (внешнее)» соединение
выполняется сравнение значений соединяемых столбцов и в результат
запроса включаются все строки левой таблицы и только те строки
правой таблицы, для которых выполняется <условие_соединения>
(для строк из левой таблицы, для которых не найдено соответствия
в правой таблице, в столбцы, извлекаемые из правой таблицы,
заносится NULL);

RIGHT [OUTER] JOIN — «правое (внешнее)» соединение (рис. 4.7);
является зеркальным отображением левого внешнего соединения, в нём
также сначала выполняется сравнение значений соединяемых столбцов,
но в результате запроса включаются все строки правой таблицы и только
те строки левой таблицы, для которых выполняется <условие_соединения>
(для строк из правой таблицы, для которых не найдено соответствия
в левой таблице, в столбцы, извлекаемые из левой таблицы, заносится
NULL);

FULL [OUTER] JOIN — «полное (внешнее)» соединение — это комбинация
«левого» и «правого» соединений таблиц; позволяет возвращать
все строки как из правой, так и из левой таблицы, включая те, которые
не удовлетворяют условиям соединения (строки, у которых нет пары по
соединяемым столбцам, возвращаются с NULL в выходных столбцах
«противоположной» таблицы). Алгоритм его работы следующий.
-сначала формируется таблица на основе внутреннего соединения
(INNER JOIN);
-в таблицу добавляются значения, не вошедшие в результат формирования
из правой таблицы (LEFT JOIN). Для них соответствующие строки из
правой таблицы заполняются NULL;
-в таблицу вывода добавляются значения, не вошедшие в результат
формирования из левой таблицы (RIGHT JOIN). Для них соответствующие
строки из левой таблицы заполняются NULL.


Если не указан тип соединения в JOIN, то он по умолчанию принимается
за INNER. Несмотря на это, при реализации внутреннего соединения
рекомендуется явно задавать INNER.

Естественное соединение (NATURAL JOIN). Стандарт SQL определяет
это соединение как результат соединения таблиц по всем одноимённым
столбцам. Соединяются те строки, в которых все значения одноимённых
столбцов одной таблицы попарно совпадают с соответствующими
значениями одноимённых столбцов другой таблицы. Остальные строки
из соединения исключаются. Если одноимённых столбцов нет, то
выполняется перекрестное соединение CROSS JOIN. Естественное
соединение не требует задания каких-либо условий (используется без
ON <условие_соединения>). Может применяться при внутреннем и
внешнем соединении таблиц.

В уточненных явных соединениях <условие_соединения>, указываемое
после ON, аналогично рассмотренному выше условию соединения в секции
WHERE. При соединении данных из нескольких таблиц конструкции JOIN
и WHERE в большинстве случаев взаимозаменяемы. Однако зачастую
конструкция JOIN является более удобной для понимания. Например,
конструкция JOIN ... ON даёт возможность отличать условие соединения,
указываемое после ON, от условия поиска, указываемого в секции WHERE.

Например, необходимо вывести для всех абонентов названия улиц,
на которых они проживают. Реализация запроса посредством
явного внутреннего соединения таблиц (соединение только для совпадающих
строк), позволяющего выбрать только строки, которые есть и в таблице
Street, и в таблице Abonent


-- LEFT JOIN: условие в ON (оставляет все строки из левой таблицы)
FROM Abonent A
LEFT JOIN Paysumma P ON A.accountid = P.accountid AND P.paysum > 1000;

-- LEFT JOIN: условие в WHERE (превращает LEFT JOIN в INNER JOIN!)
FROM Abonent A
LEFT JOIN Paysumma P ON A.accountid = P.accountid
WHERE P.paysum > 1000;  -- убирает NULL-строки!
Вот почему важно разделять: в LEFT JOIN условие в ON применяется
до соединения, а в WHERE — после.

*/

SELECT *
FROM abonent a
         LEFT JOIN paysumma p
                   ON a.accountid = p.accountid
                       AND p.paysum > 1000;
-- присутствуют NULL-строки где нет сумм!


SELECT *
FROM abonent a
         LEFT JOIN paysumma p
                   ON a.accountid = p.accountid
WHERE p.paysum > 1000;
-- убирает NULL-строки, где нет сумм!


SELECT a.fio, s.streetnm
FROM abonent a
         INNER JOIN street s ON a.streetid = s.streetid;

SELECT a.fio, s.streetnm
FROM abonent a
         NATURAL JOIN street s;


/*Если в этом же примере использовать правое внешнее соединение, то
получится список всех улиц и проживающих на них абонентов, если
таковые имеются.
Запрос выглядит так:
*/


SELECT a.fio, s.streetnm
FROM abonent a
         RIGHT JOIN street s ON a.streetid = s.streetid;

SELECT a.fio, s.streetnm
FROM abonent a
         NATURAL RIGHT JOIN street s;

/*

Для каждого абонента выводится название улицы, на которой он проживает,
а если на какой-либо улице не проживают абоненты, то в столбце Fio
строки для данной улицы выводится NULL.

Если в данном примере использовать левое внешнее соединение,
то результат будет совпадать с результатом внутреннего соединения
, так как в учебной БД нет абонентов, для которых
не указана улица проживания.

Если же использовать полное внешнее соединение (соединение со всеми
строками из обеих таблиц) для получения всех строк, относящихся к
левой и правой таблицам, а также их внутреннему соединению
*/

SELECT A.Fio, S.Streetnm
FROM Abonent A FULL JOIN Street S
ON A.Streetid = S.Streetid;

SELECT A.Fio, S.Streetnm
FROM Abonent A NATURAL FULL JOIN Street S;

/*
то для данного примера результат будет совпадать с результатом
правого внешнего соединения. Запрос выводит наименование
улиц и ФИО абонентов, проживающих на этих улицах, а также наименование
улиц, на которых абоненты не проживают. Здесь важно указать, что если
в таблице Abonent имелись бы абоненты с неопределённым значением
Streetid, то они также были бы выведены.

Нужно отметить, что не обязательно в качестве имён соединяемых таблиц
использовать только явные имена таблиц или только псевдонимы таблиц.
Допускается применять их сочетание. Запрос, использующий по умолчанию
«внутреннее» соединение таблиц, вернёт правильный результат:
*/

SELECT abonent.fio, s.streetid, s.streetnm
FROM abonent
         JOIN street s ON abonent.streetid = s.streetid;

/*

В PostgreSQL существует возможность более простого (по сравнению
с конструкцией ON) задания условия соединения — соединение по именам
столбцов. Если таблицы соединяются по одноимённым столбцам, то можно
использовать опцию

USING (<список_столбцов>)

В <список_столбцов> указываются имена всех столбцов, по значениям
в которых требуется соединить таблицы.

При создании соединения по именам столбцов нужно помнить:

что все столбцы, указанные в списке столбцов, должны существовать
в соединяемых таблицах;

по всем указанным столбцам автоматически создаётся такое соединение,
как если бы было указано <таблица1>.столбец = <таблица2>.столбец
в секции WHERE при неявном соединении или после ON при явном
соединении;

по именам столбцов можно соединить только две таблицы.

Например, рассмотренный ранее запрос, выводящий для всех абонентов
названия и идентификаторы улиц, можно реализовать с использованием
секции USING:
*/

SELECT a.fio, streetid, s.streetnm
FROM abonent a
         INNER JOIN street s USING (streetid);

/*
Явное соединение таблиц можно также применять с секцией WHERE.
Следующий запрос выводит информацию о каждом исполнителе, включая
массив дат выполнения заявок, которые он выполнил после 1 января
2024 года

Запрос группирует данные по исполнителям и использует агрегатную
функцию ARRAY_AGG для сбора дат выполнения заявок в массив.
Эту задачу аналогичным образом можно решить, используя функцию
STRING_AGG.
*/

SELECT e.*, ARRAY_AGG(r.executiondate) AS "Дата выполнения"
FROM executor e
         JOIN request r USING (executorid)
WHERE r.executiondate > '01.01.2024'
GROUP BY e.executorid;


/*
Рассмотрим ещё три соединения на базе основных для решения прикладных
задач бизнес-логики. В начале найдём исполнителей, не назначенных на
ремонт, если такие имеются. Такой запрос должен вернуть все строки
в левой таблице, которые не соответствуют никаким строкам в правой
таблице. Это соединение (Left Excluding JOIN)
записывается следующим образом
*/

SELECT e.fio, r.requestid
FROM executor e
         LEFT JOIN request r USING (executorid)
WHERE r.executorid IS NULL;

/*
Выведем номера ремонтных заявок, на выполнение которых не назначены
исполнители. Запрос выведет все строки в правой таблице, которые не
соответствуют никаким строкам в левой таблице. Такое
соединение (Right Excluding JOIN) записывается в следующем виде
*/

SELECT e.fio, r.requestid
FROM executor e
         RIGHT JOIN request r USING (executorid)
WHERE e.executorid IS NULL;


/*
Наконец, построим запрос, решающий обе предыдущие бизнес-задачи.
Примером его может быть запрос с полным внешним соединением для
получения данных, не относящихся к левой и правой таблицам одновременно
(Outer Excluding JOIN).
Этот запрос вернёт все строки в левой таблице
и все строки в правой таблице, которые не совпадают
Такое соединение реализуется так:
*/

SELECT e.fio, r.requestid
FROM executor e
         FULL OUTER JOIN request r USING (executorid)
WHERE e.executorid IS NULL
   OR r.executorid IS NULL;


/*
Например, вывести ФИО каждого абонента и список оплаченных им услуг
можно так:
*/

SELECT a.fio AS "ФИО", ARRAY_AGG(DISTINCT s.servicenm) AS "услуги"
FROM abonent a
         LEFT JOIN paysumma p USING (accountid)
         LEFT JOIN services s USING (serviceid)
GROUP BY a.fio;


/*
Программируя запрос, иногда можно допустить неточность, не разделив
условия внешнего соединения таблиц с условиями фильтрации строк.
Пусть, например, требуется вывести номера лицевых счетов абонентов,
количество поданных ими заявок и наименования соответствующих
неисправностей, устраняемых исполнителем с идентификатором 3. Эту
задачу можно решить так:
*/

SELECT r.accountid, d.failurenm, r.executorid, COUNT(r.failureid)
FROM disrepair d
         RIGHT JOIN request r ON d.failureid = r.failureid
   AND r.executorid = 3
GROUP BY d.failurenm, r.executorid, r.accountid;


/*Синтаксических ошибок нет, но результат выполнения запроса не совсем
правильный: все заявки (Request) с Executorid ≠ 3 с NULL в Disrepair.
Если же использовать секцию WHERE для отбора заявок, назначенных
исполнителю с идентификатором 3, следующий запрос позволит получить
нужную информацию:
*/

SELECT r.accountid, d.failurenm, COUNT(r.failureid)
FROM disrepair d
         RIGHT JOIN request r
                    ON d.failureid = r.failureid
WHERE r.executorid = 3
GROUP BY d.failurenm, r.accountid;


/*
Приведём идеологически улучшенную версию запроса:
Из разбора приведённого примера следует:
1.LEFT / RIGHT JOIN с условием в WHERE превращается в INNER JOIN;
2.Если нужно оставить «без пары», следует переносить условие в ON.


Итоговое правило
Что нужно сделать	Куда писать условие
Соединить таблицы по ключу	ON
Отфильтровать строки из левой таблицы	WHERE
Отфильтровать строки из правой таблицы, но сохранить все строки из левой	ON
Проверить, что нет соответствия в правой таблице	WHERE ... IS NULL
Отфильтровать строки после соединения (неважно, из какой таблицы)	WHERE
Золотое правило: Если вы используете LEFT JOIN и хотите оставить все
строки из левой таблицы — не ставьте условия на столбцы правой
таблицы в WHERE (кроме проверки IS NULL). Иначе LEFT JOIN превратится
в INNER JOIN.

Условие в ON решает, КАК соединять.
Условие в WHERE решает, ЧТО оставить.

Если вы в WHERE отсекаете NULL из правой таблицы
— вы отсекаете строки, ради которых вы и делали LEFT JOIN.
*/


SELECT r.accountid,
       d.failurenm,
       d.failureid,
       COUNT(*) AS request_count
FROM request r
         LEFT JOIN disrepair d
                   ON r.failureid = d.failureid
WHERE 1=1
    --r.executorid = 3
and d.failureid = 2
GROUP BY r.accountid, d.failurenm,d.failureid;

SELECT r.accountid,
       d.failurenm,
       d.failureid,
       COUNT(*) AS request_count
FROM request r
         INNER JOIN disrepair d
                    ON r.failureid = d.failureid
WHERE 1=1
    --r.executorid = 3
  AND d.failureid = 2
GROUP BY r.accountid, d.failurenm, d.failureid;

/*
Рассмотрим ещё примеры запросов, в которых используются явное
соединение таблиц и условие поиска в секции WHERE.
Например, если предыдущий запрос с явным правым соединением дополнить
условием и выполнить запрос

то будет выведена информация только об улицах с кодами 1, 2 и 5,
на которых не проживают абоненты.
*/

SELECT a.fio, s.streetid, s.streetnm
FROM abonent a
         RIGHT JOIN street s USING (streetid)
WHERE a.streetid IS NULL;

/*
Для выбора ФИО абонентов, которые производили оплату услуги с
идентификатором 2 позднее 1 октября 2023 г., запрос с
явным «внутренним» соединением может быть построен так:
*/

SELECT a.fio, p.paysum,p.serviceid
FROM abonent a
         JOIN paysumma p USING (accountid)
WHERE p.serviceid = 2
  AND p.paydate > '01.10.2023';


/*
Сортировка в запросе с соединением таблиц производится по
результирующему набору данных!!!

Приведём решение такой аналитической задачи.
Вывести ФИО абонентов и значения всех их платежей,
произведённых в течение количества дней
с даты, задаваемых соответственно параметрами «Дней» и «С_даты»,
например в течение 30 дней, начиная с 10.08.2023.
Результат упорядочить по дате платежей:
*/

SELECT
    A.Fio AS "ФИО",
    P.Paysum AS "Платеж",
    P.Paydate AS "Дата"
FROM Abonent A JOIN Paysumma P USING(AccountId)
WHERE P.Paydate >= :C_даты::DATE
  AND P.Paydate < :C_даты::DATE + :Дней
ORDER BY 3;

/*
В запросе с соединением нескольких таблиц необходимо учитывать
возможность наличия NULL в соединяемых столбцах, а также необходимость
выводить строки, значения в которых есть в одной из таблиц в ключевых
полях, а в другой нет.

В соединяемых столбцах могут быть NULL — и это влияет на результат
Нужно решить, что делать со строками, у которых нет пары в другой
таблице — включать их в результат или нет
В SQL NULL = NULL даёт не TRUE, а NULL (неизвестно). Поэтому строки с NULL
в соединяемом столбце никогда не соединяются друг с другом.
*/

/*
Пусть требуется вывести по каждому абоненту его номер лицевого счета,
ФИО и количество поданных заявок.
В следующих трёх запросах используется
COUNT, и в зависимости от типа соединения (JOIN, LEFT JOIN, RIGHT JOIN)
поведение может различаться.
Вот что важно учитывать:

-COUNT(*) считает все строки, даже если в них есть NULL;
-она не различает, из какой таблицы пришло значение — просто считает
строки.
*/

/*

COUNT считает только тех абонентов, у которых есть хотя бы одна заявка;
COUNT(*) здесь корректен, потому что строки будут только при совпадении
в обеих таблицах;
проблем нет, если цель — анализировать только активных (подавших заявки)
абонентов.
*/

SELECT a.accountid, a.fio, COUNT(*) req_count
FROM abonent a
         JOIN request r USING (accountid)
GROUP BY a.accountid
ORDER BY a.accountid;


/*
LEFT JOIN вернёт всех абонентов, включая тех, у кого нет заявок
(Request будет NULL);
COUNT(*) всегда считает строку, даже если в Request все NULL. В
результате абоненты без заявок получат Req_count = 1, потому что
строка есть, хотя она — результат соединения с NULL;
нужно использовать COUNT(R.RequestId) (или любой не NULL столбец из
Request) — будет считать только ненулевые записи из Request.
*/

SELECT a.accountid, a.fio, COUNT(r.requestid) req_count
FROM abonent a
         LEFT JOIN request r USING (accountid)
GROUP BY a.accountid
ORDER BY a.accountid;

/*
RIGHT JOIN даст всех, у кого есть заявка — даже если абонент не найден
(например, если Request.AccountId не имеет соответствия в Abonent);
A.AccountId может быть NULL, если в Request нет соответствия в Abonent;
GROUP BY A.AccountId может сгруппировать по NULL, что вызовет ошибку
логики: как интерпретировать заявку без абонента?

COUNT(*) снова посчитает строку, даже если A.AccountId IS NULL;
нужно явно фильтровать WHERE A.AccountId IS NOT NULL,
либо использовать R.AccountId в GROUP BY.
*/


SELECT a.accountid, a.fio, COUNT(*) req_count
FROM abonent a
         RIGHT JOIN request r USING (accountid)
WHERE a.accountid IS NOT NULL
GROUP BY a.accountid
ORDER BY a.accountid;


/*
Как следует из синтаксиса запроса SELECT, в условии соединения таблиц
можно использовать произвольное число логических выражений (как в
секции WHERE). Например, для получения таблицы соответствия фактов
начислений фактам платежей необходимо выполнить 4 соединения таблиц
Paysumma и Nachislsumma, 2 из которых статические (по номеру лицевого
счета и идентификатору услуги) и 2 динамические (по году и месяцу
периода оплаты и начисления):
*/

SELECT n.accountid,
       n.serviceid,
       n.nachislsum,
       p.paysum,
       n.nachislmonth,
       n.nachislyear
FROM nachislsumma n
         LEFT JOIN paysumma p ON n.accountid = p.accountid
    AND n.serviceid = p.serviceid
    AND n.nachislmonth = p.paymonth
    AND n.nachislyear = p.payyear
ORDER BY n.accountid, n.serviceid, n.nachislmonth, n.nachislyear;

/*
В результате выполнения данного запроса будет обнаружено начисление
с идентификатором 78 абоненту с лицевым счётом '443690' по услуге
«Водоснабжение» за сентябрь 2024 года, которое им не было оплачено.

*/


/*
С помощью оператора JOIN можно соединять три таблицы и более.
Порядок соединений может уточняться круглыми скобками, так как результат
нескольких внешних соединений зависит от порядка их выполнения.
Например, вывести 10 первых строк с адресом и ФИО абонентов,
проживающих на улицах, наименования которых начинаются с букв «Г»
или «М», указав для каждого абонента значения начислений, можно с
помощью запроса

*/

SELECT s.streetnm, a.houseno AS house, a.flatno AS flat, a.fio, n.nachislsum
FROM abonent a
         RIGHT JOIN street s USING (streetid)
         FULL JOIN nachislsumma n USING (accountid)
WHERE (s.streetnm LIKE '%М%')
   OR (s.streetnm LIKE '%Г%')
ORDER BY 1, 2, 3
    FETCH NEXT 10 ROWS ONLY;

/*

В заключение в качестве примера реализуем следующим запросом
динамическую связь между таблицами абонентов и исполнителей для
поиска однофамильцев:

*/

SELECT a.fio, e.fio
FROM abonent a
         INNER JOIN executor e
                    ON SUBSTR(e.fio, 1, LENGTH(e.fio) - 6)
                           = SUBSTR(a.fio, 1, LENGTH(a.fio) - 7)
                        OR SUBSTR(e.fio, 1, LENGTH(e.fio) - 6)
                           = SUBSTR(a.fio, 1, LENGTH(a.fio) - 6);

SELECT a.fio AS abonent_fio, e.fio AS executor_fio
FROM abonent a
         JOIN executor e ON a.fio != e.fio -- не сравниваем сами с собой
    AND SUBSTR(a.fio, 1, POSITION(' ' IN a.fio) - 1)
                                = SUBSTR(e.fio, 1, POSITION(' ' IN e.fio) - 1);


-- SPLIT_PART(строка, разделитель, номер_части)
SELECT a.fio, e.fio
FROM abonent a
         JOIN executor e ON a.fio != e.fio
    AND SPLIT_PART(a.fio, ' ', 1) = SPLIT_PART(e.fio, ' ', 1);

-- С учётом регистра (приводим к нижнему)
SELECT a.fio, e.fio
FROM abonent a
         JOIN executor e ON a.fio != e.fio
    AND LOWER(SPLIT_PART(a.fio, ' ', 1))
                                = LOWER(SPLIT_PART(e.fio, ' ', 1));


-- Найти всех абонентов и исполнителей с одинаковыми фамилиями
-- (с группировкой для удобства)

SELECT SPLIT_PART(a.fio, ' ', 1)                AS surname,
       STRING_AGG(DISTINCT 'А:' || a.fio, ', ') AS abonents,
       STRING_AGG(DISTINCT 'И:' || e.fio, ', ') AS executors
FROM abonent a
         JOIN executor e ON LOWER(SPLIT_PART(a.fio, ' ', 1))
    = LOWER(SPLIT_PART(e.fio, ' ', 1))
GROUP BY surname
ORDER BY surname;

-- Извлекаем фамилию как последовательность русских букв в начале строки
SELECT a.fio, e.fio
FROM abonent a
         JOIN executor e ON a.fio != e.fio
    AND SUBSTRING(a.fio FROM '^[А-Яа-яЁё]+')
                                = SUBSTRING(e.fio FROM '^[А-Яа-яЁё]+');


-- Компактное решение в одном запросе
SELECT a.fio, e.fio
FROM abonent a
         JOIN executor e
              ON LOWER(
                         REGEXP_REPLACE(SPLIT_PART(a.fio, ' ', 1), '(ова|ева|ина|ына|ая|а)$', '')
                 ) = LOWER(
                         REGEXP_REPLACE(SPLIT_PART(e.fio, ' ', 1), '(ова|ева|ина|ына|ая|а)$', '')
                     );
/*
Примечание: Данный запрос использует обрезание строки по длине,
предполагая, что в конце ФИО указаны инициалы (например, "Иванов И.И.").
Такое решение является хрупким и приведено скорее как демонстрация
возможности нестандартных условий соединения.
*/

/*
Селекция (горизонтальное подмножество) создаётся из тех строк
таблицы, которые удовлетворяют заданным условиям:
*/

SELECT *
FROM Abonent
WHERE Phone IS NOT NULL;

/*
Проекция (вертикальное подмножество) создаётся из указанных
столбцов таблицы:
*/

SELECT DISTINCT streetid
FROM abonent;

--с последующим исключением избыточных дубликатов строк.

/*
Декартово произведение. Для получения декартова произведения
таблиц в секции FROM необходимо указать перечень переменных таблиц,
а в секции SELECT — все их столбцы.
Переменными таблицы Abonent
(12 строк) и Street (8 строк) и получим результирующую таблицу
(96 строк):
*/
SELECT Abonent.*, Street.*
FROM Abonent
CROSS JOIN Street;

SELECT Abonent, Street
FROM Abonent, Street;

SELECT * FROM Abonent, Street;


/*
Экви-соединение. Для получения экви-соединения таблиц необходимо
для декартова произведения таблиц установить имеющее смысл
соответствие на основе равенства между столбцами соединяемых таблиц.
Например, запрос на неявное экви-соединение таблиц Abonent и Street
будет выглядеть таким образом:
*/

SELECT *
FROM abonent a,
     street s
WHERE a.streetid = s.streetid;

/*
Такой же результат может быть получен, если использовать запрос на
явное соединение:
*/

SELECT *
FROM abonent
         JOIN street USING (streetid);

/*
Естественное соединение. Для получения естественного соединения
таблиц необходимо в экви-соединении таблиц исключить дубликаты
повторяющихся столбцов (входящих в условие соединения). Для
предыдущего примера естественное соединение таблиц Abonent и Street
по столбцу Streetid по всем общим столбцам выглядит так:
*/

SELECT accountid, s.streetid, streetnm, houseno, flatno, fio, phone
FROM Abonent A, Street S
WHERE A.Streetid = S.Streetid;


/*Аналогичный результат может быть получен, если использовать следующий
запрос на явное естественное соединение:*/

SELECT accountid, streetid, streetnm, houseno, flatno, fio, phone
FROM abonent
         NATURAL JOIN street;

/*
Композиция. Для создания композиции таблиц нужно исключить из
вывода все столбцы, по которым проводилось соединение таблиц:
*/


SELECT accountid, streetnm, houseno, flatno, fio, phone
FROM abonent a,
     street s
WHERE a.streetid = s.streetid;

/*
Тета-соединение. Тета-соединение предназначено для тех случаев,
когда необходимо соединить две таблицы на основе некоторых условий,
отличных от равенства.
Получить тета-соединение таблиц Abonent и Street
можно таким образом:
*/

SELECT *
FROM abonent,
     street
WHERE abonent.streetid < street.streetid;


/*
Asof-соединение. Применяется для столбцов с разным временем путём
их смещения и соединения в одном запросе.
Для каждого значения в одном
временном ряду находится ближайшее значение в другом, и они возвращаются
в одной строке.
Число значений во временных рядах может не совпадать.
Например, следующий запрос по каждой ремонтной заявке абонентов находит
их платёж с датой ближе всего (раньше или позже) от даты регистрации
заявки в днях:

В приведённом запросе производится соединение таблиц, которые не
связаны с помощью отношения «родитель-потомок».
*/


SELECT requestid                            AS "№ заявки",
       r.accountid                          AS "№ л. с.",
       MIN(ABS(r.incomingdate - p.paydate)) AS "Дней"
FROM paysumma p
         JOIN request r USING (accountid)
GROUP BY requestid, r.accountid
ORDER BY r.requestid;

/*
Вычитание. Это соединение позволяет в одной из двух таблиц,
имеющих общие ключи, найти строки, которых нет в другой таблице

Например, для выяснения улиц, в домах которых не проживают абоненты,
можно использовать запрос
*/

SELECT s.streetid
FROM street s
         LEFT JOIN abonent a USING (streetid)
WHERE a.streetid IS NULL
ORDER BY 1;

SELECT s.streetid
FROM abonent a
         RIGHT JOIN street s USING (streetid)
WHERE a.streetid IS NULL
ORDER BY 1;


/*
Пересечение. Позволяет из двух таблиц, имеющих общие ключи,
найти значения, которые имеются в обеих таблицах
Например, для получения списка улиц, в домах на которых проживают
абоненты, можно использовать такой запрос:

Этот запрос решает ту же задачу, что и аналогичные запросы,
приведённые выше, соответственно с неявным и явным внутренним
соединением.
*/

SELECT DISTINCT s.streetid
FROM street s
         INNER JOIN abonent a USING (streetid)
ORDER BY 1;


/*
Полу-соединение. Это нестандартное соединение двух таблиц,
являющееся результатом последовательного выполнения операции
соединения этих таблиц и операции взятия проекции полученной таблицы
по столбцам первой таблицы.
Полу-соединение возвращает одну строку из таблицы,
если для этой строки есть хотя бы одна строка во второй
таблице (совпадающая по условию соединения).

Например, вывести абонентов, имеющих заявки с неисправностью с
идентификатором 2:

Список выбора содержит столбцы только из таблицы Abonent. Это и есть
характерная особенность операции полу-соединения.
Она обычно применяется в распределённой обработке запросов, чтобы сократить
объём передаваемых данных.
*/

SELECT DISTINCT a.*
FROM abonent a
         JOIN request r USING (accountid)
WHERE r.failureid = 2;

/*
Деление. Позволяет в одной из двух таблиц, имеющих общие ключи,
найти значения, для которых имеются все соответствия в другой таблице.
*/


/*
Соединение таблицы со своей копией
В некоторых, довольно часто встречающихся на практике, случаях
необходимо выбрать данные из таблицы, основываясь на результатах
дополнительных выборок из этой же таблицы. Такие выборки называются
рекурсивными (Self JOIN). Для рекурсивных выборок многотабличные
запросы используют отношения, существующие внутри одной из таблиц
(самосоединение, рефлексивное соединение). Чтобы обратиться к
одной и той же таблице внутри одного запроса, используются разные
псевдонимы таблиц, определяемые непосредственно после имени таблицы
в секции FROM запроса SELECT. Например, чтобы найти все пары абонентов,
проживающих на одной и той же улице, можно использовать следующее
неявное рефлексивное соединение таблицы Abonent:
*/


SELECT a.fio, s.fio
FROM abonent a,
     abonent s
WHERE a.streetid = s.streetid
  AND a.fio < s.fio;


/*
В приведённом примере для таблицы Abonent определены два псевдонима:
A и S. Эти псевдонимы будут существовать, пока выполняется запрос.
Запрос ведёт себя так, как будто в операции соединения участвуют
две таблицы, называемые A и S.
Обе они в действительности являются
таблицей Abonent, но алиасы позволяют рассматривать её как две
независимые таблицы.
Получив две копии таблицы Abonent для работы,
SQL выполняет операцию соединения, как для двух разных таблиц:
выбирает очередную строку из одного алиаса и соединяет её с каждой
строкой другого алиаса.
Дополнительное условие поиска A.Fio < S.Fio
предназначено для удаления из НД повторяющихся строк, появляющихся
в результате того, что запрос выбирает все комбинации строк с
одинаковым кодом улицы. Такой же результат может быть
получен, если использовать следующий запрос на явное внутреннее
рефлексивное соединение:
*/

SELECT a.fio, s.fio
FROM abonent a
         JOIN abonent s USING (streetid)
WHERE a.fio < s.fio;

/*
Примером неявного соединения таблицы со своей копией и другой таблицей
может быть запрос, выводящий все пары абонентов, имеющих ремонтные
заявки с одной и той же неисправностью газового оборудования:
*/

SELECT DISTINCT failurenm, r.accountid, b.accountid
FROM request r,
     request b,
     disrepair d
WHERE r.failureid = b.failureid
  AND d.failureid = r.failureid
  AND r.accountid < b.accountid
ORDER BY failurenm, r.accountid, b.accountid;

/*
Следующий запрос является примером соединения по неравенству таблицы
со своей копией:

Запрос ранжирует значения столбца Paysum таблицы Paysumma.
Одинаковые значения Paysum имеют одинаковый ранг. Ранг, следующий
за одинаковыми Paysum, является следующим целым числом. Таблица
Paysumma соединяется сама с собой сравнением Paysum. Подсчитываются
все уникальные значения объединённых Paysum. Такой же результат даёт
использование оконной функции DENSE_RANK
*/

SELECT p1.paysum, COUNT(DISTINCT p2.paysum) AS paysum_rank
FROM paysumma p1
         JOIN paysumma p2 ON p1.paysum <= p2.paysum
GROUP BY p1.payfactid, p1.paysum
ORDER BY 1 DESC;

/*
Предположим, что в таблицу Abonent добавлен внешний рекурсивный ключ
Head_account. Это можно сделать с помощью запроса
*/

ALTER TABLE Abonent ADD Head_account VARCHAR(6) DEFAULT NULL
    REFERENCES Abonent(Accountid);

/*
В этом столбце для каждого абонента указан номер лицевого счёта
управляющего по дому, в котором проживает абонент. Если абонент сам
является управляющим, то в столбце Head_account указывается NULL.

С помощью внутреннего самосоединения можно создать запрос,
в результате выполнения которого выводится список абонентов
с указанием ФИО управляющих их домов
*/

SELECT a.fio "Абонент", b.fio "Управляющий"
FROM abonent a
         INNER JOIN abonent b ON a.head_account = b.accountid;

/*
Этот запрос включает таблицу Abonent и её копию: из таблицы
Abonent (под псевдонимом A) извлекаются ФИО абонентов,
а из её копии (под псевдонимом B) — ФИО управляющих домов.

Хотя в таблице Abonent 12 абонентов, но запрос возвращает только
два. Остальные абоненты сами являются управляющими домов,
в которых они проживают. Чтобы включить всех абонентов в резуль-
тирующий набор, необходимо использовать явное внешнее рефлек-
сивное соединение

Для формирования списка всех абонентов и управляющих их домов запрос
использует левостороннее внешнее соединение.
*/

SELECT a.fio "Абонент", b.fio, a.fio, COALESCE(b.fio, a.fio) "Управляющий"
FROM abonent a
         LEFT OUTER JOIN abonent b ON a.head_account = b.accountid
ORDER BY a.fio;

/*
В заключение изучения явного соединения таблиц следует привести
содержательную интерпретацию следующего запроса:
*/

SELECT p.paydate,
       p.paysum,
       COALESCE(SUM(p1.paysum), 0) AS "Нарастающий итог"
FROM paysumma p,
     paysumma p1
WHERE p1.paydate <= p.paydate
GROUP BY p.paydate, p.paysum
ORDER BY p.paydate;

SELECT p.paydate,
       SUM(DISTINCT p.paysum),
       COALESCE(SUM(p1.paysum) / (SELECT COUNT(p1.payfactid)
                                  FROM paysumma p1
                                  WHERE p1.paydate = p.paydate), 0) AS "Нарастающий итог"
FROM paysumma p,
     paysumma p1
WHERE p1.paydate <= p.paydate
GROUP BY p.paydate
ORDER BY p.paydate;


/*
Этот запрос решает задачу вычисления накопительных итогов — задачу,
очень часто возникающую на практике. В предположении некоторой
упорядоченности строк накопительный итог для каждой строки
представляет собой сумму значений некоторого числового столбца для
этой строки и всех строк, расположенных выше данной.
Другими словами, накопительный (нарастающий) итог для первой строки
в упорядоченном наборе будет равен значению в этой строке.
Для любой другой строки накопительный итог будет равен сумме значения
в этой строке и накопительного итога в предыдущей строке.
Таким образом можно проследить, как меняется промежуточная
сумма каждый раз при добавлении
нового значения. Условие (P1.Paydate <= P.Paydate)
учитывает необходимость отображения плат в случае, когда у нескольких
платежей совпадает дата.

Если в день было сделано более одного платежа, то можно считать,
что они поступали в порядке следования идентификаторов платежей,
и запрос будет таким:
*/


SELECT p.paydate, p.paysum, SUM(p1.paysum)
FROM paysumma p,
     paysumma p1
WHERE p1.paydate + MAKE_INTERVAL(0, 0, 0, 0, 0, 0, p1.payfactid)
          <= p.paydate + MAKE_INTERVAL(0, 0, 0, 0, 0, 1, p.payfactid)
GROUP BY p.payfactid
ORDER BY p.paydate, p.payfactid;

SELECT p.paydate, p.paysum, SUM(p1.paysum)
FROM paysumma p,
     paysumma p1
WHERE p1.paydate + MAKE_INTERVAL(secs => p1.payfactid)
   <= p.paydate + MAKE_INTERVAL(secs => p.payfactid)
GROUP BY p.payfactid
ORDER BY p.paydate, p.payfactid;

SELECT
    payfactid,
    paydate,
    paysum,
    SUM(paysum) OVER (ORDER BY paydate, payfactid) AS running_total
FROM paysumma
ORDER BY paydate, payfactid;



/*Для очень большого числа платежей таким:*/

SELECT p.payfactid, p.paydate, p.paysum, SUM(p1.paysum)
FROM paysumma p,
     paysumma p1
WHERE p1.paydate + MAKE_INTERVAL(secs => p1.payfactid::REAL / 1000000)
          <= p.paydate + MAKE_INTERVAL(secs => p.payfactid::REAL / 1000000)
GROUP BY p.payfactid
ORDER BY p.paydate, p.payfactid;


/*Логика условия фильтрации здесь следующая:

для каждого платежа P находятся все платежи P1, которые «меньше
или равны» по порядку;

MAKE_INTERVAL(SECS => P1.Payfactid::REAL/1000000) — преобразует
Payfactid в очень маленький интервал времени (дробные секунды);

P1.Paydate + MAKE_INTERVAL(...) — создаёт уникальную временную
метку для каждого платежа с учётом порядка Payfactid внутри
одного дня;

условие <= означает: «все платежи P1, которые произошли до или
одновременно с платежом P, учитывая порядок Payfactid»;

это позволяет корректно обрабатывать несколько платежей в один
день, считая, что они поступали в порядке возрастания Payfactid.

Например, если 2024-01-01 есть платежи с Payfactid = 100 и 200, то:

для платежа P (Payfactid = 100): включаются все платежи до
2024-01-01 00:00:00.100

для платежа P (Payfactid = 200): включаются все платежи до
2024-01-01 00:00:00.200

Таким образом, второй платеж получит нарастающий итог, включающий
оба платежа этого дня.

С выводом накопительных итогов в разрезе услуг запрос будет выглядеть
следующим образом:
*/

SELECT p.serviceid,
       p.paydate,
       p.paysum,
       COALESCE(SUM(p1.paysum), 0) AS "Нарастающий итог"
FROM paysumma p
         INNER JOIN paysumma p1 ON p1.serviceid = p.serviceid
WHERE p1.paydate <= p.paydate
  AND p1.serviceid = p.serviceid
GROUP BY p.serviceid, p.paydate, p.paysum
ORDER BY p.serviceid, p.paydate;


/*
Виды вложенных запросов.
Запросы с независимыми вложенными запросами

Часто невозможно решить поставленную задачу путём использования
одного запроса. Это особенно актуально, когда, в частности, при
использовании условия поиска в секции WHERE, значение, с которым
нужно сравнивать, заранее не определено и должно быть вычислено
в момент выполнения запроса!!!
В таком случае приходят на помощь законченные запросы SELECT,
внедрённые в тело другого запроса.

Вложенные запросы (внутренние, подзапросы) полезны по нескольким
причинам:
-упрощение: разбивая сложные запросы на более мелкие, более
управляемые части, подзапросы могут упростить понимание и
поддержку запроса;

-возможность повторного использования: подзапросы можно использовать
несколько раз в рамках одного запроса, уменьшая избыточность кода;

-модульность: подзапросы позволяют инкапсулировать определённую
логику или вычисления, упрощая обновление или изменение частей
запроса, не затрагивая остальную часть запроса.

Виды вложенных запросов
Вложенный запрос — это запрос-выборка, заключённый в круглые
скобки и вложенный в секцию
SELECT,
FROM,
WHERE,
HAVING, LIMIT
или WITH основного (внешнего) запроса SELECT или других
запросов, использующих эти секции.

Вложенный запрос представляет собой
запрос SELECT, а кодирование его секций подчиняется тем же правилам,
что и основного запроса SELECT.
Вложенный запрос в своих секциях может содержать другой вложенный
запрос и т.д.
Внешний запрос SELECT использует результаты выполнения внутреннего
запроса для определения содержания окончательного результата
всей операции.

Условно подзапросы, как и сами запросы выборки, по структуре
возвращаемого набора данных подразделяют на три вида, каждый из
которых является сужением предыдущего:

1.Табличный подзапрос — запрос SELECT, возвращающий значения
набора строк и столбцов, т.е. таблицу;

2.Подзапрос столбца — запрос SELECT, возвращающий значения
только одного столбца, но, возможно, в нескольких строках;

2.Скалярный подзапрос — запрос SELECT, возвращающий значение
одного столбца в одной строке.

При использовании вложенных запросов в секции SELECT синтаксис
возвращаемых элементов имеет вид:

<возвращаемый_элемент> ::=
{[<таблица>].*
| [<таблица>.]столбец
| константа | переменная | <выражение>
| (<скалярный_подзапрос>)}

Подзапрос — это также инструмент создания временной (производной)
таблицы, содержимое которой извлекается и обрабатывается внешним
запросом, обеспечивая гибкость и позволяя создавать сложные
структуры запросов для расширенного поиска данных.
Производные таблицы являются результатом запроса SELECT,
встроенного в секцию FROM другого запроса.

Производные таблицы полезны по нескольким причинам:

1.промежуточные результаты: производные таблицы можно использовать
для хранения промежуточных результатов, которые требуются для
дальнейшей обработки в основном запросе;

2.упрощение: подобно подзапросам, производные таблицы могут помочь
упростить сложные запросы, разбив их на более мелкие части;

3.повышение производительности: в некоторых случаях использование
производных таблиц может привести к повышению производительности
запросов, поскольку система управления базами данных может
оптимизировать выполнение запроса.
Синтаксис секции FROM имеет следующий вид:

from <произвольная таблица>

где

<производная_таблица> ::= (<табличный_подзапрос>) [[AS] псевдоним]

В PostgreSQL до версии 16 конструкция
[AS] псевдоним
является обязательной, т.е. производная таблица обязательно должна
иметь псевдоним.

При использовании вложенных запросов в секциях WHERE и HAVING
изменяется синтаксис некоторых условий поиска.
Простое сравнение при использовании вложенного запроса реализуется
конструкцией с количественными предикатами

<значение> <операция_сравнения> {<значение1>
| (<скалярный_подзапрос>)
| {ANY | SOME | ALL}
| (<подзапрос_столбца>)}

Также при использовании вложенных запросов есть возможность делать
проверку на существование с помощью предикатов IN, BETWEEN или
EXISTS. Эти предикаты передают значения для всех видов утверждений
в условиях поиска. Предикаты существования называются так потому,
что они различными способами проверяют существование или отсутствие
результатов подзапросов.

Проверка на членство во множестве реализуется конструкцией

<значение> [NOT] IN ({<значение1> [, <значение2>...]
| <подзапрос_столбца>})

В PostgreSQL проверка на членство во множестве может быть также
реализована в виде

(<столбец1>, <столбец2>, [<столбец3>,] [...])
= (<табличный_подзапрос>)

или

(<столбец1>, <столбец2>, [<столбец3>,] [...])
IN (<табличный_подзапрос>)

Условие поиска с проверкой существования представляется в виде

[NOT] EXISTS (<подзапрос>)

Использование секции ORDER BY в подзапросах обычно не требуется,
однако в PostgreSQL могут использоваться другие средства для
упорядочивания результатов подзапросов. Так, язык SQL допускает
вынесение определений подзапросов из тела основного запроса в
обобщённое табличное выражение WITH. Использование подзапросов
в выражении WITH имеет вид


WITH [RECURSIVE]
имя_производной_таблицы1 [(<список_столбцов>)]
AS (<табличный_подзапрос>)
[SEARCH {BREADTH | DEPTH} FIRST BY <имя_столбца> [,<имя_столбца>...]
SET <псевдоним_столбца>]
[, имя_производной_таблицы2 [(<список_столбцов>)]]
AS (<табличный_подзапрос>)
[SEARCH {BREADTH | DEPTH} FIRST BY <имя_столбца> [,<имя_столбца>...]
SET <псевдоним_столбца>]
...
<запрос_SQL>

Где секция SEARCH применяется для придания порядка строкам результата
в вынесенном запросе.
В качестве <запрос_SQL> может использоваться
одиночный запрос или объединение нескольких запросов SELECT,
а также INSERT, UPDATE, MERGE или DELETE.

Для реализации рекурсивных запросов должно использоваться ключевое
слово RECURSIVE.


По способу выполнения запросов с подзапросами различают:
1.автономные (независимые) вложенные запросы.
2.связанные (зависимые, соотнесённые, коррелированные,
синхронизированные) вложенные запросы.

В секциях:
- SELECT,
- WHERE и
- HAVING могут использоваться и автономные, и связанные вложенные
запросы.

В секцию WHERE (или HAVING) как автономные, так и связанные
вложенные запросы включаются с помощью предикатов:
IN,
ANY,
ALL,
EXISTS или одной из операций сравнения (=, <>, !=, <, >, <=, >=, !>).
Следует отметить, что выражения, содержащие подзапрос в секциях
WHERE или HAVING, используются наиболее часто.
Практическая необходимость использования независимых (автономных) подзапросов
в секции ORDER BY встречается крайне редко.
Основная причина в том, что такие подзапросы не привязаны к данным основного запроса,
и результат их выполнения одинаков для всех строк.
Это делает их малоэффективными с точки зрения сортировки,
так как они не добавляют значимой динамики в порядок сортировки строк!!!

1.Независимым вложенным запросом называется такой, результат
которого не зависит от внешнего (основного, родительского) запроса!!!
Данные из таблиц, указанных в секциях FROM внешнего запроса и
подзапроса, извлекаются независимо друг от друга, вследствие чего
необязательно вводить псевдонимы для этих таблиц или указывать
полные имена столбцов.
Запросы с независимыми подзапросами обрабатываются системой снизу-вверх.
Первым обрабатывается вложенный запрос самого нижнего уровня.
Множество значений, полученное в результате его выполнения,
используется при реализации запроса более высокого уровня и т.д.
Независимый подзапрос можно выполнить независимо от родительского запроса!!!

2.Связанным вложенным запросом называется такой, результат
которого зависит от результата внешнего запроса.
Подзапрос является связанным,
когда в нём (в секциях WHERE, HAVING) указан столбец
таблицы внешнего запроса.
Такое обращение к столбцам внешнего запроса называется внешней ссылкой!!!
Если точнее, внешняя ссылка — это имя столбца одной из таблиц,
указанных в секции FROM внешнего запроса, но не входящего ни в одну
из таблиц секции FROM подзапроса.
В связанных подзапросах следует указывать полные имена столбцов,
причём если во внешнем и вложенном запросах используется одна и та же
таблица, то для столбцов должны быть заданы псевдонимы.
Запросы со связанными вложенными запросами обрабатываются
в обратном порядке (сверху-вниз) !!!
То есть - сначала выбирается первая строка рабочей таблицы,
сформированная основным запросом!!!, а затем из неё выбираются значения
тех столбцов, которые используются в подзапросе (подзапросах).
Если эти значения удовлетворяют условиям вложенного запроса, то выбранная
строка включается в результат. После этого во внешнем запросе
выбирается вторая строка и т.д., пока в результат не будут включены
все строки, удовлетворяющие подзапросу (последовательности
подзапросов).


Правила использования подзапросов:
1.подзапрос должен быть заключён в круглые скобки;
2.подзапрос, как правило, должен указываться справа от оператора
сравнения;
3.подзапрос, как правило, не должен содержать секцию ORDER BY,
так как подзапрос выдаёт результат, который не виден. В запросе
SELECT может быть только одна секция ORDER BY, и она должна быть
последней в главном запросе SELECT;
4.если подзапрос возвращает во внешний запрос NULL или его результат
пустой, то внешний запрос не будет возвращать никакие строки!!!!;
5.в запросах с подзапросами используются операторы сравнения двух
типов — однострочные и многострочные.

Хотя подзапросы и производные таблицы служат схожим целям с точки
зрения упрощения сложных запросов, они используются в разных частях
запроса и обеспечивают разный уровень гибкости. Ниже рассматриваются
практические примеры использования подзапросов и производных таблиц
для более эффективного управления данными и их анализа.
*/

/*
Запросы с независимыми вложенными запросами
Независимые подзапросы в секции SELECT. В секции SELECT может
использоваться только <скалярный_подзапрос>, т.е. подзапрос,
который является выражением, возвращающим только одно значение!!!

При использовании независимого подзапроса возвращённый им результат
вставляется во все строки, формируемые внешним запросом.
Таким образом, подзапрос возвращает новый столбец внешнего запроса.

Примером простейшего запроса с автономным вложенным запросом может
быть следующий:
*/

SELECT 'sin(x)^2 + cos(x)^2 =' AS "Выражение",
       (SELECT POWER(SIN(PI() / 4), 2) + POWER(COS(PI() / 4), 2))
                               AS "Результат";

/*Использование подзапроса позволяет «выдернуть» отдельное значение
из некоторой другой таблицы или запроса, чтобы включить его в вывод
для своего запроса.

Например, необходимо по каждому абоненту вывести среднее значение
его платежей, а также среднее значение начислений по всем абонентам
Запрос может выглядеть так:*/


SELECT accountid,
       ROUND(AVG(paysum), 2)                                AS avg_pay,
       (SELECT ROUND(AVG(nachislsum), 2) FROM nachislsumma) AS avg_all_nachis
FROM paysumma
GROUP BY accountid;


/*
Следующий запрос выводит номер лицевого счёта каждого абонента
и логический признак, сообщающий, превышает ли среднее значение
его начислений среднее значение начислений по всем абонентам:

*/


SELECT
    AccountId,
    AVG(Nachislsum) > (SELECT AVG(Nachislsum) FROM Nachislsumma) AS Exceeds_average
FROM Nachislsumma
GROUP BY AccountId;

/*
Как следует из этих примеров, связь между значением, возвращаемым
независимым вложенным запросом (среднее значение начислений по всем
абонентам), и значениями внешнего запроса фактически отсутствует.

Можно допустить ошибку, если попытаться вывести 2 и более значений
в одном подзапросе, например максимальное и минимальное
значения плат:
*/

SELECT (SELECT MAX(paysum) AS "MAX(Paysum)",
               MIN(paysum) AS "MIN(Paysum)"
        FROM paysumma);

/*
В этом случае подзапрос нужно указать столько раз, сколько значений
он должен возвратить
*/

SELECT
    (SELECT MAX(Paysum)
     FROM Paysumma) AS "MAX(Paysum)",
    (SELECT MIN(Paysum)
     FROM Paysumma) AS "MIN(Paysum)";

/*ли вернуть значение составного типа */

SELECT (SELECT ROW (MAX(paysum), MIN(paysum))
        FROM paysumma);

/*
Рассмотрим более полезный пример использования независимых подзапросов
в секции SELECT. Пусть необходимо вывести год и число абонентов,
которым за него не производились начисления
Запрос будет таким:
*/


SELECT nachislyear AS "Год",
       (SELECT COUNT(accountid) FROM abonent) - COUNT(DISTINCT accountid)
                   AS "Число абонентов без начислений"
FROM nachislsumma
GROUP BY nachislyear;

/*
Независимые подзапросы в секции SELECT используются довольно редко.
Область применения связанных вложенных запросов
в секции  SELECT намного шире и будет рассмотрена далее.

Независимые подзапросы в секции FROM. В соответствии со стандартом
в секции FROM могут быть определены не только базовые, но и
производные таблицы, возвращаемые вложенным запросом
(<табличный_подзапрос>).
!!! Основное преимущество использования
подзапросов заключается в том, что можно превратить большую задачу
в более мелкие!!!

Производные таблицы могут быть вложены друг в друга
и могут быть включены в соединение (неявное или явное) как обычные
таблицы или представления.
Таким образом, результат подзапроса является источником данных
для внешнего запроса.

Следует учесть, что:
как для самой производной таблицы, так и для её столбцов могут
задаваться псевдонимы с помощью конструкции

[[AS] псевдоним_таблицы]
[(<столбец [[AS] псевдоним_столбца>][, ...])]

после завершения выполнения внешнего запроса производная таблица
исчезает.
Рассмотрим простейшее определение производной таблицы!!! с помощью
запросов:
*/

SELECT *
FROM (SELECT accountid, fio, phone
      FROM abonent) AS a(id, full_name, tel);

SELECT *
FROM (SELECT accountid id, fio full_name, phone tel
      FROM abonent) a;

SELECT *
FROM (SELECT accountid id, fio full_name, phone tel
      FROM abonent);

/*
где A — псевдоним производной таблицы;
Id, Full_name, Tel — список её столбцов.
В следующих запросах именами столбцов будут соответственно
Accountid, Full_name и Phone.
*/

SELECT *
FROM (SELECT Accountid AS Id, Fio, Phone
      FROM Abonent) AS A(Accountid, Full_name);

SELECT *
FROM (SELECT Accountid, Fio Full_name, Phone
      FROM Abonent);

/*
Данные примеры иллюстрируют особенности использования подзапроса
в секции FROM, но применять их нецелесообразно, так как выборку тех же
значений можно получить с помощью такого обычного запроса:
*/

SELECT accountid, fio, phone
FROM abonent;

/*
В описании секции WHERE отмечалось, что в условии поиска секции
WHERE нельзя использовать псевдонимы возвращаемых элементов,
например так:
*/

SELECT fio AS "Full_name"
FROM abonent
WHERE "Full_name" LIKE '%';

/*
Вместе с тем использование подзапроса, назначающего псевдонимы,
даёт возможность обращаться к возвращаемым столбцам по псевдонимам
во внешнем запросе. Например, выполнить запрос
получим результат, совпадающий с результатом, представленным на
, однако возвращаемый столбец имеет имя Full_name.
*/

SELECT *
FROM (SELECT fio AS "Full_name"
      FROM abonent)
WHERE "Full_name" LIKE '%';

/*
Вторым примером использования псевдонима, назначенного подзапросом,
может быть следующий запрос вычисления среднего количества заявок,
выполненных каждым исполнителем:
*/

SELECT AVG("Число заявок") AS "Среднее число заявок"
FROM (SELECT COUNT(requestid) AS "Число заявок"
      FROM request
      WHERE executiondate IS NOT NULL
      GROUP BY executorid);

/*
Особенность данного запроса заключается в расчёте среднего значения
агрегированных данных.
Сначала подзапросом готовятся агрегированные данные,
а затем внешним запросом вычисляется их среднее значение.
*/


SELECT "Max(Paysum)", "Min(Paysum)"
FROM (SELECT MIN(Paysum) AS "Min(Paysum)",
             MAX(Paysum) AS "Max(Paysum)"
      FROM Paysumma);

/*Рассмотрим варианты, когда использование подзапроса в секции FROM
может оказаться более полезным

В следующем примере вложенный запрос для каждого абонента группы
рассчитывает количество поданных заявок, а внешний запрос проверяет,
все ли эти абоненты подавали по две заявки:*/

SELECT EVERY(Count = 2) AS All_two
FROM (SELECT accountid, COUNT(Requestid) AS Count
      FROM Request
      WHERE Accountid IN ('136160','080270','136169','443069')
      GROUP BY Accountid);

/*
Порядок конкатенации строк функцией STRING_AGG без ORDER BY
определяется порядком их чтения из источников,
который в общем случае не определён. Чтобы
упорядочить список, можно предварительно упорядочить источник данных
с помощью производной таблицы:
*/

SELECT STRING_AGG(servicenm, ', ')
FROM (SELECT servicenm
      FROM services
      ORDER BY servicenm);

/*
В секции FROM могут быть определены две и более производные таблицы.
Например, требуется вывести среднее количество ремонтных заявок,
приходящихся на одного абонента.
Для этого нужно определить общее количество ремонтных заявок,
общее число абонентов и
поделить полученное количество заявок на число абонентов.
Запрос может выглядеть таким образом:
*/

SELECT (CAST(r.req_count AS NUMERIC(5, 2)) / a.ab_count)
           AS "Req_On_Ab"
FROM (SELECT COUNT(*) FROM abonent) AS a(ab_count),
     (SELECT COUNT(*) FROM request) AS r(req_count);

/*
В настоящем запросе используется функция CAST для преобразования
вычисленного целого значения (Req_count) в десятичный формат
NUMERIC(5,2). Если не сделать такое преобразование, то при делении
целого числа на целое (R.Req_count / A.Ab_count) произойдёт
округление результата до целого в меньшую сторону (будет выведен
результат Req_On_Ab = 1).

Следует учесть, что предыдущий запрос выдаст ошибку деления на ноль,
если таблица Abonent будет пустой. Чтобы исключить такую ошибку,
можно несколько изменить предыдущий запрос. Например:
*/

SELECT CASE
           WHEN ab_count > 0 THEN
               TO_CHAR(CAST(req_count AS NUMERIC(5, 2)) / ab_count, '99.99')
           ELSE 'Нет ни одного абонента'
           END AS "Req_On_Ab"
FROM (SELECT COUNT(*) AS ab_count FROM abonent),
     (SELECT COUNT(*) AS req_count FROM request);

/*
Рассмотрим более сложный пример вложенного запроса, когда производная
таблица в секции FROM получается путём соединения двух таблиц.
Пусть требуется вывести информацию о том, сколько абонентов подали
одинаковое количество ремонтных заявок, и число этих заявок

В этом запросе сначала формируется производная таблица, которая
содержит информацию о номере лицевого счёта каждого абонента
(AccountId) и количестве поданных им заявок на ремонт (Reg_count).

Затем внешний запрос группирует строки из этой таблицы по количеству
поданных заявок, подсчитывает количество строк в каждой группе
и выводит данные в один столбец.
*/

SELECT (COUNT(*) || ' абонентов подали по ' || reg_count || ' заявки') AS info
FROM (SELECT a.accountid, COUNT(r.requestid) AS reg_count
      FROM abonent a
               JOIN request r USING (accountid)
      GROUP BY a.accountid)
GROUP BY reg_count;

/*
Приведём пример запроса, в котором осуществляется явное соединение
базовой таблицы с производной таблицей, сформированной подзапросом:
Результатом этого запроса является список ФИО исполнителей
с количеством принятых к исполнению заявок, большим трёх.
*/

SELECT e.fio, total
FROM executor e
         INNER JOIN (SELECT COUNT(requestid) AS total, executorid
                     FROM request
                     GROUP BY executorid) stat USING (executorid)
WHERE total > 3;

/*
Следующий запрос демонстрирует соединение производной таблицы Ns
с виртуальной Gs:
*/

SELECT gs.cnt AS "Месяц", COUNT(incomingdate) AS "Число заявок"
FROM (SELECT incomingdate
      FROM request) ns
         RIGHT JOIN GENERATE_SERIES(1, 12) gs(cnt)
                    ON EXTRACT(MONTH FROM ns.incomingdate) = gs.cnt
GROUP BY gs.cnt
ORDER BY gs.cnt;

/*
Этот запрос полезен для получения полного представления о заявках
по месяцам, включая месяцы без заявок, которые отражены с нулевым
значением. Содержательная интерпретация данного запроса достаточно
проста.
Подзапрос Ns выбирает все строки из таблицы заявок и
подготавливает их для дальнейшего соединения с месяцами.

Соединение RIGHT JOIN гарантирует, что каждый месяц от 1 до 12 будет
представлен в результате.
Условие соединения ON EXTRACT(MONTH FROM Ns.Incomingdate) = Gs.Cnt сопоставляет месяцы
из таблицы Request с последовательностью Cnt.
Это соединение позволяет учитывать месяцы, в которых нет данных о заявках, отображая их с
нулевым количеством.
Агрегатная функция COUNT(Incomingdate)
подсчитывает количество заявок, зарегистрированных в каждом месяце.

Результаты упорядочены по возрастанию значения Cnt, что соответствует
упорядочиванию по месяцам с января по декабрь.

Для решения той же задачи помимо демонстрационного следует привести
более простой запрос:
*/

SELECT gs.cnt                AS "Месяц",
       COUNT(r.incomingdate) AS "Число заявок"
FROM GENERATE_SERIES(1, 12) AS gs(cnt)
         LEFT JOIN request r ON EXTRACT(MONTH FROM r.incomingdate) = gs.cnt
GROUP BY gs.cnt
ORDER BY gs.cnt;


/*
При использовании соединения часто требуется, чтобы результирующая
выборка содержала данные только по одной конкретной строке.

Пусть необходимо выбрать все данные по неисправности «Засорилась водогрейная
колонка» из таблиц Disrepair и Request.
Так как в таблице Disrepair находятся данные не только по заданной
неисправности, то используем подзапрос, при этом применяя
внутреннее соединение таблиц:
*/

SELECT D.*, R.*
FROM Request R
INNER JOIN
(SELECT FailureId
FROM Disrepair
WHERE Failurenm = 'Засорилась водогрейная колонка') D
USING(FailureId);

/*
В этом запросе в секции FROM производится соединение таблицы Request
основного запроса с производной таблицей, генерируемой подзапросом.

Например, для вывода всех данных по абонентам и их заявкам только
с неисправностью «Засорилась водогрейная колонка» можно использовать
такой запрос:
*/

SELECT a.*, r.*, d.*
FROM request r
         INNER JOIN
     (SELECT failureid
      FROM disrepair
      WHERE failurenm = 'Засорилась водогрейная колонка') d USING (failureid)
         INNER JOIN abonent a USING (accountid);

/*
Запрос с вложенным запросом в секции FROM используют для нахождения
значения агрегатной функции от агрегатной функции.
Пусть требуется найти минимальное значение среди средних
значений платежей, рассчитанных для каждой услуги.
Решить такую задачу позволит следующий запрос:
*/

SELECT MIN(avg_paysum)
FROM (SELECT AVG(paysum) AS avg_paysum
      FROM paysumma
      GROUP BY serviceid);

/*
Подзапросы могут быть вложенными друг в друга. Так, следующий запрос
рассчитывает среднее значение оплат, произведённых в каждом году,
и находит разницу между этим средним и общей суммой оплат в каждом
году
*/

SELECT EXTRACT(YEAR FROM paydate) AS "Год",
       allavg - SUM(paysum)       AS "Разность"
FROM (SELECT AVG(yearsum) AS allavg
      FROM (SELECT SUM(paysum) AS yearsum
            FROM paysumma
            GROUP BY EXTRACT(YEAR FROM paydate)) t1) t2,
     paysumma p
GROUP BY EXTRACT(YEAR FROM paydate), allavg
ORDER BY 1;

/*
В заключение приведём запрос визуализации количества ремонтных заявок
по каждой неисправности:

Здесь автономный вложенный запрос создаёт производную таблицу, где
для каждой неисправности подсчитывается количество заявок. Внешний
запрос соединяет таблицы Disrepair и результат подзапроса по столбцу
FailureId. Затем выводит название неисправности, количество заявок
и визуализацию в виде повторяющихся символов «#», равных количеству
заявок.

*/

SELECT d.failurenm,
       COALESCE(fail_count, 0)              AS "Число заявок",
       REPEAT('#', COALESCE(fail_count, 0)) AS "Визуализация"
FROM disrepair d
         LEFT JOIN
     (SELECT failureid, COUNT(*)::INTEGER AS fail_count
      FROM request
      GROUP BY failureid) r
     USING (failureid)
ORDER BY d.failurenm;

/*
Независимые подзапросы в секции WHERE.
Наиболее часто вложенные запросы используются в условиях поиска
секций WHERE и HAVING для усложнённой фильтрации данных!!!
В зависимости от того, в каком условии поиска используется подзапрос,
он может представлять собой:
<скалярный_подзапрос>,
<подзапрос_столбца>,
<табличный_подзапрос>.

При простом сравнении используется <скалярный_подзапрос> либо
<подзапрос_столбца>.
В последнем случае при проверке на равенство
используется предикат [NOT] IN, а при проверке на неравенство перед
ним указывается квантор ANY, ALL или SOME.

В WHERE и HAVING напрямую <табличный_подзапрос> не используется,
но может применяться в сочетании с кванторами ANY, ALL или SOME,
а также с предикатами IN или EXISTS!!!

Использование вложенных запросов с кванторами ANY, ALL, SOME и
предикатом EXISTS будет рассмотрено позднее, после изучения
независимых и связанных подзапросов.

Рассмотрим использование независимых подзапросов в условиях поиска
секции WHERE.

Предположим, что известно ФИО абонента Шмаков С.В., но не известно
значение его номера лицевого счёта. Необходимо извлечь из таблицы
Nachislsumma все данные о начислениях абоненту с ФИО Шмаков С.В.

Ниже приведён запрос с независимым подзапросом, извлекающий требуемый
результат из таблицы Nachislsumma:
*/

SELECT *
FROM nachislsumma
WHERE accountid = (SELECT accountid
                   FROM abonent
                   WHERE fio = 'Шмаков С. В.')
ORDER BY nachislfactid;

/*
В данном примере подзапрос в условии поиска представляет собой
<скалярный_подзапрос>. Он выполняется первым и возвращает
единственное значение столбца AccountId = '136160'. Оно помещается
в условие поиска основного (внешнего) запроса так, что условие поиска
будет выглядеть следующим образом: WHERE AccountId = '136160'.

В секции SELECT вложенный запрос должен выбрать одно и только одно
значение, а тип данных этого значения должен совпадать с типом того
значения, с которым он будет сравниваться в основном запросе.

Запрос предыдущего примера вернёт во всех столбцах пустой результат,
если в таблице Abonent не будет абонента с ФИО Шмаков С.В. Вложенные
запросы, которые не производят никакого вывода (нулевой вывод),
вынуждают рассматривать результат не как верный или неверный,
а как неизвестный.
Однако неизвестный результат имеет тот же самый
эффект, что и неверный: никакие строки не выбираются основным
запросом.

Тот же запрос не выполнится, если в таблице Abonent будет более одного
абонента с ФИО Шмаков С.В., так как вложенный запрос выберет более
одного значения.

Следующий запрос, который должен найти абонентов, имеющих погашенные
заявки на ремонт газового оборудования, не может быть выполнен
из-за ошибки «подзапрос в выражении вернул больше одной строки»:

Это происходит потому, что вложенный запрос возвращает более одного
значения. Если в БД будет одно значение или его вообще не будет,
то запрос выполнится, а если несколько, то возникнет ошибка.


*/

SELECT *
FROM Abonent
WHERE AccountId = (SELECT AccountId
                   FROM Request
                   WHERE Executed
                   GROUP BY AccountId);


/*
Для обработки множества значений, возвращаемых вложенным запросом,
следует использовать специальный предикат [NOT] IN. Тогда приведённый
выше запрос может быть правильно реализован так:
*/

SELECT * FROM Abonent
WHERE Accountid IN
      (SELECT Accountid
       FROM Request
       WHERE Executed
       GROUP BY Accountid);

SELECT * FROM Abonent
WHERE Accountid IN
      (SELECT Accountid
       FROM Request
       WHERE Executed = 'YES'
       GROUP BY Accountid);

/*
В этом примере подзапрос в условии поиска представляет собой
<подзапрос_столбца>, возвращающий различные значения столбца
Accountid ('005488', '080047', '080270', '080613' и т.д.), где Executed
принимает значение TRUE.
Затем выполняется внешний запрос, выводящий те строки из таблицы Abonent, для которых верно условие
поиска «AccountID IN ('005488', '080047', '080270', '080613' и т.д.)».

С помощью предыдущего запроса получены данные об абонентах,
которые имеют погашенные ремонтные заявки, но этот запрос не даёт
информации об абонентах, все заявки которых погашены. Чтобы получить
данные об абонентах, все заявки которых погашены, предыдущий запрос
можно модифицировать:

Абонентов с номерами лицевых счетов '115705' и '080270' нет в
результирующей таблице, так как у этих абонентов имеются непогашенные
заявки.
Данный пример демонстрирует принцип построения запросов
с отрицанием, заключающийся в том, что настоящее отрицание требует
двух проходов: чтобы найти «кто нет», сначала надо найти «кто да»,
и затем избавиться от них
*/

SELECT *
FROM abonent
WHERE accountid IN
      (SELECT accountid
       FROM request
       WHERE executed)
  AND accountid NOT IN
      (SELECT accountid
       FROM request
       WHERE NOT executed);

/*
Следует привести однотабличные запросы для нахождения соответственно
лицевых счетов абонентов, имеющих все и не все погашенные ремонтные
заявки соответственно:

EVERY — это агрегатная функция, которая проверяет, все ли значения
в группе удовлетворяют заданному условию.
EVERY отвечает на вопрос:
"Для всех ли записей в этой группе выполнено условие?"
*/

SELECT accountid
FROM request
GROUP BY accountid
HAVING EVERY(executed);

SELECT accountid
FROM request
GROUP BY accountid
HAVING NOT EVERY(executed);

/*
Следующий запрос демонстрирует принцип извлечения из одной таблицы
значений, которых нет в другой таблице (разность таблиц), с помощью
подзапроса:
*/

SELECT s.streetid
FROM street s
WHERE streetid NOT IN (SELECT streetid FROM abonent)
ORDER BY s.streetid;

/*
Необходимо отметить, что СУБД PostgreSQL для реализации разности
таблиц (в терминах СУБД PostgreSQL разницей двух запросов)
поддерживает специальный оператор EXCEPT.
*/


/*
Во вложенном запросе возможно использование той же таблицы, что и в
основном запросе.
Например, если требуется вывести все данные об абоненте с ФИО Аксенов С.А.
и обо всех других абонентах, которые проживают с ним на одной улице,
то запрос может иметь следующий вид:
*/

SELECT *
FROM abonent
WHERE streetid = (SELECT streetid
                  FROM abonent
                  WHERE fio = 'Аксенов С. А.');

/*
В данном примере подзапрос выполняется отдельно от внешнего запроса,
так как является независимым.
1.Сначала будет выполнен вложенный запрос,
который выберет значение Streetid из таблицы Abonent для абонента
с ФИО Аксенов С.А.
2.Затем основной запрос выберет из той же таблицы
Abonent строки со значением столбца Streetid, равным значению,
выбранному вложенным запросом.

При построении запросов, в том числе запросов с подзапросами,
следует помнить, что NULL никогда не бывает равным или не равным
ни одному значению, даже самому себе.
Например, следующий запрос вернёт информацию только
о выполненных заявках (строки, где Executiondate не определено,
не попадут в результат!!!):
*/

SELECT *
FROM request
WHERE executiondate IN (SELECT executiondate FROM request);

/*
Более того, при наличии неопределённых значений можно получить
совершенно непредсказуемые результаты.
Например, при попытке определить исполнителей ремонтных заявок,
не назначенных ни на одну заявку, путём нахождения разности
между таблицами Executor и Request запросом
*/

SELECT executorid
FROM executor
WHERE executorid NOT IN (SELECT executorid FROM request);

/*
будет получен пустой результат. Такой результат является следствием
того, что в таблице Request есть строка, содержащая NULL в столбце
Executorid. Для предотвращения подобных ошибок необходимо выполнить
дополнительную проверку:

Когда в подзапросе SELECT executorid FROM request есть хотя бы один NULL,
весь оператор NOT IN возвращает NULL (неизвестно), а не TRUE или FALSE.
А в WHERE условие, равное NULL, означает,
что строка НЕ включается в результат.

*/

SELECT executorid
FROM executor
WHERE executorid NOT IN (SELECT executorid
                         FROM request
                         WHERE executorid IS NOT NULL);


/*
Однако часто требуется проводить вычисления над данными столбца,
который может содержать неопределённые значения. Например, требуется
найти в таблице Abonent всех абонентов, первая цифра номера телефона
которых меньше первой цифры номера телефона абонента с ФИО
Стародубцев Е.В. В НД также должны быть включены и абоненты,
у которых не указан номер телефона. Для решения этой задачи
в следующем запросе с независимым подзапросом в секции WHERE
используется функция COALESCE для преобразования NULL в действительное
значение, которое может использоваться в обычных вычислениях и
сравнениях:
*/

SELECT fio, phone
FROM abonent
WHERE COALESCE(LEFT(phone, 1), '0') < (SELECT LEFT(phone, 1)
                                       FROM abonent
                                       WHERE fio = 'Стародубцев Е. В.');

SELECT fio, phone
FROM abonent
WHERE COALESCE(LEFT(phone, 1), '0') = (SELECT LEFT(phone, 1)
                                       FROM abonent
                                       WHERE fio = 'Стародубцев Е. В.');

SELECT fio, phone
FROM abonent
WHERE COALESCE(LEFT(phone, 1), '0') > (SELECT LEFT(phone, 1)
                                       FROM abonent
                                       WHERE fio = 'Стародубцев Е. В.');


SELECT Fio, Phone
FROM Abonent
WHERE COALESCE(TO_NUMBER(SUBSTRING(Phone, 1, 1), '0'), '0')
          ---SUBSTRING(строка, от_какой_позиции, сколько_символов)
          ---TO_NUMBER(что_превращаем, 'формат')
          < (SELECT TO_NUMBER(SUBSTRING(Phone, 1, 1), '0')
             FROM Abonent
             WHERE Fio = 'Стародубцев Е. В.');


/*
Таким образом, если используется предикат IN, то вложенный запрос
выполняется только раз и формирует одно или множество значений,
используемых основным запросом. В любой ситуации, где применяется
реляционная операция сравнения «равно» («не равно»), разрешается
использовать IN (NOT IN). В отличие от запроса со знаком «равно»
(«не равно») запрос с предикатом IN (NOT IN) не потерпит неудачу,
если больше, чем одно значение выбрано вложенным запросом.
Задачи использования других операций многострочного
сравнения рассматриваются ниже.

Возможно применение агрегатных функций в качестве фильтров строк.
В этом случае вложенный запрос возвращает результат выполнения
агрегатной функции или значение выражения, основанного на столбце.

Допустим, необходимо вывести номера лицевых счетов абонентов и
значения их начислений за 2025 г., превышающие среднее значение
начислений по всем абонентам за этот год.
Запрос будет иметь следующий вид:
*/


SELECT accountid,
       nachislsum,
       nachislmonth,
       nachislyear,
       (SELECT ROUND(AVG(nachislsum), 2)
        FROM nachislsumma
        GROUP BY nachislyear
        HAVING nachislyear = 2025) AS avg_
FROM nachislsumma
WHERE nachislsum > (SELECT ROUND(AVG(nachislsum), 2)
                    FROM nachislsumma
                    GROUP BY nachislyear
                    HAVING nachislyear = 2025)
  AND nachislyear = 2025
ORDER BY accountid;

/*
В этом примере запросы, вложенные в разные секции, выполняются
только раз, возвращая среднее значение столбца Nachislsum за 2025 г.
Затем это значение последовательно сравнивается с каждой строкой,
выбираемой из таблицы Nachislsumma.

Рассмотрим ещё несколько примеров использования агрегатных функций
в подзапросе секции WHERE.

Для вывода информации о погашенных ремонтных заявках с наиболее
поздней датой поступления можно использовать
такой запрос:
*/

SELECT requestid, incomingdate, executiondate, executed
FROM request
WHERE incomingdate = (SELECT MAX(incomingdate)
                      FROM request
                      WHERE executed);

SELECT requestid, incomingdate, executiondate, executed
FROM request
WHERE incomingdate = (SELECT MAX(incomingdate)
                      FROM request
                      WHERE executed = '1');


/*
Для вывода ФИО абонентов с информацией об оплате с наибольшим
значением можно использовать следующий запрос
*/

SELECT fio, paysumma.payfactid, paysumma.paysum
FROM paysumma
         JOIN abonent USING (accountid)
WHERE paysum = (SELECT MAX(paysum)
                FROM paysumma);

/*
В секции WHERE, как и в секции FROM, подзапросы могут быть вложенными
друг в друга.
Следующий запрос подсчитывает общую сумму значений
оплат и выводит название услуги с максимальной суммой

*/


SELECT t.servicenm, t.totalsum
FROM (SELECT s.servicenm, SUM(p.paysum) AS totalsum
      FROM paysumma p
               INNER JOIN services s USING (serviceid)
      GROUP BY s.serviceid, s.servicenm) t
WHERE t.totalsum = (SELECT MAX(totalsum)
                  FROM (SELECT SUM(paysum) AS totalsum
                        FROM paysumma
                        GROUP BY serviceid) t2);



SELECT tnsfio, tnscount
FROM (SELECT fio AS tnsfio, COUNT(paysum) AS tnscount
      FROM paysumma
               INNER JOIN abonent USING (accountid)
      GROUP BY fio) t
WHERE tnscount = (SELECT MIN(tscount)
                  FROM (SELECT COUNT(paysum) AS tscount
                        FROM paysumma
                        GROUP BY accountid) t2);


/*Однако существует ещё более элегантное решение подобных задач вообще
без применения подзапросов
*/

-- группируем по ФИО и считаем количество
-- платежей для каждого абонента.
SELECT fio           AS tnsfio,
       COUNT(paysum) AS tnscount,
       COUNT(1)
FROM paysumma
         INNER JOIN abonent USING (accountid)
GROUP BY fio
ORDER BY COUNT(1) ASC
--COUNT(1) — это функция подсчёта строк,
-- где 1 — это просто константа,
--не имеющая никакого отношения к столбцам таблицы.
--отсортировать по значению, которое возвращает COUNT(1).
--Сортируем по количеству платежей по возрастанию (от меньшего
--к большему).
--А COUNT(1) внутри GROUP BY fio считает количество строк в группе
--(т.е. количество платежей для каждого абонента).
--Поскольку 1 — это константа, которая никогда не бывает NULL,
-- COUNT(1) считает все строки так же, как и COUNT(*).
    FETCH FIRST rows
--взять первую строку
WITH TIES;
-- взять также все остальные строки, у которых значение сортировки
-- (tnscount) такое же, как у последней взятой строки



/*
Независимые многостолбцовые подзапросы. СУБД PostgreSQL предоставляет
дополнительные возможности по реализации условий поиска с подзапросами.

До сих пор рассматривались такие запросы, где в секциях WHERE или
HAVING сравнивалось значение только одного столбца с результатом,
возвращаемым однострочным или многострочным подзапросом.

Если требуется сравнение значений двух или более столбцов, необходимо
сложное условие с логическими операторами.
Многостолбцовые подзапросы позволяют объединять дублируемые условия
секции WHERE или HAVING в единое условие поиска.
Синтаксис запроса с многостолбцовым подзапросом в секции WHERE имеет вид

SELECT <столбец1>, <столбец2>, [<столбец3>, ...]
FROM <таблица> [<табличный_подзапрос>]
WHERE (<столбец1>, <столбец2>, [<столбец3>, ...]) IN
(SELECT <столбец1>, <столбец2>, [<столбец4>, ...]
FROM <таблица> [<табличный_подзапрос>])
WHERE <условие_поиска>


Первым примером проверки на членство нескольких значений во множестве
может быть следующий запрос:
*/


SELECT accountid, serviceid, paysum, paydate
FROM paysumma
WHERE (serviceid, paydate) IN (SELECT serviceid, MAX(paydate)
                               FROM paysumma
                               GROUP BY serviceid)
ORDER BY serviceid DESC;


/*

Для получения всей информации об абонентах, проживающих в одном доме
с абонентом с ФИО Конюхов В.С. (номер лицевого счёта '015527'), можно
применить следующий запрос с двустолбцовым подзапросом:
*/

SELECT *
FROM abonent
WHERE (streetid, houseno) = (SELECT streetid, houseno
                             FROM abonent
                             WHERE accountid = '015527')
  AND accountid != '015527';

/*
Для вывода информации о начислениях абонентов за те же месяцы и годы,
что и начисления для абонента с лицевым счётом '015527', можно
использовать такой многостолбцовый запрос:
*/

SELECT accountid,
       serviceid,
       nachislsum,
       nachislmonth,
       nachislyear
FROM nachislsumma
WHERE (nachislmonth, nachislyear) IN
      (SELECT DISTINCT nachislmonth, nachislyear
       FROM nachislsumma
       WHERE accountid = '015527')
  AND accountid != '015527'
ORDER BY accountid;


/*
Использование подзапросов в секции GROUP BY необычно, но возможно.
Это может быть полезно в определённых ситуациях, когда требуется
динамическое вычисление значений для группировки!!!
Например, вывести количество начислений по сравнению
со средним значением можно таким запросом:

Подзапросы в секции GROUP BY для создания динамических группировок
на основе вычисляемых значений следует использовать с осторожностью,
так как они могут быть менее эффективными из-за необходимости их
выполнения для каждой строки!!!
*/


SELECT CASE
           WHEN nachislsum > (SELECT AVG(nachislsum) FROM nachislsumma)
               THEN 'Выше среднего'
           ELSE 'Ниже или равно среднему'
           END  AS "Группа начислений",
       COUNT(*) AS "Количество",
       (SELECT AVG(nachislsum) FROM nachislsumma)

FROM nachislsumma
GROUP BY nachislsum > (SELECT AVG(nachislsum) FROM nachislsumma);
/*
Группировка по вычисляемому выражению
GROUP BY nachislsum > (SELECT AVG(nachislsum) FROM nachislsumma)

Проблема в том, что PostgreSQL не может использовать индекс для такой
группировки. Выражение nachislsum > константа — это условие,
а не значение столбца.

1. Seq Scan по всей таблице nachislsumma (читаем все строки)
2. Для каждой строки вычисляем TRUE/FALSE
3. Сортируем или хешируем по этому вычисленному значению
4. Считаем агрегаты

Двойное вычисление AVG
В запросе:
SELECT → AVG(nachislsum) вычисляется ещё раз для каждой группы
Агрегаты считаются после группировки
Но это нормально — агрегаты так и работают.
*/


/*
Независимые подзапросы в секции HAVING.
Такие запросы могут использовать свои собственные агрегатные функции
(если эти функции не возвращают многочисленных значений)!!!
Также в подзапросе, включённом в условие поиска секции HAVING
внешнего запроса, могут использоваться свои собственные секции:
- GROUP BY
- HAVING.
Следует помнить, что аргументы, указанные в секции HAVING, должны
присутствовать в качестве аргументов и в секции GROUP BY. Например,
для подсчёта числа абонентов с максимальным значением платежа
за 2024 г. можно использовать запрос
*/

SELECT COUNT(DISTINCT accountid), paysum
FROM paysumma
GROUP BY paysum
HAVING paysum = (SELECT MAX(paysum)
                 FROM paysumma
                 WHERE payyear = 2024);


/*
Следующим примером может быть поиск услуги, за которую произведено
наибольшее количество платежей:

Здесь в начале выполняется самый «нижний» подзапрос, который выдает
по каждой услуге количество платежей, и результат помещает в
производную таблицу. «Верхний» подзапрос находит в этой таблице
максимальное количество платежей, которое передаётся во внешний
запрос. Внешний запрос выводит наименование услуги и соответствующее
количество произведённых платежей.
*/

SELECT servicenm, COUNT(*)
FROM paysumma
         JOIN services USING (serviceid)
GROUP BY servicenm
HAVING COUNT(*) = (SELECT MAX(a)
                   FROM (SELECT serviceid, COUNT(*) AS a
                         FROM paysumma
                         GROUP BY serviceid) t);


/*
Вывести наименования услуг, за которые сумма значений начислений
всем абонентам превышает более чем на величину, задаваемую
параметром Pr, начисление тому абоненту, который имеет максимальное
значение начисления, может следующий запрос:
*/


SELECT servicenm
FROM services
         INNER JOIN nachislsumma USING (serviceid)
GROUP BY servicenm
HAVING SUM(nachislsum) > (SELECT :Pr + MAX(nachislsum)
                          FROM services
                                   INNER JOIN nachislsumma USING (serviceid));



/*
Следующий запрос с автономным подзапросом выбирает номера лицевых
счетов всех абонентов, для которых число платежей со значением
меньше средней суммы значений платежей по всем абонентам превышает 5.
*/

SELECT accountid
FROM paysumma
GROUP BY accountid
HAVING COUNT(*) FILTER (WHERE paysum < (SELECT AVG(paysum)
                                        FROM paysumma)) > 5;


/*
Независимые подзапросы при ограничении строк. Можно привести
следующие примеры учебного запроса с использованием автономных
подзапросов при ограничении количества выводимых строк

Вывод всей информации по абонентам производится, начиная со строки,
номер которой равен числу строк в таблице Services, а количество
выводимых строк равно числу строк в таблице Request. Так как число
строк в таблице Request превышает число строк в таблице Abonent,
то выводятся все оставшиеся строки.
*/

SELECT *
FROM abonent
ORDER BY accountid
OFFSET (SELECT COUNT(*) FROM services)
    ROWS FETCH NEXT
    (SELECT COUNT(*)
     FROM request) ROWS ONLY;

SELECT *
FROM Abonent
ORDER BY AccountId
OFFSET (SELECT COUNT(*) FROM Services)
    ROWS LIMIT (SELECT COUNT(*)
                FROM Request);

/*
Используя такой же подход, можно выбирать из определённой таблицы
заданный процент строк случайным образом

Вывод всей информации по абонентам производится, начиная со строки,
номер которой равен числу строк в таблице Services, а количество
выводимых строк равно числу строк в таблице Request. Так как число
строк в таблице Request превышает число строк в таблице Abonent,
то выводятся все оставшиеся строки.

Используя такой же подход, можно выбирать из определённой таблицы
заданный процент строк случайным образом
*/

/*

Этот запрос выбирает случайные 75% строк из таблицы Paysumma.
*/
SELECT *
FROM Paysumma
ORDER BY RANDOM()
    FETCH NEXT (SELECT COUNT(*) * 75.0 / 100 FROM Paysumma) ROWS ONLY;

/*
или первую половину строк:
*/

SELECT *
FROM Paysumma
ORDER BY Accountid
OFFSET 0 ROWS FETCH NEXT (SELECT COUNT(*) / 2 FROM Paysumma) ROWS ONLY;

/*
Обобщённые табличные выражения.
Обобщённые табличные выражения — это мощная функция в SQL,
которая позволяет создавать временный результирующий набор,
на который затем можно ссылаться в запросах:
SELECT,
INSERT,
UPDATE,
DELETE.
Они особенно полезны для разбиения
сложных запросов на более простые, удобочитаемые части.

Производные таблицы, возвращаемые табличным подзапросом,
определяются в секции WITH, которая записывается перед основным запросом
SELECT.
Такая техника вынесения определений подзапросов из тела основного запроса
получила название Subquery Factoring («факторизация», «разложение
на подзапросы»).

Производные таблицы получили название обобщённые
табличные выражения (Common Table Expression, CTE) и являются
наиболее сложной и мощной вариацией производных таблиц!!!

Суть этих
выражений заключается в том, что с помощью секции WITH можно задать
шаблон, состоящий из подзапросов, к которым можно обратиться с
помощью основного запроса.
Обобщённое табличное выражение играет роль представления,
созданного в рамках одного запроса, и не сохраняется как объект
БД.

Секция WITH может использоваться в нескольких целях:

-устранение дублирования кода. Единожды определённый таким образом
подзапрос может использоваться неоднократно в разных частях запроса;

-придание запросу более понятной формулировки: описание подзапросов,
которые многократно используются в основном запросе, с тем чтобы
к ним (подзапросам) можно было обращаться в запросе по имени;

-запись рекурсивных запросов (recursive subquery factoring).

Таким образом, подзапросы в секции WITH могут быть рекурсивными
и не рекурсивными.
Простое и рекурсивное разложение на подзапросы с помощью секции
WITH не противоречат друг другу и могут использоваться совместно.
Синтаксис нерекурсивных запросов выглядит так:

WITH
имя_производной_таблицы [(<список_столбцов>)]
AS (<табличный_подзапрос>) [, ...]
<запрос_SQL>

Итак, чтобы построить CTE, необходимо применить ключевое слово WITH
в начале основного запроса (запрос_SQL), за которым следует название
CTE (имя_производной_таблицы) с необязательным списком названий
столбцов, а затем (после AS) в круглых скобках запрос, который он
обозначает.

Примером простого нерекурсивного CTE с одним подзапросом может быть
следующий:
*/


-- Создаётся табличное выражение с именем "Абонент"
WITH "Абонент" (Accountid, Fio) -- имя таблицы и столбцов подзапроса
         AS (
-- Далее указывается подзапрос
        SELECT Accountid, Fio
        FROM Abonent)
-- Вывод результата выполнения основного запроса
SELECT *
FROM "Абонент"
ORDER BY Fio;
-- обращение к таблице подзапроса


---или такой без перечисления имён столбцов, так как они уникальные:

WITH "Абонент" -- имя таблицы подзапроса
         AS (SELECT Accountid, Fio
             FROM Abonent)
SELECT *
FROM "Абонент"
ORDER BY Fio;
-- основной запрос

/*
Основное предназначение CTE заключается в разбиении сложных запросов
на простые части.
Чтобы проиллюстрировать возможности, предоставляемые оператором WITH,
рассмотрим следующую типовую задачу.

Требуется вывести данные об абонентах, у которых среднее значение
платежей превышает среднее значение платежей всех абонентов.
Рассмотрим сначала запросы, которые понадобятся при
решении этой задачи.

Вывести среднее значение платежей каждого абонента:
*/

SELECT AccountId, ROUND(AVG(Paysum), 2) AS Avg_Ab
FROM Paysumma
GROUP BY AccountId;

--Определить среднее значение платежей всех абонентов:

SELECT ROUND(AVG(Paysum), 2) AS Avg_Total
FROM Paysumma;

/*Используя эти запросы, построим обычный запрос, который решает
поставленную задачу.

Вывести данные об абонентах, у которых среднее значение платежа
превышает среднее значение платежей всех абонентов (используются
автономный и коррелированный подзапросы):
*/


SELECT Accountid, Fio
FROM Abonent A
WHERE (SELECT ROUND(AVG(Paysum), 2) AS Avg_ab
       FROM Paysumma
       GROUP BY Accountid
       HAVING Accountid = A.Accountid)
          > (SELECT ROUND(AVG(Paysum), 2) AS Avg_total
             FROM Paysumma);

/*

Используя оператор with, решение рассматриваемой задачи
можно представить в следующем виде.
Вывести данные об абонентах у которых среднее значение
платежей превышает среднее значение платежей всех абонентов

*/


WITH
    avg_ab AS (
        SELECT Accountid, ROUND(AVG(Paysum), 2) AS avg_ab
        FROM Paysumma
        GROUP BY Accountid
    ),
    avg_total AS (
        SELECT ROUND(AVG(Paysum), 2) AS avg_total
        FROM Paysumma
    )

SELECT A.Accountid, A.Fio, avg_ab.avg_ab
FROM Abonent A
         inner join avg_ab  on avg_ab.Accountid = A.Accountid
WHERE (SELECT avg_ab
       FROM avg_ab
       WHERE Accountid = A.Accountid)
          > (SELECT avg_total FROM avg_total);

/*
В секции WITH может быть определено несколько подзапросов.
В PostgreSQL секции WITH могут быть вложенными, т.е. запрос
в секции WITH может иметь свою секцию WITH.
WITH
    -- Внешняя CTE
    outer_cte AS (
        WITH
            -- Внутренняя CTE (видна только внутри outer_cte)
            inner_cte AS (
                SELECT Accountid, SUM(Paysum) AS total
                FROM Paysumma
                GROUP BY Accountid
            )
        SELECT Accountid, total
        FROM inner_cte
        WHERE total > 1000
    )
-- Основной запрос (видит только outer_cte, но не inner_cte)
SELECT * FROM outer_cte;

Имена нескольких обобщённых табличных выражений должны быть
различными.
Результат CTE после выполнения запроса не сохраняется.
Запросы в CTE могут обращаться как к таблицам, так и друг к другу.

Примером CTE с двумя подзапросами, второй из которых использует
результат первого, может быть такой запрос:
*/

WITH Sum_pay AS (SELECT Servicenm AS "Услуга", SUM(Paysum) AS "Сумма"
                 FROM Paysumma
                          NATURAL JOIN Services
                 GROUP BY Servicenm),
     Avg_pay AS (SELECT SUM("Сумма") / COUNT(*) AS "Среднее"
                 FROM Sum_pay)
SELECT *
FROM Sum_pay
WHERE "Сумма" > (SELECT "Среднее" FROM Avg_pay)
ORDER BY "Услуга";

/*
Рассмотрим ещё учебные примеры простого разложения на подзапросы
в WITH.
Вывести год поступления и
название дня недели первой ремонтной заявки и
того же дня месяца в каждом году следующих
трёх лет:

*/

WITH Initial_date
/* блок создаёт временную таблицу Initial_date с одной строкой,
содержащей MIN(Incomingdate)*/
         AS (SELECT MIN(Incomingdate) AS Dat
             FROM Request),
     Generated_dates
/* блок использует функцию GENERATE_SERIES для создания списка дат,
начиная с Initial_date и до трёх лет вперед, с шагом в один год.
Каждая дата преобразуется в тип DATE */
         AS (SELECT GENERATE_SERIES(
                            (SELECT Dat FROM Initial_date),
                            (SELECT Dat + INTERVAL '3 YEARS' FROM Initial_date),
                            '1 YEAR'
                    )::DATE AS Generated_date)
SELECT
/* запрос вернёт таблицу, где каждая строка будет содержать год
и день недели для заданной даты (MIN(Incomingdate)
соответствующего и следующих трёх лет) */
    EXTRACT(YEAR FROM Generated_date) AS "Год",
    TO_CHAR(Generated_date, 'Day')    AS "День недели"
FROM Generated_dates;



WITH Initial_date
/* блок создаёт временную таблицу Initial_date с одной строкой,
содержащей MIN(Incomingdate)*/
         AS (SELECT MIN(Incomingdate) AS Dat
             FROM Request),
Generated_dates
AS (SELECT GENERATE_SERIES(
                   (SELECT Dat FROM Initial_date),
                   (SELECT Dat + INTERVAL '3 YEARS' FROM Initial_date),
                   '1 YEAR'
           )::DATE AS Generated_date)

select *
    from Generated_dates;


/*
Пусть требуется вычислить метрики платёжной активности абонентов:
среднее число платежей в:
год YAA (Annually Active Abonents),
в месяц MAA (Monthly Active Abonents),
в неделю WAA (Weekly Active Abonents)
и в день DAA (Daily Active Abonents).
Эти метрики показывают число уникальных абонентов, которые в течение
конкретного временного промежутка хотя бы раз оплачивали коммунальные
ресурсы или жилищные услуги.
Для этого достаточно определить число платежей, произведённых
в каждом году, месяце, неделе и дне, а затем найти их среднее.
В частности, метрика DAA может быть полезной при планировании
пропускной способности, например с оценкой ожидаемой нагрузки на
серверы.

Каждую подзадачу можно решить с использованием подзапроса
в секции WITH:

*/


WITH Pdates AS (SELECT GENERATE_SERIES(MIN(P.Paydate), MAX(P.Paydate), '1 DAY')::DATE AS Dates
                FROM Paysumma P),
     Daa AS (SELECT TO_CHAR(D.Dates, 'YYYY-MM-DD'), COUNT(DISTINCT Accountid) AS Acc
             FROM Paysumma P
                      RIGHT JOIN Pdates D ON D.Dates = P.Paydate
             GROUP BY 1),
     Waa AS (SELECT TO_CHAR(D.Dates, 'YYYY-WW'), COUNT(DISTINCT Accountid) AS Acc
             FROM Paysumma P
                      RIGHT JOIN Pdates D ON D.Dates = P.Paydate
             GROUP BY 1),
     Maa AS (SELECT TO_CHAR(D.Dates, 'YYYY-MM') AS Mon, COUNT(DISTINCT Accountid) AS Acc
             FROM Paysumma P
                      RIGHT JOIN Pdates D ON D.Dates = P.Paydate
             GROUP BY Mon),
     Yaa AS (SELECT TO_CHAR(D.Dates, 'YYYY'), COUNT(DISTINCT Accountid) AS Acc
             FROM Paysumma P
                      RIGHT JOIN Pdates D ON D.Dates = P.Paydate
             GROUP BY 1)

SELECT ROUND((SELECT AVG(Acc) FROM Daa), 2) AS Daa,
       ROUND((SELECT AVG(Acc) FROM Waa), 2) AS Waa,
       ROUND((SELECT AVG(Acc) FROM Maa), 2) AS Maa,
       ROUND((SELECT AVG(Acc) FROM Yaa), 2) AS Yaa;


WITH Pdates AS (SELECT GENERATE_SERIES(MIN(P.Paydate), MAX(P.Paydate), '1 DAY')::DATE AS Dates
                FROM Paysumma P),
     Daa AS (SELECT TO_CHAR(D.Dates, 'YYYY-MM-DD'), COUNT(DISTINCT Accountid) AS Acc
             FROM Paysumma P
                      RIGHT JOIN Pdates D ON D.Dates = P.Paydate
             GROUP BY 1)

select sum(acc)/1413, avg(acc)
from Daa;

/*
Здесь первый подзапрос вызовом функции GENERATE_SERIES
формирует последовательность дат с шагом в один день в периоде от
первого до последнего платежа.
В каждом последующем подзапросе производится соединение
этой последовательности с таблицей платежей и вычисляется их количество
в соответствующем периоде.
Внешний запрос вычисляет среднее количество платежей в день,
неделю, месяц и год
*/


/*
Рассмотрим примеры использования CTE в секции WHERE. Допустим, нужно
вывести всю информацию об абонентах, которые подавали заявки на ремонт
до 2024 года. Обычный запрос:
*/
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM Abonent
WHERE AccountID IN (SELECT AccountID
                    FROM Request
                    WHERE Incomingdate < '01.01.2024');


---Запрос с CTE:
EXPLAIN (ANALYZE, BUFFERS)
WITH Cte_n  AS (
    SELECT *
    FROM Request
    WHERE Incomingdate < '01.01.2024'
)
SELECT *
FROM Abonent
WHERE AccountID IN (SELECT AccountID FROM Cte_n);


/*
Получить результат и избежать повторения
подзапроса в секциях SELECT и WHERE можно, определив его только раз
в секции WITH, а затем используя в самом запросе:
*/

WITH Fact_avg AS (SELECT ROUND(AVG(Nachislsum), 2) AS Avg_nach
                  FROM Nachislsumma
                  GROUP BY Nachislyear
                  HAVING Nachislyear = 2025)
SELECT Ns.Accountid,
       Ns.Nachislsum,
       Ns.Nachislmonth,
       Ns.Nachislyear,
       (SELECT Avg_nach FROM Fact_avg) AS Avg_all
FROM Nachislsumma Ns
WHERE Ns.Nachislsum > (SELECT Avg_nach FROM Fact_avg)
  AND Ns.Nachislyear = 2025
ORDER BY 1;


/*
Допустим, необходимо вывести по каждому абоненту:
-номер его лицевого счёта,
-ФИО
-общие суммы значений плат за 2024 г. и 2025 г.
-результат выполнения запроса с простым разложением на подзапросы


Этот SQL-запрос использует CTE, чтобы сначала создать временную
таблицу Year_abon_pay, содержащую суммы значений оплат (Total_sum)
для каждого года (Payyear) и для каждого абонента (Accountid).
Эти суммы вычисляются из таблицы Paysumma с использованием агрегатной
функции SUM и группировки по году и абоненту. Затем основной запрос
выбирает из таблицы Abonent данные о каждом абоненте, и для каждого
абонента присоединяет суммы значений оплат из временной таблицы
Year_abon_pay для года 2024 (Year_2024.Total_sum) и 2025
(Year_2025.Total_sum). Если для определённого года или абонента нет
оплат, возвращается NULL.
*/

WITH Year_abon_pay AS (SELECT Payyear, Accountid, SUM(Paysum) AS Total_sum
                       FROM Paysumma
                       GROUP BY Payyear, Accountid)
SELECT A.Accountid,
       A.Fio,
       Year_2024.Total_sum AS Total_2024,
       Year_2025.Total_sum AS Total_2025
FROM Abonent A
         LEFT JOIN Year_abon_pay AS Year_2024
                   ON A.Accountid = Year_2024.Accountid
                       AND Year_2024.Payyear = 2024
         LEFT JOIN Year_abon_pay AS Year_2025
                   ON A.Accountid = Year_2025.Accountid
                       AND Year_2025.Payyear = 2025
ORDER BY Accountid;


SELECT
    A.Accountid,
    A.Fio,
    SUM(CASE WHEN P.Payyear = 2024 THEN P.Paysum ELSE 0 END) AS Total_2024,
    SUM(CASE WHEN P.Payyear = 2025 THEN P.Paysum ELSE 0 END) AS Total_2025
FROM Abonent A
         LEFT JOIN Paysumma P ON A.Accountid = P.Accountid
GROUP BY A.Accountid, A.Fio
ORDER BY A.Accountid;


SELECT
    A.Accountid,
    A.Fio,
    SUM(P.Paysum) FILTER (WHERE P.Payyear = 2024) AS Total_2024,
    SUM(P.Paysum) FILTER (WHERE P.Payyear = 2025) AS Total_2025
FROM Abonent A
         LEFT JOIN Paysumma P ON A.Accountid = P.Accountid
GROUP BY A.Accountid, A.Fio
ORDER BY A.Accountid;



/*
crosstab(source_sql text, category_sql text)
Параметр	                Что это	                                            Обязательность
source_sql	    SQL-запрос, который возвращает исходные данные	                ✅ Обязателен
category_sql	SQL-запрос, который возвращает список категорий (имён столбцов)	❌ Опционален (но лучше указывать)

crosstab(source_sql, category_sql)
берёт строки вида (строка, категория, значение),
и для каждой строки создаёт столбец по категории,
кладя значение в нужную ячейку.
Второй параметр задаёт, какие категории будут столбцами
и в каком порядке.

*/
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT *
FROM crosstab(
             $$
    SELECT A.Accountid, A.Fio, P.Payyear::TEXT, P.Paysum
    FROM Abonent A
    LEFT JOIN Paysumma P ON A.Accountid = P.Accountid
    WHERE P.Payyear IN (2024, 2025) OR P.Payyear IS NULL
    ORDER BY 1, 3
    $$,
    $$ VALUES ('2024'), ('2025') $$
     ) AS ct(
             Accountid TEXT,
             Fio TEXT,
             Total_2024 NUMERIC,
             Total_2025 NUMERIC
    )
ORDER BY Accountid;


/*
В качестве табличного подзапроса может использоваться любой запрос
SELECT, причём при использовании рекурсии <табличный_подзапрос>
обязательно содержит в себе объединение результатов нескольких
запросов. Примеры использования рекурсивных подзапросов в секции WITH
будут приведены после изучения объединений результатов нескольких
запросов.

Вывести наименования услуг, за которые сумма значений начислений
всем абонентам превышает более чем на величину, задаваемую
параметром Pr, начисление тому абоненту, который имеет максимальное
значение начисления, может следующий запрос:
*/

WITH
    Maxnach AS (
        SELECT MAX(Nachislsum) AS Maxpayment
        FROM Nachislsumma
    ),
    Servicenach AS (
        SELECT S.Servicenm, SUM(N.Nachislsum) AS Totalnach
        FROM Services S
                 JOIN Nachislsumma N USING(Serviceid)
        GROUP BY S.Servicenm
    )

SELECT Sn.Servicenm
FROM Servicenach Sn
         JOIN Maxnach ON Sn.Totalnach > Maxpayment + :Pr;

/*
Этот SQL-запрос выполняет следующие действия:

CTE Maxnach: в этой части запроса выбирается максимальное значение
начисления (Nachislsum) из таблицы Nachislsumma и сохраняется во
временной таблице Maxnach;

CTE Servicenach: здесь происходит подсчёт сумм значений начислений
для каждой услуги (Servicenm). Сначала выполняется соединение
таблицы услуг (Services) с таблицей начислений (Nachislsumma) по
коду услуги (Serviceid). Затем данные группируются по названию
услуги, и для каждой группы вычисляется сумма значений начислений
(Totalnach);

Основной запрос: в нём происходит соединение результатов из CTE
Servicenach с временной таблицей Maxnach по условию: значения
начислений для каждой услуги (Sn.Totalnach) должны быть больше
максимального значения начисления, найденного в CTE Maxnach,
увеличенного на определённое значение (:Pr). Результатом запроса
являются названия услуг (Sn.Servicenm), для которых выполняется
данное условие.

Итак, запрос возвращает названия услуг, значения начислений которых
превышают определённое пороговое значение (максимальное значение
начислений в таблице Nachislsumma, увеличенное на значение параметра
:Pr).


*/


SELECT A.Accountid, A.Fio,
       COALESCE(SUM(CASE WHEN P.Serviceid = 1 THEN P.Paysum END), 0) AS "Газ",
       COALESCE(SUM(CASE WHEN P.Serviceid = 2 THEN P.Paysum END), 0) AS "Электр.",
       COALESCE(SUM(CASE WHEN P.Serviceid = 3 THEN P.Paysum END), 0) AS "Тепло",
       COALESCE(SUM(CASE WHEN P.Serviceid = 4 THEN P.Paysum END), 0) AS "Вода",
       COALESCE(SUM(P.Paysum), 0) AS "ВСЕГО"
FROM Abonent A
         LEFT JOIN Paysumma P USING(Accountid)
WHERE P.Serviceid IN (1, 2, 3, 4)
GROUP BY A.Accountid, A.Fio
ORDER BY A.Accountid;


/*
Значения оплат каждым абонентом в разрезе услуг
*/

SELECT A.Accountid, A.Fio,
       COALESCE(SUM(CASE WHEN P.Serviceid = 1 THEN P.Paysum END), 0) AS "Газ",
       COALESCE(SUM(CASE WHEN P.Serviceid = 2 THEN P.Paysum END), 0) AS "Электр.",
       COALESCE(SUM(CASE WHEN P.Serviceid = 3 THEN P.Paysum END), 0) AS "Тепло",
       COALESCE(SUM(CASE WHEN P.Serviceid = 4 THEN P.Paysum END), 0) AS "Вода",
       COALESCE(SUM(P.Paysum), 0) AS "ВСЕГО"
FROM Abonent A
         LEFT JOIN Paysumma P USING(Accountid)
WHERE P.Serviceid IN (1, 2, 3, 4)
GROUP BY A.Accountid, A.Fio
ORDER BY A.Accountid;


---или CTE


WITH Serv AS (SELECT Accountid, Serviceid, SUM(Paysum) AS S
              FROM Paysumma P
              GROUP BY Accountid, Serviceid)
SELECT A.Accountid,
       A.Fio,
       COALESCE(S1.S, 0)                                                             AS "Газ",
       COALESCE(S2.S, 0)                                                             AS "Электр.",
       COALESCE(S3.S, 0)                                                             AS "Тепло",
       COALESCE(S4.S, 0)                                                             AS "Вода",
       COALESCE(S1.S, 0) + COALESCE(S2.S, 0) + COALESCE(S3.S, 0) + COALESCE(S4.S, 0) AS "ВСЕГО"
FROM Abonent A
         LEFT JOIN Serv S1 ON A.Accountid = S1.Accountid AND S1.Serviceid = 1
         LEFT JOIN Serv S2 ON A.Accountid = S2.Accountid AND S2.Serviceid = 2
         LEFT JOIN Serv S3 ON A.Accountid = S3.Accountid AND S3.Serviceid = 3
         LEFT JOIN Serv S4 ON A.Accountid = S4.Accountid AND S4.Serviceid = 4
ORDER BY A.Accountid;


SELECT A.Accountid, A.Fio,
       COALESCE(SUM(P.Paysum) FILTER (WHERE P.Serviceid = 1), 0) AS "Газ",
       COALESCE(SUM(P.Paysum) FILTER (WHERE P.Serviceid = 2), 0) AS "Электр.",
       COALESCE(SUM(P.Paysum) FILTER (WHERE P.Serviceid = 3), 0) AS "Тепло",
       COALESCE(SUM(P.Paysum) FILTER (WHERE P.Serviceid = 4), 0) AS "Вода",
       COALESCE(SUM(P.Paysum), 0) AS "ВСЕГО"
FROM Abonent A
         LEFT JOIN Paysumma P ON A.Accountid = P.Accountid AND P.Serviceid IN (1, 2, 3, 4)
GROUP BY A.Accountid, A.Fio
ORDER BY A.Accountid;


WITH Serv AS MATERIALIZED (
    SELECT Accountid,
           SUM(Paysum) FILTER (WHERE Serviceid = 1) AS Gas,
           SUM(Paysum) FILTER (WHERE Serviceid = 2) AS Electr,
           SUM(Paysum) FILTER (WHERE Serviceid = 3) AS Heat,
           SUM(Paysum) FILTER (WHERE Serviceid = 4) AS Water,
           SUM(Paysum) AS Total
    FROM Paysumma
    WHERE Serviceid IN (1, 2, 3, 4)
    GROUP BY Accountid
)
SELECT A.Accountid, A.Fio,
       COALESCE(S.Gas, 0) AS "Газ",
       COALESCE(S.Electr, 0) AS "Электр.",
       COALESCE(S.Heat, 0) AS "Тепло",
       COALESCE(S.Water, 0) AS "Вода",
       COALESCE(S.Total, 0) AS "ВСЕГО"
FROM Abonent A
         LEFT JOIN Serv S ON A.Accountid = S.Accountid
ORDER BY A.Accountid;



WITH aggregated AS (
    SELECT DISTINCT A.Accountid, A.Fio,
                    SUM(P.Paysum) FILTER (WHERE P.Serviceid = 1) OVER (PARTITION BY A.Accountid) AS Gas,
                    SUM(P.Paysum) FILTER (WHERE P.Serviceid = 2) OVER (PARTITION BY A.Accountid) AS Electr,
                    SUM(P.Paysum) FILTER (WHERE P.Serviceid = 3) OVER (PARTITION BY A.Accountid) AS Heat,
                    SUM(P.Paysum) FILTER (WHERE P.Serviceid = 4) OVER (PARTITION BY A.Accountid) AS Water,
                    SUM(P.Paysum) OVER (PARTITION BY A.Accountid) AS Total
    FROM Abonent A
             LEFT JOIN Paysumma P ON A.Accountid = P.Accountid AND P.Serviceid IN (1, 2, 3, 4)
)
SELECT Accountid, Fio,
       COALESCE(Gas, 0) AS "Газ",
       COALESCE(Electr, 0) AS "Электр.",
       COALESCE(Heat, 0) AS "Тепло",
       COALESCE(Water, 0) AS "Вода",
       COALESCE(Total, 0) AS "ВСЕГО"
FROM aggregated
ORDER BY Accountid;

/*
1.Особенности использования простого разложения на подзапросы
в секции WITH:

2.производные таблицы, определённые в секции WITH, могут ссылаться
друг на друга;

3.сcылка на производную таблицу (имя_производной_таблицы) может
использоваться в любой части основного запроса (в секциях SELECT,
FROM и т.д.);

4.одна и та же производная таблица может использоваться несколько раз
в основном запросе под разными псевдонимами;

5.в многострочных запросах на обновление (INSERT, UPDATE и DELETE)
подзапросы могут включать секцию WITH, определяющую производные
таблицы;

6.производные таблицы могут использоваться в процедурном языке.




=============================================================================
Сравнение подзапроса и обобщённого табличного выражения (CTE)
=============================================================================
После изучения вложенных запросов и общих табличных выражений можно
сделать вывод о том, что использование CTE вместо подзапроса имеет
несколько преимуществ.

-------------------------------------------------------------------------------------------------------------
| Критерий              | CTE                                           | Подзапрос                         |
|-----------------------+-----------------------------------------------+-----------------------------------|
| Множественные ссылки  | После определения CTE можно многократно       | Требуется каждый раз писать       |
|                       | ссылаться на него по имени в последующих      | полный подзапрос                  |
|                       | запросах                                      |                                   |
|-----------------------+-----------------------------------------------+-----------------------------------|
| Несколько таблиц      | Более удобен для чтения при работе с          | Подзапросы будут разбросаны       |
|                       | несколькими таблицами, поскольку можно        | по всему запросу                  |
|                       | перечислить все CTE заранее                   |                                   |
-------------------------------------------------------------------------------------------------------------

Преимущества CTE:
- Улучшает читаемость сложных запросов
- Позволяет повторно использовать один и тот же подзапрос
- Упрощает отладку (можно выполнить CTE отдельно)
- Снижает дублирование кода

Недостатки CTE:
- В PostgreSQL до версии 12 CTE материализуются (могут быть медленнее)
- Может потреблять больше памяти
=============================================================================
*/


/*

Запросы со связанными вложенными запросами!!!

Вложенный запрос может ссылаться на таблицу(ы), указанную(ые) во
внешнем (основном) запросе (независимо от его уровня вложенности).

Такой вложенный запрос называется зависимым, соотнесённым,
коррелированным или связанным из-за того, что результат его выполнения
зависит от значений, определённых в основном запросе.
При этом вложенный запрос выполняется неоднократно, по разу
для каждой строки таблицы основного (внешнего) запроса, а не раз,
как в случае независимого вложенного запроса!!!

Строка внешнего запроса, для которой внутренний запрос каждый раз
будет выполнен, называется текущей строкой-кандидатом.

Процедура оценки, выполняемой при использовании связанного
вложенного запроса, состоит из нескольких шагов:

1.выбрать очередную строку из таблицы, именованной во внешнем
запросе. Это будет текущая строка-кандидат;

2.сохранить значения из этой строки-кандидата в псевдониме,
который задан в секции FROM внешнего запроса;

3.выполнить вложенный запрос. Везде, где псевдоним, данный
для внешнего запроса, найден, использовать значение для текущей
строки-кандидата.
Использование значения из строки-кандидата
внешнего запроса во вложенном запросе называется внешней ссылкой;

4.Если связанный подзапрос используется в секции WHERE или HAVING,
оценить условие поиска (TRUE или FALSE) внешнего запроса на основе
результатов вложенного запроса, выполняемого на шаге 3.
Результат вложенного запроса определяет, выбирается ли строка-кандидат для
вывода.
Если связанный подзапрос используется в секции SELECT,
то выводятся столбцы, указанные в списке возвращаемых элементов
основного запроса, и результат выполнения вложенного запроса;


5.повторить процедуру для следующей строки-кандидата основной
(внешней) таблицы и т.д., пока все её строки не будут проверены.

Общая структура связанного подзапроса такая же, как и независимого
подзапроса (используются те же самые конструкции и не меняется
порядок их следования).
Однако в секциях:
SELECT,
WHERE,
HAVING
связанного подзапроса содержится ссылка на столбец таблицы внешнего
запроса, и алгоритм выполнения связанного подзапроса совершенно
другой.

Поскольку вложенный запрос содержит ссылки на таблицу (таблицы)
основного запроса, то вероятность неоднозначных ссылок на имена
столбцов достаточно высока!!!
Поэтому если во вложенном запросе
присутствует неполное имя столбца, сервер БД должен определить,
относится оно к таблице, указанной в секции FROM самого вложенного
запроса, или к таблице, указанной в секции FROM внешнего запроса,
содержащего данный вложенный запрос.
Возможные неоднозначности при определении столбца устраняются
использованием полного имени столбца.

Неоднозначность при определении таблицы, используемой для конкретного
отбора строк, устраняется с помощью псевдонимов таблиц, указываемых
во внешнем и внутреннем запросах.

Связанные подзапросы в секции SELECT.
Чаще всего в секции SELECT применяется вложенный связанный,
а не независимый подзапрос, и только типа <скалярный_подзапрос>.

Запрос со связанным подзапросом, возвращающий ФИО абонентов и названия
улиц, на которых они проживают, имеет вид


Скалярный подзапрос — это подзапрос, который возвращает ровно одну
строку и один столбец (одно единственное значение).
Возвращает один столбец — только Streetnm
Возвращает одну строку — условие WHERE S.Streetid = A.Streetid находит
не более одной улицы (предполагается, что Streetid — уникальный ключ
в таблице Street)
Используется в SELECT — как обычное выражение, вычисляющее значение для
каждой строки внешнего запроса
Для каждой строки Abonent выполняется отдельно, подставляя A.Streetid

*/


/*
Как он работает:
Если у абонента есть улица — возвращает название
Если у абонента нет улицы (Streetid = NULL)
или улица не найдена — возвращает NULL
Это поведение LEFT JOIN !!!
*/
SELECT A.Fio,
       (SELECT S.Streetnm
        FROM Street S
        WHERE S.Streetid = A.Streetid)
FROM Abonent A;

SELECT A.Fio, S.Streetnm
FROM Abonent A
         LEFT JOIN Street S ON A.Streetid = S.Streetid;


/*
В соответствии с алгоритмом, описанным выше, данный запрос работает
в такой последовательности:

1.внешний запрос выбирает из таблицы Abonent строку с данными
об абоненте, проживающем на улице с кодом, равным 3 (первая строка);

2.сохраняет эту строку как текущую строку-кандидат под псевдонимом A;

3.выполняет вложенный запрос, просматривающий всю таблицу Street,
чтобы найти строку, где значение столбца S.Streetid такое же,
как значение A.Streetid (3). Из найденной строки таблицы Street
извлекается значение столбца Streetnm;

4.для вывода выбираются значение столбца A.Fio из основного запроса
(Аксенов С.А.) и найденное значение столбца S.Streetnm из вложенного
запроса (Войков переулок);

5.повторяются п.п. 1-4, пока каждая строка таблицы Abonent не будет
проверена.
*/


/*
Следует напомнить, что эту же задачу можно решить с использованием
неявного или явного соединения таблиц Abonent и Street.

Пусть необходимо вывести для каждого абонента номер его лицевого
счёта, ФИО и общее количество поданных им заявок.
Для этого может использоваться запрос
*/


SELECT A.Accountid,
       A.Fio,
       (SELECT COUNT(*)
        FROM Request R
        WHERE A.Accountid = R.Accountid) AS Request_count
FROM Abonent A
ORDER BY A.Accountid;

/*
Запрос работает таким образом:

1.внешний запрос из таблицы Abonent выбирает строку с данными
об абоненте, имеющем номер лицевого счёта '005488' (первая строка);

2.сохраняет эту строку как текущую строку-кандидат под псевдонимом А;

3.выполняется вложенный запрос, просматривающий таблицу Request,
чтобы найти все строки, где значение столбца R.AccountId такое же,
как значение A.AccountId ('005488'). С помощью агрегатной функции
COUNT подсчитывается общее количество таких строк (3);

4.для вывода выбираются значения столбцов A.AccountId и A.Fio
из основного запроса ('005488', 'Аксенов С.А.') и найденное
вложенным запросом количество связанных строк в таблице Request (3);

5.повторяются п.п. 1-4, пока каждая строка таблицы Abonent не будет
просмотрена.


Данный пример запроса является демонстрационным, так как поставленную
задачу эффективнее решать с применением автономного подзапроса:
*/

SELECT A.Accountid, A.Fio, COALESCE(Request_count, 0) AS Request_count
FROM Abonent A
         LEFT JOIN (SELECT Accountid, COUNT(*) AS Request_count
                    FROM Request
                    GROUP BY Accountid) R USING (Accountid)
ORDER BY A.Accountid;


/*
Если во внешнем запросе используется секция GROUP BY, то выражения,
указанные в ней, можно использовать внутри подзапросов.
С помощью следующего запроса можно получить общие суммы начислений
и плат по услуге с кодом 2 (Электроснабжение) по каждому абоненту,
который подавал ремонтные заявки:


Здесь в подзапросах вычисляются суммы значений начислений и плат
по услуге с кодом 2 для каждого абонента, отобранного внешним запросом
из таблицы Request.
Затем возвращённые подзапросами значения выводятся
по каждому абоненту в результирующих столбцах Nachisl и Pay.
*/

---Сначала PostgreSQL группирует таблицу Request по Accountid.
--Теперь PostgreSQL берёт каждую строку (каждый уникальный Accountid)
--из сгруппированного результата и выполняет подзапросы для этой строки.
---WHERE Accountid = '005488' AND Serviceid = 2 → выбирает строки 1 и 2.
---SUM(Nachislsum) = 1000 + 1500 = 2500
--WHERE Accountid = '005488' AND Serviceid = 2 → выбирает строки 1 и 2.
--SUM(Paysum) = 500 + 700 = 1200
--(Если нет записей — SUM() возвращает NULL,
--но в запросе нет COALESCE, поэтому будет NULL)

/*
┌─────────────────────────────────────────────────────────────────────────────┐
│  Шаг 1: GROUP BY Accountid FROM Request                                     │
│  ┌─────────────┐                                                            │
│  │ '005488'    │                                                            │
│  │ '015527'    │                                                            │
│  │ '080047'    │                                                            │
│  └─────────────┘                                                            │
│         │                                                                    │
│         ▼                                                                    │
│  Шаг 2: Для каждого Accountid выполняются подзапросы                        │
│                                                                             │
│  Accountid = '005488' ──┬──► (SELECT SUM(Nachislsum) FROM Nachislsumma...)  │
│                         │         → 2500                                    │
│                         └──► (SELECT SUM(Paysum) FROM Paysumma...)          │
│                                   → 1200                                    │
│                                                                             │
│  Accountid = '015527' ──┬──► (SELECT SUM(Nachislsum) ...) → 800             │
│                         └──► (SELECT SUM(Paysum) ...) → 600                 │
│                                                                             │
│  Accountid = '080047' ──┬──► (SELECT SUM(Nachislsum) ...) → NULL            │
│                         └──► (SELECT SUM(Paysum) ...) → NULL                │
│                                                                             │
│  Шаг 3: Формирование результата                                             │
└─────────────────────────────────────────────────────────────────────────────┘
*/

SELECT R.Accountid,
       (SELECT SUM(Nachislsum)
        FROM Nachislsumma
        WHERE Accountid = R.Accountid
          AND Serviceid = 2) AS Nachisl,
       (SELECT SUM(Paysum)
        FROM Paysumma
        WHERE Accountid = R.Accountid
          AND Serviceid = 2) AS Pay
FROM Request R
GROUP BY R.Accountid;


WITH nachisl_agg AS (
    SELECT Accountid, SUM(Nachislsum) AS Nachisl
    FROM Nachislsumma
    WHERE Serviceid = 2
    GROUP BY Accountid
),
     pay_agg AS (
         SELECT Accountid, SUM(Paysum) AS Pay
         FROM Paysumma
         WHERE Serviceid = 2
         GROUP BY Accountid
     )
SELECT R.Accountid, N.Nachisl, P.Pay
FROM Request R
         LEFT JOIN nachisl_agg N ON R.Accountid = N.Accountid
         LEFT JOIN pay_agg P ON R.Accountid = P.Accountid
GROUP BY R.Accountid, N.Nachisl, P.Pay
ORDER BY R.Accountid;



SELECT R.AccountId, N.Nachisl, P.Pay
FROM Request R
         LEFT JOIN (SELECT Accountid, SUM(Nachislsum) AS Nachisl
                    FROM Nachislsumma
                    WHERE Serviceid = 2
                    GROUP BY Accountid) N ON R.Accountid = N.Accountid
         LEFT JOIN (SELECT Accountid, SUM(Paysum) AS Pay
                    FROM Paysumma
                    WHERE Serviceid = 2
                    GROUP BY Accountid) P ON R.Accountid = P.Accountid
GROUP BY R.Accountid, N.Nachisl, P.Pay
ORDER BY R.Accountid;

/*
Для получения более полной информации, например, чтобы дополнительно
вывести ФИО абонентов, подойдёт следующий запрос со скалярным
коррелированным подзапросом:
*/


SELECT R.AccountId,
       (SELECT Fio FROM Abonent WHERE Accountid = R.Accountid),
       (SELECT SUM(Nachislsum)
        FROM Nachislsumma N
        WHERE N.Accountid = R.Accountid
          AND N.Serviceid = 2) AS Nachisl,
       (SELECT SUM(Paysum)
        FROM Paysumma P
        WHERE P.Accountid = R.Accountid
          AND P.Serviceid = 2) AS Pay
FROM Request R
GROUP BY R.Accountid
ORDER BY 1;


/*
Следует отметить, что можно допустить ошибку, если попытаться получить
аналогичные данные, используя запрос с соединением таблицы, например,
такого вида:

Этот запрос выдаёт некорректные данные, так как в результате соединения
строки с начислениями и оплатами будут дублироваться.
Второй запрос (с JOIN) некорректен, потому что LEFT JOIN к двум таблицам создаёт
декартово произведение строк из Nachislsumma и Paysumma для одного абонента.
Это приводит к задвоению (заутроению) сумм.

Корректные результаты будет выдавать запрос, в котором начисления и оплаты
вычисляются отдельно во вложенных связанных подзапросах в секции SELECT
(аналогичный запросу, представленному ранее).
*/


SELECT R.AccountId,
       SUM(N.Nachislsum) AS Nachisl,
       SUM(P.Paysum) AS Pay
FROM Request R
         LEFT JOIN Nachislsumma N USING(AccountId)
         LEFT JOIN Paysumma P USING(AccountId)
WHERE P.Serviceid = 2
GROUP BY R.AccountId
ORDER BY 1;

/*

Вывести информацию о каждой заявке и при этом определить, погашена ли
она, и если да, отобразить ФИО соответствующего исполнителя, а если нет,
вывести «Not Executed», можно следующим запросом:
*/

SELECT Requestid,
       Accountid,
       CASE
           WHEN Executed = TRUE THEN (SELECT Fio
                                      FROM Executor
                                      WHERE Executorid = R.Executorid)
           ELSE 'Not Executed'
           END AS "ExecutorNameOrStatus",
       Failureid,
       Incomingdate,
       Executiondate
FROM Request R;

SELECT
    R.Requestid,
    R.Accountid,
    COALESCE(E.Fio, 'Not Executed') AS ExecutorNameOrStatus,
    R.Failureid,
    R.Incomingdate,
    R.Executiondate
FROM Request R
         LEFT JOIN LATERAL (
    SELECT Fio
    FROM Executor
    WHERE Executorid = R.Executorid AND R.Executed = TRUE
    ) E ON TRUE;

--- ON TRUE =
---"берём всё что подзапрос вернул"


SELECT R.Requestid,
       R.Accountid,
       COALESCE(E.Fio, 'Not Executed') AS ExecutorNameOrStatus,
       R.Failureid,
       R.Incomingdate,
       R.Executiondate
FROM Request R
         LEFT JOIN Executor E
                   ON E.Executorid = R.Executorid -- соединяем по ID
                       AND R.Executed = TRUE;          -- и только если Executed = TRUE


/*
Подзапросы могут быть использованы для сравнения значений с NULL
или NOT NULL в других таблицах. Например, вывести код заявки, лицевой
счёт абонента, который подал эту заявку, и ФИО её исполнителя, если он
существует, иначе вывести «Исполнитель не назначен»:
*/

SELECT Requestid,
       Accountid,
       CASE
           WHEN Executorid IS NOT NULL THEN
               (SELECT Fio
                FROM Executor
                WHERE Executorid = R.Executorid)
           ELSE 'Исполнитель не назначен'
           END AS "ExecutorName"
FROM Request R
ORDER BY Requestid;

/*
В запросе можно использовать одновременно независимые и связанные
подзапросы.
Если в предыдущем примере код услуги неизвестен,
то его можно определить, используя независимый подзапрос,
например:
*/

SELECT R.AccountId,
       (SELECT SUM(Nachislsum)
        FROM Nachislsumma N
        WHERE N.AccountId = R.AccountId
          AND N.Serviceid = (SELECT Serviceid
                             FROM Services
                             WHERE Servicenm = 'Электроснабжение')) AS Nachisl,
       (SELECT SUM(Paysum)
        FROM Paysumma P
        WHERE P.AccountId = R.AccountId
          AND P.Serviceid = (SELECT Serviceid
                             FROM Services
                             WHERE Servicenm = 'Электроснабжение')) AS Pay
FROM Request R
GROUP BY R.AccountId;

/*
Если независимый подзапрос вынести в секцию WITH, то получится запрос:
*/

WITH Service AS (
    SELECT Serviceid
    FROM Services
    WHERE Servicenm = 'Электроснабжение'
)
SELECT R.Accountid,
       (SELECT SUM(Nachislsum)
        FROM Nachislsumma N
        WHERE N.Accountid = R.Accountid
          AND N.Serviceid = (SELECT Serviceid FROM Service)) AS Nachisl,
       (SELECT SUM(Paysum)
        FROM Paysumma P
        WHERE P.Accountid = R.Accountid
          AND P.Serviceid = (SELECT Serviceid FROM Service)) AS Pay
FROM Request R
GROUP BY R.Accountid;


/*
nachislfactid|accountid|serviceid|nachislsum|nachislmonth|nachislyear
1            |136160   |2        |656.00    |1           |2025
13           |136160   |2        |620.00    |5           |2023
*/
select * ---сумма начислений 1276
from Nachislsumma
where Accountid = '136160'
and Serviceid = 2;

/*
Следующий пример запроса демонстрирует применение соединения
в подзапросе:
В этом запросе со связанным подзапросом неявно соединяются таблицы
Abonent и Street для получения ФИО абонентов и их адреса, а также
выполняется явное соединение с таблицей Request, чтобы возвратить
даты подачи ими ремонтных заявок.

*/

SELECT A.Fio,
       (SELECT S.Streetnm
        FROM Street S
        WHERE S.Streetid = A.Streetid) ||
       ', д.'  ||
       A.Houseno ||
       ', кв.' ||
       A.Flatno AS Address,
       R.Incomingdate
FROM Abonent A
         INNER JOIN Request R USING (Accountid)
ORDER BY 1;

SELECT *
FROM Street S;

select *
from Abonent A;

/*
Коррелированные подзапросы можно использовать для вычисления
накопительных итогов.
Выведем для каждой услуги суммарную величину
значений плат за каждый день и все предыдущие дни.
Запрос может быть таким:

Сам запрос синтаксически правильный и логически верный,
но есть потенциальная проблема: если в один день по одной услуге есть
несколько платежей, то GROUP BY P.Serviceid, P.Paydate
сгруппирует их в одну строку, а нарастающий итог будет считаться
по всем платежам этого дня вместе, но без учёта порядка платежей внутри дня.
*/

SELECT P.Serviceid,
       P.Paydate,
       SUM(P.Paysum),
       (SELECT SUM(Paysum)
        FROM Paysumma
        WHERE Paydate <= P.Paydate
          AND Serviceid = P.Serviceid) AS "Нарастающий итог"
FROM Paysumma P
GROUP BY P.Serviceid, P.Paydate
ORDER BY P.Serviceid, P.Paydate;

SELECT Serviceid
     , Paydate
     , Paysum
     , SUM(Paysum) OVER (PARTITION BY Serviceid ORDER BY Paydate) AS "Нарастающий итог"
     , SUM(Paysum) OVER (PARTITION BY Serviceid )                 as total_service_id
     , SUM(Paysum) OVER ()                                        as total
     , SUM(Paysum) OVER (ORDER BY Serviceid,Paydate)                        as paydates
FROM Paysumma
ORDER BY Serviceid,Paydate;
---это оконная функция без PARTITION BY, которая считает нарастающий итог по всем строкам (без разбиения на услуги),
-- но порядок определяется только Paydate.


/*

Таким образом, коррелированные подзапросы в секции SELECT полезны
для выполнения вычислений или извлечения данных, которые зависят
от каждой строки основного запроса!!!
Использование коррелированных подзапросов в секции SELECT
позволяет включать в результативный набор более информативные данные,
не создавая дополнительные JOIN, что делает запросы более лаконичными
и понятными. Например, следующий запрос вычисляет общую задолженность
или переплату каждого абонента, вычитая сумму значений всех его платежей
из общей суммы значений его начислений:
*/


/*
Сложность: O(количество абонентов × (поиск по Nachislsumma + поиск по Paysumma))
При 1 млн абонентов и 10 млн записей в каждой из таблиц —
это десятки секунд или минуты.
*/

SELECT A.AccountId,
       A.FIO,
       (SELECT SUM(N.Nachislsum)
        FROM Nachislsumma N
        WHERE N.AccountId = A.AccountId)
           -
       (SELECT SUM(P.Paysum)
        FROM Paysumma P
        WHERE P.AccountId = A.AccountId) AS "Debet/Credit"
FROM Abonent A;


SELECT a.accountid,
       a.fio,
       (SELECT SUM(n.nachislsum)
        FROM nachislsumma n
        WHERE n.accountid = a.accountid)
           -
       (SELECT SUM(p.paysum)
        FROM paysumma p
        WHERE p.accountid = a.accountid) AS "Debet/Credit"
FROM abonent a;



WITH nachisl AS (SELECT accountid,
                        nachislyear,
                        nachislmonth,
                        SUM(nachislsum) AS nachislsum
                 FROM nachislsumma
                 GROUP BY accountid, nachislyear, nachislmonth),
     payment AS (SELECT accountid,
                        payyear,
                        paymonth,
                        SUM(paysum) AS paysum
                 FROM paysumma
                 GROUP BY accountid, payyear, paymonth),
-- Объединяем все уникальные периоды для каждого абонента
     periods AS (SELECT accountid, year, month
                 FROM (SELECT accountid, nachislyear AS year, nachislmonth AS month
                       FROM nachisl
                       UNION
                       SELECT accountid, payyear, paymonth
                       FROM payment) t),
-- Собираем данные по периодам
     monthly_data AS (SELECT p.accountid,
                             p.year,
                             p.month,
                             COALESCE(n.nachislsum, 0) AS nachisl,
                             COALESCE(pm.paysum, 0)    AS pay
                      FROM periods p
                               LEFT JOIN nachisl n ON p.accountid = n.accountid AND p.year = n.nachislyear AND
                                                      p.month = n.nachislmonth
                               LEFT JOIN payment pm ON p.accountid = pm.accountid AND p.year = pm.payyear AND
                                                       p.month = pm.paymonth),
-- Добавляем накопленное сальдо
     balance AS (SELECT accountid,
                        year,
                        month,
                        nachisl,
                        pay,
                        nachisl - pay                                                         AS change,
                        SUM(nachisl - pay)
                        OVER (PARTITION BY accountid
                              ORDER BY year, month) AS balance_end
                 FROM monthly_data)
-- Финальный вывод с информацией об абоненте
SELECT a.accountid,
       a.fio,
       a.phone,
       a.houseno || ', кв.' || a.flatno                                                            AS address,
       b.year || '-' || LPAD(b.month::TEXT, 2, '0')                                                AS period,
       b.nachisl                                                                                   AS "Начисления",
       b.pay                                                                                       AS "Оплата",
       b.change                                                                                    AS "Изменение",
       COALESCE(LAG(b.balance_end, 1)
                OVER (PARTITION BY b.accountid
                    ORDER BY b.year, b.month),
                0)                                                                                 AS "Сальдо на начало",
       b.balance_end                                                                               AS "Сальдо на конец"
FROM abonent a
         JOIN balance b ON a.accountid = b.accountid
WHERE a.accountid = '136160' -- ← подставьте нужный лицевой счёт
ORDER BY b.year, b.month;



/*
А проверить, есть ли у абонента начисления, превышающие среднее
начисление по его аккаунту, можно так:
здесь подзапросы используются для подсчёта начислений, превышающих
среднее значение для данного абонента.
*/

SELECT A.AccountId,
       A.FIO,
       (SELECT COUNT(*)
        FROM Nachislsumma N
        WHERE N.AccountId = A.AccountId
          AND N.Nachislsum > (SELECT AVG(N1.Nachislsum)
                              FROM Nachislsumma N1
                              WHERE N1.AccountId = A.AccountId)) AS Above_average_accruals
FROM Abonent A;

/*
Здесь подзапросы используются для подсчёта начислений, превышающих
среднее значение для данного абонента.
*/


/*
Связанные подзапросы в секции FROM.
В секции FROM можно использовать только независимый подзапрос!!!,
но внутри последнего можно применять коррелированный вложенный запрос!!!
В следующем запросе реализован вывод номеров лицевых счетов абонентов,
имеющих отрицательную разницу между суммами значений всех их оплат и
начислений (задолженность):
*/

SELECT t.accountid, ABS(t."Долг")
FROM (SELECT p.accountid,
             (SUM(p.paysum) - (SELECT SUM(n.nachislsum)
                               FROM nachislsumma n
                               WHERE n.accountid = p.accountid
                               GROUP BY n.accountid)) AS "Долг"
      FROM paysumma AS p
      GROUP BY p.accountid) t
WHERE t."Долг" < 0
ORDER BY t."Долг";

/*
Для вычисления по каждому абоненту искомой разницы в секции FROM
основного запроса применён автономный подзапрос, содержащий
коррелированный вложенный запрос. В качестве выходного значения,
элемента фильтрации строк и сортировки используется псевдоним
«Долг».
Применяя предыдущий запрос, можно вычислить общие значения
переплаты и задолженности следующим образом:
*/


SELECT SUM(CASE WHEN "Сальдо" > 0 THEN "Сальдо" ELSE 0 END)      AS "Переплата",
       SUM(CASE WHEN "Сальдо" < 0 THEN ABS("Сальдо") ELSE 0 END) AS "Долг"
FROM (SELECT P.Accountid,
             (SUM(P.Paysum) - (SELECT SUM(N.Nachislsum)
                               FROM Nachislsumma N
                               WHERE N.Accountid = P.Accountid
                               GROUP BY N.Accountid)) AS "Сальдо"
      FROM Paysumma AS P
      GROUP BY P.Accountid) t;

/*
Коррелированный подзапрос в секции FROM применяется с помощью
конструкции LATERAL.
Принципиальное отличие такого вложенного запроса
заключается в возвращаемом результате.

Если коррелированные подзапросы в секциях SELECT и WHERE
возвращают одно значение или TRUE/FALSE,
то запрос во FROM может возвращать таблицу.

Ключевое слово LATERAL, используемое во FROM-секции запроса,
позволяет вложенному запросу обращаться к строкам, извлечённым основной
частью запроса — то есть к текущей строке «левой» таблицы.

Это делает возможным создание построчных зависимых соединений между
таблицами, особенно если данные поступают из разных источников и
имеют несовпадающие временные метки.

Например, для вывода по каждому абоненту его номера лицевого счёта
и ФИО, а также всех данных о последней поданной ремонтной заявке,
можно использовать такой запрос:
*/

SELECT a.accountid,
       fio,
       last_request.*
FROM abonent a
         INNER JOIN LATERAL
    (SELECT *
     FROM request r
     WHERE accountid = a.accountid
     ORDER BY r.incomingdate DESC
     LIMIT 1) AS last_request ON TRUE;


/*
LATERAL позволяет подзапросу в FROM обращаться к колонкам
из левой таблицы и выполняться для каждой строки этой таблицы.

Запрос работает следующим образом:

-для каждой строки из Abonent выполняется подзапрос, отбирающий самую
позднюю (по Incomingdate) заявку из таблицы Request;

-подзапрос ограничен LIMIT 1, чтобы вернуть только одну — последнюю
известную заявку;

-условие ON TRUE указывает, что явного соединительного условия здесь
не требуется — связь установлена в самом подзапросе.

Если убрать ключевое слово LATERAL, подзапрос не сможет обратиться
к A.Accountid, и PostgreSQL выдаст ошибку: в элементе предложения FROM
неверная ссылка на таблицу «a».

Рассмотрим пример связанного подзапроса с применением приёма,
аналогичного Asof JOIN.
Предположим, необходимо сопоставить данные из таблиц Request и Paysumma
по дате регистрации заявки и дате оплаты.
Однако поскольку данные из этих таблиц могут
поступать из разных систем, точное совпадение дат встречается редко.
В таких ситуациях применяется LATERAL, позволяющий гибко выбирать
строку из второй таблицы (в данном случае — Paysumma) для каждой
строки из первой таблицы (Request).

Семантика запроса следующая: «Найти последний (максимально близкий,
но не превышающий по дате) платёж для каждой заявки на ремонт»:
*/

SELECT *
FROM Request R
         LEFT JOIN LATERAL
    (SELECT p.Payfactid, p.Paysum, p.Paydate
     FROM Paysumma p
     WHERE p.Accountid = R.Accountid
       AND p.Paydate <= R.Incomingdate
     ORDER BY Paydate DESC
     LIMIT 1) t ON TRUE ---можно использовать CROSS JOIN LATERAL
ORDER BY r.Incomingdate - t.Paydate, r.Requestid;


/*
Этот запрос выполняется по принципу «сверху-вниз».
Берётся строка из таблицы Request, то есть конкретная заявка,
поданная определённым абонентом, и выполняется подзапрос с условием

Accountid = R.Accountid AND Paydate <= Incomingdate

Таким образом, из таблицы Paysumma выбираются только платежи данного
абонента с датой не позднее даты регистрации выбранной заявки.

Затем выполняется левое соединение текущей строки из таблицы Request
на все строки, которые возвратил подзапрос.
После этого берётся следующая строка из таблицы Request,
для неё выполняется подзапрос, и эта строка соединяется со строками,
которые возвратил подзапрос.
Этот процесс повторяется до исчерпания строк таблицы Request!!!
Все сформированные наборы строк объединяются в единую результирующую
выборку.

В результате, например, ближайшим к дате регистрации заявки с номером
13 от 04.09.2022 является платёж № 29 от 03.05.2022, а для заявки
с № 21 от 13.09.2023 — платёж № 17 от 13.09.2023.
Если для заявки подходящий платёж не найден (например, Incomingdate раньше всех дат
оплат по этому счёту), то поля Payfactid, Paysum и Paydate будут NULL —
благодаря LEFT JOIN.

Следует отметить, что в контексте JOIN LATERAL можно использовать
коррелированные подзапросы внутри секции LIMIT, что расширяет
возможности SQL для сложных аналитических запросов.
Это демонстрирует гибкость конструкции LATERAL,
которая позволяет создавать сложные зависимости между данными в запросе.
*/



/*
Связанные подзапросы в секциях WHERE и HAVING. При использовании
связанного вложенного запроса в условиях поиска секций WHERE и HAVING
он может представлять собой <скалярный_подзапрос>, <подзапрос_столбца>
или <табличный_подзапрос>, как и для независимых вложенных запросов.
Поскольку запрос связанный, то внутренний запрос выполняется отдельно
для каждой строки внешнего запроса (текущая строка-кандидат).

Рассмотрим примеры, в которых используются:
-<скалярный_подзапрос>
и
-<подзапрос_столбца>.


Подзапросы, представляющие собой <табличный_подзапрос>,
будут рассмотрены позднее при изучении предиката EXISTS.

!!!Лучший способ решить любую задачу — это представить её в виде
пошаговой логики!!!

Пусть, например, требуется найти:
1.номера лицевых счетов абонентов
2.которые имеют максимальное значение платежа по каждой услуге.

1.Сначала найдём максимальное значение платежа за каждую
услугу.
2.Затем определяем формат вывода, для чего нужен только номер
лицевого счёта.

-- 1-й шаг. Найдём максимальное значение платежа за каждую услугу
*/
SELECT MAX(Paysum)
FROM Paysumma
GROUP BY Serviceid;

-- 2-й шаг. Получаем нужный формат вывода Accountid
/*
Так как Accountid нельзя напрямую использовать
в группе путём агрегации, используем связанный подзапрос
*/

SELECT P.Accountid, P.Serviceid, P.Paysum, p.Paydate, p.payfactid
FROM Paysumma P
WHERE P.Paysum = (SELECT MAX(Paysum)
                  FROM Paysumma
                  GROUP BY Serviceid
                  HAVING Serviceid = P.Serviceid)
order by p.accountid, p.serviceid;

-- Найдём все платежи абонента 115705 по услуге 2
SELECT Payfactid, Accountid, Serviceid, Paysum, Paydate
FROM Paysumma
WHERE Accountid = '115705'
  AND Serviceid = 2;


/*
Чтобы вывести все данные об абонентах, которые 17 декабря 2023 г.
подали заявки на ремонт газового оборудования (рис. 4.50),
можно использовать связанный вложенный запрос:
*/

SELECT *
FROM Abonent Out
WHERE '17.12.2023' IN
      (SELECT Incomingdate
       FROM Request Inn
       WHERE Out.Accountid = Inn.Accountid);

---или

SELECT *
FROM Abonent Out
WHERE TO_DATE('17.12.2023', 'DD.MM.YYYY') IN
      (SELECT Incomingdate
       FROM Request Inn
       WHERE Out.Accountid = Inn.Accountid);

/*
В этом примере Out и Inn — это соответственно псевдонимы таблиц
Abonent и Request (могут задаваться произвольно).
Поскольку значение в столбце Accountid внешнего запроса меняется
(при переборе строк), внутренний запрос должен выполняться отдельно
для каждой строки внешнего запроса.
SQL здесь осуществляет следующую процедуру:
- выбирает строку с данными об абоненте, имеющем номер лицевого
счёта '005488' (первая строка), из таблицы Abonent;
- сохраняет эту строку как текущую строку-кандидат под псевдонимом Out;
- выполняет вложенный запрос, просматривающий всю таблицу Request,
чтобы найти строки, где значение столбца Inn.Accountid — такое же,
как значение Out.Accountid (005488).
- затем из каждой такой строки таблицы Request извлекается значение
столбца Incomingdate.
-в результате вложенный запрос, представляющий
собой <подзапрос_столбца>, формирует набор значений столбца Incomingdate
для текущей строки-кандидата;

после получения набора всех значений столбца Incomingdate для
Accountid = '005488' анализируется условие поиска основного запроса,
чтобы проверить, имеется ли значение 17 декабря 2023 г. в наборе
всех значений столбца Incomingdate. Если это так (а это так),
выбирается строка с номером лицевого счёта '005488' для вывода её
из основного запроса;

повторяются п.п. 1-4 (для второй строки с номером лицевого счёта
'015527' и т.д.), пока каждая строка таблицы Abonent не будет
проверена.

Тут же самую задачу можно решить, используя естественное соединение
таблиц Abonent и Request:
*/

explain analyze
SELECT A.*
FROM Abonent A
         NATURAL JOIN Request Inn
WHERE Inn.Incomingdate = '17.12.2023';

---или

explain analyze
SELECT A.*
FROM Abonent A
         NATURAL JOIN Request Inn
WHERE Inn.Incomingdate = TO_DATE('17.12.2023', 'DD.MM.YYYY');

/*
Результат выполнения будет совпадать с результатом, представленным
Однако следует обратить внимание на наличие существенных
различий между соединением таблиц и вложенными соотнесёнными
запросами.

Дело в том, что запросы с использованием соединения таблиц
формируются СУБД как строки из декартова произведения таблиц,
перечисленных в секции FROM.

В случае же с вложенным соотнесённым
запросом строки из произведения таблиц не вычисляются благодаря
использованию механизма строки-кандидата.

Вывод в связанном вложенном запросе формируется в секции
SELECT внешнего запроса, в то время как соединения могут выводить
строки из обеих соединяемых таблиц (при указании символа «*» в секции SELECT).
Но даже если столбцы для вывода при соединении таблиц указаны явно
(см. предыдущий пример), то сначала всё равно формируется декартово произведение.

Пример использования подзапроса, возвращающего результат выражения,
основанного на столбце, может быть следующий запрос:
*/

explain analyze
SELECT *
FROM Paysumma P
WHERE Paysum IN (SELECT Nachislsum + 10
                 FROM Nachislsumma
                 WHERE Accountid = P.Accountid);

/*Хорошим примером выборки из таблицы нужных строк является такой
запрос:
*/

explain analyze
SELECT *
FROM Nachislsumma N
WHERE (SELECT Fio FROM Abonent WHERE Accountid = N.Accountid)
          ILIKE '%д%'
order by N.Accountid;

/*
Содержательная интерпретация этого запроса состоит в следующем.
Вывести всю информацию о начислениях абонентов, в ФИО которых
встречается буква «д» без учёта регистра.

Сортировать по возрастанию номера лицевого счёта.

В результате выполнения такого запроса выводится
вся информация о начислениях абонентов с ФИО Денисова Е.К. ('136169')
и Стародубцев Е.В. ('443069'), упорядоченная по возрастанию номера
лицевого счёта.

Каждый SQL-запрос можно оценить с точки зрения используемых ресурсов
сервера БД.

На практике большинство СУБД подзапросы выполняют более
эффективно.

Тем не менее при проектировании комплекса программ
с критичными требованиями по быстродействию разработчик должен
проанализировать план выполнения SQL-запроса для конкретной СУБД.

Тестирование в реальных условиях — единственный надёжный способ
решить, что лучше подходит для конкретных потребностей.

Рассмотрим пример сравнения значения, возвращаемого вложенным
запросом, с константой.
Вывести информацию об исполнителях, назначенных на выполнение четырёх
и более ремонтных заявок, можно с помощью запроса
*/

SELECT *
FROM Executor e
WHERE 4 <= (SELECT COUNT(r.Requestid)
            FROM Request r
            WHERE e.Executorid = r.Executorid);


/*
В данном примере связанный подзапрос в условии поиска представляет
собой <скалярный_подзапрос>.
Он возвращает одно единственное значение
(количество ремонтных заявок) для текущей строки-кандидата, выбранной
из таблицы Executor.

Если это значение больше или равно 4, то текущая
строка-кандидат выбирается для вывода из основного запроса.
Эта процедура повторяется, пока каждая строка таблицы Executor не будет
проверена.

В SQL имеется возможность использовать соотнесённый вложенный запрос,
основанный на той же самой таблице, что и основной запрос.

Это позволяет использовать соотнесённые вложенные запросы для извлечения сложных
форм производной информации.

Например, вывести для каждого абонента размеры начислений,
превышающие среднее значение всех его начислений, можно с помощью следующего
запроса (в результирующий НД необходимо включить только первые восемь строк):
*/

SELECT A.AccountId,
       A.Fio,
       N.Nachislsum,
       (SELECT ROUND(AVG(Nachislsum), 2)
        FROM Nachislsumma
        WHERE AccountId = N.AccountId) AS Avg_d
FROM Abonent A
         INNER JOIN Nachislsumma N USING (AccountId)
WHERE Nachislsum > (SELECT ROUND(AVG(Nachislsum), 2)
                    FROM Nachislsumma
                    WHERE AccountId = N.AccountId)
ORDER BY 1, 3
    FETCH FIRST 8 ROWS ONLY;

/*
В этом примере производится одновременная оценка среднего значения
для всех строк, удовлетворяющих условию поиска в секции WHERE
вложенного связанного запроса, одной и той же таблицы со значениями
строки-кандидата.


Выбирается первая строка-кандидат из таблицы
Nachislsumma и сохраняется под псевдонимом F.

Выполняется вложенный запрос, просматривающий ту же самую таблицу
Nachislsumma с самого начала, чтобы найти все строки,
где значение столбца S.Accountid — такое же,
как значение F.Accountid. Затем по всем таким строкам
в таблице Nachislsumma вложенный запрос (<скалярный_подзапрос>)
подсчитывает среднее значение столбца Nachislsum. Анализируется
условие поиска основного запроса, чтобы проверить, превышает ли
значение столбца Nachislsum из текущей строки-кандидата среднее
значение, вычисленное вложенным запросом. Если это так, то текущая
строка-кандидат выбирается для вывода. Таким образом, производятся
одновременно и вычисление среднего, и отбор строк, удовлетворяющих
условию.

Построим запрос на основе CTE, выбирающий ту же информацию:
*/

WITH T AS (SELECT Accountid, ROUND(AVG(Nachislsum), 2) AS Avg_d
           FROM Nachislsumma
           GROUP BY Accountid)

SELECT A.Accountid, A.Fio, N.Nachislsum, T.Avg_d
FROM Nachislsumma N
         LEFT JOIN T USING (Accountid)
         LEFT JOIN Abonent A USING (Accountid)
WHERE N.Nachislsum > T.Avg_d
ORDER BY 1, 3
    FETCH NEXT 8 ROWS ONLY;

/*
Запрос, использующий агрегатную функцию в условии поиска основного
запроса (данная функция является возвращаемым элементом вложенного
запроса), нельзя сформулировать с помощью техники соединения таблиц.

Коррелированные подзапросы в секции WHERE полезны в следующих
ситуациях:

1.если необходимо отфильтровать строки в одной таблице на основе
данных из другой таблицы,
где условия фильтрации зависят от каждой строки внешнего запроса;

2.использование подзапроса в WHERE для проверки наличия связанных
записей в другой таблице.
Это часто реализуется с помощью оператора EXISTS;

3.если требуется сравнить значения в одной таблице с вычисляемыми
значениями из другой таблицы, и эти вычисления зависят от текущей
строки;

4.когда условия фильтрации настолько сложны, что их невозможно
выразить с помощью простых логических операторов. Коррелированные
подзапросы могут использоваться для создания более сложных
логических условий;

5.если необходимо извлечь специфические значения на основе условий,
которые зависят от данных текущей строки.

Если необходимо получить список всех абонентов, чья общая сумма
платежей превышает среднюю сумму платежей по всем абонентам, то
можно использовать такой запрос с коррелированным подзапросом:
*/

SELECT a.accountid,
       a.fio,
       (SELECT SUM(p.paysum)
        FROM paysumma p
        WHERE p.accountid = a.accountid) AS total_payments

FROM abonent a
WHERE (SELECT AVG(total_sum)
       FROM (SELECT SUM(p.paysum) AS total_sum
             FROM paysumma p
             GROUP BY p.accountid) AS subquery)
          <
      (SELECT SUM(p.paysum)
       FROM paysumma p
       WHERE p.accountid = a.accountid)
ORDER BY a.accountid;


WITH payments AS (SELECT accountid, SUM(paysum) AS total_payments
                  FROM paysumma
                  GROUP BY accountid),

     ranked AS (SELECT accountid,
                       total_payments,
                       AVG(total_payments) OVER () AS avg_total
                FROM payments)

SELECT a.accountid, a.fio, r.total_payments
FROM abonent a
         JOIN ranked r ON a.accountid = r.accountid
WHERE r.total_payments > r.avg_total
ORDER BY a.accountid;



WITH payments AS (SELECT accountid, SUM(paysum) AS total_payments
                  FROM paysumma
                  GROUP BY accountid)

SELECT a.accountid, a.fio, p.total_payments
FROM abonent a
         JOIN payments p ON a.accountid = p.accountid
WHERE p.total_payments > (SELECT AVG(total_payments) FROM payments)
ORDER BY a.accountid;

/*
Здесь использован коррелированный подзапрос для вычисления общей суммы
платежей для каждого абонента, чтобы затем сравнить её со средним
значением по всем абонентам.
*/


/*
Найти абонентов, у которых есть задолженность по платежам (т.е. сумма
значений начислений превышает сумму значений платежей), можно таким
запросом:
*/

SELECT a.accountid,
       a.fio,
       (SELECT COALESCE(SUM(n.nachislsum), 0)
        FROM nachislsumma n
        WHERE n.accountid = a.accountid) AS total_charges,

       (SELECT COALESCE(SUM(p.paysum), 0)
        FROM paysumma p
        WHERE p.accountid = a.accountid) AS total_payments

FROM abonent a
WHERE (SELECT COALESCE(SUM(n.nachislsum), 0)
       FROM nachislsumma n
       WHERE n.accountid = a.accountid) >
      (SELECT COALESCE(SUM(p.paysum), 0)
       FROM paysumma p
       WHERE p.accountid = a.accountid);



WITH charges AS (SELECT accountid, COALESCE(SUM(nachislsum), 0) AS total_charges
                 FROM nachislsumma
                 GROUP BY accountid),

     payments AS (SELECT accountid, COALESCE(SUM(paysum), 0) AS total_payments
                  FROM paysumma
                  GROUP BY accountid)

SELECT a.accountid,
       a.fio,
       COALESCE(c.total_charges, 0)  AS total_charges,
       COALESCE(p.total_payments, 0) AS total_payments
FROM abonent a
         LEFT JOIN charges c ON a.accountid = c.accountid
         LEFT JOIN payments p ON a.accountid = p.accountid
WHERE COALESCE(c.total_charges, 0) > COALESCE(p.total_payments, 0);


/*
Применены коррелированные подзапросы, чтобы получить общую сумму
начислений и общую сумму платежей для каждого абонента, чтобы выяснить,
есть ли задолженность.

Рассмотрим использование соотнесённого вложенного запроса в условии
поиска секции HAVING.

Условие поиска секции HAVING в подзапросе оценивается для каждой
группы из внешнего запроса, а не для каждой строки. Следовательно,
вложенный запрос будет выполняться только раз для каждой группы,
выведенной внешним запросом, а не для каждой строки (как это было
при использовании в секции WHERE).

Например, чтобы подсчитать общие суммы начислений за услуги для
абонентов, чьи ФИО начинаются с буквы «С» (рис. 4.53), можно
использовать соотнесённый вложенный запрос:
*/


SELECT n.accountid, SUM(n.nachislsum) AS summ
FROM nachislsumma n
GROUP BY accountid
HAVING accountid = (SELECT a.accountid
                    FROM abonent a
                    WHERE a.accountid = n.accountid
                      AND a.fio LIKE 'С%')
ORDER BY n.accountid;

/*
Последовательность выполнения: основной запрос группирует таблицу
Nachislsumma по столбцу Accountid; затем для каждой группы выполняется
связанный вложенный запрос, возвращая единственное значение столбца
Accountid таблицы Abonent (столбец Accountid содержит уникальные
значения).

Использование коррелированных подзапросов в секции HAVING полезно,
если:
1.нужно сравнить агрегированное значение каждой группы с
агрегированными результатами, зависящими от подзапроса;
2.требуется отбор на основе вложенных условий, зависящих от сложных
логических операций.
*/



/*
Связанные подзапросы в секции ORDER BY.
Это может быть полезно, если нужно отсортировать результаты
на основе данных, которые вычисляются динамически с помощью подзапроса.
Важно, чтобы подзапрос возвращал одно значение для каждой строки
основного запроса.
Пусть необходимо вывести ФИО каждого абонента и всю информацию о его
платежах со значениями меньше среднего.
Результат упорядочить по наименованию соответствующей услуги:
*/


SELECT a.fio, p.*
FROM paysumma p
         JOIN abonent a USING (accountid)
WHERE p.paysum < (SELECT AVG(paysum)
                  FROM paysumma
                  WHERE accountid = a.accountid)
ORDER BY (SELECT servicenm
          FROM services
          WHERE serviceid = p.serviceid);



/*
Количественные предикаты.
Проверка существования результата запроса

Количественные предикаты
Операции сравнения в секциях:
- WHERE
- HAVING
можно расширить до многократного сравнения с использованием
кванторов ANY и ALL.
Это расширение используется при сравнении значений определённого столбца
со значениями, возвращаемыми вложенным запросом (<подзапрос_столбца>).

Оператор NOT не может использоваться с ANY и ALL!!!

Квантор ANY.
Квантор ANY, указанный после знака любой из операций
сравнения, означает, что будет возвращено TRUE, если хотя бы для одного
значения из подзапроса результат сравнения истинен!!!

Рассмотрим использование квантора ANY с независимым подзапросом.
Например, требуется вывести всю информацию об оплатах абонентам услуги
с кодом, равным 4, за период до 2025 г., размер которых превышает
хотя бы одно значение оплат этой же услуги за 2025 г.

Соответствующий запрос будет выглядеть так:
*/

SELECT *
FROM paysumma
WHERE paysum > ANY (SELECT paysum
                    FROM paysumma
                    WHERE payyear = 2025
                      AND serviceid = 4)

---ANY означает «хотя бы один» (логическое ИЛИ).
---x > значение1 OR x > значение2 OR x > значение3 OR ...
  AND payyear < 2025
  AND serviceid = 4
ORDER BY payfactid;



/*
В этом примере вложенный запрос выполняется только раз, возвращая
все значения столбца Paysum, для которых истинно условие Payyear = 2025
и Serviceid = 4 (311.30, 160.00...).
Затем значения, выбранные подзапросом, последовательно сравниваются
со значением столбца Paysum для каждой строки!!! из таблицы Paysumma
основного запроса. При первом обнаруженном совпадении сравнение
прекращается, и соответствующая строка выводится.

Условие «> ANY» равносильно утверждению «больше, чем минимальное
из существующих», а условие «< ANY» — «меньше, чем максимальное
из существующих».

Становится очевидным, что эти условия можно записать
иначе, используя агрегатные функции MIN и MAX.

Предыдущий запрос можно переписать со скалярным подзапросом:
*/

SELECT *
FROM paysumma
WHERE paysum > (SELECT MIN(paysum)
                FROM paysumma
                WHERE payyear = 2025
                  AND serviceid = 4)
  AND payyear < 2025
  AND serviceid = 4
ORDER BY payfactid;

/*
Следует отметить, что использование сравнения «= ANY» эквивалентно
использованию предиката IN.
Например, для вывода всех данных о платежах
тех абонентов, у которых есть хотя бы один платёж
со значением, превышающим 2300, можно использовать следующие
эквивалентные запросы:

Эти запросы ищут платежи, номер лицевого счёта которых равен хотя бы
одному номеру лицевого счёта из подзапроса, выбирающего Accountid тех
платежей, где значение (Paysum) превышает 2300.
*/

SELECT *
FROM paysumma
WHERE accountid = ANY (SELECT accountid
                       FROM paysumma
                       WHERE paysum > 2300)
ORDER BY accountid;

--или

SELECT *
FROM paysumma
WHERE accountid IN (SELECT accountid
                    FROM paysumma
                    WHERE paysum > 2300)
ORDER BY accountid;

/*
Квантор ALL.
Квантор всеобщности ALL, указанный после знака
любой из операций сравнения, требует, чтобы результат сравнения был
истинным для всех значений, возвращаемых подзапросом.

Рассмотрим использование квантора ALL с независимым вложенным
запросом.
Например, требуется вывести всю информацию о ремонтных
заявках, дата регистрации которых ранее даты регистрации всех заявок
с кодом неисправности газового оборудования, равным 7.

Соответствующий запрос:
*/

SELECT *
FROM request
WHERE incomingdate < ALL (SELECT incomingdate
                          FROM request
                          WHERE failureid = 7)
ORDER BY requestid;

/*
Если требуется вывести всю информацию о ремонтных заявках, дата
выполнения которых позднее даты выполнения всех заявок с кодом
неисправности, равным 2, то запрос будет выглядеть так:

В процессе выполнения данного запроса подзапросом формируется набор
значений столбца Executiondate, взятых из строк, где Failureid = 2.
В результате условие поиска внешнего запроса будет выглядеть
следующим образом:
Executiondate > ALL (24.10.2024, 10.08.2023, 11.10.2023, 14.09.2023).
*/


SELECT * FROM Request
WHERE Executiondate > ALL (SELECT Executiondate
                           FROM Request
                           WHERE Failureid = 2)
ORDER BY Requestid;

/*
Результат использования квантора ALL

В НД не включены строки, где столбец Executiondate имеет NULL, так как
проверка условия «NULL > ALL(...)» всегда возвращает результат FALSE,
а выводятся только те строки, для которых условие поиска истинно.

Условие «> ALL» равносильно утверждению «больше, чем максимальное»,
а условие «< ALL» — «меньше, чем минимальное». Становится очевидным,
что такие условия можно записать иначе, используя агрегатные функции
MAX и MIN. Таким образом, предыдущий запрос можно переписать
со скалярным подзапросом:
*/

SELECT *
FROM request
WHERE executiondate > (SELECT MAX(executiondate)
                       FROM request
                       WHERE failureid = 2)
ORDER BY requestid;

/*
Следует отметить, что использование сравнения «<> ALL» эквивалентно
использованию предиката NOT IN независимо от того, независимый или
связанный подзапрос используется.

Примером применения квантора ALL в секции HAVING может быть запрос,
возвращающий название самой «популярной» услуги, т.е. за которую
произведено наибольшее количество плат:
*/

SELECT s.servicenm, sum(p.paysum), count(*)
FROM services s
         JOIN paysumma p USING (serviceid)
GROUP BY s.servicenm
HAVING COUNT(*) >= ALL (SELECT COUNT(*)
                        FROM paysumma
                        GROUP BY serviceid);

/*
Рассмотрим использование связанного подзапроса с квантором ALL.
Пусть требуется вывести наименования неисправностей газового
оборудования,
все ремонтные заявки с которыми зарегистрированы
после 1 мая 2023 г. Соответствующий запрос:
*/

SELECT d.failurenm
FROM disrepair d
WHERE '01.05.2023' < ALL (SELECT r.incomingdate
                          FROM request r
                          WHERE d.failureid = r.failureid);


SELECT d.failurenm
FROM disrepair d
WHERE TO_DATE('01.05.2023', 'DD.MM.YYYY') < ALL
      (SELECT r.incomingdate
       FROM request r
       WHERE d.failureid = r.failureid);

/*
Поскольку в этом примере используется связанный подзапрос, он
выполняется для каждой текущей строки из таблицы Disrepair (эта строка
сохраняется во внешнем запросе под псевдонимом D).
Вложенный запрос просматривает всю таблицу Request,
чтобы найти строки, где значение столбца R.Failureid такое же,
как значение столбца D.Failureid, и формирует набор значений столбца
Incomingdate для текущей строки - кандидата.

Затем анализируется условие поиска основного запроса,
чтобы проверить, меньше ли значение '01.05.2023' всех значений столбца
Incomingdate, полученных подзапросом.
Если это так, то текущая строка-кандидат выбирается
для вывода её из основного запроса!!!
*/


/*
Следующий запрос со связанным подзапросом в секции HAVING позволяет
определить тех абонентов, у кого максимальное значение платежа как
минимум в 2.8 раза превышает среднее значение платежей остальных
абонентов.
*/

SELECT P.AccountId
FROM Paysumma P
GROUP BY P.AccountId
HAVING MAX(P.Paysum) >= ALL
       (SELECT 2.8 * AVG(P1.Paysum)
        FROM Paysumma P1
        WHERE P.AccountId <> P1.AccountId);

/*

┌─────────────────────────────────────────────────────────────────────────────┐
│  Внешний запрос: GROUP BY AccountId → для каждого AccountId:               │
│                                                                             │
│  AccountId = 1: MAX = 300                                                   │
│      Подзапрос: средний платёж всех остальных (2,3,4) = 330                 │
│      2.8 × 330 = 924 → 300 >= 924? FALSE → НЕ ВЫВОДИТ                       │
│                                                                             │
│  AccountId = 2: MAX = 70                                                    │
│      Подзапрос: средний платёж всех остальных (1,3,4) = 390                 │
│      2.8 × 390 = 1092 → 70 >= 1092? FALSE → НЕ ВЫВОДИТ                      │
│                                                                             │
│  AccountId = 3: MAX = 1100                                                  │
│      Подзапрос: средний платёж всех остальных (1,2,4) = 101.25              │
│      2.8 × 101.25 = 283.5 → 1100 >= 283.5? TRUE → ВЫВОДИТ                   │
│                                                                             │
│  AccountId = 4: MAX = 20                                                    │
│      Подзапрос: средний платёж всех остальных (1,2,3) = 360                 │
│      2.8 × 360 = 1008 → 20 >= 1008? FALSE → НЕ ВЫВОДИТ                      │
└─────────────────────────────────────────────────────────────────────────────┘

Строки таблицы Paysumma группируются внешним запросом по значениям
столбца AccountId.
Это делается с помощью секций:
SELECT,
FROM,
GROUP BY.
Получившиеся группы фильтруются секцией HAVING. В ней для каждой из
групп вычисляется (с помощью функции MAX) максимум значений из столбца
Paysum, которые находятся в строках этой группы.

Внутренний запрос дважды проверяет среднее значение Paysum для всех
строк, в которых значения столбца AccountId отличаются от значения
этого столбца в текущей группе внешнего запроса. Следует обратить
внимание, что в последней строке запроса приходится указывать два
значения, взятые из разных AccountId. Поэтому в секции FROM из внешнего
и внутреннего запросов приходится для таблицы Paysumma указывать два
разных псевдонима.

Эти псевдонимы затем используются в сравнении, расположенном
в последней строке запроса. Цель их использования состоит в том,
чтобы показать — обращение должно идти к значению столбца AccountId
из текущей строки внутреннего подзапроса (P1.AccountId), а также
к значению того же столбца, но на этот раз из текущей группы внешнего
подзапроса (P.AccountId).


Применение в одном запросе и квантора ANY, и ALL можно
продемонстрировать в решении следующего кейса.
Вывести всю информацию об оплатах абонентами услуги с кодом, равным 4,
за период до 2025 г., размер которых превышает хотя бы одно значение
оплат этой же услуги за 2025 г.
и всю информацию о ремонтных заявках,
дата регистрации которых ранее даты регистрации всех заявок с кодом
неисправности газового оборудования, равным 7:
*/


SELECT *
FROM paysumma
         INNER JOIN request USING (accountid)
WHERE paysum > ANY (SELECT MIN(paysum)
                    FROM paysumma
                    WHERE payyear = 2025
                      AND serviceid = 4)
  AND payyear < 2025
  AND serviceid = 4
  AND incomingdate < ALL (SELECT incomingdate
                          FROM request
                          WHERE failureid = 7)
ORDER BY payfactid;

/*
При отсутствующих данных следует иметь в виду различие влияния на них
кванторов ANY и ALL.
Когда правильный подзапрос не возвращает результатов,
квантор ALL автоматически принимает значение TRUE, а квантор ANY
— FALSE.
*/

SELECT *
FROM request
WHERE executiondate > ANY (SELECT executiondate
                           FROM request
                           WHERE failureid = 4);

--не возвращает выходных данных (в учебной базе нет заявок с
-- неисправностью с кодом 4), в то время как запрос

SELECT *
FROM request
WHERE executiondate > ALL (SELECT executiondate
                           FROM request
                           WHERE failureid = 4);

/*
Проверка существования результата запроса
В SQL проверка существования результата запроса представляет собой
логическое выражение

[NOT] EXISTS (<подзапрос>)

Результат условия считается истинным только тогда, когда результат
выполнения <подзапрос> является непустым множеством, т.е. когда
существует какая-либо строка в таблице, удовлетворяющая условию
поиска секции WHERE вложенного запроса.

Другими словами, EXISTS — это проверка, которая возвращает значение,
равное TRUE или FALSE, в зависимости от наличия вывода из вложенного
запроса.
Она может работать автономно в секции SELECT и в условии
поиска или в комбинации с другими логическими выражениями,
использующими логические операции AND, OR и NOT.
Она берёт вложенный запрос как аргумент и оценивает его:
-как верный,   если тот производит любой вывод;
-как неверный, если тот не делает этого.

Этим она отличается от других проверок, где результат не может быть
неизвестным.

Простым примером применения EXISTS в секции SELECT может быть запрос,
проверяющий, есть ли среди абонентов хотя бы один с ФИО Иванов И.И.:
*/
SELECT EXISTS
(SELECT 1
FROM Abonent
WHERE Fio = 'Иванов И. И.');

/*
Данный запрос выдаст FALSE.
Полезным запросом является запрос сравнения наборов данных,
возвращаемых двумя запросами:
*/

SELECT CASE
           WHEN NOT EXISTS
               ((SELECT OVERLAY(phone PLACING '66' FROM 1)
                 FROM abonent)
                EXCEPT
                (SELECT SUBSTR(phone, 1, 0) || '66' || SUBSTR(phone, 3)
                 FROM abonent))
               THEN 'Наборы данных совпадают'
           ELSE 'Наборы данных не совпадают'
           END;

/*
В данном случае наборы данных являются идентичными.

Чаще всего EXISTS применяется в случаях, когда требуется найти
значения, соответствующие основному условию, заданному в секции WHERE,
и дополнительному условию, заключённому в подзапрос, являющийся
аргументом предиката. Как правило, подзапрос ссылается на другую
таблицу.

Существует возможность с помощью следующего запроса решить, извлекать
ли некоторые данные из таблицы Abonent, если хотя бы у одного из
абонентов имеются непогашенные заявки на ремонт газового оборудования:
*/

SELECT accountid, fio
FROM abonent
WHERE EXISTS
              (SELECT * FROM request WHERE executed IS FALSE);

--или

SELECT accountid, fio
FROM abonent
WHERE EXISTS (SELECT * FROM request WHERE executed = 'NO');

/*
В этих запросах независимый подзапрос выбирает все данные о непогашенных
ремонтных заявках. Предикат EXISTS в условии поиска внешнего запроса
«отмечает», что вложенным запросом был произведён некоторый вывод,
и поскольку предикат EXISTS был одним в условии поиска, делает условие
поиска основного запроса верным. Поскольку в таблице заявок имеются
(EXISTS) строки с Executed, принимающим значение FALSE, то в НД
представлены все строки таблицы Abonent.


На практике часто встречается необходимость выборки или выполнения
какого-либо действия в одной таблице в зависимости от факта возврата
строк подзапроса из другой таблицы.
Применение независимого скалярного подзапроса или подзапроса столбца
*/

SELECT accountid, fio
FROM abonent
WHERE EXISTS (SELECT 1 FROM request WHERE executed IS FALSE);

/*
Вместо табличного подзапроса и подсчёта числа строк,
возвращаемых подзапросом
*/

SELECT accountid, fio
FROM abonent
WHERE 0 < (SELECT COUNT(*)
           FROM request
           WHERE executed = FALSE);
/*позволяет существенно сократить объём выбираемых данных.*/


/*
Примером неправильного использования автономного подзапроса
с предикатом EXISTS может быть такой запрос:
*/

SELECT serviceid, servicenm
FROM services
WHERE EXISTS (SELECT 1
              FROM services
              WHERE servicenm = 'Водоснабжение');

/*
которым предполагается выбор всей информации об услуге «Водоснабжение».
Однако в результате выполнения запроса выводится информация обо всех
услугах.

В соотнесённом вложенном запросе предикат EXISTS оценивается отдельно
для каждой строки таблицы, имя которой указано во внешнем запросе,
т.е. алгоритм выполнения запроса с предикатом EXISTS и связанным
подзапросом точно такой же, как и для всех запросов с соотнесёнными
подзапросами в условии поиска (проверка существования или отсутствия
связанных строк).
Например, с помощью следующего запроса можно вывести
коды неисправностей, которые возникали у газового оборудования
нескольких абонентов:
*/

SELECT DISTINCT failureid
FROM request out
WHERE EXISTS (SELECT 1
              FROM request inn
              WHERE inn.failureid = out.failureid
                AND inn.accountid <> out.accountid)
ORDER BY failureid;

/*
Для каждой строки-кандидата внешнего запроса внутренний запрос
находит строки, совпадающие со значением в столбце Failureid
и соответствующие разным абонентам
(условие AND Inn.Accountid <> Out.Accountid).

Если любые такие строки найдены внутренним запросом, то это означает,
что имеются два разных абонента, газовое оборудование которых имело
текущую неисправность (неисправность в текущей строке-кандидате из
внешнего запроса).

Предикат EXISTS возвращает TRUE для текущей строки
(результат выполнения подзапроса является непустым множеством), и код
неисправности из таблицы, указанной во внешнем запросе,
будет выведен.

Если DISTINCT не указывать, то каждая из этих неисправностей будет
выбираться для каждого абонента, у которого она произошла (у некоторых
несколько раз).

Как предикат EXISTS можно использовать во всех случаях, когда
необходимо определить, имеется ли вывод из вложенного запроса. Поэтому
можно применять предикат EXISTS и в соединении таблиц.

Например, вывести все данные абонентов, имеющих заявки
с неисправностью с кодом 2, можно так:
*/

SELECT a.*
FROM abonent a
WHERE EXISTS
          (SELECT *
           FROM request r
           WHERE a.accountid = r.accountid
             AND r.failureid = 2);


/*
Здесь в подзапросе используется проверка условия.

С помощью следующего запроса можно вывести не только коды, но и названия
неисправностей, которые возникали у газового оборудования нескольких
абонентов:
*/


SELECT DISTINCT d.*
FROM disrepair d,
     request out
WHERE EXISTS (SELECT 1
              FROM request inn
              WHERE inn.failureid = out.failureid
                AND inn.accountid <> out.accountid)
  AND d.failureid = out.failureid
ORDER BY 1;

/*
В данном примере внешний запрос — это соединение таблицы Disrepair
с таблицей Request.

Использование NOT EXISTS указывает на инверсию результатов запроса.
Следующий запрос иллюстрирует принцип извлечения из одной таблицы
значений, которых нет в другой таблице (разность таблиц), с помощью
предиката EXISTS:
*/

SELECT s.streetid
FROM street s
WHERE NOT EXISTS (SELECT 1
                  FROM abonent a
                  WHERE s.streetid = a.streetid);

/*
Запрос возвращает данные об улицах, на которых не проживают абоненты.

Простая перестройка вышеприведённого запроса позволит извлечь улицы,
присутствующие и в таблице Street, и в таблице Abonent (пересечение
таблиц).

Следующие два запроса содержат EXISTS в секции HAVING. В первом из них
используется автономный подзапрос, а во втором — коррелированный.
*/

/*
Вывод данных абонентов, чьи суммарные платежи за газ превышают 2000,
при условии, что существует хотя бы одна заявка на ремонт, сделанная
в 2024 году (этот подзапрос автономный и не зависит от основного
запроса)
*/

SELECT a.accountid, a.fio, SUM(p.paysum) AS total_sum
FROM abonent a
         JOIN paysumma p USING (accountid)
WHERE p.serviceid = (SELECT serviceid
                     FROM services
                     WHERE servicenm = 'Газоснабжение')
GROUP BY a.accountid, a.fio
HAVING SUM(p.paysum) > 2000
   AND EXISTS (SELECT 1
               FROM request r
               WHERE EXTRACT(YEAR FROM r.incomingdate) = 2024)
ORDER BY a.fio;


/*
Таким образом, запрос с использованием EXISTS в секции HAVING позволяет
фильтровать группы данных, основываясь на существовании или отсутствии
связанных данных в другой таблице.
Это полезно, когда нужно комбинировать агрегатные функции с
логическими проверками наличия данных в других таблицах.

В выражениях операции CASE можно использовать подзапросы, что позволяет
получить информацию об особенной форме.

Например, следующий запрос со связанным подзапросом в секции SELECT
выводит для каждой улицы её идентификатор, если на ней проживает
хотя бы один абонент, и наименование улицы в противном случае:
*/


SELECT
    CASE
        WHEN EXISTS (SELECT 1 FROM Abonent A
                     WHERE A.Streetid = S.Streetid)
            THEN CAST(S.Streetid AS TEXT)
        ELSE S.Streetnm
        END AS "Улица"
FROM Street S
ORDER BY 1;

/*
Рассмотрим примеры применения предиката EXISTS в случае, когда
необходимо найти значения, соответствующие основному условию,
заданному в секции WHERE, и дополнительному условию,
заключённому в подзапрос, являющийся аргументом предиката.
Подобные запросы могут использоваться уже для анализа данных.


Пусть необходимо найти номер лицевого счёта абонентов,
которые подавали заявки на ремонт газового оборудования
с неисправностью «Течёт из водогрейной колонки» (код равен 3),
и которые при этом подавали более четырёх заявок.
Для решения такой задачи построим следующий запрос,
в котором первое условие задаётся предикатом EXISTS со вложенным
коррелированным запросом, а второе условие с секцией HAVING следует
после вложенного запроса:
*/

SELECT accountid
FROM request r
WHERE EXISTS (SELECT accountid
              FROM request
              WHERE failureid = 3
                AND accountid = r.accountid)
GROUP BY accountid
HAVING COUNT(requestid) > 4;

/*
Построим ещё один запрос, который выведет наименования неисправностей
газового оборудования, указанных в ремонтных заявках, поданных
абонентом с ФИО Аксенов С.А.
*/

SELECT failurenm
FROM disrepair d
WHERE EXISTS (SELECT 1
              FROM request r
              WHERE d.failureid = r.failureid
                AND r.accountid = (SELECT accountid
                                   FROM abonent
                                   WHERE fio = 'Аксенов С. А.'));


/*
Предикат EXISTS нельзя использовать в случае, если вложенный запрос
возвращает значение агрегатной функции.
Предикат EXISTS применяется также в запросах INSERT, UPDATE, DELETE
и условном операторе IF.


С помощью предиката NOT EXISTS можно реализовать стандартную операцию
реляционной алгебры — деление.

Пусть требуется найти абонентов, которые оплачивали все услуги.
Используя принцип построения запросов с двойным отрицанием,
можно преобразовать задание таким образом: отобрать абонентов из таблицы Paysumma (делимое),
для которых не существует тех услуг из таблицы Services (делитель),
для которых нет плат в таблице Paysumma для этого абонента и этой
услуги.

С использованием предиката проверки на существование это задание
реализуется следующим запросом:
*/

SELECT DISTINCT p.accountid
FROM paysumma p
WHERE NOT EXISTS
          (SELECT 1
           FROM services s
           WHERE NOT EXISTS
                     (SELECT 1
                      FROM paysumma p1
                      WHERE p1.accountid = p.accountid
                        AND p1.serviceid = s.serviceid))
ORDER BY p.accountid;

/*
Решение данной задачи, основанное на группировке по номеру лицевого
счёта абонента с подсчётом уникальных кодов оплаченных им услуг и
отборе только тех абонентов, у которых это количество равно общему
числу услуг:
*/

SELECT accountid
FROM paysumma
GROUP BY accountid
HAVING COUNT(DISTINCT serviceid) = (SELECT COUNT(serviceid)
                                    FROM services)
ORDER BY accountid;


/*
Для получения такого же результата можно отобрать абонентов, для
которых разность между таблицами Services и Paysumma не содержит строк:
*/

SELECT DISTINCT p.accountid
FROM paysumma p
WHERE serviceid = ALL (SELECT serviceid
                       FROM services s
                       WHERE serviceid NOT IN (SELECT serviceid
                                               FROM paysumma p1
                                               WHERE p1.accountid = p.accountid
                                                 AND p1.serviceid = s.serviceid))
ORDER BY accountid;


/*
Полу-соединение таблиц в SQL можно также реализовать
с помощью подзапроса или оператора EXISTS.
Например, вывести абонентов, имеющих заявки
с неисправностью с идентификатором 2:
*/

SELECT DISTINCT a.*---r.*
FROM abonent a
---left join request r on a.accountid = r.accountid
WHERE EXISTS (SELECT 1
              FROM request r
              WHERE a.accountid = r.accountid
                AND r.failureid = 2);

/*
Список выбора содержит столбцы только из таблицы Abonent.
Это и есть характерная особенность операции полу-соединения.
Подзапрос внутри условия WHERE проверяет наличие строк в таблице
Request, где AccountID совпадает с AccountID из Abonent и R.Failureid
равно 2. Если подзапрос возвращает хотя бы одну строку, то условие
EXISTS будет истинным, и соответствующая строка из Abonent будет
включена в результирующий набор.

Операция полу-соединения обычно применяется в распределённой обработке
запросов, чтобы сократить объём передаваемых данных.

Таким образом, предикат EXISTS является мощным инструментом
для проверки существования данных, позволяя создавать эффективные
и производительные запросы для сложных условий фильтрации.
Он особенно полезен в ситуациях, когда необходимо проверить наличие
или отсутствие связанных строк в других таблицах!!!

В заключение рассмотрения вложенных запросов необходимо
дополнительно обратить внимание на особенности применения
количественных предикатов и предиката существования при наличии
отсутствующих данных.

Так как при обработке в следующих запросах (вывести всю информацию
об абонентах, число символов в ФИО которых меньше числа символов
в ФИО любого абонента, проживающего на улице с номером 3),
отсутствуют NULL, то оба эти запроса вернут одинаковые результаты.

*/


SELECT *
FROM abonent
WHERE LENGTH(fio) < ANY (SELECT LENGTH(fio)
                         FROM abonent
                         WHERE streetid = 3);

SELECT *
FROM abonent a
WHERE NOT EXISTS (SELECT 1
                  FROM abonent d
                  WHERE LENGTH(a.fio) >= LENGTH(d.fio)
                    AND streetid = 3);

/*
При наличии NULL, как при обработке в двух других запросах,
получаются разные результаты.
*/

SELECT *
FROM abonent
WHERE phone < ANY (SELECT phone
                   FROM abonent
                   WHERE accountid = '005488');

SELECT *
FROM abonent a
WHERE NOT EXISTS (SELECT 1
                  FROM abonent d
                  WHERE a.phone >= d.phone
                    AND accountid = '005488');

/*
Это является следствием того, что EXISTS всегда принимает значения
TRUE или FALSE и никогда UNKNOWN.

В запросе с ANY во внешнем запросе, когда выбирается столбец
Phone с NULL, предикат принимает значение UNKNOWN и строка,
так же, как и в случае, когда результатом сравнения будет FALSE,
не включается в выборку. Во втором же варианте запроса, когда во
внешнем запросе выбирается строка с NULL в столбце Phone,
предикат, используемый в подзапросе, имеет значение UNKNOWN.
Поэтому при выполнении подзапроса не будет получено ни одной строки,
в результате чего оператор NOT EXISTS примет значение TRUE,
и, следовательно, данная строка с NULL попадает в выборку внешнего
запроса.

Таким образом, при отсутствии NULL предикат EXISTS может быть
использован вместо ANY и ALL.

Также вместо COUNT(*) в секции SELECT могут быть использованы те же
самые подзапросы с использованием EXISTS и NOT EXISTS:
*/

SELECT *
FROM abonent a
WHERE 1 > (SELECT COUNT(*)
           FROM abonent d
           WHERE LENGTH(a.fio) >= LENGTH(d.fio)
             AND accountid = '005488');

SELECT *
FROM abonent a
WHERE NOT EXISTS (SELECT fio
                  FROM abonent d
                  WHERE LENGTH(a.fio) >= LENGTH(d.fio)
                    AND accountid = '005488');

/*
Выбор между независимыми и зависимыми подзапросами зависит от задачи,
которую требуется решить, и от данных, с которыми придётся работать.
Вот основные различия и сценарии использования для каждого типа
подзапросов.


Независимые подзапросы выполняются один раз и не зависят от
внешнего запроса. Они могут быть использованы в качестве источника
данных, для сравнения или в качестве аргумента функции во внешнем
запросе.

Сценарии использования:
1.получение фиксированного набора данных, когда нужно получить
конкретный набор данных, который не зависит от каждой строки
внешнего запроса. Например, выборка всех абонентов, чья сумма
платежей ниже средней по компании;

2.использование в качестве статического значения, например, когда
нужно сравнить значение в каждой строке основного запроса с
результатом подзапроса, который возвращает единственное значение
(например, среднее или максимальное значение);

3.независимые подзапросы могут быть использованы в FROM-секции
в качестве источника данных для создания временной таблицы,
которая затем используется в основном запросе.

*/

---2
SELECT accountid, MAX(paysum) AS max_pay
FROM paysumma
GROUP BY accountid
HAVING MAX(paysum) > (SELECT AVG(paysum) FROM paysumma);
--                    ↑ независимый подзапрос (одно число)


---3
SELECT serviceid, total
FROM (SELECT serviceid, SUM(paysum) AS total
      FROM paysumma
      GROUP BY serviceid) AS subquery   -- ↑ независимый подзапрос
WHERE total > 10000;

/*
Коррелированные подзапросы выполняются повторно для каждой строки
внешнего запроса, и результат подзапроса может различаться в зависимости
от текущей строки внешнего запроса. Они используют значения из внешнего
запроса для выполнения своих условий.

Сценарии использования:
1.проверка условий для каждой строки: когда нужно проверить условие
для каждой строки основного запроса, используя данные из другой
таблицы.
Например, выборка абонентов, для которых сумма платежей
меньше, чем было начислено;

2.возвращение значения, зависящего от каждой строки: когда нужно
вернуть значение для каждой строки основного запроса, которое
зависит от какого-то условия в другой таблице. Например, выборка
имени сотрудника и имени его непосредственного руководителя, где
руководитель определяется для каждого сотрудника индивидуально;

3.коррелированные подзапросы часто используются с EXISTS, IN, ANY, ALL
для проверки наличия, соответствия или сравнения значений в зависимости
от каждой строки основного запроса.


Общие выводы:

коррелированные подзапросы могут существенно снизить
производительность!!!!
Особенно на больших объёмах данных, поскольку
они выполняются многократно.
Всегда стоит искать возможности
оптимизации, например, использование соединений вместо
коррелированных подзапросов, если это возможно!!!;

иногда коррелированные подзапросы могут сделать SQL-запрос сложным
для понимания и поддержки. Важно стремиться к написанию чистого,
хорошо комментированного кода, особенно при использовании сложных
подзапросов!!!

Окончательный выбор между независимыми и коррелированными подзапросами
зависит от конкретной задачи и требований к производительности.
В некоторых случаях можно использовать оба подхода для достижения
одного и того же результата, но с различиями в эффективности
и читаемости кода.
*/


/*
Составные запросы и операции над множествами результатов.
Рекурсивные и коррелированные подзапросы в секции WITH
Составные запросы и операции над множествами результатов

Ранее рассмотренные SQL-запросы формировали один результирующий набор
строк. Даже при соединении нескольких таблиц результат представлял
собой единое множество.
Однако в некоторых задачах требуется объединить результаты нескольких
отдельных запросов SELECT в один итоговый набор.

Для таких случаев в SQL предусмотрены операции над множествами
результатов запросов.
Каждый запрос SELECT возвращает множество строк, и SQL предоставляет
возможность объединять эти множества с помощью следующих операций:

UNION — объединение с удалением дубликатов;
UNION ALL — объединение с сохранением дубликатов;
INTERSECT — пересечение;
EXCEPT — разность.

Запрос, содержащий такие операции, называется составным, а каждый
отдельный запрос внутри него — составляющим!!!

Иногда составные запросы называют вертикальными объединениями,
поскольку они формируют результат за счёт последовательного добавления
строк, а не расширения столбцов, как это происходит при обычных JOIN.

Общий синтаксис составного запроса может быть представлен в следующем
виде:


SELECT ...
Операция_1
SELECT ...
[Операция_2
SELECT ...
...];

Операции с наборами данных UNION, EXCEPT и INTERSECT выполняются
сверху вниз (слева направо), но INTERSECT имеет более высокий
приоритет, чем UNION и EXCEPT. При необходимости изменить порядок
выполнения операций можно, используя скобки.

Чтобы выполнить составной запрос, все составляющие SELECT запросы
должны быть согласованы по структуре:

1.одинаковое число столбцов в каждом SELECT;
2.совместимость типов данных по соответствующим позициям;
3.имена столбцов в результирующем наборе определяются по первому
SELECT;
4.секция ORDER BY может быть указана только в последнем запросе
(или после всего составного выражения);
5.точка с запятой «;» ставится только после последнего SELECT.
Её отсутствие в промежуточных запросах означает продолжение
выражения.

В PostgreSQL столбцы в соответствующих позициях могут иметь разные
типы, но эти типы должны быть совместимы. Если требуется дать
псевдоним столбцам, то следует делать это для списка столбцов в самом
верхнем запросе. Псевдонимы в других участвующих в операции выборках
разрешены и могут быть даже полезными, но они не будут распространяться
на уровне операции!!!

Таким образом, составные запросы позволяют эффективно объединять,
пересекать и фильтровать результаты нескольких SELECT-операций,
расширяя возможности обработки данных в SQL,
и в PostgreSQL в частности.


Объединение
Объединение — это операция SQL, используемая для объединения
результирующих наборов двух или более запросов SELECT в единый
результирующий набор. При получении данных из таблиц БД необходимость
в объединении результатов двух или более запросов в одну таблицу
реализуется с помощью оператора UNION. UNION — это оператор,
осуществляющий операцию объединения. Он объединяет вывод двух или
более запросов в единый набор строк и столбцов и имеет вид:

Запрос X
UNION [ALL]
Запрос Y
[UNION [ALL]]
Запрос Z...;

Объединение таблиц с помощью оператора UNION отличается от вложенных
запросов и соединений таблиц тем, что в нём ни один из двух (или
больше) запросов не управляет другим запросом.
Все запросы выполняются
независимо друг от друга, а уже их вывод объединяется.

Например, необходимо вывести ФИО абонентов и исполнителей ремонтных
заявок, фамилии которых начинаются на букву «Ш». Для этого можно
использовать запрос:

Следует отметить,
что результат запроса в PostgreSQL упорядочен по ФИО.
*/

SELECT Fio AS "ФИО"
FROM Abonent
WHERE Fio LIKE 'Ш%'
UNION
SELECT Fio
FROM Executor
WHERE Fio LIKE 'Ш%';

/*
Чтобы включить все строки в вывод запроса, следует указать UNION ALL
или в список выборки SELECT добавить дополнительный столбец с
константой.

Если бы, например, существовал не только исполнитель с ФИО
Школьников С.М., но и абонент с такими же ФИО, и вместо UNION
использовался UNION ALL, то строка с ФИО Школьников С.М. была бы
выведена дважды.

Добавление в список выборки столбца с константой, кроме того,
позволяет различать строки результата:
*/

SELECT fio AS "ФИО", 'Абонент' AS "Кто"
FROM abonent
WHERE fio LIKE '%'
UNION
SELECT fio, 'Слесарь'
FROM executor
WHERE fio LIKE '%';

/*
Если требуется вывести одним запросом больше столбцов, чем другим,
то можно создавать дополнительные столбцы искусственно, например
*/

SELECT fio AS "ФИО", 'Абонент' AS "Кто", phone
FROM abonent
WHERE fio LIKE '%'
UNION
SELECT fio, 'Слесарь', NULL
FROM executor
WHERE fio LIKE '%';

----ИЛИ ТАК:

SELECT CASE
           WHEN phone IS NULL THEN fio || ' - абонент, нет телефона'
           ELSE fio || ' - абонент, телефон: ' || phone
           END AS "ФИО, кто, телефон"
FROM abonent
WHERE fio LIKE '%'
UNION
SELECT fio || ' - слесарь'
FROM executor
WHERE fio LIKE '%';

/*
Операторы UNION и UNION ALL могут быть скомбинированы,
чтобы удалять одни дубликаты, не удаляя других.
Объединение запросов

(Запрос X
UNION ALL
Запрос Y)
UNION
Запрос Z;

не обязательно даст те же результаты,
что и объединение запросов

Запрос X
UNION ALL
(Запрос Y
UNION
Запрос Z);

так как дублирующиеся строки удаляются при использовании
UNION без ALL.

Результаты выполнения промежуточных запросов, участвующих в объединении,
упорядочивать запрещено, однако результирующий набор можно
отсортировать, указывая порядковые номера возвращаемых элементов.
Например, объединить в одну таблицу информацию об услугах и
неисправностях газового оборудования, а результат отсортировать по
значениям второго выводимого столбца в обратном алфавитном порядке
можно с помощью запроса
*/


SELECT failureid, failurenm
FROM disrepair
UNION ALL
SELECT serviceid, servicenm
FROM services
ORDER BY 2 DESC;

SELECT *
FROM disrepair
UNION ALL
SELECT *
FROM services
ORDER BY 2 DESC;

/*
В объединяемых запросах можно использовать одну и ту же таблицу.

Пусть, например, требуется вывести первые 10 значений начислений
за 2025 г., уменьшенные на 5%,
если значение меньше 560, на 10%,
если значение от 600 до 900, и уменьшенные на 20%, если значение
больше 900.
Вывести также процент уменьшения, код начисления, прежнее
и новое значения начислений.
Запрос будет выглядеть так:

*/

SELECT accountid,
       ' 5%'             AS "Снижение",
       nachislfactid,
       nachislsum        AS "Old_Sum",
       nachislsum * 0.95 AS "New_Sum"
FROM nachislsumma
WHERE nachislsum < 560
  AND nachislyear = 2025
UNION
SELECT accountid,
       ' 10%',
       nachislfactid,
       nachislsum,
       nachislsum * 0.90
FROM nachislsumma
WHERE (nachislsum BETWEEN 600 AND 900)
  AND nachislyear = 2025
UNION
SELECT accountid,
       ' 20%',
       nachislfactid,
       nachislsum,
       nachislsum * 0.80
FROM nachislsumma
WHERE nachislsum > 900
  AND nachislyear = 2025
ORDER BY 1, 2
    FETCH NEXT 10 ROWS ONLY;


/*
При использовании объединения запросов с одной и той же таблицей
в PostgreSQL в некоторых случаях полезно проанализировать возможность
решить задачу с помощью функций секции GROUP BY.

Например, пусть требуется вывести средние значения плат по услугам
и абонентам и средние значения плат по услугам.
Эта задача может быть решена двумя способами: с помощью объединения
запросов оператором UNION и с использованием функции ROLLUP.
*/

/*
Запрос с объединением UNION:
*/


SELECT Serviceid, NULL AS Accountid, ROUND(AVG(Paysum), 2)
FROM Paysumma
GROUP BY Serviceid
UNION
SELECT Serviceid, Accountid, ROUND(AVG(Paysum), 2)
FROM Paysumma
GROUP BY Serviceid, Accountid
UNION
SELECT NULL, NULL, ROUND(AVG(Paysum), 2)
FROM Paysumma
ORDER BY 1, 2;

/*
Используя функцию ROLLUP или GROUPING SETS (см. лекц. 3.5), можно
значительно короче написать аналогичный запрос:
*/


SELECT Serviceid, Accountid, ROUND(AVG(Paysum), 2)
FROM Paysumma
GROUP BY ROLLUP (Serviceid, Accountid)
ORDER BY 1, 2;

--или

SELECT Serviceid, Accountid, ROUND(AVG(Paysum), 2)
FROM Paysumma
GROUP BY GROUPING SETS ((Serviceid, Accountid), (Serviceid), ())
ORDER BY 1, 2;

/*
В данных запросах столбцы с функцией GROUPING позволяют определить
строки итогов (это может потребоваться для обработки значений NULL
в основных столбцах итоговых строк). В отличие от предыдущего запроса
с UNION, запросы с ROLLUP или GROUPING SETS выведут дополнительно
строку общего итога — среднее значение оплат по таблице Paysumma.
*/

/*315*/


