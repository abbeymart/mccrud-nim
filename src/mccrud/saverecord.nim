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
proc newSaveRecord*(appDb: Database; collName: string; userInfo: UserParam; actionParams: JsonNode; options: Table[string, ValueType]) =
    echo "save-constructor"
    #  include actionParams in options/option-params
    options["actionParams"] = actionParams
    newCrud(appDb, collName, userInfo, options )

proc saveRecord*() =
    echo "save-record"

proc createRecord*() =
    echo "create-record"

proc updateRecord*() =
    echo "update-record"

proc insertIntoFromSelectRecords*() =
    echo "insert-into-from-select-records"
