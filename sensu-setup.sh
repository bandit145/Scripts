#install rabbimq and redis from ansible
#might have to pull these two into a second script    
get -q http://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | apt-key add -
echo "deb     http://sensu.global.ssl.fastly.net/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list
#sensu package is installed with built in ansible commmand'
mkdir /home/server/ssl
cd /home/server/ssl && wget http://sensuapp.org/docs/0.25/files/sensu_ssl_tool.tar && tar -xvf sensu_ssl_tool.tar
cd /home/server/ssl/sensu_ssl_tool && ./ssl_certs.sh generate
mkdir /etc/sensu
mkdir /etc/sensu/ssl
cp /home/server/ssl/sensu_ssl_tool/client /home/server/ssl/sensu_ssl_tool/sensu_ca /home/server/ssl/sensu_ssl_tool/server /etc/sensu/ssl
cp /home/server/sensu_ssl_tool/sensu_ca/cacert.pem /home/server/sensu_ssl_tool/server/cert.pem /home/server/sensu_ssl_tool/server/key.pem /etc/rabbitmq/ssl
#config rabbitmq
rabbitmqtcl add_vhost /sensu
#replace password with password(not secure but yolo)
rabbitmqtcl add_user sensu password
rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"
#throw certs into etc/sensu/etc
cp /home/server/sensu_ssl_tool/server/cert.pem  /home/server/sensu_ssl_tool/server/key.pem /etc/sensu/ssl
#Asnible will add the config files to the servers
#rabbitmq: /etc/sensu/conf.d/rabbitmq.json
#api: /etc/sensu/conf.d/api.json
#uchiwa: /etc/sensu/uchiwa.json
#transport: /etc/sensu/transport.json
#redis:  /etc/sensu/conf.d/redis.json
#start redis
/etc/init.d/redis-server start
update-rc.d redis-server defaults
#start rabbitmq
update-rc.d rabbitmq-server defaults
service rabbitmq-server start
#start sensu
update-rc.d sensu-server defaults
update-rc.d sensu-api defaults
/etc/init.d/sensu-server start
sudo /etc/init.d/sensu-api start
#start uchiwa
update-rc.d uchiwa defaults
service uchiwa start