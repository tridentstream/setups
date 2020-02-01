#!/usr/bin/env bash

# We wrap the entire script in a big function which we only call at the very end, in order to
# protect against the possibility of the connection dying mid-script. This protects us against
# the problem described in this blog post:
#   http://blog.existentialize.com/dont-pipe-to-your-shell.html
_() {
postgres_url_path="https://ftp.postgresql.org/pub/source/v12.1/postgresql-12.1.tar.gz"

pyenv_root="${HOME}/.pyenv"

read -r -d '' start_sh <<"EOF"
#!/usr/bin/env bash

PORT=45477
HOST=0.0.0.0
PRIVATE_KEY=
CERT_KEY=
POSTGRES_PATH=%POSTGRES_PATH%

# make sure we are in the right path
work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $work_dir

# make pyenv available
PATH="%pyenv_root%/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# postgres stuff
$POSTGRES_PATH/bin/pg_ctl -D pg-data status
status=$?
if [ $status -eq 3 ]; then
    mkdir -p pg-data/socket
    $POSTGRES_PATH/bin/pg_ctl -D pg-data -l logfile start
    $POSTGRES_PATH/bin/createdb tridentstream --host=`pwd`/pg-data/socket/
fi

# activate environment
pyenv activate tridentstream

# install additional plugins
if [ ! -e "requirements.txt" ]; then
    touch "requirements.txt"
fi
pip install -r requirements.txt

# install plugins
shopt -s nullglob
if [ -d "packages" ]; then
    for filename in packages/*.{tar.gz,zip,whl}; do
        pip install "$filename"
    done
fi

# bootstrap
bootstrap-tridentstream

# build command
cmd="twistd tridentstream -e "
if [ -z "$PRIVATE_KEY" ]
then
    cmd="$cmd tcp:$PORT:interface=$HOST"
else
    cmd="$cmd \"ssl:$PORT:interface=$HOST:privateKey=$PRIVATE_KEY:certKey=$CERT_KEY\""
fi
exec $cmd
EOF

read -r -d '' restart_sh <<"EOF"
#!/usr/bin/env bash

./stop.sh
./start.sh
EOF

read -r -d '' stop_sh <<"EOF"
#!/usr/bin/env bash

if [ -e "twistd.pid" ]; then
    pkill -F twistd.pid
fi
EOF

install_pyenv() {
    curl https://pyenv.run | bash
}

activate_pyenv() {
    PATH="${pyenv_root}/bin:${PATH}"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
}

install_postgresql() {
    current_path=$(pwd)
    tmp_dir=$(mktemp -d)
    cd $tmp_dir
    wget $postgres_url_path
    tar zxvf postgresql-12.1.tar.gz
    cd postgresql-12.1
    ./configure --prefix=$current_path/postgres
    make
    make install

    POSTGRES_PATH=$current_path/postgres
    cd $current_path
}

setup_postgres() {
    $POSTGRES_PATH/bin/initdb pg-data
    echo "listen_addresses = ''" >> pg-data/postgresql.conf
    echo "unix_socket_directories = 'socket'" >> pg-data/postgresql.conf
}

install_tridentstream() {
    pyenv install -s 3.7.6
    if ! pyenv activate tridentstream ; then
        pyenv virtualenv 3.7.6 tridentstream
        pyenv activate tridentstream
    fi

    pip install -U setuptools wheel pip
    pip install psycopg2-binary pyopenssl leveldb
    pip install tridentstream
}

setup_tridentstream() {
    mkdir -p tridentstream/media tridentstream/dbs tridentstream/packages
}

create_environ() {
    touch .environ
    echo "SECRET_KEY=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`" >> .environ
    echo "MEDIA_ROOT=`pwd`/media" >> .environ
    echo "DATABASE_ROOT=`pwd`/dbs" >> .environ
    echo "DATABASE_URL=postgres:///`pwd`/pg-data/socket/tridentstream" >> .environ
    echo "CACHE_URL=dbcache://dbcache" >> .environ
    echo "INSTALLED_APPS=" >> .environ
}

write_start_sh() {
    body=start_sh
    body="${start_sh}"
    body="${body/\%POSTGRES_PATH\%/$POSTGRES_PATH}"
    body="${body/\%pyenv_root\%/$pyenv_root}"
    echo "$body" > start.sh
    chmod +x start.sh
}

write_stop_sh() {
    echo "$stop_sh" > stop.sh
    chmod +x stop.sh
}

write_restart_sh() {
    echo "$restart_sh" > restart.sh
    chmod +x restart.sh
}

usage() {
    cat << EOF
Usage: ${0##*/} [-h] [-p PG_PATH]
Generate configuration files for Tridentstream.

    -h, --help       display this help and exit.
    -p, --postgres   Path to postgresql binaries, if not specified, will download and install
EOF
}

check_config() {
    if [ ! -z "$POSTGRES_PATH" ] && [ -f "$POSTGRES_PATH/bin/initdb" ]; then
        echo "Postgres path defined but expected binaries not found"
        exit 1
    fi
}

main() {
    if ! [ -x "$(command -v pyenv)" ]; then
        install_pyenv
    fi
    activate_pyenv

    install_tridentstream
    setup_tridentstream
    cd tridentstream

    if [ -z "$POSTGRES_PATH" ]; then
        install_postgresql
    fi
    setup_postgres

    if [ ! -f .environ ]; then
        create_environ
    fi

    write_start_sh
    write_stop_sh
    write_restart_sh

    clear
    echo "Finished setting up, start up Tridentstream with:"
    echo "  cd tridentstream"
    echo "  ./start.sh"
    echo ""
    echo "After Tridentstream is started, head over to https://<ip>:45477/ and login for the first time"
}

POSTGRES_PATH=
while [ "$1" != "" ]; do
    case $1 in
        -p | --postgres )       shift
                                POSTGRES_PATH=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

check_config
main
}

# Now that we know the whole script has downloaded, run it.
_ "$@"