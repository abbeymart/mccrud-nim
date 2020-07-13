#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#             CRUD Package - get record(s)
# 

## get-record procedure is for fetching records by role (access-control)
## 
import crud, sequtils

# constructor
## get-record operations constructor
proc newGetRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    checkAccess: bool = true;
                    whereParams: seq[WhereParam] = @[];
                    docIds: seq[string] = @[];
                    fields: seq[string] = @[]; 
                    options: Table[string, ValueType] = []): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, whereParams = whereParams, docIds = docIds, options = options )
  
proc getAllRecords*(crud: CrudParam; fields: seq[string] = @[]): ResponseMessage =  
    try:
        # ensure that checkAccess is false, otherwise send unauthorized response
        if crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))

        # check query params, skip and limit records to return maximum 100,000 or as set by service consumer
        if crud.limit > crud.defaultLimit:
            crud.limit = crud.defaultLimit

        if crud.skip < 0:
            crud.skip = 0
        
        var getRecScript = computeSelectQuery(crud.collName, fields = fields)
        getRecScript.add(" SKIP ")
        getRecScript.add($crud.skip)
        getRecScript.add(" LIMIT ")
        getRecScript.add($crud.limit)

        # perform query for the collName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
        # The client/consumer transform/map query result/value of getRecs to collName projected fields or model definition   
        let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))

        return getResMessage("success", ResponseMessage(value: %*(getRecs)))
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))

proc getRecord*(crud: CrudParam; by: string;
                    docIds: seq[string] = @[];
                    whereParams: seq[WhereParam] = @[];
                    fields: seq[string] = @[]): ResponseMessage =  
    try:
        # update crud instance ref-variables
        if crud.docIds.len < 1 and docIds.len > 0:
            crud.docIds = docIds
        if crud.whereParams.len < 1 and whereParams.len > 0:
            crud.whereParams = whereParams

        # validate required inputs by action-type
        if by == "id" and crud.docIds.len < 1:
            # return error message
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by id (docIds[]) is required"))
        elif (by == "params" or by == "query") and whereParams.len < 1:
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by params (whereParams) is required"))
        
        # check query params, skip and limit(records to return maximum 100,000 or as set by service consumer)
        if crud.limit > crud.defaultLimit:
            crud.limit = crud.defaultLimit

        if crud.skip < 0:
            crud.skip = 0
        
        # validate taskPermission, otherwise send unauthorized response
        if not crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))
        
        # Perform query by: id, params, open (all permitted record - by admin, owner or role assignment)
        case by
        of "id":
            # check permission for the read task
            var taskPermit = taskPermission(crud, "read")
            let taskValue = taskPermit.value{"ok"}.getBool(false)

            if taskValue and taskPermit.code == "success":
                ## get current records
                var getRecScript = computeSelectByIdScript(crud.collName, crud.docIds, fields = fields)
                # append skip and limit params
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit)

                # perform query for the collName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
                # The client/consumer transform/map query result/value of getRecs to collName projected fields or model definition   
                let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
                
                return getResMessage("success", ResponseMessage(value: %*(getRecs)))
            else:
                # return task permission reponse
                return taskPermit
        of "params", "query":
            # check permission for the read task
            var taskPermit = taskPermission(crud, "read")
            let taskValue = taskPermit.value{"ok"}.getBool(false)

            if taskValue and taskPermit.code == "success":
                let selectQuery = computeSelectQuery(crud.collName, crud.queryParam)
                let whereParam = computeWhereQuery(crud.whereParams)

                var getRecScript = selectQuery & " " & whereParam
                # append skip and limit params
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit)

                let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
                # perform query for the collName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
                # The client/consumer transform/map query result/value of getRecs to collName projected fields or model definition    
                return getResMessage("success", ResponseMessage(value: %*(getRecs)))
            else:
                # return task permission reponse
                return taskPermit
        else:
            # get all-recs (upto max-limit) by admin or owner
            
            # compose docIds for getRecords by params
            if by == "params" or by == "query":
                let selectQuery = "SELECT id FROM " & crud.collName
                let whereParam = computeWhereQuery(crud.whereParams)

                var getRecScript = selectQuery & " " & whereParam
                # append skip and limit params
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit)

                let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
                crud.docIds = @[]
                for rec in getRecs:
                    crud.docIds.add(rec[0])

            # check role-based access
            var accessRes = checkAccess(accessDb = crud.accessDb, collName = crud.collName,
                                    docIds = crud.docIds, userInfo = crud.userInfo )
            
            var isAdmin: bool = false
            var collAccessPermitted: bool = false
            var userId: string = ""

            if accessRes.code == "success":
                # get access info value (json) => toObject
                let accessInfo = to(accessRes.value, CheckAccess)
                isAdmin = accessInfo.isAdmin
                userId = accessInfo.userId
                # check if collName (id) is included in checkAccess-response
                proc collAccess(it: RoleService, collId: string): bool =
                    it.serviceId == collId
                collAccessPermitted = accessInfo.roleServices.anyIt(collAccess(it, accessInfo.collId))
    
            # if current user is admin or read-access permitted on collName, perform task, get all records
            if isAdmin or collAccessPermitted:
                return crud.getAllRecords(fields)
            
            # get records owned by the current-user or requestor
            var getRecScript = ""
            if fields.len > 0:
                var 
                    fieldCount = 0
                    fieldLen = fields.len
                # get record(s) based on projected/provided field names (seq[string])
                getRecScript.add ("SELECT ")
                for field in fields:
                    inc fieldCount
                    getRecScript.add(field)
                    if fieldLen > 1 and fieldCount < fieldLen:
                        getRecScript.add(", ")
                    else:
                        getRecScript.add(" ")
                getRecScript.add("WHERE created_by = ")
                getRecScript.add(userId)
                getRecScript.add(" ")
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit) 
            else:
                # SELECT all fields in the table / collection
                getRecScript = "SELECT * FROM " & crud.collName & " "
                getRecScript.add("WHERE created_by = ")
                getRecScript.add(userId)
                getRecScript.add(" ")
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit)

            let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))

            # perform query for the collName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
            # The client/consumer transform/map query result/value of getRecs to collName projected fields or model definition    
            return getResMessage("success", ResponseMessage(value: %*(getRecs)))
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
