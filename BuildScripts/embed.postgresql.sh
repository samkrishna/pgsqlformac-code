#!/bin/sh

# embed.postgresql.sh
# FiSQL Server
#
# Created by Andy Satori on 3/2/10.
# Copyright 2010 Druware Software Designs. All rights reserved.

# postgresql/bin

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/clusterdb

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/createdb
	
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/createlang
	
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/createuser
	
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/dropdb
	
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/droplang

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/dropuser

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/pg_ctl

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/pg_dump

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/pg_dumpall

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/pg_resetxlog

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/pg_restore

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/psql

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/reindexdb

install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/bin/vacuumdb

# postgresql/lib
	
# libecpg.6.1.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg.6.1.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg.6.1.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg.6.1.dylib

# libecpg.6.3.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg.6.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg.6.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg.6.3.dylib

# libecpg.6.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg.6.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg.6.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg.6.dylib
	
# libecpg.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg.dylib
	
# libecpg_compat.3.1.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg_compat.3. \
	@loader_path/../lib/libecpg_compat.3..dylib \
	./postgresql/lib/libecpg_compat.3.1.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg_compat.3.1.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg_compat.3.1.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg_compat.3.1.dylib

# libecpg_compat.3.2.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg_compat.3. \
	@loader_path/../lib/libecpg_compat.3..dylib \
	./postgresql/lib/libecpg_compat.3.2.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg_compat.3.2.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg_compat.3.2.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg_compat.3.2.dylib

# libecpg_compat.3.2.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg_compat.3. \
	@loader_path/../lib/libecpg_compat.3..dylib \
	./postgresql/lib/libecpg_compat.3.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg_compat.3.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg_compat.3.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg_compat.3.3.dylib

# libecpg_compat.3.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg_compat.3. \
	@loader_path/../lib/libecpg_compat.3..dylib \
	./postgresql/lib/libecpg_compat.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg_compat.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg_compat.3.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg_compat.3.dylib
	
# libecpg_compat.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg_compat.3. \
	@loader_path/../lib/libecpg_compat.3..dylib \
	./postgresql/lib/libecpg_compat.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libecpg.6.dylib \
	@loader_path/../lib/libecpg.6.dylib \
	./postgresql/lib/libecpg_compat.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libecpg_compat.dylib
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libecpg_compat.dylib
	
# libpgtypes.3.1.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libpgtypes.3.1.dylib

# libpgtypes.3.2.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libpgtypes.3.2.dylib

# libpgtypes.3.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libpgtypes.3.dylib

# libpgtypes.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpgtypes.3.dylib \
	@loader_path/../lib/libpgtypes.3.dylib \
	./postgresql/lib/libpgtypes.dylib

# libpq.5.2.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libpq.5.2.dylib

# libpq.5.4.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libpq.5.4.dylib

# libpq.5.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libpq.5.dylib

# libpq.dylib:
install_name_tool -change \
	/Library/PostgreSQL/lib/libpq.5.dylib \
	@loader_path/../lib/libpq.5.dylib \
	./postgresql/lib/libpq.dylib


	



