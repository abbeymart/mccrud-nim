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
## get-record operations constructor
proc newGetRecord*(appDb: Database;
                    collName: string;
                    userInfo: UserParam;
                    whereParams: seq[WhereParam];
                    docIds: seq[string] = @[]; 
                    options: Table[string, ValueType]): CrudParam =
    ## base / shared constructor
    result = newCrud(appDb, collName, userInfo, whereParams = whereParams, options )
    
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
        
        # perform query for the collName
        # TODO: get the model definition for the collName in order of the field(s)

        type UserColl = object
            id: string  # uuid
            username:string
            firstname: string
            lastname: string
            middlename: string
            email: string
            recovery_email: string
            lang: string
            is_active: bool
            desc: string
            profile: string  # jsonb 


        var getQueryScript = "SELECT * FROM " & crud.collName & " "

        getQueryScript.add(" SKIP ")
        getQueryScript.add($crud.skip)
        getQueryScript.add(" LIMIT ")
        getQueryScript.add($crud.limit)

        let getRecs =  crud.appDb.db.getAllRows(sql(getQueryScript))

        # transform/map getRecs into collName model definition

        # return mapped records as json array-objects 

        
    except:
        const okRes = OkayResponse(ok: false)
        return getResMessage("saveError", ResponseMessage(value: %*(okRes), message: getCurrentExceptionMsg()))

    