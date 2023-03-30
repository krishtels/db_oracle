CREATE TYPE XML_RECORD AS TABLE OF VARCHAR2(1000);

CREATE OR REPLACE FUNCTION CONCAT_STRING(CONCAT_DATA IN XML_RECORD, SEPARATOR IN VARCHAR2) RETURN VARCHAR2
    IS
        STRING_RESULT VARCHAR2(10000) := '';
        I INTEGER;
BEGIN
    I := CONCAT_DATA.FIRST;
    IF I IS NULL
    THEN
        RETURN STRING_RESULT;
    END IF;

    STRING_RESULT := CONCAT_DATA(I);
    I := CONCAT_DATA.NEXT(I);
    WHILE I IS NOT NULL
    LOOP
        STRING_RESULT := STRING_RESULT || SEPARATOR || CONCAT_DATA(I);
        I := CONCAT_DATA.NEXT(I);
    END LOOP;

    RETURN STRING_RESULT;
END;

CREATE OR REPLACE FUNCTION EXTRACT_VALUES(
    XML_STRING IN VARCHAR2,
    PATH_STRING IN VARCHAR2
) RETURN XML_RECORD IS
    I                  NUMBER := 1;
    COLLECTION_LENGTH   NUMBER := 0;
    CURRENT_NODE_VALUE VARCHAR2(50) := ' ';
    XML_COLLECTION     XML_RECORD := XML_RECORD();
BEGIN
    SELECT
        EXTRACTVALUE(XMLTYPE(XML_STRING),
        PATH_STRING || '[' || I || ']') INTO CURRENT_NODE_VALUE
    FROM
        DUAL;
    WHILE CURRENT_NODE_VALUE IS NOT NULL LOOP
        I := I + 1;
        -- DBMS_OUTPUT.PUT_LINE(PATH_STRING
        --     || '['
        --     || I
        --     || ']');
        COLLECTION_LENGTH := COLLECTION_LENGTH + 1;
        XML_COLLECTION.EXTEND();
        XML_COLLECTION(COLLECTION_LENGTH) := TRIM(CURRENT_NODE_VALUE);
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            PATH_STRING || '[' || I || ']') INTO CURRENT_NODE_VALUE
        FROM
            DUAL;
    END LOOP;
    RETURN XML_COLLECTION;
END;

CREATE OR REPLACE FUNCTION EXTRACT_WITH_SUBNODES( XML_STRING IN VARCHAR2, PATH_STRING IN VARCHAR2 ) RETURN XML_RECORD IS
    CURRENT_NODE_VALUE VARCHAR2(1000);
    XML_COLLECTION     XML_RECORD := XML_RECORD();
    I                  NUMBER := 1;
BEGIN
    LOOP
        SELECT
            EXTRACT(XMLTYPE(XML_STRING),
            PATH_STRING || '[' || I || ']').GETSTRINGVAL()
        INTO CURRENT_NODE_VALUE FROM DUAL;
        
        IF CURRENT_NODE_VALUE IS NULL
        THEN
            EXIT;
        END IF;
        XML_COLLECTION.EXTEND;
        XML_COLLECTION(XML_COLLECTION.COUNT) := TRIM(CURRENT_NODE_VALUE);
        I := I + 1;
    END LOOP;
    RETURN XML_COLLECTION;
END;

CREATE OR REPLACE PACKAGE PACKAGE4 AS
    FUNCTION PROCESS_WHERE(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_OPERATOR(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_SELECT(XML_STRING IN VARCHAR2) RETURN SYS_REFCURSOR;
    FUNCTION PROCESS_INSERT(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_UPDATE(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_DELETE(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_CREATE(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION PROCESS_DROP(XML_STRING IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION GENERATE_AUTO_INCREMENT(TABLE_NAME IN VARCHAR2) RETURN VARCHAR2;
END PACKAGE4;

CREATE OR REPLACE PACKAGE BODY PACKAGE4 AS
    FUNCTION PROCESS_OPERATOR(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        I                       NUMBER := 1;
        TABLES_LIST             XML_RECORD := XML_RECORD();
        IN_COLUMNS              XML_RECORD := XML_RECORD();
        CONCAT_OPERATIONS       XML_RECORD := XML_RECORD();
        CONCAT_OPERATION_FILTER XML_RECORD := XML_RECORD();
        FILTER                  XML_RECORD := XML_RECORD();
        CONCAT_OPERANDS         XML_RECORD := XML_RECORD();
        JOIN_OPERATIONS         XML_RECORD := XML_RECORD();
        JOIN_CONDITION          VARCHAR2(100);
        JOIN_TYPE               VARCHAR2(100);
        XML_RECORD_ITERATOR     VARCHAR2(50);
        WHERE_QUERY VARCHAR2(1000);
        SELECT_QUERY            VARCHAR2(1000) := 'SELECT ';
    BEGIN
        IF XML_STRING IS NULL THEN
            RETURN NULL;
        END IF;
        TABLES_LIST := EXTRACT_VALUES(XML_STRING, 'Operation/Tables/Table');
        IN_COLUMNS := EXTRACT_VALUES(XML_STRING, 'Operation/Columns/Column');
        SELECT_QUERY := SELECT_QUERY
            || ' '
            || IN_COLUMNS(1);
        FOR INDX IN 2..IN_COLUMNS.COUNT LOOP
            SELECT_QUERY := SELECT_QUERY
                || ', '
                || IN_COLUMNS(INDX);
        END LOOP;
        SELECT_QUERY := SELECT_QUERY
            || ' FROM '
            || TABLES_LIST(1);
        FOR INDX IN 2..TABLES_LIST.COUNT LOOP
            SELECT
                EXTRACTVALUE(XMLTYPE(XML_STRING),
                'Operation/Joins/Join' || '[' || (INDX - 1) || ']/Type')
            INTO JOIN_TYPE FROM DUAL;
            SELECT
                EXTRACTVALUE(XMLTYPE(XML_STRING),
                'Operation/Joins/Join' || '[' || (INDX - 1) || ']/Condition')
            INTO JOIN_CONDITION FROM DUAL;
            SELECT_QUERY := SELECT_QUERY
                || ' '
                || JOIN_TYPE
                || ' '
                || TABLES_LIST(INDX)
                || ' ON '
                || JOIN_CONDITION;
        END LOOP;
        -- SELECT
        --     EXTRACT(XMLTYPE(XML_STRING), 'Operation/Where').GETSTRINGVAL() INTO WHERE_QUERY
        -- FROM
        --     DUAL;
        SELECT_QUERY := SELECT_QUERY
            || PROCESS_WHERE(XML_STRING);
        -- DBMS_OUTPUT.PUT_LINE(SELECT_QUERY);
        RETURN SELECT_QUERY;
    END PROCESS_OPERATOR;

    FUNCTION PROCESS_WHERE(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        WHERE_FILTER        XML_RECORD := XML_RECORD();
        WHERE_CLOUSE        VARCHAR2(1000) := ' WHERE ';
        CONDITION_BODY      VARCHAR2(100);
        SUB_QUERY           VARCHAR2(1000);
        SUB_QUERY1          VARCHAR2(1000);
        CONDITION_OPERATOR  VARCHAR2(100);
        I                   NUMBER := 1;
        FILTERS             XML_RECORD := XML_RECORD();
        CONCAT_OPERAND      XML_RECORD := XML_RECORD();
        XML_RECORD_ITERATOR VARCHAR2(50);
        SELECT_QUERY        VARCHAR2(1000) := 'SELECT ';
    BEGIN
        WHERE_FILTER := EXTRACT_WITH_SUBNODES(XML_STRING, 'Operation/Where/Conditions/Condition');
        FOR I IN 1..WHERE_FILTER.COUNT LOOP
            SELECT
                EXTRACTVALUE(XMLTYPE(WHERE_FILTER(I)),
                'Condition/Body') INTO CONDITION_BODY
            FROM
                DUAL;
            -- DBMS_OUTPUT.PUT_LINE(TRIM(CONDITION_BODY));
            SELECT
                EXTRACT(XMLTYPE(WHERE_FILTER(I)),
                'Condition/Operation').GETSTRINGVAL() INTO SUB_QUERY
            FROM
                DUAL;
            SELECT
                EXTRACTVALUE(XMLTYPE(WHERE_FILTER(I)),
                'Condition/ConditionOperator') INTO CONDITION_OPERATOR
            FROM
                DUAL;
            SUB_QUERY1 := PROCESS_OPERATOR(SUB_QUERY);
            IF SUB_QUERY1 IS NOT NULL THEN
                SUB_QUERY1 := '('
                    || SUB_QUERY1
                    || ')';
            END IF;
            WHERE_CLOUSE := WHERE_CLOUSE
                || ' '
                || TRIM(CONDITION_BODY)
                || ' '
                || SUB_QUERY1
                || ' '
                || CONDITION_OPERATOR
                || ' ';
        END LOOP;

        IF WHERE_FILTER.COUNT = 0 THEN
            RETURN ' ';
        END IF;
        RETURN WHERE_CLOUSE;
    END PROCESS_WHERE;


    FUNCTION PROCESS_SELECT(XML_STRING IN VARCHAR2) RETURN SYS_REFCURSOR IS
        RF_CUR SYS_REFCURSOR;
    BEGIN
        OPEN RF_CUR FOR PROCESS_OPERATOR(XML_STRING);
        RETURN RF_CUR;
    END;


    FUNCTION PROCESS_INSERT(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        VALUES_TO_INSERT       VARCHAR2(1000);
        SELECT_QUERY_TO_INSERT VARCHAR2(1000);
        XML_VALUES             XML_RECORD := XML_RECORD();
        INSERT_QUERY           VARCHAR2(1000);
        TABLE_NAME             VARCHAR2(100);
        XML_COLUMNS            VARCHAR2(200);
    BEGIN
        SELECT
            EXTRACT(XMLTYPE(XML_STRING),
            'Operation/Values').GETSTRINGVAL() INTO VALUES_TO_INSERT
        FROM
            DUAL;
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            'Operation/Table') INTO TABLE_NAME
        FROM
            DUAL;
        XML_COLUMNS := '('
            || CONCAT_STRING(EXTRACT_VALUES(XML_STRING, 'Operation/Columns/Column'), ',')
            || ')';
        INSERT_QUERY := 'INSERT INTO '
            || TABLE_NAME
            || XML_COLUMNS;
        IF VALUES_TO_INSERT IS NOT NULL THEN
            XML_VALUES := EXTRACT_VALUES(VALUES_TO_INSERT, 'Values/Value');
            INSERT_QUERY := INSERT_QUERY
                || ' VALUES'
                || '('
                || XML_VALUES(1)
                || ') ';
            FOR I IN 2..XML_VALUES.COUNT LOOP
                INSERT_QUERY := INSERT_QUERY
                    || ',('
                    || XML_VALUES(I)
                    || ') ';
            END LOOP;
        ELSE
            SELECT
                EXTRACT(XMLTYPE(XML_STRING), 'Operation/Operation').GETSTRINGVAL() INTO SELECT_QUERY_TO_INSERT
            FROM
                DUAL;
            INSERT_QUERY := INSERT_QUERY
                || PROCESS_OPERATOR(SELECT_QUERY_TO_INSERT);
        END IF;
        RETURN INSERT_QUERY;
    END;

    FUNCTION PROCESS_UPDATE(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        SET_COLLECTION     XML_RECORD := XML_RECORD();
        WHERE_CLOUSE       VARCHAR2(1000) := ' WHERE ';
        SET_OPERATIONS     VARCHAR2(1000);
        SUB_QUERY          VARCHAR2(1000);
        CONDITION_OPERATOR VARCHAR2(1000);
        UPDATE_QUERY       VARCHAR2(1000) := 'UPDATE ';
        TABLE_NAME         VARCHAR2(100);
    BEGIN
        SELECT
            EXTRACT(XMLTYPE(XML_STRING),
            'Operation/SetOperations').GETSTRINGVAL() INTO SET_OPERATIONS
        FROM
            DUAL;
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            'Operation/Table') INTO TABLE_NAME
        FROM
            DUAL;
        SET_COLLECTION := EXTRACT_VALUES(SET_OPERATIONS, 'SetOperations/Set');
        UPDATE_QUERY := UPDATE_QUERY
            || TABLE_NAME
            || ' SET '
            || SET_COLLECTION(1);
        FOR I IN 2..SET_COLLECTION.COUNT LOOP
            UPDATE_QUERY := UPDATE_QUERY
                || ','
                || SET_COLLECTION(I);
        END LOOP;
        UPDATE_QUERY := UPDATE_QUERY
            || PROCESS_WHERE(XML_STRING);
        RETURN UPDATE_QUERY;
    END;

    FUNCTION PROCESS_DELETE(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        WHERE_CLOUSE       VARCHAR2(1000) := ' WHERE ';
        CONDITION_OPERATOR VARCHAR2(100);
        DELETE_QUERY       VARCHAR2(1000) := 'DELETE FROM';
        TABLE_NAME         VARCHAR2(100);
    BEGIN
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            'Operation/Table') INTO TABLE_NAME
        FROM
            DUAL;
        DELETE_QUERY := DELETE_QUERY
            || PROCESS_WHERE(XML_STRING);
        RETURN DELETE_QUERY;
    END;

    FUNCTION PROCESS_CREATE(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        TABLE_COLUMNS         XML_RECORD := XML_RECORD();
        TABLE_NAME            VARCHAR2(100);
        COL_CONSTRAINTS       XML_RECORD := XML_RECORD();
        TABLE_CONSTRAINTS     XML_RECORD := XML_RECORD();
        COL_NAME              VARCHAR2(100);
        COL_TYPE              VARCHAR2(100);
        PARENT_TABLE          VARCHAR2(100);
        CREATE_QUERY          VARCHAR2(1000) := 'CREATE TABLE ';
        PRIMARY_CONSTRAINT    VARCHAR2(1000);
        FOREIGN_CONSTRAINT    VARCHAR2(1000);
        AUTO_INCREMENT_SCRIPT VARCHAR2(1000);
    BEGIN
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            'Operation/Table') INTO TABLE_NAME
        FROM
            DUAL;
        CREATE_QUERY := CREATE_QUERY
            || TABLE_NAME
            || '(';
        TABLE_COLUMNS := EXTRACT_WITH_SUBNODES(XML_STRING, 'Operation/Columns/Column');
        FOR I IN 1 .. TABLE_COLUMNS.COUNT LOOP
            SELECT
                EXTRACTVALUE(XMLTYPE(TABLE_COLUMNS(I)),
                'Column/Name') INTO COL_NAME
            FROM
                DUAL;
            SELECT
                EXTRACTVALUE(XMLTYPE(TABLE_COLUMNS(I)),
                'Column/Type') INTO COL_TYPE
            FROM
                DUAL;
            COL_CONSTRAINTS := EXTRACT_VALUES(TABLE_COLUMNS(I), 'Column/Constraints/Constraint');
            CREATE_QUERY := CREATE_QUERY
                || ' '
                || COL_NAME
                || ' '
                || COL_TYPE
                || ' '
                || CONCAT_STRING(COL_CONSTRAINTS, '
            ');
            IF I != TABLE_COLUMNS.COUNT THEN
                CREATE_QUERY := CREATE_QUERY
                    || ' , ';
            END IF;
        END LOOP;
        SELECT
            EXTRACT(XMLTYPE(XML_STRING),
            'Operation/TableConstraints/PrimaryKey').GETSTRINGVAL() INTO PRIMARY_CONSTRAINT
        FROM
            DUAL;

        IF PRIMARY_CONSTRAINT IS NOT NULL THEN
            CREATE_QUERY := CREATE_QUERY
                || 'Constraint'
                || TABLE_NAME
                || '_pk PRIMARY KEY ('
                || CONCAT_STRING( EXTRACT_VALUES(PRIMARY_CONSTRAINT, 'PrimaryKey/Columns/Column'), ',' )
                || ')';
        ELSE
            AUTO_INCREMENT_SCRIPT := GENERATE_AUTO_INCREMENT(TABLE_NAME);
            CREATE_QUERY := CREATE_QUERY
                || ', ID NUMBER PRIMARY KEY';
        END IF;

        TABLE_CONSTRAINTS := EXTRACT_WITH_SUBNODES(XML_STRING, 'Operation/TableConstraints/ForeignKey');
        FOR I IN 1 .. TABLE_CONSTRAINTS.COUNT LOOP
            SELECT
                EXTRACTVALUE(XMLTYPE(TABLE_CONSTRAINTS(I)),
                'ForeignKey/Parent') INTO PARENT_TABLE
            FROM
                DUAL;
            CREATE_QUERY := CREATE_QUERY
                || ' , CONSTRAINT '
                || TABLE_NAME
                || '_'
                || PARENT_TABLE
                || '_fk Foreign Key ('
                || CONCAT_STRING(EXTRACT_VALUES(TABLE_CONSTRAINTS(I), 'ForeignKey/ChildColumns/Column'), ' , ')
                || ' ) '
                || 'REFERENCES '
                || PARENT_TABLE
                || '('
                || CONCAT_STRING(EXTRACT_VALUES(TABLE_CONSTRAINTS(I), 'ForeignKey/ChildColumns/Column'), ' , ')
                || ')';
        END LOOP;
        CREATE_QUERY := CREATE_QUERY
            || ');'
            || AUTO_INCREMENT_SCRIPT;
        RETURN CREATE_QUERY;
    END;

    FUNCTION PROCESS_DROP(XML_STRING IN VARCHAR2) RETURN VARCHAR2 IS
        DROP_QUERY VARCHAR2(1000) := 'DROP TABLE ';
        TABLE_NAME VARCHAR2(100);
    BEGIN
        SELECT
            EXTRACTVALUE(XMLTYPE(XML_STRING),
            'Operation/Table') INTO TABLE_NAME
        FROM
            DUAL;
        DROP_QUERY := DROP_QUERY
            || TABLE_NAME;
        RETURN DROP_QUERY;
    END;
    
    FUNCTION GENERATE_AUTO_INCREMENT(TABLE_NAME IN VARCHAR2) RETURN VARCHAR2 IS
        AUTO_INCREMENT_SCRIPT VARCHAR(1000);
    BEGIN
        AUTO_INCREMENT_SCRIPT := 'CREATE SEQUENCE '
            || TABLE_NAME
            || '_pk_seq'
            || '; ';
        AUTO_INCREMENT_SCRIPT := AUTO_INCREMENT_SCRIPT
            || 'CREATE OR REPLACE TRIGGER '
            || TABLE_NAME
            || ' BEFORE INSERT ON '
            || TABLE_NAME
            || ' FOR EACH'
            || 'ROW BEGIN'
            || ' IF INSERTING THEN '
            || ' SELECT '
            || TABLE_NAME
            || '_pk_seq'
            || '.NEXTVAL INTO :NEW."ID" FROM DUAL;'
            || ' END IF;'
            || ' END IF;'
            || 'END';
        RETURN AUTO_INCREMENT_SCRIPT;
    END;
END PACKAGE4;

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation><Type>SELECT</Type><Tables><Table>XMLTEST1</Table><Table>XMLTEST2</Table></Tables><Joins><Join><Type>LEFT JOIN</Type><Condition>XMLTEST1.ID = XMLTEST2.ID</Condition></Join></Joins><Columns><Column>XMLTEST1.ID</Column><Column>XMLTEST2.ID</Column></Columns><Where><Conditions><Condition><Body>XMLTEST1.ID = 1</Body><ConditionOperator>AND</ConditionOperator></Condition><Condition><Body>EXISTS</Body><Operation><Type>SELECT</Type><Tables><Table>XMLTEST1</Table></Tables><Columns><Column>ID</Column></Columns><Where><Conditions><Condition><Body>ID = 1</Body></Condition></Conditions></Where></Operation></Condition></Conditions></Where></Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_OPERATOR(INPUT_DATA));
END;

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation><Type>DROP</Type><Table>XMLTEST1</Table></Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_DROP(INPUT_DATA));
END;

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation><Type>INSERT</Type><Table>Table1</Table><Columns><Column>XMLTEST1.ID</Column><Column>XMLTEST2.ID</Column></Columns><Operation><Type>SELECT</Type><Tables><Table>XMLTEST1</Table></Tables><Columns><Column>ID</Column></Columns><Where><Conditions><Condition><Body>ID = 1</Body></Condition></Conditions></Where></Operation></Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_INSERT(INPUT_DATA));
END;

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation><Type>CREATE</Type><Table>SOME_TABLE</Table><Columns><Column><Name>COL1</Name><Type>NUMBER</Type><Constraints><Constraint>NOT NULL</Constraint></Constraints></Column><Column><Name>COL2</Name><Type>VARCHAR2(100)</Type><Constraints><Constraint>NOT NULL</Constraint></Constraints></Column></Columns><TableConstraints><Primary><Columns><Column>COL2</Column></Columns></Primary><ForeignKey><ChildColumns><Column>COL1</Column></ChildColumns><Parent>SOME_TABLE2</Parent><ParentColumns><Column>ID</Column></ParentColumns></ForeignKey></TableConstraints></Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_CREATE(INPUT_DATA));
END;

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation><Type>UPDATE</Type><Table>XMLTEST1</Table><SetOperations><Set>col1 = 1</Set></SetOperations><Where><Conditions><Condition><Body>XMLTEST1.ID = 1</Body><ConditionOperator>AND</ConditionOperator></Condition><Condition><Body>EXISTS</Body><Operation><Type>SELECT</Type><Tables><Table>XMLTEST1</Table></Tables><Columns><Column>ID</Column></Columns><Where><Conditions><Condition><Body>ID = 1</Body></Condition></Conditions></Where></Operation></Condition></Conditions></Where></Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_UPDATE(INPUT_DATA));
END;


DECLARE
    RF_CUR SYS_REFCURSOR;
    v INTEGER;
    INPUT_DATA VARCHAR2(1000) := '<Operation>
    <Type>SELECT</Type>
    <Tables>
        <Table>XMLTEST1</Table>
    </Tables>
    <Joins>
    </Joins>
    <Columns>
        <Column>XMLTEST1.ID</Column>
    </Columns>
    <Where>
        <Conditions></Conditions>
    </Where>
</Operation>';
begin
    RF_CUR := PACKAGE4.PROCESS_SELECT(INPUT_DATA);
    LOOP
    -- Получаем строку
    FETCH RF_CUR INTO v;
    -- Выходим из цикла, если извлекаемых строк больше не осталось
    DBMS_OUTPUT.PUT_LINE(v);
    EXIT WHEN RF_CUR%notfound;
 
    END LOOP;
 
    CLOSE RF_CUR;
end;    


CREATE TABLE XMLTEST1
(
    id INTEGER NOT NULL
);

CREATE TABLE XMLTEST2
(
    id INTEGER NOT NULL
);


SELECT * FROM XMLTEST2;

INSERT INTO XMLTEST2 VALUES (2);

DECLARE
    INPUT_DATA VARCHAR2(1000) := '<Operation>
    <Type>SELECT</Type>
    <Tables>
        <Table>XMLTEST3</Table>
    </Tables>
    <Columns>
        <Column>XMLTEST3.ID</Column>
        <Column>XMLTEST3.NAME</Column>
    </Columns>
    <Where>
        <Conditions>
            <Condition>
                <Body>XMLTEST3.NAME LIKE "text"</Body>
            </Condition>
        </Conditions>
    </Where>
</Operation>';
BEGIN
    DBMS_OUTPUT.PUT_LINE(PACKAGE4.PROCESS_OPERATOR(INPUT_DATA));
END;