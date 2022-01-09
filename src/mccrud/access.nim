#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 

##     CRUD Package - common / extendable base constructor & procedures for all CRUD operations
## 

import strutils, times, sequtils
import db_postgres, json
import mcdb, mcresponse
import ../crudtypes
import ./computeSelect, ./computeWhere, ./utils

## getRoleServices returns the role-service records for the authorized user and transactions
proc getRoleServices*(
                    accessDb: Database;
                    userGroup: string;
                    serviceIds: seq[string];   # for any tasks (record, coll/table, function, package, solution...)
                    roleTable: string = "roles";
                    ): seq[RoleServiceType] =
    var roleServices: seq[RoleServiceType] = @[]
    try:
        #  concatenate serviceIds for query computation:
        let itemIds = serviceIds.join(", ")

        var roleQuery = sql("SELECT service_id, group, category, can_create, can_read, can_update, can_delete FROM " &
                         roleTable & " WHERE group = " & userGroup & " AND service_id IN (" & itemIds & ") " &
                         " AND is_active = true")
        
        let queryResult = accessDb.db.getAllRows(roleQuery)

        if queryResult.len() > 0:           
            for row in queryResult:
                roleServices.add(RoleServiceType(
                    serviceId: row[0],
                    group: row[1],
                    category: row[2],   # coll/table, package_group, package, module, function etc.
                    canCreate: strToBool(row[3]),
                    canRead: strToBool(row[4]),
                    canUpdate: strToBool(row[5]),
                    canDelete: strToBool(row[6]),
                ))
        return roleServices
    except:
        return roleServices

## checkAccess validate if current CRUD task is permitted based on defined/assiged roles
proc checkAccess*(
                accessDb: Database;
                userInfo: UserParamType;
                tableName: string;
                docIds: seq[string] = @[];    # for update, delete and read tasks 
                accessTable: string = "accesskeys";
                userTable: string = "users";
                roleTable: string = "roles";
                serviceTable: string = "services";
                ): ResponseMessage =
    # validate current user active status: by token (API) and user/loggedIn-status
    try:
        # check active login session
        let accessQuery = sql("SELECT expire, user_id FROM " & accessTable & " WHERE user_id = " &
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
        let userQuery = sql("SELECT id, active_group, groups, is_active, is_admin, profile FROM " & userTable &
                            " WHERE id = " & userInfo.id & " AND is_active = true")

        let currentUser = accessDb.db.getRow(userQuery)

        if currentUser.len() < 1:
            return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Unauthorized: user information not found or inactive") )

        # if all the above checks passed, check for role-services access by taskType
        # obtain tableName - collId (id) from serviceTable/Table (holds all accessible resources)
        var collInfoQuery = sql("SELECT id from " & serviceTable &
                                " WHERE name = " & tableName )

        let collInfo = accessDb.db.getRow(collInfoQuery)
        var collId = ""

        # if permitted, include collId and docIds in serviceIds
        var serviceIds = docIds
        if collInfo.len() > 0:
            collId = collInfo[0]
            serviceIds.add(collInfo[0])

        # Get role assignment (i.e. service items permitted for the user-group)
        var roleServices: seq[RoleServiceType] = @[]
        if serviceIds.len() > 0:
            roleServices = getRoleServices(accessDb = accessDb,
                                        serviceIds = serviceIds,
                                        userGroup = currentUser[1],
                                        roleTable = roleTable)
        # userRoles: {roles: ["cd", "ef", "gh"]}
        # TODO: check/validate parseJson result of the currentUser jsonb string value
        let accessRes = CheckAccess(userId: currentUser[0],
                                    group: currentUser[1],
                                    groups: strToSeq(currentUser[2]),
                                    isActive: strToBool(currentUser[3]),
                                    isAdmin: strToBool(currentUser[4]),
                                    roleServices: roleServices,
                                    collId: collId
                                    )

        return getResMessage("success", ResponseMessage(
                                            value: %*(accessRes),
                                            message: "Request completed successfully. ") ) 
    except:
        return getResMessage("notFound", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

## getCurrentRecord returns the current records for the CRUD task
proc getCurrentRecord*(appDb: Database; tableName: string; queryParams: QueryParamType; whereParams: seq[WhereParamType]): ResponseMessage =
    try:
        # compose query statement based on the whereParams
        var selectQuery = computeSelectQuery(tableName, queryParams)
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
proc taskPermission*(crud: CrudParamType; taskType: string): ResponseMessage =
    # taskType: "create", "update", "delete"/"remove", "read"
    # permit task(crud): by owner, role/group (on coll/table or doc/record(s)) or admin 
    try:
        # validation access variables   
        var taskPermitted, ownerPermitted, recordPermitted, collPermitted, isAdmin: bool = false

        # check role-based access
        var accessRes = checkAccess(accessDb = crud.accessDb, tableName = crud.tableName,
                                    docIds = crud.docIds, userInfo = crud.userInfo )
        var accessInfo: CheckAccess
        
        if accessRes.code == "success":
            # get access info value (json) => toObject
            accessInfo = to(accessRes.value, CheckAccess)
            # accessInfo = to[CheckAccess]($$accessRes.value) ## required marshal module

            # ownership (i.e. created by userId) for all currentRecords (update/delete...)
            let accessUserId = accessInfo.userId
            if crud.docIds.len() > 0 and accessUserId != "":
                var selectQuery = "SELECT id, createdby, updatedby, createdat, updatedat FROM "
                selectQuery.add(crud.tableName)
                selectQuery.add(" ")
                var whereQuery= " WHERE id IN ("
                whereQuery.add(crud.docIds.join(", "))
                whereQuery.add(" AND ")
                whereQuery.add("createdby = ")
                whereQuery.add(accessUserId)
                whereQuery.add(" ")    

                var reqQuery = sql(selectQuery & " " & whereQuery)

                var ownedRecs = crud.appDb.db.getAllRows(reqQuery)
                # ensure all records are owned by the current user (re: accessUserId)
                if ownedRecs.len() == crud.docIds.len():
                    ownerPermitted = true    

            isAdmin = accessInfo.isAdmin
            let
                # userId = accessInfo.userId
                # userRole = accessInfo.userRole
                # userRoles = accessInfo.userRoles
                isActive = accessInfo.isActive
                roleServices = accessInfo.roleServices

            # validate active status
            if not isActive:
                return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "Your account is not active"))

            # validate roleServices permission
            if roleServices.len < 1:
                return getResMessage("unAuthorized", ResponseMessage(value: nil, message: "You are not authorized to perform the requested action/task"))

            # filter the roleServices by categories ("collection | table" and "record or document") 
            proc tableFunc(item: RoleServiceType): bool = 
                    (item.category.toLower() == "collection" or item.category.toLower() == "table")

            proc recordFunc(item: RoleServiceType): bool = 
                    (item.category.toLower() == "record" or item.category.toLower() == "document")
                
            let roleTables = roleServices.filter(tableFunc)
            let roleRecords = roleServices.filter(recordFunc)

            # taskType specific permission(s)
            case taskType:
            of "create", "insert":
                proc collFunc(item: RoleServiceType): bool = 
                    item.canCreate
                # collection/table level access | only tableName Id was included in serviceIds
                if roleTables.len > 0:
                    collPermitted = roleTables.allIt(collFunc(it))
            of "update":
                proc collFunc(item: RoleServiceType): bool = 
                    item.canUpdate
                # collection/table level access
                if roleTables.len > 0:
                    collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access: all docIds must have at least a match in the roleRecords
                proc recRoleFunc(it1: string; it2: RoleServiceType): bool = 
                    (it2.service_id == it1 and it2.canUpdate)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))
            of "delete", "remove":
                proc collFunc(item: RoleServiceType): bool = 
                    item.canDelete
                # collection/table level access
                if roleTables.len > 0:
                    collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access: all docIds must have at least a match in the roleRecords
                proc recRoleFunc(it1: string; it2: RoleServiceType): bool = 
                    (it2.service_id == it1 and it2.canDelete)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))
            of "read", "search":
                proc collFunc(item: RoleServiceType): bool = 
                    item.canRead
                # collection/table level access
                if roleTables.len > 0:
                    collPermitted = roleTables.allIt(collFunc(it))
                # document/record level access: all docIds must have at least a match in the roleRecords
                proc recRoleFunc(it1: string; it2: RoleServiceType): bool = 
                    (it2.service_id == it1 and it2.canRead)

                proc recFunc(it1: string): bool =
                    roleRecords.anyIt(recRoleFunc(it1, it))
                
                if crud.docIds.len > 0:
                    recordPermitted = crud.docIds.allIt(recFunc(it))
            else:
                let ok = OkayResponse(ok: false)
                return getResMessage("unAuthorized", ResponseMessage(value: %*(ok), message: "Unknown access type or access type not specified"))
        else:
            let ok = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(ok), message: "You are not authorized to perform the requested action/task"))
        
        # overall access permitted
        taskPermitted = recordPermitted or collPermitted or ownerPermitted or isAdmin
        # let ok = OkayResponse(ok: taskPermitted)
        if taskPermitted:
            var accessResult = PermissionType(ok: taskPermitted, accessInfo: accessInfo)
            let response  = ResponseMessage(value: %*(accessResult),
                                            message: "action authorised / permitted")
            result = getResMessage("success", response)
        else:
            var accessResult = PermissionType(ok: taskPermitted, accessInfo: accessInfo)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(accessResult), message: "You are not authorized to perform the requested action/task"))
    except:
        let ok = OkayResponse(ok: false)
        return getResMessage("unAuthorized", ResponseMessage(value: %*(ok), message: getCurrentExceptionMsg()))
    