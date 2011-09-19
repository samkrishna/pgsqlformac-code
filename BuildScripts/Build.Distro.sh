ww="-YES-"		
	fi

	if (test "$is_arch" = "-YES-") 
	then
		PLATFORM=$f
		is_arch="-NO-"
	fi
	
	if (test "$f" = "-arch") 
	then
		is_arch="-YES-"		
	fi
done

echo +++ Building for: $PLATFORM

SERVER_WAS_RUNNING=NO

#-- backup current installation ------------------------------------------------

# clean up any current build directories

echo +++ Preparing a work area

if (test -d $TEMP_PATH) then
	rm -rf $TEMP_PATH
fi

# recreate the temp path

mkdir -p $TEMP_PATH/backup

# check for a current install.  If one exists, move it aside while the new one 
# is assembled.

echo +++ Setting aside any current installation to prevent loss.

if (test -d $INSTALL_PATH) then

	# is there a running instance?  if so, kill it.
	
	PID=`ps auxwc | grep '^postgres' | grep 'postgres$' | awk -F" " '{print $2}'`
	if (test "$PID") then
		SERVER_WAS_RUNNING=YES
		set $PID
		SystemStarter stop PostgreSQL 
	fi
	sleep 3
	
	PID=`ps auxwc | grep '^postgres' | grep 'postgres$' | awk -F" " '{print $2}'`
	if (test "$PID") then
		set $PID
		kill -9 $PID
	fi
	sleep 2

	mkdir -p $TEMP_PATH/backup$INSTALL_PATH
	mv $INSTALL_PATH/* $TEMP_PATH/backup$INSTALL_PATH
fi

touch $TEMP_PATH/build.log

if (test "$USE_CONSOLE" = "-YES-") 
then
	open -a Console /var/tmp/postgres/build.log		
fi

#-- get latest versions --------------------------------------------------------

echo +++ Fetching Current Sources

export VERSIONS=`curl --silent "http://www.postgresql.org/versions.rss" | \
  grep -E '(title>)' | \
  sed -n '2,$p' | \
  sed -e 's/<title>//' -e 's/<\/title>//' \
  	-e 's/            //' | \
  head -4 | fmt`
  
# now we have the list of versions, we can download the current versions.

CURRENT_VERSION=`echo $VERSIONS | awk -F" " '{print $1}'`
BACK_VERSION=`echo $VERSIONS | awk -F" " '{print $2}'`


if !(test -f $PG_VERSIONS_PATH/postgresql-$CURRENT_VERSION.tar.gz) then
	# fetch the current Version	
	echo Current Version: $CURRENT_VERSION
	export URL=http://wwwmaster.postgresql.org/redir/198/h/source/v$CURRENT_VERSION/postgresql-$CURRENT_VERSION.tar.gz
	curl -L $URL > $PG_VERSIONS_PATH/postgresql-$CURRENT_VERSION.tar.gz
fi

if !(test -f $PG_VERSIONS_PATH/postgresql-$BACK_VERSION.tar.gz) then
	# fetch the current Version	
	echo Back Version: $BACK_VERSION 
	export URL=http://wwwmaster.postgresql.org/redir/198/h/source/v$BACK_VERSION/postgresql-$BACK_VERSION.tar.gz
	curl -L $URL > $PG_VERSIONS_PATH/postgresql-$BACK_VERSION.tar.gz
fi

#-- Build the older version first ----------------------------------------------

echo +++ Building Current Version - $BACK_VERSION - /opt/local

cp $PG_VERSIONS_PATH/postgresql-$BACK_VERSION.tar.gz $TEMP_PATH
START_PATH=$PWD
cd $TEMP_PATH
tar xzf postgresql-$BACK_VERSION.tar.gz
cd postgresql-$BACK_VERSION

export CFLAGS="-O -arch $PLATFORM"
export LDFLAGS="-arch $PLATFORM"

./configure --prefix=/opt/local --with-bonjour --without-python \
	--without-tcl --without-perl --with-openssl --with-ldap --with-pam \
	--with-krb5  > $TEMP_PATH/build.log
make  > $TEMP_PATH/build.log
make install > $TEMP_PATH/build.log
make clean > $TEMP_PATH/build.log

mkdir -p $TEMP_PATH/merge/$BACK_VERSION/$PLATFORM/opt
mv /opt/local $TEMP_PATH/merge/$BACK_VERSION/$PLATFORM/opt

echo +++ Building Back Version - $BACK_VERSION - /Library/PostgreSQL8

cp $PG_VERSIONS_PATH/postgresql-$BACK_VERSION.tar.gz $TEMP_PATH
START_PATH=$PWD
cd $TEMP_PATH
tar xzf postgresql-$BACK_VERSION.tar.gz
cd postgresql-$BACK_VERSION

export CFLAGS="-O -arch $PLATFORM"
export LDFLAGS="-arch $PLATFORM"

./configure --prefix=/Library/PostgreSQL --with-bonjour --with-python \
	--with-tcl --with-perl --with-openssl --with-ldap --with-pam \
	--with-krb5 > $TEMP_PATH/build.log
make > $TEMP_PATH/build.log
make install > $TEMP_PATH/build.log
make clean > $TEMP_PATH/build.log

mkdir -p $TEMP_PATH/merge/$BACK_VERSION/$PLATFORM/Library/PostgreSQL8
mv /Library/PostgreSQL8 $TEMP_PATH/merge/$BACK_VERSION/$PLATFORM/Library/

#-- Build the current version second -------------------------------------------

echo +++ Building Current Version - $CURRENT_VERSION - /opt/local

cp $PG_VERSIONS_PATH/postgresql-$CURRENT_VERSION.tar.gz $TEMP_PATH
START_PATH=$PWD
cd $TEMP_PATH
tar xzf postgresql-$CURRENT_VERSION.tar.gz
cd postgresql-$CURRENT_VERSION

export CFLAGS="-O -arch $PLATFORM"
export LDFLAGS="-arch $PLATFORM"

# --disable-shared is currently broken so for the interim we will make shared
# and remove the dylib's post install

./configure --prefix=/opt/local --with-bonjour --without-python \
	--without-tcl --without-perl --with-openssl --with-ldap --with-pam --with-krb5  > $TEMP_PATH/build.log
make  > $TEMP_PATH/build.log
make install > $TEMP_PATH/build.log
make clean > $TEMP_PATH/build.log

rm -rf /opt/local/*.dylib

mkdir -p $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/opt
mv /opt/local $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/opt

echo +++ Building Current Version - $CURRENT_VERSION - /Library/PostgreSQL8

./configure --prefix=/Library/PostgreSQL8 --with-bonjour --with-python \
	--with-tcl --with-perl --with-openssl --with-ldap --with-pam --with-krb5  > $TEMP_PATH/build.log
make  > $TEMP_PATH/build.log
make install > $TEMP_PATH/build.log
make clean > $TEMP_PATH/build.log

mkdir -p $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/Library/PostgreSQL8
mv /Library/PostgreSQL8 $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/Library/

# because of the noted change above, we will remove the shared libraries.  It 
# will not hurt to leave this in place after this is patched.


rm -rf $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/opt/*.dylib 
rm -rf $TEMP_PATH/merge/$CURRENT_VERSION/$PLATFORM/opt/*.so

#-- clean up and put things back as they were ----------------------------------

echo +++ Restoring the previous state post build.

#if (test -d $TEMP_PATH/backup$INSTALL_PATH) then
#	mv $TEMP_PATH/backup$INSTALL_PATH/* $INSTALL_PATH
	
	# restart the database.
	
#	if (test "$SERVER_WAS_RUNNING" = "YES") then
#		SystemStarter start PostgreSQL 	
#	fi
#fi

#-- build the tar file and upload it to the central server for merging ---------

tar cf $TEMP_PATH/merge-$PLATFORM.tar $TEMP_PATH/merge
gzip $TEMP_PATH/merge-$PLATFORM.tar

#-- 

# remove the temp folder as it is no longer required

echo +++ Done!