#!/usr/bin/perl
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01';

#----------------------------------------------------------------------------

=head1 NAME

updates.pl - template generator for the blog updates.

=head1 SYNOPSIS

  perl updates.pl

=head1 DESCRIPTION

The CPAN Testers Statistics site regular features monthly blog updates.
Previously these were added to the templates by hand and included in the code
tarball that was published on the site. However, as the data files are now
being released separately, this script allows the templates relating to the
blog updates to be generated once the latest data files have been updated.

=cut

# -------------------------------------
# Pre-Loading

BEGIN {
    my $syck_loaded = 0;
    eval {
        require YAML::Syck;
        eval "use YAML::Syck qw(Load LoadFile)";
        $syck_loaded = 1;
    };
    if(!$syck_loaded) {
        require YAML;
        eval "use YAML qw(Load LoadFile)";
    }
}

# -------------------------------------
# Library Modules

use Getopt::Long;
use HTML::Entities  qw(decode_entities encode_entities_numeric);
use Template;
use Time::Piece;

# -------------------------------------
# Variables

use constant TEMPLATES => './templates';
use constant UPDATES   => 'data/updates.yml';

my (%options);

# -------------------------------------
# Program

init_options();

my $content = LoadFile($options{updates});
make_file($content, 1,'updates-index.tt','updates-index.html');
make_file($content,-1,'updates-all.tt','updates-all.html');
make_file($content,10,'updates-rss.tt','rss-2.0.xml');

# -------------------------------------
# Subroutines

=head1 FUNCTIONS

=over 4

=item make_file

=cut

sub make_file {
    my ($yml,$cnt,$source,$target) = @_;
    my $src = "$options{templates}/$source";
    my $out = "$options{templates}/$target";
    unless(-f $src) {
        print STDERR "Cannot access file [$src]\n";
        return;
    }

    my @updates;
    for my $update (@{$content->{updates}}) {
        last    if($cnt == 0);
        $cnt--;

	    $update->{Content} =~ s/^\s*<\s+//s;
        if($target =~ /\.xml$/) {
            my $string = decode_entities( $update->{Content} );
            $update->{Content} = encode_entities_numeric( $string );
        }
        push @updates, $update;
    }

    #Wed, 20 Aug 2008 15:05:22 UT
    my $tp = localtime;
    my $builddate = sprintf "%s, %d %s %04d %02d:%02d:%02d UT",
        $tp->wdayname, $tp->mday, $tp->monname, $tp->year,
        $tp->hour, $tp->min, $tp->sec;

    my %vars = (
        updates     => \@updates,
        builddate   => $builddate,
    );

    my %config = (                              # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $options{templates},
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
        TRIM            => 1,
    );

    my $parser = Template->new(\%config);           # initialise parser
    $parser->process($src,\%vars,$out) # parse the template
        or die $parser->error();
}

=item init_options

Prepare command line options

=cut

sub init_options {
    GetOptions( \%options,
         'templates|t=s',
         'updates|u=s',
         'help|h',
         'version|V'
    );

    _help(1) if($options{help});
    _help(0) if($options{version});

    # use defaults if none provided
    $options{templates} ||= TEMPLATES;
    $options{updates}   ||= UPDATES;

    if($options{templates} && ! -d $options{templates}) {
        print "\nERROR: Given templates directory [$options{templates}] not valid, see help below.\n";
        _help(1);
    }

    if($options{updates} && ! -f $options{updates}) {
        print "\nERROR: Given updates data file [$options{updates}] not a valid file, see help below.\n";
        _help(1);
    }
}

sub _help {
    my $full = shift;

    if($full) {
        print "\n";
        print "Usage:$0 [--help|h] [--version|V] \\\n";
        print "         [--templates|t=<dir>] \\\n";
        print "         [--updates|u=<file>] \n\n";

#              12345678901234567890123456789012345678901234567890123456789012345678901234567890
        print "This program builds the CPAN Testers Statistics RSS feed and templates.\n";

        print "\nFunctional Options:\n";
        print "  [--templates=<dir>]        # path to templates directory\n";
        print "  [--updates=<file>]         # path/file to updates YAML file\n";

        print "\nOther Options:\n";
        print "  [--version]                # program version\n";
        print "  [--help]                   # this screen\n";

        print "\nFor further information type 'perldoc $0'\n";
    }

    print "$0 v$VERSION\n\n";
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

  Copyright (C) 2008 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

