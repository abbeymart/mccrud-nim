#
#              mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details about the copyright / license.
# 
#            Audit / Transactions Log Procedures
#

## The audit / transactions log procedures include:
## login, logout, create, update, delete and read operations
## 
## 

# types
import types
import db_postgres, json, times
import mcresponse
# import dbconnect

# Define types
type
    LogParam* = object
        auditDb*: Database
        auditColl*: string

# contructor
proc newLog*(auditDb: Database; auditColl: string = "audits"): LogParam =
    # new result
    result.auditDb = auditDb
    result.auditColl = auditColl
 
proc createLog*(log: LogParam; table: string; collDocuments: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = collDocuments
            logType = "create"
            logBy = userId
            logAt = now().utc

        # validate params/values
        var errorMessage = ""
        
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # echo "params-passed"
        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        # echo "run-query"
        log.auditDb.db.exec(taskQuery, tableName, collDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: collDocuments, message: "successful create-log action"))
    
    except:
        # echo getCurrentException.repr
        # echo getCurrentExceptionMsg()
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc updateLog*(log: LogParam; table: string; collDocuments: JsonNode; newCollDocuments: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = collDocuments
            newCollDocuments = newCollDocuments
            logType = "update"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Old/existing record(s) information is required."        
        if newCollDocuments == nil:
            errorMessage = errorMessage & " | Updated/new record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, new_coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, collDocuments, newCollDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: newCollDocuments, message: "successful update-log action"))
    
    except:
        # echo getCurrentExceptionMsg()
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc readLog*(log: LogParam; table: string; collDocuments: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = collDocuments
            logType = "read"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, collDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: collDocuments, message: "successful read-log action"))
    
    except:
        echo getCurrentException.repr
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc deleteLog*(log: LogParam; table: string; collDocuments: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = collDocuments
            logType = "remove"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, collDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: collDocuments, message: "successful remove-log action"))
    
    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc loginLog*(log: LogParam; table: string = "users"; loginParams: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = loginParams
            logType = "login"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, collDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: nil, message: "successful login-log action"))
    
    except:
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc logoutLog*(log: LogParam; table: string = "users"; logoutParams: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            collDocuments = logoutParams
            logType = "logout"
            logBy = userId
            logAt = now().utc
        
        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if collDocuments == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditColl & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, collDocuments, logType, logBy, logAt)
        
        # send response
        return getResMessage("success", ResponseMessage(value: nil, message: "successful logout-log action"))
    
    except:
        # echo getCurrentExceptionMsg()
        return getResMessage("insertError", ResponseMessage(value: nil, message: getCurrentExceptionMsg()))
