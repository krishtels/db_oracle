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
        SELECT student.GROUPS.id INTO id_ FROM student.GROUPS WHERE student.GROUPS.name=:NEW.name;
        dbms_output.put_line('This name already exists'||:NEW.name);
        raise existing_name;
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
        SELECT student.GROUPS.id INTO id_ FROM student.GROUPS WHERE student.GROUPS.id=:NEW.id;
               dbms_output.put_line('An id already exists'||:NEW.id);
        raise existing_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('successfully inserted!');
END;

CREATE OR REPLACE TRIGGER check_student_id
BEFORE UPDATE OR INSERT
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
