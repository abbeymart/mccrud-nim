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
##
import crud

# constructor
## save-record operations constructor
proc newGetRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    actionParams: seq[QueryParam];
                    docIds: seq[string] = @[]; 
                    options: Table[string, ValueType]): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, actionParams = actionParams, options )
    
    ## specific/sub-set constructor variable
    result.docIds = @[]
    result.currentRecords = @[]
    
    result.roleServices = @[]
    result.recExistMessage = "Save / update error or duplicate records exist: "
    result.unAuthMessage = "Action / task not authorised or permitted "

proc getRecord*(crud: CrudParam; by: string;
                    docIds: seq[string] = @[];
                    whereParams: seq[WhereParam] = @[]): ResponseMessage =

    
    
    try:
        # update crud instance ref-variables
        if crud.docIds.len < 1 and docIds.len > 0:
            crud.docIds = docIds
        if crud.whereParams.len < 1 and whereParams.len > 0:
            crud.whereParams = whereParams

        # validate required inputs by action-type
        if by == "id" and crud.docIds.len < 1:
            # return error message
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by id (docIds[]) is required"))
        elif whereParams.len < 1:
            return getResMessage("paramsError", ResponseMessage(value: nil, message: "Delete condition by params (whereParams) is required"))
        
        echo "success"
        # validate taskPermission, otherwise send unauthorized response

        if not crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))
    
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))
  
proc getAllRecords*(crud: CrudParam): ResponseMessage =  
    try:
        echo "success"
        # validate that checkAccess is true, otherwise send unauthorized response
        if not crud.checkAccess:
            const okRes = OkayResponse(ok: false)
            return getResMessage("unAuthorized", ResponseMessage(value: %*(okRes), message: "Operation not authorized"))
    
        # check query params, skip and limit(records to return to 100,000)
        if crud.limit > 100000:
            crud.limit = 100000

        if crud.skip < 0:
            crud.skip = 0
        
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))

    