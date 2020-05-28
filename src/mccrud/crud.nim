#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#        CRUD Library - common / extendable base type/class
# 

import db_postgres

# Define types
type
    Database* = ref object
        db: DbConn
    ActionParam* = ref object
        name: string
        age: Natural
    SortParam* = ref object
        name: string
        age: Natural
    QueryParam* = ref object
        name: string
        age: Natural
    UserParam* = ref object
        name: string
        age: Natural
    CrudParam* = ref object
        actionParams*: ActionParam
        sortParams*: SortParam
        queryParams*: QueryParam
        userInfo*: UserParam
        docIds*: seq[string]
        test1: string
    OptionParam* = ref object
        actionParams*: ActionParam
        sortParams*: SortParam
        queryParams*: QueryParam
        userInfo*: UserParam
        docIds*: seq[string]
        test1: string
    
# Variables
var
    coll*: string = ""
    actionParams*: seq[string] = @[]
    token*: string = ""
    skip*: int = 0
    limit*: int = 10000

# default contructor

proc newCrud*(appDb: Database, params: CrudParam, options = OptionParam ): CrudParam =
    result = CrudParam()
