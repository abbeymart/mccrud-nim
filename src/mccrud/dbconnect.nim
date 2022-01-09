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
## More to be added later - MongoDb...
## 
import types
import db_postgres as postgres
import db_mysql as mysql
import db_sqlite as sqlite

var defaultSecureOption = DbSecureType(secureAccess: false)

var defaultOptions = DbConfigType(fileName: "testdb.db",
                                host: "localhost",
                                url: "localhost:5432",
                                userName: "abbeymart",
                                password: "ab12trust",
                                dbName: "mccentral",
                                port: 5432,
                                dbType: DatabaseType.Postgres,
                                poolSize: 20,
                                secureOption: defaultSecureOption )
# database constructor
proc newDatabase*(options: DbConfigType = defaultOptions): Database =
    new result
    case options.dbType
    of [DatabaseType.Postgres]:
      # var dbHostConnection = "host=localhost port=5432 dbname=mydb"
      # var pgHostConnection = "host=" & options.hostName & " port=" & $options.port & " dbname=" & options.dbName
      # TODO: include the TLS/secure and pgdb options
      result.db = postgres.open(connection=options.url, user=options.userName, password=options.password, database=options.dbName )
      # result.db = open(options.host, options.userName, options.password, options.dbName)
    of [DatabaseType.MySQL]:
      result.dbmysql = mysql.open(connection=options.url, user=options.userName, password=options.password, database=options.dbName )
    of [DatabaseType.Sqlite]:
      result.dbsqlite = sqlite.open(connection=options.fileName, "", "", "")
    # else:
    #   raise newException(DbError, "Unknown db-type: unable to establish db connection. ")

proc close*(database: Database, dbType = DatabaseType.Postgres) =
    case dbType
    of[DatabaseType.Postgres]:
      database.db.close()
    of[DatabaseType.MySQL]:
      database.dbmysql.close()
    of[DatabaseType.Sqlite]:
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
