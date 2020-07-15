# Testing data

import mccrud, times, json, strutils

var defaultSecureOption = DbSecureType(secureAccess: false)

var defaultDbOptions = DbOptionType(fileName: "testdb.db", hostName: "localhost",
                                hostUrl: "localhost:5432",
                                userName: "postgres", password: "ab12trust",
                                dbName: "mccentral", port: 5432,
                                dbType: "postgres", poolSize: 20,
                                secureOption: defaultSecureOption )

# db connection / instance
var dbConnect = newDatabase(defaultDbOptions)

var userInfo = UserParam(
    id: "5b0e139b3151184425aae01c",
    firstName: "Abi",
    lastName: "Akindele",
    lang: "en-US",
    loginName: "abbeymart",
    email: "abbeya1@yahoo.com",
    token: "aaaaaaaaaaaaaaa455YFFS99902zzz"
    )

# var saveRecordInstance = CrudParam(appDb: dbConnect, collName: tableName)

# data from the client (UI) in JSON format seq[object]

# var createRecords: seq[AuditTable] = ""
# var updateRecords = ""

type
    AuditTable = object
        id*: string     # uuid
        collName: string
        collValues: JsonNode
        collNewValues: JsonNode
        logType: string
        logBy: string
        logDate: DateTime
    CollModel = object
        name: string
        desc: string
        url: string
        priority: int
        cost: float

var
    colName = "audits"
    userId = userInfo.id

var collParams = %*(CollModel(name: "Abi",
                            desc: "Testing only",
                            url: "localhost:9000",
                            priority: 1,
                            cost: 1000.00
                            ))

var collNewParams = %*(CollModel(name: "Abi Akindele",
                            desc: "Testing only - updated",
                            url: "localhost:9900",
                            priority: 1,
                            cost: 2000.00
                            ))

var saveRecordRequest: seq[JsonNode] = @[
    parseJson("""
        "collName": "audits",
        "collValues": {"name": "Abi", "priority": 1},
        "logType": "create",
        "logBy": "5b0e139b3151184425aae01c",
        "logAt: 2020-07-12 00:30:21-04
    """),
    parseJson("""
        "collName": "audits",
        "collValues": {"name": "Abi", "priority": 1},
        "collNewValues": {"name": "Ola", "priority": 1},
        "logType": "update",
        "logBy": "5b0e139b3151184425aae01c",
        "logAt: 2020-07-12 00:30:21-04
    """),
]

var auditRec  = AuditTable(
        collName:  colName,
        collValues: collParams,
        logType: "create",
        logBy: userId,
        logDate: now().utc,
    )

var createRecords = @[
    auditRec,
    auditRec,
]

proc generateCreateActionParams(recs: seq[object]): seq[QueryParam] =
    var actionParams: seq[QueryParam] = @[]

    for recItem in recs:
        echo "add field-info drom recItem"
        var queryParam = QueryParam()
        for key, value in recItem.fieldPairs:
            queryParam.fieldItems.add(
                FieldItem(
                    fieldName: key.toLower(),
                    fieldValue: $(value),
                    fieldType: $(typeof key),
                )
            )
        actionParams.add(queryParam)
    result = actionParams

var createRecsParams = generateCreateActionParams(createRecords)
