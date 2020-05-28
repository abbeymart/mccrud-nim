#
#            mconnect collections package
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#        CRUD Library - common / extendable base type/class
# 

import db_postgres, json

# Define types
type
    Database* = ref object
        db: DbConn
    ActionParam* = JsonNode
    SortParam* = JsonNode
    QueryParam* = JsonNode
    UserParam* = ref object
        name: string
        age: Natural
    CrudParam* = ref object
        actionParams*: JsonNode
        sortParams*: JsonNode
        queryParams*: JsonNode
        userInfo*: UserParam
        token: string
        docIds*: seq[string]
        auditColl*: string
        accessColl*: string
        serviceColl*: string
        roleColl*: string
        userColl*: string
        logAll*: bool
        logRead*: bool
        logCreate*: bool
        logUpdate*: bool
        logDelete*: bool
        skip: uint
        limit: uint
        maxQueryLimit: uint
        mcMessages*: JsonNode
    OptionParam* = ref object
        auditDb: Database
        
    
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
