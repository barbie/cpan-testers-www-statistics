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
    CREATE TABLE release_summary (
      dist    text    NOT NULL,
      version text    NOT NULL,
      id      int     NOT NULL,
      guid    text    NOT NULL
    );
});

while(<DATA>){
  chomp;
  $dbh->do('INSERT INTO release_summary ( dist, version, id, guid ) VALUES (?, ?, ?, ?)', {}, split(/\|/,$_) );
}

my ($ct) = $dbh->selectrow_array('select count(*) from release_summary');

$dbh->disconnect;

is($ct, 5, "row ct");


#dist|version|id|guid
__DATA__
Acme-Buffy|1.1|23576|00023576-b19f-3f77-b713-d32bba55d77f
Acme-Buffy|1.2|31840|00031840-b19f-3f77-b713-d32bba55d77f
Acme-Buffy|1.3|340624|00126021-b19f-3f77-b713-d32bba55d77f
Acme-Buffy|1.4|355637|00355637-b19f-3f77-b713-d32bba55d77f
Acme-Buffy|1.5|9314169|416fcf48-e41c-11df-bc7b-f3193444d33b
