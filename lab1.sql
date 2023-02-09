CREATE USER student IDENTIFIED BY password;
GRANT UNLIMITED TABLESPACE TO student

CREATE TABLE student.My_table (
    id INTEGER NOT NULL,   
    val INTEGER NOT NULL,
    constraint PK_MYTABLE primary key (id)
)

CREATE TABLE student.My_table_without_triggeer (
    id INTEGER NOT NULL,   
    val INTEGER NOT NULL,
    constraint PK_MYTABLE_WITHOUT_TG primary key (id)
)

CREATE SEQUENCE sq_my_table
START WITH 1 
INCREMENT BY 1 
NOMAXVALUE;

CREATE OR REPLACE TRIGGER trigger_my_table before INSERT ON student.My_table FOR each row
BEGIN
  SELECT sq_my_table.NEXTVAL
  INTO :new.id
  FROM DUAL;
END;



DECLARE
    v NUMBER;
BEGIN
    FOR i IN 1..10000
    LOOP
       v := DBMS_RANDOM.RANDOM();
    INSERT INTO 
        student.My_table(val)
    VALUES
        (v);
    END LOOP;
END;

SELECT COUNT(*) FROM student.My_table



CREATE OR REPLACE Function IfEven RETURN VARCHAR2
IS
    CURSOR even_cur IS
      SELECT count(*) FROM student.My_table
       WHERE mod(student.My_table.val, 2) = 0;
    CURSOR odd_cur IS
      SELECT count(*) FROM student.My_table
       WHERE mod(student.My_table.val, 2) = 1;
    even NUMBER;
    odd NUMBER;
    result VARCHAR2(5);
BEGIN
    OPEN even_cur;
    FETCH even_cur INTO even;
    CLOSE even_cur;
    OPEN odd_cur;
    FETCH odd_cur INTO odd;
    CLOSE odd_cur;
    IF even = odd THEN
      result := 'EQUAL';
    ELSE
      IF even > odd THEN
        result := 'TRUE';
      ELSE
        result := 'FALSE';
      END IF;
    END IF;
    RETURN result;
END;

SELECT IfEven() FROM dual;
SELECT COUNT(*) FROM student.MY_TABLE
WHERE mod(student.My_table.val, 2) = 0;



CREATE OR REPLACE Function GetInsertComBy(id INTEGER)
   RETURN VARCHAR2
IS
BEGIN
    return 'INSERT INTO student.My_table_without_triggeer(id, val) VALUES (' || id || ', ' || DBMS_RANDOM.RANDOM() || ')';
END;

DECLARE
BEGIN
   EXECUTE IMMEDIATE GetInsertComBy(15);
END;

SELECT * FROM student.My_table_without_triggeer;


CREATE OR REPLACE Procedure InsertById(id_u INTEGER, val_u INTEGER)
IS
BEGIN
    INSERT INTO 
        student.My_table_without_triggeer(id, val) 
    VALUES 
        ( id_u, val_u);
END;

CREATE OR REPLACE Procedure UpdateById(id_u INTEGER, val_u INTEGER)
IS
BEGIN
    UPDATE
        student.MY_TABLE
    SET
        MY_TABLE.val = val_u
    WHERE 
      MY_TABLE.id = id_u;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No such number');
END;


CREATE OR REPLACE Procedure DeleteById(id_u INTEGER)
IS
BEGIN
    DELETE
        student.MY_TABLE
    WHERE MY_TABLE.id = id_u;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No such number');
END;


SELECT * FROM student.My_table_without_triggeer;

EXECUTE InsertById(2, 15);

SELECT * FROM student.My_table
WHERE id >=1 and id <=10;

EXECUTE UpdateById(2, 10);

EXECUTE DeleteById(2);
