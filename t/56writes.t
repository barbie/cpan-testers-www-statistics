#!perl

use strict;
use warnings;
$|=1;

my $CHECK_DOMAIN    = 'www.google.com';

# NOTE about t/56writes.t & t/expected.zip...
#
# If the write tests fail, due to any change a new expected.zip file is
# required. In order to regenerate the archive enter the following
# commands:
#
# $> prove -Ilib t/05setup_db-*.t
# $> perl -Ilib t/56writes.t --update-archive
#
# This will assume that any failing tests are actually correct, and
# create a new zip file t/expected-NEW.zip. To commit it, just enter:
#
# $> mv t/expected-NEW.zip t/expected.zip

my $UPDATE_ARCHIVE = ($ARGV[0] && $ARGV[0] eq '--update-archive') ? 1 : 0;


use Test::More tests => 267;
use Test::Differences;
use File::Slurp qw( slurp );
use Archive::Zip;
use Archive::Extract;
use File::Spec;
use File::Path;
use File::Copy;
use File::Basename;
use Sort::Versions;

use lib 't';
use CTWS_Testing;

ok( my $obj = CTWS_Testing::getObj(), "got object" );
ok( CTWS_Testing::cleanDir($obj), 'directory removed' );
unlink($obj->mainstore) if(-f $obj->mainstore);
unlink($obj->leadstore) if(-f $obj->leadstore);

my $rc;
my @files;
my @expectedFiles;
my $expectedDir;

my $EXPECTEDPATH = File::Spec->catfile( 't', '_EXPECTED' );
my $zip = File::Spec->catfile('t','expected.zip');
if(-f $zip) {
    my $ae = Archive::Extract->new( archive => $zip );
    ok( $ae->extract(to => $EXPECTEDPATH), 'extracted expected files' );
} else {
    ok(0);
}
#---------------------------------------
# Tests for creating pages

my $page = CTWS_Testing::getPages();
my $dir  = $obj->directory();

# copy templates directory
# .. as updates-index.html and updates-all.html are created dynamically
#    we create blank version in this test version of the directory
my $SOURCE = $obj->templates();
my $TARGET = File::Spec->catfile( 't', '_TEMPLATES' );
my @source = CTWS_Testing::listFiles( $SOURCE );
for my $f (@source) {
    my $source = File::Spec->catfile( $SOURCE, $f );
    my $target = File::Spec->catfile( $TARGET, $f );
    mkpath( dirname($target) );
    copy( $source, $target )	if(-f $source);
}
my $images = File::Spec->catfile( $TARGET, 'images' );
rmtree($images);
$obj->templates($TARGET);

#my ($stats,$fails,$pass,$counts,$dists,$index,$versions) = $page->_build_stats();


## BUILD BASICS METHODS

$obj->directory($dir . '/_write_basics'),
$page->_write_basics();
check_dir_contents(
	"[_write_basics]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._write_basics'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_missing_in_action'),
$page->_missing_in_action();
check_dir_contents(
	"[_missing_in_action]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._missing_in_action'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


## READ JSON DATA

{
    my $store1 = 't/data/cpanstats-test.json';
    $page->storage_read($store1);

    my @versions = sort {versioncmp($b,$a)} keys %{$page->{perls}};
    $page->{versions} = \@versions;
}


## BUILD MATRIX METHODS

$obj->directory($dir . '/_build_osname_matrix'),
$page->_build_osname_matrix();
check_dir_contents(
	"[_build_osname_matrix]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_osname_matrix'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_build_platform_matrix'),
$page->_build_platform_matrix();
check_dir_contents(
	"[_build_platform_matrix]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_platform_matrix'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


## BUILD REGULAR STATS METHODS

$obj->directory($dir . '/_report_cpan'),
$page->_report_cpan();
check_dir_contents(
	"[_report_cpan]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._report_cpan'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_build_monthly_stats'),
$page->_build_monthly_stats();
check_dir_contents(
	"[_build_monthly_stats]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_monthly_stats'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_report_interesting'),
$page->_report_interesting();
check_dir_contents(
	"[_report_interesting]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._report_interesting'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_build_monthly_stats_files'),
$page->_build_monthly_stats_files();
check_dir_contents(
	"[_build_monthly_stats_files]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_monthly_stats_files'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_build_failure_rates'),
$page->_build_failure_rates();
check_dir_contents(
	"[_build_failure_rates]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_failure_rates'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_build_performance_stats'),
$page->_build_performance_stats();
check_dir_contents(
	"[_build_performance_stats]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_performance_stats'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );

$obj->directory($dir . '/_write_index'),
$page->_write_index();
check_dir_contents(
	"[_write_index]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._write_index'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


## BUILD LEADERBOARDS METHODS

$obj->directory($dir . '/_build_osname_leaderboards'),
$page->_build_osname_leaderboards();
check_dir_contents(
	"[_build_osname_leaderboards]",
	$obj->directory,
	File::Spec->catfile($EXPECTEDPATH,'56writes._build_osname_leaderboards'),
);
ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


#---------------------------------------
# Tests for creating graphs

SKIP: {
	skip "Can't see a network connection", 117	if(pingtest($CHECK_DOMAIN));

    $obj->directory($dir . '/update_full'),
    $page->update_full();
    check_dir_contents(
        "[update_full]",
        $obj->directory,
        File::Spec->catfile($EXPECTEDPATH,'56writes.update_full'),
    );
    ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


	my $graph = CTWS_Testing::getGraphs();

    CTWS_Testing::saveFiles($dir . '/graphs');

	$obj->directory($dir . '/graphs'),
	$graph->create();
	check_dir_contents(
		"[graphs]",
		$obj->directory,
		File::Spec->catfile($EXPECTEDPATH,'56writes.graphs'),
	);
	ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );
};

#---------------------------------------
# Tests for main API

#$obj->directory($dir . '/make_pages'),
#$obj->make_pages();
#check_dir_contents(
#	"[make_pages]",
#	$obj->directory,
#	File::Spec->catfile($EXPECTEDPATH,'56writes.make_pages'),
#);
#ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );


SKIP: {
	skip "Can't see a network connection", 11	if(pingtest($CHECK_DOMAIN));

    CTWS_Testing::saveFiles($dir . '/make_graphs');

    $obj->directory($dir . '/make_graphs');
    eval { $obj->make_graphs() };

    SKIP: {
        skip "could not retrieve graphs", 1    if($@ =~ /- (request failed|Cannot access page) -/);
        check_dir_contents(
            "[make_graphs]",
            $obj->directory,
            File::Spec->catfile($EXPECTEDPATH,'56writes.make_graphs'),
        );
    }
    ok( CTWS_Testing::cleanDir($obj), 'directory cleaned' );
};

#---------------------------------------
# Update Code

if( $UPDATE_ARCHIVE ){
  my $zip = Archive::Zip->new();
  $zip->addTree( $EXPECTEDPATH );
  my $f = File::Spec->catfile( 't', 'expected-NEW.zip' );
  diag "CREATING NEW ZIP FILE: $f";
  unlink $f if -f $f;
  $zip->writeToFileNamed($f) == Archive::Zip::AZ_OK
	or diag "==== ERROR WRITING TO $f ====";
}

##################################################################

#my $time = time;
#system("cp -r $EXPECTEDPATH ${EXPECTEDPATH}_$time");

ok( CTWS_Testing::whackDir($obj), 'directory removed' );
ok( rmtree($EXPECTEDPATH), 'expected dir removed' );
ok( rmtree($TARGET), 'template dir removed' );

exit;

##################################################################

sub eq_or_diff_files {
  my ($f1, $f2, $desc, $filter) = @_;
  my $s1 = -f $f1 ? slurp($f1) : undef;
  &$filter($s1) if $filter;
  my $s2 = -f $f2 ? slurp($f2) : undef;
  &$filter($s2) if $filter;
  return
	( defined($s1) && defined($s2) )
	? eq_or_diff( $s1, $s2, $desc )
	: ok( 0, "$desc - both files exist [missing ".(defined($s2) ? $f1 : $f2)."]")
  ;
}

sub check_dir_contents {
  my ($diz, $dir, $expectedDir) = @_;
  my @files = CTWS_Testing::listFiles( $dir );
  my @expectedFiles = CTWS_Testing::listFiles( $expectedDir );
  ok( scalar(@files), "got files [$dir]" );
  ok( scalar(@expectedFiles), "got expectedFiles [$expectedDir]" );
  eq_or_diff( \@files, \@expectedFiles, "$diz file listings match" );
  my $count = 3;
  for my $f ( @files ){
    my $fGot = File::Spec->catfile($dir,$f);
    my $fExpected = File::Spec->catfile($expectedDir, $f);

    # diff text files only
    if($f =~ /\.(html?|txt|js|css|json|ya?ml|ini|cgi)$/i) {
        $count++;
        my $ok = eq_or_diff_files(
            $fGot,
            $fExpected,
            "$diz diff $f",
            sub {
                if($_[0]) {
                    $_[0] =~ s/^(\s*)\d+\.\d+(?:_\d+)? at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.( Comments and design patches)/$1 ==TIMESTAMP== $2/gmi;
                    $_[0] =~ s!\w{3},\s+\d{2}\s+\w{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+[\w\\ \xe4]+!==TIMESTAMP==!gmi;
                    $_[0] =~ s!\w{3}\s+\w{3}\s+\d{1,2}\s+\d{2}:\d{2}:\d{2}\s+\w{3,4}\s+\d{4}!==TIMESTAMP==!gmi;
                    $_[0] =~ s/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/==TIMESTAMP==/gmi;
                    $_[0] =~ s/\d+(st|nd|rd|th)\s+\w+\s+\d+/==TIMESTAMP==/gmi;
                    $_[0] =~ s!\d{4}/\d{2}/\d{2}!==TIMESTAMP==!gmi;
                    $_[0] =~ s!20\d{6}!==TIMESTAMP==!gmi;
                    $_[0] =~ s!\d{2}/\d{2}!==TIMESTAMP==!gmi;
                    $_[0] =~ s!\w+ \d{4}!==TIMESTAMP==!gmi;
                    $_[0] =~ s!CPAN-Testers-WWW-Statistics-0.\d{2}!==DISTRO==!gmi;
                }
                $_[0];
            }
        );
        next if $ok;
    }

    next unless $UPDATE_ARCHIVE;
    if(-f $fExpected)   { unlink($fExpected); }
    else                { mkpath( dirname($fExpected) ) ; }
    copy( $fGot, $fExpected );
  }

#diag("check_dir_contents: [$diz] tests=$count/".(scalar(@files)+3));
  return unless $UPDATE_ARCHIVE;
  for my $f ( @expectedFiles ){
    # remove files no longer expected
    my $fGot = File::Spec->catfile($dir,$f);
    my $fExpected = File::Spec->catfile($expectedDir, $f);
    next    if(-f $fGot);
    unlink($fExpected);

    # remove directories no longer expected
    my $dGot = dirname($fGot);
    my $dExpected = dirname($fExpected);
    while(!-d $dGot) {
      last    if($dGot eq $dir);
      last    if(-d $dGot);
      $dGot = dirname($dGot);
      $dExpected = dirname($dExpected);
    }
  }
}

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
