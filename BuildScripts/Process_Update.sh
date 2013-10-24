#!/bin/sh
set -e

# this script is intended to consolidate the entire build process into a single
# script that can be run on either powerpc or x86 to build the local versions,
# push them into a dropbox account for consolidation with an alternate machine
# running the other platform.  Once all 4 archs are built and discovered, the 
# script the unifies the platforms into a single universal binary.  the 
# universal binary is then altered to be relocatable. the release notes are 
# assembled, and the distribution folder is assembled and prepared for final
# review for publication. the process itself runs daily

#  1. Check the current versions against what we have on hand
#  2. If On Hand does not match the latest, download and build the latest
#  3. move the latest to the dropbox destination
#  4. if all four platforms are current check for universal
#  5. build universal if needed
#  6. make relocatable
#  7. build auxiliary tools
#  8. assemble release notes
#  9. build package installer
# 10. build the disk image

# Constants -------2---------3---------4---------5---------6---------7---------8

# set some constants that we will use throughout the script but can be altered
# easily for a given environment

# NOTIFY_EMAIL - who do we need to let know this is running
NOTIFY_EMAIL=dru@druware.com
INSTALL_PATH=/Library/PostgreSQL
PG_VERSIONS_PATH=/Users/Shared/Projects/PostgreSQL/Versions
TEMP_PATH=/var/tmp/postgres
DOWNLOAD_HOST=http://ftp.postgresql.org/pub/source
SYNCH_FOLDER=/Users/arsatori/Dropbox/Projects/PostgreSQL

# Functions -------2---------3---------4---------5---------6---------7---------8

# the following are a bunch of functions that we use to implement the various 
# bits of the process.

# assumes the parameters on the function line.

function buildVersion
{
	is_arch="-NO-"
	is_path="-NO-"
	is_ver="-NO-"
	for f in "$@"
	do
		if (test "$is_ver" = "-YES-") 
		then
			SELECTED_VERSION=$f
			is_ver="-NO-"
		fi
		
		if (test "$f" = "-ver") 
		then
			is_ver="-YES-"		
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
		
		if (test "$is_path" = "-YES-") 
		then
			SELECTED_INSTALL_PATH=$f
			is_path="-NO-"
		fi
		
		if (test "$f" = "-path") 
		then
			is_path="-YES-"		
		fi		
	done

	echo +++ Building Version - $SELECTED_VERSION - $SELECTED_INSTALL_PATH - $PLATFORM
		
	cp $PG_VERSIONS_PATH/postgresql-$SELECTED_VERSION.tar.gz $TEMP_PATH
	START_PATH=$PWD
	cd $TEMP_PATH
	
	tar xzf postgresql-$SELECTED_VERSION.tar.gz
	cd postgresql-$SELECTED_VERSION
	
	export CFLAGS="-O -arch $PLATFORM"
	export LDFLAGS="-arch $PLATFORM"
	
	echo +++     Configuring 
	./configure --prefix=$SELECTED_INSTALL_PATH --with-bonjour --with-python \
		--with-tcl --with-perl --with-openssl --with-ldap --with-pam \
		--with-krb5 &> $TEMP_PATH/build.log
	echo +++     Building 
	make &> $TEMP_PATH/build.log
	echo +++     Installing 
	make install &> $TEMP_PATH/build.log 
	cd contrib
	echo +++     Building Contrib
	make &> $TEMP_PATH/build.log
	echo +++     Installing
	make install &> $TEMP_PATH/build.log 
	echo +++     Cleaning
	make clean &> $TEMP_PATH/build.log 
	cd ..
	make clean &> $TEMP_PATH/build.log 
	
	rm -rf $TEMP_PATH/merge
	echo +++     Moving Results to Merge Folder
	mkdir -p $TEMP_PATH/merge/$SELECTED_VERSION/$PLATFORM$SELECTED_INSTALL_PATH
	mv $SELECTED_INSTALL_PATH/* $TEMP_PATH/merge/$SELECTED_VERSION/$PLATFORM$SELECTED_INSTALL_PATH
	
	rm $TEMP_PATH/postgresql-$SELECTED_VERSION.tar.gz
	rm -rf $TEMP_PATH/postgresql-$SELECTED_VERSION	
}

function fetchVersion
{
	if !(test -f $SYNCH_FOLDER/$1.done) then
		
		echo +++ Downloading Version: $1 
		export URL=$DOWNLOAD_HOST/v$1/postgresql-$1.tar.gz
		curl -L $URL > $PG_VERSIONS_PATH/postgresql-$1.tar.gz
		
		if [[ $CURRENT_ARCH = "powerpc" ]]; then
			buildVersion -arch 'ppc7400' -ver $1 -path $2
			cp -r $TEMP_PATH/merge/ $SYNCH_FOLDER
			buildVersion -arch 'ppc64' -ver $1 -path $2
			cp -r $TEMP_PATH/merge/ $SYNCH_FOLDER
		else
			# Intel branches
			buildVersion -arch 'i386' -ver $1 -path $2
			cp -r $TEMP_PATH/merge/ $SYNCH_FOLDER
			buildVersion -arch 'x86_64' -ver $1 -path $2
			cp -r $TEMP_PATH/merge/ $SYNCH_FOLDER
		fi
		
		touch $SYNCH_FOLDER/$1.done
	fi
}

function mergeVersionFolder
{
	currentDir=`pwd`
	# echo ProcessFolder: $currentDir
	oIFS=$IFS
	IFS=$'\n'
	for f in "$@"
	do
		# if it's a folder, process the files in the folder		
		if [[ -d "${f}" ]]; then
			cd "${f}"
			mergeVersionFolder $(ls -1 ".")
			cd ..
		else
		
			currentItem="${f}"
			currentName=`basename $currentItem`
			currentDir=`pwd`
		
			# echo      trying merge $currentName in $currentDir
			# echo      baseFolder is $baseFolder
		
			# is this a file to be copied or lipo'd?
			isLipoFile=false
			itemIsBinary=false
			if [[ $currentDir = */bin ]]; then itemIsBinary=true; fi			
			if [[ $currentName = *.a ]]; then itemIsBinary=true; fi
			if [[ $currentName = *.dylib ]]; then itemIsBinary=true; fi
			if [[ $currentName = *.so ]]; then itemIsBinary=true; fi
			
			# now we have the base set, undo the binary flag if it is a script 
			# or symlink before creating and executing the lipo command on 
			# anything that is still binary after all of the checks.
			if ( $itemIsBinary ); then
				if (grep "^\#\![| ]/bin/sh$" $currentName >> /dev/null); then itemIsBinary=false; fi
				if [[ -L $currentName ]]; then itemIsBinary=false; fi
			fi
			
			if ( $itemIsBinary ); then
				# echo         File: $currentName @ $currentDir is binary

				lipoCommand="/usr/bin/lipo -create"
				partialPath=`expr "$currentDir" : "$baseFolder/Universal/\(.*\)"`
				
				# echo             "in $partialPath"
				
				if ($hasi386 = true); then 
					lipoCommand="$lipoCommand -arch i386 $baseFolder/i386/$partialPath/$currentName"
				fi
				if ($hasx86_64 = true); then 
					lipoCommand="$lipoCommand -arch x86_64 $baseFolder/x86_64/$partialPath/$currentName"
				fi
				if ($hasPPC = true); then
					lipoCommand="$lipoCommand -arch ppc7400 $baseFolder/ppc7400/$partialPath/$currentName"
				fi
				if ($hasPPC64); then 
					lipoCommand="$lipoCommand -arch ppc64 $baseFolder/ppc64/$partialPath/$currentName"
				fi				
				lipoCommand="$lipoCommand -output $baseFolder/Universal/$partialPath/$currentName"
				eval $lipoCommand
			fi
		fi
		
	done
	IFS=$oIFS
}

function mergeVersion
{
	hasi386=false
	hasx86_64=false
	hasPPC=false
	hasPPC64=false
	
	cd $SYNCH_FOLDER/$1
	
	thisFolder=`pwd`
	thisFolderName=`basename $thisFolder`

	versionIFS=$IFS
	mergeIFS=$'\n'
	for f in $(ls -1 ".")
	do
		if [[ -d "${f}" ]]; then
			currentFolder="${f}"
			currentFolderName=`basename $currentFolder`
			
			if (test "$currentFolderName" = "i386"); then 
				hasi386=true
			fi
			if (test "$currentFolderName" = "x86_64"); then 
				hasx86_64=true
			fi
			if (test "$currentFolderName" = "ppc"); then 
				hasPPC=true
			fi
			if (test "$currentFolderName" = "ppc7400"); then 
				hasPPC=true
			fi
			if (test "$currentFolderName" = "ppc64"); then 
				hasPPC64=true
			fi
		fi
	done
	IFS=$versionIFS
	
	if ($hasi386 = true); then echo ... Have i386; fi
	if ($hasx86_64 = true); then echo ... Have x86_64; fi
	if ($hasPPC = true); then echo ... Have ppc; fi
	if ($hasPPC64); then echo ... Have ppc64; fi
	
	# remove the universal folder if it exists
	
	rm -rf Universal
	
	# create a universal from one of the folders - default to x86_64 since that
	# is the defacto arch of all new Macs
	echo mergeVersionFolder: $thisFolder
	
	cp -pR x86_64 Universal
	baseFolder=$thisFolder
	cd Universal
	mergeVersionFolder $(ls -1 ".")
	cd ..
}

function postProcessVersionFolder
{
	currentDir=`pwd`
	oIFS=$IFS
	IFS=$'\n'
	for f in "$@"
	do
		# if it's a folder, process the files in the folder		
		if [[ -d "${f}" ]]; then
			cd "${f}"
			postProcessVersionFolder $(ls -1 ".")
			cd ..
		else
			currentItem="${f}"
			currentName=`basename $currentItem`
			currentDir=`pwd`
				
			# is this a file to be copied or lipo'd?
			shouldProcessFile=false
			itemIsBinary=false
			if [[ $currentDir = */bin ]]; then itemIsBinary=true; fi			
			if [[ $currentName = *.a ]]; then itemIsBinary=true; fi
			if [[ $currentName = *.dylib ]]; then itemIsBinary=true; fi
			if [[ $currentName = *.so ]]; then itemIsBinary=true; fi
			
			# now we have the base set, undo the binary flag if it is a script 
			# or symlink before creating and executing the lipo command on 
			# anything that is still binary after all of the checks.
			if ( $itemIsBinary ); then
				if (grep "^\#\![| ]/bin/sh$" $currentName >> /dev/null); then itemIsBinary=false; fi
				if [[ -L $currentName ]]; then itemIsBinary=false; fi
			fi
			
			if ( $itemIsBinary ); then
				# echo         File: $currentName @ $currentDir is binary

				# figure out the the dylib's to swap out
				
				# echo Item to Process: $currentDir/$currentItem
				
				currentLibs=`otool -L $currentItem | grep "\t/Library/PostgreSQL/lib/" | awk -F" " '{print $1}'`
				
				# loop the item in currentLibs and run install_name_tool for each item
				arr=$(echo $currentLibs | tr " " "\n")
				for i in $arr
				do
					currentLib=`basename ${i}`
					
					installTool="install_name_tool -change"
					installTool="$installTool /Library/PostgreSQL/lib/$currentLib"
					installTool="$installTool @loader_path/../lib/$currentLib"
					installTool="$installTool $currentDir/$currentItem"
					
					# echo ... $installTool	
					eval $installTool
				done

			fi
		fi
		
	done
	IFS=$oIFS
}


function postProcessVersion 
{
	cd $SYNCH_FOLDER/$1
	
	thisFolder=`pwd`
	thisFolderName=`basename $thisFolder`

	if (test -d "./Universal"); then
		cd ./Universal
		postProcessVersionFolder $(ls -1 ".")
	fi

	cd ..
}

#--------1---------2---------3---------4---------5---------6---------7---------8

# make sure all of our directories are in place
if !(test -d $PG_VERSIONS_PATH); then
	mkdir -p $PG_VERSIONS_PATH
fi
if !(test -d $TEMP_PATH); then
	mkdir -p $TEMP_PATH
fi

VERSIONS=`curl --silent "http://www.postgresql.org/versions.rss" > $TEMP_PATH/versions.rss`

CURRENT_VERSION=""
BACK_VERSION=""
OLD_VERSION=""
CURRENT_ARCH=`uname -p`

rdom () { local IFS=\> ; read -d \< E C ;}
while rdom; do
	if [[ $E = "title" ]]; then
		if [[ $C != "PostgreSQL latest versions" ]]; then 
			if [[ $CURRENT_VERSION = "" ]]; then
				CURRENT_VERSION=`echo $C | awk '{gsub(/^ +| +$/,"")}1'`
			elif [[ $BACK_VERSION = "" ]]; then				
				BACK_VERSION=`echo $C | awk '{gsub(/^ +| +$/,"")}1'`
			elif [[ $OLD_VERSION = "" ]]; then				
				OLD_VERSION=`echo $C | awk '{gsub(/^ +| +$/,"")}1'`
			fi
		fi
	fi
done < $TEMP_PATH/versions.rss

# check for the version and the platforms for each version, and if one does not 
# either build it, or if not this platform, exit and wait until the current 

if [[ $CURRENT_ARCH = "powerpc" ]]; then
	if !(test -d $SYNCH_FOLDER/$OLD_VERSION/ppc7400); then
		fetchVersion $OLD_VERSION $INSTALL_PATH
	fi
	
	if !(test -d $SYNCH_FOLDER/$BACK_VERSION/ppc7400); then
		fetchVersion $BACK_VERSION $INSTALL_PATH
	fi

	if !(test -d $SYNCH_FOLDER/$CURRENT_VERSION/ppc7400); then
		fetchVersion $CURRENT_VERSION $INSTALL_PATH
		fetchVersion $CURRENT_VERSION /opt/local
	fi
else
	if !(test -d $SYNCH_FOLDER/$OLD_VERSION/x86_64); then
		fetchVersion $OLD_VERSION $INSTALL_PATH
	fi
	
	if !(test -d $SYNCH_FOLDER/$BACK_VERSION/x86_64); then
		fetchVersion $BACK_VERSION $INSTALL_PATH
	fi

	if !(test -d $SYNCH_FOLDER/$CURRENT_VERSION/x86_64); then
		fetchVersion $CURRENT_VERSION $INSTALL_PATH
		fetchVersion $CURRENT_VERSION /opt/local
	fi
fi

# do the merge

if !(test -d $SYNCH_FOLDER/$OLD_VERSION/Universal); then
	mergeVersion $OLD_VERSION
fi

if !(test -d $SYNCH_FOLDER/$BACK_VERSION/Universal); then
	mergeVersion $BACK_VERSION
	fi

if !(test -d $SYNCH_FOLDER/$CURRENT_VERSION/Universal); then
	mergeVersion $CURRENT_VERSION
fi

# finally, install_name_tool fix the paths to use relative paths
if (test -d $SYNCH_FOLDER/$OLD_VERSION/Universal); then
	postProcessVersion $OLD_VERSION 
fi
if (test -d $SYNCH_FOLDER/$BACK_VERSION/Universal); then
	postProcessVersion $BACK_VERSION
fi
if (test -d $SYNCH_FOLDER/$CURRENT_VERSION/Universal); then
	postProcessVersion $CURRENT_VERSION
fi
echo ... DONE!

