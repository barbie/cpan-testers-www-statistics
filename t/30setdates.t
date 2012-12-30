#!perl

use strict;
use warnings;

use CPAN::Testers::WWW::Statistics;
use Data::Dumper;
use Test::More tests => 10;

use lib 't';
use CTWS_Testing;

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );
ok( my $pages = CTWS_Testing::getPages(), "got pages object" );

$pages->setdates();
diag(Dumper($obj->{dates}));

like($pages->{dates}{RUNTIME},      qr{^\w{3}, \d{1,2} \w{3} \d{4} \d{2}:\d{2}:\d{2} \w+$}, 'RUNTIME matches pattern');
like($pages->{dates}{RUNDATE},      qr{^\d{1,2}\w{2} \w+ \d{4}$},                           'RUNDATE matches pattern');
like($pages->{dates}{RUNDATE2},     qr{^\d{1,2}\w{2} \w+ \d{4}$},                           'RUNDATE2 matches pattern');
like($pages->{dates}{RUNDATE3},     qr{^\d{1,2}\w{2} \w+ \d{4}, \d{2}:\d{2}$},              'RUNDATE3 matches pattern');
like($pages->{dates}{THISMONTH},    qr{^\d{6}$},                                            'THISMONTH matches pattern');
like($pages->{dates}{THISDATE},     qr{^\w+ \d+$},                                          'THISDATE matches pattern');
like($pages->{dates}{LASTMONTH},    qr{^\d{6}$},                                            'LASTMONTH matches pattern');
like($pages->{dates}{LASTDATE},     qr{^\w+ \d+$},                                          'LASTDATE matches pattern');
like($pages->{dates}{PREVMONTH},    qr{^\d{2}/\d{2}$},                                      'PREVMONTH matches pattern');
like($pages->{dates}{THATMONTH},    qr{^\d{6}$},                                            'THATMONTH matches pattern');
