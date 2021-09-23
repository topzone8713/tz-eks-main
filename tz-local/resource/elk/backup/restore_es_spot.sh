#!/usr/bin/env bash

# restore_es_spot.sh 20180111

DATE="$1"
echo "Date: " $DATE

sudo mkdir -p /tmp
cd /tmp
sudo rm -Rf /tmp/var

echo sudo aws s3 cp s3://soda-elasticsearch/elasticsearch_$DATE.zip elasticsearch_$DATE.zip
sudo aws s3 cp s3://soda-elasticsearch/elasticsearch_$DATE.zip elasticsearch_$DATE.zip
echo sudo tar xvfz /tmp/elasticsearch_$DATE.zip
sudo tar xvfz /tmp/elasticsearch_$DATE.zip

sudo service es1 stop
sudo rm -Rf /var/lib/es1/nodes_bak
sudo mv /var/lib/es1/nodes /var/lib/es1/nodes_bak
sudo mv /tmp/var/lib/es1/nodes /var/lib/es1/nodes
sudo service es1 start

exit 0
