#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#            CRUD Package - delete(remove) record(s)
# 

## delete(remove)-record procedure is delete record(s) by role (access-control)
## 
import crud

# constructor
## delete-record operations constructor
proc newDeleteRecord*(appDb: Database;
                    tableName: string;
                    userInfo: UserParamType;
                    where: seq[WhereParamType];
                    docIds: seq[string] = @[]; 
                    options: Table[string, DataTypes]): CrudParamType =
    ## base / shared constructor
    result = newCrud(appDb, tableName, userInfo, where = where, docIds = docIds, options = options )

## Delete or remove record(s) by id(s)
## 
proc deleteRecordById(crud: CrudParamType): ResponseMessage =
    try:
        ## get current records
        let currentRecScript = computeSelectByIdScript(crud.tableName, crud.docIds)
        let currentRecs =  crud.appDb.db.getAllRows(sql(currentRecScript))

        # exit / return if currentRecs[0].len < 1 or currentRecs.len < crud.docIds.len
        if currentRecs[0].len < 1 or currentRecs.len < crud.docIds.len:
            let okRes = OkayResponse(ok: false)
            return getResMessage("notFound", ResponseMessage(value: %*(okRes), message: "No or less record(s) found"))  
        
        ## compute delete script from docIds
        let deleteScripts: string = computeDeleteByIdScript(crud.tableName, crud.docIds)
                
        # perform delete task, wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        crud.appDb.db.exec(sql(deleteScripts))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        # TODO: transform currentRecs into JSON based on projected fiedls or data model structure
        let collValues = %*(CurrentRecord(currentRec: currentRecs))
        if crud.logDelete:
            discard crud.transLog.deleteLog(crud.tableName, collValues, crud.userInfo.id)

        # response
        return getResMessage("success", ResponseMessage(value: %*(crud.docIds), message: "Record(s) deleted(removed) successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("deleteError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

## Delete or remove record(s) by params / query
## 
proc deleteRecordByParam(crud: CrudParamType): ResponseMessage =
    try:
        ## get current records
        let selectQuery = computeSelectQuery(crud.tableName, crud.queryParam)
        let whereParam = computeWhereQuery(crud.where)

        let currentRecScript = selectQuery & " " & whereParam

        let currentRecs =  crud.appDb.db.getAllRows(sql(currentRecScript))

        # exit / return if currentRecs[0].len < 1
        if currentRecs[0].len < 1:
            let okRes = OkayResponse(ok: false)
            return getResMessage("notFound", ResponseMessage(value: %*(okRes), message: "No record(s) found"))  
        
        ## compute delete script from where
        let deleteScripts: string = computeDeleteByParamScript(crud.tableName, crud.where)
            
        # wrap in transaction
        crud.appDb.db.exec(sql"BEGIN")
        crud.appDb.db.exec(sql(deleteScripts))
        crud.appDb.db.exec(sql"COMMIT")

        # perform audit/trans-log action
        # TODO: transform currentRecs into JSON based on projected fiedls or data model structure
        let collValues = %*(CurrentRecord(currentRec: currentRecs))
        if crud.logDelete:
            discard crud.transLog.deleteLog(crud.tableName, collValues, crud.userInfo.id)

        # response
        return getResMessage("success", ResponseMessage(value: %*(crud.docIds), message: "Record(s) deleted(removed) successfully"))
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("deleteError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))  

proc deleteRecord*(crud: CrudParamType; by: string;
                    docIds: seq[string] = @[];
                    where: seq[WhereParamType] = @[]): ResponseMessage =
    ## perform delete task, by taskType (id or params/query)
    try:
        # update crud instance ref-variables
        if crud.docIds.len < 1 and docIds.len > 0:
            crud.docIds = docIds
        if crud.where.len < 1 and where.len > 0:
            crud.where = where

        # validate required inputs by action-type
        if by == "id" and crud.docIds.len < 1:
            # return error message
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Fod delete by id, docIds[] is required"))
        elif where.len < 1:
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "For delete by params, where is required"))
        
        case by:
        of "id":
            # delete record(s) by id
                return deleteRecordById(crud)
        of "params", "query":
            # delete record(s) by params/query
                return deleteRecordByParam(crud)
    except:
        let okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
    