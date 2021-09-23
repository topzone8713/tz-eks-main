#!/usr/bin/env bash

set -x

export INDEX=$1

pwd
cp template.sh run.sh
sed -i "s|_INDEX|$1|g" run.sh
sudo bash run.sh

exit 0
