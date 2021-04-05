db:
	/usr/lib/postgresql/12/bin/initdb -D pgdata
	mkdir pgdata/sockets
	cp priv/dev/postgresql.conf ./pgdata/
	/usr/lib/postgresql/12/bin/pg_ctl -D ./pgdata -l logfile start
	priv/dev/create-role-phoenix.sh
	cp priv/dev/pg_hba.conf ./pgdata/
	/usr/lib/postgresql/12/bin/pg_ctl -D ./pgdata -l logfile restart

hooks:
	cp -v priv/dev/pre-commit .git/hooks/

dev: hooks db
