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


var odbcconnection: ODBCConnection;

odbcconnection = ODBCConnection();
odbcconnection.initSQLEnvironment();
odbcconnection.UserName = "postgres";
odbcconnection.Password = "gr8orthan0";
odbcconnection.Dsn = "test";
if (!odbcconnection.connect())
{
    if (!odbcconnection.isConnected()) {
        println("Connection Failed");
        odbcconnection.close();
        exit(0);
    }
}





