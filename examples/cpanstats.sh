#!/usr/bin/bash

BASE=/home/barbie/projects/cpanstats
mkdir -p $BASE/logs

date
cd $BASE

perl bin/cpanstats-writepages       \
     --directory=/var/www/cpanstats \
     --templates=templates          \
     --database=../db/cpanstats.db   >$BASE/logs/writestats.out 2>&1
perl bin/cpanstats-writegraphs \
     --directory=/var/www/cpanstats >>$BASE/logs/writestats.out 2>&1
