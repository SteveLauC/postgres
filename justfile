default:
  just --list

configure:
    ./configure  --with-system-tzdata=/opt/homebrew/opt/postgresql@17/share/postgresql/timezone --prefix $(pwd)/install

install:
    make install -j 12

initdb:
    $(pwd)/install/bin/initdb -D $(pwd)/data 

start-master:
    $(pwd)/install/bin/pg_ctl -D $(pwd)/data -o "-p 5433" start

stop-master:
    $(pwd)/install/bin/pg_ctl -D $(pwd)/data -o "-p 5433" stop

single:
    $(pwd)/install/bin/postgres --single -D $(pwd)/data postgres

psql:
    $(pwd)/install/bin/psql --port 5433 postgres
