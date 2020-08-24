import ../crudtypes

## updateScript compose update SQL script
## 
proc computeUpdateScript*(tableName: string, actionParams: seq[SaveParamType], docIds: seq[string]): seq[string] =
    if docIds.len < 1 or tableName == "" or actionParams.len < 1 :
        raise newException(UpdateQueryError, "Table/collection name, doc-ids and action-params are required for the update operation")
    
    # compute update script from queryParams  
    try:
        var updateScripts: seq[string] = @[]
        var invalidUpdateItemCount = 0
        var updateItemCount = 0         # valid update item count
        for item in actionParams:
            var 
                itemScript = "UPDATE " & tableName & " SET"
                fieldCount = 0
                missingField = 0
            let fieldLen = item.fields.len
            for field in item.fields:
                # check missing fieldName/Value
                if field.fieldName == "" or field.fieldValue == "":
                    inc missingField
                    continue
                inc fieldCount
                itemScript.add(" ")
                itemScript.add(field.fieldName)
                itemScript.add(" = ")
                
                case field.fieldType
                of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                    itemScript.add("'")
                    itemScript.add(field.fieldValue)
                    itemScript.add("'")
                else:
                    itemScript.add(field.fieldValue)

                if fieldLen > 1 and fieldCount < (fieldLen - missingField):
                    itemScript.add(", ")
                else:
                    itemScript.add(" ")
            
            # validate/update script content based on valid field specifications
            if fieldCount > 0:
                inc updateItemCount
                updateScripts.add(itemScript)
            else:
                inc invalidUpdateItemCount
        
        # check is there was no valid update items
        if invalidUpdateItemCount == actionParams.len:
            raise newException(UpdateQueryError, "Invalid action-params")
        
        return updateScripts
    except:
        raise newException(UpdateQueryError, getCurrentExceptionMsg())
