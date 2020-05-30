#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##        CRUD Library - common / extendable base type/class
# 

import db_postgres, json, tables

# Define types
type
    Database = ref object
        db: DbConn
         
    ValueType = int | string | float | bool | Positive | JsonNode | BiggestInt | BiggestFloat | Table | seq | SqlQuery | Database

    UserParam* = object
        name*: string
        age*: Natural

    CrudParam* = ref object
        actionParams*: Table[string, ValueType]
        actionQuery*: SqlQuery
        sortParams*: Table[string, ValueType]
        orderParams*: Table[string, ValueType]
        groupParams*: Table[string, Table[string, ValueType]]
        queryParams*: Table[string, Table[string, ValueType]]
        projectParams*: Table[string, ValueType]
        docIds*: seq[string]
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
        skip*: Positive
        limit*: Positive
        maxQueryLimit*: Positive
        mcMessages*: Table[string, string] 
      
    RequiredParam* = object
        userInfo*: UserParam
        token*: string
        coll*: seq[string]
    
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
proc newCrud*(appDb: Database; params: RequiredParam; options: Table[string, ValueType]): CrudParam =
    var defaultTable = initTable[string, ValueType]
    
    new result
    
    result.appDb = appDb
    result.userInfo = params.userInfo
    result.token = params.token

    result.actionParams = options.getOrDefault("actionParams", defaultTable)
    result.actionQuery = options.getOrDefault("actionQuery", sql"")
    result.queryParams = options.getOrDefault("queryParams", defaultTable)
    result.sortParams = options.getOrDefault("sortParams", defaultTable)
    result.orderParams = options.getOrDefault("orderParams", defaultTable)
    result.groupParams = options.getOrDefault("groupParams", defaultTable)
    result.projectParams = options.getOrDefault("projectParams", defaultTable)
    result.docIds = options.getOrDefault("docIds", @[])
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
    result.skip = options.getOrDefault("skip", 0)
    result.limit = options.getOrDefault("limit" ,100000)
    result.maxQueryLimit = options.getOrDefault("maxQueryLimit", 100000)
    result.mcMessages = options.getOrDefault("messages", defaultTable)

proc roleServices*(accessDb: Database; userGroup: string, roleColl: string = "roles") =
    var db:Database = accessDb
    echo db.repr

proc checkAccess*(accessDb: Database, options: UserParam): UserParam =
    var db:Database = accessDb
    echo db.repr
    result = UserParam()
