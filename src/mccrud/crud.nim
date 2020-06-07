#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##     CRUD Package - common / extendable base type/constructor & procedures
# 

import db_postgres, json, tables
import mcdb, mccache, mcresponse, mctranslog

export db_postgres, json, tables
export mcdb, mccache, mcresponse, mctranslog

# Define types
type
    Database = ref object
        db: DbConn
         
    ValueType* = int | string | float | bool | Positive | JsonNode | BiggestInt | BiggestFloat | Table | seq | Database | typed

    UserParam* = object
        uid*: string
        username*: string
        email*: string
        token*: string

    # value are string type for params parsing convenience,
    # values will be cast by fieldType, else will throw ValueError exception
    FieldInfo = object
        fieldName*: string
        fieldValue*: string # for create/insert and update
        fieldType*: string # "int", "string", "bool", "boolean", "float",...
        fieldAlias*: string
        show*: bool     # for mongoDB, ignore for Postgres, MySQL & SQLite
        fieldFunction*: string # COUNT, MIN, MAX... for select/read-query...
        fieldOp*: string # fieldOp: GT, EQ, GTE, LT, LTE, NEQ(<>), "IS NULL",... for case-query
        
    CaseCondition* = object
        fieldInfo*: seq[FieldInfo]
        resultMessage*: string
        resultField*: string  # for ORDER BY options

    CaseQueryParam* = object
        conditions*: seq[CaseCondition]
        defaultField*: string   # for ORDER BY options
        defaultMessage*: string 
        orderBy*: bool
        asField*: string

    # functionType => MIN(min), MAX, SUM, AVE, COUNT, CUSTOM/USER defined
    # fieldNames => specify one field for all except custom/user function,
    # the fieldType must match the argument types expected by the functionType 
    # otherwise the only the first function-matching field will be used, as applicable
    QueryFunction* = object
        functionType*: string
        fieldInfo*: seq[FieldInfo]
        
    QueryParam* = object
        collName: string    # default: "" => will use collName instead
        fieldInfo: seq[FieldInfo]

    SelectFromParam* = object
        collName*: string
        fieldInfo*: seq[FieldInfo]

    InsertIntoParam* = object
        collName*: string
        fieldInfo*: seq[FieldInfo]
   
    # fieldValue(s) are string type for params parsing convenience,
    # fieldValue(s) will be cast by supported fieldType(s), else will through ValueError exception
    # fieldOp: GT, EQ, GTE, LT, LTE, NEQ(<>), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
    # groupOp/groupLinkOp: AND | OR
    # groupCat: user-defined, e.g. "age-policy", "demo-group"
    # groupOrder: user-defined e.g. 1, 2...
    WhereParam* = object
        fieldColl*, fieldName*, fieldOp*, groupOp*, groupCat*, groupLinkOp*: string
        fieldType*: string
        fieldOrder*, groupOrder*: int
        fieldPreOp*: string # NOT operator e.g. NOT <fieldName> <fieldOp> <fieldValue>
        fieldValue*: string     # start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string # end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] # values for IN/NOTIN operator
        fieldPostOp*: string # EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>

    QueryTop* = object          
        topValue: Positive
        topUnit: string # number or percentage (# or %)
    
    OrderParam* = object
        collName: string
        fieldName*: string
        queryFunction*: QueryFunction
        fieldOrderType*: string # "ASC" ("asc") | "DESC" ("desc")
        functionOrderType*: string

    # for aggregate query condition
    HavingParam* = object
        collName: string
        queryFunction*: QueryFunction
        queryOp*: string
        queryOpValue*: string # value will be cast to fieldType in queryFunction
        orderType*: string # "ASC" ("asc") | "DESC" ("desc")
        # subQueryParams*: SubQueryParam # for ANY, ALL, EXISTS...

    SubQueryParam* = object
        whereType*: string   # EXISTS, ANY, ALL
        whereField*: string  # for ANY / ALL | Must match the fieldName in queryParam
        whereOp*: string     # e.g. "=" for ANY / ALL
        queryParams*: QueryParam
        queryWhereParams*: WhereParam

    # combined/joined query (read) param-type
    JoinSelectField* =  object
        collName*: string
        collFields*: seq[FieldInfo]
    
    JoinField* = object
        collName*: string
        joinField*: string

    JoinQueryParam* = object
        selectFromColl*: string # default to collName
        selectFields*: seq[JoinSelectField]
        joinType*: string # INNER (JOIN), OUTER (LEFT, RIGHT & FULL), SELF...
        joinFields*: seq[JoinField] # [{collName: "abc", joinField: "field1" },]
    
     
    SelectIntoParam* = object
        selectFields*: seq[FieldInfo] # @[] => SELECT *
        intoColl*: string          # new table/collection
        fromColl*: string          # old/external table/collection
        fromFilename*: string      # IN external DB file, e.g. backup.mdb
        whereParam*: seq[WhereParam]
        joinParam*: JoinQueryParam # for copying from more than one table/collection

    UnionQueryParam* = object
        selectQueryParams*: seq[QueryParam]
        whereParams*: seq[WhereParam]
        orderParams*: seq[OrderParam]

    GetRecordParam = object
        queryBy*: string # "uid" or "param"
        queryIds*: seq[string]
        queryParams*: seq[QueryParam]

    ## Shared CRUD Operation Types
    ##    
    CrudParam* = ref object
        ## collName: table/collection to insert or update record(s).
        collName*: string   
        ## actionParams: @[{"fieldA": 2345, "fieldB": "abc"}], for create & update.
        ## Field names and corresponding values of record(s) to insert/create or update.
        ## Field-values will be validated based on data model definition.
        ## ValueError exception will be raised for invalid value/data type 
        ##
        actionParams*: seq[Table[string, ValueType]]
        ## Bulk Insert Operation: 
        ## insertToParams {collName: "abc", fieldNames: @["field1", "field2"]}
        ## For collName: "" will use the default constructor collName
        insertIntoParams*: seq[InsertIntoParam]
        ## selectFromParams =
        ## {collName: "abc", fieldNames: @["field1", "field2"]}
        ## the order and types of insertIntoParams' & selectFromParams' fields must match, otherwise ValueError exception will occur
        ## 
        selectFromParams*: seq[SelectFromParam]
        selectIntoParams*: seq[SelectIntoParam]
        ## whereParams = @[{fieldName: "ab", fieldOp: ">=", groupOp: "AND(and)", order: 1, fieldType: "integer", filedValue: "10"},].
        ## The query conditions:
        ## 
        whereParams*: seq[WhereParam]
        ## Read-only params =>
        ## queryParams = @[{collName: "abc", fieldInfo: {fieldName: "abc", show: true}}] | @[] => SELECT * 
        queryParams*: seq[QueryParam]
        subQueryParams*: SubQueryParam
        ## Combined/joined query:
        ## 
        joinQueryParams*: seq[JoinQueryParam]
        unionQueryParams*: seq[UnionQueryParam]
        # existQueryParams*: seq[SubQueryParam] # => subQueryParams
        queryDistinct*: bool
        queryTop*: QueryTop
        # Query function
        queryFunction*: seq[QueryFunction]
        ## orderParams = {"fieldA": "ASC", "fieldC": "DESC"}
        ## An order-param without orderType will default to ASC (ascending-order):
        ## {"fieldP": "" } => orderType = "ASC" (default)
        ## 
        orderParams*: seq[OrderParam]
        groupParams*: seq[string] ## @["fieldA", "fieldB"]
        havingParams*: seq[HavingParam]
        caseParams*: seq[CaseQueryParam] 
        skip*: Positive
        limit*: Positive
        ## Shared / Commmon
        ## 
        auditColl*: string
        accessColl*: string
        serviceColl*: string
        roleColl*: string
        userColl*: string
        appDb*: Database
        accessDb*: Database
        auditDb*: Database
        logAll*: bool
        logRead*: bool
        logCreate*: bool
        logUpdate*: bool
        logDelete*: bool
        mcMessages*: Table[string, string]
        userInfo*: UserParam
        checkAccess*: bool
        transLog*: LogParam 
    
    RoleService* = object
        service*  : string
        group*    : string
        category* : string
        canRead*  : bool
        canCreate*: bool
        canUpdate*: bool
        canDelete*: bool
    
    RoleServices* = ref object
        roleServices*: seq[RoleService]
    
    CheckAccess* = object
        userActive*: bool
        userId*: string
        isAdmin*: bool
        userRole*: string
        userRoles*: seq[string]
        roleServices*: seq[string]
    
    CheckAccessResponse* = ref object
        code*: string
        message*: string
        value*: CheckAccess
  
# default contructor
proc newCrud*(appDb: Database; collName: string; userInfo: UserParam; options: Table[string, ValueType]): CrudParam =
    var defaultTable = initTable[string, JsonNode]()
    
    new result

    result.appDb = appDb
    result.collName = collName
    result.userInfo = userInfo
    # Create/Update
    result.actionParams = options.getOrDefault("actionParams", @[defaultTable])
    result.insertIntoParams = options.getOrDefault("insertIntoParams", @[])
    result.selectFromParams = options.getOrDefault("selectFromParams", @[])
    result.selectIntoParams = options.getOrDefault("selectIntoParams", @[])

    # Read
    result.queryParams = options.getOrDefault("queryParams", @[])
    result.queryFunction = options.getOrDefault("queryFunction", @[])
    result.whereParams = options.getOrDefault("whereParams", @[])
    result.orderParams = options.getOrDefault("orderParams", @[])
    result.groupParams = options.getOrDefault("groupParams", @[])
    result.havingParams = options.getOrDefault("havingParams", @[])
    result.queryDistinct = options.getOrDefault("queryDistinct", false)
    result.queryTop= options.getOrDefault("queryTop", QueryTop())
    result.joinQueryParams = options.getOrDefault("joinQueryParams", @[])
    result.unionQueryParams = options.getOrDefault("unionQueryParams", @[])
    result.caseQueryParams = options.getOrDefault("caseQueryParams", @[])
    result.skip = options.getOrDefault("skip", 0)
    result.limit = options.getOrDefault("limit" ,100000)

    # Shared
    result.auditColl = options.getOrDefault("auditColl", "audits")
    result.accessColl = options.getOrDefault("accessColl", "accesskeys")
    result.auditColl = options.getOrDefault("servicecoll", "services")
    result.roleColl = options.getOrDefault("roleColl", "roles")
    result.userColl = options.getOrDefault("userColl", "users")
    result.auditDb = options.getOrDefault("auditDb", appDb)
    result.accessDb = options.getOrDefault("acessDb", appDb)
    result.logAll = options.getOrDefault("logAll", false)
    result.logRead = options.getOrDefault("logRead", false)
    result.logCreate = options.getOrDefault("logCreate", false)
    result.logUpdate= options.getOrDefault("logUpdate", false)
    result.logDelete = options.getOrDefault("logDelete", false)
    result.checkAccess = options.getOrDefault("checkAccess", true)
    
    result.mcMessages = options.getOrDefault("messages", defaultTable)

    # translog instance
    result.transLog = newLog(result.auditDb, result.auditColl)


proc roleServices*(accessDb: Database; userGroup: string; roleColl: string = "roles") =
    var db:Database = accessDb
    echo db.repr

proc checkAccess*(accessDb: Database, userInfo: UserParam): UserParam =
    var db:Database = accessDb
    echo db.repr
    result = UserParam()

proc getCurrentRecord*(appDb: Database; collName: string; whereParams: WhereParam) =
    echo "get-record"

proc taskPermitted*(appDb: Database; collName: string; recordIds: seq[string]; userInfo: UserParam) =
    # permit task(crud), by owner, role or admin only => on coll/table or doc/record(s)
    echo "task-permission"
