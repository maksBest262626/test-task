FROM redis:7.2.0-alpine
# For generate redis conf do command(in this folder)     wget -O redis.conf 'http://download.redis.io/redis-stable/redis.conf'
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
# For check(after building) use command
# docker exec -it dester_ebay_redis /bin/sh
# redis-cli
# ping         # Should be return "PONG"
# set a1 brrrya
# get a1       # Should be return "brrrya"