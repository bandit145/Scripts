
#Note: This is to be launched from an ansible deployment playbook 
#TODO: when deploying we need another script the uses scp to copy the keys to clients
#TODO: install redis,sensu,rabbitmq,uchiwa start and enable at end of script
#can add checks and stuff later if needed
#sensu server configuration for ansible to run against server
import subprocess as sp

#install rabbimq and redis from ansible
#might have to pull these two into a second script    
sp.call(["wget -q http://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | apt-key add -"], shell = True)
sp.call(['echo "deb     http://sensu.global.ssl.fastly.net/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list'], shell = True)
#sensu package is installed with built in ansible commmand'
sp.call(["mkdir /home/server/ssl"], shell = True)
sp.call(["cd /home/server/ssl && wget http://sensuapp.org/docs/0.25/files/sensu_ssl_tool.tar && tar -xvf sensu_ssl_tool.tar"], shell = True)
sp.call(["cd /home/server/ssl/sensu_ssl_tool && ./ssl_certs.sh generate"], shell = True)
sp.call(["mkdir /etc/sensu"], shell = True)#probably be made throuhg ansible
sp.call(["mkdir /etc/sensu/ssl"], shell = True)
sp.call(["cp /home/server/ssl/sensu_ssl_tool/client /home/server/ssl/sensu_ssl_tool/sensu_ca /home/server/ssl/sensu_ssl_tool/server /etc/sensu/ssl"], shell = True)
sp.call(["cp /home/server/sensu_ssl_tool/sensu_ca/cacert.pem /home/server/sensu_ssl_tool/server/cert.pem /home/server/sensu_ssl_tool/server/key.pem /etc/rabbitmq/ssl"], shell = True)
#config rabbitmq
sp.call(["rabbitmqtcl add_vhost /sensu"], shell = True)
#replace password with password(not secure but yolo)
sp.call(["rabbitmqtcl add_user sensu password"], shell = True)
sp.call(['rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"'], shell = True)
#throw certs into etc/sensu/etc
sp.call(["cp /home/server/sensu_ssl_tool/server/cert.pem  /home/server/sensu_ssl_tool/server/key.pem /etc/sensu/ssl"], shell = True)
#Asnible will add the config files to the servers
#rabbitmq: /etc/sensu/conf.d/rabbitmq.json
#api: /etc/sensu/conf.d/api.json
#uchiwa: /etc/sensu/uchiwa.json
#transport: /etc/sensu/transport.json
#redis:  /etc/sensu/conf.d/redis.json
#start redis
sp.call(["/etc/init.d/redis-server start"], shell = True)
sp.call(["update-rc.d redis-server defaults"], shell = True)
#start rabbitmq
sp.call(["update-rc.d rabbitmq-server defaults"], shell = True)
sp.call(["service rabbitmq-server start"], shell = True)
#start sensu
sp.call(["update-rc.d sensu-server defaults"], shell = True)
sp.call(["update-rc.d sensu-api defaults"], shell = True)
sp.call(["/etc/init.d/sensu-server start"], shell = True)
sp.call(["sudo /etc/init.d/sensu-api start"], shell = True)
#start uchiwa
sp.call(["update-rc.d uchiwa defaults"], shell = True)
sp.call(["service uchiwa start"], shell = True)