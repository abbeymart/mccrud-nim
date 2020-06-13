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
    result = newCrud(appDb, collName, userInfo, actionParams, options )
    # specific/sub-set constructor variable
    result.docIds = @[]
    result.currentRecords = @[]
    result.roleServices = @[]
    result.isRecExist = false
    result.isAuthorized = false
    result.recExistMessage = "Save / update error or duplicate records exist: "
    result.unAuthMessage = "Action / task not authorised or permitted "

proc saveRecord*(crud: CrudParam) =
    echo "save-record"

proc createRecord*() =
    echo "create-record"

proc updateRecord*() =
    echo "update-record"

proc insertIntoFromSelectRecords*() =
    echo "insert-into-from-select-records"
