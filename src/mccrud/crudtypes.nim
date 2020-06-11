#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#       See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 
##                   CRUD Package types
##
import json, tables
import mcdb, mctranslog

# Define crud types
type
    ValueType* = int | string | float | bool | Positive | JsonNode | BiggestInt | BiggestFloat | Table | seq | Database | typed

    UserParam* = object
        uid*: string
        loginName*: string
        email*: string
        token*: string

    # fieldValue(s) are string type for params parsing convenience,
    # fieldValue(s) will be cast by supported fieldType(s), else will through ValueError exception
    # fieldOp: GT, EQ, GTE, LT, LTE, NEQ(<>), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
    # groupOp/groupLinkOp: AND | OR
    # groupCat: user-defined, e.g. "age-policy", "demo-group"
    # groupOrder: user-defined e.g. 1, 2...
    FieldItem* = object
        fieldColl*: string
        fieldName*: string
        fieldType*: string   # "int", "string", "bool", "boolean", "float",...
        fieldOrder*: string
        fieldOp*: string    # GT/gt/>, EQ/==, GTE/>=, LT/<, LTE/<=, NEQ(<>/!=), BETWEEN, NOTBETWEEN, IN, NOTIN, LIKE, IS, ISNULL, NOTNULL etc., with matching params (fields/values)
        fieldValue*: string  # for insert/update | start value for range/BETWEEN/NOTBETWEEN and pattern for LIKE operators
        fieldValueEnd*: string   # end value for range/BETWEEN/NOTBETWEEN operator
        fieldValues*: seq[string] # values for IN/NOTIN operator
        fieldPostOp*: string # EXISTS, ANY or ALL e.g. WHERE fieldName <fieldOp> <fieldPostOp> <anyAllQueryParams>
        groupOp*: string     # e.g. AND | OR...
        fieldAlias*: string # for SELECT/Read query
        show*: bool     # include or exclude from the SELECT query fields
        fieldFunction*: string # COUNT, MIN, MAX... for select/read-query...

    WhereParam* = object
        groupCat*: string
        groupLinkOp*: string
        groupOrder*: int
        groupItems*: seq[FieldItem]

    # functionType => MIN(min), MAX, SUM, AVE, COUNT, CUSTOM/USER defined
    # fieldNames => specify one field for all except custom/user function,
    # the fieldType must match the argument types expected by the functionType 
    # otherwise the only the first function-matching field will be used, as applicable
    QueryFunction* = object
        functionType*: string
        fieldItems*: seq[FieldItem]
        
    QueryParam* = object
        collName*: string    # default: "" => will use collName instead
        fieldItems*: seq[FieldItem]   # @[] => SELECT * (all fields)

    QueryTop* = object         
        topValue*: Positive
        topUnit*: string # number or percentage (# or %)
    
    CaseCondition* = object
        fieldItems*: seq[FieldItem]
        resultMessage*: string
        resultField*: string  # for ORDER BY options

    CaseQueryParam* = object
        conditions*: seq[CaseCondition]
        defaultField*: string   # for ORDER BY options
        defaultMessage*: string 
        orderBy*: bool
        asField*: string

    SelectFromParam* = object
        collName*: string
        fieldItems*: seq[FieldItem]

    InsertIntoParam* = object
        collName*: string
        fieldItems*: seq[FieldItem]

    GroupParam* = object
        fieldName*: string
        fieldOrder*: int

    OrderParam* = object
        collName*: string
        fieldName*: string
        queryFunction*: QueryFunction
        fieldOrder*: string # "ASC" ("asc") | "DESC" ("desc")
        functionOrder*: string

    # for aggregate query condition
    HavingParam* = object
        collName: string
        queryFunction*: QueryFunction
        queryOp*: string
        queryOpValue*: string # value will be cast to fieldType in queryFunction
        orderType*: string # "ASC" ("asc") | "DESC" ("desc")
        # subQueryParams*: SubQueryParam # for ANY, ALL, EXISTS...

    SubQueryParam* = object
        whereType*: string   # EXISTS, ANY, ALL
        whereField*: string  # for ANY / ALL | Must match the fieldName in queryParam
        whereOp*: string     # e.g. "=" for ANY / ALL
        queryParams*: QueryParam
        queryWhereParams*: WhereParam

    # combined/joined query (read) param-type
    JoinSelectField* =  object
        collName*: string
        collFields*: seq[FieldItem]
    
    JoinField* = object
        collName*: string
        joinField*: string

    JoinQueryParam* = object
        selectFromColl*: string # default to collName
        selectFields*: seq[JoinSelectField]
        joinType*: string # INNER (JOIN), OUTER (LEFT, RIGHT & FULL), SELF...
        joinFields*: seq[JoinField] # [{collName: "abc", joinField: "field1" },]
    
    SelectIntoParam* = object
        selectFields*: seq[FieldItem] # @[] => SELECT *
        intoColl*: string          # new table/collection
        fromColl*: string          # old/external table/collection
        fromFilename*: string      # IN external DB file, e.g. backup.mdb
        whereParam*: seq[WhereParam]
        joinParam*: JoinQueryParam # for copying from more than one table/collection

    UnionQueryParam* = object
        selectQueryParams*: seq[QueryParam]
        whereParams*: seq[WhereParam]
        orderParams*: seq[OrderParam]

    RoleService* = object
        serviceId*: string
        group*    : string
        category* : string
        canRead*  : bool
        canCreate*: bool
        canUpdate*: bool
        canDelete*: bool
    
    CheckAccess* = object
        userId*: string
        userRole*: string
        userRoles*: JsonNode
        isActive*: bool
        isAdmin*: bool
        roleServices*: seq[RoleService]

    ## Shared CRUD Operation Types  
    CrudParam* = ref object
        ## collName: table/collection to insert, update, read or delete record(s).
        collName*: string 
        docIds*: seq[string]  # for update, delete and read tasks
        ## actionParams: @[{collName: "abc", fieldNames: @["field1", "field2"]},], for create & update.
        ## Field names and corresponding values of record(s) to insert/create or update.
        ## Field-values will be validated based on data model definition.
        ## ValueError exception will be raised for invalid value/data type 
        ##
        actionParams*: seq[QueryParam]
        ## Bulk Insert Operation: 
        ## insertToParams {collName: "abc", fieldNames: @["field1", "field2"]}
        ## For collName: "" will use the default constructor collName
        insertIntoParams*: seq[InsertIntoParam]
        ## selectFromParams =
        ## {collName: "abc", fieldNames: @["field1", "field2"]}
        ## the order and types of insertIntoParams' & selectFromParams' fields must match, otherwise ValueError exception will occur
        ## 
        selectFromParams*: seq[SelectFromParam]
        selectIntoParams*: seq[SelectIntoParam]
        ## Query conditions
        ## whereParams: @[{groupCat: "validLocation", groupOrder: 1, groupLinkOp: "AND", groupItems: @[]}]
        ## groupItems = @[{collName: "testing", fieldName: "ab", fieldOp: ">=", groupOp: "AND(and)", order: 1, fieldType: "integer", filedValue: "10"},].
        ## 
        whereParams*: seq[WhereParam]
        # queryParams*: seq[QueryParam] => actionParams
        ## Read-only params =>
        ##  
        subQueryParams*: SubQueryParam
        ## Combined/joined query:
        ## 
        joinQueryParams*: seq[JoinQueryParam]
        unionQueryParams*: seq[UnionQueryParam]
        queryDistinct*: bool
        queryTop*: QueryTop
        # Query function
        queryFunction*: seq[QueryFunction]
        ## orderParams = @[{collName: "testing", fieldName: "name", fieldOrder: "ASC", queryFunction: "COUNT", functionOrderr: "DESC"}] 
        ## An order-param without orderType will default to ASC (ascending-order)
        ## 
        orderParams*: seq[OrderParam]
        groupParams*: seq[GroupParam] ## @[{fieldName: ""location", fieldOrder: 1}]
        havingParams*: seq[HavingParam]
        caseParams*: seq[CaseQueryParam] 
        skip*: Positive
        limit*: Positive
        ## Database, audit-log and access parameters 
        ## 
        auditColl*: string
        accessColl*: string
        serviceColl*: string
        roleColl*: string
        userColl*: string
        appDb*: Database
        accessDb*: Database
        auditDb*: Database
        logAll*: bool
        logRead*: bool
        logCreate*: bool
        logUpdate*: bool
        logDelete*: bool
        userInfo*: UserParam
        checkAccess*: bool
        transLog*: LogParam
    ##
