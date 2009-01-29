package CPAN::Testers::WWW::Statistics::Graphs;

use warnings;
use strict;
use vars qw($VERSION);

$VERSION = '0.59';

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Statistics::Graphs - CPAN Testers Statistics graphs.

=head1 SYNOPSIS

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);
  my $ct = CPAN::Testers::WWW::Statistics::Graphs->new(parent => $obj);
  $ct->create();

=head1 DESCRIPTION

Using previously formatted data, generate graphs using the Google Chart API.

Note that this package should not be called directly, but via its parent as:

  my %hash = { config => 'options' };
  my $obj = CPAN::Testers::WWW::Statistics->new(%hash);
  $obj->make_graphs();

=cut

# -------------------------------------
# Library Modules

use File::Path;
use HTML::Entities;
use IO::File;
use WWW::Mechanize;

# -------------------------------------
# Variables

my %month = (
    0 => 'January',   1 => 'February', 2 => 'March',     3 => 'April',
    4 => 'May',       5 => 'June',     6 => 'July',      7 => 'August',
    8 => 'September', 9 => 'October', 10 => 'November', 11 => 'December'
);

my ($backg,$foreg) = ('black','white');

my @graphs = (
['stats1','CPAN Testers Statistics - Reports',      [qw(UPLOADS REPORTS PASS FAIL)]],
['stats2','CPAN Testers Statistics - Attributes',   [qw(TESTERS PLATFORMS PERLS)]],
['stats3','CPAN Testers Statistics - Non-Passes',   [qw(FAIL NA UNKNOWN)]],
['stats4','CPAN Testers Statistics - Testers',      [qw(ALL FIRST LAST)]],
);

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

my $chart_api    = 'http://chart.apis.google.com/chart?chs=1000x300&cht=lc';
my $chart_titles = 'chtt=%s&chdl=%s';
my $chart_labels = 'chxt=x,x,y,r&chxl=0:|%s|1:|%s|2:|%s|3:|%s';
my $chart_data   = 'chd=t:%s';
my $chart_colour = 'chco=%s';
my $chart_filler = 'chf=bg,s,dddddd';

my %COLOURS = (
    white      => [255,255,255],
    black      => [0,0,0],
    red        => [255,0,0],
    blue       => [0,0,255],
    purple     => [230,0,230],
    green      => [0,255,0],
    grey       => [128,128,128],
    light_grey => [170,170,170],
    dark_grey  => [75,75,75],
    cream      => [200,200,240],
    yellow     => [255,255,0],
    orange     => [255,128,0],
);

my @COLOURS = map {sprintf "%s%s%s", _dec2hex($COLOURS{$_}->[0]),_dec2hex($COLOURS{$_}->[1]),_dec2hex($COLOURS{$_}->[2])} qw(red blue green orange purple grey);
my @MONTH   = qw( - J F M A M J J A S O N D );

# -------------------------------------
# Subroutines

=head1 INTERFACE

=head2 The Constructor

=over 4

=item * new

Graph creation object. Checks to see whether the data files exist, and allows
the user to turn or off the progress tracking.

new() takes an option hash as an argument, which may contain 'progress => 1'
to turn on the progress tracker and/or 'directory => $dir' to indicate the path
to the data files. If no directory is supplied the current directory is
assumed.

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    die "Must specify the parent statistics object\n"   unless(defined $hash{parent});

    my $self = {parent => $hash{parent}};
    bless $self, $class;
}

=head2 Methods

=over 4

=item * create

Method to facilitate the creation of graphs.

=back

=cut

sub create {
    my $self = shift;
    my $directory = $self->{parent}->directory;
    mkpath($directory);

    $self->{parent}->_log("start");

    for my $g (@graphs) {
        $self->{parent}->_log("writing graph - $g->[0]");

        my $url = _make_graph("$directory",@$g);
        $self->{parent}->_log("url - [".(length $url)."] $url");
#        print "$url\n";

        $mech->get($url);
        if(!$mech->success()) {
            my $file = "$g->[0].html";
            warn("FAIL: $0 - Cannot access page - see '$file'\n");
            $mech->save_content($file);
        } elsif($mech->response->header('Content-Type') =~ /html/) {
            my $file = "$g->[0].html";
            warn("FAIL: $0 - request failed - see '$file'\n");
            $mech->save_content($file);
        } else {
            my $file = "$directory/$g->[0].png";
            my $fh = IO::File->new(">$file") or die "$0 - Cannot write file [$file]: $!\n";
            binmode($fh);
            print $fh $mech->content;
            $fh->close;
        }
    }

    $self->{parent}->_log("finish");
}

#=item _make_graph
#
#Creates and writes out a single graph.
#
#=cut

sub _make_graph {
    my ($dir,$file,$title,$legend) = @_;
    my (@dates1,@dates2);
    my $yr = 0;

    my @data = _get_data("$file.txt");
    for my $date (@{$data[0]}) {
        my $year  = substr($date,0,4);
        my $month = substr($date,4,2);
        push @dates1, ($month %2 == 1 ? $MONTH[$month] : '');
        push @dates2, ($year != $yr ? $year : '');
        $yr = $year;
    }

    my $max = 0;
    for my $inx (1 .. $#data) {
        for my $data (@{$data[$inx]}) {
            $max = $data    if($max < $data);
        }
    }

    $max = _set_max($max);
    my $range = _set_range(0,$max);

    my (@d,@c);
    my @colours = @COLOURS;
    for my $inx (1 .. $#data) {
        push @c, shift @colours;
        for(@{$data[$inx]}) {
#print "pcent = $_ / $max * 100 = ";
            $_ = $_ / $max * 100;
#print "$_ = ";
            $_ = int($_ * 1) / 1;
#print "$_\n";
        }

        push @d, join(',',@{$data[$inx]});
    }
    my $d = join('|',@d);
    my $data = sprintf $chart_data, $d;

    my $dates1 = join('|', @dates1);
    my $dates2 = join('|', @dates2);

    my $colour = sprintf $chart_colour, join(',',@c);
    my $titles = sprintf $chart_titles, $title, join('|',@$legend);
    my $labels = sprintf $chart_labels, $dates1, $dates2, $range, $range;
    $titles =~ s/ /+/g;
    $labels =~ s/ /+/g;
    my @api = ($chart_api, $titles, $labels, $colour, $chart_filler, $data) ;

    my $url = join('&',@api);
    return $url;
}

#=item _get_data
#
#Reads and returns the contents of the graph data file.
#
#=cut

sub _get_data {
  my $file = shift;

  my @data;
  my $fh = IO::File->new($file) or die "Cannot open data file [$file]: $!\n";
  while(<$fh>) {
    chomp;
    my @values = split(",",$_);
    push @{$data[$_]}, $values[$_]    for(0..$#values);
  }
  return @data;
}

sub _dec2hex {
    my $hexnum = sprintf("%x", $_[0]);
    return '00'         if(length($hexnum) < 1);
    return '0'.$hexnum  if(length($hexnum) < 2);
    return $hexnum;
}

sub _set_max {
    my $max = shift;
#print "max=$max\n";

       if($max <  10)       { $max = 10 }
    elsif($max <  100)      { $max = ((int($max/10)+1)*10)           }
#    elsif($max < 500)      { $max = ((int($max/50)+1)*50)           }
    elsif($max <  1000)     { $max = ((int($max/100)+1)*100)         }
    elsif($max <  10000)    { $max = ((int($max/1000)+1)*1000)       }
    elsif($max <  100000)   { $max = ((int($max/10000)+1)*10000)     }
    elsif($max <  1000000)  { $max = ((int($max/100000)+1)*100000)   }
    else                    { $max = ((int($max/1000000)+1)*1000000) }

#print "max=$max\n";
    return $max;
}

sub _set_range {
    my ($min,$max) = @_;
    my $step = 1;

       if($max <  10)       { $step = 1        }
    elsif($max <  100)      { $step = 10       }
    elsif($max <  500)      { $step = 50       }
    elsif($max <  1000)     { $step = 50       }
    elsif($max <  10000)    { $step = 500      }
    elsif($max <  100000)   { $step = 5000     }
    elsif($max <  1000000)  { $step = 50000    }
    else                    { $step = 1000000  }

    my @r;
    for(my $r = $min; $r < ($max+$step); $r += $step) {
        my $x = $r < 1000000 ? $r < 1000 ? $r : ($r/1000) . 'k' : ($r/1000000) . 'm';
        push @r, $x;
    };
#print "range=".(join('|',@r))."\n";
    return join('|',@r);
}

q('This is not a love song!');

__END__

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

