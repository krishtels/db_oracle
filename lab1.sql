create table MyTable (
   id NUMBER NOT NULL,
   val NUMBER NOT NULL,
   constraint PK_MYTABLE primary key (id)
)

DECLARE
    v NUMBER;
BEGIN
    FOR i IN 1..10001
    LOOP
       v := DBMS_RANDOM.RANDOM();
    INSERT INTO 
        MyTable(id,val)
    VALUES
        (i,v);
    END LOOP;
END;

SELECT COUNT(*) FROM MyTable