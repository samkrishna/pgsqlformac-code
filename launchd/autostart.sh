## Stop PostgreSQL from auto starting in Mac OS X 10.7.x (Lion)
sudo launchctl unload -w /Library/LaunchDaemons/com.edb.launchd.postgresql-9.1.plist

## Enable PostgreSQL to auto start in Mac OS X 10.7.x (Lion)
sudo launchctl load -w /Library/LaunchDaemons/com.edb.launchd.postgresql-9.1.plist

## Manually Start PostgreSQL
## su as user "postgres" and run server: 
cd /Library/PostgreSQL/9.1/bin/
./pg_ctl -D /Library/PostgreSQL/9.1/data/ start

## Manually Stop PostgreSQL
./pg_ctl -D /Library/PostgreSQL/9.1/data/ stop

## Note:
## - Without "sudo" the commands seem to run successfully but don't take effect
## - Contents of com.edb.launchd.postgresql-9.1.plist in attached file (Permission MUST be: -rw-r--r--  1 root  wheel)