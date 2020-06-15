#!/bin/bash
####################################################
#                                                  #
#     E.g. Configuración de una zona esclava       #
#                                                  #
####################################################

# DNS Master
cat<<-EOF > /var/containers/$BIND_CONTAINER/var/named/views/views.conf
view "zona-externa" {
    match-clients { any; };
    zone "kevops.com" IN {
       type master;
       file "zones/kevops.com.zone";
       allow-transfer { 10.142.0.2; };
       also-notify { 10.142.0.2; };
       notify yes;
     };
};
EOF

# DNS Esclavo
cat<<-EOF > /var/containers/$BIND_CONTAINER/var/named/views/views.conf
view "zona-externa" {
    match-clients { any; };
    zone "kevops.com" IN {
       type slave;
       file "zones/kevops.com.zone";
       masters { 10.128.0.9; };                                                            
     };
};
EOF