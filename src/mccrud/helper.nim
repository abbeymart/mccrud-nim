# CRUD helper procedures/functions

import strutils, times, algorithm

import crudtypes

## strToBool procedure converts a string parameter to a boolean
proc strToBool*(val: string): bool =
    try:
        if val.toLower() == "true":
            return true
        if val.toLower() == "t":
            return true
        elif val.toLower() == "yes":
            return true
        elif val.toLower() == "y":
            return true
        elif val.parseInt > 0:
            return true
        else:
            return false 
    except:
        return false

## strToTime converts time from string to Time format
proc strToTime*(val: string): Time =
    try:
        result = fromUnix(val.parseInt)
    except:
        return Time()

## computeSelectQuery compose SELECT query from the queryParam
## queryType => simple, join, cases, subquery, combined etc.
proc computeSelectQuery*(collName: string; queryParam: QueryParam, queryType: string = "simple"): string =
    # initialize variable to compose the select-query
    var selectQuery = "SELECT"
    var sortedFields: seq[FieldItem] = @[]
    var fieldLen = 0           
    var unspecifiedFieldNameCount = 0 # variable to determine unspecified fieldNames

    try:
        if queryParam.fieldItems.len() == 0 or queryParam.fieldItems.len() < 1:
            selectQuery.add(" * FROM ")
            selectQuery.add(collName)
            selectQuery.add(" ")
            return selectQuery
        elif queryParam.fieldItems.len() == 1:
            sortedFields = queryParam.fieldItems    # no sorting required for one item
            fieldLen = 1
        else:
            # sort queryParam.fieldItems by fieldOrder (ASC)
            sortedFields  = queryParam.fieldItems.sortedByIt(it.fieldOrder)
            fieldLen = sortedFields.len()

        # iterate through sortedFields and compose select-query/script, by queryType
        case queryType.toLower():
        of "simple":
            var fieldCount = 0      # fieldCount: determine the current field count 
            for fieldItem in sortedFields:
                fieldCount += 1
                # check fieldName
                if fieldItem.fieldName == "":
                    unspecifiedFieldNameCount += 1
                    continue
                selectQuery.add(" ")
                selectQuery.add(fieldItem.fieldName)
                if fieldLen > 1 and fieldCount < fieldLen:
                    selectQuery.add(", ")
                else:
                    selectQuery.add(" ")
        of "coll.field", "table.field":
            var fieldCount = 0
            for fieldItem in sortedFields:
                fieldCount += 1
                # check fieldName
                if fieldItem.fieldName == "":
                    unspecifiedFieldNameCount += 1
                    continue        
                if fieldItem.fieldColl != "":
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldColl)
                    selectQuery.add(".")
                    selectQuery.add(fieldItem.fieldName)
                    if fieldLen > 1 and fieldCount < fieldLen:
                        selectQuery.add(", ")
                    else:
                        selectQuery.add(" ")
                else:
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldName)
                    if fieldLen > 1 and fieldCount < fieldLen:
                        selectQuery.add(", ")
                    else:
                        selectQuery.add(" ")
        of "join":
            echo "join"
        of "cases":
            echo "cases"
        else:
            echo "default"
        
        # raise exception or return empty select statement , if no fieldName was specified
        if(unspecifiedFieldNameCount == fieldLen):
            raise newException(ValueError, "error: no field-names specified")
            # return "error: no field-names specified"
        
        # add table/collection to select from
        selectQuery.add(" FROM ")
        selectQuery.add(collName)
        selectQuery.add(" ")

        return selectQuery

    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(ValueError, getCurrentExceptionMsg())
        # return ("error: " & getCurrentExceptionMsg())

## computeWhereQuery compose WHERE query from the whereParams
proc computeWhereQuery*(whereParams: seq[WhereParam]): string =
    # initialize variable to compose where-query
    var whereQuery = " WHERE "
    var groupsLen = 0
    var unspecifiedFieldNameCount = 0 # variable to determine unspecified fieldNames

    try:
        groupsLen = whereParams.len()

        # raise exception or return empty select statement , if no group was specified
        if(groupsLen == 0 or groupsLen < 1):
            raise newException(ValueError, "error: no where-groups specified")
            # return "error: no where-groups specified"
        
        # sort whereParams by groupOrder (ASC)
        var sortedGroups  = whereParams.sortedByIt(it.groupOrder)

        # variables to determine the end of groups and group-items
        var groupCount, itemCount = 0

        # iterate through whereParams (groups)
        for group in sortedGroups:
            groupCount += 1
            let itemsLen = group.groupItems.len()
            # check groupItems length
            if itemsLen == 0 or itemsLen < 1:
                continue

            # sort groupCat items by fieldOrder (ASC)
            var sortedItems  = group.groupItems.sortedByIt(it.fieldOrder)

            # compute the field-where-script
            var fieldQuery = " ("
            for groupItem in sortedItems:
                itemCount += 1
                # check groupItems length
                if groupItem.fieldName == "":
                    unspecifiedFieldNameCount += 1
                    continue

                var fieldname = groupItem.fieldName
                if groupItem.fieldColl != "":
                    fieldname = groupItem.fieldColl & "." & groupItem.fieldName

                case groupItem.fieldOp.toLower():
                of "eq", "=":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " = " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "neq", "!=", "<>":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " <> " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "lt", "<":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " < " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "lte", "<=":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " <= " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "gte", ">=":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " >= " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "gt", ">":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " > " & "'" & groupItem.fieldValue & "'"
                    if groupItem.groupOp != "":
                        if itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "in", "includes":
                    let fieldSubQuery = groupItem.fieldSubQuery
                    let fieldSelectQuery = computeSelectQuery(fieldSubQuery.collName, fieldSubQuery)
                    let fieldWhereQuery = computeWhereQuery(fieldSubQuery.whereParams)
                    let fieldInSelectQuery = fieldSelectQuery & " " & fieldWhereQuery

                    if groupItem.fieldValues.len() > 0:
                        # compose the IN values from fieldValues
                        var inValues = "("
                        for itemValue in groupItem.fieldValues:
                            if groupItem.fieldType == "string":
                                inValues.add("'")
                                inValues.add(itemValue)
                                inValues.add("'")
                                inValues.add(", ")
                            elif groupItem.fieldType == "int" or groupItem.fieldType == "float":
                                inValues.add(itemValue)
                                inValues.add(", ")
                        if groupItem.fieldValue != "":
                            fieldQuery = fieldQuery & fieldname & " IN " & inValues
                        if groupItem.groupOp != "":
                            if itemsLen > 1 and itemCount < itemsLen:
                                fieldQuery = fieldQuery & " " & groupItem.groupOp
                    elif groupItem.fieldSubQuery.collName != "":
                        if groupItem.fieldValue != "":
                            fieldQuery = fieldQuery & fieldname & " IN " & (fieldInSelectQuery)  & "'"
                        if groupItem.groupOp != "":
                            if itemsLen > 1 and itemCount < itemsLen:
                                fieldQuery = fieldQuery & " " & groupItem.groupOp

            # add closing bracket to complete the group-items query/script or continue
            if unspecifiedFieldNameCount == itemCount:
                continue
                
            fieldQuery = fieldQuery & " )"
            
            # add optional groupLinkOp, if groupsLen > 1
            if groupsLen > 1 and groupCount < groupsLen and group.groupLinkOp != "":
                fieldQuery = fieldQuery & " " & group.groupLinkOp.toUpper() & " "
            elif groupsLen > 1 and groupCount < groupsLen and group.groupLinkOp == "":
                fieldQuery = fieldQuery & " AND "   # default groupLinkOp => AND
            else:
                fieldQuery = fieldQuery & " "
                
            # compute where-script from the group-script, append in sequence by groupOrder 
            whereQuery = whereQuery & " " & fieldQuery

    except:
        # return empty select statement, for exception/error
        return ("error: " & getCurrentExceptionMsg())

## createScript compose insert SQL script
## 
proc computeCreateScript*(collName: string, queryParams: seq[QueryParam]): seq[string] =
    # create script from rec param
        var createScripts: seq[string] = @[]
        
        for item in queryParams:
            var itemScript = "INSERT INTO " & collName
            var itemValues = " VALUES("
            var 
                fieldCount = 0
                missingField = 0
            for field in item.fieldItems:
                fieldCount += 1
                # check missing fieldName/Value
                if field.fieldName == "" or field.fieldValue == "":
                    missingField += 1
                    continue
                itemScript.add(" ")
                itemScript.add(field.fieldName)
                if fieldCount < item.fieldItems.len:
                    itemScript.add(", ")
                else:
                    itemScript.add(" ")
                case field.fieldType
                of "string", "uuid":
                    itemValues.add("'")
                    itemValues.add(field.fieldValue)
                    itemValues.add("'")
                else:
                    itemValues.add(field.fieldValue)
                if fieldCount < item.fieldItems.len:
                    itemValues.add(", ")
                else:
                    itemValues.add(" ")
            if missingField < fieldCount:
                createScripts.add(itemScript)
        
## updateScript compose update SQL script
## 
proc computeUpdateScript*(collName: string, queryParams: seq[QueryParam], docIds: seq[string]): seq[string] =
    # create script from rec param
        var updateScripts: seq[string] = @[]
        
        for item in queryParams:
            var itemScript = "INSERT INTO " & collName
            var itemValues = " VALUES("
            var 
                fieldCount = 0
                missingField = 0
            for field in item.fieldItems:
                fieldCount += 1
                # check missing fieldName/Value
                if field.fieldName == "" or field.fieldValue == "":
                    missingField += 1
                    continue
                itemScript.add(" ")
                itemScript.add(field.fieldName)
                if fieldCount < item.fieldItems.len:
                    itemScript.add(", ")
                else:
                    itemScript.add(" ")
                case field.fieldType
                of "string", "uuid":
                    itemValues.add("'")
                    itemValues.add(field.fieldValue)
                    itemValues.add("'")
                else:
                    itemValues.add(field.fieldValue)
                if fieldCount < item.fieldItems.len:
                    itemValues.add(", ")
                else:
                    itemValues.add(" ")
            if missingField < fieldCount:
                updateScripts.add(itemScript)

## deleteScript compose delete SQL script
## 
