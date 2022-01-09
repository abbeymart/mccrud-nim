import strutils, algorithm

import ../crudtypes
import computeSelect

## computeWhereQuery compose WHERE query from the where
## 
proc computeWhereQuery*(where: seq[WhereParamType]): string =
    if where.len < 1 :
                raise newException(WhereQueryError, "Where-params is required for the where condition(s)")
    
    # compute where script from where
    try:
        # initialize group validation variables
        var groupsLen = 0
        var unspecifiedGroupCount = 0   # variable to determine group with empty/no fieldItems

        groupsLen = where.len()

        # raise exception, if no group was specified or empty
        if(groupsLen < 1):
            raise newException(WhereQueryError, "No where-groups specified")

        # sort where by groupOrder (ASC)
        var sortedGroups  = where.sortedByIt(it.groupOrder)

        # variable for valid group count, i.e. group with groupItems
        var groupCount = 0          
            
        # iterate through where (groups)
        var whereQuery = " WHERE "
        for group in sortedGroups:
            var
                unspecifiedGroupItemCount = 0 # variable to determine unspecified fieldName or fieldValue
                groupItemCount = 0      # valid groupItem count, i.e. group item with valid name and value

            let groupItemsLen = group.groupItems.len()
            # check groupItems length
            if groupItemsLen < 1:
                inc unspecifiedGroupCount
                continue
            inc groupCount          # count valid group, i.e. group with groupItems
            # sort group items by fieldOrder (ASC)
            var sortedItems  = group.groupItems.sortedByIt(it.fieldOrder)

            # compute the field-where-script
            var fieldQuery = " ("
            for groupItem in sortedItems:
                # check groupItem's fieldName and fieldValue
                if groupItem.fieldName == "" or groupItem.fieldValue == "":
                    inc unspecifiedGroupItemCount
                    continue
                inc groupItemCount      # count valid groupItem
                var fieldname = groupItem.fieldName
                if groupItem.fieldTable != "":
                    fieldname = groupItem.fieldTable & "." & groupItem.fieldName

                case groupItem.fieldOp:
                of OpTypes.EQ:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" = ")
                        fieldQuery.add("'")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add("'")
                        fieldQuery.add(" ")
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.BOOL, DataTypes.BOOLEAN, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" = ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp
                of OpTypes.NEQ:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <> ")
                        fieldQuery.add("'")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add("'")
                        fieldQuery.add(" ")
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.BOOL, DataTypes.BOOLEAN, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <> ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of OpTypes.LT:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        inc unspecifiedGroupItemCount
                        continue
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" < ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of OpTypes.LTE:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        inc unspecifiedGroupItemCount
                        continue
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of OpTypes.GTE:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        inc unspecifiedGroupItemCount
                        continue
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" >= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of OpTypes.GT:
                    case groupItem.fieldType
                    of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                        inc unspecifiedGroupItemCount
                        continue
                    of DataTypes.INT, DataTypes.FLOAT, DataTypes.NUMBER, DataTypes.TIME:
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" > ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of OpTypes.IN, OpTypes.INCLUDES:
                    if groupItem.fieldSubQuery != QueryParamType():
                        var inValues = "("
                        # include values from SELECT query (e.g. lookup table/collection)
                        let fieldSubQuery = groupItem.fieldSubQuery
                        let fieldSelectQuery = computeSelectQuery(fieldSubQuery.tableName, fieldSubQuery)
                        let fieldWhereQuery = computeWhereQuery(fieldSubQuery.where)
                        inValues = fieldSelectQuery & " " & fieldWhereQuery & " )"
                        
                        fieldQuery = fieldQuery & " " & fieldname & " IN " & (inValues)
                        
                        if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                    elif groupItem.fieldValues.len() > 0:
                        let fieldValueLen = groupItem.fieldValues.len
                        # compose the IN values from fieldValues
                        var inValues = "("
                        var valCount = 0        # valid field value count
                        var noValCount = 0      # invalid/missing field value count
                        for itemValue in groupItem.fieldValues:
                            # check for value itemValue
                            let itVal = $(itemValue)    # stringified for comparison check
                            if itVal == "":
                                inc noValCount
                                continue
                            inc valCount
                            case groupItem.fieldType
                            of DataTypes.STRING, DataTypes.UUID, DataTypes.TEXT, DataTypes.VARCHAR:
                                inValues.add("'")
                                inValues.add(itemValue)
                                inValues.add("'")
                                if valCount < groupItem.fieldValues.len:
                                    inValues.add(", ")
                            else:
                                inValues.add(itemValue)
                                if fieldValueLen > 1 and valCount < (fieldValueLen - noValCount):
                                    inValues.add(", ")
                        
                        inValues.add(") ")
                        fieldQuery = fieldQuery & " " & fieldname & " IN " & (inValues)
                        
                        if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                else:
                    raise newException(WhereQueryError, "Unknown or unsupported field operator")        
            # continue to the next group iteration, if fieldItems is empty for the current group 
            if unspecifiedGroupItemCount == groupItemsLen:
                continue
            # add closing bracket to complete the group-items query/script
            fieldQuery = fieldQuery & " ) "
            
            # validate acceptable groupLinkOperators (and || or)
            var grpLinkOp = group.groupLinkOp
            var groupLnOp = @["and", "or"]
            if grpLinkOp != "" and not groupLnOp.contains(grpLinkOp.toLower()):
                grpLinkOp = "and"      # use OpTypes.AND as default operator
                # raise newException(WhereQueryError, "Unacceptable group-link-operator (should be 'and', 'or')")
            
            # add optional groupLinkOp, if groupsLen > 1
            if groupsLen > 1 and groupCount < (groupsLen - unspecifiedGroupCount):
                fieldQuery = fieldQuery & " " & grpLinkOp.toUpper() & " "
                
            # compute where-script from the group-script, append in sequence by groupOrder 
            whereQuery = whereQuery & " " & fieldQuery
        
        # check WHERE script contains at least one condition, otherwise raise an exception
        if unspecifiedGroupCount == groupsLen:
            raise newException(WhereQueryError, "No valid where condition specified")
        
        return whereQuery
    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(WhereQueryError, getCurrentExceptionMsg())
