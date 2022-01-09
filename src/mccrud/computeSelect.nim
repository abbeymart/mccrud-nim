import algorithm
import ../crudtypes

## computeSelectByIdScript compose select SQL script by id(s) 
## 
proc computeSelectByIdScript*(tableName: string; docIds:seq[string]; fields: seq[string] = @[] ): string =
    if docIds.len < 1 or tableName == "":
        raise newException(SelectQueryError, "table/collection name and record id(s) are required for the select/read operation")
    try:   
        var selectQuery = ""
        let 
            fieldLen = fields.len
            docIdLen = docIds.len
        if fieldLen > 0:
            var fieldCount = 0
            # get record(s) based on projected/provided field names (seq[string])
            selectQuery.add ("SELECT ")
            for field in fields:
                inc fieldCount
                selectQuery.add(field)
                if fieldLen > 1 and fieldCount < fieldLen:
                    selectQuery.add(", ")
            selectQuery.add(" FROM ")
            selectQuery.add(tableName)
            selectQuery.add(" WHERE id IN (")
            var idCount =  0
            for id in docIds:
                inc idCount
                selectQuery.add("'")
                selectQuery.add(id)
                selectQuery.add("'")
                if docIdLen > 1 and idCount < docIdLen:
                    selectQuery.add(", ")
            selectQuery.add(" )")
        else:
            selectQuery = "SELECT * FROM "
            selectQuery.add(tableName)
            selectQuery.add(" WHERE id IN (")
            var idCount =  0
            for id in docIds:
                inc idCount
                selectQuery.add("'")
                selectQuery.add(id)
                selectQuery.add("'")
                if docIdLen > 1 and idCount < docIdLen:
                    selectQuery.add(", ")
            selectQuery.add(" )")
        
        return selectQuery
    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(SelectQueryError, getCurrentExceptionMsg())

## computeSelectQuery compose SELECT query from the queryParam
## queryType => simple, join, cases, subquery, combined etc.
proc computeSelectQuery*(tableName: string;
                        queryParam: QueryParamType = QueryParamType();
                        queryType: QueryTypes = QueryTypes.SELECT;
                        fields: seq[string] = @[]): string =
    if tableName == "":
        raise newException(SelectQueryError, "Table/collection name is required for the select/read operation")                    
    
    try:
        # script, sorting, valid group item count variables
        var selectQuery = ""
        var sortedFields: seq[ReadFieldType] = @[]
        var fieldLen = 0                  # number of fields in the SELECT statement/query         
        var unspecifiedGroupItemCount = 0 # variable to determine unspecified fieldName(s) to check if query/script should be returned

        if queryParam == QueryParamType() or queryParam.fields.len() < 1:
            if fields.len > 0:
                var fieldCount = 0
                fieldLen = fields.len
                # get record(s) based on projected/provided field names (seq[string])
                selectQuery.add ("SELECT ")
                for field in fields:
                    inc fieldCount
                    selectQuery.add(field)
                    if fieldLen > 1 and fieldCount < fieldLen:
                        selectQuery.add(", ")
                    else:
                        selectQuery.add(" ")
            # SELECT all fields in the table / collection
            else:
                selectQuery.add("SELECT * ")

            # add remaining query/script information 
            selectQuery.add(" FROM ")
            selectQuery.add(tableName)
            selectQuery.add(" ")
            return selectQuery
        elif queryParam.fields.len() == 1:
            sortedFields = queryParam.fields    # no sorting required for one field
            fieldLen = 1
        else:
            # sort queryParam.fieldItems by fieldOrder (ASC)
            sortedFields  = queryParam.fields.sortedByIt(it.fieldOrder)
            fieldLen = sortedFields.len()

        # iterate through sortedFields and compose select-query/script, by queryType
        case queryType:
        of QueryTypes.SELECT:
            var fieldCount = 0      # fieldCount: determine the valid fields that can be processed
            selectQuery.add ("SELECT ") 
            for fieldItem in sortedFields:
                # check fieldName
                if fieldItem.fieldName == "":
                    inc unspecifiedGroupItemCount
                    continue
                inc fieldCount      # count valid field
                selectQuery.add(fieldItem.fieldName)
                if fieldLen > 1 and fieldCount < (fieldLen - unspecifiedGroupItemCount):
                    selectQuery.add(", ")
                else:
                    selectQuery.add(" ")
        of QueryTypes.SELECT_TABLE_FIELD, QueryTypes.SELECT_COLLECTION_DOC:
            var fieldCount = 0      # fieldCount: determine the valid fields that can be processed
            selectQuery.add ("SELECT ") 
            for fieldItem in sortedFields:
                # check fieldName
                if fieldItem.fieldName == "":
                    inc unspecifiedGroupItemCount
                    continue
                inc fieldCount      # count valid field  
                if fieldItem.tableName != "":
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.tableName)
                    selectQuery.add(".")
                    selectQuery.add(fieldItem.fieldName)
                    if fieldLen > 1 and fieldCount < (fieldLen - unspecifiedGroupItemCount):
                        selectQuery.add(", ")
                    else:
                        selectQuery.add(" ")
                else:
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldName)
                    if fieldLen > 1 and fieldCount < (fieldLen - unspecifiedGroupItemCount):
                        selectQuery.add(", ")
                    else:
                        selectQuery.add(" ")
        of QueryTypes.SELECT_INCLUDE_ONE_TO_ONE:
            echo "TODO - select one-to-one target record{}"
        of QueryTypes.SELECT_INCLUDE_ONE_TO_MANY:
            echo "TODO - select one-to-many target records[]"
        of QueryTypes.SELECT_INCLUDE_MANY_TO_MANY:
            echo "TODO - select many-to-many source/target records[]"
        of QueryTypes.INNER_JOIN:
            echo "TODO - select INNER_JOIN query"
        of QueryTypes.OUTER_LEFT_JOIN:
            echo "TODO - select OUTER_LEFT_JOIN query"
        of QueryTypes.OUTER_RIGHT_JOIN:
            echo "TODO - select OUTER_RIGHT_JOIN query"
        of QueryTypes.OUTER_FULL_JOIN:
            echo "TODO - select OUTER_FULL_JOIN query"
        of QueryTypes.SELF_JOIN:
            echo "TODO - select SELF_JOIN query"
        of QueryTypes.CASE:
            echo "TODO - case query"
        of QueryTypes.UNION:
            echo "TODO - union query"
        of QueryTypes.SELECT_FROM:
            echo "TODO - select from query"
        of QueryTypes.INSERT_INTO:
            echo "TODO - insert into query"
        else:
            raise newException(SelectQueryError, "Unknown query type")
        # raise exception or return empty select statement , if no fieldName was specified
        if(unspecifiedGroupItemCount == fieldLen):
            raise newException(SelectQueryError, "No valid field names specified")
        
        # add table/collection to select from
        selectQuery.add(" FROM ")
        selectQuery.add(tableName)
        selectQuery.add(" ")

        return selectQuery

    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(SelectQueryError, getCurrentExceptionMsg())
