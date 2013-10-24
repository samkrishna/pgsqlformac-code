![](./background.tif)

# PostgreSQL 9.3.0 - Universal

## Release Notes and Quick Installation Guide

PostgreSQL has come a very long way. When we started this; there was no 
prepackaged package available from PostgreSQL.org, there were packages that blindly followed the Unix / Linux conventions that PostgreSQL used by default but nothing official, and there was little support for the Mac. Today, there is official support, commercial support and an ever growing base of users around the world. In that same time, PostgreSQL itself has gone from a good Open Source alternative RDBMS to a very good RDBMS that competes well against the best of the breed, commercial or Open Source.

Our original vision was to be more than just a package, something that also 
brought enterprise ready tools. That vision has never come to fruition, primarily due to a lack of financial support. Open Source software does not pay very well. This release contains the work we have done to date, and though we continue to work with these tools to improve them, there are changes coming. Specifically, there will be commercial versions of the tools that are more complete and robust appearing in the Mac App Store. That revenue should help speed up the process.

The first fruits of that labor are included in this release.  An alpha level version of the enQuery Lite adhoc query tool is now included in the applications folder.  At this point it is roughly on par with the old Query Tool, and will eventually supplant the Query Tool in the distribution. 

There is another reason for this revenue push.

We believe that looking forward, PostgreSQL for the Mac is going to need to evolve to support the sandbox and the new 'services' model of the host. This is going to require a good bit of work, work that will need to be done with some focus. We want to contribute that work back to the community, but also be able to pay the people doing the work.

### Release Notes 10-18-2013

* Updated to 9.3.0 published standalone, support for PowerPC dropped
* Support for Mavericks added
* Support for 10.6.x dropped
* Started updated all the GUI tools to modern Xcode to move development forward

#### Known Issues

* Create User will fail when a UserID is entered, the underlying syntax changed 
	and the generated query is wrong.
* None of the Data Views in the Preference Pane work, only Source Views.
* The installer does NOT stop a currently running instance of PostgreSQL, and 
	will fail the install if one is running
* If the installer fails, please let us know and provide a copy of the 
	installation log with the error, this will greatly help us address any 
	remaining issues in the installer.
	
### Installation Guide

This package no longer uses multiple installers.  The Server installation goes into the /Library/ folder.  It will install into two folders, /Library/PostgreSQL and /Library/StartupItems/PostgreSQL.  It also creates a Postgres user and group via directory services.  There is an uninstall script placed into the /Applications/PostgreSQL folder that removes all of the above.  The server installation does not include the static libraries, only the dynamic libraries. If you want the static libraries, you will need to download the Developer package.


The Developer folder contains the documentation and framework for the PGSQLKit framework to make developing for PostgreSQL easier with a Cocoa like framework 
for access.


The Client Tools package is no longer a .pkg installer, though the .pkg does 
remain in the server install package, and can be run on it’s own.  Since it 
doesn’t need to place anything in specific locations, all of the Client tool 
applications have been placed in a folder, so that you may elect what you wish 
to put where.  Further, these tools can be installed to any Mac OS X (10.5+)  
install and do not require a local installation of the server.


### Technical Notes
Of technical note, the command line options used to build the core packages are slightly different for the Server and the Developer version.  On the Server 
side, the options are:
	./configure --prefix=/Library/PostgreSQL --with-openssl --with-bonjour \
		--with-perl --with-pam --with-krb5 --with-tcl --with-python \
		--with-gssapi

For users that wish to use Ruby with PostgreSQL, the easiest way to integrate the two is to use either the Postgres or PG gems.  Both can be installed with this server:

	postgres:
		sudo gem install postgres -- --with-pgsql-dir=/Library/PostgreSQL
		
	pg:
		sudo gem install pg -- --with-pg-dir=/Library/PostgreSQL


### Contributing

We are frequently asked about how to contribute to the project.  Your contributions are not only welcomed, but encouraged.  They help us keep his 
project going.  Code and documentation are welcomed, but if money is asier, it is welcomed as well.  All donations are run through SourceForge.net:

Donate to the PostgreSQL for Mac project: 
<http://sourceforge.net/donate/index.php?group_id=133151>

### License

PostgreSQL itself is licensed under the BSD License.  In addition, the GUI 
tools are also released under a BSD style license, copyright Druware 
Software Designs.  The BSD license, means that in the simplest terms is 
that  you can do whatever you want with the product and source code as long 
as you don't claim you wrote it or sue us. You should give it a read though,
it is only half a page and follows below:
	
	Copyright (c) 1997-2013, PostgreSQL Global Development Group
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are met:

	1. Redistributions of source code must retain the above copyright notice, 
		this list of conditions and the following disclaimer. 
	2. Redistributions in binary form must reproduce the above copyright notice, 
		this list of conditions and the following disclaimer in the 
		documentation and/or other materials provided with the distribution. 
	3. Neither the name of the PostgreSQL Global Development Group nor the names
		of its contributors may be used to endorse or promote products derived 
		from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.

