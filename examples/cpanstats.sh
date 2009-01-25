#!/usr/bin/bash

BASE=/home/barbie/projects/cpan-testers/cpanstats
mkdir -p $BASE/logs

date
cd $BASE

perl bin/cpanstats-writepages   \
     --config=data/settings.ini	\
     --logclean=1		\
     --database=../db/cpanstats.db
perl bin/cpanstats-writegraphs	\
     --config=data/settings.ini
