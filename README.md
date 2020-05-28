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
    -h $BIND_CONTAINER.$BIND_DOMAIN \
    -v /etc/localtime:/etc/localtime:ro \
    -v /usr/share/zoneinfo:/usr/share/zoneinfo:ro \
    -v /var/containers/$BIND_CONTAINER/var/named/views/:/var/named/views/:z \
    -v /var/containers/$BIND_CONTAINER/var/named/zones/:/var/named/zones/:z \
    -v /var/containers/$BIND_CONTAINER/etc/named:/etc/named:z \
    -e "TZ=America/Mexico_City" \
    docker.io/kevopsoficial/bind
```

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
                3600)   ; Minimum
                IN NS  ns0
                IN A   1.2.3.4;
ns0             IN A   1.2.3.4
example         IN A   1.2.3.5
```

Reiniciamos el contenedor para hacer efectivos los cambios.

```
docker restart $BIND_CONTAINER
```