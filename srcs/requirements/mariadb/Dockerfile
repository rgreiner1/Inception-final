FROM alpine:3.20

RUN apk update && \
    apk upgrade && \
    apk add --no-cache mariadb && \
    apk add mariadb-common && \
    apk add mariadb-client && \
    apk add mariadb-server-utils && \
    apk add bash

RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld

RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

RUN	rm -rf /etc/mysql/server.cnf /etc/server.cnf ~/server.cnf

COPY ./conf/server.cnf /etc/mysql/server.cnf
COPY ./conf/server.cnf /etc/server.cnf
COPY ./conf/server.cnf ~/server.cnf

EXPOSE 3306

COPY /tools/entry.sh /
RUN chmod +x /entry.sh

CMD ["/entry.sh"]