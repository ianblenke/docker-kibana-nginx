FROM nginx
MAINTAINER Ian Blenke <ian@blenke.com>

RUN rm /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/example_ssl.conf

ADD run.sh /
RUN chmod ugo+rx /run.sh

EXPOSE 80

CMD ["/run.sh"]
