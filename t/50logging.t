#!/usr/bin/perl -w
use strict;

use File::Path;
use File::Slurp;
use Test::More tests => 22;

use lib 't';
use CTWS_Testing;

my $LOG = 't/_DBDIR/50logging.log';
my $CFG = 't/data/50logging.ini';

my $cfg = CTWS_Testing::create_config( $CFG );

unlink($LOG) if(-f $LOG);

{
    ok( my $obj = CTWS_Testing::getObj(config => $cfg), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Hello");
    $obj->_log("Goodbye");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),15, 'log written');
    like($log[13], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,   'line 1 of log');
    like($log[14], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!, 'line 2 of log');
}

{
    ok( my $obj = CTWS_Testing::getObj(config => $cfg), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Back Again");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),29, 'log extended');
    like($log[13], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 1 of log');
    like($log[14], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 2 of log');
    like($log[28], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Back Again!, 'line 3 of log');
}

{
    ok( my $obj = CTWS_Testing::getObj(config => $cfg), "got object" );

    is($obj->logfile, $LOG, 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');
    $obj->logclean(1);
    is($obj->logclean, 1, 'logclean reset');

    $obj->_log("Start Again");

    ok( -f $LOG, '50logging.log created in current dir' );

    my @log = read_file($LOG);
    chomp @log;

    is(scalar(@log),1, 'log overwritten');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Start Again!, 'line 1 of log');
}

unlink($LOG);
