// Playground - noun: a place where people can play

import Cocoa
import PGSQLKit

var conn: PGSQLConnection;
conn = PGSQLConnection();
conn.UserName = "postgres";
conn.Password = "test";
conn.ConnectionString = "host=localhost port=5432 dbname=postgres user=postgres password=gr8orthan0";
if (!conn.connect())
{
    print("Connection Failed");
    print(conn.LastError);
    conn.close();
} else {
    print("Connected");
    
    var rs: GenDBRecordset
    rs = conn.open("select current_database()")
    var rCount = rs.rowCount()
    var currentState = rs.IsEOF
    if (!rs.IsEOF)
    {
        print("table: " + rs.fieldByIndex(0).asString())
        // rs.moveNext()
    }
    rs.close()
    conn.close();
}

