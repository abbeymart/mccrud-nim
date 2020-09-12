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
                    tableName: string;
                    userInfo: UserParamType;
                    actionParams: seq[SaveParamType];
                    docIds: seq[string] = @[];
                    options: Table[string, ValueType]): CrudParamType =
    ## base / shared constructor
    result = newCrud(appDb, tableName, userInfo, actionParams = actionParams, docIds = docIds, options = options )

proc createRecord(crud: CrudParamType; rec: seq[SaveParamType]): ResponseMessage =
    try:
        # create script from rec param
        var createScripts: seq[string] = computeCreateScript(crud.tableName, rec)
        
        ## perform create/insert action
        ## wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        for item in createScripts:
            crud.appDb.db.exec(sql(item))
        crud.appDb.db.exec(sql"COMMIT")
        
        # records count
        let recCnt = createScripts.len

        # perform audit/trans-log action
        let collValues = %*(TaskRecord(taskRec: rec, recCount: recCnt ))
        if crud.logCreate:
            discard crud.transLog.createLog(crud.tableName, collValues, crud.userInfo.id)
        
        # response 
        return getResMessage("success", ResponseMessage(value: %*(TaskRecord(recCount: recCnt)), message: "Record(s) created successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

proc updateRecord(crud: CrudParamType, rec: seq[SaveParamType]): ResponseMessage =
    try:
        ## update script from rec param
        var updateScripts: seq[string] = computeUpdateScript(crud.tableName, rec, crud.docIds)

        ## perform update action
        ## get current records
        var currentRecScript = "SELECT * FROM "
        currentRecScript.add(crud.tableName)
        currentRecScript.add(" WHERE id IN (")
        var idCount =  0
        for id in crud.docIds:
            inc idCount
            currentRecScript.add("'")
            currentRecScript.add(id)
            currentRecScript.add("'")
            if idCount < crud.docIds.len:
                currentRecScript.add(", ")
        currentRecScript.add(" )")

        let currentRecs =  crud.appDb.db.getAllRows(sql(currentRecScript))

        # exit / return if currentRecs[0].len < 1 or currentRecs.len < updateScripts.len
        if currentRecs[0].len < 1 or currentRecs.len < updateScripts.len:
            let okRes = OkayResponse(ok: false)
            return getResMessage("notFound", ResponseMessage(value: %*(okRes), message: "No or less record(s) found"))  
        
        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        for item in updateScripts:
            crud.appDb.db.exec(sql(item))
        crud.appDb.db.exec(sql"COMMIT")

        # records count
        let recCnt = updateScripts.len

        # perform audit/trans-log action
        let 
            collValues = %*(CurrentRecord(currentRec: currentRecs))
            collNewValues = %*(TaskRecord(taskRec: rec, recCount: updateScripts.len))
        if crud.logUpdate:
            discard crud.transLog.updateLog(crud.tableName, collValues, collNewValues, crud.userInfo.id)

        # response
        return getResMessage("success", ResponseMessage(value: %*(TaskRecord(recCount: recCnt)), message: "Record(s) updated successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

# keep this separate, as a specialised procedure/function
# proc insertIntoFromSelectRecords(rec: seq[QueryParam]): ResponseMessage =
#     echo "insert-into-from-select-records"

proc saveRecord*(crud: CrudParamType): ResponseMessage =
    ## determine taskType from actionParams: create or update
    ## iterate through actionParams, update createRecs, updateRecs & crud.docIds
    var 
        createRecs: seq[SaveParamType] = @[]    ## include records with fieldName != "id" (or _id)
        updateRecs: seq[SaveParamType] = @[]    ## include records with fieldName == "id" (or _id)

    try:
        for rec in crud.actionParams:
            ## determine if record existed (update) or is new (create)
            proc itemExist(it: SaveFieldType; recId: var string): bool =
                recId = it.fieldValue
                (it.fieldName == "id" or it.fieldName == "_id") and it.fieldValue != ""
            var recId = ""
            if rec.fields.anyIt(itemExist(it, recId)):
                updateRecs.add(rec)
                crud.docIds.add(recId)
            else:
                createRecs.add(rec)

        ## save-record(s): new records, docIds = @[], for createRecs.len > 0
        if createRecs.len > 0:
            # create/insert new record(s)
            return createRecord(crud, createRecs)

        ## update-record(s): existing record(s), docIds != @[], for updateRecs.len > 0
        if updateRecs.len > 0:
            # update existing record(s)
            return updateRecord(crud, updateRecs)
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
    