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
import crud

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

proc saveRecord*(crud: CrudParam) =
    # determine taskType from actionParams: create or update
    # iterate through actionParams, add record to createRecs or updateRecs
    var 
        createRecs: seq[FieldItem] = @[]   # include records with fieldName != "uid"
        updateRecs: seq[FieldItem] = @[]  # include records with fieldName == "uid"

    for rec in crud.actionParams:
        for field in rec.fieldItems:
            if field.fieldName == "uid":
                updateRecs.add(field)
            else:
                createRecs.add(field)

    # save-record(s): new records, docIds = @[], for createRecs.len > 0
    if createRecs.len > 0:
        echo "process create"
        # check permission based on the create and/or update records
        var taskPermit = taskPermission(crud, "create")
        let taskValue = taskPermit.value{"ok"}.getBool(false)
        if taskValue and taskPermit.code == "success":
            echo "process task"

    # update-record(s): existing record(s), docIds != @[], for updateRecs.len > 0
    if updateRecs.len > 0:
        echo "process update"
        # check permission based on the create and/or update records
        var taskPermit = taskPermission(crud, "update")
        let taskValue = taskPermit.value{"ok"}.getBool(false)
        if taskValue and taskPermit.code == "success":
            echo "process task"

proc createRecord*() =
    echo "create-record"

proc updateRecord*() =
    echo "update-record"

proc insertIntoFromSelectRecords*() =
    echo "insert-into-from-select-records"
