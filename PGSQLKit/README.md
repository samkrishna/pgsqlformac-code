


# License

Copyright (c) 2005-2013, Druware Software Designs
All rights reserved.

Redistribution and use in binary forms, with or without modification, are 
permitted provided that the following conditions are met:

1. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution. 
2. Neither the name of the Druware Software Designs nor the names of its 
contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
THE POSSIBILITY OF SUCH DAMAGE.

# Change Log

## 04/23/2013
* fixed a bug in PQSQLField asNumber: method.  Could trunctate values due to 
  an improper use of float versus double

## 07/31/2012
* cleaned up a bunch of warnings
* reworked project file to better work with relocating the framework into 
  applications, bundles and other frameworks in order to make the framework
  sandbox friendly

## 02/15/2012
* added ntiffin's refactoring of PGSQLConnection to use PGSQLConnectionBase 
  and use of PGSQLDispatch to replace the underlying asynchronous methods. 
  initial testing shows strong performance improvements with the usage of 
  blocks
* clean up of PGSQLDataObject(List) implementations to address bugs in save and
  xml behavior, as well as remove last few analyzer issues

## 02/08/2012
* completed initial implementation of PGSQLDataObject, DataObjectList and 
  associated unit tests.

## 01/30/2012
* initial add of PGSQLDataObject into the PGSQLKit from the internal 
  experimental branch
* added NSData+Base64.h/m from Matt Gallagher to support the xml serialization

## 10/12/2011
* updated to 9.1.1 libpq code
* released as part of Universal Installer.

## 10/04/2011
* began GenDB implementation and migration for enQuery

## 09/21/2010
* added -clone() method to PGSQLConnection for a quick and easy create of a 
duplicate connection from the existing connection.
* updated to libpq from PostgreSQL9 release.
* PGSQLLogin now collapses when a saved connection is selected.

