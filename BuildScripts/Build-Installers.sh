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

# configure and build PostgreSQL
#cd ../PostgreSQL
#./configure --prefix=/Library/PostgreSQL8 --with-openssl --with-rendezvous --with-perl --with-pam --with-krb5 --with-tcl --with-python --without-readline --enable-static --disable-shared
#make
#sudo make install
#cd ../BuildScripts

# build the Service Manager applet
cd ./ServiceManager
/usr/bin/xcodebuild -project Service\ Manager.xcode -buildstyle Deployment -target Service\ Manager
cd ..

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
if (test -d $BASEPATH/Installers/StartupItem/Files/Library/StartupItems) then
	rm -rf $BASEPATH/Installers/StartupItem/Files/*
fi

mkdir -p $BASEPATH/Installers/StartupItem/Files/Library/StartupItems
cp -r $BASEPATH/StartupItem/ $BASEPATH/Installers/StartupItem/Files/Library/StartupItems

find $BASEPATH/Installers/StartupItem/ -name ".DS_Store" -exec rm -f {} \; 

# fix permissions so that they get installed correctly.
chown -R root:admin $BASEPATH/Installers/StartupItem/Files/*

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/Postgres\ Startup\ Item.pkg -f $BASEPATH/Installers/StartupItem/Files -r $BASEPATH/Installers/StartupItem/Resources -d $BASEPATH/Installers/StartupItem/Description.plist -i $BASEPATH/Installers/StartupItem/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/Installers/StartupItem/Files/*

