#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#          CRUD Package - save record(s)
# 

## save-record procedure is for creating new record(s) and update existing record(s)
## by role (access-control)
## 
##  
import crud, sequtils

## save-record operations constructor
proc newSaveRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    actionParams: seq[QueryParam]; 
                    options: Table[string, ValueType]): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, actionParams = actionParams, options )
    
    ## specific/sub-set constructor variable
    result.docIds = @[]
    # result.currentRecords = @[]
    # result.roleServices = @[]
    # result.isRecExist = false
    # result.isAuthorized = false
    # result.recExistMessage = "Save / update error or duplicate records exist: "
    # result.unAuthMessage = "Action / task not authorised or permitted "


proc createRecord(crud: CrudParam; rec: seq[QueryParam]): ResponseMessage =
    try:
        # create script from rec param
        var createScripts:seq[string] = computeCreateScript(crud.collName, rec)
        
        ## perform create/insert action
        ## wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        for item in createScripts:
            crud.appDb.db.exec(sql(item))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        let 
            tabName = crud.collName
            collValues = %*(TaskRecord(taskRec: rec))
            userId = crud.userInfo.id
        if crud.logCreate:
            discard crud.transLog.createLog(tabName, collValues, userId)
        
        # response
        return getResMessage("success", ResponseMessage(value: nil, message: "Record(s) updated successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

proc updateRecord(crud: CrudParam, rec: seq[QueryParam]): ResponseMessage =
    try:
        ## update script from rec param
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

proc saveRecord*(crud: CrudParam): ResponseMessage =
    ## determine taskType from actionParams: create or update
    ## iterate through actionParams, update createRecs, updateRecs & crud.docIds
    var 
        createRecs: seq[QueryParam] = @[]    ## include records with fieldName != "id"
        updateRecs: seq[QueryParam] = @[]    ## include records with fieldName == "id"

    try:
        for rec in crud.actionParams:
            ## determine if record existed (update) or is new (create)
            proc itemExist(it: FieldItem; recId: var string): bool =
                recId = it.fieldName 
                it.fieldName == "id"
            var recId = ""
            if rec.fieldItems.anyIt(itemExist(it, recId)):
                updateRecs.add(rec)
                crud.docIds.add(recId)
            else:
                createRecs.add(rec)

        ## save-record(s): new records, docIds = @[], for createRecs.len > 0
        if createRecs.len > 0:
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "create")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                # create/insert new record(s)
                return createRecord(crud, createRecs)
            else:
                return taskPermit

        ## update-record(s): existing record(s), docIds != @[], for updateRecs.len > 0
        if updateRecs.len > 0:
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "update")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # update existing record(s)
                return updateRecord(crud, updateRecs)
            else:
                return taskPermit
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
    