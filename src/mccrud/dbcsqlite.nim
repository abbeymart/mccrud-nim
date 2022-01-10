#
#              mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details about the copyright / license.
# 
#             Db Connection Constructor
#

## Db Connection constructor for Sqlite...
## 
## 
import types
import db_sqlite as sqlite

var defaultSecureOption = DbSecureType(secureAccess: false)

var defaultOptions = DbConfigType(fileName: "testdb.db",
                                host: "localhost",
                                url: "localhost:5433",
                                userName: "postres",
                                password: "ab12trust",
                                dbName: "mcaccessnim",
                                port: 5433,
                                dbType: DatabaseType.Postgres,
                                poolSize: 20,
                                secureOption: defaultSecureOption )
# database constructor
proc newDatabase*(options: DbConfigType = defaultOptions): Database =
    new result
    result.dbsqlite = sqlite.open(connection=options.fileName, "", "", "")
proc close*(database: Database, dbType = DatabaseType.Postgres) =
    database.dbsqlite.close()
      
when isMainModule:
  try:
    let dbConnect = newDatabase()
    # echo "db-response-status: ", dbConnect.db.status
    doAssert $dbConnect.db.status ==  "CONNECTION_OK"
    # dbConnect.db.close()
    dbConnect.close()
  except:
    echo "error opening DB Connection: ", getCurrentExceptionMsg()
