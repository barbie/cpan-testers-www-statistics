#!perl

use strict;
use warnings;

use Test::More tests => 22;
use File::Path;
use File::Spec;
use Cwd;
use lib 't';
use CTWS_Testing;

unlink('50logging.log') if(-f '50logging.log');

{
    ok( my $obj = CTWS_Testing::getObj(config => 't/50logging.ini'), "got object" );

    is($obj->logfile, '50logging.log', 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Hello");
    $obj->_log("Goodbye");

    ok( -f '50logging.log', '50logging.log created in current dir' );

    my @log = do { open FILE, '<', '50logging.log'; <FILE> };
    chomp @log;

    is(scalar(@log),10, 'log written');
    like($log[8], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,   'line 1 of log');
    like($log[9], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!, 'line 2 of log');
}


{
    ok( my $obj = CTWS_Testing::getObj(config => 't/50logging.ini'), "got object" );

    is($obj->logfile, '50logging.log', 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');

    $obj->_log("Back Again");

    ok( -f '50logging.log', '50logging.log created in current dir' );

    my @log = do { open FILE, '<', '50logging.log'; <FILE> };
    chomp @log;

    is(scalar(@log),19, 'log extended');
    like($log[8], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Hello!,      'line 1 of log');
    like($log[9], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Goodbye!,    'line 2 of log');
    like($log[18], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Back Again!, 'line 3 of log');
}

{
    ok( my $obj = CTWS_Testing::getObj(config => 't/50logging.ini'), "got object" );

    is($obj->logfile, '50logging.log', 'logfile default set');
    is($obj->logclean, 0, 'logclean default set');
    $obj->logclean(1);
    is($obj->logclean, 1, 'logclean reset');

    $obj->_log("Start Again");

    ok( -f '50logging.log', '50logging.log created in current dir' );

    my @log = do { open FILE, '<', '50logging.log'; <FILE> };
    chomp @log;

    is(scalar(@log),1, 'log overwritten');
    like($log[0], qr!\d{4}/\d\d/\d\d \d\d:\d\d:\d\d Start Again!, 'line 1 of log');
}

unlink('50logging.log');
