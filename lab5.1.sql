CREATE TABLE DEV.TABLE1(
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    TESTCOLUMN VARCHAR(20)
);
DROP TABLE DEV.TABLE3;
DROP TABLE DEV.TABLE3_AUDIT;
DROP TABLE DEV.TABLE3_LOGGING_ACTIONS;
CREATE TABLE DEV.TABLE2 (
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    TESTCOLUMN DATE
);

CREATE TABLE DEV.TABLE3 (
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    TESTCOLUMN NUMBER,
    TABLE2_ID NUMBER,
    CONSTRAINT TABLE3_TABLE2_FK FOREIGN KEY(TABLE2_ID) REFERENCES DEV.TABLE2(ID) ON DELETE CASCADE
);

CREATE TABLE DEV.TABLE1_LOGGING_ACTIONS (
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    OPERATION VARCHAR2(10) NOT NULL,
    DATE_EXEC TIMESTAMP NOT NULL,
    IS_REVERTED NUMBER NOT NULL,
    NEW_ID NUMBER,
    NEW_TESTCOLUMN VARCHAR(20),
    OLD_ID NUMBER,
    OLD_TESTCOLUMN VARCHAR(20)
);


CREATE TABLE DEV.TABLE2_LOGGING_ACTIONS (
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    OPERATION VARCHAR2(10) NOT NULL,
    DATE_EXEC TIMESTAMP NOT NULL,
    IS_REVERTED NUMBER NOT NULL,
    NEW_ID NUMBER,
    NEW_TESTCOLUMN DATE,
    OLD_ID NUMBER,
    OLD_TESTCOLUMN DATE
);

CREATE TABLE DEV.TABLE3_LOGGING_ACTIONS (
    ID NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    OPERATION VARCHAR2(10) NOT NULL,
    DATE_EXEC TIMESTAMP NOT NULL,
    IS_REVERTED NUMBER NOT NULL,
    NEW_ID NUMBER,
    NEW_TESTCOLUMN NUMBER,
    NEW_FK_ID NUMBER,
    OLD_ID NUMBER,
    OLD_TESTCOLUMN NUMBER,
    OLD_FK_ID NUMBER
);



CREATE OR replace trigger TABLE3_LOG_TRIGGER 
BEFORE INSERT OR UPDATE OR DELETE 
ON DEV.TABLE3 FOR EACH ROW
DECLARE
BEGIN
     CASE
        WHEN INSERTING THEN
            INSERT INTO DEV.TABLE3_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN,
                NEW_FK_ID,
                OLD_FK_ID
            ) VALUES(
                'INSERT',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                NULL,
                NULL,
                :NEW.TABLE2_ID,
                NULL
            );
        WHEN DELETING THEN
            INSERT INTO DEV.TABLE3_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN,
                OLD_FK_ID,
                NEW_FK_ID
            ) VALUES(
                'DELETE',
                SYSTIMESTAMP,
                0,
                NULL,
                NULL,
                :OLD.ID,
                :OLD.TESTCOLUMN,
                :OLD.TABLE2_ID,
                NULL
            );
        WHEN UPDATING THEN
            INSERT INTO DEV.TABLE3_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN,
                NEW_FK_ID,
                OLD_FK_ID
            ) VALUES (
                'UPDATE',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                :OLD.ID,
                :OLD.TESTCOLUMN,
                :NEW.TABLE2_ID,
                :OLD.TABLE2_ID
                
            );
    END CASE;
END;


CREATE OR replace trigger TABLE1_LOG_TRIGGER 
BEFORE INSERT OR UPDATE OR DELETE 
ON DEV.TABLE1 FOR EACH ROW
DECLARE
BEGIN
     CASE
        WHEN INSERTING THEN
            INSERT INTO DEV.TABLE1_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES(
                'INSERT',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                NULL,
                NULL
            );
        WHEN DELETING THEN
            INSERT INTO DEV.TABLE1_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES(
                'DELETE',
                SYSTIMESTAMP,
                0,
                NULL,
                NULL,
                :OLD.ID,
                :OLD.TESTCOLUMN
            );
        WHEN UPDATING THEN
            INSERT INTO DEV.TABLE1_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES (
                'UPDATE',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                :OLD.ID,
                :OLD.TESTCOLUMN
                
            );
    END CASE;
END;

CREATE OR replace trigger TABLE2_LOG_TRIGGER 
BEFORE INSERT OR UPDATE OR DELETE 
ON DEV.TABLE2 FOR EACH ROW
DECLARE
BEGIN
     CASE
        WHEN INSERTING THEN
            INSERT INTO DEV.TABLE2_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES(
                'INSERT',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                NULL,
                NULL
            );
        WHEN DELETING THEN
            INSERT INTO DEV.TABLE2_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES(
                'DELETE',
                SYSTIMESTAMP,
                0,
                NULL,
                NULL,
                :OLD.ID,
                :OLD.TESTCOLUMN
            );
        WHEN UPDATING THEN
            INSERT INTO DEV.TABLE2_LOGGING_ACTIONS (
                OPERATION,
                DATE_EXEC,
                IS_REVERTED,
                NEW_ID,
                NEW_TESTCOLUMN,
                OLD_ID,
                OLD_TESTCOLUMN
            ) VALUES (
                'UPDATE',
                SYSTIMESTAMP,
                0,
                :NEW.ID,
                :NEW.TESTCOLUMN,
                :OLD.ID,
                :OLD.TESTCOLUMN
                
            );
    END CASE;
END;


CREATE OR REPLACE TYPE STRING_ARRAY IS VARRAY( 3 ) OF VARCHAR2( 10 );

CREATE OR REPLACE FUNCTION GET_DEPENDENT_TABLES( IN_TABLE_NAME IN VARCHAR2 ) 
RETURN STRING_ARRAY
IS 
    DEPENDENT_TABLES STRING_ARRAY := STRING_ARRAY( );
    INDX NUMBER := 0;

BEGIN
    FOR RELATION IN (
        SELECT
            P.TABLE_NAME,
            CH.TABLE_NAME CHILD
        FROM
            ALL_CONS_COLUMNS P
        JOIN ALL_CONSTRAINTS CH
            ON P.CONSTRAINT_NAME = CH.R_CONSTRAINT_NAME
        WHERE
            P.TABLE_NAME = IN_TABLE_NAME and p.OWNER='DEV'
    
     ) LOOP
        DEPENDENT_TABLES.EXTEND;
        INDX := INDX + 1;
        DEPENDENT_TABLES(INDX) := RELATION.CHILD;
    END LOOP;
    RETURN DEPENDENT_TABLES;
END;


CREATE OR REPLACE PROCEDURE RESTORE_TABLE1( RESTORE_UNTIL TIMESTAMP ) IS
BEGIN
    FOR action IN (SELECT * FROM DEV.TABLE1_LOGGING_ACTIONS WHERE RESTORE_UNTIL <= DATE_EXEC AND IS_REVERTED = 0 ORDER BY ID DESC)
    LOOP
        IF action.operation = 'INSERT' THEN
            DELETE DEV.TABLE1 WHERE id = action.new_id;
        END IF;
        
        IF action.operation = 'UPDATE' THEN
            UPDATE DEV.TABLE1 SET
            TABLE1.id = action.old_id,
            TABLE1.TESTCOLUMN = action.OLD_TESTCOLUMN
            WHERE TABLE1.id = action.new_id;
        END IF;
        
        IF action.operation = 'DELETE' THEN
            INSERT INTO DEV.TABLE1 VALUES (action.old_id, action.OLD_TESTCOLUMN);
        END IF;
    END LOOP;
    UPDATE DEV.TABLE1_LOGGING_ACTIONS
    SET
        IS_REVERTED = 1
    WHERE
        DATE_EXEC > RESTORE_UNTIL;
END;

CREATE OR REPLACE PROCEDURE RESTORE_TABLE2( RESTORE_UNTIL TIMESTAMP ) IS
BEGIN
    RESTORE_CHILD('TABLE2', RESTORE_UNTIL);
    FOR action IN (SELECT * FROM DEV.TABLE2_LOGGING_ACTIONS WHERE RESTORE_UNTIL <= DATE_EXEC AND IS_REVERTED = 0 ORDER BY ID DESC)
    LOOP
        IF action.operation = 'INSERT' THEN
            DELETE DEV.TABLE2 WHERE id = action.new_id;
        END IF;
        
        IF action.operation = 'UPDATE' THEN
            UPDATE DEV.TABLE2 SET
            id = action.old_id,
            TESTCOLUMN = action.OLD_TESTCOLUMN
            WHERE id = action.new_id;
        END IF;
        
        IF action.operation = 'DELETE' THEN
            INSERT INTO DEV.TABLE2 VALUES (action.old_id, action.OLD_TESTCOLUMN);
        END IF;
    END LOOP;
    UPDATE DEV.TABLE2_LOGGING_ACTIONS
    SET
        IS_REVERTED = 1
    WHERE
        DATE_EXEC > RESTORE_UNTIL;
END;

CREATE OR REPLACE PROCEDURE RESTORE_TABLE3( RESTORE_UNTIL TIMESTAMP ) IS
BEGIN
    FOR action IN (SELECT * FROM DEV.TABLE3_LOGGING_ACTIONS WHERE RESTORE_UNTIL <= DATE_EXEC AND IS_REVERTED = 0 ORDER BY ID DESC)
    LOOP
        IF action.operation = 'INSERT' THEN
            DELETE DEV.TABLE3 WHERE id = action.new_id;
        END IF;
        
        IF action.operation = 'UPDATE' THEN
            UPDATE DEV.TABLE3 SET
            id = action.old_id,
            TESTCOLUMN = action.OLD_TESTCOLUMN,
            TABLE2_ID = action.OLD_FK_ID
            WHERE id = action.new_id;
        END IF;
        
        IF action.operation = 'DELETE' THEN
            INSERT INTO DEV.TABLE3 VALUES (action.old_id, action.OLD_TESTCOLUMN, ACTION.OLD_FK_ID);
        END IF;
    END LOOP;
    UPDATE DEV.TABLE3_LOGGING_ACTIONS
    SET
        IS_REVERTED = 1
    WHERE
        DATE_EXEC > RESTORE_UNTIL;
END;




CREATE OR REPLACE PROCEDURE RESTORE_DATA(INPUT_TABLES IN STRING_ARRAY, INPUT_TS IN TIMESTAMP ) IS

BEGIN
    FOR I IN 1..INPUT_TABLES.COUNT LOOP
        EXECUTE IMMEDIATE '
        BEGIN
            RESTORE_'
            || INPUT_TABLES(I)
            || '(TO_TIMESTAMP('''
            || TO_CHAR(INPUT_TS, 'DD-MM-YYYY HH:MI:SS')
            || ''', ''DD-MM-YYYYHH:MI:SS''));
        END;
        ';
    END LOOP;
END;


CREATE OR REPLACE PROCEDURE RESTORE_DATA1(INPUT_TABLES IN STRING_ARRAY, INPUT_TS IN NUMBER ) IS
TS VARCHAR2(1000);
BEGIN
    FOR I IN 1..INPUT_TABLES.COUNT LOOP
        EXECUTE IMMEDIATE '
        BEGIN
            RESTORE_'
            || INPUT_TABLES(I)
            || '(TO_TIMESTAMP('''
            || TO_CHAR(CURRENT_TIMESTAMP - INPUT_TS, 'DD-MM-YYYY HH:MI:SS')
            || ''', ''DD-MM-YYYYHH:MI:SS''));
        END;
        ';
    END LOOP;

END;


CREATE OR REPLACE PROCEDURE RESTORE_CHILD ( TABLE_NAME IN VARCHAR2, RESTORE_UNTIL TIMESTAMP ) IS CHILD_ARRAY STRING_ARRAY;
BEGIN
    CHILD_ARRAY := GET_DEPENDENT_TABLES(TABLE_NAME);
    RESTORE_DATA(CHILD_ARRAY, RESTORE_UNTIL);
END;

INSERT INTO DEV.TABLE1(TESTCOLUMN) VALUES ('TEST5');
INSERT INTO DEV.TABLE2(TESTCOLUMN) VALUES(CURRENT_DATE);
INSERT INTO DEV.TABLE3(TESTCOLUMN, TABLE2_ID) VALUES (1, 2);
UPDATE DEV.TABLE1 SET TESTCOLUMN = 'TESTED2';

SELECT * FROM DEV.TABLE1;
SELECT * FROM DEV.TABLE2;
SELECT * FROM DEV.TABLE3;

SELECT * FROM DEV.TABLE1_LOGGING_ACTIONS;
SELECT * FROM DEV.TABLE2_LOGGING_ACTIONS;
SELECT * FROM DEV.TABLE3_LOGGING_ACTIONS;

TRUNCATE TABLE DEV.TABLE1;
TRUNCATE TABLE DEV.TABLE2;
TRUNCATE TABLE DEV.TABLE3;
TRUNCATE TABLE DEV.TABLE1_LOGGING_ACTIONS;
TRUNCATE TABLE DEV.TABLE2_LOGGING_ACTIONS;
TRUNCATE TABLE DEV.TABLE3_LOGGING_ACTIONS;

UPDATE DEV.TABLE1_AUDIT SET IS_REVERTED = 0;

DECLARE
    TABLES STRING_ARRAY := STRING_ARRAY('TABLE1', 'TABLE2', 'TABLE3');
BEGIN
    RESTORE_DATA(TABLES, '30-MAR-23 9.15.00.000000000 PM');
END;

DECLARE
    TABLES STRING_ARRAY := STRING_ARRAY('TABLE1');
BEGIN
    RESTORE_DATA1(TABLES, 10);
END;

CREATE OR REPLACE DIRECTORY my_dir AS 'D:\labs\db_oracle';


CREATE OR REPLACE NONEDITIONABLE PACKAGE "REPORTS" as
  procedure get_report(TS in timestamp);
  procedure get_report;
end;

CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY "REPORTS" as
last_date TIMESTAMP := SYSTIMESTAMP;  
PROCEDURE GET_REPORT(TS IN TIMESTAMP)
IS 
    l_clob VARCHAR2(32767);
    file_id UTL_FILE.file_type;
begin
      l_clob := '
        <html>
            <head>
                <style>
                table, th, td {
                    border: 1px solid black;
                    border-collapse: collapse;
                }
                table.center {
                    margin-left: auto;
                    margin-right: auto;
                }
                </style>
            </head>
            <body>
            <h1 style="text-align: center"> Operation list since' || TS ||'</h1> <table style="width:100%" class="center"> ';
            
            l_clob := l_clob || '
            <h1 align="center"> TABLE1 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE1_LOGGING_ACTIONS where DATE_EXEC >  TS and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';
        

            l_clob := l_clob || '
            <h1 align="center"> TABLE2 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE2_LOGGING_ACTIONS where DATE_EXEC >  TS and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';


            l_clob := l_clob || '
            <h1 align="center"> TABLE3 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE3_LOGGING_ACTIONS where DATE_EXEC >  TS and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';

    l_clob := l_clob || '</body></html>';
    file_id := UTL_FILE.FOPEN ('MY_DIR', 'feedback.html', 'W');
    UTL_FILE.PUT_LINE(file_id,l_clob);
    UTL_FILE.fclose (file_id);
end;
 

PROCEDURE GET_REPORT
IS 
    l_clob VARCHAR2(32767);
    file_id UTL_FILE.file_type;
begin
      l_clob := '
        <html>
            <head>
                <style>
                table, th, td {
                    border: 1px solid black;
                    border-collapse: collapse;
                }
                table.center {
                    margin-left: auto;
                    margin-right: auto;
                }
                </style>
            </head>
            <body>
            <h1 style="text-align: center"> Operation list since' || last_date ||'</h1> <table style="width:100%" class="center"> ';
            
            l_clob := l_clob || '
            <h1 align="center"> TABLE1 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE1_LOGGING_ACTIONS where DATE_EXEC >  last_date and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';
        

            l_clob := l_clob || '
            <h1 align="center"> TABLE2 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE2_LOGGING_ACTIONS where DATE_EXEC >  last_date and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';


            l_clob := l_clob || '
            <h1 align="center"> TABLE3 INFO</h1> 
            <table> 
            <tr align="center">
                <th align="center">OPERATION</th>
                <th align="center">RECORDED ON </th>
            </tr>';
            for l_rec in (select * from DEV.TABLE3_LOGGING_ACTIONS where DATE_EXEC >  last_date and IS_REVERTED = 0) loop
                    l_clob := l_clob || 
                    '<tr align="center"> <td align="left">'|| 
                    l_rec.operation ||'</td> <td align="center">' 
                    ||l_rec.DATE_EXEC || '</td> </tr>';
            end loop;
            l_clob := l_clob || '</table>';

    l_clob := l_clob || '</body></html>';
    file_id := UTL_FILE.FOPEN ('MY_DIR', 'feedback.html', 'W');
    UTL_FILE.PUT_LINE(file_id,l_clob);
    UTL_FILE.fclose (file_id);
    last_date := SYSTIMESTAMP; 
end;
end;


BEGIN
    REPORTS.GET_REPORT('30-MAR-23 3.15.00.000000000 PM');
END;

BEGIN
    REPORTS.GET_REPORT();
END;
