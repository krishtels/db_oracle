CREATE TABLE student.GROUPS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL UNIQUE,
    c_val INTEGER,
    constraint PK_GROUP primary key(id)
);


CREATE TABLE student.STUDENTS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    group_id INTEGER,
    constraint PK_STUDENT primary key(id),
     constraint FK_STUDENT_GROUP foreign key (GROUP_ID)
      references student.GROUPS (id) ON DELETE CASCADE
);


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


INSERT INTO student.GROUPS(name, c_val) VALUES ('one', 10);
INSERT INTO student.GROUPS(name, c_val) VALUES ('two', 12);
INSERT INTO student.GROUPS(name, c_val) VALUES ('three', 11);

INSERT INTO student.GROUPS(name, c_val) VALUES ('one', 11);

SELECT * FROM student.GROUPS;

INSERT INTO student.STUDENTS (name, group_id) VALUES ('Katya', 3);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Lesha', 2);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Nastya', 1);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Dasha', 3);
INSERT INTO student.STUDENTS (name, group_id) VALUES ('Nikita', 2);

SELECT * FROM student.STUDENTS;
