#!perl

use strict;
use warnings;
$|=1;

use Test::More tests => 9;
use File::Path;
use lib 't';
use CTWS_Testing;
use File::Spec;
use File::Path;

ok( my $obj = CTWS_Testing::getObj(), "got object" );

ok( unlink($obj->database), 'removed database' );
ok( rmtree( File::Spec->catfile('t','_DBDIR') ), 'removed DBDIR' );
ok( rmtree($obj->directory), 'removed directory' );

ok( ! -f $obj->database, 'database removed' );
ok( ! -d $obj->directory, 'directory removed' );

# these shouldn't exist ...  whack just to be sure.
rmtree( File::Spec->catfile('t','_DBDIR')    );
rmtree( File::Spec->catfile('t','_EXPECTED') );

# triple check
ok( ! -d File::Spec->catfile('t','_TMPDIR'),   '_TMPDIR removed'   );
ok( ! -d File::Spec->catfile('t','_DBDIR'),    '_DBDIR removed'    );
ok( ! -d File::Spec->catfile('t','_EXPECTED'), '_EXPECTED removed' );

