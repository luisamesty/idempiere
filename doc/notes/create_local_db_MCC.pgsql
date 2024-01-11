# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
  # psql -p 5433 postgres
# for m4erp.com execute as user postgres: 
  $ su postgres
-- Database: idempiereMCC11pro
DROP DATABASE "idempiereMCC11pro";
-- OR RENAME
ALTER DATABASE "idempiereMCC11pro"
RENAME TO "idempiereMCC11pro2";
--CREATE
CREATE DATABASE "idempiereMCC11pro"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereMCC11pro"
    SET search_path TO adempiere;

# CREATE DATABASE FROM BACKUP
# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
  # psql -p 5434 postgres
# for m4erp.com execute as user postgres: 
  $ su postgres
# EXECUTE restore Command
 $psql -p 5433 -d idempiereMCC11pro -f idempiereMCC11pro_2023_10_26_2315_psql ;


# UNZIP bz2 files on UBUNTU
bunzip2 idempiereMCC11pro_2023_10_26_2315.pgsql.bz

bunzip2 path/to/myfile.bz2
bzip2 -d path/to/myfile.bz

# LINUX TAMANACO
Para entrar al PostgreSQL:
$ 

# /opt/PostgreSQL/150/bin/psql -p 5432 -U adempiere idempiereMCC11pro

How to kill all other active connections to your database in PostgreSQL?
#Using SQL Query, run the query below:

SELECT    pg_terminate_backend(pg_stat_activity.pid)
FROM    pg_stat_activity
WHERE    pg_stat_activity.datname = 'database_name'
    AND pid <> pg_backend_pid();

or this query:
SELECT    pg_terminate_backend(pid)
FROM    pg_stat_get_activity(NULL::integer)
WHERE    datid = (
        SELECT            oid
        FROM            pg_database
        WHERE            datname = 'database_name');

# DUMP DATABASE
  $ pg_dump -p 5433 -d idempiereMCC11pro > dump-MCC11pro_2024_01_14.dmp
