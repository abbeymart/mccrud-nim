#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#       See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#                   CRUD Package Types

## CRUD types | centralised and exported types for all CRUD operations
## 
import json, db_postgres, tables, times
import mcdb, mctranslog

# Define crud types

type 
    DataTypes* = enum
        STRING,
        VARCHAR,
        TEXT,
        UUID,
        NUMBER,
        POSITIVE,
        INT,
        FLOAT,
        BOOL,
        BOOLEAN,
        JSON,
        BIGINT,
        BIGFLOAT,
        DATE,
        DATETIME,
        TIMESTAMP,
        TIMESTAMPZ,
        # TIME,
        OBJECT,     ## key-value pairs
        ENUM,       ## Enumerations
        SET,        ## Unique values set
        ARRAY,
        SEQ,
        TABLE,      ## Table/Map/Dictionary
        MCDB,       ## Database connection handle
        MODEL_RECORD,   ## Model record definition
        MODEL_VALUE,   ## Model value definition
  
    ProcType = proc(): string
    ProcValidateType = proc(): bool

    ProcedureTypes* = enum
        PROC,              ## proc(): T
        VALIDATE_PROC,      ## proc(val: T): bool
        DEFAULT_PROC,       ## proc(): T
        SET_PROC,           ## proc(): T
        GET_PROC,           ## proc(): T
        UNARY_PROC,         ## proc(val: T): T
        BI_PROC,            ## proc(valA, valB: T): T
        PREDICATE_PROC,     ## proc(val: T): bool
        BI_PREDICATE_PROC,   ## proc(valA, valB: T): bool
        SUPPLY_PROC,        ## proc(): T
        BI_SUPPLY_PROC,      ## proc(): (T, T)
        CONSUMER_PROC,      ## proc(val: T): void
        BI_CONSUMER_PROC,    ## proc(valA, valB: T): void
        COMPARATOR_PROC,    ## proc(valA, valB: T): int
        MODEL_PROC,         ## proc(): Model  | to define new data model

    OpTypes* = enum
        AND,
        OR,
        NE,
        EQ,
        GT,
        GTE,
        LT,
        LTE,
        NEQ,
        IN,
        NOT_IN,
        BETWEEN,
        NOT_BETWEEN,
        INCLUDES,
        LIKE,
        NOT_LIKE,
        STARTS_WITH,
        ENDS_WITH,
        ILIKE,
        NOT_ILIKE,
        REGEX,
        NOT_REGEX,
        IREGEX,
        NOT_IREGEX,
        ANY,
        ALL,

    QueryTypes* = enum        
        SAVE,
        INSERT,
        UPDATE,
        DELETE,
        INSERT_INTO,
        SELECT_FROM,
        CASE,
        UNION,
        JOIN,
        INNER_JOIN,
        OUTER_LEFT_JOIN,
        OUTER_RIGHT_JOIN,
        OUTER_FULL_JOIN,
        SELF_JOIN,
        SUB,
        SELECT,
        SELECT_TOP,
        SELECT_TABLE_FIELD,
        SELECT_COLLECTION_DOC,
        SELECT_ONE_TO_ONE,      ## LAZY SELECT: select sourceTable, then getTargetTable() related record{target: {}}
        SELECT_ONE_TO_MANY,     ## LAZY SELECT: select sourceTable, then getTargetTable() related records ..., targets: [{}, {}]
        SELECT_MANY_TO_MANY,    ## LAZY SELECT: select source/targetTable, then getTarget(Source)Table() related records
        SELECT_INCLUDE_ONE_TO_ONE,  ## EAGER SELECT: select sourceTable and getTargetTable related record {..., target: {}}
        SELECT_INCLUDE_ONE_TO_MANY, ## EAGER SELECT: select sourceTable and getTargetTable related records { , []}
        SELECT_INCLUDE_MANY_TO_MANY, ## EAGER SELECT: select sourceTable and getTargetTable related record {{}}

    QueryWhereTypes* = enum
        ID,
        PARAMS,
        QUERY,
        SUBQUERY,

    OrderTypes* = enum
        ASC,
        DESC,

    uuId* = string

    CreatedByType* = uuId
    UpdatedByType* = uuId
    CreatedAtType* = DateTime
    UpdatedAtType* = DateTime

    ValueType* = int | string | float | bool | Positive | JsonNode | BiggestInt | BiggestFloat | Table | seq | Database | typed
 
    ## User/client information to be provided after successful login
    ## 
    UserParamType* = object
        id*: string         # stored as uuid in the DB
        firstName*: string
        lastName*: string
        language*: string
        loginName*: string
        email*: string
        token*: string

    ProcedureType* = object
        procDesc: ProcType          # return string to be cast into procReturnType
        procParams*: seq[string]    # proc params/fieldNames, to be injected into procName, used to get the fieldValue
        procReturnType*: DataTypes  # proc return type

    FieldDescType* = object
        fieldType*: DataTypes
        fieldLength*: int
        fieldPattern*: string # "![0-9]" => excluding digit 0 to 9 | "![_, -, \, /, *, |, ]" => exclude the charaters
        fieldFormat*: string # "12.2" => max 12 digits, including 2 digits after the decimal
        notNull*: bool
        unique*: bool
        indexable*: bool
        primaryKey*: bool
        minValue*: float
        maxValue*: float
        defaultValue*: ProcType  # result/return type (DataTypes) must match the fieldType
        validate*: ProcValidateType       # validate value (pattern, format...), returns a bool (valid=true/invalid=false)
        setValue*: ProcType # transform fieldValue prior to insert/update | cast string-result to fieldType

    RecordDescType* = Table[string, FieldDescType ]
    
    RelationOptionTypes* = enum
        RESTRICT,       ## must remove target-record(s), prior to removing source-record
        CASCADE,        ## default for ONUPDATE | update foreignKey value or delete foreignKey record/value
        NO_ACTION,      ## leave the foreignKey value, as-is
        SET_DEFAULT,    ## set foreignKey to specified default value
        SET_NULL,       ## default for ONDELETE | allow/set foreignKey to be null

    RelationTypeTypes* = enum
        ONE_TO_ONE,
        ONE_TO_MANY,
        MANY_TO_ONE,
        MANY_TO_MANY,

    ## Model/table relationship, from source-to-target
    ## 
    RelationType* = ref object
        relationType*: RelationTypeTypes   # one-to-one, one-to-many, many-to-one, many-to-many
        targetField*: string    # default: primary key/"id" field, it could be another unique key
        targetModel*: ModelType
        targetTable*: string
        foreignKey*: string     # default: sourceModel<sourceField>, e.g. userId
        relationTable*: string # optional tableName for many-to-many | default: sourceTable_targetTable
        onDelete*: RelationOptionTypes
        onUpdate*: RelationOptionTypes

    ## Model definition / description
    ## 
    ModelType* = ref object
        modelName*: string
        tableName*: string
        recordDesc*: Table[string, FieldDescType]
        timeStamp*: bool           ## auto-add: createdAt and updatedAt | default: true
        actorStamp*: bool           ## auto-add: createdBy and updatedBy | default: true
        activeStamp*: bool          ## record active status, isActive (true | false) | default: true
        relations*: seq[RelationType]
        methods*: seq[ProcedureType]    ## model-level procs, e.g fullName(a, b: T): T
        appDb*: Database            ## Db handle
        alterTable*: bool        ## create / alter table and sync existing data, if there was a change to the table structure | default: true       
                                ## if alterTable: false, it will create/re-create the table, with no data sync

    SaveFieldType* = object
        fieldName*: string
        fieldValue*: string
        fieldOrder*: int
        fieldType*: DataTypes
        fieldFunction*: ProcedureTypes ## COUNT, MIN, MAX... for select/read-query...

    CreateFieldType* = object
        fieldName*: string
        fieldValue*: string 

    UpdateFieldType* = object
        fieldName*: string
        fieldValue*: string
        fieldOrder*: int
        fieldFunction*: ProcedureTypes ## COUNT, MIN, MAX... for select/read-query...

    ReadFieldType* = object
        tableName*: string
        fieldName*: string
        fieldOrder*: int
        fieldAlias*: string
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes ## COUNT, MIN, MAX... for select/read-query...

    DeleteFieldType* = object
        fieldName*: string
        fieldSubQuery*: QueryParamType
        fieldFunction*: ProcedureTypes ## COUNT, MIN, MAX... for select/read-query...

    FieldSubQueryType* = object
        tableName*: string    ## default: "" => will use instance tableName instead
        fields*: seq[ReadFieldType]   ## @[] => SELECT * (all fields)
        where*: seq[WhereParamType]

    GroupFunctionType* = object
        fields*: seq[string]
        fieldFunction*: ProcedureTypes ## COUNT, MIN, MAX, custom... for select/read-query...

    WhereFieldType* = object
        fieldTable*: string
        fieldType*: DataTypes
        fieldName*: string
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldProc*: ProcedureTypes ## COUNT, MIN, MAX... for select/read-query...
        fieldProcFields*: seq[string] ## parameters for the fieldProc

    WhereParamType* = object
        groupCat*: string       # group (items) categorization
        groupLinkOp*: string        # group relationship to the next group (AND, OR)
        groupOrder*: int        # group order, the last group groupLinkOp should be "" or will be ignored
        groupItems*: seq[WhereFieldType] # group items to be composed by category

    SaveParamType* = object
        tableName*: string
        fields*: seq[SaveFieldType]
        where*: seq[WhereParamType]
   
    QueryParamType* = object        # same as QueryReadParamType
        tableName*: string    ## default: "" => will use instance tableName instead
        fields*: seq[ReadFieldType]   ## @[] => SELECT * (all fields)
        where*: seq[WhereParamType] ## whereParams or docId(s)  will be required for delete task

    QueryReadParamType* = object
        tableName*: string
        fields*: seq[ReadFieldType]
        where*: seq[WhereParamType]

    QuerySaveParamType* = object
        tableName*: string
        fields*: seq[SaveFieldType]
        where*: seq[WhereParamType]

    QueryUpdateParamType* = object
        tableName*: string
        fields*: seq[UpdateFieldType]
        where*: seq[WhereParamType]

    QueryDeleteParamType* = object
        tableName*: string
        fields*: seq[DeleteFieldType]
        where*: seq[WhereParamType]

    ## For SELECT TOP... query
    QueryTopType* = object         
        topValue*: int    
        topUnit*: string ## number or percentage (# or %)
    
    ## SELECT CASE... query condition(s)
    ## 
    CaseFieldType* = object
        fieldTable*: string
        fieldName*: string
        fieldType*: DataTypes   ## "int", "string", "bool", "boolean", "float",...
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldAlias*: string ## for SELECT/Read query
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes

    CaseConditionType* = object
        fields*: seq[CaseFieldType]
        resultMessage*: string
        resultField*: string  ## for ORDER BY options

    ## For SELECT CASE... query
    CaseQueryType* = object
        conditions*: seq[CaseConditionType]
        defaultField*: string   ## for ORDER BY options
        defaultMessage*: string 
        orderBy*: bool
        asField*: string

    SelectFromFieldType* = object
        fieldTable*: string
        fieldName*: string
        fieldType*: DataTypes   ## "int", "string", "bool", "boolean", "float",...
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldAlias*: string ## for SELECT/Read query
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes

    SelectFromType* = object
        tableName*: string
        fields*: seq[SelectFromFieldType]

    InsertIntoFieldType* = object
        fieldTable*: string
        fieldName*: string
        fieldType*: DataTypes   ## "int", "string", "bool", "boolean", "float",...
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldAlias*: string ## for SELECT/Read query
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes

    InsertIntoType* = object
        tableName*: string
        fields*: seq[InsertIntoFieldType]

    GroupType* = object
        fields*: seq[string]
        fieldFunction*: seq[ProcedureTypes]
        fieldOrder*: int

    OrderType* = object
        tableName*: string
        fieldName*: string
        queryProc*: ProcedureTypes
        fieldOrder*: OrderTypes ## "ASC" ("asc") | "DESC" ("desc")
        functionOrder*: OrderTypes

    # for aggregate query condition
    HavingType* = object
        tableName: string
        queryProc*: ProcedureTypes
        queryOp*: OpTypes
        queryOpValue*: string ## value will be cast to fieldType in queryProc
        orderType*: OrderTypes ## "ASC" ("asc") | "DESC" ("desc")
        # subQueryParams*: SubQueryParam # for ANY, ALL, EXISTS...

    SubQueryType* = object
        whereType*: string   ## EXISTS, ANY, ALL
        whereField*: string  ## for ANY / ALL | Must match the fieldName in QueryParamType
        whereOp*: OpTypes     ## e.g. "=" for ANY / ALL
        queryParams*: QueryParamType
        queryWhereParams*: WhereParamType

    ## combined/joined query (read) param-type
    ## 
    JoinSelectFieldItemType* = object
        fieldTable*: string
        fieldName*: string
        fieldType*: DataTypes   ## "int", "string", "bool", "boolean", "float",...
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldAlias*: string ## for SELECT/Read query
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes
    
    JoinSelectFieldType* =  object
        tableName*: string
        tableFields*: seq[JoinSelectFieldItemType]
    
    JoinFieldType* = object
        tableName*: string
        joinField*: string

    JoinQueryType* = object
        selectFromTable*: string ## default to tableName
        selectFields*: seq[JoinSelectFieldType]
        joinType*: string ## INNER (JOIN), OUTER (LEFT, RIGHT & FULL), SELF...
        joinFields*: seq[JoinFieldType] ## [{tableName: "abc", joinField: "field1" },]
    
    SelectIntoFieldType* = object
        fieldTable*: string
        fieldName*: string
        fieldType*: DataTypes   ## "int", "string", "bool", "boolean", "float",...
        fieldOrder*: int
        fieldOp*: OpTypes    ## GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  ## for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   ## end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] ## values for IN/NOTIN operator
        fieldSubQuery*: QueryParamType ## for WHERE IN (SELECT field from fieldTable)
        fieldPostOp*: OpTypes ## EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     ## e.g. AND | OR...
        fieldAlias*: string ## for SELECT/Read query
        show*: bool     ## includes or excludes from the SELECT query fields
        fieldFunction*: ProcedureTypes

    SelectIntoType* = object
        selectFields*: seq[SelectIntoFieldType] ## @[] => SELECT *
        intoTable*: string          ## new table/collection
        fromTable*: string          ## old/external table/collection
        fromFilename*: string      ## IN external DB file, e.g. backup.mdb
        WhereParamType*: seq[WhereParamType]
        joinParam*: JoinQueryType ## for copying from more than one table/collection

    UnionQueryType* = object
        selectQueryParams*: seq[QueryParamType]
        where*: seq[WhereParamType]
        orderParams*: seq[OrderType]

    RoleServiceType* = object
        serviceId*: string
        group*    : string
        category* : string
        canRead*  : bool
        canCreate*: bool
        canUpdate*: bool
        canDelete*: bool
    
    OkayResponse* = object
        ok*: bool
    
    CheckAccess* = object
        userId*: string
        group*: string
        groups*: seq[string]
        isActive*: bool
        isAdmin*: bool
        roleServices*: seq[RoleServiceType]
        collId*: string

    PermissionType* = object
        ok*: bool
        accessInfo*: CheckAccess

    CurrentRecord* = object
        currentRec*: seq[Row]
    
    TaskRecord* = object
        taskRec*: seq[QueryParamType]
        recCount*: int 

    # Exception types
    SaveError* = object of CatchableError
    CreateError* = object of CatchableError
    UpdateError* = object of CatchableError
    DeleteError* = object of CatchableError
    ReadError* = object of CatchableError
    AuthError* = object of CatchableError
    ConnectError* = object of CatchableError
    SelectQueryError* = object of CatchableError
    WhereQueryError* = object of CatchableError
    CreateQueryError* = object of CatchableError
    UpdateQueryError* = object of CatchableError
    DeleteQueryError* = object of CatchableError

    ## Shared CRUD Operation Types  
    CrudParamType* = ref object
        ## tableName: table/collection to insert, update, read or delete record(s).
        tableName*: string 
        docIds*: seq[string]  ## for update, delete and read tasks
        ## actionParams: @[{tableName: "abc", fieldNames: @["field1", "field2"]},], for create & update.
        ## Field names and corresponding values of record(s) to insert/create or update.
        ## Field-values will be validated based on data model definition.
        ## ValueError exception will be raised for invalid value/data type 
        ##
        actionParams*: seq[SaveParamType]
        queryParam*: QueryParamType
        queryReadParam*: QueryReadParamType
        queryDeleteParam*: QueryDeleteParamType
        queryUpdateParam*: QueryUpdateParamType
        querySaveParam*: QuerySaveParamType
        ## Bulk Insert Operation: 
        ## insertToParams {tableName: "abc", fieldNames: @["field1", "field2"]}
        ## For tableName: "" will use the default constructor tableName
        insertInto*: seq[InsertIntoType]
        ## selectFrom =
        ## {tableName: "abc", fieldNames: @["field1", "field2"]}
        ## the order and types of insertInto' & selectFrom' fields must match, otherwise ValueError exception will occur
        ## 
        selectFrom*: seq[SelectFromType]
        selectInto*: seq[SelectIntoType]
        ## Query conditions
        ## where: @[{groupCat: "validLocation", groupOrder: 1, groupLinkOp: "AND", groupItems: @[]}]
        ## groupItems = @[{tableName: "testing", fieldName: "ab", fieldOp: ">=", groupOp: "AND(and)", order: 1, fieldType: "integer", filedValue: "10"},].
        ## 
        where*: seq[WhereParamType]
        # queryParams*: seq[QueryParamType] => actionParams
        ## Read-only params =>
        ##  
        subQuery*: SubQueryType
        ## Combined/joined query:
        ## 
        joinQuery*: seq[JoinQueryType]
        unionQuery*: seq[UnionQueryType]
        queryDistinct*: bool
        queryTop*: QueryTopType
        ## Query function
        queryFunctions*: seq[ProcedureTypes]
        ## orderParams = @[{tableName: "testing", fieldName: "name", fieldOrder: "ASC", queryProc: "COUNT", functionOrderr: "DESC"}] 
        ## An order-param without orderType will default to ASC (ascending-order)
        ## 
        order*: seq[OrderType]
        group*: seq[GroupType] ## @[{fieldName: ""location", fieldOrder: 1}]
        having*: seq[HavingType]
        caseQuery*: seq[CaseQueryType] 
        skip*: Natural
        limit*: Positive
        defaultLimit*: int
        ## Database, audit-log and access parameters 
        ## 
        auditTable*: string
        accessTable*: string
        serviceTable*: string
        roleTable*: string
        userTable*: string
        appDb*: Database
        accessDb*: Database
        auditDb*: Database
        logAll*: bool
        logRead*: bool
        logCreate*: bool
        logUpdate*: bool
        logDelete*: bool
        userInfo*: UserParamType
        checkAccess*: bool
        transLog*: LogParam
        isRecExist*: bool
        isAuthorized*: bool
        createRecords*: seq[SaveParamType]
        updateRecords*: seq[SaveParamType]
        currentRecords*: seq[Row]
        roleServices*: seq[RoleServiceType]
        recExistMessage*: string
        unAuthMessage*: string
        cacheExpire*: Positive
