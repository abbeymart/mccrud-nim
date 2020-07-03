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
##
import crud

# constructor
## get-record operations constructor
proc newGetRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    whereParams: seq[WhereParam];
                    docIds: seq[string] = @[]; 
                    options: Table[string, ValueType]): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, whereParams = whereParams, options )
    
    ## specific/sub-set constructor variable
    result.docIds = @[]
    result.currentRecords = @[]

    result.roleServices = @[]
    result.recExistMessage = "Save / update error or duplicate records exist: "
    result.unAuthMessage = "Action / task not authorised or permitted "

proc getRecord*(crud: CrudParam; by: string;
                    docIds: seq[string] = @[];
                    whereParams: seq[WhereParam] = @[]): ResponseMessage =  
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
        elif whereParams.len < 1:
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by params (whereParams) is required"))
        
        # check query params, skip and limit(records to return maximum 100,000 or as set by service consumer)
        if crud.limit > 100000:
            crud.limit = 100000

        if crud.skip < 0:
            crud.skip = 0
        
        # validate taskPermission, otherwise send unauthorized response
        if not crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))
        
        # TODO: task permission


        # TODO: if permitted, perform query by: id, params, open (all permitted record - by admin, owner or role assignment)
        case by
        of "id":
            # check permission based on the delete task
            var taskPermit = taskPermission(crud, "read")
            let taskValue = taskPermit.value{"ok"}.getBool(false)

            if taskValue and taskPermit.code == "success":
                ## get current records
                let getRecScript = computeSelectByIdScript(crud.collName, crud.docIds)
                let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
                # return mapped records as json array-objects 
                return getResMessage("success", ResponseMessage(value: %*(getRecs)))
            else:
                # return task permission reponse
                return taskPermit
        of "params", "query":
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "read")
            let taskValue = taskPermit.value{"ok"}.getBool(false)

            if taskValue and taskPermit.code == "success":
                let selectQuery = computeSelectQuery(crud.collName, crud.queryParam)
                let whereParam = computeWhereQuery(crud.whereParams)

                var getRecScript = selectQuery & " " & whereParam
                getRecScript.add(" SKIP ")
                getRecScript.add($crud.skip)
                getRecScript.add(" LIMIT ")
                getRecScript.add($crud.limit)

                let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
                # return mapped records as json array-objects 
                return getResMessage("success", ResponseMessage(value: %*(getRecs)))
            else:
                # return task permission reponse
                return taskPermit
        else:
            # TODO: get all-recs (upto max-limit) by admin / role / owner
            echo "get all records by admin / role / owner"  
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
  
proc getAllRecords*(crud: CrudParam): ResponseMessage =  
    try:
        echo "success"
        # validate that checkAccess is true, otherwise send unauthorized response
        if not crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))

        # check query params, skip and limit(records to return maximum 100,000 or as set by service consumer)
        if crud.limit > 100000:
            crud.limit = 100000

        if crud.skip < 0:
            crud.skip = 0
        
        # perform query for the collName and deliver string[][] result to the client/consumer of the CRUD service
        # The user (client/consumer's) transform/map query result/value of getRecs to collName model definition

        var getRecScript = "SELECT * FROM " & crud.collName & " "

        getRecScript.add(" SKIP ")
        getRecScript.add($crud.skip)
        getRecScript.add(" LIMIT ")
        getRecScript.add($crud.limit)

        let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))

        # return mapped records as json array-objects 
        return getResMessage("success", ResponseMessage(value: %*(getRecs)))

    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
