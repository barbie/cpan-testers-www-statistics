#!perl

use strict;
use warnings;
$|=1;

use Test::More tests => 5;
use File::Path;
use lib 't';
use CTWS_Testing;
use File::Spec;
use File::Path;

ok( my $obj = CTWS_Testing::getObj(), "got object" );

rmtree( 't/_DBDIR' );       # removed DBDIR
rmtree($obj->directory);    # removed directory

if($^O =~ /Win32/i) {   # Windows cannot delete until after process has stopped
    ok(1);
} else {
    ok( ! -d $obj->directory,   'directory removed' );
}

# these shouldn't exist ...  whack just to be sure.
rmtree( "t/$_" )    for(qw(_TMPDIR _DBDIR _EXPECTED));

# triple check
if($^O =~ /Win32/i) {   # Windows cannot delete until after process has stopped
    ok(1);
    ok(1);
    ok(1);
} else {
    ok( ! -d 't/_TMPDIR',   '_TMPDIR removed'   );
    ok( ! -d 't/_DBDIR',    '_DBDIR removed'    );
    ok( ! -d 't/_EXPECTED', '_EXPECTED removed' );
}

