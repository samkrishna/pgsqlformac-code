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

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/PostgreSQL8.pkg -f $BASEPATH/Installers/PostgreSQL8/Files -r $BASEPATH/Installers/PostgreSQL8/Resources -d $BASEPATH/Installers/PostgreSQL8/Description.plist -i $BASEPATH/Installers/PostgreSQL8/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/Installers/PostgreSQL8/Files/*

# ************************************************************** PostgreSQL8.pkg


