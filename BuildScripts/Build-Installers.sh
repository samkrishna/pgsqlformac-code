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
if (! test -d $BASEPATH/dist) then
	mkdir $BASEPATH/dist
fi
if (! test -d $BASEPATH/dist/packages) then
	mkdir $BASEPATH/dist/packages
fi

# ************************************************************** PostgreSQL8.pkg

# make sure that we have an installation to build an install from ... 
# the script probably out to automate that as well.

# also needs to make sure that the Service Manager.app is built and ready to 
# deploy

# copy the files into the temp storage.
if (test -d $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin) then
	rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*
fi
if (test -d $BASEPATH/Installers/PostgreSQL8/Files/Applications) then
	rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*
fi

mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin
cp -r /Library/PostgreSQL8/bin/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/doc
cp -r /Library/PostgreSQL8/doc/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/doc
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/include
cp -r /Library/PostgreSQL8/include/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/include
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/man
cp -r /Library/PostgreSQL8/man/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/man
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/share
cp -r /Library/PostgreSQL8/share/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/share
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/lib
cp -r /Library/PostgreSQL8/lib/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/lib
mkdir -p $BASEPATH/Installers/PostgreSQL8/Files/Applications/PostgreSQL
cp -r $BASEPATH/ServiceManager/build/Service\ Manager.app $BASEPATH/Installers/PostgreSQL8/Files/Applications/PostgreSQL

find $BASEPATH/Installers/PostgreSQL8/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/Installers/PostgreSQL8/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/PostgreSQL8.pkg -f $BASEPATH/Installers/PostgreSQL8/Files -r $BASEPATH/Installers/PostgreSQL8/Resources -d $BASEPATH/Installers/PostgreSQL8/Description.plist -i $BASEPATH/Installers/PostgreSQL8/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*

# ************************************************************** StartupItem.pkg

# copy the files into the temp storage.
mkdir -p $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj
cp $BASEPATH/StartupItem/PostgreSQL/PostgreSQL $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/
cp $BASEPATH/StartupItem/PostgreSQL/StartupParameters.plist $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/

mkdir -p $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj
cp $BASEPATH/StartupItem/PostgreSQL/Resources/English.lproj/Localizable.strings $BASEPATH/temp/Files/Library/StartupItems/PostgreSQL/Resources/English.lproj/

mkdir -p $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/*.rtf $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/*.strings $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/background.tif $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/InstallationCheck $BASEPATH/temp/Resources
cp  $BASEPATH/Installers/StartupItem/Resources/postflight $BASEPATH/temp/Resources

sudo find $BASEPATH/temp/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/Installers/StartupItem/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/Postgres\ Startup\ Item.pkg -f $BASEPATH/temp/Files -r $BASEPATH/temp/Resources -d $BASEPATH/Installers/StartupItem/Description.plist -i $BASEPATH/Installers/StartupItem/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp

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
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/Postgres\ JDBC.pkg -f $BASEPATH/temp/Files -r $BASEPATH/temp/Resources -d $BASEPATH/Installers/JDBC/Description.plist -i $BASEPATH/Installers/JDBC/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/temp

# ************************************************************** ODBC Driver.pkg
# ************************************************************* Client tools.pkg

# copy the files into the temp storage.
if (test -d $BASEPATH/Installers/ClientTools/Files) then
	rm -rf $BASEPATH/Installers/ClientTools/Files/*
fi

mkdir -p $BASEPATH/Installers/ClientTools/Files/Applications/PostgreSQL

cp -r $BASEPATH/CreateDatabase/build/Create\ Database.app $BASEPATH/Installers/ClientTools/Files/Applications/PostgreSQL
cp -r $BASEPATH/CreateUser/build/Create\ User.app $BASEPATH/Installers/ClientTools/Files/Applications/PostgreSQL
cp -r $BASEPATH/QueryTool/build/Query\ Tool\ for\ Postgres.app $BASEPATH/Installers/ClientTools/Files/Applications/PostgreSQL

sudo find $BASEPATH/Installers/ClientTools/ -name ".DS_Store" -exec rm -f {} \; 
sudo find $BASEPATH/Installers/ClientTools/Files/ -name "CVS" -exec rm -rf {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/Installers/ClientTools/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/Client\ Tools.pkg -f $BASEPATH/Installers/ClientTools/Files -r $BASEPATH/Installers/ClientTools/Resources -d $BASEPATH/Installers/ClientTools/Description.plist -i $BASEPATH/Installers/ClientTools/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/Installers/ClientTools/Files/*

# ************************************************************** Admin Tools.pkg
# ********************************************************** Migration Tools.pkg
# *************************************************************** SQL-Ledger.pkg
# ************************************************************** pgAdmin/III.pkg


# ************************************************* PostgreSQL Meta Package.mpkg

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/PostgreSQL.mpkg -f $BASEPATH/Installers/PostgreSQL/Files -r $BASEPATH/Installers/PostgreSQL/Resources -d $BASEPATH/Installers/PostgreSQL/Description.plist -i $BASEPATH/Installers/PostgreSQL/Info.plist



