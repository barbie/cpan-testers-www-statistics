#!perl

use strict;
use warnings;
$|=1;

use Test::More tests => 15;
use File::Spec;
use lib 't';
use CTWS_Testing;

ok( my $obj = CTWS_Testing::getObj(), "got object" );
isa_ok( $obj, 'CPAN::Testers::WWW::Statistics', "Parent object type" );

ok( my $page = CTWS_Testing::getPages(), "got object" );
isa_ok( $page, 'CPAN::Testers::WWW::Statistics::Pages', "Pages object type" );
ok( my $graph = CTWS_Testing::getGraphs(), "got object" );
isa_ok( $graph, 'CPAN::Testers::WWW::Statistics::Graphs', "Graphs object type" );

my $db = File::Spec->catfile('t','_DBDIR','test.db');
isa_ok( $obj->{CPANSTATS},         'CPAN::Testers::Common::DBUtils', 'CPANSTATS' );
is(     $obj->{CPANSTATS}->{database}, $db,                          'CPANSTATS.database' );
is(     $obj->{CPANSTATS}->{driver},   'SQLite',                     'CPANSTATS.database' );

isa_ok( $obj->{UPLOADS},         'CPAN::Testers::Common::DBUtils', 'UPLOADS' );

is( $obj->database, $db, 'database' );
ok( -f $obj->database, 'database exists' );

ok( $obj->directory, 'directory' );
is( $obj->directory, File::Spec->catfile('t','_TMPDIR'), 'directory' );
ok( -d $obj->directory, 'directory exists' );

