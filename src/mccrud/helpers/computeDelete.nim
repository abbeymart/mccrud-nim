import ../crudtypes
import computeWhere

## deleteByIdScript compose delete SQL script by id(s) 
## 
proc computeDeleteByIdScript*(tableName: string, docIds:seq[string]): string =
    if docIds.len < 1 or tableName == "":
        raise newException(DeleteQueryError, "Table/collection name and record id(s) are required for the delete operation")
    try:
        var deleteScripts = ""
        let docIdsLen = docIds.len
        deleteScripts = "DELETE FROM " & tableName & " WHERE id IN("
        var idCount = 0
        for id in docIds:
            inc idCount
            deleteScripts.add("'")
            deleteScripts.add(id)
            deleteScripts.add("'")
            if docIdsLen > 1 and idCount < docIdsLen:
                deleteScripts.add(", ")
        deleteScripts.add(")")
        return deleteScripts
    except:
        raise newException(DeleteQueryError, getCurrentExceptionMsg())

## deleteByParamScript compose delete SQL script by params
## 
proc computeDeleteByParamScript*(tableName: string, where: seq[WhereParamType]): string =
    if where.len < 1 or tableName == "":
        raise newException(DeleteQueryError, "Table/collection name and where-params are required for the delete operation")
    try:
        var deleteScripts = ""
        let whereParam = computeWhereQuery(where)
        deleteScripts = "DELETE FROM " & tableName & " " & whereParam
        return deleteScripts
    except:
        raise newException(DeleteQueryError, getCurrentExceptionMsg())
