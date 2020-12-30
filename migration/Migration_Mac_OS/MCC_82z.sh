./migrate_postgresql_for_mac.sh ../i8.1z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereMCC8.2pro > MCC/MCC_8.1z.lst
./migrate_postgresql_for_mac.sh ../i8.2 commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereMCC8.2pro > MCC/MCC_8.2.lst
./migrate_postgresql_for_mac.sh ../i8.2z commit | /Library/PostgreSQL/12/bin/psql -p 5434  -d idempiereMCC8.2pro > MCC/MCC_8.2z.lst
