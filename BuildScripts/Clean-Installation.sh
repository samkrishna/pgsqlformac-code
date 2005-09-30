#!/bin/sh

# clean up the previous installation so we can test it again.
echo 
echo \# This script will attempt to remove all vestiges of a PostgreSQL8 installation
echo \# -----------------------------------------------------------------------------
echo \#

# make sure that we are running as root
x=`whoami | grep root`
if (! test -n "$x") then 
	echo \# You must be root \(sudo\) to have sufficient rights to remove the
	echo \# folders and files that need to be removed.
	
	exit 0
fi

set -e 

echo \# User: $x

# make sure the database is shutdown
echo \# Stopping the Database
/Library/StartupItems/PostgreSQL/PostgreSQL stop
echo \#       ...done

# remove the user and group from the netinfo database
echo \# Removing NetInfo entries

PG_UID=`/usr/bin/nifind -p //users/postgres | grep "^uid:.[0-9]" | sed 's/.*: //' | sed 's/ //'`
	
# User exists 
if test $PG_UID; then
	sudo /usr/bin/niutil -destroyprop / /users/postgres gid 
	sudo /usr/bin/niutil -destroyprop / /users/postgres uid 
	sudo /usr/bin/niutil -destroyprop / /users/postgres home 
	sudo /usr/bin/niutil -destroy / /users/postgres
	echo \#        ...Deleted Postgres User: $PG_UID
fi

PG_GID=`/usr/bin/nifind -p //groups/postgres | grep "gid:.[0-9]" | sed 's/.*: //' | sed 's/ //'`
	
# Group Exist, destroy it 
if test $PG_GID; then
	sudo /usr/bin/niutil -destroyprop / /groups/postgres gid 
	sudo /usr/bin/niutil -destroy / /groups/postgres
	echo \#        ...Deleted Postgres Group: $PG_GID
fi

sudo /usr/bin/niutil -resync /

echo \#       ...done

# remove the log files
echo \# Removing Logs \& Receipts
sudo rm -f /Library/Logs/PostgreSQL8.log
sudo rm -rf /Library/Receipts/PostgreSQL8.pkg
sudo rm -rf /Library/Receipts/Postgres\ Startup\ Item.pkg
sudo rm -rf /Library/Receipts/Postgres\ JDBC.pkg
sudo rm -rf /Library/Receipts/Client\ Tools.pkg
sudo rm -rf /Library/Receipts/SQL-Ledger.pkg
echo \#       ...done

# remove the directories
echo \# Removing Files and Folders
sudo rm -rf /Library/PostgreSQL8
sudo rm -rf /Library/StartupItems/PostgreSQL
sudo rm -rf /Applications/PostgreSQL

# the following lines are for SQL-Ledger
sudo rm -rf /Library/WebServer/Documents/sql-ledger
sudo rm -f /private/etc/httpd/users/sql-ledger.conf
sudo rm -f /usr/bin/dbiproxy
sudo rm -f /usr/bin/dbish
sudo rm -rf /Library/Perl/5.8.1/darwin-thread-multi-2level

echo \#       ...done

echo \#
echo \# -----------------------------------------------------------------------------
echo \# PostgreSQL8 has been removed from the system.