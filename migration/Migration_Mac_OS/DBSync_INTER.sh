./migrate_postgresql_for_mac.sh ../i7.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereINTER8.1pro > INTER/INTER_7.1.lst
./migrate_postgresql_for_mac.sh ../i7.1z commit | /Library/PostgreSQL/10/bin/psql -p 5434  -d idempiereINTER8.1pro > INTER/INTER_7.1z.lst
./migrate_postgresql_for_mac.sh ../i8.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereINTER8.1pro > INTER/INTER_8.1.lst
./migrate_postgresql_for_mac.sh ../i8.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereINTER8.1pro > INTER/INTER_8.1z.lst

