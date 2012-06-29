#!perl

use strict;
use warnings;

use Test::More tests => 3;
use CPAN::Testers::WWW::Statistics;

use lib 't';
use CTWS_Testing;

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );

$obj->address('t/data/addresses.txt');


my %names = (
    'barbie@missbarbell.co.uk' => 'Barbie (BARBIE)',
    'barbie@cpan.org' => 'barbie + cpan org'
);

for my $name (keys %names) {
    is($obj->tester($name), $names{$name}, "tester name matches: $name");
}
