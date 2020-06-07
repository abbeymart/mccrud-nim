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
proc newDeleteRecord*(appDb: Database; collName: string; userInfo: UserParam; actionParams: JsonNode; options: Table[string, ValueType]) =
    echo "remove-constructor"
    #  include actionParams in options/option-params
    options["actionParams"] = actionParams
    newCrud(appDb, collName, userInfo, options )

proc deleteRecord*() =
    echo "remove-record"
