//
//  main.swift
//  PGSQLKit Swift Test Client
//
//  Created by Andy Satori on 9/11/14.
//  Copyright (c) 2014 Druware Software Designs. All rights reserved.
//

import Foundation
import PGSQLKit

println("Testing ODBCKit from Swift")


var connection: PGSQLConnection;

connection = ODBCConnection();
connection.initSQLEnvironment();
connection.UserName = "postgres";
connection.Password = "gr8orthan0";
connection.Dsn = "test";
if (!connection.connect())
{
    if (!connection.isConnected()) {
        println("Connection Failed");
        connection.close();
        exit(0);
    }
}





