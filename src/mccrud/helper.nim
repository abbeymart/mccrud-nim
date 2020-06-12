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
            sortedFields = queryParam.fieldItems
        else:
            # sort queryParam.fieldItems by fieldOrder (ASC)
            sortedFields  = queryParam.fieldItems.sortedByIt(it.fieldOrder)
            fieldLen = sortedFields.len()

        # iterate through sortedFields and compose select-query/script, by queryType
        case queryType:
        of "simple":
            for fieldItem in sortedFields:
                # check fieldName
                if fieldItem.fieldName == "":
                    unspecifiedFieldNameCount += 1
                    continue
                selectQuery.add(" ")
                selectQuery.add(fieldItem.fieldName)
                selectQuery.add(", ")
        of "cases":
            for fieldItem in sortedFields:
                if fieldItem.fieldName == "":
                    unspecifiedFieldNameCount += 1
                    continue        
                if fieldItem.fieldColl != "":
                    # selectQuery = selectQuery & " " & fieldItem.fieldColl & "." & fieldItem.fieldName & " "
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldColl)
                    selectQuery.add(".")
                    selectQuery.add(fieldItem.fieldName)
                    selectQuery.add(", ")
                else:
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldName)
                    selectQuery.add(", ")
        of "join":
            echo "join"
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
                        fieldQuery = fieldQuery & fieldname & " = " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                        else:
                            fieldQuery = fieldQuery & " "
                of "neq", "!=", "<>":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & " NOT " & fieldname & " = " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                        else:
                            fieldQuery = fieldQuery & " "
                of "lt", "<":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " < " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of "lte", "<=":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " <= " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                        else:
                            fieldQuery = fieldQuery & " "
                of "gte", ">=":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " >= " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                        else:
                            fieldQuery = fieldQuery & " "
                of "gt", ">":
                    if groupItem.fieldValue != "":
                        fieldQuery = fieldQuery & fieldname & " > " & groupItem.fieldValue
                    if groupItem.groupOp != "":
                        if itemCount < itemsLen:
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                        else:
                            fieldQuery = fieldQuery & " "

            # add closing bracket to complete the group-items query/script or continue
            if unspecifiedFieldNameCount == itemCount:
                continue
                
            fieldQuery = fieldQuery & " )"
            
            # add optional groupLinkOp, if groupLen > 1
            if groupCount < groupsLen and group.groupLinkOp != "":
                fieldQuery = fieldQuery & " " & group.groupLinkOp.toUpperAscii() & " "
            elif groupCount < groupsLen and group.groupLinkOp == "":
                fieldQuery = fieldQuery & " AND "   # default groupLinkOp => AND
            else:
                fieldQuery = fieldQuery & " "
                
            # compute where-script from the group-script, append in sequence by groupOrder 
            whereQuery = whereQuery & " " & fieldQuery

    except:
        # return empty select statement, for exception/error
        return ("error: " & getCurrentExceptionMsg())
