#!/usr/bin/perl -w
use strict;
$|++;

my $VERSION = '0.04';

#----------------------------------------------------------------------------

=head1 NAME

cpanmail.cgi - script to access the NNTP server and retrieve a mail address.

=head1 SYNOPSIS

  perl cpanmail.cgi

=head1 DESCRIPTION

Using the CPAN Testers NNTP interface, retrieve the given article, and return
the email address in a non-spam form.

=cut

# -------------------------------------
# Library Modules


use CGI;
#use CGI::Carp qw(fatalsToBrowser);
use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use Email::Simple;
use Net::NNTP;
use Template;

# -------------------------------------
# Variables

my $LOG = 'logs/cpanstats.log';
my $CONFIG = './cpanmail.ini';

my %tvars;

# -------------------------------------
# Program

my $cgi = CGI->new();
$tvars{nntpid} = $cgi->param('nntpid');
$tvars{nntpid} =~ s/\D+//g  if($tvars{nntpid});

my $found = 0;
if($tvars{nntpid}) {
    if(-f $CONFIG) {
        $found = retrieve_from_db($tvars{nntpid});
    }

    if(!$found) {
        $found = retrieve_from_nntp($tvars{nntpid});
    }
} else {
    $found = 3;
}

$tvars{found} = $found;
write_results();

# -------------------------------------
# Subroutines

=item retrieve_from_db

Access the database and retrieve the required article data.

=cut

sub retrieve_from_db {
    my $id = shift;
    my $cfg;

    # load configuration file
    local $SIG{'__WARN__'} = \&_alarm_handler;
    eval { $cfg = Config::IniFiles->new( -file => $CONFIG ); };
    return 0    unless($cfg && !$@);

    # configure databases
    my $db = 'CPANSTATS';
    return 0    unless($cfg->SectionExists($db));
    my %opts = map {my $v = $cfg->val($db,$_); defined($v) ? ($_ => $v) : () }
                    qw(driver database dbfile dbhost dbport dbuser dbpass);
    my $dbh = CPAN::Testers::Common::DBUtils->new(%opts);
    return 0    unless($dbh);

    my @rows = $dbh->get_query('array',"SELECT * FROM cpanstats WHERE id=$id");
    return 0    unless(@rows);

    $tvars{subject} = sprintf "%s %s-%s %s %s", $rows[0]->[1], $rows[0]->[4], $rows[0]->[5], $rows[0]->[6], $rows[0]->[7];
    $tvars{from}    = $rows[0]->[3];

    return 1;
}

=item retrieve_from_nntp

Access the NNTP server and parse the required article.

=cut

sub retrieve_from_nntp {
    my $id = shift;

    my $nntp = Net::NNTP->new("nntp.perl.org")
        || return 9; #die "Cannot connect to nntp.perl.org";

    my($num, $first, $last) = $nntp->group("perl.cpan.testers");
    return 4    if($id < $first || $id > $last);

    my $article = join "", @{$nntp->article($id) || []};
    return 0    unless($article);   # no article for that id!

    my $mail = Email::Simple->new($article);
    return 0    unless $mail;

    $tvars{from}    = $mail->header("From");
    $tvars{subject} = $mail->header("Subject");

    return 1;
}

=item write_results

Outputs the results using Template Toolkit

=cut

sub write_results {
    # deter spammers
    if($tvars{from}) {
        $tvars{from} =~ s/\@/ at /g;
        $tvars{from} =~ s/\./ dot /g;
    }

    my %config = (								# provide config info
		RELATIVE		=> 1,
		ABSOLUTE		=> 1,
		INCLUDE_PATH	=> '..',
		INTERPOLATE		=> 0,
		POST_CHOMP		=> 1,
		TRIM			=> 1,
	);

    print $cgi->header;
	my $parser = Template->new(\%config);		# initialise parser
	$parser->process('response.html',\%tvars)	# parse the template
		or die $parser->error();
}

sub _alarm_handler () { return; }

__END__

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 SEE ALSO

L<Net::NNTP>.

F<http://stats.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut
