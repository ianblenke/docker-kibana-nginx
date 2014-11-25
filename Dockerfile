FROM nginx
MAINTAINER Ian Blenke <ian@blenke.com>

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y wget ca-certificates
RUN wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz -O /tmp/kibana.tar.gz && \
    mkdir -p /app && \
    tar zxf /tmp/kibana.tar.gz && mv kibana-3.1.2/* /app

RUN rm /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/example_ssl.conf

ADD run.sh /
RUN chmod ugo+rx /run.sh

EXPOSE 80

CMD ["/run.sh"]
