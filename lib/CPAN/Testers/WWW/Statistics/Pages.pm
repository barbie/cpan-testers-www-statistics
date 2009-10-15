package CPAN::Testers::WWW::Statistics::Pages;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.68';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Pages - CPAN Testers Statistics pages.

=head1 SYNOPSIS

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);
  my $ct = CPAN::Testers::WWW::Statistics::Pages->new(parent => $obj);
  $ct->create();

=head1 DESCRIPTION

Using the cpanstats database, this module extracts all the data and generates
all the HTML pages needed for the CPAN Testers Statistics website. In addition,
also generates the data files in order generate the graphs that appear on the
site.

Note that this package should not be called directly, but via its parent as:

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);
  $obj->make_pages();

=cut

# -------------------------------------
# Library Modules

use File::Basename;
use File::Copy;
use File::Path;
use HTML::Entities;
use IO::File;
use Sort::Versions;
use Template;
#use Time::HiRes qw ( time );

# -------------------------------------
# Variables

my ($known_s,$known_t) = (0,0);

my %month = (
    0 => 'January',   1 => 'February', 2 => 'March',     3 => 'April',
    4 => 'May',       5 => 'June',     6 => 'July',      7 => 'August',
    8 => 'September', 9 => 'October', 10 => 'November', 11 => 'December'
);

my ($LIMIT,%options,%pages);
my ($THISYEAR,$RUNDATE,$STATDATE,$THISDATE,$THATYEAR,$LASTDATE,$THATDATE);
my ($DATABASE2);

# -------------------------------------
# Subroutines

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

Page creation object. Allows the user to turn or off the progress tracking.

new() takes an option hash as an argument, which may contain 'progress => 1'
to turn on the progress tracker and/or 'database => $db' to indicate the path
to the database. If no database path is supplied, './cpanstats.db' is used.

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    die "Must specify the parent statistics object\n"   unless(defined $hash{parent});

    my $self = {parent => $hash{parent}};
    bless $self, $class;

    $self->_init_date();
    return $self;
}

=head2 Public Methods

=over 4

=item * create

Method to facilitate the creation of pages.

=back

=cut

sub create {
    my $self = shift;

    $self->{parent}->_log("start");
    $self->_write_basics();
    $self->_write_stats();
    $self->{parent}->_log("finish");
}

=head2 Private Methods

=over 4

=item * _write_basics

Write out basic pages, all of which are simply built from the templates,
without any data processing required.

=cut

sub _write_basics {
    my $self = shift;
    my $directory = $self->{parent}->directory;
    my $templates = $self->{parent}->templates;
    my $database  = $self->{parent}->database;
    my $results   = "$directory/stats";
    mkpath($results);

    $self->{parent}->_log("writing basic files");

    # calculate database metrics
    my $mtime = (stat($database))[9];
    my @ltime = localtime($mtime);
    $DATABASE2 = sprintf "%d%s %s %d", $ltime[3],_ext($ltime[3]),$month{$ltime[4]},$ltime[5]+1900;
    my $DATABASE1 = sprintf "%04d/%02d/%02d", $ltime[5]+1900,$ltime[4]+1,$ltime[3];
    my $DBSZ_UNCOMPRESSED = int((-s $database        ) / (1024 * 1024));
    my $DBSZ_COMPRESSED   = int((-s $database . '.gz') / (1024 * 1024));

    my $ranges1 = $self->{parent}->ranges('TEST_RANGES');
    my $ranges2 = $self->{parent}->ranges('CPAN_RANGES');

    # additional pages not requiring metrics
    my %pages = (
            index    => {THISDATE => $THISDATE, DATABASE => $DATABASE1,
                         DBSZ_COMPRESSED => $DBSZ_COMPRESSED, DBSZ_UNCOMPRESSED => $DBSZ_UNCOMPRESSED},
            cpanmail => {},
            response => {},
            perform  => {},
            graphs   => {},
            graphs1  => {RANGES => $ranges1, template=>'archive',PREFIX=>'stats1' ,TITLE=>'Monthly Report Counts'},
            graphs2  => {RANGES => $ranges1, template=>'archive',PREFIX=>'stats2' ,TITLE=>'Testers, Platforms and Perls'},
            graphs3  => {RANGES => $ranges1, template=>'archive',PREFIX=>'stats3' ,TITLE=>'Monthly Non-Passing Reports Counts'},
            graphs4  => {RANGES => $ranges1, template=>'archive',PREFIX=>'stats4' ,TITLE=>'Monthly Tester Fluctuations'},
            graphs6  => {RANGES => $ranges2, template=>'archive',PREFIX=>'stats6' ,TITLE=>'All Distribution Uploads per Month'},
            graphs12 => {RANGES => $ranges2, template=>'archive',PREFIX=>'stats12',TITLE=>'New Distribution Uploads per Month'}
    );

    $self->{parent}->_log("building support pages");
    $self->_writepage($_,$pages{$_})    for(keys %pages);

    # copy files
    $self->{parent}->_log("copying static files");
    my $tocopy = $self->{parent}->tocopy;
    foreach my $filename (@$tocopy) {
        my $src  = $templates . "/$filename";
        if(-f $src) {
            my $dest = $directory . "/$filename";
            mkpath( dirname($dest) );
            if(-d dirname($dest)) {
                copy( $src, $dest );
            } else {
                warn "Missing directory: $dest\n";
            }
        } else {
            warn "Missing file: $src\n";
        }
    }
}

=item * _write_stats

Extracts data, compiles the pages, generates the graph data files and
creates the HTML pages.

=cut

sub _write_stats {
    my $self = shift;
    my (%stats,%perls,%fails,%pass,%testers,%counts,%dists);

## BUILD INDEPENDENT STATS

    $self->_report_cpan();
    $self->_report_matrix();

## BUILD GENERAL STATS

    my ($stats,$fails,$pass,$counts,$dists,$index,$versions) = $self->_build_stats();

## BUILD STATS PAGES

    $self->_report_interesting($dists,$index);
    $self->_build_distro_matrix($pass,$versions);
    $self->_build_monthly_stats_files($stats,$counts);
    $self->_build_failure_rates($fails);
    $self->_build_monthly_stats($stats);
    $self->_build_performance_stats($index->{build});
}

sub _build_stats {
    my $self = shift;
    my (%stats,%perls,%fails,%pass,%testers,%counts,%dists);

    $self->{parent}->_log("building dist hash");

    my $iterator = $self->{parent}->{CPANSTATS}->iterator('hash',"SELECT dist,version FROM ixlatest");
    while(my $row = $iterator->()) {
        $dists{$row->{dist}}->{ALL} = 0;
        $dists{$row->{dist}}->{IXL} = 0;
        $dists{$row->{dist}}->{VER} = $row->{version};
    }

    $self->{parent}->_log("building stats hash");

    my %index = (
        count   => { posters => 0,  entries => 0,  reports => 0  },
        xrefs   => { posters => {}, entries => {}, reports => {} },
        xlast   => { posters => [], entries => [], reports => [] },
    );

    my $file = $self->{parent}->builder();
    if($file && -f $file) {
        if(my $fh = IO::File->new($file,'r')) {
            while(<$fh>) {
                my ($d,$r,$p) = /(\d+),(\d+),(\d+)/;
                next    unless($d);
                $index{build}{$d}->{webtotal}  = $r;
                $index{build}{$d}->{webunique} = $p;
            }
            $fh->close;
        }
    }

    $iterator = $self->{parent}->{CPANSTATS}->iterator('array',"SELECT * FROM cpanstats ORDER BY id");
    while(my $row = $iterator->()) {
        #insert_report($id,$state,$date,$from,$distvers,$platform);
        $row->[7] =~ s/\s.*//;  # only need to know the main release

        if($row->[1] eq 'cpan') {
            $stats{$row->[2]}->{pause}++;
            $stats{$row->[2]}->{uploads} ->{$row->[4]}
                                         ->{$row->[5]}++;
            $fails{$row->[4]}->{$row->[5]}->{post} = $row->[2];
        } else {
            my $name = $self->_tester_name($row->[3]);
            $stats{$row->[2]}->{reports}++;
            $stats{$row->[2]}->{state}   ->{$row->[1]}++;
            $stats{$row->[2]}->{tester}  ->{$name    }++;
            $stats{$row->[2]}->{dist}    ->{$row->[4]}++;
            $stats{$row->[2]}->{version} ->{$row->[5]}++;
            $stats{$row->[2]}->{platform}->{$row->[6]}++;
            $stats{$row->[2]}->{perl}    ->{$row->[7]}++;

            # check failure rates
            $fails{$row->[4]}->{$row->[5]}->{fail}++    if($row->[1] =~ /FAIL|UNKNOWN/i);
            $fails{$row->[4]}->{$row->[5]}->{pass}++    if($row->[1] =~ /PASS/i);
            $fails{$row->[4]}->{$row->[5]}->{total}++;

            # build latest pass matrix
            my $perl = $row->[7];
            $perl =~ s/\s.*//;  # only need to know the main release
            $perls{$perl} = 1;
            $pass{$row->[6]}->{$perl}->{$row->[4]} = 1;

            # record tester activity
            $testers{$name}->{first} ||= $row->[2];
            $testers{$name}->{last}    = $row->[2];
            $counts{$row->[2]}->{testers}{$name} = 1;

            if(defined $dists{$row->[4]}) {
                $dists{$row->[4]}->{ALL}++;
                $dists{$row->[4]}->{IXL}++  if($dists{$row->[4]}->{VER} eq $row->[5]);
            }

            my $day = substr($row->[10],0,8);
            $index{build}{$day}->{reports}++    if(defined $index{build}{$day});
        }

        my @row = (0, @$row);

        $index{count}->{posters} = $row[1];
        $index{count}->{entries}++;
        $index{count}->{reports}++  if($row[2] ne 'cpan');

        for my $type (qw(posters entries reports)) {
            next    if($type eq 'reports' && $row[2] eq 'cpan');
            if($index{count}->{$type} == 1 || ($index{count}->{$type} % 500000) == 0) {
                $index{xrefs}->{$type}->{$index{count}->{$type}} = \@row;
            } else {
                $index{xlast}->{$type} = \@row;
            }       
        }
    }

    for my $tester (keys %testers) {
        $counts{$testers{$tester}->{first}}->{first}++;
        $counts{$testers{$tester}->{last}}->{last}++;
    }

    my @versions = sort {versioncmp($b,$a)} keys %perls;

    $self->{parent}->_log("stats hash built");

    return (\%stats,\%fails,\%pass,\%counts,\%dists,\%index,\@versions);
}

=item * _report_matrix

Generates the report matrix page

=cut

sub _report_matrix {
    my $self = shift;
    my (%stats,%perls,%tvars);

    $self->{parent}->_log("building report matrix");

    # grab all records for the month
    #my @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT platform,perl FROM cpanstats WHERE postdate='$LASTDATE' AND state!='cpan'");
    my $iterator = $self->{parent}->{CPANSTATS}->iterator('array',"SELECT platform,perl,id FROM cpanstats WHERE postdate='$LASTDATE' AND state!='cpan'");
    while(my $row = $iterator->()) {
        $self->{parent}->_log("- id=$row->[2]");

    #for my $row (@rows) {
        # platform -> perl
        $row->[1] =~ s/\s.*//;  # only need to know the main release
        $stats{$row->[0]}->{$row->[1]}++;
        $perls{$row->[1]} = 1;
    }
    $self->{parent}->_log("- hash created");

    my @vers = sort {versioncmp($b,$a)} keys %perls;

    my $content = '<table class="matrix">';
    $content .= '<tr><th>Platform/Perl</th><th>' . join("</th><th>",@vers) . '</th></tr>';
    for my $platform (sort keys %stats) {
        $content .= '<tr><th>' . $platform . '</th>';
        for my $perl (@vers) {
            $content .= '<td class="'
                        . (defined $stats{$platform}->{$perl} ?
                            ($stats{$platform}->{$perl} > 50 ? 'lots' :
                              ($stats{$platform}->{$perl} >  0 ? 'some' : 'none')) : 'none')
                        . '">'
                        . ($stats{$platform}->{$perl} || '-')
                        . '</td>';
        }
        $content .= '</tr>';
    }
    $content .= '</table>';
    $self->{parent}->_log("- matrix created");

    $tvars{CONTENT} = $content;
    $self->_writepage('rmatrix',\%tvars);
}

=item * _report_interesting

Generates the interesting stats page

=cut

sub _report_interesting {
    my $self  = shift;
    my $dists = shift;
    my $index = shift;
    my %tvars;

    $self->{parent}->_log("building interesting page");

    my (@bydist,@byvers);
    my $inx = 20;
    for my $dist (sort {$dists->{$b}{ALL} <=> $dists->{$a}{ALL}} keys %$dists) {
        push @bydist, [$dists->{$dist}{ALL},$dist];
        last    if(--$inx <= 0);
    }
    $inx = 20;
    for my $dist (sort {$dists->{$b}{IXL} <=> $dists->{$a}{IXL}} keys %$dists) {
        push @byvers, [$dists->{$dist}{IXL},$dist,$dists->{$dist}{VER}];
        last    if(--$inx <= 0);
    }

    $tvars{BYDIST} = \@bydist;
    $tvars{BYVERS} = \@byvers;

    for my $type (qw(posters entries reports)) {
        $index->{xrefs}{$type}{$index->{count}{$type}} = $index->{xlast}{$type};

        for my $key (sort {$a <=> $b} keys %{ $index->{xrefs}{$type} }) {
            my @row = @{ $index->{xrefs}{$type}{$key} };

            $row[0] = $key;
            $row[2] = uc $row[2];
            $row[4] = $self->_tester_name($row[4])  if($row[4] && $row[4] =~ /\@/);
            push @{ $tvars{ uc($type) } }, \@row;
        }
    }

    my @headings = qw( count id grade postdate tester dist version platform perl osname osvers fulldate );
    $tvars{HEADINGS} = \@headings;
    $self->_writepage('interest',\%tvars);
}

=item * _report_cpan

Generates the statistic pages that relate specifically to CPAN.

=cut

sub _report_cpan {
    my $self = shift;
    my (%authors,%distros,%counts,%tvars);

    $self->{parent}->_log("building cpan trends page");

    my $next = $self->{parent}->{CPANSTATS}->iterator('hash',"SELECT * FROM uploads ORDER BY released");
    while(my $row = $next->()) {
        next    if($row->{dist} eq 'perl');

        my $date = _parsedate($row->{released});
        $authors{$row->{author}}{count}++;
        $distros{$row->{dist}}{count}++;
        $authors{$row->{author}}{dist}{$row->{dist}}++;
        $authors{$row->{author}}{dists}++   if($authors{$row->{author}}{dist}{$row->{dist}} == 1);

        $counts{$date}{authors}{$row->{author}}++;
        $counts{$date}{distros}{$row->{dist}}++;

        $counts{$date}{newauthors}++  if($authors{$row->{author}}{count} == 1);
        $counts{$date}{newdistros}++  if($distros{$row->{dist}}{count} == 1);
    }

    my $directory = $self->{parent}->directory;
    my $results   = "$directory/stats";
    mkpath($results);

    my $stat6  = IO::File->new("$results/stats6.txt",'w+')     or die "Cannot write to file [$results/stats6.txt]: $!\n";
    print $stat6 "#DATE,AUTHORS,DISTROS\n";
    my $stat12 = IO::File->new("$results/stats12.txt",'w+')    or die "Cannot write to file [$results/stats12.txt]: $!\n";
    print $stat12 "#DATE,AUTHORS,DISTROS\n";

    for my $date (sort keys %counts) {
        my $authors = scalar(keys %{ $counts{$date}{authors} });
        my $distros = scalar(keys %{ $counts{$date}{distros} });

        $counts{$date}{newauthors} ||= 0;
        $counts{$date}{newdistros} ||= 0;

        print $stat6  "$date,$authors,$distros\n";
        print $stat12 "$date,$counts{$date}{newauthors},$counts{$date}{newdistros}\n";

#        print $stat6  "$date,$authors\n";
#        print $stat7  "$date,$distros\n";
#        print $stat12 "$date,$counts{$date}{newauthors}\n";
#        print $stat13 "$date,$counts{$date}{newdistros}\n";
    }

    $stat6->close;
#    $stat7->close;
    $stat12->close;
#    $stat13->close;

    $self->_writepage('trends',\%tvars);


    $self->{parent}->_log("building cpan leader page");

    my $query = 'SELECT x.author,COUNT(x.dist) AS count FROM ixlatest AS x '.
                'INNER JOIN uploads AS u ON u.dist=x.dist AND u.version=x.version '.
		"WHERE u.type != 'backpan' GROUP BY x.author";
    my @latest = $self->{parent}->{CPANSTATS}->get_query('hash',$query);
    my (@allcurrent,@alluploads,@allrelease,@alldistros);
    my $inx = 1;
    for my $latest (sort {$b->{count} <=> $a->{count}} @latest) {
        push @allcurrent, {inx => $inx++, count => $latest->{count}, name => $latest->{author}};
        last    if($inx > 20);
    }

    $inx = 1;
    for my $author (sort {$authors{$b}{dists} <=> $authors{$a}{dists}} keys %authors) {
        push @alluploads, {inx => $inx++, count => $authors{$author}{dists}, name => $author};
        last    if($inx > 20);
    }

    $inx = 1;
    for my $author (sort {$authors{$b}{count} <=> $authors{$a}{count}} keys %authors) {
        push @allrelease, {inx => $inx++, count => $authors{$author}{count}, name => $author};
        last    if($inx > 20);
    }

    $inx = 1;
    for my $distro (sort {$distros{$b}{count} <=> $distros{$a}{count}} keys %distros) {
        push @alldistros, {inx => $inx++, count => $distros{$distro}{count}, name => $distro};
        last    if($inx > 20);
    }

    $tvars{allcurrent} = \@allcurrent;
    $tvars{alluploads} = \@alluploads;
    $tvars{allrelease} = \@allrelease;
    $tvars{alldistros} = \@alldistros;

    $self->_writepage('leadercpan',\%tvars);


    $self->{parent}->_log("building cpan interesting stats page");

    $tvars{authors}{total} = _count_mailrc();
    my @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT COUNT(distinct author) FROM uploads");
    $tvars{authors}{active}   = $rows[0]->[0];
    $tvars{authors}{inactive} = $tvars{authors}{total} - $rows[0]->[0];

    @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT COUNT(distinct dist) FROM uploads WHERE type != 'backpan'");
    $tvars{distros}{uploaded1} = $rows[0]->[0];
    @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT COUNT(distinct dist) FROM uploads");
    $tvars{distros}{uploaded2} = $rows[0]->[0];
    $tvars{distros}{uploaded3} = $tvars{distros}{uploaded2} - $tvars{distros}{uploaded1};

    @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT COUNT(*) FROM uploads WHERE type != 'backpan'");
    $tvars{distros}{uploaded4} = $rows[0]->[0];
    @rows = $self->{parent}->{CPANSTATS}->get_query('array',"SELECT COUNT(*) FROM uploads");
    $tvars{distros}{uploaded5} = $rows[0]->[0];
    $tvars{distros}{uploaded6} = $tvars{distros}{uploaded5} - $tvars{distros}{uploaded4};

    $self->_writepage('statscpan',\%tvars);
}

sub _build_distro_matrix {
    my $self = shift;
    my $pass = shift;
    my $vers = shift;
    my %tvars;

    $self->{parent}->_log("building distribution matrix");

    my $index = 0;
    my $content = '<table class="matrix">';
    $content .= '<tr><th>Platform/Perl</th><th>' . join("</th><th>",@$vers) . '</th></tr>';
    for my $platform (sort keys %$pass) {
        $content .= '<tr><th>' . $platform . '</th>';
        for my $perl (@$vers) {
            my $count = defined $pass->{$platform}{$perl}
                            ? scalar(keys %{$pass->{$platform}{$perl}})
                            : 0;
            if($count) {
                $index++;

                my @list = sort keys %{$pass->{$platform}{$perl}};
                $tvars{dists}     = \@list;
                $tvars{vplatform} = $platform;
                $tvars{vperl}     = $perl;
                $tvars{count}     = $count;
                $self->_writepage('matrix/list-'.$index,\%tvars);
                undef %tvars;
            }

            $content .= '<td class="'
                        . ($count > 50 ? 'lots' :
                          ($count >  0 ? 'some' : 'none'))
                        . '">'
                        . ($count ? qq|<a href="matrix/list-$index.html">$count</a>| : '-')
                        . '</td>';
        }
        $content .= '</tr>';
    }
    $content .= '</table>';

    $self->{parent}->_log("written $index list pages");

    $tvars{CONTENT} = $content;
    $self->_writepage('dmatrix',\%tvars);
}

sub _build_monthly_stats_files {
    my $self   = shift;
    my $stats  = shift;
    my $counts = shift;
    my %tvars;

    my $directory = $self->{parent}->directory;
    my $results   = "$directory/stats";
    mkpath($results);

    $self->{parent}->_log("building monthly stats for graphs - 1,3");

    #print "DATE,UPLOADS,REPORTS,NA,PASS,FAIL,UNKNOWN\n";
    my $fh = IO::File->new(">$results/stats1.txt");
    print $fh "#DATE,UPLOADS,REPORTS,PASS,FAIL\n";

    my $fh3 = IO::File->new(">$results/stats3.txt");
    print $fh3 "#DATE,FAIL,NA,UNKNOWN\n";
    
    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT);
        my @fields = (
            $date,
            ($stats->{$date}{pause}         || 0),
            ($stats->{$date}{reports}       || 0),
            ($stats->{$date}{state}{pass} || 0),
            ($stats->{$date}{state}{fail} || 0)
        );

        unshift @{$tvars{STATS}},
            [   @fields,
                $stats->{$date}{state}{na},
                $stats->{$date}{state}{unknown}];

        # graphs don't include current month
        next    if($date > $LIMIT-1);

        my $content = sprintf "%d,%d,%d,%d,%d\n", @fields;
        print $fh $content;

        $content = sprintf "%d,%d,%d,%d\n",
            $date,
            ($stats->{$date}{state}{fail}    || 0),
            ($stats->{$date}{state}{na}      || 0),
            ($stats->{$date}{state}{unknown} || 0);
        print $fh3 $content;
    }
    $fh->close;
    $fh3->close;

    $self->_writepage('mreports',\%tvars);

    $self->{parent}->_log("building monthly stats for graphs - 2");

    #print "DATE,TESTERS,PLATFORMS,PERLS\n";
    $fh = IO::File->new(">$results/stats2.txt");
    print $fh "#DATE,TESTERS,PLATFORMS,PERLS\n";

    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT-1);
        printf $fh "%d,%d,%d,%d\n",
            $date,
            scalar(keys %{$stats->{$date}{tester}}),
            scalar(keys %{$stats->{$date}{platform}}),
            scalar(keys %{$stats->{$date}{perl}});
    }
    $fh->close;

    $self->{parent}->_log("building monthly stats for graphs - 4");

    #print "DATE,ALL,FIRST,LAST\n";
    $fh = IO::File->new(">$results/stats4.txt");
    print $fh "#DATE,ALL,FIRST,LAST\n";

    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT-1);

        if(defined $counts->{$date}) {
            $counts->{$date}{all}     = scalar(keys %{$counts->{$date}{testers}});
        }
        $counts->{$date}{all}   ||= 0;
        $counts->{$date}{first} ||= 0;
        $counts->{$date}{last}  ||= 0;
        $counts->{$date}{last}    = ''  if($date > $THISDATE);

        printf $fh "%d,%s,%s,%s\n",
            $date,
            $counts->{$date}{all},
            $counts->{$date}{first},
            $counts->{$date}{last};
    }
    $fh->close;
}

sub _build_failure_rates {
    my $self  = shift;
    my $fails = shift;
    my %tvars;

    $self->{parent}->_log("building failure rates");

    # calculate worst failure rates - by failure count
    my %worst;
    for my $dist (keys %$fails) {
        my ($version) = sort {versioncmp($b,$a)} keys %{$fails->{$dist}};
        $worst{"$dist-$version"} = $fails->{$dist}{$version};
        $worst{"$dist-$version"}->{dist}   = $dist;
        $worst{"$dist-$version"}->{pcent}  = $fails->{$dist}{$version}{fail} ? int(($fails->{$dist}{$version}{fail}/$fails->{$dist}{$version}{total})*10000)/100 : 0.00;
        $worst{"$dist-$version"}->{pass} ||= 0;
        $worst{"$dist-$version"}->{fail} ||= 0;
    }
    my $count = 1;
    for my $dist (sort {$worst{$b}->{fail} <=> $worst{$a}->{fail} || $worst{$b}->{pcent} <=> $worst{$a}->{pcent}} keys %worst) {
        last unless($worst{$dist}->{fail});
        my $pcent = sprintf "%3.2f%%", $worst{$dist}->{pcent};
        push @{$tvars{WORST}}, [$count++, $worst{$dist}->{fail}, $dist, $worst{$dist}->{post}, $worst{$dist}->{pass}, $worst{$dist}->{total}, $pcent, $worst{$dist}->{dist}];
        last    if($count > 100);
    }

    $tvars{DATABASE} = $DATABASE2;
    $self->_writepage('wdists',\%tvars);
    undef %tvars;

    # calculate worst failure rates - by percentage
    $count = 1;
    for my $dist (sort {$worst{$b}->{pcent} <=> $worst{$a}->{pcent} || $worst{$b}->{fail} <=> $worst{$a}->{fail}} keys %worst) {
        last unless($worst{$dist}->{fail});
        my $pcent = sprintf "%3.2f%%", $worst{$dist}->{pcent};
        push @{$tvars{WORST}}, [$count++, $worst{$dist}->{fail}, $dist, $worst{$dist}->{post}, $worst{$dist}->{pass}, $worst{$dist}->{total}, $pcent, $worst{$dist}->{dist}];
        last    if($count > 100);
    }

    $tvars{DATABASE} = $DATABASE2;
    $self->_writepage('wpcent',\%tvars);
    undef %tvars;
}

sub _build_monthly_stats {
    my $self  = shift;
    my $stats = shift;
    my %tvars;

    $self->{parent}->_log("building monthly tables");

    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $platform (sort {$stats->{$date}{platform}{$b} <=> $stats->{$date}{platform}{$a}} keys %{$stats->{$date}{platform}}) {
            $content .= ', '    if($content);
            $content .= "[$stats->{$date}{platform}{$platform}] $platform";
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mplatforms',\%tvars);
    undef %tvars;

    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $perl (sort {$stats->{$date}{perl}{$b} <=> $stats->{$date}{perl}{$a}} keys %{$stats->{$date}{perl}}) {
            $content .= ', '    if($content);
            $content .= "[$stats->{$date}{perl}{$perl}] $perl";
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mperls',\%tvars);
    undef %tvars;

    my %testers;
    for my $date (sort keys %$stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $tester (sort {$stats->{$date}{tester}{$b} <=> $stats->{$date}{tester}{$a}} keys %{$stats->{$date}{tester}}) {
            $content .= ', '    if($content);
            $content .= "[$stats->{$date}{tester}{$tester}] $tester";
            $testers{$tester} += $stats->{$date}{tester}{$tester};
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mtesters',\%tvars);
    undef %tvars;

    $self->{parent}->_log("building leader board");

    my $count = 1;
    for my $tester (sort {$testers{$b} <=> $testers{$a}} keys %testers) {
        push @{$tvars{STATS}}, [$count++, $testers{$tester}, $tester];
    }

    $count--;
    print "Unknown Addresses: ".($count-$known_t)."\n";
    print "Known Addresses:   ".($known_s)."\n";
    print "Listed Addresses:  ".($known_s+$count-$known_t)."\n";
    print "\n";
    print "Unknown Testers:   ".($count-$known_t)."\n";
    print "Known Testers:     ".($known_t)."\n";
    print "Listed Testers:    ".($count)."\n";

    push @{$tvars{COUNTS}}, ($count-$known_t),$known_s,($known_s+$count-$known_t),($count-$known_t),$known_t,$count;

    $self->_writepage('testers',\%tvars);
}

sub _build_performance_stats {
    my $self  = shift;
    my $index = shift;

    my $directory = $self->{parent}->directory;
    my $results   = "$directory/stats";
    mkpath($results);

    $self->{parent}->_log("building peformance stats for graphs");

    my $fh = IO::File->new(">$results/build1.txt");
    print $fh "#DATE,REQUESTS,PAGES,REPORTS\n";

    for my $date (sort {$a <=> $b} keys %$index) {
        #next    if($date > $LIMIT-1);

        printf $fh "%d,%d,%d,%d\n",
            $date,
            ($index->{$date}{webtotal}  || 0),
            ($index->{$date}{webunique} || 0),
            ($index->{$date}{reports}   || 0);
    }
    $fh->close;
}


=item * _writepage

Creates a single HTML page.

=cut

sub _writepage {
    my ($self,$page,$vars) = @_;
    my $directory = $self->{parent}->directory;
    my $templates = $self->{parent}->templates;

   $self->{parent}->_log("_writepage: page=$page");

    my $template = $vars->{template} || $page;
    $template = 'distlist'    if($page =~ m!^matrix/list-!);

    my $layout = "layout.html";
    my $source = "$template.html";
    my $target = "$directory/$page.html";
    mkdir(dirname($target));

   $self->{parent}->_log("_writepage: layout=$layout, source=$source, target=$target");

    $vars->{SOURCE}    = $source;
    $vars->{VERSION}   = $VERSION;
    $vars->{RUNDATE}   = $RUNDATE;
    $vars->{STATDATE}  = $STATDATE;
    $vars->{THATDATE}  = $THATDATE;
    $vars->{copyright} = $self->{parent}->copyright;

#    if($page =~ /^list-/) {
#        use Data::Dumper;
#        print STDERR "$page:" . Dumper($pages{$page});
#    }

    my %config = (                          # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $templates,
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
        TRIM            => 1,
    );

    my $parser = Template->new(\%config);   # initialise parser
    $parser->process($layout,$vars,$target) # parse the template
        or die $parser->error() . "\n";
}

=item * _init_date

Prime all key date variable.

=cut

sub _init_date {
    my $self = shift;
    $self->{parent}->_log("init");

    my @datetime = localtime;
    $THISYEAR = ($datetime[5] +1900);
    $RUNDATE  = sprintf "%d%s %s %d",
                        $datetime[3], _ext($datetime[3]),
                        $month{$datetime[4]}, $THISYEAR;

    # LIMIT is the last date for all data
    $LIMIT    = ($THISYEAR) * 100 + $datetime[4] + 1;
    if($datetime[4] == 0) {
        $datetime[4] = 11;
        $THISYEAR--;
    }

    # STATDATE/THISDATE is the Month/Year stats are run for
    $STATDATE = sprintf "%s %d", $month{int($datetime[4])}, $THISYEAR;
    $THISDATE = sprintf "%04d%02d", $THISYEAR, int($datetime[4]);

    # LASTDATE/THATDATE is the previous Month/Year for a full matrix
    $datetime[4]--;
    $THATYEAR = $THISYEAR;
    if($datetime[4] == 0) {
        $datetime[4] = 11;
        $THATYEAR--;
    }
    $LASTDATE = sprintf "%04d%02d", $THATYEAR, int($datetime[4]);
    $THATDATE = sprintf "%s %d", $month{int($datetime[4])}, $THATYEAR;

    #print STDERR "THISYEAR=[$THISYEAR]\n";
    #print STDERR "LIMIT=[$LIMIT]\n";
    #print STDERR "STATDATE=[$STATDATE]\n";
    #print STDERR "RUNDATE=[$RUNDATE]\n";
}

=item * _tester_name

Returns either the known name of the tester for the given email address, or
returns a doctored version of the address for displaying in HTML.

=cut

my $address;
sub _tester_name {
    my ($self,$name) = @_;

    $address ||= do {
        my (%address_map,%known);
        my $address = $self->{parent}->address;

        my $fh = IO::File->new($address)    or die "Cannot open address file [$address]: $!";
        while(<$fh>) {
            chomp;
            my ($source,$target) = (/(.*),(.*)/);
            next    unless($source && $target);
            $address_map{$source} = $target;
            $known{$target}++;
        }
        $fh->close;
        $known_t = scalar(keys %known);
        $known_s = scalar(keys %address_map);
        \%address_map;
    };

    my $addr = ($address->{$name} && $address->{$name} =~ /\&\#x?\d+\;/)
                ? $address->{$name}
                : encode_entities( ($address->{$name} || $name) );
    $addr =~ s/\./ /g if($addr =~ /\@/);
    $addr =~ s/\@/ \+ /g;
    $addr =~ s/</&lt;/g;
    return $addr;
}

=item * _ext

Provides the ordinal for dates.

=cut

sub _ext {
    my $num = shift;
    return 'st' if($num == 1 || $num == 21 || $num == 31);
    return 'nd' if($num == 2 || $num == 22);
    return 'rd' if($num == 3 || $num == 23);
    return 'th';
}

sub _parsedate {
    my $time = shift;
    my @time = localtime($time);
    return sprintf "%04d%02d", $time[5]+1900,$time[4]+1;
}

sub _count_mailrc {
    my $count = 0;

    my $fh  = IO::File->new('data/01mailrc.txt','r')     or die "Cannot read file [data/01mailrc.txt]: $!\n";
    while(<$fh>) {
        last	if(/^alias\s*DBIML/);
        $count++;
    }
    $fh->close;

    return $count;
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

L<CPAN::Testers::Data::Generator>,
L<CPAN::WWW::Testers>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2005-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

