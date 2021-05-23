#./migrate_postgresql_for_mac.sh ../i7.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_7.1.lst
#./migrate_postgresql_for_mac.sh ../i7.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_7.1z.lst
./migrate_postgresql_for_mac.sh ../i8.1 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_8.1.lst
./migrate_postgresql_for_mac.sh ../i8.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_8.1z.lst
./migrate_postgresql_for_mac.sh ../i8.2 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_8.2.lst
./migrate_postgresql_for_mac.sh ../i8.2z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereSeed8.2 > Seed/Seed_8.2z.lst

