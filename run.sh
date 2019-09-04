#!/usr/bin/env bash

set -e
if ! [ "`which docker`" ]; then (echo [`date`] ERROR: docker must be installed >&2) && exit 1; fi
cd "$(dirname "$0")"

SERVICE=front

usage() {
    echo "---------------------------------------------------------------------------------"
    echo "USAGE: ./run.sh start|stop|exec|ps|sh"
    echo "NGINX: ./run.sh test|reload"
    echo ""
    exit 1
}

stop() {
    if [ -z "$@" ]; then
        docker-compose down
    else 
        docker-compose kill $@
    fi
}

up() {
    docker-compose up -d --build $@
    docker-compose logs -f --tail 300 $@
}

logs() {
    docker-compose logs -f $@
}

error_logs() {
    docker-compose logs $@ front 2>&1 | grep 'warn\|error' | cut -f2 -d\* | cut -f1 -d,
}

execute() {
    docker-compose exec $@
}

pslist() {
    docker-compose ps
}


[[ "$1" == "stop" ]] && { shift; stop $@; exit 0; }
[[ "$1" == "start" ]] && { shift; up $@; exit 0; }
[[ "$1" == "restart" ]] && { shift; stop $@; up $@; exit 0; }
[[ "$1" == "exec" ]] && { shift; exec $@; exit 0; }
[[ "$1" == "sh" ]] && { shift; docker-compose exec $SERVICE sh; exit 0; }
[[ "$1" == "ps" ]] && { pslist; exit 0; }
[[ "$1" == "logs" ]] && { shift; logs $@; exit 0; }

# nginx specifics
[[ "$1" == "test" ]] && { shift; docker-compose exec $SERVICE nginx -t; exit 0; }
[[ "$1" == "reload" ]] && { shift; docker-compose exec $SERVICE nginx -s reload; exit 0; }
[[ "$1" == "errors" ]] && { shift; error_logs $@; exit 0; }



usage
