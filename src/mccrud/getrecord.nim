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
proc newGetRecord*(appDb: Database; collName: string; userInfo: UserParam; actionParams: JsonNode; options: Table[string, ValueType]) =
    echo "get-record-constructor"
    #  include actionParams in options/option-params
    options["actionParams"] = actionParams
    newCrud(appDb, collName, userInfo, options )

proc getRecord*() =
    echo "get-record-record"
