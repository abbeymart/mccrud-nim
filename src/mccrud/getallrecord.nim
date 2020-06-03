#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#             CRUD Library - get all record(s)
# 

## get-all-record procedure is for fetching lookup records
## 
## 
import crud

# constructor
proc newGetAllRecord*(appDb: Database; coll, userInfo: UserParam; options: Table[string, ValueType]) =
    echo "get-all-constructor"

proc getAllRecord*() =
    echo "save-record"
