#!/usr/bin/perl -w
use strict;

my $VERSION = '0.12';

#http://www.eurodns.com/search/index.php

#----------------------------------------------------------------------------

=head1 NAME

addresses.pl - helper script to map tester addresses to real people.

=head1 SYNOPSIS

  perl addresses.pl
        --database|d=<file> \
        --address|a=<file>  \
        --mailrc|m=<file>   \
        [--month=<string>] [--match] [--sort]

=head1 DESCRIPTION

Using the cpanstats database, the latest 01mailrc.txt file and the addresses
file, the script tries to match unmatched tester addresses to either a cpan
author or an already known tester.

For the remaining addresses, an attempt at pattern matching is made to try and
identify similar addresses in the hope they can be manually identified.

=cut

# -------------------------------------
# Library Modules

use lib qw(./lib ../lib);

use DBI;
use IO::File;
use Getopt::ArgvFile default=>1;
use Getopt::Long;

use CPAN::Testers::WWW::Statistics::Database;

# -------------------------------------
# Variables

use constant DATABASE => './cpanstats.db';
use constant ADDRESS  => 'data/addresses.txt';
use constant MAILRC   => 'data/01mailrc.txt';
use constant MONTH    => 199000;

my (%parsed_map,%cpan_map,%pause_map,%unparsed_map,%address_map,%domain_map);
my (%result,%options);
my $parsed = 0;

# -------------------------------------
# Program

##### INITIALISE #####

init_options();
my $dbi = CPAN::Testers::WWW::Statistics::Database->new(database => $options{database});


##### MAIN #####

load_addresses();
match_addresses();
print_addresses();

# -------------------------------------
# Subroutines

=head1 FUNCTIONS

=over 4

=item load_addresses

Loads all the data files with addresses against we can match, then load all
the addresses listed in the DB that we need to match against.

=cut

sub load_addresses {
    my $fh = IO::File->new($options{address})    or die "Cannot open address file [$options{address}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($source,$target) = (/(.*),(.*)/);
        next    unless($source && $target);
        $parsed_map{$source} = $target;
        my ($email) = $source =~ /([-+=\w]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|[a-z]{2,2}))/i;
        next    unless($email);
        $email = lc($email);
        my ($local,$domain) = split(/\@/,$email);
        $address_map{$email} = $target;
        $domain_map{$domain} = $target;
#print STDERR "$source => $local => $domain\n"   unless($domain);

    }
    $fh->close;

#    use Data::Dumper;
#    print STDERR Dumper(\%domain_map);

    $fh = IO::File->new($options{mailrc})    or die "Cannot open mailrc file [$options{mailrc}]: $!";
    while(<$fh>) {
        s/\s+$//;
        next    if(/^$/);

        my ($alias,$name,$email) = (/alias\s+([A-Z]+)\s+"([^<]+) <([^>]+)>"/);
        next    unless($alias);
        $pause_map{lc($alias)} = "$name ($alias)";
        $cpan_map{lc($email)} = "$name ($alias)";
    }
    $fh->close;

    # grab all records for the month
    my $sql = $options{month}
        ? "SELECT tester UNIQ FROM cpanstats WHERE postdate >= '$options{month}' AND state IN ('pass','fail','na','unknown')"
        : "SELECT tester UNIQ FROM cpanstats WHERE state IN ('pass','fail','na','unknown')";
    my @rows = $dbi->get_query($sql);
    for my $row (@rows) {
        $parsed++;
        next    if($parsed_map{$row->[0]});
        $unparsed_map{$row->[0]} = "";
    }
}

sub match_addresses {
    for my $key (keys %unparsed_map) {
        my ($email) = $key =~ /([-+=\w]+\@(?:[-\w]+\.)+(?:com|net|org|info|biz|edu|museum|mil|gov|[a-z]{2,2}))/i;
        unless($email) {
            push @{$result{NOEMAIL}}, $key;
            next;
        }
        $email = lc($email);
        my ($local,$domain) = split(/\@/,$email);
#print STDERR "email=[$email], local=[$local], domain=[$domain]\n"  if($email =~ /indiana/);
        next    if(map_pause($key,$local,$domain,$email));
        next    if(map_address($key,$local,$domain,$email));
        next    if(map_cpan($key,$local,$domain,$email));

        my @parts = split(/\./,$domain);
        while(@parts > 1) {
            my $domain2 = join(".",@parts);
#print STDERR "domain2=[$domain2]\n"  if($email =~ /indiana/);
            last    if(map_domain($key,$local,$domain2,$email));
            shift @parts;
        }
    }
}

sub print_addresses {
    if($result{NOMAIL}) {
        print "ERRORS:\n";
        for my $email (sort @{$result{NOMAIL}}) {
            print "NOMAIL: $email\n";
        }
    }

    print "\nMATCH:\n";
    for my $key (sort {$unparsed_map{$a} cmp $unparsed_map{$b}} keys %unparsed_map) {
        if($unparsed_map{$key}) {
            print "$key,$unparsed_map{$key}\n";
            delete $unparsed_map{$key};
        }
    }

    print "\n";
    return  if($options{match});

    my @mails;
    print "PATTERNS:\n";
    for my $key (sort {$unparsed_map{$a} cmp $unparsed_map{$b}} keys %unparsed_map) {
        next    unless($key);

        my ($local,$domain) = $key =~ /([-+=\w]+)\@([^\s]+)/;
        if($domain) {
            my @parts = split(/\./,$domain);
            push @mails, [join(".",reverse @parts) . '@' . $local , $key];
        } else {
            print STDERR "FAIL: $key\n";
        }
    }
    for my $email (sort {$a->[0] cmp $b->[0]} @mails) {
        if($options{'sort'}) {
            print "$email->[1],\n";
        } else {
            print "$email->[0]\t$email->[1],\n";
        }
    }

    print "\nArticles parsed = $parsed\n\n";
}

sub map_pause {
    my ($key,$local,$domain,$email) = @_;

    if($domain eq 'cpan.org') {
        $unparsed_map{$key} = $pause_map{$local} . ' #[PAUSE]';
        return 1;
    }
    return 0;
}

sub map_address {
    my ($key,$local,$domain,$email) = @_;

    if($address_map{$email}) {
        $unparsed_map{$key} = $address_map{$email} . ' #[ADDRESS]';
        return 1;
    }
    return 0;
}

sub map_cpan {
    my ($key,$local,$domain,$email) = @_;

    if($cpan_map{$email}) {
        $unparsed_map{$key} = $cpan_map{$email} . ' #[CPAN]';
        return 1;
    }
    return 0;
}

sub map_domain {
    my ($key,$local,$domain,$email) = @_;

    return 0    if( $domain eq 'us.ibm.com'     ||
                    $domain eq 'aacom.fr'       ||
                    $domain eq 'free.fr'        ||
                    $domain eq 'web.de'         ||
                    $domain eq 'xs4all.nl'      ||
                    $domain eq 'demon.nl'       ||
                    $domain eq 'shaw.ca'        ||
                    $domain eq 'mail.ru'        ||
                    $domain eq 'gmx.de'         ||
                    $domain eq 'ath.cx'         ||
                    $domain eq 'nih.gov'        ||
                    $domain eq 'rambler.ru'     ||

                    $domain =~ /^(ieee|no-ip|dyndns|cpan|perl)\.org$/                               ||
                    $domain =~ /^(verizon|gmx|comcast|earthlink|cox)\.net$/                         ||
                    $domain =~ /^(yahoo|google|gmail|mac|pair|rr|sun|aol|pobox|hotmail|ibm)\.com$/  ||

                    $domain =~ /^(net|org|com)\.(br|au|tw)$/        ||
                    $domain =~ /^(co|org)\.uk$/                     ||
                    $domain =~ /\b(edu|(ac|edu)\.(uk|jp|at|tw))$/             # education establishments
                );

#print STDERR "domain=[$domain]\n"   if($domain =~ /istic.org/);

    if($domain_map{$domain}) {
        $unparsed_map{$key} = $domain_map{$domain} . " #[DOMAIN] - $domain";
        return 1;
    }
    for my $map (keys %domain_map) {
        if($map =~ /\b$domain$/) {
            $unparsed_map{$key} = $domain_map{$map} . " #[DOMAIN] - $domain - $map";
            return 1;
        }
    }
    return 0;
}

=item init_options

Prepare command line options

=cut

sub init_options {
    GetOptions( \%options,
        'database|d=s',
        'address|a=s',
        'mailrc|m=s',
        'month=s',
        'match',
        'sort',
        'help|h',
        'version|v'
    );

    _help(1) if($options{help});
    _help(0) if($options{version});

    # use defaults if none provided
    $options{database} ||= DATABASE;
    $options{address}  ||= ADDRESS;
    $options{mailrc}   ||= MAILRC;
    $options{month}    ||= MONTH;
    $options{match}    ||= 0;
    $options{'sort'}   ||= 0;

    for my $opt (qw(database address mailrc)) {
        _help(1,"No $opt option given, see help below.")                                unless(   $options{$opt});
        _help(1,"Given $opt file [$options{$opt}] not a valid file, see help below.")   unless(-f $options{$opt});
    }
}

sub _help {
    my ($full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print "\n";
        print "Usage:$0 [--help|h] [--version|v] \\\n";
        print "         [--database|d=<file>] \\\n";
        print "         [--address|a=<file>] \\\n";
        print "         [--mailrc|m=<file>] \\\n";
        print "         [--month=<string>] \\\n";
        print "         [--match] \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program builds the CPAN Testers Statistics website.\n";

        print "\nFunctional Options:\n";
        print "  [--database=<file>]        # path/file to database\n";
        print "  [--address=<file>]         # path/file to addresses file\n";
        print "  [--mailrc=<file>]          # path/file to mailrc file\n";
        print "  [--month=<string>]         # YYYYMM string to match from\n";
        print "  [--match]                  # display matches only\n";

        print "\nOther Options:\n";
        print "  [--version]                # program version\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n";
    exit(0);
}

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Statistics

=head1 SEE ALSO

L<CPAN::WWW::Testers::Generator>,
L<CPAN::WWW::Testers>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2008 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

