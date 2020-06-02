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
import mcdb, mccache, mcresponse, mctranslog

# constructor
proc newGetRecord*() =
    echo "save-constructor"

proc getRecord*() =
    echo "save-record"
