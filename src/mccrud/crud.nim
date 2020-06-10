#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##     CRUD Package - common / extendable base type/constructor & procedures
# 

import strutils, times, algorithm
import sequtils
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
        fieldOp*: string    # GT/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        # fieldPreOp*: string     # NOT operator e.g. NOT <fieldName> <fieldOp> <fieldValue>
        fieldValue*: string  # for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   # end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] # values for IN/NOTIN operator
        fieldPostOp*: string # EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     # e.g. AND | OR...
        fieldAlias*: string # for SELECT/Read query
        show*: bool     # include or exclude from the SELECT query fields
        fieldFunction*: string # COUNT, MIN, MAX... for select/read-query...

    WhereParam* = object
        groupCat*: string
        groupLinkOp*: string
        groupOrder*: int
        groupItems*: seq[FieldInfo]

    # functionType => MIN(min), MAX, SUM, AVE, COUNT, CUSTOM/USER defined
    # fieldNames => specify one field for all except custom/user function,
    # the fieldType must match the argument types expected by the functionType 
    # otherwise the only the first function-matching field will be used, as applicable
    QueryFunction* = object
        functionType*: string
        fieldInfo*: seq[FieldInfo]
        
    QueryParam* = object
        collName: string    # default: "" => will use collName instead
        fieldInfo: seq[FieldInfo]   # @[] => SELECT * (all fields)

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
        serviceId*  : string
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
        if val.toLower() == "true":
            return true
        if val.toLower() == "t":
            return true
        elif val.toLower() == "yes":
            return true
        elif val.toLower() == "y":
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

proc computeWhereQuery*(whereParams: seq[WhereParam]): string =
    # initialize variable to compose where-query
    var whereQuery = "WHERE "

    # sort whereParams by groupOrder (ASC)
    var sortedGroups  = whereParams.sortedByIt(it.groupOrder)
    let groupsLen = sortedGroups.len()

    # variables to determine the end of groups and group-items
    var groupCount, itemCount = 0

    # iterate through whereParams (groups)
    for group in sortedGroups:
        groupCount += 1

        # sort groupCat items by fieldOrder (ASC)
        var sortedItems  = group.groupItems.sortedByIt(it.fieldOrder)
        let itemsLen = sortedItems.len()

        # compute the field-where-script
        var fieldQuery = "("
        for groupItem in sortedItems:
            itemCount += 1
            var fieldname = groupItem.fieldName
            if groupItem.fieldColl != "":
                fieldname = groupItem.fieldColl & "." & groupItem.fieldName

            case groupItem.fieldOp.toLower():
            of "eq", "=":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & fieldname & " = " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
                    else:
                        fieldQuery = fieldQuery & " "
            of "neq", "!=", "<>":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & " NOT " & fieldname & " = " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
                    else:
                        fieldQuery = fieldQuery & " "
            of "lt", "<":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & fieldname & " < " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
            of "lte", "<=":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & fieldname & " <= " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
                    else:
                        fieldQuery = fieldQuery & " "
            of "gte", ">=":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & fieldname & " >= " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
                    else:
                        fieldQuery = fieldQuery & " "
            of "gt", ">":
                if groupItem.fieldValue != "":
                    fieldQuery = " " & fieldQuery & fieldname & " > " & groupItem.fieldValue
                if groupItem.groupOp != "":
                    if itemCount < itemsLen:
                        fieldQuery = fieldQuery & " " & groupItem.groupOp
                    else:
                        fieldQuery = fieldQuery & " "

        # add closing bracket to complete the group-items query/script
        fieldQuery = fieldQuery & " )"
        
        # add optional groupLinkOp, if groupLen > 1
        if groupCount < groupsLen and group.groupLinkOp != "":
            fieldQuery = fieldQuery & " " & group.groupLinkOp.toUpperAscii() & " "
        elif groupCount < groupsLen and group.groupLinkOp == "":
            fieldQuery = fieldQuery & " AND "   # default groupLinkOp => AND
        else:
            fieldQuery = fieldQuery & " "
            
        # compute where-script from the group-script, append in sequence by groupOrder 
        whereQuery = whereQuery & " " & fieldQuery

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

proc getRoleServices*(
                    accessDb: Database;
                    userGroup: string;
                    serviceIds: seq[string];   # for any tasks (record, coll/table, function...)
                    roleColl: string = "roles"
                    ): seq[RoleService] =
    var roleServices: seq[RoleService] = @[]
    try:
        #  concatenate serviceIds for query computation:
        let itemIds = serviceIds.join(", ")

        var roleQuery = sql("SELECT service_id, group, category, can_create, can_update, can_read, can_delete FROM " &
                         roleColl & " WHERE group = " & userGroup & " AND service_id IN (" & itemIds & ") " &
                         " AND is_active = true")
        
        let queryResult = accessDb.db.getAllRows(roleQuery)

        if queryResult.len() > 0:           
            for row in queryResult:
                roleServices.add(RoleService(
                    serviceId: row[0],
                    group: row[1],
                    category: row[2],   # coll/table, package_group, package, module, function etc.
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
                userInfo: UserParam;
                collName: string;
                docIds: seq[string] = @[];    # for update, delete and read tasks 
                accessColl: string = "accesskeys";
                userColl: string = "users";
                roleColl: string = "roles";
                serviceColl: string = "services";
                ): ResponseMessage =
    # validate current user active status: by token (API) and user/loggedIn-status
    try:
        # check active login session
        let accessQuery = sql("SELECT expire, user_id FROM " & accessColl & " WHERE user_id = " &
                            userInfo.uid & " AND token = " & userInfo.token &
                            " AND login_name = " & userInfo.loginName)

        let accessRecord = accessDb.db.getRow(accessQuery)

        if accessRecord.len > 0:
            # check expiry date
            if getTime() > strToTime(accessRecord[0]):
                return getResMessage("tokenExpired", ResponseMessage(value: nil, message: "Access expired: please login to continue") )
        else:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: please ensure that you are logged-in") )

        # check current current-user status/info
        let userQuery = sql("SELECT uid, default_group, groups, is_active, profile FROM " & userColl &
                            " WHERE uid = " & userInfo.uid & " AND is_active = true")

        let currentUser = accessDb.db.getRow(userQuery)

        if currentUser.len() < 1:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: user information not found or inactive") )

        # if all the above checks passed, check for role-services access by taskType
        # check access by taskType
        # obtain collName - collId (uid) from serviceColl/table
        var collInfoQuery = sql("SELECT uid from " & serviceColl &
                                " WHERE name = " & collName )

        let collInfo = accessDb.db.getRow(collInfoQuery)

        # include collId and docIds in serviceIds
        var serviceIds = docIds
        if collInfo.len() > 0:
            serviceIds.add(collInfo[0])

        # Get role assignment (i.e. service items permitted for the user-group)
        var roleServices: seq[RoleService] = @[]
        if serviceIds.len() > 0:
            roleServices = getRoleServices(accessDb = accessDb,
                                        serviceIds = serviceIds,
                                        userGroup = currentUser[1],
                                        roleColl = roleColl)
        
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
    except:
        return getResMessage("notFound", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc getCurrentRecord*(appDb: Database; collName: string; whereParams: seq[WhereParam]): ResponseMessage =
    try:
        # compose query statement based on the whereParams
        var whereQuery = computeWhereQuery(whereParams)

        var reqQuery = sql("SELECT * FROM " & collName & " " & whereQuery)

        var reqResult = appDb.db.getAllRows(reqQuery)

        if reqResult.len() > 0:
            var response  = ResponseMessage(value: %*(reqResult),
                                        message: "Records retrieved successfuly.",
                                        code: "success")
            return getResMessage("success", response)
        else:
            return getResMessage("notFound", ResponseMessage(value: nil, message: "No record(s) found!"))
    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc taskPermission*(accessRes: ResponseMessage;
                    taskType: string;   # "create", "update", "delete"/"remove", "read"
                    docIds: seq[string] = @[];
                    ): ResponseMessage =
    # permit task(crud): by owner, role/group, admin => on coll/table or doc/record(s)
    try:
        if accessRes.code == "success":
            # get access info value (json) => toObject
            let accessInfo = to(accessRes.value, CheckAccess)

            let
                # userId = accessInfo.userId
                # userRole = accessInfo.userRole
                # userRoles = accessInfo.userRoles
                isActive = accessInfo.isActive
                isAdmin = accessInfo.isActive
                roleServices = accessInfo.roleServices

            # validate active status
            if isActive:
                return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Your account is not active"))

            # validate access   
            var taskPermitted, recordPermitted, collPermitted: bool = false

            # table/collection level permission
            # let tableQuery = sql("SELECT * FROM ")

            case taskType:
            of "create", "insert":
                proc collFunc(item: RoleService): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table") and (item.canCreate == true)
                # check collection/table level access
                collPermitted = roleServices.anyIt(collFunc(it))
            
                # ownership (i.e. created by userId) for all currentRecords (update/delete...)
                # var currentRecs: seq[string] = @[]
                
            of "update":
                echo "check-create"
                proc collFunc(item: RoleService): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table") and (item.canUpdate == true)
                # check collection/table level access
                collPermitted = roleServices.anyIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canUpdate == true)

                proc recFunc(it1: string): bool =
                    roleServices.anyIt(recRoleFunc(it1, it))
                
                if docIds.len > 0:
                    recordPermitted = docIds.allIt(recFunc(it))
            of "delete", "remove":
                echo "check-create"
                proc collFunc(item: RoleService): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table") and (item.canDelete == true)
                # check collection/table level access
                collPermitted = roleServices.anyIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canDelete == true)

                proc recFunc(it1: string): bool =
                    roleServices.anyIt(recRoleFunc(it1, it))
                
                if docIds.len > 0:
                    recordPermitted = docIds.allIt(recFunc(it))
            of "read", "search":
                echo "check-create"
                proc collFunc(item: RoleService): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table") and (item.canRead == true)
                # check collection/table level access
                collPermitted = roleServices.anyIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canRead == true)

                proc recFunc(it1: string): bool =
                    roleServices.anyIt(recRoleFunc(it1, it))
                
                if docIds.len > 0:
                    recordPermitted = docIds.allIt(recFunc(it))

            # overall access permitted
            taskPermitted = recordPermitted or collPermitted or isAdmin

            if taskPermitted:
                let response  = ResponseMessage(value: %*(taskPermitted),
                                            message: "action authorised / permitted")
                result = getResMessage("success", response)
            else:
                return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "You are not authorized to perform the requested action/task"))
        else:
            echo "error"
        
    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))
