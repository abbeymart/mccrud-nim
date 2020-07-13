import unittest
import mccrud
import mctranslog
import mcdb
import json

# test data sets

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

suite "create new records testing":
    # "setup: run once before the tests"

    test "should connect and return an instance object":
        echo logInstanceResult
        check mcLog == logInstanceResult

    test "should store create-transaction log and return success":
        let res = mcLog.createLog(collName, collParams, userId)
        echo "create-log-response: ", res
        check res.code == "success"
        check res.value == collParams

    test "should store logout-transaction log and return success":
        collName = "users"
        let res = mcLog.logoutLog(collName, logoutParams, userId)
        check res.code == "success"
        check res.value == nil

    test "should return paramsError for incomplete/undefined inputs":
        try:
            let res = mcLog.logoutLog(collName, logoutParams, "")
            echo "paramsError-response: ", res
            check res.code == "insertError"
            check res.value == nil
        except:
            echo getCurrentExceptionMsg()
    teardown:
        # close db after testing
        dbConnect.close()
