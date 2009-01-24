package CTWS_Testing;

use strict;
use warnings;

use CPAN::Testers::WWW::Statistics;
use CPAN::Testers::WWW::Statistics::Pages;
use CPAN::Testers::WWW::Statistics::Graphs;

use File::Path;
use File::Temp;
use File::Find;
use File::Spec;

my $parent;

sub getObj {
    my %opts = @_;
    $opts{directory} ||= File::Spec->catfile('t','_TMPDIR');
    $opts{config}    ||= \*DATA;

    _cleanDir( $opts{directory} ) or return;

    eval { $parent = CPAN::Testers::WWW::Statistics->new(%opts); };
    return $parent;
}

sub getPages {
    my $obj = CPAN::Testers::WWW::Statistics::Pages->new(parent => $parent);
    return $obj;
}

sub getGraphs {
    my $obj = CPAN::Testers::WWW::Statistics::Graphs->new(parent => $parent);
    return $obj;
}

sub _cleanDir {
  my $dir = shift;
  if( -d $dir ){ rmtree($dir) or return; }
  mkpath($dir) or return;
  return 1;
}

sub cleanDir {
  my $obj = shift;
  return _cleanDir( $obj->directory );
}

sub whackDir {
  my $obj = shift;
  my $dir = $obj->directory;
  if( -d $dir ){ rmtree($dir) or return; }
  return 1;
}

sub listFiles {
  my $dir = shift;
  my @files;
  find({ wanted => sub { push @files, File::Spec->abs2rel($File::Find::name,$dir) if -f $_ } }, $dir);
  return sort @files;
}

1;

__DATA__

[MASTER]
database=t/_DBDIR/test.db
address=data/addresses.txt
templates=templates

[CPANSTATS]
driver=SQLite
database=t/_DBDIR/test.db

[UPLOADS]
driver=SQLite
database=t/_DBDIR/test2.db

