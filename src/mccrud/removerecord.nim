#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#            CRUD Library - delete/remove record(s)
# 


## remove-record procedure is delete record(s) by role (access-control)
## 
## 
import crud
import mcdb, mccache, mcresponse, mctranslog

# constructor
proc newSaveRecord*() =
    echo "save-constructor"

proc saveRecord*() =
    echo "save-record"

proc createRecord*() =
    echo "create-record"

proc updateRecord*() =
    echo "save-record"
