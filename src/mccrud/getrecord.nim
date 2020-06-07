#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#             CRUD Library - get record(s)
# 

## get-record procedure is for fetching records by role (access-control)
## 
##
import crud

# constructor
proc newGetRecord*(appDb: Database; collName: string; userInfo: UserParam; actionParams: JsonNode; options: Table[string, ValueType]) =
    echo "get-record-constructor"

proc getRecord*() =
    echo "get-record-record"
