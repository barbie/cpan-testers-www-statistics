package CPAN::Testers::WWW::Statistics::Database;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.55';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Database - DB handling code.

=head1 SYNOPSIS

  my $dbi = CPAN::Testers::WWW::Statistics::Database->new(database => $db);
  my @rows = $dbi->get_query($sql);
  $dbi->do_query($sql);

  my $iterator = $dbi->get_query_interator($sql);
  while(my $row = $iterator->()) {
    # do something
  }

=head1 DESCRIPTION

Database handling code for interacting with a local cpanstats database.

=cut

# -------------------------------------
# Library Modules

use DBI;

# -------------------------------------
# Variables

use constant    DATABASE    => 'cpanstats.db';

# -------------------------------------
# Routines

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

=back

=cut

sub new {
    my ($class,%hash) = @_;
    my $self = {};

    $self->{database} = $hash{database} || DATABASE;

    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$self->{database}",'','');
    $self->{dbh}->{AutoCommit} = 1;

    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    return      unless($self->{dbh});

    $self->{dbh}->disconnect;
}

=head2 Methods

=over 4

=item * do_query

An SQL wrapper method to perform a non-returning request.

=cut

sub do_query {
    my ($self,$sql) = @_;

    # prepare the sql statement for executing
    my $sth = $self->{dbh}->prepare($sql);
    print STDERR $self->{dbh}->errstr.":$sql\n"	unless($sth);

    # execute the SQL using any values sent to the function
    # to be placed in the sql
    if(!$sth->execute()) {
        print STDERR $sth->errstr,$sql
    }

    $sth->finish;
}

=item * get_query

An SQL wrapper method to perform a returning request.

=cut

sub get_query {
    my ($self,$sql) = @_;
    my @rows;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;
    while(my $row = $sth->fetchrow_arrayref) {
        push @rows, [@$row];
    }
    return @rows;
}

=item * get_query_iterator

An SQL wrapper method to perform a returning request, via an iterator.

=cut

sub get_query_iterator {
    my ($self,$sql) = @_;
    my @rows;
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;

    return sub { return $sth->fetchrow_arrayref }
}

q("Will code for Guinness!");

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
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

