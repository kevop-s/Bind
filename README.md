# Bind 9

BIND (Berkeley Internet Name Domain, anteriormente: Berkeley Internet Name Daemon) es el servidor de DNS más comúnmente usado en Internet, especialmente en sistemas Unix, en los cuales es un Estándar de facto.

Una nueva versión de BIND (BIND 9) fue escrita desde cero en parte para superar las dificultades arquitectónicas presentes anteriormente para auditar el código en las primeras versiones de BIND, y también para incorporar DNSSEC (DNS Security Extensions). BIND 9 incluye entre otras características importantes: TSIG, notificación DNS, nsupdate, IPv6, rndc flush, vistas, procesamiento en paralelo, y una arquitectura mejorada en cuanto a portabilidad. Es comúnmente usado en sistemas GNU/Linux.

## Despliegue

**Cada uno de los comandos aquí mostrados, deberán ser ejecutados en la máquina host**

Declaramos las variables utilizadas para el depsliegue del contenedor.

```
BIND_CONTAINER="bind"
BIND_DOMAIN="kevops.com"
```

* **BIND_CONTAINER**: Nombre del contenedor.
* **BIND_CONTAINER**: Dominio asociado a la instancia.

Realizamos la configuración del volúmen utilizado por el contenedor.

```
mkdir -p /var/containers/$BIND_CONTAINER{/var/named/views/,/var/named/zones/,/etc/named} -p
chown 25:0 -R /var/containers/$BIND_CONTAINER
```

Permitir la entrada del tráfico por el puerto 53 en caso de tener a **firewalld** activado.

```
firewall-cmd --permanent --add-port=53/tcp
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload
```

Realizamos el despliegue del contenedor.

```
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
```

### Variables de entorno

Las variables de entorno configuran los valores de la sección **options** del archivo [named.conf](https://raw.githubusercontent.com/kevop-s/Bind/master/docker/named.conf).

Para configurar alguno de los valores, con excepción de **listen-on** y **pid-file**, se utiliza la siguiente sintáxis.

* Las variables de entorno pueden estar en mayúsculas o minúsculas.
* El valor de las variables que apuntan a una ruta debera situarse entre comillas.
* Las variables deben iniciar con el prefijo **BIND_**
* Los guiones de la opción a modificar deberán ser sustituidos por guiones bajo.

E.g.
Para configurar la opción **directory** la variable de entorno deberá lucir de la siguiente forma:

```
BIND_DIRECTORY="/var/named"
```

E.g.
Para configurar la opción **forwarders** la variable de entorno deberá lucir de la siguiente forma:

```
BIND_FORWARDERS={8.8.8.8; 8.8.4.4;}
```

### Configuración named.conf

La imagen también admite la creación de un archivo de configuración previamente diseñado, dicho archivo deberá situarse en el directorio **/var/containers/$BIND_CONTAINER/etc/named** con el nombre de **named.conf** previo al despliegue del contenedor, caso contrario el despliegue deberá realizarse integrando las variables de entorno señaladas anteriormente.

## Creación de Zona

Primero creamos la vista correspondiente a la zona que deseamos dar de alta, en el archivo **/var/containers/$BIND_CONTAINER/var/named/views/views.conf**.

> E.g. Suponemos que la zona es kevops.com

```
view "external-zone" {
    match-clients { any; };
    zone "kevops.com" IN {
       type master;
       file "zones/kevops.com.zone";
     };
};
```

A continuación creamos el archivo de zona con los registros necesarios, en el directorio **/var/containers/$BIND_CONTAINER/var/named/zones/**.

> E.g. Suponemos que la zona es kevops.com y el archivo tiene por nombre kevops.com.zone

```
$TTL    3600
@       IN      SOA     kevops.com.  . (
                1267456432      ; Serial
                10800   ; Refresh
                3600    ; Retry
                3600    ; Expire
                1)      ; Minimum
                IN NS  ns0
                IN A   1.2.3.4;
ns0             IN A   1.2.3.4
example         IN A   1.2.3.5
```

Reiniciamos el contenedor para hacer efectivos los cambios.

```
docker restart $BIND_CONTAINER
```