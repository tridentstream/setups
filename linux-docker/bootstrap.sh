#!/usr/bin/env bash

install_deluge() {
    mkdir deluge-downloads
    chown 911:911 deluge-downloads
    mkdir -p deluge/plugins
    if [ ! -f deluge/plugins/Streaming-0.11.0-py3.6.egg ]; then
        wget -P deluge/plugins https://github.com/JohnDoee/deluge-streaming/releases/download/0.11.0/Streaming-0.11.0-py3.6.egg
    fi

    envsubst "\$EXTERNAL_HOST,\$DELUGE_PASSWORD" < streaming.conf.template > deluge/streaming.conf
    envsubst "\$DELUGE_PASSWORD" < deluge-fixture.json.template > tridentstream/fixtures/deluge-fixture.json
}

setup_tridentstream() {
    mkdir -p tridentstream/fixtures tridentstream/packages
}

create_env() {
    touch .env
    echo "SECRET_KEY=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`" >> .env
    echo "POSTGRES_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`" >> .env

    echo "DELUGE_PASSWORD=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`" >> .env

    echo "EXTERNAL_HOST=$EXTERNAL_HOST" >> .env
    echo "INSTALLED_APPS=" >> .env
}

setup_templates() {
    envsubst "" < nginx.conf.template > nginx.conf
}

usage() {
    cat << EOF
Usage: ${0##*/} [-hd] [-o HOSTNAME]
Generate configuration files for Tridentstream.

    -h, --help       display this help and exit.
    -o, --hostname   Hostname to use to access the server.
    -d, --deluge     Use built-in deluge.
EOF
}

check_config() {
    if [ -z "$EXTERNAL_HOST" ]; then
        echo "No hostname defined, please define a hostname and try again"
        exit 1
    fi
}

main() {
    if [ ! -f .env ]; then
        create_env
    fi

    set -a
    . ./.env
    set +a

    setup_tridentstream

    if [ "$use_deluge" -eq "1" ]; then
        install_deluge
    fi

    setup_templates

    if [ "$use_deluge" -eq "1" ]; then
        start_command="docker-compose -f docker-compose.yml -f docker-compose.deluge.yml up -d"
    else
        start_command="docker-compose up -d"
    fi

    echo $start_command > start.sh
    chmod +x start.sh

    echo "Finished setting up, start up Tridentstream with:"
    echo "./start.sh"
    echo "or"
    echo $start_command
    echo ""
    echo "After Tridentstream is started, head over to https://$EXTERNAL_HOST/ and login for the first time"
    if [ "$use_deluge" -eq "1" ]; then
        echo ""
        echo "Since you also installed Deluge, make sure you open up https://$EXTERNAL_HOST/_deluge_web/ and change"
        echo "the default deluge password to something unique"
    fi
}

use_deluge=0
while [ "$1" != "" ]; do
    case $1 in
        -o | --hostname )       shift
                                EXTERNAL_HOST=$1
                                ;;
        -d | --deluge )         use_deluge=1
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