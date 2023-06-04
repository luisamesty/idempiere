# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
# psql -p 5434 postgres
-- Database: idempiereTAM8.2pro
DROP DATABASE "idempiereTAM8.2pro";
CREATE DATABASE "idempiereTAM8.2pro"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereTAM8.2pro"
    SET search_path TO adempiere;

    