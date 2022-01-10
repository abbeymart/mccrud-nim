import strutils, algorithm, json

import types

## computeWhereQuery compose WHERE query from the queryParam
## 
proc computeWhereQuery*(qParam: JsonNode): string =
    # compute qParam script from qParam
    try:
        if qParam == nil :
                raise newException(WhereQueryError, "Where-params is required for the qParam condition(s)")
    
        # initialize query variable
        var whereQuery = "WHERE"
        for it in qParam.pairs:
            # assert val-type
            case qParam[it.key].kind
            of JString:
                echo it.key, "=", it.val
                # TODO: check string types - string, date & json
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)
            of JObject:
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)
            of JBool:
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)
            of JInt:
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)
            of JFloat:
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)    
            else:
                echo it.key, "=", it.val
                whereQuery = whereQuery & " " & it.key & "=" & $(it.val)

        
        
        return whereQuery
    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(WhereQueryError, getCurrentExceptionMsg())
