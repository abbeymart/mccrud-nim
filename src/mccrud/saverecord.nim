#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#          CRUD Library - save record(s)
# 

## save-record procedure is for creating new record(s) and update existing record(s)
## by role (access-control)
## 
import crud

# constructor
proc newSaveRecord*(appDb: Database; coll, userInfo: UserParam; options: Table[string, ValueType]) =
    echo "save-constructor"

proc saveRecord*() =
    echo "save-record"

proc createRecord*() =
    echo "create-record"

proc updateRecord*() =
    echo "save-record"
