#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#            CRUD Package - delete(remove) record(s)
# 


## delete(remove)-record procedure is delete record(s) by role (access-control)
## 
##
import crud

# constructor
## save-record operations constructor
proc newDeleteRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    actionParams: seq[QueryParam];
                    docIds: seq[string] = @[]; 
                    options: Table[string, ValueType]): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, actionParams = actionParams, options )
    
    ## specific/sub-set constructor variable
    result.docIds = docIds

## Delete or remove record(s) by id(s)
## 
proc deleteRecordById(crud: CrudParam): ResponseMessage =
    try:
        ## delete script from docIds
        let deleteScripts: string = computeDeleteByIdScript(crud.collName, crud.docIds)
        
        ## perform delete action
        ## get current records
        var currentRecScript = "SELECT * FROM "
        currentRecScript.add(crud.collName)
        currentRecScript.add(" WHERE id IN (")
        var idCount =  0
        for id in crud.docIds:
            idCount += 1
            currentRecScript.add("'")
            currentRecScript.add(id)
            currentRecScript.add("'")
            if idCount < crud.docIds.len:
                currentRecScript.add(", ")
        currentRecScript.add(" )")

        let currentRecs =  crud.appDb.db.getAllRows(sql(currentRecScript))

        # TODO: exit / return if currentRecs[0].len < 1

        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        crud.appDb.db.exec(sql(deleteScripts))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        let 
            tabName = crud.collName
            collValues = %*(CurrentRecord(currentRec: currentRecs))
            userId = crud.userInfo.id
        if crud.logDelete:
            discard crud.transLog.deleteLog(tabName, collValues, userId)

        # response
        return getResMessage("success", ResponseMessage(value: %*(crud.docIds), message: "Record(s) deleted(removed) successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

## Delete or remove record(s) by id(s)
## 
proc deleteRecordByParam(crud: CrudParam): ResponseMessage =
    try:
        ## delete script from docIds
        let deleteScripts: string = computeDeleteByParamScript(crud.collName, crud.whereParams)
        
        ## perform delete action
        ## get current records
        let selectQuery = computeSelectQuery(crud.collName, crud.queryParam)
        let whereParam = computeWhereQuery(crud.whereParams)

        let currentRecScript = selectQuery & " " & whereParam

        let currentRecs =  crud.appDb.db.getAllRows(sql(currentRecScript))

        # TODO: exit / return if currentRecs[0].len < 1

        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        crud.appDb.db.exec(sql(deleteScripts))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        let 
            tabName = crud.collName
            collValues = %*(CurrentRecord(currentRec: currentRecs))
            userId = crud.userInfo.id
        if crud.logDelete:
            discard crud.transLog.deleteLog(tabName, collValues, userId)

        # response
        return getResMessage("success", ResponseMessage(value: %*(crud.docIds), message: "Record(s) deleted(removed) successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

proc deleteRecord*(crud: CrudParam; by: string;
                    docIds: seq[string] = @[];
                    whereParams: seq[WhereParam] = @[]): ResponseMessage =
    
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
    
    
    ## determine taskType from actionParams: create or update
    ## iterate through actionParams, update createRecs, updateRecs & crud.docIds
    try:
        case by:
        of "id":
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "delete")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # delete existing record(s)
                return deleteRecordById(crud)
            else:
                return taskPermit
        of "params", "query":
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "delete")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # update existing record(s)
                return deleteRecordByParam(crud)
            else:
                return taskPermit
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
    