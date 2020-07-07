#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
#                  CRUD Helper Procedures
# 

## CRUD helper procedures/functions for the CRUD operations
## strToBool (val: string): bool | converts string input to boolean
## 
## strToTime (val: string): Time | coverts time value in string (parseable as int) to Time
## 
## computeSelectQuery | computes string of SQL scripts for query (read) operations
## 
## computeWhereQuery | computes string of SQL condition scripts for CRUD operations
## 
## computeCreateQuery | computes array/sequence of string of SQL scripts for insert operations
##
## computeUpdateQuery | computes array/sequence of string of SQL scripts for update operations
## 
## computeDeleteQuery | computes array/sequence of string of SQL scripts for delete operations
##  

import strutils, times, algorithm

import crudtypes

## strToBool procedure converts a string parameter to a boolean
proc strToBool*(val: string): bool =
    try:
        let strVal = val.toLower
        if strVal == "true" or strVal == "t" or strVal == "yes" or strVal == "y":
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
        # return the current time
        return Time()

## computeSelectQuery compose SELECT query from the queryParam
## queryType => simple, join, cases, subquery, combined etc.
proc computeSelectQuery*(collName: string; queryParam: QueryParam, queryType: string = "simple"): string =
    # initialize variable to compose the select-query
    var selectQuery = "SELECT"
    var sortedFields: seq[FieldItem] = @[]
    var fieldLen = 0                  # number of fields in the SELECT statement/query         
    var unspecifiedFieldNameCount = 0 # variable to determine unspecified fieldName(s) to check if query/script should be returned

    try:
        if queryParam.fieldItems.len() < 1:
            # SELECT all fields in the table / collection
            selectQuery.add(" * FROM ")
            selectQuery.add(collName)
            selectQuery.add(" ")
            return selectQuery
        elif queryParam.fieldItems.len() == 1:
            sortedFields = queryParam.fieldItems    # no sorting required for one field
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
    var unspecifiedGroupCount = 0

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
            inc groupCount
            let itemsLen = group.groupItems.len()
            # check groupItems length
            if itemsLen < 1:
                inc unspecifiedGroupCount
                continue

            # sort groupCat items by fieldOrder (ASC)
            var sortedItems  = group.groupItems.sortedByIt(it.fieldOrder)

            # compute the field-where-script
            var fieldQuery = " ("
            for groupItem in sortedItems:
                inc itemCount
                # check groupItem's fieldName and fieldValue
                if groupItem.fieldName == "" or groupItem.fieldValue == "":
                    inc unspecifiedFieldNameCount
                    continue

                var fieldname = groupItem.fieldName
                if groupItem.fieldColl != "":
                    fieldname = groupItem.fieldColl & "." & groupItem.fieldName

                case groupItem.fieldOp.toLower():
                of "eq", "=":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" = ")
                        fieldQuery.add("'")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add("'")
                        fieldQuery.add(" ")
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" = ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "neq", "!=", "<>":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <> ")
                        fieldQuery.add("'")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add("'")
                        fieldQuery.add(" ")
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <> ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "lt", "<":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedFieldNameCount
                        continue
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" < ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "lte", "<=":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedFieldNameCount
                        continue
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "gte", ">=":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedFieldNameCount
                        continue
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" >= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "gt", ">":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedFieldNameCount
                        continue
                    else:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" > ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "in", "includes":
                    # include values from SELECT query (e.g. lookup table/collection)
                    var inValues = "("
                    if groupItem.fieldSubQuery != QueryParam():
                        let fieldSubQuery = groupItem.fieldSubQuery
                        let fieldSelectQuery = computeSelectQuery(fieldSubQuery.collName, fieldSubQuery)
                        let fieldWhereQuery = computeWhereQuery(fieldSubQuery.whereParams)
                        inValues = fieldSelectQuery & " " & fieldWhereQuery & " )"
                        if groupItem.fieldSubQuery.collName != "":
                            fieldQuery = fieldQuery & " " & fieldname & " IN " & (inValues)
                            if groupItem.groupOp != "" and itemsLen > 1:
                                fieldQuery = fieldQuery & " " & groupItem.groupOp
                    elif groupItem.fieldValues.len() > 0:
                        # compose the IN values from fieldValues
                        var inValues = "("
                        var valCount = 0
                        var noValCount = 0
                        for itemValue in groupItem.fieldValues:
                            inc valCount
                            # check for value itemValue
                            let itVal = $(itemValue)
                            if itVal == "":
                                inc noValCount
                                continue
                            case groupItem.fieldType
                            of "string", "uuid", "text", "varchar":
                                inValues.add("'")
                                inValues.add(itemValue)
                                inValues.add("'")
                                if valCount < groupItem.fieldValues.len:
                                    inValues.add(", ")
                            else:
                                inValues.add(itemValue)
                                if valCount < groupItem.fieldValues.len:
                                    inValues.add(", ")
                            inValues.add(")")
                
                        if groupItem.groupOp != "" and itemsLen > 1 and itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & fieldname & " IN " & (inValues) & " " & groupItem.groupOp
                        
            # continue to the next group iteration, if fieldItems is empty for the current group 
            if unspecifiedFieldNameCount == itemCount:
                continue
            # add closing bracket to complete the group-items query/script
            fieldQuery = fieldQuery & " )"
            
            # validate acceptable groupLinkOperators (and || or)
            var groupLnOp = @["and", "or"]
            if groupLnOp.contains(group.groupLinkOp):
                raise newException(ValueError, "unacceptable group-link-operator (should be 'and', 'or')")
            
            # add optional groupLinkOp, if groupsLen > 1
            if groupsLen > 1 and groupCount < groupsLen and group.groupLinkOp != "":
                fieldQuery = fieldQuery & " " & group.groupLinkOp.toUpper() & " "
            elif groupsLen > 1 and groupCount < groupsLen and group.groupLinkOp == "":
                fieldQuery = fieldQuery & " AND "   # default groupLinkOp => AND
            else:
                fieldQuery = fieldQuery & " "
                
            # compute where-script from the group-script, append in sequence by groupOrder 
            whereQuery = whereQuery & " " & fieldQuery
        # TODO: check WHERE script contains at least one condition, otherwise return empty string
        
    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(ValueError, getCurrentExceptionMsg())

## createScript compose insert SQL script
## 
proc computeCreateScript*(collName: string, queryParams: seq[QueryParam]): seq[string] =
    # create script from queryParams
        var createScripts: seq[string] = @[]
        
        try:
            for item in queryParams:
                var itemScript = "INSERT INTO " & collName & " ("
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
                    of "string", "uuid", "text", "varchar":
                        itemValues.add("'")
                        itemValues.add(field.fieldValue)
                        itemValues.add("'")
                    else:
                        itemValues.add(field.fieldValue)
                    if fieldCount < item.fieldItems.len:
                        itemValues.add(", ")
                    else:
                        itemValues.add(" ")
                itemScript.add(" )")
                itemValues.add(" )")
                
                if missingField < fieldCount:
                    createScripts.add(itemScript & itemValues)
            return createScripts
        except:
            # raise exception or return empty select statement, for exception/error
            raise newException(ValueError, getCurrentExceptionMsg())

## updateScript compose update SQL script
## 
proc computeUpdateScript*(collName: string, queryParams: seq[QueryParam], docIds: seq[string]): seq[string] =
    # updated script from queryParams  
        try:
            var updateScripts: seq[string] = @[]
            for item in queryParams:
                var 
                    itemScript = "UPDATE " & collName & " SET"
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
                    itemScript.add(" = ")
                    case field.fieldType
                    of "string", "uuid", "text", "varchar":
                        itemScript.add("'")
                        itemScript.add(field.fieldValue)
                        itemScript.add("'")
                    else:
                        itemScript.add(field.fieldValue)

                    if fieldCount < item.fieldItems.len:
                        itemScript.add(", ")
                    else:
                        itemScript.add(" ")
                if missingField < fieldCount:
                    updateScripts.add(itemScript)
            return updateScripts
        except:
            # raise exception or return empty select statement, for exception/error
            raise newException(ValueError, getCurrentExceptionMsg())

## deleteByIdScript compose delete SQL script by id(s) 
## 
proc computeDeleteByIdScript*(collName: string, docIds:seq[string]): string =
        try:
            var deleteScripts: string = ""
            if docIds.len < 1:
                raise newException(ValueError, "record id(s) is(are) required for delete operation")
            deleteScripts = "DELETE FROM " & collName & " WHERE id IN("
            var idCount = 0
            for id in docIds:
                inc idCount
                deleteScripts.add("'")
                deleteScripts.add(id)
                deleteScripts.add("'")
                if idCount < docIds.len:
                    deleteScripts.add(", ")
            return deleteScripts
        except:
            # raise exception or return empty select statement, for exception/error
            raise newException(ValueError, getCurrentExceptionMsg())

## deleteByParamScript compose delete SQL script by params
proc computeDeleteByParamScript*(collName: string, whereParams: seq[WhereParam]): string =
        try:
            var deleteScripts: string = ""
            let whereParam = computeWhereQuery(whereParams)
            if whereParams.len < 1 or whereParam == "":
                raise newException(ValueError, "where condition is required for delete operation")
            deleteScripts = "DELETE FROM " & collName & " " & whereParam
            return deleteScripts
        except:
            # raise exception or return empty select statement, for exception/error
            raise newException(ValueError, getCurrentExceptionMsg())

## selectByIdScript compose select SQL script by id(s) 
## 
proc computeSelectByIdScript*(collName: string, docIds:seq[string]): string =
        try:
            if docIds.len < 1:
                raise newException(ValueError, "record id(s) is(are) required for delete operation")
            var currentRecScript = "SELECT * FROM "
            currentRecScript.add(collName)
            currentRecScript.add(" WHERE id IN (")
            var idCount =  0
            for id in docIds:
                idCount += 1
                currentRecScript.add("'")
                currentRecScript.add(id)
                currentRecScript.add("'")
                if idCount < docIds.len:
                    currentRecScript.add(", ")
            currentRecScript.add(" )")
            return currentRecScript
        except:
            # raise exception or return empty select statement, for exception/error
            raise newException(ValueError, getCurrentExceptionMsg())
