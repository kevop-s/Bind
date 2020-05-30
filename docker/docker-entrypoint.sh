#!/bin/bash

FIRST_RUN=1
MAIN_PROC_RUN=1
BIND_CONFIG_FILE="/etc/named/named.conf"
BIND_CONFIG_FILE_BCK="/etc/named.conf"

trap "docker_stop" SIGINT SIGTERM

function docker_stop {
    echo "[BIND $(date +'%Y-%m-%d %R')] Rcv end signal"
    BIND_PID=$(pgrep named)
    rndc stop > /dev/null 2>&1 || kill -TERM $BIND_PID
    export MAIN_PROC_RUN=0
}

function check_variables(){
    cat<<-EOF > $BIND_CONFIG_FILE
options {
  listen-on port 53   { any; };
  pid-file   "/run/named/named.pid";
EOF
    env | grep BIND_ | while read BIND_VAR; do
        VAR=$(echo "${BIND_VAR,,}" | awk '{split($0,a,"="); print a[1]}' | sed "s%bind_%%g" | sed "s%_%-%g")
        VALUE=$(echo "$BIND_VAR" | awk '{split($0,a,"="); print a[2]}')
        VERIFY_VARIABLE=$(cat $BIND_CONFIG_FILE_BCK | grep $VAR -w)

        if [ -n "${VERIFY_VARIABLE}" ]; then
            echo "  $VAR   $VALUE;" >> $BIND_CONFIG_FILE
        else
            echo "[Bind $(date)] Variable isn't valid"
        fi
    done

cat<<-EOF >> $BIND_CONFIG_FILE
};
view "internal-view" {
    recursion yes;
    match-clients { 127.0.0.1/32; };
    zone "." IN {
    type hint;
    file "/var/named/named.ca";
    };
};
include "/var/named/views/views.conf";
EOF

    if [ ! -f "/var/named/views/views.conf" ]; then
        touch /var/named/views/views.conf
    fi
    
    if [ -z "${BIND_KEY_ALGORITHM}" ]; then
        BIND_KEY_ALGORITHM="hmac-md5"
    fi

    if [ -z "${BIND_CPU}" ]; then
        BIND_CPU=1
    fi

    HOSTNAME=$(cat /etc/hostname | awk -F. '{print $1}')
    VERIFY_DNSSEC=$(cat /etc/rndc.key | grep $HOSTNAME -o)
    if [ -z ${VERIFY_DNSSEC} ]; then
        KEY_FILE=$(dnssec-keygen -a ${BIND_KEY_ALGORITHM} -b 512 -n HOST ${HOSTNAME})
        PRIV_KEY=$(cat ${KEY_FILE}.private | awk '/Key/{print $2}')
        sed -i /etc/rndc.key -e "s/key-name/${HOSTNAME}/" -e "s/key-algorithm/${BIND_KEY_ALGORITHM}/" -e "s#key-value#${PRIV_KEY}#"
    fi
}

if [ ! -f /etc/named/named.conf ]; then
    mkdir -p /etc/named/
    check_variables
fi

echo "[BIND $(date +'%Y-%m-%d %R')] Starting Bind"
while [ ${MAIN_PROC_RUN} -eq 1 ]; do
    if [ "${FIRST_RUN}" -ne 0 ] ; then
        /usr/sbin/named -4 -u named -c $BIND_CONFIG_FILE -d 0 -g -n $BIND_CPU
    fi
    sleep 15
    /sbin/docker-health-check.sh
    FIRST_RUN=$?
done