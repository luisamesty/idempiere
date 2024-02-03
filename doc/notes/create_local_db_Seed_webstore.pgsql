# DATABASE FOR ICREATED webstore API
# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/12/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
  # psql -p 5433 postgres
# for m4erp.com execute as user postgres: 
  $ su postgres
-- Database: idempiereSeed11_webstore
DROP DATABASE "idempiereSeed11_webstore";
CREATE DATABASE "idempiereSeed11_webstore"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereSeed11_webstore"
    SET search_path TO adempiere;   
    
 
 # CREATE DATABASE idempiereSeed11_webstore FROM Adempiere_pg.jar 
# Execute Postgres ON MAC  Port 5434 - 5433 or 5432
# /Library/PostgreSQL/15/bin/psql -p 5434 postgres
# Execute Postgres ON LINUX  Port 5434 - 5433 or 5432
# for m4erp.com execute as user postgres: 
  $ su postgres
# Unzip Adempiere_pg.jar from /home/luisamesty/sources/iDempiere11/idempiere/org.adempiere.server-feature/data/seed
# TO: /home/luisamesty/sources/iDempiere11/Adempiere_pg.dmp
# EXECUTE 
  $ psql -p 5433 -d idempiereSeed11_webstore -f Adempiere_pg.dmp ;   

