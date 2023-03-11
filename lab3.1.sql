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

CREATE OR REPLACE PROCEDURE COMPARE_SCHEMA(dev_schema_name VARCHAR2, prod_schema_name VARCHAR2)
IS
    counter NUMBER;
    counter2 NUMBER;
    text VARCHAR2(100);
BEGIN
-- dev tables to create or add columns in prod
FOR res IN (Select  DISTINCT table_name from all_tab_columns where owner = dev_schema_name  and (table_name, column_name) not in
        (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
    LOOP
        counter := 0;
        SELECT COUNT(*) INTO counter FROM all_tables where owner = prod_schema_name and table_name = res.table_name;
        IF counter > 0 THEN
            FOR res2 IN (Select  DISTINCT column_name,data_type from all_tab_columns where owner = dev_schema_name and table_name = res.table_name  and (table_name, column_name) not in
                        (select table_name, column_name from all_tab_columns where owner = prod_schema_name))
                        LOOP
                            DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || prod_schema_name || '.' || res.table_name || ' ADD ' || res2.column_name || ' ' || res2.data_type || ';');
                        END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || prod_schema_name || '.' || res.table_name || ' AS (SELECT * FROM '  || dev_schema_name || '.' || res.table_name || ');');
        END IF;
    END LOOP;
    
-- prod tables to delete or drop columns
FOR res IN (Select  DISTINCT table_name from all_tab_columns where owner = prod_schema_name  and (table_name, column_name) not in
        (select table_name, column_name from all_tab_columns where owner = dev_schema_name))
    LOOP
        counter := 0;
        counter2 :=0;
        SELECT COUNT(column_name) INTO counter FROM all_tab_columns where owner = prod_schema_name and table_name = res.table_name;
        SELECT COUNT(column_name) INTO counter2 FROM all_tab_columns where owner = dev_schema_name and table_name = res.table_name;
        IF counter != counter2 THEN
            FOR res2 IN (select column_name from all_tab_columns where owner = prod_schema_name and table_name = res.table_name and 
                            column_name not in (select column_name from all_tab_columns where owner = dev_schema_name and table_name = res.table_name))
                        LOOP
                            DBMS_OUTPUT.PUT_LINE('ALTER TABLE '|| prod_schema_name || '.' || res.table_name || ' DROP COLUMN ' || res2.column_name || ';');
                        END LOOP;
        ELSE
            DBMS_OUTPUT.PUT_LINE('DROP TABLE ' || prod_schema_name || '.' || res.table_name || ' CASCADE CONSTRAINTS;');
        END IF;
    END LOOP;
    
-- dev procedure to create in prod
FOR res IN (select DISTINCT object_name from all_objects where object_type='PROCEDURE' and owner=dev_schema_name  and object_name not in
        (select object_name from all_objects where owner = prod_schema_name and object_type='PROCEDURE'))
    LOOP
        counter := 0;   
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (select text from all_source where type='PROCEDURE' and name=res.object_name and owner=dev_schema_name)
            LOOP
                IF COUNTER != 0 THEN
                    DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
                ELSE
                   DBMS_OUTPUT.PUT_LINE(rtrim(prod_schema_name || '.' || res2.text,chr (10) || chr (13)));
                   counter := 1;
                END IF;
            END LOOP;
    END LOOP;   

-- prod procedures to delete
FOR res IN (select DISTINCT object_name from all_objects where object_type='PROCEDURE' and owner=prod_schema_name and object_name not in
        (select object_name from all_objects where owner = dev_schema_name and object_type='PROCEDURE'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP PROCEDURE ' || prod_schema_name || '.' || res.object_name);
    END LOOP;   

--dev functions to create in prod
FOR res IN (select DISTINCT object_name from all_objects where object_type='FUNCTION' and owner=dev_schema_name  and object_name not in
        (select object_name from all_objects where owner = prod_schema_name and object_type='FUNCTION'))
    LOOP
        counter := 0;   
        DBMS_OUTPUT.PUT_LINE('CREATE OR REPLACE ');
        FOR res2 IN (select text from all_source where type='FUNCTION' and name=res.object_name and owner=dev_schema_name)
            LOOP
                IF COUNTER != 0 THEN
                    DBMS_OUTPUT.PUT_LINE(rtrim(res2.text,chr (10) || chr (13)));
                ELSE
                   DBMS_OUTPUT.PUT_LINE(rtrim(prod_schema_name || '.' || res2.text,chr (10) || chr (13)));
                   counter := 1;
                END IF;
            END LOOP;
    END LOOP; 

--prod functions to delete
FOR res IN (select DISTINCT object_name from all_objects where object_type='FUNCTION' and owner=prod_schema_name and object_name not in
        (select object_name from all_objects where owner = dev_schema_name and object_type='FUNCTION'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP FUNCTION ' || prod_schema_name || '.' || res.object_name);
    END LOOP;  
    
--dev indexes to create in prod
FOR res IN (select  index_name, index_type, table_name from all_indexes where table_owner=dev_schema_name and index_name not like '%_PK' and index_name not in
        (select index_name from all_indexes where table_owner=prod_schema_name and index_name not like '%_PK'))
    LOOP
        select column_name INTO text from ALL_IND_COLUMNS where index_name=res.index_name and table_owner=dev_schema_name;
        DBMS_OUTPUT.PUT_LINE('CREATE ' || res.index_type || ' INDEX ' || res.index_name || ' ON ' || prod_schema_name || '.' || res.table_name || '(' || text || ');');
    END LOOP;

--delete indexes drop prod
FOR res IN (select  index_name from all_indexes where table_owner= prod_schema_name  and index_name not like '%_PK' and index_name not in
        (select index_name from all_indexes where table_owner=dev_schema_name and index_name not like '%_PK'))
    LOOP
        DBMS_OUTPUT.PUT_LINE('DROP INDEX ' || res.index_name || ';');
    END LOOP;

END;


create or replace procedure SCHEME_TABLES_ORDER(schema_name in varchar2) as
begin
    -- DIFFERENCE IN TABLES
    EXECUTE IMMEDIATE 'TRUNCATE TABLE fk_tmp';
    dbms_output.put_line('Showing tables order in schema');
    
    FOR schema_table IN (SELECT tables1.table_name name FROM
    all_tables tables1 WHERE OWNER = schema_name) LOOP
    
        INSERT INTO fk_tmp (CHILD_OBJ, PARENT_OBJ)
        SELECT DISTINCT a.table_name, c_pk.table_name r_table_name
        FROM all_cons_columns a
        JOIN all_constraints c ON a.owner = c.owner AND a.constraint_name = c.constraint_name
        JOIN all_constraints c_pk ON c.r_owner = c_pk.owner AND c.r_constraint_name = c_pk.constraint_name
        WHERE c.constraint_type = 'R' AND a.table_name = schema_table.name;
        
        IF SQL%ROWCOUNT = 0 THEN
        dbms_output.put_line( schema_table.name);
        END IF;
        
    END LOOP;
    
    FOR fk_cur IN (
        SELECT CHILD_OBJ,PARENT_obj,CONNECT_BY_ISCYCLE
        FROM fk_tmp
        CONNECT BY NOCYCLE PRIOR PARENT_OBJ = child_obj
        ORDER BY LEVEL
    ) LOOP
    IF fk_cur.CONNECT_BY_ISCYCLE = 0 THEN
        dbms_output.put_line(fk_cur.CHILD_OBJ);
    ELSE
        dbms_output.put_line('CYCLE IN TABLE' || fk_cur.CHILD_OBJ);
    END IF;
    END LOOP;
end SCHEME_TABLES_ORDER;


BEGIN
    COMPARE_SCHEMA('DEV','PROD');
    SCHEME_TABLES_ORDER('DEV');
END;
