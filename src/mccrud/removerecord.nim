#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#            CRUD Library - delete(remove) record(s)
# 


## delete(remove)-record procedure is delete record(s) by role (access-control)
## 
## 
import crud
import mcdb, mccache, mcresponse, mctranslog

# constructor
proc newDeleteRecord*() =
    echo "remove-constructor"

proc deleteRecord*() =
    echo "remove-record"
