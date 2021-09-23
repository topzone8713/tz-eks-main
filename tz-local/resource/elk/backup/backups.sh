#!/usr/bin/env bash

# apt install awscli
# preparation 1) make s3 auth
# aws configure
# AWS Access Key ID [None]: AKIAJSLFJ2UZND352MYQ
# AWS Secret Access Key [None]: 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
#
# vi /root/.aws/config
# [default]
# output = json
# region = ap-northeast-1
#
# vi /root/.aws/credentials
# [default]
# aws_access_key_id = AKIAJSLFJ2UZND352MYQ
# aws_secret_access_key = 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

# preparation 2) add repo path in elasticsearch.yml 
#vi /etc/es1/elasticsearch.yml
#path.repo: ["/var/lib/es1/nodes"]
#sudo service es1 restart

# preparation 3) add crontab
#0 1 * * *  : sudo /bin/bash /home/elasticsearch/crew-elk/resources/elasticsearch/batch/backups.sh

cd /home/elasticsearch/crew-elk/resources/elasticsearch/batch
export CURDIR=`pwd`

set -x

echo "==[ delete indexes made before 60 days ]============================================"

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"nginx-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"stats-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"user_action-"}]'

sudo /usr/local/bin/curator_cli --host localhost --port 9200 delete_indices \
	--filter_list '[{"filtertype":"age","source":"creation_date","direction":"older","unit":"days","unit_count":60},{"filtertype":"pattern","kind":"prefix","value":"error_action-"}]'

echo "==[start: "`date '+%Y%m%d%H%M%S'`"]============================================"
export DATE=`date +%Y%m%d`

# make s3 bucket
#aws s3 rb s3://soda-elasticsearch --force
COUNT=`aws s3 ls | grep soda-elasticsearch | wc -l`
echo $COUNT
if [ "$COUNT" == "0" ]; then
	aws s3 mb s3://soda-elasticsearch
fi

cd $CURDIR
sudo /bin/bash $CURDIR/backup.sh erroraction
sudo /bin/bash $CURDIR/backup.sh user_action
sudo /bin/bash $CURDIR/backup.sh useraction

sudo /bin/bash $CURDIR/backup.sh nginx-2
sudo /bin/bash $CURDIR/backup.sh stats-2

cd /var/lib/es1
sudo tar cvfz elasticsearch_$DATE.zip /var/lib/es1/nodes

aws s3 cp elasticsearch_$DATE.zip s3://soda-elasticsearch/
aws s3 ls s3://soda-elasticsearch

echo "==[done: "`date '+%Y%m%d%H%M%S'`"]============================================"
rm -Rf /var/lib/es1/*.zip

exit 0
