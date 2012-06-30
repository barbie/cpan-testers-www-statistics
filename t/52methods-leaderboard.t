#!perl

use strict;
use warnings;

use Test::More tests => 3;
use CPAN::Testers::WWW::Statistics;

use lib 't';
use CTWS_Testing;
use Data::Dumper;

my $expected1 = { };
my $expected2 = { 
    '999999' => {
        'solaris' => {
            'kriegjcb + mi ruhr-uni-bochum de ((Jost Krieger))' => 1,
            'JOST + cpan org (&quot;Josts Smokehouse&quot;)' => 1
        },
        'darwin' => {
            'jj + jonallen info (&quot;JJ&quot;)' => 2
        },
        'openbsd' => {
            'bingos + cpan org' => 1
        },
        'linux' => {
            'CPAN DCOLLINS + comcast net' => 4,
            'cpan + sourcentral org (&quot;Oliver Paukstadt&quot;)' => 5,
            'andreas koenig gmwojprw + franz ak mind de' => 1,
            'imacat + mail imacat idv tw' => 10
        },
        'freebsd' => {
            'srezic + cpan org' => 4,
            'bingos + cpan org' => 1
        },
        'mswin32' => {
            'stro + cpan org' => 1,
            'rhaen + cpan org (Ulrich Habel)' => 2
        }
    }
};

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );

$obj->leaderboard( renew => 1 );

my $data = $obj->leaderboard( check => 1 );
#diag('check=' . Dumper($data));
is_deeply( $data, $expected1, '.. no differences' );

$data = $obj->leaderboard( results => [ '999999' ] );
#diag('results=' . Dumper($data));
is_deeply( $data, $expected2, '.. known results' );

