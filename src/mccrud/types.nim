#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#       See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#                   CRUD Package Types

## CRUD types | centralised and exported types for all CRUD operations
## 
import db_postgres as postgres
import db_mysql as mysql
import db_sqlite as sqlite
import json, tables, times
import mcresponse

# Define crud types

# db-Types
type
    DatabaseType* = enum
        Postgres = "postgres",
        MySQL ="mysql",
        Sqlite ="sqlite"

    Database* = ref object
        dbc*: postgres.DbConn
        dbcmysql*: mysql.DbConn
        dbcsqlite*: sqlite.DbConn

    DbSecureType* = object
        secureAccess*: bool
        secureCert*: string
        secureKey*: string
        sslMode*: string

    # TODO: define db-options field-value-types
    DbOptionType* = object
        fileName*: string
        hostName*: string
        hostUrl*: string
        userName*: string
        password*: string
        dbName*: string
        port*: uint
        dbType*: DatabaseType
        poolSize*: uint
        secureOption*: DbSecureType

    DbConfigType* = object
        host*: string
        userName*: string
        password*: string
        dbName*: string
        fileName*: string
        location*: string
        port*: uint
        dbType*: DatabaseType
        poolSize*: uint
        url*: string
        secureOption*: DbSecureType
        timezone*: string
        options*: DbOptionType

type
    CrudTasksType* = enum
        CreateTask  = "create"
        InsertTask  = "insert"
        UpdateTask  = "update"
        ReadTask    = "read"
        DeleteTask  = "delete"
        RemoveTask  = "remove"
        LoginTask   = "login"
        LogoutTask  = "logout"
        SystemTask  = "system"
        AppTask     = "app"
        UnknownTask = "unknown"
        OtherTask = "other"

    DataTypes* = enum
        STRING = "string",
        VARCHAR = "varchar",
        TEXT = "text",
        UUID = "uuid",
        NUMBER = "number",
        POSITIVE = "positive",
        INT = "int",
        FLOAT = "float",
        BOOL= "bool",
        BOOLEAN = "boolean",
        JSON = "json",
        BIGINT = "bigint",
        BIGFLOAT = "bigfloat",
        DATE = "date",
        DATETIME ="datatime",
        TIME="time",
        TIMESTAMP="timestamp",
        TIMESTAMPZ="timestampz",
        OBJECT = "object",     ## key-value pairs
        ENUM="enum",       ## Enumerations
        SET="set",        ## Unique values set
        ARRAY="array",
        SEQ= "seq",
        TABLE= "table",      ## Table/Map/Dictionary
        MCDB="mcdb",       ## Database connection handle
        MODEL_RECORD="modelrecord",   ## Model record definition
        MODEL_VALUE="modelvalue",   ## Model value definition
  
    RelationTypes* = enum
        AND="and",
        OR= "or",
    
    OpTypes* = enum
        EQ= "eq",
        NE= "ne",
        GT= "gt",
        GTE= "gte",
        LT= "lt",
        LTE= "lte",
        NEQ= "neq",
        IN= "in",
        NOT_IN= "notin",
        BETWEEN="between",
        NOT_BETWEEN="notbetween",
        INCLUDES="includes",
        LIKE= "like",
        NOT_LIKE="notlike",
        STARTS_WITH="startswith",
        ENDS_WITH="endswith",
        ILIKE="ilike",
        NOT_ILIKE="notilike",
        REGEX="regex",
        NOT_REGEX="notregex",
        IREGEX="iregex",
        NOT_IREGEX="notiregex",
        ANY="any",
        ALL= "all",

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
        ID = "id",
        PARAMS = "params",
        QUERY = "query",
        SUBQUERY ="subquery",

    OrderTypes* = enum
        ASC = "asc",
        DESC = "desc",

    uuId* = string

    CreatedByType* = uuId
    UpdatedByType* = uuId
    CreatedAtType* = DateTime
    UpdatedAtType* = DateTime

    ValueType* = int | string | float | bool | Positive | Natural | JsonNode | BiggestInt | BiggestFloat | Table | seq | Database | typed
 
    ## User/client information to be provided after successful login
    ## 
    UserInfoType* = object
        userId*: string         # stored as uuid in the DB
        firstname*: string
        lastname*: string
        language*: string
        loginName*: string
        email*: string
        token*: string
        expire*: Natural
        roleId*: string 

    AppBaseModelType* = ref object of RootObj
        id*: string # stored as uuid in the DB
        appId*: string
        language*: string
        description*: string
        isActive*: bool
        createdBy*:string
        createdAt*: DateTime
        updatedBy*: string
        updatedAt*: DateTime

    BaseModelType* = ref object of RootObj
        id*: string # stored as uuid in the DB
        language*: string
        description*: string
        isActive*: bool
        createdBy*:string
        createdAt*: DateTime
        updatedBy*: string
        updatedAt*: DateTime

    RelationBaseModelType* = ref object of RootObj
        description*: string
        isActive*: bool
        createdBy*:string
        createdAt*: DateTime
        updatedBy*: string
        updatedAt*: DateTime

    AppParamsType* = object     
        appId*: string
        accessKey*: string
        appName*: string
        category*:string

    AuditStampType* = object
        isActive*: bool
        createdBy*:string
        createdAt*:DateTime
        updatedBy*:string
        updatedAt*:DateTime

    Audit* = ref object of AppBaseModelType
        tableName*: string
        logRecords*: JsonNode
        newLogRecords*: JsonNode
        logType*: string
        logBy*: string  # login/user-name
        logAt*: Datetime    

    Application* = object
        id*: string         # stored as uuid in the DB
        appName*: string
        accessKey*:string
        language*: string
        description*: string
        isActive*: bool
        createdBy*:string
        createdAt*:DateTime
        updatedBy*:string
        updatedAt*:DateTime
        appCategory*: string

    EmailAddressType* = Table[string, string]

    Profile* = ref object of BaseModelType
        userId*:string
        firstname*:string
        lastname*:string
        middlename*:string
        phone*:string
        emails*:seq[string]
        recEmail*:string
        roleId*:string
        dateOfBirth*:DateTime
        twoFactorAuth*:bool
        authAgent*: string
        authPhone*:string
        postalCode*:string

    RoleServiceType* = object
        serviceId*: string
        roleId*:string
        roleIds*:seq[string]
        serviceCategory*:string
        canRead*:bool
        canCreate*:bool
        canUpdate*:bool
        canDelete*:bool
        canCrud*:bool
        tableAccessPermitted*: bool

    CheckAccessType* = object
        userId*: string
        roleId*: string
        roleIds*: seq[string]
        isActive*: bool
        isAdmin*:bool
        roleServices*: seq[RoleServiceType]
        tableId*:string
        ownerPermitted*:bool

    CheckAccessParamsType* = object
        accessDb*: Database
        userInfo*: UserInfoType
        tableName*: string
        recordIds*: seq[string]
        accessTable*: string
        userTable*: string
        roleTable*: string
        serviceTable*: string
        profileTable*: string

    RoleFuncType* = proc(it1: string, it2: RoleServiceType): bool

    FieldValueType* = string | int | float | bool | object | seq[string] | seq[int] | seq[bool] | seq[float] | seq[object] | Time

    # ActionParamType* = Table[string, FieldValueType]
    ActionParamType* = JsonNode

    ValueToDataType* = Table[string, FieldValueType]

    ActionParamsType* = seq[JsonNode]

    SortParamType* = Table[string, int]

    ProjectParamType* = Table[string, int]

    # QueryParamType* = Table[string, FieldValueType]
    QueryParamType* = JsonNode

    ModelOptionsType* = object
        timeStamp*: bool
        activeStamp*: bool
        actorStamp*:bool
    
    ## CrudParamsType is the struct type for receiving, composing and passing CRUD inputs
    CrudParamsType* = ref object of RootObj
        modelRef*: JsonNode
        appDb*: Database
        tableName*: string
        tableFields*: seq[string]
        userInfo*: UserInfoType
        actionParams*: ActionParamsType
        queryParams*: QueryParamType
        recordIds*: seq[string]
        projectParams*: ProjectParamType
        sortParams*: SortParamType
        token*: string
        skip*: int
        limit*: int
        taskName*: string
        taskType*: string
        appParams*: AppParamsType

    CrudOptionsType* = ref object of CrudParamsType
        checkAccess*: bool
        cacheResult*: bool
        bulkCreate*: bool
        dbType*: DatabaseType
        accessDb*: Database
        auditDb*: Database
        serviceDb*: Database
        auditTable*: string
        serviceTable*: string
        userTable*: string
        roleTable*: string
        accessTable*: string
        verifyTable*: string
        profileTable*: string
        userRoleTable*: string
        maxQueryLimit*: int
        logCrud*: bool
        logCreate*: bool
        logUpdate*: bool
        logRead*: bool
        logDelete*: bool
        logLogin*: bool
        logLogout*: bool
        unAuthorizedMessage*: string
        recExistMessage*: string
        cacheExpire*: int
        loginTimeout*: int
        usernameExistsMessage*: string
        emailExistsMessage*: string
        msgFrom*: string
        modelOptions*: ModelOptionsType
        fieldSeparator*: string
        appDbs*: seq[string]
        appTables*: seq[string]

    SelectQueryOptions* = object
        skip*: int
        limit*: int
    
    MessageObjectType* = Table[string, string]

    ValidateResponseType* = object
        ok*: bool
        errors*: MessageObjectType
    
    OkayResponse* = object
        ok*: bool

    QueryFieldValueType*[V] = object
        value*: V

    FieldValueDescType*[T] = object
        valueType*: DataTypes
        value*: T

    FieldValuesType* = seq[FieldValueDescType]
    FieldValuesTypes* = seq[seq[FieldValueDescType]]
    
    CreateQueryObject* = object
        createQueryWithValues*: seq[string]
        createQuery*: string
        fieldNames*: seq[string]
        # TODO: determine generic-type for fieldValue
        fieldValues*: seq[seq[string]]  

    WhereQueryObject* = object
        whereQueryWithValues*: string
        whereQuery*: string
        fieldValues*: seq[string]

    UpdateQueryObject* = object
        updateQueryWithValues*: seq[string]
        updateQuery*: string
        fieldNames*: seq[string]
        fieldValues*: seq[string]
        whereQuery*: WhereQueryObject

    DeleteQueryObject* = object
        deleteQuery*: string
        fieldValues*: seq[string]
        whereQuery*: WhereQueryObject

    SelectQueryObject* = object
        selectQueryWithWhere*: string
        selectQuery*: string
        fieldValues*: seq[string]
        whereQuery*: WhereQueryObject

    CreateQueryResult* = object
        createQueryObject*: CreateQueryObject
        ok*: bool
        message*: string

    UpdateQueryResult* = object
        updateQueryObject*: UpdateQueryObject
        ok*: bool
        message*: string

    MultiUpdateQueryResult* = object
        updateQueryObjects*: seq[UpdateQueryObject]
        ok*: bool
        message*: string

    DeleteQueryResult* = object
        deleteQueryObject*: DeleteQueryObject
        ok*: bool
        message*: string
    
    SelectQueryResult* = object
        selectQueryObject*: SelectQueryObject
        ok*: bool
        message*: string

    WhereQueryResult* = object
        whereQueryObject*: WhereQueryObject
        ok*: bool
        message*: string

    LogRecordsType* = object
        logRecords*: JsonNode
        queryParam*: QueryParamType
        recordIds*: seq[string]
        tableFields*: seq[string]
        tableRecords*: seq[JsonNode]

    CrudResultType* = object
        queryParam*: QueryParamType
        recordIds*: seq[string]
        recordsCount*: int
        records*: seq[JsonNode]
        taskType*: CrudTasksType
        logRes*: ResponseMessage

    GetStatType* = object
        skip*: int
        limit*: int
        recordsCount*: int
        totalRecordsCount*: int
        queryParam*: QueryParamType
        recordIds*: seq[string]
        expire*: int

    GetResultType* = object
        records*: seq[JsonNode]
        stats*: GetStatType
        taskType*: CrudTasksType
        logRes*: ResponseMessage

    SaveResultType* = object
        queryParam*: QueryParamType
        recordIds*: seq[string]
        recordsCount*: int
        taskType*: CrudTasksType
        logRes*: ResponseMessage

    ErrorType* = object
        code*: string
        message*: string

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
