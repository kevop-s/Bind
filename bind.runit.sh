#!/bin/bash

#######################################
#                                     #
#             Runit Bind 9            #
#                                     #
#######################################

firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload

BIND_CONTAINER="bind"
BIND_DOMAIN="kevops.com"

mkdir -p /var/containers/$BIND_CONTAINER{/var/named/views/,/var/named/zones/,/etc/named} -p
chown 25:0 -R /var/containers/$BIND_CONTAINER

docker run -itd --name $BIND_CONTAINER \
    -p 53:53/tcp \
    -p 53:53/udp \
    --health-cmd='/sbin/docker-health-check.sh' \
    --health-interval=10s \
    -h $BIND_CONTAINER.$BIND_DOMAIN \
    -v /etc/localtime:/etc/localtime:ro \
    -v /usr/share/zoneinfo:/usr/share/zoneinfo:ro \
    -v /var/containers/$BIND_CONTAINER/var/named/views/:/var/named/views/:z \
    -v /var/containers/$BIND_CONTAINER/var/named/zones/:/var/named/zones/:z \
    -v /var/containers/$BIND_CONTAINER/etc/named:/etc/named:z \
    -e "TZ=America/Mexico_City" \
    -e "BIND_DIRECTORY=\"/var/named\"" \
    -e "BIND_DUMP_FILE=\"/var/named/data/cache_dump.db\"" \
    -e "BIND_STATISTICS_FILE=\"/var/named/data/named_stats.txt\"" \
    -e "BIND_MEMSTATISTICS_FILE=\"/var/named/data/named_mem_stats.txt\"" \
    -e "BIND_ALLOW_QUERY={ any;}" \
    -e "BIND_RECURSION=yes" \
    -e "BIND_DNSSEC_ENABLE=yes" \
    -e "BIND_DNSSEC_VALIDATION=yes" \
    -e "BIND_DNSSEC_LOOKASIDE=auto" \
    -e "BIND_BINDKEYS_FILE=\"/etc/named.iscdlv.key\"" \
    -e "BIND_MANAGED_KEYS_DIRECTORY=\"/var/named/dynamic\"" \
    -e "BIND_FORWARDERS={8.8.8.8; 8.8.4.4;}" \
    -e "BIND_AUTH_NXDOMAIN=no" \
    -e "BIND_SESSION_KEYFILE=\"/run/named/session.key\"" \
    -e "BIND_FORWARD=only" \
    -e "BIND_NOTIFY=yes" \
    docker.io/kevopsoficial/bind