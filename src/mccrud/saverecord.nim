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

# constructor
proc newSaveRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    actionParams: seq[QueryParam]; 
                    options: Table[string, ValueType]): CrudParam =
    # base shared constructor variable
    result = newCrud(appDb, collName, userInfo, actionParams = actionParams, options )
    
    # specific/sub-set constructor variable
    result.docIds = @[]
    result.currentRecords = @[]
    result.roleServices = @[]
    result.isRecExist = false
    result.isAuthorized = false
    result.recExistMessage = "Save / update error or duplicate records exist: "
    result.unAuthMessage = "Action / task not authorised or permitted "


proc createRecord(rec: seq[QueryParam]): ResponseMessage =
    try:
        # create script

        # create/insert action

        # if action was successful task audit log

        # response
        echo ""
    except:
        let ok = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(ok), message: getCurrentExceptionMsg()))  

proc updateRecord(rec: seq[QueryParam]): ResponseMessage =
    try:
        # create script

        # create/insert action

        # if action was successful task audit log

        # response
        echo ""
    except:
        let ok = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(ok), message: getCurrentExceptionMsg()))  

# keep this separate, as a specialised procedure/function
# proc insertIntoFromSelectRecords(rec: seq[QueryParam]): ResponseMessage =
#     echo "insert-into-from-select-records"

proc saveRecord*(crud: CrudParam): ResponseMessage =
    # determine taskType from actionParams: create or update
    # iterate through actionParams, update createRecs, updateRecs & crud.docIds
    var 
        createRecs: seq[QueryParam] = @[]    # include records with fieldName != "uid"
        updateRecs: seq[QueryParam] = @[]    # include records with fieldName == "uid"

    try:
        for rec in crud.actionParams:
            # determine if record existed (update) or is new (create)
            proc itemExist(it: FieldItem; recId: var string): bool =
                recId = it.fieldName 
                it.fieldName == "uid"
            var recId = ""
            if rec.fieldItems.anyIt(itemExist(it, recId)):
                updateRecs.add(rec)
                crud.docIds.add(recId)
            else:
                createRecs.add(rec)

        # save-record(s): new records, docIds = @[], for createRecs.len > 0
        if createRecs.len > 0:
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "create")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # TODO: compose insert SQL
                return createRecord(createRecs)
            else:
                return taskPermit

        # update-record(s): existing record(s), docIds != @[], for updateRecs.len > 0
        if updateRecs.len > 0:
            # check permission based on the create and/or update records
            var taskPermit = taskPermission(crud, "update")
            let taskValue = taskPermit.value{"ok"}.getBool(false)
            if taskValue and taskPermit.code == "success":
                echo "process task"
                # TODO: compose update SQL
                return updateRecord(updateRecs)
            else:
                return taskPermit
    except:
        let ok = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(ok), message: getCurrentExceptionMsg()))
    