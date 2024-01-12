CREATE DATABASE "idempiereLP11pro"
    WITH 
    OWNER = adempiere
    ENCODING = 'UTF8'
   TABLESPACE = pg_default
    CONNECTION LIMIT = -1;
ALTER DATABASE "idempiereLP11pro"
    SET search_path TO adempiere;

# DUMP DATABASE
  $ pg_dump -p 5433 -d idempiereLP10pro > dump-LP10pro_2024_01_14.dmp
