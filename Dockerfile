FROM node:18-alpine AS build
RUN apk add --no-cache redis git sed \
  && cd /opt \
  && git clone https://github.com/NodeBB/NodeBB.git nodebb \
  && cd nodebb \
  && git checkout -b v3.2.1 v3.2.1 \
  && npm config set registry https://registry.npmmirror.com \
  && npm install -g npm@8.10.0 \
  && cp install/package.json package.json \
  && npm install \
  && npm install @chrischenny/nodebb-plugin-node-ldap-ad@1.0.0 \
  && sed -i '1 idaemonize yes' /etc/redis.conf \
  && sed -i 's/bind 127.0.0.1 ::1/bind 127.0.0.1/' /etc/redis.conf \
  && sed -i 's/appendonly no/appendonly yes/' /etc/redis.conf \
  && sed -i '/save */d' /etc/redis.conf

FROM node:18-alpine
ADD ./supervisor.sh /
RUN chmod +x /supervisor.sh \
  && apk add --no-cache redis \
  && mkdir -p /etc/nodebb \
  && npm install -g npm@8.10.0 \
  && chmod 777 /var/lib/redis
COPY --from=build /etc/redis.conf /etc
COPY --from=build /opt/nodebb /opt/nodebb
ENV NODE_ENV=production config=/etc/nodebb/config.json launchCmd="echo 1"
WORKDIR /opt/nodebb
EXPOSE 4567
VOLUME ["/etc/nodebb", "/var/lib/redis", "/opt/nodebb/public/uploads"]
CMD ["/supervisor.sh"]
