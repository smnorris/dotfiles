#!/bin/bash

# -----------------------------------------------------
# Install and setup GDAL / Postgresql / PostGIS / etc
# -----------------------------------------------------

# install postgres
brew install postgresql

brew install gdal

# homebrew core gdal formula works fine but the osgeo4mac makes fgdb support easier
# adjust and uncomment below if writing to .gdb
# -----------------

# Latest postgres/postgis is often required, but we might not actually want it.
# This example upgrades then revert postgres/postgis

# brew unpin postgresql
# brew unpin postgis
# brew upgrade postgresql
# brew switch postgresql 10.5
# brew switch postgis 2.5.0

# With postgres updated, switch gdal from homebrew core to osgeo4mac

#brew uninstall --ignore-dependencies gdal
#brew tap osgeo/osgeo4mac
#brew install gdal2 --enable-unsupported --with-postgresql --with-complete --with-libkml
#export GDAL_DRIVER_PATH=/usr/local/lib/gdalplugins
#brew install gdal2-filegdb
# this added to .path : export PATH="/usr/local/opt/gdal2/bin:$PATH"
# -----------------

brew services start postgresql       # homebrew provided service to stop/start db

# homebrew now runs initdb, creating superuser with the user account (as in ubuntu)...
# we want a default superuser postgres/postgres for dev, create it
createuser -s -e postgres -U $USER

# create our primary gis db
createdb postgis

# set the password (rather than interactively with the createuser -P option)
psql -U $USER -c "alter user postgres with password postgres;"

# install postgis *after* installing gdal2
brew install postgis

# enable postgis
psql -d postgis -c "CREATE EXTENSION postgis;"

# tune the database

# This writes settings to /usr/local/var/postgres/pgtune.conf to optimize
# postgres for running on big postgis databases. These settings have been
# tested on a 2018 Macbook Pro with 32GB RAM.
# http://big-elephants.com/2012-12/tuning-postgres-on-macos/

cat << EOF > /usr/local/var/postgres/pgtune.conf
log_timezone = 'Canada/Pacific'
datestyle = 'iso, mdy'
timezone = 'Canada/Pacific'
lc_messages = 'en_US.UTF-8'         # locale for system error message
lc_monetary = 'en_US.UTF-8'         # locale for monetary formatting
lc_numeric = 'en_US.UTF-8'          # locale for number formatting
lc_time = 'en_US.UTF-8'             # locale for time formatting
default_text_search_config = 'pg_catalog.english'
default_statistics_target = 100
log_min_duration_statement = 2000
max_connections = 100
max_locks_per_transaction = 64
dynamic_shared_memory_type = posix
checkpoint_timeout = 30min          # range 30s-1d
maintenance_work_mem = 1GB
effective_cache_size = 16GB
work_mem = 500MB
max_wal_size = 10GB
wal_buffers = 16MB
shared_buffers = 8GB
EOF

# Edit /usr/local/var/postgres/postgresql.conf to read and load pgtune.conf

cat << EOF >> /usr/local/var/postgres/postgresql.conf
# Include custom settings:
include = 'pgtune.conf'
EOF

# Tune kernel settings to allow larger amounts of shared memory to facilitate
# parallel processing.
# https://www.postgresql.org/docs/10/static/kernel-resources.html
# https://benscheirman.com/2011/04/increasing-shared-memory-for-postgres-on-os-x/

sudo bash -c 'cat > /etc/sysctl.conf' << EOF
kern.sysv.shmmax=34359738368
kern.sysv.shmmin=1
kern.sysv.shmmni=32
kern.sysv.shmseg=8
kern.sysv.shmall=8388608
kern.maxprocperuid=512
kern.maxproc=2048
EOF

# install and config odbc drivers
brew install psqlodbc

# define an ODBC driver entry for PortgreSQL in the file /usr/local/etc/odbcinst.ini
# note that square brackets around the driver are essential, and change the
# file path of unixodbc as required. get file path with command
# $ odbc_config --odbcinstini
cat <<EOF >> /usr/local/etc/odbcinst.ini
[PostgreSQL Unicode]
Description     = PostgreSQL ODBC driver (Unicode version)
Driver          = psqlodbcw.so
Debug           = 0
CommLog         = 0
UsageCount      = 1
EOF

# define DSNs
# create if not exists the file .odbc.ini in $HOME directory and add the desired DSN
# presumably change protocol value depending on postgres version
touch .odbc.ini
cat <<EOF >> .odbc.ini
[postgis]
Driver      = PostgreSQL Unicode
ServerName  = localhost
Port        = 5432
Database    = postgis
Username    = postgres
Password    = postgres
Protocol    = 12.1
Debug       = 1
EOF

# test with command
# > isql -v postgis
# should connect successfully


# lostgis  -- useful postgis extension
#pip install pgxnclient
#pgxn install lostgis
#pgxn load -d postgis lostgis

# just clone, install functions needed and delete
git clone https://github.com/gojuno/lostgis.git
psql -f lostgis/sql/functions/ST_Safe_Repair.sql
psql -f lostgis/sql/functions/ST_Safe_Difference.sql
psql -f lostgis/sql/functions/ST_Safe_Intersection.sql
rm -rf lostgis

# for dumping postgres queries to csv
brew install psql2csv

# -----------------------------
# Python geo
# -----------------------------
brew install spatialindex
pip install rtree
pip install virtualenv
pip install pyodbc
pip install psycopg2-binary

pip install shapely
pip install fiona
pip install rasterio

pip install jupyter

pip install bcdata
pip install pgdata

# -----------------------------
# another python package manager
# (brew cask may be a better approach?)
# -----------------------------
wget https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
bash Miniconda3-latest-MacOSX-x86_64.sh
rm Miniconda3-latest-MacOSX-x86_64.sh

# -----------------------------
# Python dev
# -----------------------------
# https://github.com/tqdm/tqdm/issues/460
sudo mkdir -p /usr/local/man
sudo chown -R "$USER:admin" /usr/local/man
pip install twine
pip install flake8
pip install black
pip install white

# -----------------------------
# Node
# -----------------------------
npm install -g topojson
npm install -g tokml
npm install -g geojson-rewind
npm install -g togeojson
npm install -g csv2geojson
npm install -g mapshaper
npm install -g http-server
npm install -g tj/serve

# sometimes you want a specific node version, use nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

# -----------------------------
# Misc
# -----------------------------
brew install gist
brew install pandoc
brew install csvkit
brew install rmtrash

wget -O ~/bin/pgconman.py https://raw.githubusercontent.com/perrygeo/pgconman/master/pgconman.py

