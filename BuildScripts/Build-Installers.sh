#!/bin/sh
set -e 


# this script has but one purpose, to go through and pull the various elements
# together to copy them into the Installers and then build the .pkg files.  
# those files will then be bundled into a .dmg which is then zipped and ready 
# for distribution.

PMAPP=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
cd ..
BASEPATH=$PWD

# make sure we have our directory to build the dist into.
if (! test -d $BASEPATH/dist/PostgreSQL) then
	mkdir -p $BASEPATH/dist/PostgreSQL
fi
if (! test -d $BASEPATH/dist/PostgreSQL/packages) then
	mkdir -p $BASEPATH/dist/PostgreSQL/packages
fi
if (! test -d $BASEPATH/dist/SQL\-Ledger/packages) then
	mkdir -p $BASEPATH/dist/SQL\-Ledger/packages
fi

# ************************************************************** PostgreSQL8.pkg

# copy the files into the temp storage.
if (test -d $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin) then
	rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*
fi
if (test -d $BASEPATH/Installers/PostgreSQL8/Files/Applications) then
	rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*
fi

mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/bin
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/bin/* $BASEPATH/temp/Files/Library/PostgreSQL8/bin
mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/doc
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/doc/* $BASEPATH/temp/Files/Library/PostgreSQL8/doc
mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/include
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/include/* $BASEPATH/temp/Files/Library/PostgreSQL8/include
mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/man
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/man/* $BASEPATH/temp/Files/Library/PostgreSQL8/man
mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/share
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/share/* $BASEPATH/temp/Files/Library/PostgreSQL8/share
mkdir -p $BASEPATH/temp/Files/Library/PostgreSQL8/lib
cp -r ~/Desktop/Workflow\ Support/PostgreSQL8/Universal/Library/PostgreSQL8/lib/* $BASEPATH/temp/Files/Library/PostgreSQL8/lib
mkdir -p $BASEPATH/temp/Files/Applications/PostgreSQL
cp -r $BASEPATH/ServiceManager/build/Deployment/Service\ Manager.app $BASEPATH/temp/Files/Applications/PostgreSQL
cp -r $BASEPATH/Backup\ Database/build/Release/Backup\ Database.app $BASEPATH/temp/Files/Applications/PostgreSQL
cp -r $BASEPATH/BuildScripts/Clean-Installation.sh $BASEPATH/temp/Files/Applications/PostgreSQL/Uninstall-PostgreSQL.sh

find $BASEPATH/temp/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/temp/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker \
	-build -p $BASEPATH/dist/PostgreSQL/packages/PostgreSQL8.pkg \
	-f $BASEPATH/temp/Files \
	-r $BASEPATH/Installers/PostgreSQL8/Resources \
	-d $BASEPATH/Installers/PostgreSQL8/Description.plist \
	-i $BASEPATH/Installers/PostgreSQL8/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp/Files/*

# ************************************************************** StartupItem.pkg

# copy the files into the temp storage.
mkdir -p $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj
cp $BASEPATH/StartupItem/PostgreSQL/PostgreSQL $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/
cp $BASEPATH/StartupItem/PostgreSQL/StartupParameters.plist $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/

mkdir -p $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj
cp $BASEPATH/StartupItem/PostgreSQL/Resources/English.lproj/Localizable.strings $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj/

mkdir -p $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/*.rtf $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/background.tif $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/preflight $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/postflight $BASEPATH/temp/Resources

sudo find $BASEPATH/temp/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:wheel $BASEPATH/Installers/StartupItem/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker \
	-build -p $BASEPATH/dist/PostgreSQL/packages/Postgres\ Startup\ Item.pkg \
	-f $BASEPATH/temp/Files \
	-r $BASEPATH/temp/Resources \
	-d $BASEPATH/Installers/StartupItem/Description.plist \
	-i $BASEPATH/Installers/StartupItem/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp

# ************************************************************* Client tools.pkg

# copy the files into the temp storage.
mkdir -p $BASEPATH/temp/Files/Applications/PostgreSQL

cp -r $BASEPATH/CreateDatabase/build/Deployment/Create\ Database.app $BASEPATH/temp/Files/Applications/PostgreSQL
cp -r $BASEPATH/CreateUser/build/Deployment/Create\ User.app $BASEPATH/temp/Files/Applications/PostgreSQL
cp -r $BASEPATH/QueryTool/build/Deployment/Query\ Tool\ for\ Postgres.app $BASEPATH/temp/Files/Applications/PostgreSQL

sudo find $BASEPATH/temp/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/temp/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build \
	-p $BASEPATH/dist/PostgreSQL/packages/Client\ Tools.pkg \
	-f $BASEPATH/temp/Files \
	-r $BASEPATH/Installers/ClientTools/Resources \
	-d $BASEPATH/Installers/ClientTools/Description.plist \
	-i $BASEPATH/Installers/ClientTools/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp

exit

# ************************************************************** JDBC Driver.pkg

# copy the files into the temp storage.

mkdir -p $BASEPATH/temp/Files/Library/Java/Extensions
cp $BASEPATH/Installers/JDBC/Files/Library/Java/Extensions/*.jar $BASEPATH/temp/Files/Library/Java/Extensions

mkdir -p $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/JDBC/Resources/*.rtf $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/JDBC/Resources/background.tif $BASEPATH/temp/Resources

sudo find $BASEPATH/Installers/StartupItem/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/temp/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/PostgreSQL/packages/Postgres\ JDBC.pkg -f $BASEPATH/temp/Files -r $BASEPATH/temp/Resources -d $BASEPATH/Installers/JDBC/Description.plist -i $BASEPATH/Installers/JDBC/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp

# ************************************************************** ODBC Driver.pkg

# ************************************************************** Admin Tools.pkg

# PGAdmin III


# ********************************************************** Migration Tools.pkg
# *************************************************************** SQL-Ledger.pkg

#mkdir -p $BASEPATH/temp/Files/Applications/SQL-Ledger
#mkdir -p $BASEPATH/temp/Files/Library/Perl/5.8.1/darwin-thread-multi-2level
#mkdir -p $BASEPATH/temp/Files/Library/WebServer/Documents/sql-ledger
#mkdir -p $BASEPATH/temp/Files/private/etc/httpd/users
#mkdir -p $BASEPATH/temp/Files/usr/bin

#cp -r $BASEPATH/Installers/SQL-Ledger/Files/Applications/SQL-Ledger.scpt $BASEPATH/temp/Files/Applications/SQL-Ledger
#cp -r $BASEPATH/Installers/SQL-Ledger/Files/Applications/SQL-Ledger\ Admin.scpt $BASEPATH/temp/Files/Applications/SQL-Ledger
#cp -r $BASEPATH/Installers/SQL-Ledger/Files/Library/Perl/5.8.1/darwin-thread-multi-2level/* $BASEPATH/temp/Files/Library/Perl/5.8.1/darwin-thread-multi-2level
#cp -r $BASEPATH/Installers/SQL-Ledger/Files/private/etc/httpd/users/sql-ledger.conf $BASEPATH/temp/Files/private/etc/httpd/users
#cp -r $BASEPATH/Installers/SQL-Ledger/Files/usr/bin/dbiproxy $BASEPATH/temp/Files/usr/bin
#cp -r $BASEPATH/Installers/SQL-Ledger/Files/usr/bin/dbish $BASEPATH/temp/Files/usr/bin

#cd $BASEPATH/temp/Files/Library/WebServer/Documents/
#curl -O http://www.sql-ledger.com/source/sql-ledger-2.4.11.tar.gz
#cd $BASEPATH
 
#sudo find $BASEPATH/temp -name ".DS_Store" -exec rm -f {} \;

# fix permissions so that they get installed correctly.
#chown -R root:admin $BASEPATH/temp/*

#mkdir -p $BASEPATH/dist/SQL-Ledger

#rm -rf $BASEPATH/dist/SQL-Ledger/packages
#cp -r $BASEPATH/dist/PostgreSQL/packages $BASEPATH/dist/SQL-Ledger/

# build the .pkg
#/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/SQL-Ledger/packages/SQL-Ledger.pkg -f $BASEPATH/temp/Files -r $BASEPATH/Installers/SQL-Ledger/Resources -d $BASEPATH/Installers/SQL-Ledger/Description.plist -i $BASEPATH/Installers/SQL-Ledger/Info.plist

# clean up after ourselves
#rm -rf $BASEPATH/temp

# ************************************************************** pgAdmin/III.pkg


# ************************************************* PostgreSQL Meta Package.mpkg

# build the .pkg
mkdir -p $BASEPATH/temp

/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/PostgreSQL/PostgreSQL.mpkg -f $BASEPATH/temp -r $BASEPATH/Installers/PostgreSQL/Resources -d $BASEPATH/Installers/PostgreSQL/Description.plist -i $BASEPATH/Installers/PostgreSQL/Info.plist

# ************************************************* SQL-Ledger Meta Package.mpkg

# build the .pkg
#mkdir -p $BASEPATH/temp

#/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/SQL-Ledger/SQL-Ledger.mpkg -f $BASEPATH/temp -r $BASEPATH/Installers/SQL-LedgerMP/Resources -d $BASEPATH/Installers/SQL-LedgerMP/Description.plist -i $BASEPATH/Installers/SQL-LedgerMP/Info.plist

