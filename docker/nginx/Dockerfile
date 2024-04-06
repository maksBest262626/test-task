FROM openresty/openresty:1.21.4.2-1-alpine-fat

ARG USER_ID
ARG GROUP_ID
ENV SKIP_TRACK=1

RUN apk add --update  \
    git \
    nano \
    wget \
    curl \
    zip \
    tcpdump \
    openssl \
    rsync \
    g++ make gcc automake autoconf  \
    && rm -rf /var/cache/apk/*

RUN mkdir -p /tmp/fwatch \
    && cd /tmp/fwatch \
    && wget https://github.com/emcrisostomo/fswatch/releases/download/1.17.1/fswatch-1.17.1.tar.gz \
    && tar xvf fswatch-1.17.1.tar.gz \
    && cd fswatch-1.17.1 \
    && ./configure && make && make install

#https://github.com/brimworks/lua-zlib
#https://www.kyne.com.au/%7Emark/software/lua-cjson-manual.html
#https://luarocks.org/modules/pintsized/lua-resty-redis-connector
#https://github.com/moteus/lua-path
#https://github.com/hnimminh/luaredis
#https://github.com/lunarmodules/Penlight
#https://github.com/leafo/magick
RUN    luarocks install lua-cjson \
    && luarocks install lua-resty-redis \
    && luarocks install lua-resty-redis-connector \
    && luarocks install lua-resty-cookie \
    && luarocks install penlight \
    && luarocks install magick \
    && luarocks install lua-path

RUN rm -rf /etc/nginx/conf.d/default.conf

## Virtual host configuration
COPY ./etc-nginx /etc/nginx

# /usr/local/openresty/nginx/conf/nginx.conf
RUN addgroup -g $GROUP_ID nginx-user \
 && adduser -G nginx-user -D -u $USER_ID nginx-user \
 && chown nginx-user:nginx-user /tmp \
 && chown -R nginx-user:nginx-user /etc/nginx/conf.d/ \
 && chown -R nginx-user:nginx-user /usr/local/openresty/ \
 && chown -R nginx-user:nginx-user /var/run/openresty/ \
 && chmod g+w,g+s /etc/nginx/conf.d/ \
 && mkdir -p /var/log/nginx \
 && chown -R nginx-user: /var/log/nginx \
 && chmod g+w,g+s /var/log/nginx

#RUN touch /tmp/nginx.pid \
#    && chmod +w /tmp/nginx.pid \
#    && chown -R nginx-user:nginx /tmp/nginx.pid \
#    && chown -R nginx-user:nginx /var/run/nginx.pid
#
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh

#USER nginx-user
WORKDIR /var/www

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]