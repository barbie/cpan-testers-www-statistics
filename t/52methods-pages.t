#!perl

use strict;
use warnings;

use Test::More tests => 35;
use CPAN::Testers::WWW::Statistics::Pages;

use lib 't';
use CTWS_Testing;

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );
ok( my $pages = CTWS_Testing::getPages(), "got pages object" );

$obj->address('t/data/addresses.txt');


my %names = (
    'barbie@missbarbell.co.uk' => 'Barbie (BARBIE)',
    'barbie@cpan.org' => 'barbie[]cpan org'
);

for my $name (keys %names) {
    is($pages->_tester_name($name), $names{$name}, "tester name matches: $name");
}
my %exts = (     1 => 'st',  2 => 'nd',  3 => 'rd',  4 => 'th',  5 => 'th',
                 6 => 'th',  7 => 'th',  8 => 'th',  9 => 'th', 10 => 'th',
                11 => 'th', 12 => 'th', 13 => 'th', 14 => 'th', 15 => 'th',
                16 => 'th', 17 => 'th', 18 => 'th', 19 => 'th', 20 => 'th',
                21 => 'st', 22 => 'nd', 23 => 'rd', 24 => 'th', 25 => 'th',
                26 => 'th', 27 => 'th', 28 => 'th', 29 => 'th', 30 => 'th',
                31 => 'st'
);

for my $ext (keys %exts) {
    is(CPAN::Testers::WWW::Statistics::Pages::_ext($ext),$exts{$ext}, "extension matches: $ext");
}