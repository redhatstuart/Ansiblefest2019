FROM docker.io/centos:latest
MAINTAINER Guilherme Ferreira - guilherme.nmf@gmail.com 
EXPOSE 8080
LABEL io.openshift.expose-services="8080:http"
RUN yum install httpd -y && \
    yum clean all -y
COPY src/index.html /var/www/html/
RUN sed -i "s/Listen 80/Listen 8080/g" /etc/httpd/conf/httpd.conf && \
    chgrp -R 0 /var/log/httpd /var/run/httpd && \
    chmod -R g=u /var/log/httpd /var/run/httpd
USER 1001
CMD ["usr/sbin/httpd", "-D", "FOREGROUND"]
