#!perl

use strict;
use warnings;
$|=1;

use Test::More tests => 17;
use File::Spec;
use lib 't';
use CTWS_Testing;

ok(  my $obj = CTWS_Testing::getObj(), "got object" );
isa_ok( $obj, 'CPAN::Testers::WWW::Statistics', "Parent object type" );

ok(  my $page = CTWS_Testing::getPages(), "got object" );
isa_ok( $page, 'CPAN::Testers::WWW::Statistics::Pages', "Pages object type" );

ok(  my $graph = CTWS_Testing::getGraphs(), "got object" );
isa_ok( $graph, 'CPAN::Testers::WWW::Statistics::Graphs', "Graphs object type" );

my $db = 't/_DBDIR/test.db';
isa_ok( $obj->{CPANSTATS},         'CPAN::Testers::Common::DBUtils', 'CPANSTATS' );
is(     $obj->{CPANSTATS}->{database}, $db,                          'CPANSTATS.database' );
is(     $obj->{CPANSTATS}->{driver},   'SQLite',                     'CPANSTATS.database' );

is(    $obj->database, $db, 'database' );
ok( -f $obj->database, 'database exists' );

ok(    $obj->directory, 'directory' );
is(    $obj->directory, File::Spec->catfile('t', '_TMPDIR'), 'directory' );
ok( -d $obj->directory, 'directory exists' );


my @now = localtime(time);
my $date1 = sprintf "%04d%02d", $now[5]+1900, $now[4]; $date1++;
my $date2 = sprintf "%04d%02d", $now[5]+1900, $now[4];
my $date3 = sprintf "%04d%02d", $now[5]+1900, $now[4]; $date3--;

$date2 -= 88    if($date2 % 100 > 12 || $date2 % 100 < 1);
$date3 -= 88    if($date3 % 100 > 12 || $date3 % 100 < 1);

eval { $page->set_dates() };
is($page->{dates}{THISMONTH}, $date1, '..this month');
is($page->{dates}{LASTMONTH}, $date2, '..last month');
is($page->{dates}{THATMONTH}, $date3, '..previous month');

