#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##       CRUD Library - common / extendable base type/class
# 

import db_postgres, json, tables
import mcdb, mccache, mcresponse, mctranslog

export db_postgres, json, tables
export mcdb, mccache, mcresponse, mctranslog

# Define types
type
    Database = ref object
        db: DbConn
         
    ValueType* = int | string | float | bool | Positive | JsonNode | BiggestInt | BiggestFloat | Table | seq | SqlQuery | Database

    UserParam* = object
        uid*: string
        username*: string
        email*: string
        token*: string

    # value are string type for params parsing convenience,
    # values will be cast by fieldType, else will through ValueError exception
    FieldValue* = object
        fieldType: string
        fieldValue: string

    # functionType => MIN(min), MAX, SUM, AVE, COUNT, CUSTOM/USER
    # fieldNames => specify one field for all except custom/user function, 
    # otherwise the only the first function-matching field will be used, as applicable
    QueryFunction* = object
        functionType: string    
        fieldNames: seq[string] 
    
    ProjectParam* = object
        fieldName*: string
        fieldAlias*: string # field name alias
        show*: bool         # for mongoDB, ignore for Postgres, MySQL & SQLite

    OrderParam* = object
        fieldName*: string
        orderType*: string   # ASC | DESC (asc | desc)

    SubQueryParam* = object
        collName*: string
        fieldNames*: seq[string]

    # fieldValue(s) are string type for params parsing convenience,
    # fieldValue(s) will be cast by fieldType, else will through ValueError exception
    # fieldOp: >, =, >=, <, <=, BETWEEN, IN, QueryFunction etc., with matching specified params
    WhereParam* = object
        fieldName*, fieldType*, fieldOp*, groupOp*, groupCat*: string
        order*: int
        fieldValue*: string     # start value for range/BETWEEN operator
        fieldValueEnd*: string # end value for range/BETWEEN operator
        fieldValues*: seq[string] # values for IN operator
       
    CrudParam* = ref object
        collName*: string   # table/collection to insert or update record(s)
        ## actionParams = @[{"fieldA": 2345, "fieldB": "abc"}], for create & update
        ## field names and corresponding values of record(s) to insert/create or update
        ##
        actionParams*: seq[Table[string, ValueType]]
        ## whereParams = @[{fieldName: "ab", fieldOp: ">=", groupOp: "AND(and)", order: 1, fieldType: "integer", filedValue: "10"},]
        ## the query conditions
        ## 
        whereParams*: seq[WhereParam]
        ## Read-only params =>
        ## projectParams = @[{fieldName: "abc", show: true}] | @[] => SELECT * 
        projectParams*: seq[ProjectParam]
        ## subQueryParams = @[{"collName": "services", }]
        subQueryParams*: seq[SubQueryParam]
        queryDistinct*: bool
        queryTop*: bool
        queryFunction*: seq[QueryFunction]
        ## orderParams = @[{"fieldName": "fieldA", "orderType": "ASC"}, {"fieldName": "fieldC", "orderType": "DESC"}]
        ## An order-param without orderType will default to ASC (ascending-order):
        ## {"fieldName": "fieldP", } => orderType = "ASC" (default)
        ## 
        orderParams*: seq[OrderParam]
        groupParams*: seq[string] ## @["fieldA", "fieldB"]
        skip*: Positive
        limit*: Positive
        ## Update, Read & Delete
        docIds*: seq[string]
        ## Shared / Commmon
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
    
    RoleService = object
        service*  : string
        group*    : string
        category* : string
        canRead*  : bool
        canCreate*: bool
        canUpdate*: bool
        canDelete*: bool
    
    RoleServices = ref object
        roleServices*: seq[RoleService]
    
    CheckAccess = object
        userActive*: bool
        userId*: string
        isAdmin*: bool
        userRole*: string
        userRoles*: seq[string]
        roleServices*: seq[string]
    
    CheckAccessResponse = ref object
        code*: string
        message*: string
        value*: CheckAccess
  
# default contructor
proc newCrud*(appDb: Database; collName: string; userInfo: UserParam; options: Table[string, ValueType]): CrudParam =
    # var defaultParams = initTable[string, ValueType]()
    var defaultTable = initTable[string, ValueType]()
    
    new result

    result.appDb = appDb
    result.collName = collName
    result.userInfo = userInfo
    # Create/Update
    result.actionParams = options.getOrDefault("actionParams", @[defaultTable])
    
    # Read
    result.projectParams = options.getOrDefault("projectParams", @[ProjectParam()])
    result.whereParams = options.getOrDefault("whereParams", @[WhereParam()])
    result.orderParams = options.getOrDefault("orderParams", @[])
    result.groupParams = options.getOrDefault("groupParams", @[])
    result.queryDistinct = options.getOrDefault("queryDistinct", false)
    result.queryTop= options.getOrDefault("queryTop", false)
    result.subQueryParams = options.getOrDefault("subQueryParams", @[])
    result.queryFunction = options.getOrDefault("queryFunction", @[])
    result.skip = options.getOrDefault("skip", 0)
    result.limit = options.getOrDefault("limit" ,100000)
    
    # Read, Update & Delete
    result.docIds = options.getOrDefault("docIds", @[])

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

proc checkAccess*(accessDb: Database, options: UserParam): UserParam =
    var db:Database = accessDb
    echo db.repr
    result = UserParam()

proc getCurrentRecord*() =
    echo "save-record"

proc taskPermitted*() =
    echo "save-record"
