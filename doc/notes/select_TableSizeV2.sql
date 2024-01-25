SELECT
  t.schema_name,
  t.relname,
  pg_size_pretty(t.table_size) AS size,
  t.table_size, CAST(reg.reltuples as integer) as record_num

FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,reltuples,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size

       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
         GROUP BY  pg_catalog.pg_namespace.nspname, relname, reltuples, pg_catalog.pg_class.oid
     ) t
LEFT JOIN (
	SELECT 
	  nspname AS schema_name,relname,COALESCE(reltuples,0) as reltuples
	FROM pg_class C
	LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
	WHERE 
	  nspname NOT IN ('pg_catalog', 'information_schema') AND
	  relkind='r' 
) as reg ON reg.schema_name = t. schema_name AND reg.relname = t.relname

WHERE t.schema_name NOT LIKE 'pg_%'
ORDER BY table_size DESC;