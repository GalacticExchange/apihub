#!/usr/bin/env bash

/bin/bash -l -c "cd /var/www/apps/apihub/current && RAILS_ENV=$1 bundle exec rake subscribe:redis --silent"