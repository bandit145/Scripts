#Note: This is to be launched from an ansible deployment playbook 
#TODO: when deploying we need another script the uses scp to copy the keys to clients
#TODO: install redis,sensu,rabbitmq,uchiwa start and enable at end of script
#can add checks and stuff later if needed
#sensu server configuration for ansible to run against server
import subprocess as sp

#install rabbimq and redis from ansible
#might have to pull these two into a second script    
sp.call(["wget -q http://sensu.global.ssl.fastly.net/apt/pubkey.gpg -O- | sudo apt-key add -"])
sp.call(['echo "deb     http://sensu.global.ssl.fastly.net/apt sensu main" | sudo tee /etc/apt/sources.list.d/sensu.list'])
#sensu package is installed with built in ansible commmand'
sp.call(["mkdir /home/server/ssl"])
sp.call(["cd /home/server/ssl && wget http://sensuapp.org/docs/0.25/files/sensu_ssl_tool.tar && tar -xvf sensu_ssl_tool.tar"])
sp.call(["cd /home/server/ssl/sensu_ssl_tool $$ ./ssl_certs.sh generat"])
sp.call("mkdir /etc/sensu/ssl")
sp.call(["cp /home/server/ssl/sensu_ssl_tool/client /home/server/ssl/sensu_ssl_tool/sensu_ca /home/server/ssl/sensu_ssl_tool/server /etc/sensu/ssl"])
sp.call(["cp /home/server/sensu_ssl_tool/sensu_ca/cacert.pem /home/server/sensu_ssl_tool/server/cert.pem /home/server/sensu_ssl_tool/server/key.pem /etc/rabbitmq/ssl"])
#config rabbitmq
sp.call(["rabbitmqtcl add_vhost /sensu"])
sp.call(["rabbitmqtcl add_user sensu password"])
sp.call(['rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"'])
#throw certs into etc/sensu/etc
sp.call(["cp /home/server/sensu_ssl_tool/server/cert.pem  /home/server/sensu_ssl_tool/server/key.pem /etc/sensu/ssl"])
#Asnible will add the config files to the servers
#rabbitmq: /etc/sensu/conf.d/rabbitmq.json
#api: /etc/sensu/conf.d/api.json
#uchiwa: /etc/sensu/uchiwa.json
#transport: /etc/sensu/transport.json
#redis:  /etc/sensu/conf.d/redis.json
