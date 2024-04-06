#!/bin/sh

echo 'Import LUA configuration'
#. /dev/stdin <<< "$(luarocks path)"
eval "$(luarocks path)"

#echo LUA_PATH: $LUA_PATH
#export LUA_PATH

check_err() {
  error_num="$1"
  error_name="$2"
  shift

  if [ ! -z "$error_num" ] && [ $error_num -ne 0 ]
  then
        echo "Error: ${error_num}, ${error_name}"
  fi
}

replace_vars() {
  echo Replace ENVs in configuration files
  for filename in /etc/nginx/conf.d/*.conf
  do
      [ -e "$filename" ] || continue
  
      echo "---> process: ${filename}"
      printenv | while read envv; do \
        vn=$(echo $envv | sed 's|=.*||');
        vv=$(echo $envv | sed 's|[^=]*=||');
        sed -i "s/<$vn>/$vv/" "$filename";
      done
  done
}

nginx_start() {
  rsync -va /etc/nginx/conf.dist/ /etc/nginx/conf.d/
  replace_vars
  echo "Starting Nginx..."
  nginx -t
  
  is_nginx_loaded=$(ps ax | grep nginx | grep worker)

  if [[ -n "$is_nginx_loaded" ]]; then
    nginx -s reload
  else
    nginx
  fi
}
nginx -s stop
nginx_start

echo 'Starting file watcher';
while true; do
    fswatch -1 /etc/nginx/conf.dist/ | xargs -0 -I {} sleep 1
    nginx_start
done