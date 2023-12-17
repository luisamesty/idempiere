# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
# psql -p 5434 postgres
-- Database: idempiereSeed10
DROP DATABASE "idempiereSeed10";
CREATE DATABASE "idempiereSeed10"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereSeed10"
    SET search_path TO adempiere;   