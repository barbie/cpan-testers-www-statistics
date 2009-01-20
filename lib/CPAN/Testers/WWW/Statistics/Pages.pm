package CPAN::Testers::WWW::Statistics::Pages;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.55';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Pages - CPAN Testers Statistics pages.

=head1 SYNOPSIS

  my $ct = CPAN::Testers::WWW::Statistics::Pages->new(progress => 1);
  $ct->create();

=head1 DESCRIPTION

Using the cpanstats database, this module extracts all the data and generates
all the HTML pages needed for the CPAN Testers Statistics website. In addition,
also generates the data files in order generate the graphs that appear on the
site.

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

use CPAN::Testers::WWW::Statistics::Database;

# -------------------------------------
# Variables

use constant DATABASE => './cpanstats.db';
use constant ADDRESS  => 'data/addresses.txt';

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
    my ($class,%hash) = @_;
    my $self = {};

    $self->{templates} = $hash{templates} || './templates';
    $self->{directory} = $hash{directory} || './html';
    $self->{progress}  = $hash{progress}  || 0;
    $self->{database}  = $hash{database}  || DATABASE;
    $self->{address}   = $hash{address}   || ADDRESS;

    bless $self, $class;

    return unless(-f $self->{database});
    return $self;
}

=head2 Public Methods

=over 4

=item * create

Method to facilitate the creation of pages.

=cut

sub create {
    my $self = shift;

    _progress("init") if($self->{progress});
    _init_date();

    $self->{dbh} = CPAN::Testers::WWW::Statistics::Database->new(database => $self->{database});

    _progress("start") if($self->{progress});
    $self->_write_basics();
    $self->_write_stats();
    _progress("finish") if($self->{progress});
}

=back

=head2 Private Methods

=over 4

=item * _write_basics

Write out basic pages, all of which are simply built from the templates,
without any data processing required.

=cut

sub _write_basics {
    my $self = shift;

    mkpath($self->{directory});

    # calculate database metrics
    my $mtime = (stat($self->{database}))[9];
    my @ltime = localtime($mtime);
    $DATABASE2 = sprintf "%d%s %s %d", $ltime[3],_ext($ltime[3]),$month{$ltime[4]},$ltime[5]+1900;
    my $DATABASE1 = sprintf "%04d/%02d/%02d", $ltime[5]+1900,$ltime[4]+1,$ltime[3];
    my $DBSZ_UNCOMPRESSED = int((-s $self->{database}        ) / (1024 * 1024));
    my $DBSZ_COMPRESSED   = int((-s $self->{database} . '.gz') / (1024 * 1024));

    # additional pages not requiring metrics
    my %pages = (
            index    => {THISDATE => $THISDATE, DATABASE => $DATABASE1,
                         DBSZ_COMPRESSED => $DBSZ_COMPRESSED, DBSZ_UNCOMPRESSED => $DBSZ_UNCOMPRESSED},
            updates  => {},
            cpanmail => {},
            response => {},
            graphs   => {});

    _progress("building support pages") if($self->{progress});
    $self->_writepage($_,$pages{$_})    for(keys %pages);

    # copy files
    foreach my $filename (
        'rss-2.0.xml',
        'cgi-bin/cpanmail.cgi',
        'favicon.ico',
        'style.css',
        map {'images/'.basename($_)} glob($self->{templates} . '/images/*'),
        )
    {
        my $src  = "$self->{templates}/$filename";
        my $dest = "$self->{directory}/$filename";
        mkpath( dirname($dest) );
        copy( $src, $dest );
    }
}

=item * _write_stats

Extracts data, compiles the pages, generates the graph data files and
creates the HTML pages.

=cut

sub _write_stats {
    my $self = shift;
    my (%stats,%perls,%fails,%pass,%tvars);

    _progress("building report matrix") if($self->{progress});

    $self->_report_matrix();
    $self->_report_interesting();

## BUILD GENERAL STATS

    _progress("building stats hash") if($self->{progress});

    my $iterator = $self->{dbh}->get_query_iterator("SELECT * FROM cpanstats");
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
        }
    }

    my @versions = sort {versioncmp($b,$a)} keys %perls;

    _progress("stats hash built") if($self->{progress});

## GENERATE DISTRIBUTION MATRIX

    _progress("building distribution matrix") if($self->{progress});

    my $index = 0;
    my $content = '<table class="matrix">';
    $content .= '<tr><th>Platform/Perl</th><th>' . join("</th><th>",@versions) . '</th></tr>';
    for my $platform (sort keys %pass) {
        $content .= '<tr><th>' . $platform . '</th>';
        for my $perl (@versions) {
            my $count = defined $pass{$platform}->{$perl}
                            ? scalar(keys %{$pass{$platform}->{$perl}})
                            : 0;
            if($count) {
                $index++;

                my @list = sort keys %{$pass{$platform}->{$perl}};
                $tvars{dists}     = \@list;
                $tvars{vplatform} = $platform;
                $tvars{vperl}     = $perl;
                $tvars{count}     = $count;
                $self->_writepage('list-'.$index,\%tvars);
                undef %tvars;
            }

            $content .= '<td class="'
                        . ($count > 50 ? 'lots' :
                          ($count >  0 ? 'some' : 'none'))
                        . '">'
                        . ($count ? qq|<a href="list-$index.html">$count</a>| : '-')
                        . '</td>';
        }
        $content .= '</tr>';
    }
    $content .= '</table>';

    _progress("written $index list pages") if($self->{progress});

    $tvars{CONTENT} = $content;
    $self->_writepage('dmatrix',\%tvars);
    undef %tvars;

## GENERATE MONTHLY REPORT STAT GRAPHS & TABLE

    _progress("building monthly stats for graphs") if($self->{progress});

    #print "DATE,UPLOADS,REPORTS,NA,PASS,FAIL,UNKNOWN\n";
    my $fh = IO::File->new(">stats1.txt");
    my $fh3 = IO::File->new(">stats3.txt");
    for my $date (sort keys %stats) {
        next    if($date > $LIMIT);
        my @fields = (
            $date,
            $stats{$date}->{pause},
            $stats{$date}->{reports},
            $stats{$date}->{state}->{pass},
            $stats{$date}->{state}->{fail}
        );

        unshift @{$tvars{STATS}},
            [   @fields,
                $stats{$date}->{state}->{na},
                $stats{$date}->{state}->{unknown}];

        # graphs don't include current month
        next    if($date > $LIMIT-1);

        my $content = sprintf "%d,%d,%d,%d,%d\n", @fields;
        print $fh $content;

        $content = sprintf "%d,%d,%d,%d\n",
            $date,
            ($stats{$date}->{state}->{fail}    || 0),
            ($stats{$date}->{state}->{na}      || 0),
            ($stats{$date}->{state}->{unknown} || 0);
        print $fh3 $content;
    }
    $fh->close;
    $fh3->close;

    $self->_writepage('mreports',\%tvars);
    undef %tvars;

## GENERATE MONTHLY REPORT STAT GRAPHS

    #print "DATE,TESTERS,PLATFORMS,PERLS\n";
    $fh = IO::File->new(">stats2.txt");
    for my $date (sort keys %stats) {
        next    if($date > $LIMIT-1);
        printf $fh "%d,%d,%d,%d\n",
            $date,
            scalar(keys %{$stats{$date}->{tester}}),
            scalar(keys %{$stats{$date}->{platform}}),
            scalar(keys %{$stats{$date}->{perl}});
    }
    $fh->close;

## GENERATE FAILURE RATE TABLES

    _progress("building failure rates") if($self->{progress});

    # calculate worst failure rates - by failure count
    my %worst;
    for my $dist (keys %fails) {
        my ($version) = sort {versioncmp($b,$a)} keys %{$fails{$dist}};
        $worst{"$dist-$version"} = $fails{$dist}->{$version};
        $worst{"$dist-$version"}->{dist}   = $dist;
        $worst{"$dist-$version"}->{pcent}  = $fails{$dist}->{$version}->{fail} ? int(($fails{$dist}->{$version}->{fail}/$fails{$dist}->{$version}->{total})*10000)/100 : 0.00;
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

## GENERATE MONTHLY TESTERS / PLATFORM / PERL REPORT TABLES

    _progress("building monthly tables") if($self->{progress});

    for my $date (sort keys %stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $platform (sort {$stats{$date}->{platform}->{$b} <=> $stats{$date}->{platform}->{$a}} keys %{$stats{$date}->{platform}}) {
            $content .= ', '    if($content);
            $content .= "[$stats{$date}->{platform}->{$platform}] $platform";
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mplatforms',\%tvars);
    undef %tvars;

    for my $date (sort keys %stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $perl (sort {$stats{$date}->{perl}->{$b} <=> $stats{$date}->{perl}->{$a}} keys %{$stats{$date}->{perl}}) {
            $content .= ', '    if($content);
            $content .= "[$stats{$date}->{perl}->{$perl}] $perl";
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mperls',\%tvars);
    undef %tvars;

    my %testers;
    for my $date (sort keys %stats) {
        next    if($date > $LIMIT);

        my ($count,$content) = (0,'');
        for my $tester (sort {$stats{$date}->{tester}->{$b} <=> $stats{$date}->{tester}->{$a}} keys %{$stats{$date}->{tester}}) {
            $content .= ', '    if($content);
            $content .= "[$stats{$date}->{tester}->{$tester}] $tester";
            $testers{$tester} += $stats{$date}->{tester}->{$tester};
            $count++;
        }
        unshift @{$tvars{STATS}}, [$date,$count,$content];
    }
    $self->_writepage('mtesters',\%tvars);
    undef %tvars;

## GENERATE TESTERS LEADER BOARD

    _progress("building leader board") if($self->{progress});

    $count = 1;
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
    undef %tvars;
    undef %testers;
}

=item * _report_matrix

Generates the report matrix page

=cut

sub _report_matrix {
    my $self = shift;
    my (%stats,%perls,%tvars);

    # grab all records for the month
    my $iterator = $self->{dbh}->get_query_iterator("SELECT * FROM cpanstats WHERE postdate like '$LASTDATE'");
    while(my $row = $iterator->()) {
        next    if($row->[1] eq 'cpan');

        # platform -> perl
        $row->[7] =~ s/\s.*//;  # only need to know the main release
        $stats{$row->[6]}->{$row->[7]}++;
        $perls{$row->[7]} = 1;
    }

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

    $tvars{CONTENT} = $content;
    $self->_writepage('rmatrix',\%tvars);
}

=item * _report_interesting

Generates the interesting stats page

=cut

sub _report_interesting {
    my $self = shift;
    my %tvars;

    my @bydist = $self->{dbh}->get_query("SELECT count(id) AS count,dist FROM cpanstats WHERE state != 'cpan' GROUP BY dist ORDER BY count DESC LIMIT 20");
    my @byvers = $self->{dbh}->get_query("SELECT count(id) AS count,dist,version FROM cpanstats WHERE state != 'cpan' GROUP BY dist,version ORDER BY count DESC LIMIT 20");

    $tvars{BYDIST} = \@bydist;
    $tvars{BYVERS} = \@byvers;

    my (%index,@posters,@entries,@reports);
    my %counter = ( posters => 0, entries => 0, reports => 0 );
    my ($last_posters,$last_entries,$last_reports);
    my ($posters_count,$entries_count,$reports_count) = (0,0,0);

    my $next = $self->{dbh}->get_query_iterator('SELECT * FROM cpanstats ORDER BY id');
    while(my $row = $next->()) {
        my @row = (0, @$row);
        $counter{posters} = $row[1];
        if($counter{posters} == 1 || ($counter{posters} % 500000) == 0) {
            $index{posters}->{$row[1]} = $counter{posters};
            push @posters, \@row;
        } else {
            $posters_count = $counter{posters};
            $last_posters = \@row;
        }

        $counter{entries}++;
        if($counter{entries} == 1 || ($counter{entries} % 500000) == 0) {
            $index{entries}->{$row[1]} = $counter{entries};
            push @entries, \@row;
        } else {
            $entries_count = $counter{entries};
            $last_entries = \@row;
        }

        if($row[2] ne 'cpan') {
            $counter{reports}++;
            if(($counter{reports} == 1 || ($counter{reports} % 500000) == 0)) {
                $index{reports}->{$row[1]} = $counter{reports};
                push @reports, \@row;
            } else {
                $reports_count = $counter{reports};
                $last_reports = \@row;
            }
        }
    }

    $index{posters}->{$last_posters->[1]} = $posters_count;
    $index{entries}->{$last_entries->[1]} = $entries_count;
    $index{reports}->{$last_reports->[1]} = $reports_count;

    push @posters, $last_posters;
    push @entries, $last_entries;
    push @reports, $last_reports;

    my (@postersx,@entriesx,@reportsx);
    for my $row (@posters) {
        $row->[0] = $index{posters}{$row->[1]};
        $row->[4] = $self->_tester_name($row->[4])  if($row->[4] =~ /\@/);
        my @this = @$row;
        push @postersx, \@this;
    }
    for my $row (@entries) {
        $row->[0] = $index{entries}{$row->[1]};
        $row->[4] = $self->_tester_name($row->[4])  if($row->[4] =~ /\@/);
        my @this = @$row;
        push @entriesx, \@this;
    }
    for my $row (@reports) {
        $row->[0] = $index{reports}{$row->[1]};
        $row->[4] = $self->_tester_name($row->[4])  if($row->[4] =~ /\@/);
        my @this = @$row;
        push @reportsx, \@this;
    }

    my @headings = ('count','id','state','postdate','tester','dist','version','platform','perl','osname','osvers','fulldate');

    $tvars{HEADINGS} = \@headings;
    $tvars{POSTERS}  = \@postersx;
    $tvars{ENTRIES}  = \@entriesx;
    $tvars{REPORTS}  = \@reportsx;

    $self->_writepage('interest',\%tvars);
}

=item * _writepage

Creates a single HTML page.

=cut

sub _writepage {
    my ($self,$page,$vars) = @_;

#   _progress("writing page - $page") if($self->{progress});

    my $template = $page;
    $template = 'distlist'    if($page =~ /^list-/);

    my $layout = "layout.html";
    my $source = "$template.html";
    my $target = "$self->{directory}/$page.html";

    $vars->{SOURCE}   = $source;
    $vars->{VERSION}  = $VERSION;
    $vars->{RUNDATE}  = $RUNDATE;
    $vars->{STATDATE} = $STATDATE;
    $vars->{THATDATE} = $THATDATE;

#    if($page =~ /^list-/) {
#        use Data::Dumper;
#        print STDERR "$page:" . Dumper($pages{$page});
#    }

    my %config = (                              # provide config info
        RELATIVE        => 1,
        ABSOLUTE        => 1,
        INCLUDE_PATH    => $self->{templates},
        INTERPOLATE     => 0,
        POST_CHOMP      => 1,
        TRIM            => 1,
    );

    my $parser = Template->new(\%config);           # initialise parser
    $parser->process($layout,$vars,$target) # parse the template
        or die $parser->error();
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
        my $fh = IO::File->new($self->{address})    or die "Cannot open address file [$self->{address}]: $!";
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
    $addr =~ s/\@/[]/g;
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

=item * _progress

Simple audit logging function.

=cut

my $lasttime = time;

sub _progress {
    my $msg = shift;
    my $time = time;
    my @localtime = localtime($time);
    my $secs = $time - $lasttime;
    printf STDERR "%02d:%02d:%02d\t%03d\t%s\n", $localtime[2], $localtime[1], $localtime[0], $secs, $msg;
    $lasttime = $time;
}

=item * _init_date

Prime all key date variable.

=cut

sub _init_date {
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
    $THATDATE = sprintf "%s %d", $month{int($datetime[4])}, $THISYEAR;

    #print STDERR "THISYEAR=[$THISYEAR]\n";
    #print STDERR "LIMIT=[$LIMIT]\n";
    #print STDERR "STATDATE=[$STATDATE]\n";
    #print STDERR "RUNDATE=[$RUNDATE]\n";
}

q("I'm breaking the back of love.");

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

  Copyright (C) 2005-2009 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

