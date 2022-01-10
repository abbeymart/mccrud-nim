#
#              mconnect solutions
#        (c) Copyright 2020 Abi Akindele (mconnect.biz)
#
#    See the file "LICENSE.md", included in this
#    distribution, for details about the copyright / license.
# 
#             Db Connection Constructor
#

## Db Connection constructor for Postgres, MySQL and Sqlite...
## 
import types
import db_postgres as postgres
import db_mysql as mysql
import db_sqlite as sqlite

export postgres, mysql, sqlite

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

type DbSetupType* = object
  database*: Database
  dbConfig*: DbConfigType

# database constructor
proc newDatabase*(options: DbConfigType = defaultOptions): DbSetupType =
    # new result
    case options.dbType
    of DatabaseType.Postgres:
      # var dbHostConnection = "host=localhost port=5432 dbname=mydb"
      # var pgHostConnection = "host=" & options.hostName & " port=" & $options.port & " dbname=" & options.dbName
      # TODO: include the TLS/secure and db options
      let dbc = postgres.open(connection=options.url, user=options.userName, password=options.password, database=options.dbName )
      # result.db = open(options.host, options.userName, options.password, options.dbName)
      result.database = Database(dbc: dbc)
      result.dbConfig = options
    of DatabaseType.MySQL:
      let dbc = mysql.open(connection=options.url, user=options.userName, password=options.password, database=options.dbName )
      result.database = Database(dbcmysql: dbc)
      result.dbConfig = options
    of DatabaseType.Sqlite:
      let dbc = sqlite.open(connection=options.fileName, "", "", "")
      result.database = Database(dbcsqlite: dbc)
      result.dbConfig = options
    # else:
    #   raise newException(DbError, "Unknown db-type: unable to establish db connection. ")

proc close*(database: Database, dbType = DatabaseType.Postgres) =
    case dbType
    of DatabaseType.Postgres:
      database.dbc.close()
    of DatabaseType.MySQL:
      database.dbcmysql.close()
    of DatabaseType.Sqlite:
      database.dbcsqlite.close()
    
when isMainModule:
  try:
    let dbConnect = newDatabase()
    # echo "db-response-status: ", dbConnect.db.status
    doAssert $dbConnect.database.dbc.status ==  "CONNECTION_OK"
    # dbConnect.db.close()
    dbConnect.database.close()
  except:
    echo "error opening DB Connection: ", getCurrentExceptionMsg()
