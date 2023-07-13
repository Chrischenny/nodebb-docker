#!/bin/ash
shutdown() {
  pkill -f redis-server
  echo "Redis stoped"
  [ ! -e /etc/nodebb/config.json ] && [ -e /opt/nodebb/config.json ] && cp /opt/nodebb/config.json /etc/nodebb/config.json
  echo "Stopped"
  exit 143;
}

term_handler() {
  echo "SIGTERM received"
  pkill -f node
  echo "NodeBB stoped"
  shutdown
}

set_timezone() {
  if [ ! -z $timezone ]
  then
    echo "Setting timezone"
    apk add tzdata;
    cp /usr/share/zoneinfo/"$timezone" /etc/localtime;
    echo $timezone > /etc/timezone;
    apk del tzdata;
  fi
}

trap term_handler SIGTERM

echo "Starting"
[ -e /var/lib/redis/appendonly.aof ] && chown redis /var/lib/redis/appendonly.aof
redis-server /etc/redis.conf

if [ -e /opt/nodebb/config.json ]; then
  rm -f /opt/nodebb/config.json
fi

cd /opt/nodebb/
set_timezone
if [ ! -e /etc/nodebb/config.json ]; then
  node app start
  # 等待用户前台配置完成后会退出，然后配置文件根据环境变量写道 /etc/nodebb/config.json，再次启动
  node app start
else
  node app start
fi
echo "NodeBB died"

# [ -e /etc/nodebb/config.json ] && yes n | node nodebb upgrade

shutdown
