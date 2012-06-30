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
    CREATE TABLE leaderboard (
        postdate    text    NOT NULL,
        osname      text    NOT NULL,
        tester      text    NOT NULL,  
        score       int     NOT NULL,  
        PRIMARY KEY (postdate,osname,tester)
    )
});

my ($ct) = $dbh->selectrow_array('select count(*) from leaderboard');

$dbh->disconnect;

is($ct, 0, "row ct");

__DATA__
