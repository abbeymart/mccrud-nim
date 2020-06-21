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

proc removeRecordById(crud: CrudParam, rec: seq[string]): ResponseMessage =
    try:
        ## create script from rec param
        var updateScripts: seq[string] = computeUpdateScript(crud.collName, rec, crud.docIds)
        
        ## perform update action
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

        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        for item in updateScripts:
            crud.appDb.db.exec(sql(item))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        let 
            tabName = crud.collName
            collValues = %*(CurrentRecord(currentRec: currentRecs))
            collNewValues = %*(TaskRecord(taskRec: rec))
            userId = crud.userInfo.id
        if crud.logUpdate:
            discard crud.transLog.updateLog(tabName, collValues, collNewValues, userId)

        # response
        return getResMessage("success", ResponseMessage(value: nil, message: "Record(s) updated successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

proc removeRecordByParam(crud: CrudParam, rec: seq[WhereParam]): ResponseMessage =
    try:
        ## create script from rec param
        var updateScripts: seq[string] = computeUpdateScript(crud.collName, rec, crud.docIds)
        
        ## perform update action
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

        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        for item in updateScripts:
            crud.appDb.db.exec(sql(item))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        let 
            tabName = crud.collName
            collValues = %*(CurrentRecord(currentRec: currentRecs))
            collNewValues = %*(TaskRecord(taskRec: rec))
            userId = crud.userInfo.id
        if crud.logUpdate:
            discard crud.transLog.updateLog(tabName, collValues, collNewValues, userId)

        # response
        return getResMessage("success", ResponseMessage(value: nil, message: "Record(s) updated successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  


# keep this separate, as a specialised procedure/function
# proc insertIntoFromSelectRecords(rec: seq[QueryParam]): ResponseMessage =
#     echo "insert-into-from-select-records"

proc deleteRecord*(crud: CrudParam; by: string;
                    docIds: seq[string] = @[];
                    whereParams: seq[WhereParam] = @[]): ResponseMessage =
    ## delete actions by type/conditons ("id" or "params") only,
    ## to avoid removing all table/collection records
    ## 
    if (by == "id" and docIds.len < 1) or (whereParams.len < 1):
        # return error message
        return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by id (docIds[]) or by params (whereParams) is required"))
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
                # update existing record(s)
                return removeRecordById(crud, docIds)
            else:
                return taskPermit
        of "params", "query":
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "delete")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # update existing record(s)
                return removeRecordByParam(crud, whereParams)
            else:
                return taskPermit
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
    