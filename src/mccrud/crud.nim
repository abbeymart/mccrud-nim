#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 

##     CRUD Package - common / extendable base constructor & procedures for all CRUD operations
## 

import strutils, times, sequtils
import db_postgres, json, tables
import mcdb, mccache, mcresponse, mctranslog
import helper, crudtypes

export db_postgres, json, tables
export mcdb, mccache, mcresponse, mctranslog
export helper, crudtypes

## Default CRUD contructor returns the instance/object for CRUD task(s)
proc newCrud*(appDb: Database; 
            collName: string; 
            userInfo: UserParam;
            actionParams: seq[QueryParam] = @[];
            queryParams: seq[QueryParam] = @[];
            whereParams: seq[WhereParam] = @[];
            inserIntoParams: seq[InsertIntoParam] = @[];
            selectFromParams: seq[SelectFromParam] = @[];
            selectIntoParams: seq[SelectIntoParam] = @[];
            queryFunctions: seq[QueryFunction] = @[];
            orderParams: seq[OrderParam] = @[];
            groupParams: seq[GroupParam]  = @[];
            havingParams: seq[HavingParam] = @[];
            caseParams: seq[CaseQueryParam]  = @[];
            subQueryParams: seq[SubQueryParam] = @[];
            joinQueryParams: seq[JoinQueryParam] = @[];
            unionQueryParams: seq[UnionQueryParam] = @[];
            queryDistinct: bool = false;
            queryTop: QueryTop = QueryTop();
            skip: Positive = 0;
            limit: Positive = 100000;
            auditColl: string = "audits";
            accessColl: string = "accesskeys";
            serviceColl: string = "services";
            roleColl: string = "roles";
            userColl: string = "users";
            accessDb: Database = appDb;
            auditDb: Database = appDb;
            logAll: bool = false;
            logRead: bool = false;
            logCreate: bool = false;
            logUpdate: bool = false;
            logDelete: bool = false;
            checkAccess: bool = false;
            transLog: LogParam = LogParam(auditDb: auditDb, auditColl: auditColl);
            options: Table[string, ValueType]): CrudParam =
    
    new result

    result.appDb = appDb
    result.collName = collName
    result.userInfo = userInfo
    result.actionParams = actionParams
    result.queryParams = queryParams
   
    # Create/Update
    result.insertIntoParams = inserIntoParams
    result.selectFromParams = selectFromParams
    result.selectIntoParams = selectIntoParams

    # Read
    result.queryFunctions = queryFunctions
    result.whereParams = whereParams
    result.orderParams = orderParams
    result.groupParams = groupParams
    result.havingParams = havingParams
    result.queryDistinct = queryDistinct
    result.queryTop= queryTop
    result.joinQueryParams = joinQueryParams
    result.unionQueryParams = unionQueryParams
    result.caseParams = caseParams
    result.skip = skip
    result.limit = limit

    # Shared
    result.auditColl = auditColl
    result.accessColl = accessColl
    result.auditColl = auditColl
    result.roleColl = roleColl
    result.userColl = userColl
    result.auditDb = auditDb
    result.accessDb = accessDb
    result.logAll = logAll
    result.logRead = logRead
    result.logCreate = logCreate
    result.logUpdate= logUpdate
    result.logDelete = logDelete
    result.checkAccess = checkAccess

    # translog instance
    result.transLog = newLog(result.auditDb, result.auditColl)

## getRoleServices retur the role-service records for the authorized user and transactions
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

        var roleQuery = sql("SELECT service_id, group, category, can_create, can_read, can_update, can_delete FROM " &
                         roleColl & " WHERE group = " & userGroup & " AND service_id IN (" & itemIds & ") " &
                         " AND is_active = true")
        
        let queryResult = accessDb.db.getAllRows(roleQuery)

        if queryResult.len() > 0:           
            for row in queryResult:
                roleServices.add(RoleService(
                    serviceId: row[0],
                    group: row[1],
                    category: row[2],   # coll/table, package_group, package, module, function etc.
                    canCreate: strToBool(row[3]),
                    canRead: strToBool(row[4]),
                    canUpdate: strToBool(row[5]),
                    canDelete: strToBool(row[6])
                ))
        return roleServices
    except:
        return roleServices

## checkAccess validate if current CRUD task is permitted based on defined/assiged roles
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
                            userInfo.id & " AND token = " & userInfo.token &
                            " AND login_name = " & userInfo.loginName)

        let accessRecord = accessDb.db.getRow(accessQuery)

        if accessRecord.len > 0:
            # check expiry date
            if getTime() > strToTime(accessRecord[0]):
                return getResMessage("tokenExpired", ResponseMessage(value: nil, message: "Access expired: please login to continue") )
        else:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: please ensure that you are logged-in") )

        # check current current-user status/info
        let userQuery = sql("SELECT id, default_group, groups, is_active, profile FROM " & userColl &
                            " WHERE id = " & userInfo.id & " AND is_active = true")

        let currentUser = accessDb.db.getRow(userQuery)

        if currentUser.len() < 1:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: user information not found or inactive") )

        # if all the above checks passed, check for role-services access by taskType
        # check access by taskType
        # obtain collName - collId (id) from serviceColl/Table
        var collInfoQuery = sql("SELECT id from " & serviceColl &
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
                                    isAdmin: parseJson(currentUser[4]){"is_dmin"}.getBool(false),
                                    roleServices: roleServices
                                    )

        return getResMessage("success", ResponseMessage(
                                            value: %*(accessRes),
                                            message: "Request completed successfully. ") ) 
    except:
        return getResMessage("notFound", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

## getCurrentRecord returns the current records for the CRUD task
proc getCurrentRecord*(appDb: Database; collName: string; queryParams: QueryParam; whereParams: seq[WhereParam]): ResponseMessage =
    try:
        # compose query statement based on the whereParams
        var selectQuery = computeSelectQuery(collName, queryParams)
        var whereQuery = computeWhereQuery(whereParams)

        var reqQuery = sql(selectQuery & " " & whereQuery)

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

## taskPermission determines if the current CRUD task is permitted
## permission options: by owner, by record/role-assignment, by table/collection or by admin
## 
proc taskPermission*(crud: CrudParam; taskType: string): ResponseMessage =
    # taskType: "create", "update", "delete"/"remove", "read"
    # permit task(crud): by owner, role/group (on coll/table or doc/record(s)) or admin 
    try:
        # validation access variables   
        var taskPermitted, ownerPermitted, recordPermitted, collPermitted, isAdmin: bool = false

        # ownership (i.e. created by userId) for all currentRecords (update/delete...)
        if crud.docIds.len() > 0:
            var selectQuery = "SELECT id, created_by, updated_by, created_date, updated_date FROM "
            selectQuery.add(crud.collName)
            selectQuery.add(" ")
            var whereQuery= " WHERE id IN ("
            whereQuery.add(crud.docIds.join(", "))
            whereQuery.add(" AND ")
            whereQuery.add("created_by = ")
            whereQuery.add(crud.userInfo.id)
            whereQuery.add(" ")    

            var reqQuery = sql(selectQuery & " " & whereQuery)

            var ownedRecs = crud.appDb.db.getAllRows(reqQuery)
            if ownedRecs.len() == crud.docIds.len():
                ownerPermitted = true    

        # check role-based access
        var accessRes = checkAccess(accessDb = crud.accessDb, collName = crud.collName,
                                    docIds = crud.docIds, userInfo = crud.userInfo )
        if accessRes.code == "success":
            # get access info value (json) => toObject
            let accessInfo = to(accessRes.value, CheckAccess)

            isAdmin = accessInfo.isActive
            let
                # userId = accessInfo.userId
                # userRole = accessInfo.userRole
                # userRoles = accessInfo.userRoles
                isActive = accessInfo.isActive
                roleServices = accessInfo.roleServices # TODO: check value: object or parsed-json (transform to object)

            # validate active status
            if not isActive:
                return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Your account is not active"))

            # filter the roleServices by categories ("collection | table" and "record or document") 
            proc tableFunc(item: RoleService): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table")

            proc recordFunc(item: RoleService): bool = 
                    (item.category.toLower() == "record" or item.category.toLower() == "document")
                
            let roleTables = roleServices.filter(tableFunc)
            let roleRecords = roleServices.filter(recordFunc)

            # taskType specific permission(s)
            case taskType:
            of "create", "insert":
                proc collFunc(item: RoleService): bool = 
                    item.canCreate
                # collection/table level access | only collName Id was included in serviceIds
                collPermitted = roleTables.allIt(collFunc(it))

            of "update":
                proc collFunc(item: RoleService): bool = 
                    item.canUpdate
                # collection/table level access
                collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canUpdate)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))
            of "delete", "remove":
                proc collFunc(item: RoleService): bool = 
                    item.canDelete
                # collection/table level access
                collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canDelete)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))
            of "read", "search":
                echo "check-create"
                proc collFunc(item: RoleService): bool = 
                    item.canRead
                # collection/table level access
                collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access
                proc recRoleFunc(it1: string; it2: RoleService): bool = 
                    (it2.service_id == it1 and it2.canRead)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))

        # overall access permitted
        taskPermitted = recordPermitted or collPermitted or ownerPermitted or isAdmin
        let ok = OkayResponse(ok: taskPermitted)
        if taskPermitted:
            let response  = ResponseMessage(value: %*(ok),
                                            message: "action authorised / permitted")
            result = getResMessage("success", response)
        else:
            let ok = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(ok), message: "You are not authorized to perform the requested action/task"))
    except:
        let ok = OkayResponse(ok: false)
        return getResMessage("unAuthorized", ResponseMessage(value: %*(ok), message: getCurrentExceptionMsg()))
    