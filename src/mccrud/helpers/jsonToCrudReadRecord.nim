## Convert json/object from client to CRUD meta data for CRUD operation
## 
## 
import json, tables
import ../crudtypes

# Convert jsonToObj to QuerySaveParamType | QueryReadParamType | QueryDeleteParamType

var 
    saveFields: seq[SaveFieldType] = @[]
    readFields: seq[ReadFieldType] = @[]
    deleteFields: seq[DeleteFieldType] = @[]
    updateFields: seq[UpdateFieldType] = @[]
    whereParam: seq[WhereParamType] = @[]

proc jsonToCrudReadRecord(model: ModelType, jNode: JsonNode): SaveParamType =
    # TODO: compose CRUD meta-data based on JSON data request and defined model
    for fieldName, fieldDesc in model.recordDesc.pairs():
        # errorChecking
        var errorMessage = ""
        var 
            validField: bool = false
            defaultValue = ""
            validaPattern = false

        # check the key type from userModel
        var fieldType = fieldDesc.fieldType
        var fieldValue: string      # cast to fieldType
        
        # check the jNode for key info, validate and set value or capture exception/value-error
        case fieldType
        of DataTypes.STRING:
            fieldValue = jNode{fieldName}.getStr("")
            # TODO: validate fieldValue: null / defaultValue, validate... 
            # validateProc
            if not fieldDesc.validate():
                validField = false
            # null value check:
            if fieldDesc.notNull and fieldValue == "" and fieldDesc.defaultValue() == "":
                validField = false
                errorMessage.add(fieldName)
                errorMessage.add(":")
                errorMessage.add("Field value cannot be null or empty")
            elif fieldDesc.notNull and fieldValue == "" and fieldDesc.defaultValue() != "":
                fieldValue = fieldDesc.defaultValue()
                validField = true
            elif fieldDesc.notNull and fieldValue == "":
                validField = false
            else:
                validField = true
            
            if validField and errorMessage == "":
                saveFields.add(
                SaveFieldType(
                fieldName: fieldName,
                fieldValue: fieldValue,
                fieldType: DataTypes.STRING)    
                )
        
        of DataTypes.BOOL, DataTypes.BOOLEAN:
            let jValue = jNode{fieldName}.getBool(false)
            if jValue:
                fieldValue = "true"
            else:
                fieldValue = "false"
            # TODO: validate fieldValue: null / defaultValue, validate... 
            # validateProc
            if not fieldDesc.validate():
                validField = false
            # null value check:
            if fieldDesc.notNull and fieldValue == "" and fieldDesc.defaultValue() == "":
                validField = false
                errorMessage.add(fieldName)
                errorMessage.add(":")
                errorMessage.add("Field value cannot be null or empty")
            elif fieldDesc.notNull and fieldValue == "" and fieldDesc.defaultValue() != "":
                fieldValue = fieldDesc.defaultValue()
                validField = true
            elif fieldDesc.notNull and fieldValue == "":
                validField = false
            else:
                validField = true
            
            if validField and errorMessage == "":
                saveFields.add(
                SaveFieldType(
                fieldName: fieldName,
                fieldValue: fieldValue,
                fieldType: DataTypes.STRING)    
                )
        
        of DataTypes.INT:
            let jValue = jNode{fieldName}.getInt(0)
        else:
            echo "perform all other cases or return value-error/unsupported-type exception"
        # TODO: add other cases for all DataTypes

    
    # check errorMessage

    result = SaveParamType(
        tableName: "users",
        fields: saveFields,
        where: whereParam,
        )
