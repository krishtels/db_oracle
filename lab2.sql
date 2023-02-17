CREATE TABLE student.GROUPS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    c_val NUMBER,
    constraint PK_GROUP primary key(id)
);

CREATE TABLE student.STUDENTS
(
    id INTEGER NOT NULL,
    name VARCHAR2(100) NOT NULL,
    GROUP_ID INTEGER,
    constraint PK_STUDENT primary key(id),
     constraint FK_STUDENT_GROUP foreign key (GROUP_ID)
      references student.GROUPS (id) ON DELETE CASCADE
);