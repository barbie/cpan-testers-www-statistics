# Complete DB Schema for CPANSTATS Database

DROP TABLE IF EXISTS cpanstats;
CREATE TABLE cpanstats (
     id         int(10) unsigned NOT NULL,
     state      varchar(32),
     postdate   varchar(8),
     tester     varchar(255),
     dist       varchar(255),
     version    varchar(255),
     platform   varchar(255),
     perl       varchar(255),
     osname     varchar(255),
     osvers     varchar(255),
     fulldate   varchar(32),
     PRIMARY KEY (id)
);

DROP TABLE IF EXISTS `release_data`;
CREATE TABLE `release_data` (
  `dist`	varchar(255) NOT NULL,
  `version`	varchar(255) NOT NULL,
  `id`		int(10) unsigned NOT NULL,
  `oncpan`	tinyint(4) default '0',
  `distmat`	tinyint(4) default '0',
  `perlmat`	tinyint(4) default '0',
  `patched`	tinyint(4) default '0',
  `pass`	int(10) default '0',
  `fail`	int(10) default '0',
  `na`		int(10) default '0',
  `unknown`	int(10) default '0'
);

DROP TABLE IF EXISTS release_summary;
CREATE TABLE release_summary (
    dist        varchar(255) NOT NULL,
    version     varchar(255) NOT NULL,
    id          int(10) unsigned NOT NULL,
    oncpan      tinyint(4) default 0,
    distmat     tinyint(4) default 0,
    perlmat     tinyint(4) default 0,
    patched     tinyint(4) default 0,
    pass        int(10) default 0,
    fail        int(10) default 0,
    na          int(10) default 0,
    unknown     int(10) default 0
);

DROP TABLE IF EXISTS `uploads`;
CREATE TABLE `uploads` (
  `type`        varchar(10)     NOT NULL,
  `author`      varchar(32)     NOT NULL,
  `dist`        varchar(255)    NOT NULL,
  `version`     varchar(255)    NOT NULL,
  `filename`    varchar(255)    NOT NULL,
  `released`    int(16)		NOT NULL,
  PRIMARY KEY  (`author`,`dist`,`version`)
) ENGINE=MyISAM;

DROP TABLE IF EXISTS `ixlatest`;
CREATE TABLE `ixlatest` (
  `dist`        varchar(255)    NOT NULL,
  `version`     varchar(255)    NOT NULL,
  `released`    int(16)		NOT NULL,
  `author`      varchar(32)     NOT NULL,
  `oncpan`      tinyint(4)      DEFAULT 0,
  PRIMARY KEY  (`dist`)
) ENGINE=MyISAM;

DROP TABLE IF EXISTS `summary`;
CREATE TABLE `summary` (
  `type`	varchar(8)	 NOT NULL,
  `name`	varchar(255)     NOT NULL,
  `lastid`	int(10) unsigned NOT NULL,
  `dataset`	blob,
  PRIMARY KEY  (`type`,`name`)
) ENGINE=MyISAM;

DROP TABLE IF EXISTS `page_requests`;
CREATE TABLE `page_requests` (
  `type`	varchar(8)	 NOT NULL,
  `name`	varchar(255)     NOT NULL,
  `weight`	int(2) unsigned  NOT NULL
) ENGINE=MyISAM;

DROP TABLE IF EXISTS osname;
CREATE TABLE osname (
     id         int(10) unsigned NOT NULL auto_increment,
     osname     varchar(255),
     ostitle    varchar(255),
     PRIMARY KEY (id)
);

