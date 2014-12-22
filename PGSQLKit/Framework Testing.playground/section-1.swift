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
    println("Connection Failed");
    println(conn.LastError);
    conn.close();
} else {
    println("Connected");
    
    var rs: GenDBRecordset
    rs = conn.open("select current_database()")
    var rCount = rs.rowCount()
    var currentState = rs.IsEOF
    if (!rs.IsEOF)
    {
        println("table: " + rs.fieldByIndex(0).asString())
        // rs.moveNext()
    }
    rs.close()
    conn.close();
}

