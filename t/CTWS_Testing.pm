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
  find({ wanted => sub { push @files, File::Spec->abs2rel($File::Find::name,$dir) if -f $_ } }, $dir)
      if(-d $dir);
  return sort @files;
}

sub saveFiles {
    my $dir = shift;

    mkpath("$dir/stats");

    my $fh = IO::File->new("$dir/stats/build1.txt",'w+');
    print $fh "#DATE,REQUESTS,PAGES,REPORTS\n20090715,32167,4304,21943\n20090716,43144,6573,16277\n20090717,37462,5942,21923\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats1.txt",'w+');
    print $fh "#DATE,UPLOADS,REPORTS,PASS,FAIL\n200810,2,0,0,0\n200811,3,4,0,4\n200812,1,2,2,0\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats2.txt",'w+');
    print $fh "#DATE,TESTERS,PLATFORMS,PERLS\n200810,0,0,0\n200811,3,4,2\n200812,2,1,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats3.txt",'w+');
    print $fh "#DATE,FAIL,NA,UNKNOWN\n200810,0,0,0\n200811,4,0,0\n200812,0,0,0\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats4.txt",'w+');
    print $fh "#DATE,ALL,FIRST,LAST\n200810,0,0,0\n200811,3,2,3\n200812,2,2,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats6.txt",'w+');
    print $fh "#DATE,AUTHORS,DISTROS\n200810,2,2\n200811,3,3\n200812,1,1\n";
    $fh->close;

    $fh = IO::File->new("$dir/stats/stats12.txt",'w+');
    print $fh "#DATE,AUTHORS,DISTROS\n200810,0,0\n200811,1,1\n200812,0,0\n";
    $fh->close;
}

1;

__DATA__

[MASTER]
database=t/_DBDIR/test.db
address=t/data/addresses.txt
templates=templates

[CPANSTATS]
driver=SQLite
database=t/_DBDIR/test.db

[TOCOPY]
LIST=<<HERE
cgi-bin/cpanmail.cgi
favicon.ico
HERE

[TEST_RANGES]
LIST=<<HERE
199901-200412
200301-200712
200601-200912
HERE

[CPAN_RANGES]
LIST=<<HERE
199901-200412
200301-200712
200601-200912
HERE
