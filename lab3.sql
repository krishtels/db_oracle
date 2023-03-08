-- create users
CREATE USER dev IDENTIFIED BY password;
CREATE USER prod IDENTIFIED BY password;
GRANT ALL PRIVILEGES TO dev;
GRANT ALL PRIVILEGES TO prod;

-- create dev schema
CREATE TABLE dev.products( 
    product_id NUMBER not null, 
    product_name VARCHAR2(50) not null,
--	category varchar2(50),
    CONSTRAINT products_pk PRIMARY KEY (product_id)
);

CREATE TABLE dev.users( 
    user_id NUMBER(10) not null, 
    user_name VARCHAR2(50) not null,
    CONSTRAINT user_pk PRIMARY KEY (user_id)
);


-- create prod schema
CREATE TABLE prod.products( 
    product_id NUMBER not null, 
    product_name VARCHAR2(50) not null,
	category VARCHAR2(50),
    CONSTRAINT products_pk PRIMARY KEY (product_id)
);

SET SERVEROUTPUT ON;


CREATE OR REPLACE PROCEDURE compare_schemes(schema1 in VARCHAR2, schema2 in VARCHAR2) as
diff NUMBER := 0;
BEGIN
-- DIFFERENCE IN COLUMNS
    dbms_output.put_line('Comparing 2 schemes, printing difference in tables structure');
    FOR same_table IN 
    (SELECT table_name FROM all_tables tables1 WHERE OWNER = schema1
    INTERSECT
    SELECT tables2.table_name FROM all_tables tables2 WHERE OWNER = schema2) LOOP
        SELECT COUNT(*) INTO diff FROM
        (SELECT table1.COLUMN_NAME name, table1.DATA_TYPE FROM all_tab_columns table1 WHERE OWNER=schema1 
        AND TABLE_NAME = same_table.table_name) cols1
        FULL JOIN
        (SELECT table2.COLUMN_NAME name, table2.DATA_TYPE FROM all_tab_columns table2 WHERE OWNER=schema2 
        AND TABLE_NAME = same_table.table_name) cols2
        ON cols1.name = cols2.name
        WHERE cols1.name IS NULL OR cols2.name IS NULL;

    IF diff > 0 THEN
    dbms_output.put_line('Table structure of ' || same_table.table_name || ' is different in ' || schema1 || ' and ' || schema2);
    ELSE
    dbms_output.put_line('Table structure of ' || same_table.table_name || ' the same'); END IF;
    END LOOP;
END compare_schemes;


CREATE OR REPLACE PROCEDURE compare_schemes_tables (schema1 in VARCHAR2, schema2 in VARCHAR2) AS 
BEGIN
-- DIFFERENCE IN TABLES
    dbms_output.put_line('Comparing 2 schemes, printing difference in tables');
    FOR other_table IN (SELECT tables1.table_name name FROM all_tables tables1 WHERE tables1.OWNER = schema1
    MINUS
    SELECT tables2.table_name FROM all_tables tables2 WHERE tables2.OWNER=schema2) LOOP
        dbms_output.put_line('Table ' || other_table.name || ' is in ' || schema1 || ' but not in ' || schema2);
    END LOOP;

    FOR other_table IN (SELECT tables2.table_name name FROM all_tables tables2 WHERE tables2.OWNER=schema2
    MINUS
    SELECT tables1.table_name FROM all_tables tables1 WHERE tables1.OWNER = schema1) LOOP
        dbms_output.put_line('Table ' || other_table.name || ' is in ' || schema2 || ' but not in ' || schema1);
    END LOOP;
end compare_schemes_tables;


DROP TABLE fk_tmp; 
CREATE TABLE fk_tmp(
    id NUMBER,
    child_obj VARCHAR2(100), 
    parent_obj VARCHAR2(100)
);


CREATE OR REPLACE PROCEDURE scheme_tables_order(schema_name in VARCHAR2) AS 
BEGIN
-- DIFFERENCE IN TABLES ORDER
    EXECUTE IMMEDIATE 'TRUNCATE TABLE fk_tmp';
    dbms_output.put_line('Showing tables order in schema');
 
    FOR schema_table IN (SELECT tables1.table_name name FROM all_tables tables1 WHERE OWNER = schema_name) LOOP
        INSERT INTO fk_tmp (CHILD_OBJ, PARENT_OBJ)
            SELECT DISTINCT a.table_name, c_pk.table_name r_table_name FROM all_cons_columns a
            JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
            JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
        WHERE c.constraint_type = 'R' AND a.table_name = schema_table.name;

    IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line(schema_table.name); 
    END IF;
    END LOOP;

    FOR fk_cur IN (
        SELECT child_obj, parent_obj, CONNECT_BY_ISCYCLE FROM fk_tmp
        CONNECT BY NOCYCLE PRIOR parent_obj = child_obj ORDER BY LEVEL
    ) LOOP
        IF fk_cur.CONNECT_BY_ISCYCLE = 0 THEN
            dbms_output.put_line(fk_cur.child_obj); 
        ELSE
            dbms_output.put_line('CYCLE IN TABLE' || fk_cur.child_obj); 
        END IF;
    END LOOP;
END scheme_tables_order;


begin
    COMPARE_SCHEMES('DEV', 'PROD'); 
    COMPARE_SCHEMES_TABLES('DEV', 'PROD'); 
    SCHEME_TABLES_ORDER('DEV'); 
    SCHEME_TABLES_ORDER('PROD');
end;


-- Task 2

SELECT * FROM ALL_OBJECTS WHERE OBJECT_TYPE = 'TABLE' AND OWNER = 'DEV';
 


CREATE OR REPLACE PROCEDURE compare_schemes(schema1 in VARCHAR2, schema2 in VARCHAR2)
AS
diff NUMBER := 0;
type objarray IS VARRAY(4) OF VARCHAR2(10); 
objects_arr objarray; 
total integer; 
BEGIN
-- DIFFERENCE IN COLUMNS
    objects_arr := OBJARRAY('PROCEDURE', 'PACKAGE', 'INDEX', 'TABLE');
    total := objects_arr.count;
    dbms_output.put_line('Comparing 2 schemes, printing difference in tables');

    FOR i IN 1 .. total LOOP
        FOR same_object IN (
        SELECT objects1.object_name FROM ALL_OBJECTS objects1 WHERE OWNER = schema1 AND OBJECT_TYPE = objects_arr(i)
        INTERSECT
        SELECT objects2.object_name FROM ALL_OBJECTS objects2 WHERE OWNER = schema2 AND OBJECT_TYPE = objects_arr(i)) LOOP
            SELECT COUNT(*) INTO diff FROM
            (SELECT table1.COLUMN_NAME name, table1.DATA_TYPE FROM all_tab_columns table1 WHERE OWNER=schema1 AND TABLE_NAME= same_object.object_name) cols1
            FULL JOIN
            (SELECT table2.COLUMN_NAME name, table2.DATA_TYPE FROM all_tab_columns table2 WHERE OWNER=schema2 AND TABLE_NAME = same_object.object_name) cols2
            ON cols1.name = cols2.name
            WHERE cols1.name IS NULL OR cols2.name IS NULL;


    IF diff > 0 THEN
    dbms_output.put_line(objects_arr(i) || ' structure of ' || same_object.object_name || ' is different in ' || schema1 || ' and ' || schema2);
    ELSE
    dbms_output.put_line(objects_arr(i) || ' structure of ' || same_object.object_name || ' the same'); END IF;
    END LOOP;
    END LOOP;
end compare_schemes;


CREATE OR REPLACE PROCEDURE compare_schemes_tables (schema1 in VARCHAR2, schema2 in VARCHAR2) AS 
type objarray IS VARRAY(4) OF VARCHAR2(10); 
objects_arr objarray; 
total integer; 
BEGIN
    objects_arr := OBJARRAY('PROCEDURE', 'PACKAGE', 'INDEX', 'TABLE');
    total := objects_arr.count;

    dbms_output.put_line('Comparing 2 schemes, printing difference in tables, procedures, indexes, packets');
    FOR i IN 1 .. total LOOP
    FOR other_table IN (SELECT objects1.object_name name FROM ALL_OBJECTS objects1 WHERE OWNER = schema1 AND OBJECT_TYPE = objects_arr(i)
    MINUS
    SELECT objects2.object_name FROM ALL_OBJECTS objects2 WHERE OWNER = schema2 AND OBJECT_TYPE = objects_arr(i)) LOOP
        dbms_output.put_line(objects_arr(i) || ' ' || other_table.name || ' is in ' || schema1 || ' but not in ' || schema2);
    END LOOP;
    END LOOP;

    FOR i IN 1 .. total LOOP
    FOR other_table IN (select objects2.object_name name FROM ALL_OBJECTS objects2 WHERE OWNER = schema2 AND OBJECT_TYPE = objects_arr(i)
    MINUS
    SELECT objects1.object_name FROM ALL_OBJECTS objects1 WHERE OWNER = schema1 AND OBJECT_TYPE = objects_arr(i)) LOOP
        dbms_output.put_line(objects_arr(i) || ' ' || other_table.name || ' is in ' || schema2 || ' but not in ' || schema1);
    END LOOP;
    END LOOP;
end compare_schemes_tables;
 

begin
COMPARE_SCHEMES('DEV', 'PROD'); 
COMPARE_SCHEMES_TABLES('DEV', 'PROD'); 
SCHEME_TABLES_ORDER('DEV'); 
SCHEME_TABLES_ORDER('PROD');
end;

