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

## computeWhereQuery compose WHERE quesy from the whereParams
proc computeWhereQuery*(whereParams: seq[WhereParam]): string =
    # initialize variable to compose where-query
    var whereQuery = " WHERE "

    # sort whereParams by groupOrder (ASC)
    var sortedGroups  = whereParams.sortedByIt(it.groupOrder)
    let groupsLen = sortedGroups.len()

    # variables to determine the end of groups and group-items
    var groupCount, itemCount = 0

    # iterate through whereParams (groups)
    for group in sortedGroups:
        groupCount += 1

        # sort groupCat items by fieldOrder (ASC)
        var sortedItems  = group.groupItems.sortedByIt(it.fieldOrder)
        let itemsLen = sortedItems.len()

        # compute the field-where-script
        var fieldQuery = " ("
        for groupItem in sortedItems:
            itemCount += 1
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

        # add closing bracket to complete the group-items query/script
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
