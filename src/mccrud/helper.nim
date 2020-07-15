#
#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details about the copyright / license.
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

## computeSelectByIdScript compose select SQL script by id(s) 
## 
proc computeSelectByIdScript*(collName: string; docIds:seq[string]; fields: seq[string] = @[] ): string =
    if docIds.len < 1 or collName == "":
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
            selectQuery.add(collName)
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
            selectQuery.add(collName)
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
proc computeSelectQuery*(collName: string;
                        queryParam: QueryParam = QueryParam();
                        queryType: string = "simple";
                        fields: seq[string] = @[]): string =
    if collName == "":
        raise newException(SelectQueryError, "Table/collection name is required for the select/read operation")                    
    
    try:
        # script, sorting, valid group item count variables
        var selectQuery = ""
        var sortedFields: seq[FieldItem] = @[]
        var fieldLen = 0                  # number of fields in the SELECT statement/query         
        var unspecifiedGroupItemCount = 0 # variable to determine unspecified fieldName(s) to check if query/script should be returned

        if queryParam == QueryParam() or queryParam.fieldItems.len() < 1:
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
        of "coll.field", "table.field":
            var fieldCount = 0      # fieldCount: determine the valid fields that can be processed
            selectQuery.add ("SELECT ") 
            for fieldItem in sortedFields:
                # check fieldName
                if fieldItem.fieldName == "":
                    inc unspecifiedGroupItemCount
                    continue
                inc fieldCount      # count valid field  
                if fieldItem.fieldColl != "":
                    selectQuery.add(" ")
                    selectQuery.add(fieldItem.fieldColl)
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
        # of "join":
        #     echo "TODO - join query"
        # of "cases":
        #     echo "TODO - cases query"
        else:
            # TODO: add join, cases etc queries...
            raise newException(SelectQueryError, "Unknown query type")
        # raise exception or return empty select statement , if no fieldName was specified
        if(unspecifiedGroupItemCount == fieldLen):
            raise newException(SelectQueryError, "No valid field names specified")
        
        # add table/collection to select from
        selectQuery.add(" FROM ")
        selectQuery.add(collName)
        selectQuery.add(" ")

        return selectQuery

    except:
        # raise exception or return empty select statement, for exception/error
        raise newException(SelectQueryError, getCurrentExceptionMsg())

## computeWhereQuery compose WHERE query from the whereParams
## 
proc computeWhereQuery*(whereParams: seq[WhereParam]): string =
    if whereParams.len < 1 :
                raise newException(WhereQueryError, "Where-params is required for the where condition(s)")
    
    # compute where script from whereParams
    try:
        # initialize group validation variables
        var groupsLen = 0
        var unspecifiedGroupCount = 0   # variable to determine group with empty/no fieldItems

        groupsLen = whereParams.len()

        # raise exception, if no group was specified or empty
        if(groupsLen < 1):
            raise newException(WhereQueryError, "No where-groups specified")

        # sort whereParams by groupOrder (ASC)
        var sortedGroups  = whereParams.sortedByIt(it.groupOrder)

        # variable for valid group count, i.e. group with groupItems
        var groupCount = 0          
            
        # iterate through whereParams (groups)
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
                    of "int", "float", "number", "bool", "boolean", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" = ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
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
                    of "int", "float", "number", "bool", "boolean", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <> ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of "lt", "<":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedGroupItemCount
                        continue
                    of "int", "float", "number", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" < ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of "lte", "<=":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedGroupItemCount
                        continue
                    of "int", "float", "number", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" <= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of "gte", ">=":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedGroupItemCount
                        continue
                    of "int", "float", "number", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" >= ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of "gt", ">":
                    case groupItem.fieldType
                    of "string", "uuid", "text", "varchar":
                        inc unspecifiedGroupItemCount
                        continue
                    of "int", "float", "number", "time":
                        fieldQuery.add(" ")
                        fieldQuery.add(groupItem.fieldName)
                        fieldQuery.add(" > ")
                        fieldQuery.add(groupItem.fieldValue)
                        fieldQuery.add(" ")
                    else:
                        raise newException(WhereQueryError, "Unknown or unsupported field type")
                    
                    if groupItem.groupOp != "" and groupItemCount < (groupItemsLen - unspecifiedGroupItemCount):
                            fieldQuery = fieldQuery & " " & groupItem.groupOp & " "
                of "in", "includes":
                    if groupItem.fieldSubQuery != QueryParam():
                        var inValues = "("
                        # include values from SELECT query (e.g. lookup table/collection)
                        let fieldSubQuery = groupItem.fieldSubQuery
                        let fieldSelectQuery = computeSelectQuery(fieldSubQuery.collName, fieldSubQuery)
                        let fieldWhereQuery = computeWhereQuery(fieldSubQuery.whereParams)
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
                            of "string", "uuid", "text", "varchar":
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
                grpLinkOp = "and"       # use "and" as default operator
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

## createScript compose insert SQL script
## 
proc computeCreateScript*(collName: string, actionParams: seq[QueryParam]): seq[string] = 
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
            let fieldLen = item.fieldItems.len
            for field in item.fieldItems:
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
                of "string", "uuid", "text", "varchar":
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

## updateScript compose update SQL script
## 
proc computeUpdateScript*(collName: string, actionParams: seq[QueryParam], docIds: seq[string]): seq[string] =
    if docIds.len < 1 or collName == "" or actionParams.len < 1 :
        raise newException(UpdateQueryError, "Table/collection name, doc-ids and action-params are required for the update operation")
    
    # compute update script from queryParams  
    try:
        var updateScripts: seq[string] = @[]
        var invalidUpdateItemCount = 0
        var updateItemCount = 0         # valid update item count
        for item in actionParams:
            var 
                itemScript = "UPDATE " & collName & " SET"
                fieldCount = 0
                missingField = 0
            let fieldLen = item.fieldItems.len
            for field in item.fieldItems:
                # check missing fieldName/Value
                if field.fieldName == "" or field.fieldValue == "":
                    inc missingField
                    continue
                inc fieldCount
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

                if fieldLen > 1 and fieldCount < (fieldLen - missingField):
                    itemScript.add(", ")
                else:
                    itemScript.add(" ")
            
            # validate/update script content based on valid field specifications
            if fieldCount > 0:
                inc updateItemCount
                updateScripts.add(itemScript)
            else:
                inc invalidUpdateItemCount
        
        # check is there was no valid update items
        if invalidUpdateItemCount == actionParams.len:
            raise newException(UpdateQueryError, "Invalid action-params")
        
        return updateScripts
    except:
        raise newException(UpdateQueryError, getCurrentExceptionMsg())

## deleteByIdScript compose delete SQL script by id(s) 
## 
proc computeDeleteByIdScript*(collName: string, docIds:seq[string]): string =
    if docIds.len < 1 or collName == "":
        raise newException(DeleteQueryError, "Table/collection name and record id(s) are required for the delete operation")
    try:
        var deleteScripts = ""
        let docIdsLen = docIds.len
        deleteScripts = "DELETE FROM " & collName & " WHERE id IN("
        var idCount = 0
        for id in docIds:
            inc idCount
            deleteScripts.add("'")
            deleteScripts.add(id)
            deleteScripts.add("'")
            if docIdsLen > 1 and idCount < docIdsLen:
                deleteScripts.add(", ")
        deleteScripts.add(")")
        return deleteScripts
    except:
        raise newException(DeleteQueryError, getCurrentExceptionMsg())

## deleteByParamScript compose delete SQL script by params
## 
proc computeDeleteByParamScript*(collName: string, whereParams: seq[WhereParam]): string =
    if whereParams.len < 1 or collName == "":
        raise newException(DeleteQueryError, "Table/collection name and where-params are required for the delete operation")
    try:
        var deleteScripts = ""
        let whereParam = computeWhereQuery(whereParams)
        deleteScripts = "DELETE FROM " & collName & " " & whereParam
        return deleteScripts
    except:
        raise newException(DeleteQueryError, getCurrentExceptionMsg())
