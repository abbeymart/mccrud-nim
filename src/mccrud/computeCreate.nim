import ../crudtypes

## createScript compose insert SQL script
## 
proc computeCreateScript*(collName: string, actionParams: seq[SaveParamType]): seq[string] = 
    if collName == "" or actionParams.len < 1 :
        raise newException(CreateQueryError, "Table/collection name and action-params are required for the create operation")
    
    # lower-case the collName
    # var colName = collName.toLower()

    # computed create script from queryParams    
    try:
        var createScripts: seq[string] = @[]
        var invalidCreateItemCount = 0
        var createItemCount = 0         # valid create item count
        for item in actionParams:
            var itemScript = "INSERT INTO " & collName & " ("
            var itemValues = " VALUES("
            var 
                fieldCount = 0      # valid field count
                missingField = 0    # invalid field name/value count
            let fieldLen = item.fields.len
            for field in item.fields:
                # check missing fieldName/Value
                if field.fieldName == "" or field.fieldValue == "":
                    inc missingField
                    continue
                inc fieldCount
                itemScript.add(" ")
                itemScript.add(field.fieldName)
                if fieldLen > 1 and fieldCount < (fieldLen - missingField):
                    itemScript.add(", ")
                else:
                    itemScript.add(" ")
                
                case field.fieldType
                of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                    itemValues.add("'")
                    itemValues.add(field.fieldValue)
                    itemValues.add("'")
                else:
                    itemValues.add(field.fieldValue)
                
                if fieldLen > 1 and fieldCount < (fieldLen - missingField):
                    itemValues.add(", ")
                else:
                    itemValues.add(" ")
            itemScript.add(" )")
            itemValues.add(" )")

            # validate/update script content based on valid field specifications 
            if fieldCount > 0:
                inc createItemCount
                createScripts.add(itemScript & itemValues)
            else:
                inc invalidCreateItemCount
        
        # check is there was no valid create items
        if invalidCreateItemCount == actionParams.len:
            raise newException(CreateQueryError, "Invalid action-params")

        return createScripts
    except:
        raise newException(CreateQueryError, getCurrentExceptionMsg())
