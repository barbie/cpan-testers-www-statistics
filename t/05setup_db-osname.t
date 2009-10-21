#!perl

use strict;
use warnings;
use Test::More tests => 1;
use DBI;
use File::Spec;
use File::Path;
use File::Basename;

my $f = File::Spec->catfile('t','_DBDIR','test.db');
#unlink $f if -f $f;
mkpath( dirname($f) );

my $dbh = DBI->connect("dbi:SQLite:dbname=$f", '', '', {AutoCommit=>1});
$dbh->do(q{
    CREATE TABLE `osname` (
        `id`        int		NOT NULL,
        `osname`    text    NOT NULL,
        `ostitle`   text    NOT NULL,
      PRIMARY KEY  (`id`)
    );
});

while(<DATA>){
  chomp;
  $dbh->do('INSERT INTO osname ( id, osname, ostitle ) VALUES ( ?, ?, ? )', {}, split(/\|/,$_) );
}

my ($ct) = $dbh->selectrow_array('select count(*) from osname');

$dbh->disconnect;

is($ct, 24, "row ct");


# select * from osname;
#id|osname|ostitle
__DATA__
1|aix|AIX
2|bsdos|BSD/OS
3|cygwin|Windows (Cygwin)
4|darwin|Mac OS X
5|dec_osf|Tru64
6|dragonfly|Dragonfly BSD
7|freebsd|FreeBSD
8|gnu|GNU Hurd
9|haiku|Haiku
10|hpux|HP-UX
11|irix|IRIX
12|linux|Linux
13|macos|Mac OS classic
14|midnightbsd|MidnightBSD
15|mirbsd|MirOS BSD
16|mswin32|Windows (Win32)
17|netbsd|NetBSD
18|openbsd|OpenBSD
19|os2|OS/2
20|os390|OS390/zOS
21|osf|OSF
22|sco|SCO
23|solaris|SunOS/Solaris
24|vms|VMS
