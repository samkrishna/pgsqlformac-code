#!/bin/sh

PG_NEW_VERSION=$1

# if pg is running, fail with an error

x=`ps auxwc | grep '^postgres' |grep 'postgres$' | awk -F" " '{print $2}'`
if /bin/test "$x"
then
	echo PostgreSQL cannot switch versions while there is a version running. 
	echo Please stop all running instances of PostgreSQL before running pg_set_version
	
	exit 1
fi

# can't compare the version if the symlink doesn't exist
if test -L /Library/PostgreSQL8/bin
then
	# if the version is not changing, fail with an error.
	pg_current_verison=`/Library/PostgreSQL8/bin/psql --version | grep 'psql' | awk -F" " '{print $3}'`
	if test $pg_current_verison = $PG_NEW_VERSION
	then
		echo PostgreSQL will not change the version to the same versions
		exit 1
	fi
fi

# if the version is not found, fail with an error
if test -d /Library/PostgreSQL8/versions/$PG_NEW_VERSION
then
	rm /Library/PostgreSQL8/bin
	ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/bin /Library/PostgreSQL8/bin
	rm /Library/PostgreSQL8/include
	ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/include /Library/PostgreSQL8/include
	rm /Library/PostgreSQL8/lib
	ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/lib /Library/PostgreSQL8/lib
	rm /Library/PostgreSQL8/share
	ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/share /Library/PostgreSQL8/share
	
	# the next two items may not exist, if they don't, do not create a link to them
	if (test -d /Library/PostgreSQL8/doc) then
		rm /Library/PostgreSQL8/doc
	fi
	if (test -d /Library/PostgreSQL8/versions/$PG_NEW_VERSION/doc) then
		ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/doc /Library/PostgreSQL8/doc
	fi
	if (test -d /Library/PostgreSQL8/man) then
		rm /Library/PostgreSQL8/man
	fi
	if (test -d /Library/PostgreSQL8/versions/$PG_NEW_VERSION/man) then
		ln -s /Library/PostgreSQL8/versions/$PG_NEW_VERSION/man /Library/PostgreSQL8/man
	fi
	
	echo PostgreSQL8 Version set to $PG_NEW_VERSION.
	exit 0
fi

echo PostgreSQL cannot find the requested version to set to, no changes have 
echo been made.

exit 1
