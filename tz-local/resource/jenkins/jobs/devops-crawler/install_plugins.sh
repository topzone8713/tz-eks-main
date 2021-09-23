#!/bin/bash

java -jar /var/jenkins_home/jenkins-plugin-manager-*.jar --war /usr/share/jenkins/jenkins.war \
  --plugin-download-directory /var/jenkins_home/plugins \
  --plugins greenballs:1.15.1 greenballs \
  --plugins docker-plugin:1.2.2 docker-plugin \
  --plugins docker-workflow:1.26 docker-workflow \
  --plugins workflow-aggregator:2.6 workflow-aggregator \
  --plugins github:1.33.1 github \
  --plugins ws-cleanup:0.39 ws-cleanup \
  --plugins simple-theme-plugin:0.6 simple-theme-plugin \
  --plugins kubernetes:1.29.2 kubernetes \
  --plugins matrix-auth:2.5.2 matrix-auth \
  --plugins kubernetes-cli:1.10.0 kubernetes-cli \
  --plugins github-branch-source:2.10.2 github-branch-source \
  --plugins amazon-ecr:1.6 amazon-ecr


