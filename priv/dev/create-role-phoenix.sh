#!/usr/bin/env bash

set -euo pipefail

_pw_phoenix=$(mix phx.gen.secret)
_pw_root=$(mix phx.gen.secret)
_user=$(whoami)
cat >/tmp/run.sql <<EOF
create role phoenix with password '${_pw_phoenix}';
alter role phoenix with login;
alter role phoenix createdb;
alter role ${_user} with password '${_pw_root}';
alter role ${_user} with login;
EOF
/usr/lib/postgresql/12/bin/psql -h 127.0.0.1 -d postgres -f /tmp/run.sql
rm /tmp/run.sql
cat <<EOF
Created role 'phoenix' with password ${_pw_phoenix}
Save this password to your configuration!
For demonstration purposes, restricted local logins to password-based logins.
New password for user ${_user} is ${_pw_root}. Saving this password to ~/.pgpass ...
EOF
echo -n "127.0.0.1:5432:postgres:${_user}:${_pw_root}" >> ~/.pgpass
chmod 0600 ~/.pgpass
echo "Done!"

cat <<EOF

* * *
Now saving phoenix password into ./config/dev.secret.exs
EOF

cat >> config/dev.secret.exs <<EOF

config :do_auth, DoAuth.Repo, username: "phoenix", password: "${_pw_phoenix}"

EOF
chmod 0600 config/dev.secret.exs
echo "Done!"
