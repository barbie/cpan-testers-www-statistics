#!perl

use strict;
use warnings;

use Test::More tests => 19;
use CPAN::Testers::WWW::Statistics;
use CPAN::Testers::WWW::Statistics::Pages;
use CPAN::Testers::WWW::Statistics::Graphs;

my %config = (
    't/data/21config01.ini' => "Must specify the output directory\n",        # no output directory
    't/data/21config02.ini' => "Must specify the template directory\n",      # no template directory
    't/data/21config03.ini' => "No configuration for CPANSTATS database\n",  # no CPANSTATS database
    't/data/21config05.ini' => "No configuration for UPLOADS database\n",    # no UPLOADS database
);

for my $config (keys %config) {
    eval { CPAN::Testers::WWW::Statistics->new(config => $config) };
    is($@, $config{$config}, "config: $config");
}


%config = (
    't/data/21config07.ini' => "Template directory not found\n",
    't/data/21config08.ini' => "Must specify the path of the SQL database\n",
    't/data/21config09.ini' => "Archive SQLite database not found\n",
    't/data/21config10.ini' => "Must specify the path of the address file\n",
    't/data/21config11.ini' => "Address file not found\n",
);

for my $config (keys %config) {
    ok( my $obj   = CPAN::Testers::WWW::Statistics->new(config => $config), "got parent object" );
    eval { $obj->make_pages };
    is($@, $config{$config}, "config: $config");
}


eval { CPAN::Testers::WWW::Statistics->new() };
is($@,"Must specify the configuration file\n");
eval { CPAN::Testers::WWW::Statistics->new(config => 'doesnotexist') };
is($@,"Configuration file [doesnotexist] not found\n");
eval { CPAN::Testers::WWW::Statistics->new(config => 't/data/21config00.ini') };
is($@,"Cannot load configuration file [t/data/21config00.ini]\n");

eval { CPAN::Testers::WWW::Statistics::Pages->new() };
is($@,"Must specify the parent statistics object\n");
eval { CPAN::Testers::WWW::Statistics::Graphs->new() };
is($@,"Must specify the parent statistics object\n");

