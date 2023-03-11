--TASK 1

CREATE TABLE student.GROUPS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    c_val INTEGER
);


CREATE TABLE student.STUDENTS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    group_id INTEGER
);

--TASK 2

CREATE SEQUENCE students_seq
START WITH 1 
INCREMENT BY 1 
NOMAXVALUE;

CREATE OR REPLACE TRIGGER trigger_id_student before INSERT ON student.STUDENTS FOR each row
BEGIN
  SELECT students_seq.NEXTVAL
  INTO :new.id
  FROM DUAL;
END;


CREATE SEQUENCE groups_seq
START WITH 1 
INCREMENT BY 1 
NOMAXVALUE;

CREATE OR REPLACE TRIGGER trigger_id_groups before INSERT ON student.GROUPS FOR each row
BEGIN
  SELECT groups_seq.NEXTVAL
  INTO :new.id
  FROM DUAL;
END;


CREATE OR REPLACE TRIGGER check_group_name
BEFORE UPDATE OR INSERT
ON student.GROUPS FOR EACH ROW
DECLARE
id_ NUMBER;
existing_name EXCEPTION;
BEGIN
   if :NEW.name <> :OLD.name THEN
        SELECT student.GROUPS.id INTO id_ FROM student.GROUPS WHERE student.GROUPS.name=:NEW.name;
        dbms_output.put_line('This name already exists'||:NEW.name);
        raise existing_name;
  END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('successfully inserted!');
END;


CREATE OR REPLACE TRIGGER check_group_id
BEFORE UPDATE OR INSERT
ON student.GROUPS FOR EACH ROW
FOLLOWS CHECK_GROUP_NAME
DECLARE
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
    if :NEW.name <> :OLD.name THEN
        SELECT student.GROUPS.id INTO id_ FROM student.GROUPS WHERE student.GROUPS.id=:NEW.id;
               dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('successfully inserted!');
END;

CREATE OR REPLACE TRIGGER check_student_id
BEFORE INSERT
ON student.students FOR EACH ROW
DECLARE
id_ NUMBER;
existing_id EXCEPTION;
BEGIN
    SELECT student.students.id INTO id_ FROM student.students WHERE student.students.id=:NEW.id;
        dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('successfully inserted!');
END;


INSERT INTO student.GROUPS(name, c_val) VALUES('053501', 0);
INSERT INTO student.GROUPS(name, c_val) VALUES('053502', 0);
INSERT INTO student.GROUPS(name, c_val) VALUES('053503', 0);
INSERT INTO student.GROUPS(name, c_val) VALUES('053504', 0);
INSERT INTO student.GROUPS(name, c_val) VALUES('053505', 0);

SELECT * FROM student.GROUPS;

INSERT INTO student.GROUPS(name, c_val) VALUES('053505', 0);

INSERT INTO student.STUDENTS (name, group_id) VALUES ('Katya', 3);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Lesha', 2);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Nastya', 1);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Dasha', 3);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Nikita', 2);

SELECT * FROM student.STUDENTS;

--TASK 3
CREATE OR REPLACE TRIGGER fk_student_group
AFTER DELETE ON student.students FOR EACH ROW
DECLARE
   PRAGMA AUTONOMOUS_TRANSACTION;
   students_amount_in_group NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'ALTER TRIGGER fk_group_student DISABLE';
    EXECUTE IMMEDIATE 'SELECT student.groups.c_val FROM groups WHERE id='||:OLD.group_id INTO students_amount_in_group;
        dbms_output.put_line(students_amount_in_group);
    EXECUTE IMMEDIATE 'ALTER TRIGGER fk_student_group DISABLE';
END;

CREATE OR REPLACE TRIGGER fk_group_student
AFTER DELETE ON student.groups FOR EACH ROW
DECLARE
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  EXECUTE IMMEDIATE 'ALTER TRIGGER fk_student_group DISABLE';
    EXECUTE IMMEDIATE 'DELETE FROM student.students WHERE students.group_id='||:OLD.id;
     EXECUTE IMMEDIATE 'ALTER TRIGGER fk_student_group ENABLE';
END;

select * from student.groups;
select * from student.students;
DELETE FROM student.groups WHERE id=2;

DELETE FROM student.students WHERE id=1;


--TASK 4
CREATE TABLE student.LOGGING_ACTIONS
(
    id NUMBER PRIMARY KEY,
    operation VARCHAR2(10) NOT NULL,
    date_exec TIMESTAMP NOT NULL,
    new_student_id NUMBER,
    new_student_name VARCHAR2(100),
    new_studenr_group_id NUMBER,
    old_student_id NUMBER,
    old_student_name VARCHAR2(100),
    old_studenr_group_id NUMBER
);


CREATE OR replace trigger stud_logger 
AFTER INSERT OR UPDATE OR DELETE 
ON student.STUDENTS FOR EACH ROW
DECLARE
    TEMP_ID NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM student.LOGGING_ACTIONS' INTO TEMP_ID;
    CASE
    WHEN INSERTING THEN
        INSERT INTO student.LOGGING_ACTIONS VALUES(TEMP_ID+1, 'INSERT', SYSTIMESTAMP, :new.id, :new.name, :new.group_id, NULL, NULL, NULL);
    WHEN UPDATING THEN
        INSERT INTO student.LOGGING_ACTIONS VALUES(TEMP_ID+1, 'UPDATE', SYSTIMESTAMP, :new.id, :new.name, :new.group_id, :old.id, :old.name, :old.group_id);

    WHEN DELETING THEN
        INSERT INTO student.LOGGING_ACTIONS VALUES(TEMP_ID+1, 'DELETE', SYSTIMESTAMP, NULL, NULL, NULL, :old.id, :old.name, :old.group_id);
    END CASE;
END;


INSERT INTO student.STUDENTS (name, group_id) VALUES ('Dima', 4);
INSERT INTO student.students (name, group_id) VALUES('Roman', 4);
UPDATE student.students SET student.students.group_id=5 WHERE students.id=7;
DELETE FROM student.students WHERE student.students.id=7;

select * from student.LOGGING_ACTIONS;


--TASK 5
CREATE OR REPLACE PROCEDURE restore_students(time_back TIMESTAMP) IS
BEGIN
    FOR action IN (SELECT * FROM student.LOGGING_ACTIONS WHERE time_back < date_exec ORDER BY id DESC)
    LOOP
        IF action.operation = 'INSERT' THEN
            DELETE student.students WHERE id = action.new_student_id;
        END IF;
        
        IF action.operation = 'UPDATE' THEN
            UPDATE student.students SET
            id = action.old_student_id,
            name = action.old_student_name,
            group_id = action.old_studenr_group_id
            WHERE id = action.new_student_id;
        END IF;
        
        IF action.operation = 'DELETE' THEN
            INSERT INTO student.students VALUES (action.old_student_id, action.old_student_name, action.old_studenr_group_id);
        END IF;
    END LOOP;
END;

SELECT * FROM student.GROUPS;
SELECT * FROM student.STUDENTS;

INSERT INTO student.students(name, group_id) values('Vanya', 4);
UPDATE student.students SET student.students.group_id=5 WHERE students.id=3;
SELECT * FROM student.LOGGING_ACTIONS;

DELETE FROM student.students WHERE name='Vanya';
EXEC restore_students(TO_TIMESTAMP('19-Feb-02 01.19.05.0000000 PM'));
EXEC restore_students(TO_TIMESTAMP(CURRENT_TIMESTAMP - 45));
EXEC restore_students(TO_TIMESTAMP(CURRENT_TIMESTAMP + numToDSInterval( 1, 'second' )));


--TASK 6
CREATE OR REPLACE TRIGGER c_val_update
    AFTER INSERT OR UPDATE OR DELETE
    ON student.students
    for each row
BEGIN
    IF INSERTING THEN
        UPDATE student.groups
        SET C_VAL = C_VAL + 1
        WHERE id = :new.group_id;
    END IF;
    IF UPDATING THEN
        UPDATE student.groups
        SET C_VAL = C_VAL - 1
        WHERE id = :old.group_id;
        
        UPDATE student.groups
        SET C_VAL = C_VAL + 1
        WHERE id = :new.group_id;
    END IF;
    IF DELETING THEN
        UPDATE student.groups
        SET C_VAL = C_VAL - 1
        WHERE id = :old.group_id;
    END IF;
END;

INSERT INTO student.students(name, group_id) values('001', 4);
INSERT INTO student.students(name, group_id) values('002', 5);
INSERT INTO student.students(name, group_id) values('003', 5);
INSERT INTO student.students(name, group_id) values('004', 6);

UPDATE student.STUDENTS SET group_id=6 where id=36;
DELETE FROM student.STUDENTS WHERE id=37;

SELECT * FROM student.GROUPS;
SELECT * FROM student.STUDENTS;

INSERT into student.groups(name, c_val) VALUES ('053505', 0);

DELETE FROM student.GROUPS WHERE id = 4;

SELECT * FROM student.LOGGING_ACTIONS;
EXEC restore_students(TO_TIMESTAMP('20-Feb-23 01.19.05.0000000 PM'));
INSERT INTO student.students(name, group_id) values('005', 6);