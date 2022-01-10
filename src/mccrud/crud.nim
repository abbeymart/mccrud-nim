#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 

##     CRUD Package - common / extendable base constructor & procedures for all CRUD operations
## 

import tables, json
import mcresponse
import ./helpers/helper, ./types, ./auditlog

export helper, types, auditlog

type
        Crud* = ref object of CrudOptionsType
                createItems*:    ActionParamsType
                updateItems*:    ActionParamsType
                currentRecords*: seq[JsonNode]
                transLog*:       LogParam
                cacheKey*:       string 

## Default CRUD contructor returns the instance/object for CRUD task(s)
proc newCrud*(params: CrudParamsType, options: CrudOptionsType): Crud =
    # instance result
    result.appDb = params.appDb
    result.tableName = params.tableName
    result.tableFields = params.tableFields
    result.userInfo = params.userInfo
    result.actionParams = params.actionParams
    result.recordIds = params.recordIds
    result.projectParams = params.projectParams
    result.sortParams = params.sortParams
    result.token = params.token
    result.skip = params.skip
    result.limit = params.limit
    result.taskName = params.taskName
    result.taskType = params.taskType
    result.appParams = params.appParams

    # options
    result.maxQueryLimit = options.maxQueryLimit
    result.auditTable = options.auditTable
    result.accessTable = options.accessTable
    result.roleTable = options.roleTable
    result.userTable = options.userTable
    result.verifyTable = options.verifyTable
    result.profileTable = options.profileTable
    result.serviceTable = options.serviceTable
    result.userRoleTable = options.userRoleTable
    result.auditDb = options.auditDb
    result.accessDb = options.accessDb
    result.logCrud = options.logCrud
    result.logRead = options.logRead
    result.logCreate = options.logCreate
    result.logUpdate = options.logUpdate
    result.logDelete = options.logDelete
    result.checkAccess = options.checkAccess # Dec 09/2020: user to implement auth as a middleware
    result.cacheResult = options.cacheResult
    result.cacheExpire = options.cacheExpire # cache expire in secs
    result.bulkCreate = options.bulkCreate
    result.modelOptions = options.modelOptions
    result.fieldSeparator = options.fieldSeparator
    result.appDbs = options.appDbs
    result.appTables = options.appTables

    # Default values
    if result.appDbs.len == 0:
        result.appTables = @["database", "database-mcpa", "database-mcpay", "database-mcship", "database-mctrade", "database-mcproperty", "database-mcinfo", "database-mcbc"]

    if result.appTables.len == 0:
        result.appTables = @["table", "table-mcpa", "table-mcpay", "table-mcship", "table-mctrade", "table-mcproperty", "table-mcinfo", "table-mcbc"]

    if result.fieldSeparator == "":
            result.fieldSeparator = "_"
    
    if result.auditTable == "":
            result.auditTable = "audits"
    
    if result.accessTable == "":
            result.accessTable = "accesses"
    
    if result.roleTable == "":
            result.roleTable = "roles"
    
    if result.userTable == "":
            result.userTable = "users"
    
    if result.verifyTable == "":
            result.verifyTable = "verify_users"
    
    if result.profileTable == "":
            result.profileTable = "profiles"
    
    if result.serviceTable == "":
            result.serviceTable = "services"
    
    if result.auditDb == nil:
            result.auditDb = result.appDb

    if result.accessDb == nil:
            result.accessDb = result.appDb
    
    if result.skip < 0:
            result.skip = 0

    if result.maxQueryLimit <= 0:
            result.maxQueryLimit = 10000

    if result.limit <= 0 or result.limit > result.maxQueryLimit:
            result.limit = result.maxQueryLimit

    if result.cacheExpire <= 0:
            result.cacheExpire = 300 # 300 seconds or 5 minutes

    # compute cacheKey
    let qParam = $(%* result.queryParams)
    let sParam = $(%* result.sortParams)
    let pParam = $(%* result.projectParams)
    let recIds = $(%* result.recordIds)

    result.cacheKey = result.tableName & qParam & sParam & pParam & recIds

    # auditlog / translog instance
    result.transLog = newLog(result.auditDb, result.auditTable)

# String() method implementation for crud instance/object
proc crudString*(crud: Crud): string =
        # let crudStr = $(%* crud.repr)
        return "CRUD Instance Information: " & crud.repr

## saveRecord method creates new record(s) or updates existing record(s)
proc saveRecord*(crud: Crud): ResponseMessage =
        return ResponseMessage()

## deleteRecord method deletes/removes record(s) by recordIds or queryParams
proc deleteRecord*(crud: Crud): ResponseMessage =
        return ResponseMessage()

## getRecord method fetches records by recordIds, queryParams or all
proc getRecord*(crud: Crud): ResponseMessage =
        return ResponseMessage()

## getRecords method fetches records by recordIds, queryParams or all - lookup-items (no-access-constraint)
proc getRecords*(crud: Crud): ResponseMessage =
        return ResponseMessage()
