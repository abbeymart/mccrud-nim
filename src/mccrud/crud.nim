#                   mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details a bout the copyright / license.
# 

##     CRUD Package - common / extendable base constructor & procedures for all CRUD operations
## 

import db_postgres, json, tables
import mcdb, mccache, mcresponse, mctranslog
import ./helpers/helper, ./crudtypes

export db_postgres, json, tables
export mcdb, mccache, mcresponse, mctranslog
export helper, crudtypes

## Default CRUD contructor returns the instance/object for CRUD task(s)
proc newCrud*(appDb: Database; 
            tableName: string; 
            userInfo: UserParamType;
            actionParams: seq[SaveParamType] = @[];
            queryParam: QueryParamType = QueryParamType();
            queryReadParam: QueryReadParamType = QueryReadParamType();
            queryDeleteParam: QueryDeleteParamType = QueryDeleteParamType();
            queryUpdateParam: QueryUpdateParamType = QueryUpdateParamType();
            querySaveParam: QuerySaveParamType = QuerySaveParamType();
            where: seq[WhereParamType] = @[];
            docIds: seq[string] = @[];
            insertInto: seq[InsertIntoType] = @[];
            selectFrom: seq[SelectFromType] = @[];
            selectInto: seq[SelectIntoType] = @[];
            queryFunctions: seq[ProcedureTypes] = @[];
            order: seq[OrderType] = @[];
            group: seq[GroupType]  = @[];
            having: seq[HavingType] = @[];
            caseQuery: seq[CaseQueryType]  = @[];
            subQuery: seq[SubQueryType] = @[];
            joinQuery: seq[JoinQueryType] = @[];
            unionQuery: seq[UnionQueryType] = @[];
            queryDistinct: bool = false;
            queryTop: QueryTopType = QueryTopType();
            skip: Natural = 0;
            limit: Positive = 100000;
            defaultLimit: Positive = 100000;
            auditTable: string = "audits";
            accessTable: string = "accesskeys";
            serviceTable: string = "services";
            roleTable: string = "roles";
            userTable: string = "users";
            accessDb: Database = appDb;
            auditDb: Database = appDb;
            logAll: bool = false;
            logRead: bool = false;
            logCreate: bool = false;
            logUpdate: bool = false;
            logDelete: bool = false;
            checkAccess: bool = true;
            transLog: LogParam = LogParam(auditDb: auditDb, auditColl: auditTable);
            options: Table[string, DataTypes]): CrudParamType =
    
    # new result

    result.appDb = appDb
    result.tableName = tableName
    result.userInfo = userInfo
    result.actionParams = actionParams
    result.queryParam = queryParam
    result.queryReadParam = queryReadParam
    result.queryDeleteParam = queryDeleteParam
    result.queryUpdateParam = queryUpdateParam
    result.querySaveParam = querySaveParam
    result.docIds = docIds
   
    # Create/Update
    result.insertInto = insertInto
    result.selectFrom = selectFrom
    result.selectInto = selectInto

    # Read
    result.queryFunctions = queryFunctions
    result.where = where
    result.order = order
    result.group = group
    result.having = having
    result.queryDistinct = queryDistinct
    result.queryTop= queryTop
    result.joinQuery = joinQuery
    result.unionQuery = unionQuery
    result.caseQuery = caseQuery
    result.skip = skip
    result.limit = limit
    result.defaultLimit = defaultLimit

    # Shared
    result.auditTable = auditTable
    result.accessTable = accessTable
    result.auditTable = auditTable
    result.roleTable = roleTable
    result.userTable = userTable
    result.auditDb = auditDb
    result.accessDb = accessDb
    result.logAll = logAll
    result.logRead = logRead
    result.logCreate = logCreate
    result.logUpdate= logUpdate
    result.logDelete = logDelete
    result.checkAccess = checkAccess

    # translog instance
    result.transLog = newLog(result.auditDb, result.auditTable)
