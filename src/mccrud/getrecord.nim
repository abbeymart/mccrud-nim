#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#             CRUD Package - get record(s)
# 

## get-record procedure is for fetching records by role (access-control)
## 
import crud

# constructor
## get-record operations constructor
proc newGetRecord*(appDb: Database;
                    tableName: string;
                    userInfo: UserParamType;
                    checkAccess: bool = true;
                    where: seq[WhereParamType] = @[];
                    docIds: seq[string] = @[];
                    fields: seq[string] = @[]; 
                    options: Table[string, DataTypes]): CrudParamType =
    ## base / shared constructor
    result = newCrud(appDb = appDb, tableName = tableName,
                    userInfo = userInfo, where = where,
                    docIds = docIds, options = options )
  
proc getAllRecords*(crud: CrudParamType; fields: seq[string] = @[]): ResponseMessage =  
    try:
        # check query params, skip and limit records to return maximum 100_000 or as set by service consumer
        if crud.limit > crud.defaultLimit:
            crud.limit = crud.defaultLimit

        if crud.skip < 0:
            crud.skip = 0
        
        var getRecScript = computeSelectQuery(crud.tableName, fields = fields)
        getRecScript.add(" SKIP ")
        getRecScript.add($crud.skip)
        getRecScript.add(" LIMIT ")
        getRecScript.add($crud.limit)

        # perform query for the tableName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array  
        # TODO: transform getRecs into JSON based on projected fiedls or data model structure
        let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))

        return getResMessage("success", ResponseMessage(value: %*(getRecs)))
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))

proc getRecord*(crud: CrudParamType; by: QueryWhereTypes;
                docIds: seq[string] = @[];
                where: seq[WhereParamType] = @[];
                fields: seq[string] = @[]): ResponseMessage =  
    try:
        # update crud instance ref-variables
        if crud.docIds.len < 1 and docIds.len > 0:
            crud.docIds = docIds
        if crud.where.len < 1 and where.len > 0:
            crud.where = where

        # validate required inputs by action-type
        if by == QueryWhereTypes.ID and crud.docIds.len < 1:
            # return error message
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by id (docIds[]) is required"))
        elif (by == QueryWhereTypes.PARAMS or by == QueryWhereTypes.QUERY) and where.len < 1:
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by params (whereParams) is required"))
        
        # check query params, skip and limit(records to return maximum 100,000 or as set by service consumer)
        if crud.limit > crud.defaultLimit:
            crud.limit = crud.defaultLimit

        if crud.skip < 0:
            crud.skip = 0
        
        # Perform query by: id, params, open (all permitted record - by admin, owner or role assignment)
        case by
        of QueryWhereTypes.ID:
            ## get current records
            var getRecScript = computeSelectByIdScript(crud.tableName, crud.docIds, fields = fields)
            # append skip and limit params
            getRecScript.add(" SKIP ")
            getRecScript.add($crud.skip)
            getRecScript.add(" LIMIT ")
            getRecScript.add($crud.limit)

            # perform query for the tableName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
            # TODO: transform currentRecs into JSON based on projected fiedls or data model structure
            let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
              
            return getResMessage("success", ResponseMessage(value: %*(getRecs)))
        of QueryWhereTypes.PARAMS, QueryWhereTypes.QUERY:
            let selectQuery = computeSelectQuery(crud.tableName, crud.queryParam)
            let whereParam = computeWhereQuery(crud.where)

            var getRecScript = selectQuery & " " & whereParam
            # append skip and limit params
            getRecScript.add(" SKIP ")
            getRecScript.add($crud.skip)
            getRecScript.add(" LIMIT ")
            getRecScript.add($crud.limit)

            let getRecs =  crud.appDb.db.getAllRows(sql(getRecScript))
            # perform query for the tableName and deliver seq[Row] result to the client/consumer of the CRUD service, as json array
            # TODO: transform currentRecs into JSON based on projected fiedls or data model structure
            return getResMessage("success", ResponseMessage(value: %*(getRecs)))
        else:
            const okRes = OkayResponse(ok: false)
            return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: "Incomplete query conditions"))
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
