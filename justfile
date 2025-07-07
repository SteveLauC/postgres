configure:
    ./configure  --with-system-tzdata=/opt/homebrew/opt/postgresql@17/share/postgresql/timezone --prefix $(pwd)/install

install:
    make install

initdb:
    $(pwd)/install/bin/initdb -D data 