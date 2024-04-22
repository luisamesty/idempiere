# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
# psql -p 5433 postgres
-- Database: idempiereTAM8.2pro
DROP DATABASE "idempiereTAM8.2pro";
-- OR RENAME
ALTER DATABASE "idempiereTAM8.2pro"
RENAME TO "idempiereTAM8.2pro2";
--CREATE
CREATE DATABASE "idempiereTAM8.2pro"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereTAM8.2pro"
    SET search_path TO adempiere;

# CREATE DATABASE FROM BACKUP
# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
# psql -p 5434 postgres
psql -p 5433 -d idempiereTAM8.2pro -f idempiereTAM8.2pro_2023_10_26_2315_psql ;


# UNZIP bz2 files on UBUNTU
bunzip2 idempiereTAM8.2pro_2023_10_26_2315.pgsql.bz idempiereTAM8.2pro_2024_04_11_2315.pgsql
bunzip2 path/to/myfile.bz2
bzip2 -d path/to/myfile.bz

# LINUX TAMANACO
Para entrar al PostgreSQL:
$ 

# /opt/PostgreSQL/10/bin/psql -p 5432 -U adempiere idempiereTAM8.2pro

How to kill all other active connections to your database in PostgreSQL?
#Using SQL Query, run the query below:

SELECT    pg_terminate_backend(pg_stat_activity.pid)
FROM    pg_stat_activity
WHERE    pg_stat_activity.datname = 'idempiereTAM8.2pro'
    AND pid <> pg_backend_pid();

or this query:
SELECT    pg_terminate_backend(pid)
FROM    pg_stat_get_activity(NULL::integer)
WHERE    datid = (
        SELECT            oid
        FROM            pg_database
        WHERE            datname = 'idempiereTAM8.2pro');


