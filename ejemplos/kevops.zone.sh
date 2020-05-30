#!/bin/bash
#############################################
#                                           #
#      E.g. Configuración de una zona       #
#                                           #
#############################################

# Creamos la vista para la zona que daremos de alta
cat<<-EOF > /var/containers/$BIND_CONTAINER/var/named/views/views.conf
view "external-zone" {
    match-clients { any; };
    zone "kevops.com" IN {
       type master;
       file "zones/kevops.com.zone";
     };
};
EOF

# Creamos el archivo con los registros correspondientes a la zona
cat<<-EOF > /var/containers/$BIND_CONTAINER/var/named/zones/kevops.com.zone
\$TTL    3600
@       IN      SOA     kevops.com.  . (
                1      ; Serial
                10800   ; Refresh
                3600    ; Retry
                3600    ; Expire
                1)      ; Minimum
                IN NS  ns0
                IN A   1.2.3.4
ns0             IN A   1.2.3.4
ejemplo         IN A   1.2.3.5
EOF
