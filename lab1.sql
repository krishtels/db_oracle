CREATE USER student IDENTIFIED BY password;
GRANT UNLIMITED TABLESPACE TO student

CREATE TABLE student.My_table (
    id INTEGER NOT NULL,   
    val INTEGER NOT NULL,
    constraint PK_MYTABLE primary key (id)
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

select IfEven() from dual;
select COUNT(*) from student.MY_TABLE
where mod(student.My_table.val, 2) = 0;