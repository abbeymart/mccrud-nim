# Testing data

import mccrud, times

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

# create record:
var tableName = "audits"

# var saveRecordInstance = CrudParam(appDb: dbConnect, collName: tableName)

# data from the client (UI) in JSON format seq[object]

var createRecords = ""
var updateRecords = ""

type
    AuditTable = object
        id*: string
        coll_name: string
        coll_values: JsonNode
        coll_new_values: JsonNode
        log_type: string
        log_by: string
        log_date: Time

        name: string
        desc: string
        url: string
        priority: int
        cost: float

var
    collName: string = "services"
    userId: string = "abbeycityunited"

var collParams = %*(AuditTable(name: "Abi",
                            desc: "Testing only",
                            url: "localhost:9000",
                            priority: 1,
                            cost: 1000.00
                            )
                )

var collNewParams = %*(AuditTable(name: "Abi Akindele",
                            desc: "Testing only - updated",
                            url: "localhost:9900",
                            priority: 1,
                            cost: 2000.00
                            )
                )
