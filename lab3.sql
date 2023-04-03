-- create users
DROP USER dev;
DROP PROCEDURE dev.remove_products;
DROP TABLE dev.PRODUCTS;
DROP TABLE dev.users;
DROP TABLE dev.examples;

DROP USER prod;
DROP PROCEDURE prod.remove_products;
DROP TABLE prod.PRODUCTS;
DROP TABLE prod.users;
DROP TABLE prod.examples;


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

CREATE TABLE dev.examples ( 
    ex_id NUMBER(10) not null, 
    
    CONSTRAINT ex_pk PRIMARY KEY (ex_id),
    CONSTRAINT fk_ex FOREIGN KEY (ex_id) REFERENCES dev.examples(ex_id)
);



CREATE OR REPLACE PROCEDURE dev.remove_products (product_id NUMBER) AS
   BEGIN
      DELETE FROM dev.PRODUCTS
      WHERE  dev.PRODUCTS.PRODUCT_ID = product_id;
   END;


CREATE OR REPLACE PROCEDURE prod.remove_dhd (product_id NUMBER) AS
   BEGIN
      DELETE FROM prod.PRODUCTS
      WHERE  prod.PRODUCTS.PRODUCT_ID = product_id;
   END;


-- create prod schema
CREATE TABLE prod.products( 
    product_id NUMBER not null, 
    product_name VARCHAR2(50) not null,
	category VARCHAR2(50),
    CONSTRAINT products_pk PRIMARY KEY (product_id)
);
drop index dev.prod_produts_name;

CREATE INDEX dev.prod_produts_name 
ON dev.products(product_name);

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

begin
COMPARE_SCHEMES_TABLES('PROD', 'DEV'); 
end;


-- Task 3
SELECT * FROM ALL_SOURCE WHERE OWNER = 'DEV';

CREATE OR REPLACE PROCEDURE REPLACE_OBJECT (schema1 IN VARCHAR2, schema2 IN VARCHAR2, object_type IN VARCHAR2, object_name IN VARCHAR2) 
AS
query_string VARCHAR2(4000); 
BEGIN
    query_string := '';
    FOR src IN (SELECT line, text FROM ALL_SOURCE WHERE OWNER = schema1 AND NAME = object_name) LOOP
        IF src.line =1 THEN
            query_string := 'CREATE OR REPLACE ' || REPLACE(src.text, LOWER(object_name), schema2 || '.' || object_name);
        ELSE
            query_string := query_string || src.text; END IF;
    END LOOP;
    IF LENGTH( query_string ) > 0 THEN
        EXECUTE IMMEDIATE query_string; 
        dbms_output.put_line(query_string);
    END IF;
END REPLACE_OBJECT;


CREATE OR REPLACE PROCEDURE CREATE_OBJECT (schema1 IN VARCHAR2, schema2 IN VARCHAR2, object_type IN VARCHAR2, object_name IN VARCHAR2) 
AS
query_string VARCHAR2(4000); 
BEGIN
    query_string := '';
    FOR src IN (SELECT line, text FROM ALL_SOURCE WHERE OWNER = schema1 AND NAME = object_name) LOOP
        IF src.line =1 THEN
            query_string := 'CREATE ' || REPLACE(src.text, LOWER(object_name), schema2 || '.' || object_name);
        ELSE
            query_string := query_string || src.text; 
        END IF;
    END LOOP;
    IF LENGTH( query_string ) > 0 THEN
        EXECUTE IMMEDIATE query_string; 
        dbms_output.put_line(query_string);
    END IF;
END CREATE_OBJECT;


CREATE OR REPLACE PROCEDURE DELETE_OBJECT (schema1 IN VARCHAR2, object_type IN VARCHAR2, object_name IN VARCHAR2)
AS
delete_query VARCHAR(1000); 
BEGIN
    delete_query := '';
    delete_query := 'DROP ' || object_type || ' ' || schema1 || '.' || object_name; 
    IF LENGTH( delete_query ) > 0 THEN
        EXECUTE IMMEDIATE delete_query;
        dbms_output.put_line(delete_query); 
    END IF;

END DELETE_OBJECT;



CREATE OR REPLACE PROCEDURE COMPARE_OBJECTS (schema1 IN VARCHAR2, schema2 IN VARCHAR2, object_type IN VARCHAR2) AS
diff NUMBER :=0; 
query_string VARCHAR(32767); 
BEGIN
    FOR pair IN (SELECT obj1.NAME AS name1, obj2.NAME AS name2 FROM
        (SELECT OBJECT_NAME name FROM ALL_OBJECTS WHERE OBJECT_TYPE = object_type AND OWNER = schema1) obj1 
        FULL JOIN
        (SELECT OBJECT_NAME name FROM ALL_OBJECTS WHERE OBJECT_TYPE = object_type AND OWNER = schema2) obj2 
        ON obj1.name = obj2.name) 
    LOOP
        IF object_type = 'PROCEDURE' THEN
            IF pair.name1 IS NULL THEN
                DELETE_OBJECT(schema2,object_type, pair.name2); 
                dbms_output.put_line('D');
            ELSIF pair.name2 IS NULL THEN
                CREATE_OBJECT(schema1, schema2, object_type, pair.name1); 
                dbms_output.put_line('C');
            ELSE
                SELECT COUNT(*) INTO diff FROM all_source src1 
                FULL JOIN all_source src2 
                ON src1.name = src2.name
                WHERE src1.name= pair.name1 AND src1.line = src2.line AND src1.text != src2.text
                AND src1.OWNER = schema1 AND src2.OWNER = schema2;
                IF diff > 0 THEN 
                    REPLACE_OBJECT(schema1,schema2,object_type,pair.name1); 
                    dbms_output.put_line('R');
                END IF; 
            END IF;
        ELSIF object_type = 'TABLE' THEN
            IF pair.name1 IS NULL THEN
                query_string := 'DROP TABLE ' || schema2 || '.' || pair.name2;
                EXECUTE IMMEDIATE query_string;
                dbms_output.put_line(query_string); 
                dbms_output.put_line('D');
            ELSIF pair.name2 IS NULL THEN
                query_string := REPLACE (DBMS_LOB.SUBSTR (DBMS_METADATA.get_ddl ('TABLE', pair.name1, schema1)), schema1, schema2);
                EXECUTE IMMEDIATE query_string; 
                dbms_output.put_line(query_string);
                dbms_output.put_line('C');
            END IF; 

        END IF;
    END LOOP;
    IF object_type = 'TABLE' THEN 
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
            query_string := 'DROP TABLE ' || schema2 || '.' || same_table.table_name;
            EXECUTE IMMEDIATE query_string; 
            dbms_output.put_line(query_string);
            query_string := REPLACE (DBMS_LOB.SUBSTR (DBMS_METADATA.get_ddl ('TABLE', same_table.table_name, schema1)), schema1, schema2);
            EXECUTE IMMEDIATE query_string; 
            dbms_output.put_line(query_string);
        END IF;
        END LOOP;
    END IF;
END COMPARE_OBJECTS;


begin
COMPARE_SCHEMES('DEV', 'PROD'); 
COMPARE_SCHEMES_TABLES('DEV', 'PROD'); 
end;

EXEC COMPARE_OBJECTS('DEV', 'PROD', 'PROCEDURE');
EXEC COMPARE_OBJECTS('DEV', 'PROD', 'TABLE');



