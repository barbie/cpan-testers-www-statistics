#!/usr/bin/bash

BASE=/home/barbie/projects/cpanstats
mkdir -p $BASE/logs

date
cd $BASE

perl bin/cpanstats-writepages   >$BASE/logs/writestats.out 2>&1
perl bin/cpanstats-writegraphs >>$BASE/logs/writestats.out 2>&1
