#!/bin/sh
set -e 


# this script has but one purpose, to go through and pull the various elements
# together to copy them into the Installers and then build the .pkg files.  
# those files will then be bundled into a .dmg which is then zipped and ready 
# for distribution.

PMAPP=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker
BASEPATH=$PWD

# make sure we have our directory to build the dist into.
if (! test -d $BASEPATH/dist) then
	mkdir $BASEPATH/dist
fi
if (! test -d $BASEPATH/dist/packages) then
	mkdir $BASEPATH/dist/packages
fi

# **************************************************************** Postgres8.pkg

# copy the files into the temp storage.
if (test -d $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin) then
	rm -rf $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/*
fi

mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin
cp -r /Library/PostgreSQL8/bin/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/bin
mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/doc
cp -r /Library/PostgreSQL8/doc/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/doc
mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/include
cp -r /Library/PostgreSQL8/include/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/include
mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/man
cp -r /Library/PostgreSQL8/man/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/man
mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/share
cp -r /Library/PostgreSQL8/share/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/share
mkdir $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/lib
cp -r /Library/PostgreSQL8/lib/* $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/lib

find $BASEPATH/Installers/PostgreSQL8/ -name ".DS_Store" -exec rm -f {} \; 

# build the .pkg
/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker -build -p $BASEPATH/dist/packages/PostgreSQL8.pkg -f $BASEPATH/Installers/PostgreSQL8/Files -r $BASEPATH/Installers/PostgreSQL8/Resources -d $BASEPATH/Installers/PostgreSQL8/Description.plist -i $BASEPATH/Installers/PostgreSQL8/Info.plist

# clean up after ourselves
rm -rf $BASEPATH/Installers/PostgreSQL8/Files/Library/PostgreSQL8/*



