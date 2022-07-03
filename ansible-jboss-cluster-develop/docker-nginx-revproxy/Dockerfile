FROM ubuntu

MAINTAINER jayendren <jayendren@gmail.com>

# ENVARS
ENV TIME_ZONE Africa/Johannesburg

# INSTALL
RUN \
  #add-apt-repository -y ppa:nginx/stable && \
  apt-get update && \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
#  rm -f /etc/nginx/sites-enabled/default && \
  chown -R www-data:www-data /var/lib/nginx

ADD src/nginx.conf /etc/nginx/nginx.conf

# POST INSTALL
RUN cp /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime

# CLEAN UP
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# PORTS
EXPOSE 80
EXPOSE 443

# VOLUMES
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]
WORKDIR /etc/nginx

# CMD
ENTRYPOINT ["nginx"]
