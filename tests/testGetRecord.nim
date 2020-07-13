import unittest
import mccrud
import mctranslog
import mcdb
import json

# test data sets
var defaultSecureOption = DbSecureType(secureAccess: false)

var defaultDbOptions = DbOptionType(fileName: "testdb.db", hostName: "localhost",
                                hostUrl: "localhost:5432",
                                userName: "postgres", password: "ab12trust",
                                dbName: "mccentral", port: 5432,
                                dbType: "postgres", poolSize: 20,
                                secureOption: defaultSecureOption )

# db connection / instance
var dbConnect = newDatabase(defaultDbOptions)

var logInstanceResult = LogParam(auditDb: dbConnect, auditColl: "audits")

# audit-log instance
var mcLog = newLog(dbConnect, "audits")

# Working/Test data
type
    TestParam = object
        name: string
        desc: string
        url: string
        priority: int
        cost: float

var
    collName: string = "services"
    userId: string = "abbeycityunited"

var collParams = %*(TestParam(name: "Abi",
                            desc: "Testing only",
                            url: "localhost:9000",
                            priority: 1,
                            cost: 1000.00
                            )
                )

var collNewParams = %*(TestParam(name: "Abi Akindele",
                            desc: "Testing only - updated",
                            url: "localhost:9900",
                            priority: 1,
                            cost: 2000.00
                            )
                )

var
    loginParams = collParams
    logoutParams = collParams

