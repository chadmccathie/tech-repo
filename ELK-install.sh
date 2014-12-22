#!/usr/bin/env bash
set ex
echo -e "Please enter the Hostname or FQDN of the server. Note : This must be the exact address you type to access Kibana"
read IPADDRESS

#Install Java
sudo yum -y install java-1.7.0-openjdk

# Install Nginx 1.6.2

sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
sudo yum install nginx16 -y
sudo chkconfig nginx on
sudo service nginx start

# Install Logstash and start the service
sudo rpm -ivh https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-1.4.2-1_2c0f5a1.noarch.rpm
service logstash start

# Install the plugins
sudo rpm -ivh https://download.elasticsearch.org/logstash/logstash/packages/centos/logstash-contrib-1.4.2-1_efd53ef.noarch.rpm

# Generate the SSL Certs for the Logstash Forwarders
sudo openssl req -x509 -batch -nodes -newkey rsa:2048 -keyout /etc/pki/tls/private/logstash-forwarder.key -out /etc/pki/tls/certs/logstash-forwarder.crt

# Input the configuration files for logstash, Input and Output
sudo echo 'input {
  lumberjack {
  port => 5000
    type => "logs"
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}' | sudo tee -a  /etc/logstash/conf.d/10-lumberjack-input.conf

sudo echo 'output {
elasticsearch {
host => '\"$IPADDRESS\"'
cluster => "elasticsearch"
}
}' | sudo tee -a /etc/logstash/conf.d/20-lumberjack-output.conf

# Install Elasticsearch 
sudo rpm -ivh http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.2.noarch.rpm
sudo chkconfig elasticsearch on
sudo service elasticsearch start

sudo echo 'cluster.name: elasticsearch
network.bind_host: '\"$IPADDRESS\"'
network.publish_host: '\"$IPADDRESS\"'
http.cors.enabled: true
discovery.zen.ping.multicast.enabled: false
network.host: '\"$IPADDRESS\"'' | sudo tee -a  /etc/elasticsearch/elasticsearch.yml

# Download and install Kibana
sudo wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz
sudo tar zxvf kibana-3.1.2.tar.gz -C /opt/

# Set the nginx config for Kibana
sudo echo '
server {
listen 80 default_server;
root /opt/kibana-3.1.2;
index index.html index.htm;
location / {
try_files $uri $uri/ /index.html;
}
}' | sudo tee -a  /etc/nginx/conf.d/kibana.conf

# Clean up tmp files
sudo rm *.tar.gz
