-- Database: idempiereSeed8.2
DROP DATABASE "idempiereSeed8.2";
CREATE DATABASE "idempiereSeed8.2"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

ALTER DATABASE "idempiereSeed8.2"
    SET search_path TO adempiere;