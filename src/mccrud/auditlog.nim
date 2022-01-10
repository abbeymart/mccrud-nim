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

import db_postgres, json, times
import mcresponse
import ./types

# Define types
type
    LogParam* = object
        auditDb*: Database
        auditTable*: string

# contructor
proc newLog*(auditDb: Database; auditTable: string = "audits"): LogParam =
    # new result
    result.auditDb = auditDb
    result.auditTable = auditTable
 
proc createLog*(log: LogParam; table: string; logRecords: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = logRecords
            logType = CrudTasksType.CreateTask
            logBy = userId
            logAt = now().utc

        # validate params/values
        var errorMessage = ""
        
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # echo "params-passed"
        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        # echo "run-query"
        log.auditDb.db.exec(taskQuery, tableName, logRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(MessageCode.SuccessCode, ResponseMessage(value: logRecords, message: "successful create-log action"))
    
    except:
        # echo getCurrentException.repr
        # echo getCurrentExceptionMsg()
        return getResMessage(MessageCode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc updateLog*(log: LogParam; table: string; logRecords: JsonNode; newLogRecords: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = logRecords
            newLogRecords = newLogRecords
            logType = "update"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Old/existing record(s) information is required."        
        if newLogRecords == nil:
            errorMessage = errorMessage & " | Updated/new record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, new_coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, logRecords, newLogRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(MessageCode.SuccessCode, ResponseMessage(value: newLogRecords, message: "successful update-log action"))
    
    except:
        # echo getCurrentExceptionMsg()
        return getResMessage(MessageCode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc readLog*(log: LogParam; table: string; logRecords: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = logRecords
            logType = "read"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, logRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(Messagecode.SuccessCode, ResponseMessage(value: logRecords, message: "successful read-log action"))
    
    except:
        echo getCurrentException.repr
        return getResMessage(MessageCode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc deleteLog*(log: LogParam; table: string; logRecords: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = logRecords
            logType = "remove"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, logRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(Messagecode.SuccessCode, ResponseMessage(value: logRecords, message: "successful remove-log action"))
    
    except:
        return getResMessage(Messagecode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc loginLog*(log: LogParam; table: string = "users"; loginParams: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = loginParams
            logType = "login"
            logBy = userId
            logAt = now().utc

        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, logRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(MessageCode.SuccessCode, ResponseMessage(value: nil, message: "successful login-log action"))
    
    except:
        return getResMessage(MessageCode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))

proc logoutLog*(log: LogParam; table: string = "users"; logoutParams: JsonNode; userId: string ): ResponseMessage =
    try:
        # log-params/values
        let
            tableName = table
            logRecords = logoutParams
            logType = "logout"
            logBy = userId
            logAt = now().utc
        
        # validate params
        var errorMessage = ""
        if tableName == "":
            errorMessage = errorMessage & " | Table or Collection name is required."
        if logBy == "":
            errorMessage = errorMessage & " | userId is required."
        if logRecords == nil:
            errorMessage = errorMessage & " | Created record(s) information is required."        

        if errorMessage != "":
            raise newException(ValueError, errorMessage)

        # store action record
        var taskQuery = sql("INSERT INTO " & log.auditTable & " (coll_name, coll_documents, log_type, log_by, log_at ) VALUES (?, ?, ?, ?, ?);")

        log.auditDb.db.exec(taskQuery, tableName, logRecords, logType, logBy, logAt)
        
        # send response
        return getResMessage(MessageCode.SuccessCode, ResponseMessage(value: nil, message: "successful logout-log action"))
    
    except:
        # echo getCurrentExceptionMsg()
        return getResMessage(MessageCode.InsertErrorCode, ResponseMessage(value: nil, message: getCurrentExceptionMsg()))
