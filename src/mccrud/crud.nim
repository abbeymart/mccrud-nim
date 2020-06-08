#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##     CRUD Package - common / extendable base type/constructor & procedures
# 

import strutils, times
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
        loginName*: string
        email*: string
        token*: string

    # fieldValue(s) are string type for params parsing convenience,
    # fieldValue(s) will be cast by supported fieldType(s), else will through ValueError exception
    # fieldOp: GT, EQ, GTE, LT, LTE, NEQ(<>), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
    # groupOp/groupLinkOp: AND | OR
    # groupCat: user-defined, e.g. "age-policy", "demo-group"
    # groupOrder: user-defined e.g. 1, 2...
    FieldInfo* = object
        fieldColl*: string
        fieldName*: string
        fieldType*: string   # "int", "string", "bool", "boolean", "float",...
        fieldOrder*: string
        fieldOp*: string     # NOT operator e.g. NOT <fieldName> <fieldOp> <fieldValue>
        fieldValue*: string  # for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   # end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] # values for IN/NOTIN operator
        fieldPostOp*: string # EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     # e.g. AND | OR...
        fieldAlias*: string # for SELECT/Read query
        show*: bool     # for mongoDB, ignore for Postgres, MySQL & SQLite
        fieldFunction*: string # COUNT, MIN, MAX... for select/read-query...

    WhereParam* = object
        groupCat*: string
        groupLinkOp*: string
        groupOrder*: int
        groupItems*: seq[FieldInfo]
  
    QueryTop* = object          
        topValue: Positive
        topUnit: string # number or percentage (# or %)
    
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

    # GetRecordParam = object
    #     queryBy*: string # "uid" or "param"
    #     queryIds*: seq[string]
    #     queryParams*: seq[QueryParam]

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
    
    CheckAccess* = object
        userId*: string
        userRole*: string
        userRoles*: JsonNode
        isActive*: bool
        isAdmin*: bool
        roleServices*: seq[RoleService]

# helper procedures | # TODO: move to mcutils package
proc strToBool*(val: string): bool =
    try:
        if val.toLowerAscii == "true":
            return true
        if val.toLowerAscii == "t":
            return true
        elif val.toLowerAscii == "yes":
            return true
        elif val.toLowerAscii == "y":
            return true
        elif val.parseInt > 0:
            return true
        else:
            return false 
    except:
        return false

proc strToTime*(val: string): Time =
    try:
        result = fromUnix(val.parseInt)
    except:
        return Time()

proc computeWhereQuery(whereParams: seq[WhereParam]): string =
    echo "where-query"

    var composeTab = initTable[string, string]()

    # sort whereParams by groupOrder (ASC)

    # iterate through whereParams
        # set initial table value for the group

        # sort groupCat items by fieldOrder (ASC)

        # compute the field-where-script

        # compute group-script: append field-script by fieldOrder into the group-table value
       
    # iterate through the composeTable/group-scripts
    # compute where-script from the group-script, append in sequence by groupOrder 


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

proc getRoleServices*(accessDb: Database; userGroup: string; roleColl: string = "roles"): seq[RoleService] =
    var roleServices: seq[RoleService] = @[]
    try:
        var roleQuery = sql("SELECT service, group, category, can_create, can_update, can_read, can_delete FROM " &
                         roleColl & " WHERE group = " & userGroup & " AND is_active = true")
        
        let queryResult = accessDb.db.getAllRows(roleQuery)

        for row in queryResult:
            roleServices.add(RoleService(
                service: row[0],
                group: row[1],
                category: row[2],
                canRead: strToBool(row[3]),
                canCreate: strToBool(row[4]),
                canUpdate: strToBool(row[5]),
                canDelete: strToBool(row[6])
            ))

        return roleServices
    except:
        return roleServices

proc checkAccess*(
                accessDb: Database; 
                collName: string;
                recordIds: seq[string];
                userInfo: UserParam; 
                accessColl: string = "accesskeys";
                userColl: string = "users"; 
                roleColl: string = "roles";): ResponseMessage =
    
    # validate current user active status: by token (API) and user/loggedIn-status
    var
        isActive   = false
        userId       = ""
        isAdmin      = false
        userRole     = ""
        userRoles: JsonNode    = nil
        roleServices: seq[RoleService] = @[]
        currentUser: Row  = @[]
        accessRecord: Row = @[]
    
    try:
        var accessQuery = sql("SELECT expire, user_id FROM " & accessColl & " WHERE user_id = " &
                            userInfo.uid & " AND token = " & userInfo.token &
                            " AND login_name = " & userInfo.loginName)

        accessRecord = accessDb.db.getRow(accessQuery)

        if accessRecord.len > 0:
            # check expiry date
            if getTime() > strToTime(accessRecord[0]):
                return getResMessage("tokenExpired", ResponseMessage(value: nil, message: "Access expired: please login to continue") )
        else:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: please ensure that you are logged-in") )

        # current-user status/info
        var userQuery = sql("SELECT uid, default_group, groups, is_active, profile FROM " & userColl &
                            " WHERE uid = " & userInfo.uid & " AND is_active = true")

        currentUser = accessDb.db.getRow(userQuery)

        if currentUser.len > 0:
            # Get role assignment (i.e. service items permitted for the user-group)
            roleServices = getRoleServices(accessDb, currentUser[1], roleColl)

            # Extract the info from currentUser
            userId     = currentUser[0]
            userRole   = currentUser[1]
            userRoles  = parseJson(currentUser[2])
            isActive   = bool(currentUser[3].parseInt)
            isAdmin    = parseJson(currentUser[4]){"isAdmin"}.getBool(false)

            let accessRes = CheckAccess(userId: currentUser[0],
                                    userRole: currentUser[1],
                                    userRoles: parseJson(currentUser[2]),
                                    isActive: strToBool(currentUser[3]),
                                    isAdmin: parseJson(currentUser[4]){"isAdmin"}.getBool(false),
                                    roleServices: roleServices
                                    )
            return getResMessage("success", ResponseMessage(
                                            value: %*(accessRes), 
                                            message: "Request completed successfully. ") )
        else:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: user information not found or inactive") )
    except:
        return getResMessage("notFound", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc getCurrentRecord*(appDb: Database; collName: string; whereParams: seq[WhereParam]): ResponseMessage =
    try:
        # TODO: compose query statement based on the whereParams
        var whereQuery = computeWhereQuery(whereParams)

        var reqQuery = sql("SELECT * FROM " & collName & " " & whereQuery)

        var reqResult = appDb.db.getAllRows(reqQuery)

        var response  = ResponseMessage(value: %*(reqResult),
                                        message: "records retrieved successfuly",
                                        code: "success"
                        )
        result = getResMessage("success", response)
    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc createPermitted*(appDb: Database; 
                    collName: string;
                    recordIds: seq[string];
                    userInfo: UserParam;
                    roleColl: string = "roles"; 
                    serviceColl: string = "services";): ResponseMessage =
    # permit task(crud), by owner, role or admin only => on coll/table or doc/record(s)
    
    echo "task-permission"
    var db:Database = appDb
    echo db.repr
    var response  = ResponseMessage(value: nil,
                                    message: "records retrieved successfuly",
                                    code: "success"
                    )
    result = getResMessage("success", response)

proc updatePermitted*(appDb: Database;
                    collName: string;
                    recordIds: seq[string];
                    userInfo: UserParam;
                    roleColl: string = "roles"; 
                    serviceColl: string = "services";): ResponseMessage =
    # permit task(crud), by owner, role or admin only => on coll/table or doc/record(s)
    try:
        echo "task-permission"
        var db:Database = appDb
        echo db.repr

        var recordRolePermitted, tableRolePermitted: bool = false

        # table/collection level permission
        let tableQuery = sql("SELECT * FROM ")

        var response  = ResponseMessage(value: nil,
                                    message: "records retrieved successfuly",
                                    code: "success"
                    )
        result = getResMessage("success", response)

        # record(s) level permission

        # record(s) owner's permissions


    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))
