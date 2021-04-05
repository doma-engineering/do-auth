/usr/lib/postgresql/12/bin/pg_ctl -D ./pgdata -l logfile stop; mv ~/.pgpass{,.old}; rm -rf ./logfile ./pgdata
