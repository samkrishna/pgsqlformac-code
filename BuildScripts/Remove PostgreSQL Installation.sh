#!/bin/sh

# clean up the previous installation so we can test it again.
echo 
echo \# This script will attempt to remove all vestiges of a PostgreSQL installation
echo \# -----------------------------------------------------------------------------
echo \#

# make sure that we are running as root
x=`whoami | grep root`
if (! test -n "$x") then 
	echo \# You must be root \(sudo\) to have sufficient rights to remove the
	echo \# folders and files that need to be removed.
	
	exit 0
fi

#set -e 

echo \# User: $x

# make sure the database is shutdown
echo \# Stopping the Database
/Library/StartupItems/PostgreSQL/PostgreSQL stop
echo \#       ...done

# remove the user and group from the netinfo database
echo \# Removing NetInfo entries

PG_UID=`/usr/bin/dscl . -read /users/postgres | grep "^UniqueID:.[0-9]" | sed 's/.*: //' | sed 's/ //'`
	
# User exists 
if test $PG_UID; then
	sudo /usr/bin/dscl . -delete /users/postgres
	echo \#        ...Deleted Postgres User: $PG_UID
fi

PG_GID=`/usr/bin/dscl . -read /groups/postgres | grep "^PrimaryGroupID:.[0-9]" | sed 's/.*: //' | sed 's/ //'`
	
# Group Exist, destroy it 
if test $PG_GID; then
	sudo /usr/bin/dscl . -delete /groups/postgres
	echo \#        ...Deleted Postgres Group: $PG_GID
fi

echo \#       ...done

# remove the log files
echo \# Removing Logs \& Receipts
sudo rm -f /Library/Logs/PostgreSQL8.log
sudo rm -rf /Library/Receipts/backupDatabase.pkg
sudo rm -rf /Library/Receipts/cleanInstallation.pkg
sudo rm -rf /Library/Receipts/createDatabase.pkg
sudo rm -rf /Library/Receipts/createUser.pkg
sudo rm -rf /Library/Receipts/pgsqlkit.pkg
sudo rm -rf /Library/Receipts/postgresql.pkg
sudo rm -rf /Library/Receipts/postgresqlServer.pkg
sudo rm -rf /Library/Receipts/queryToolForPostgres.pkg
sudo rm -rf /Library/Receipts/uninstallPostgresqlServer.pkg
sudo rm -rf /Library/Preferences/com.druware.postgresqlformac.plist
echo \#       ...done

# remove the directories
echo \# Removing Files and Folders
sudo rm -rf /Library/PostgreSQL
sudo rm -rf /Library/StartupItems/PostgreSQL
sudo rm -rf /Library/PreferencePanes/PostgreSQL\ Server.prefPane
sudo rm -rf /Applications/PostgreSQL

echo \#       ...done

echo \#
echo \# -----------------------------------------------------------------------------
echo \# PostgreSQL8 has been removed from the system.