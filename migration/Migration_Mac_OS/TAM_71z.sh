./migrate_postgresql_for_mac.sh i7.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereTAM8.1pro > TAM/TAM_7.1.lst
./migrate_postgresql_for_mac.sh i7.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereTAM8.1pro > TAM/TAM_7.1z.lst
./migrate_postgresql_for_mac.sh i8.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereTAM8.1pro > TAM/TAM_8.1.lst
./migrate_postgresql_for_mac.sh i8.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereTAM8.1pro > TAM/TAM_8.1z.lst

