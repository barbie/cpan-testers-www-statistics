#!/usr/bin/bash

BASE=/opt/projects/cpantesters/cpanstats
mkdir -p $BASE/logs

date
cd $BASE

perl bin/cpanstats-writepages   \
     --config=data/settings.ini	\
     --logclean=1		\
     --basics --update --stats --leader

perl bin/cpanstats-writegraphs	\
     --config=data/settings.ini

# takes the longest to run
perl bin/cpanstats-writepages   \
     --config=data/settings.ini	\
     --logclean=1		\
     --matrix

