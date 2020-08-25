## Convert json/object from client to CRUD meta data for CRUD operation
## 
## 
import json, tables
import ../crudtypes

# Convert jsonToObj to QuerySaveParamType | QueryReadParamType | QueryDeleteParamType

var 
    saveFields: seq[SaveFieldType] = @[]
    whereParam: seq[WhereParamType] = @[]

type
    UserProfileType* = object
        id: string
        username: string
        email: string
        firstName: string
        lastName: string
        phone: string

# convert JSON inputs to typed model definition

proc jsonToCrudSaveRec*(model: auto, jNode: JsonNode): UserProfileType =
    # TODO: convert jNode to model-definition
    echo "testing"
    try:
        result = to(jNode, UserProfileType)
    except:
        raise newException(ValueError, getCurrentExceptionMsg())
