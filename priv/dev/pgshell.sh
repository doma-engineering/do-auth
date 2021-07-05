_db_suffix="dev"
if [ ! -z "$1"]; then
  _db_suffix="$1"
fi
psql -U phoenix -h 127.0.0.1 -p 5666 -d "do_auth_${_db_suffix}"
