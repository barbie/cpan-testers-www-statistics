#!perl

use strict;
use warnings;
$|=1;
use Test::More tests => 1;
use DBI;
use File::Spec;
use File::Path;
use File::Basename;

my $f = File::Spec->catfile('t','_DBDIR','test.db');
unlink $f if -f $f;
mkpath( dirname($f) );

my $dbh = DBI->connect("dbi:SQLite:dbname=$f", '', '', {AutoCommit=>1});

$dbh->do(q{
  CREATE TABLE noreports (
    dist          TEXT,
    version       TEXT,
    osname        TEXT
  )
});

$dbh->do(q{
  CREATE TABLE cpanstats (
    id            INTEGER PRIMARY KEY,
    guid          TEXT,
    state         TEXT,
    postdate      TEXT,
    tester        TEXT,
    dist          TEXT,
    version       TEXT,
    platform      TEXT,
    perl          TEXT,
    osname        TEXT,
    osvers        TEXT,
    fulldate      TEXT,
    type          TEXT
  )
});

# calculate dates
my @date = localtime(time);
my $THISMONTH = sprintf "%04d%02d", $date[4] > 0 ? ($date[5]+1900, $date[4])   : ($date[5]+1899, 12);
my $LASTMONTH = sprintf "%04d%02d", $date[4] > 1 ? ($date[5]+1900, $date[4]-1) : ($date[5]+1899, 11 + $date[4]);

while(<DATA>){
  next  unless(/^\d/);
  chomp;

  # adjust dates to current months
  my @fields = split(/\|/,$_);
  $fields[3]  =~ s/201101/$LASTMONTH/;
  $fields[3]  =~ s/201102/$THISMONTH/;
  $fields[11] =~ s/201101/$LASTMONTH/;
  $fields[11] =~ s/201102/$THISMONTH/;
  $dbh->do('INSERT INTO cpanstats ( id, guid, state, postdate, tester, dist, version, platform, perl, osname, osvers, fulldate, type) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )', {}, @fields );
}

$dbh->do(q{ CREATE INDEX distverstate ON cpanstats (dist, version, state) });
$dbh->do(q{ CREATE INDEX ixdate ON cpanstats (postdate) });
$dbh->do(q{ CREATE INDEX ixperl ON cpanstats (perl) });
$dbh->do(q{ CREATE INDEX ixplat ON cpanstats (platform) });

my ($ct) = $dbh->selectrow_array('select count(*) from cpanstats');

$dbh->disconnect;

is($ct, 96, "row count for cpanstats");

my $fgz = File::Spec->catfile('t','_DBDIR','test.db.gz');
link($f,$fgz);


# sqlite> select * from cpanstats where postdate=200901 order by dist limit 20;
# id|state|postdate|tester|dist|version|platform|perl|osname|osvers|date
__DATA__
104440|104440-ed372d00-b19f-3f77-b713-d32bba55d77f|unknown|201101|kriegjcb@mi.ruhr-uni-bochum.de ((Jost Krieger))|AI-NeuralNet-Mesh|0.44|sun4-solaris|5.8.1|solaris|2.8|201101061151|2
1396564|1396564-ed372d00-b19f-3f77-b713-d32bba55d77f|unknown|201101|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.5.5|freebsd|6.1-release|201101022114|2
1544358|1544358-ed372d00-b19f-3f77-b713-d32bba55d77f|na|201101|jj@jonallen.info ("JJ")|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.3|darwin|7.9.0|201101290833|2
1587804|1587804-ed372d00-b19f-3f77-b713-d32bba55d77f|na|201101|jj@jonallen.info ("JJ")|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.1|darwin|7.9.0|201101030648|2
1717321|1717321-ed372d00-b19f-3f77-b713-d32bba55d77f|na|201101|srezic@cpan.org|Abstract-Meta-Class|0.10|i386-freebsd|5.5.5|freebsd|6.1-release|201101171653|2
1994346|1994346-ed372d00-b19f-3f77-b713-d32bba55d77f|unknown|201101|srezic@cpan.org|AI-NeuralNet-SOM|0.02|i386-freebsd|5.6.2|freebsd|6.1-release|201101062212|2
2538246|2538246-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201101|bingos@cpan.org|Acme-CPANAuthors-French|0.06|i386-freebsd-thread-multi-64int|5.8.8|freebsd|6.2-release|201101021014|2
2549071|2549071-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201101|bingos@cpan.org|Acme-CPANAuthors-French|0.07|OpenBSD.i386-openbsd-thread-multi-64int|5.8.8|openbsd|4.2|201101042025|2
2603754|2603754-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201101|JOST@cpan.org ("Josts Smokehouse")|AI-NeuralNet-SOM|0.02|i86pc-solaris-64int|5.8.8 patch 34559|solaris|2.11|201101122105|2
2613077|2613077-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201101|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.8.9|freebsd|6.1-release-p23|201101132053|2
2725989|2725989-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201101|stro@cpan.org|Acme-CPANAuthors-Canadian|0.0101|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.00|201101011303|2
2959417|2959417-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201101|rhaen@cpan.org (Ulrich Habel)|Abstract-Meta-Class|0.11|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.1|201101301529|2
2964284|2964284-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme|1.11111|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102010443|2
2964285|2964285-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme-Buffy|1.5|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102010443|2
2964537|2964537-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-CodeRepos|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102010609|2
2964541|2964541-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-Japanese|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102010611|2
2965412|2965412-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme-Brainfuck|1.1.1|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102010929|2
2965930|2965930-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|AI-NeuralNet-BackProp|0.89|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102011103|2
2965931|2965931-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|AI-NeuralNet-Mesh|0.44|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102011103|2
2966360|2966360-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|cpan@sourcentral.org ("Oliver Paukstadt")|AI-NeuralNet-SOM|0.07|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|201102010542|2
2966429|2966429-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-BOPE|0.01|s390x-linux|5.8.8|linux|2.6.16.60-0.31-default|201102010558|2
2966541|2966541-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-Canadian|0.0101|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|201102010628|2
2966560|2966560-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201102|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-French|0.07|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|201102010635|2
2966567|2966567-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-CodeRepos|0.080522|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|201102010638|2
2966771|2966771-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|AEAE|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102011502|2
2967174|2967174-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|AOL-TOC|0.340|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102011645|2
2967432|2967432-ed372d00-b19f-3f77-b713-d32bba55d77f|fail|201102|andreas.koenig.gmwojprw@franz.ak.mind.de|Acme-CPANAuthors-French|0.07|x86_64-linux|5.10.0|linux|2.6.24-1-amd64|201102011038|2
2967647|2967647-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|imacat@mail.imacat.idv.tw|Acme-Anything|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|201102011830|2
2969433|2969433-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|201102010115|2
2969661|2969661-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|201102010303|2
2969663|2969663-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|201102010303|2
2970367|2970367-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.11.0 patch GitLive-blead-163-g28b1dae|linux|2.6.24-19-generic|201102010041|2
2975969|2975969-ed372d00-b19f-3f77-b713-d32bba55d77f|pass|201102|rhaen@cpan.org (Ulrich Habel)|Acme-CPANAuthors-Japanese|0.090101|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.1|201102021220|2
11278|11278-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JHARDING|AOL-TOC|0.32||0|||201101281749|1
11422|11422-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JHARDING|AOL-TOC|0.33||0|||201101040912|1
11989|11989-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-BackProp|0.40||0|||201101220918|1
12095|12095-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-BackProp|0.42||0|||201101261138|1
12605|12605-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-BackProp|0.77||0|||201101121011|1
12822|12822-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-BackProp|0.89||0|||201101170921|1
13051|13051-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JHARDING|AOL-TOC|0.340||0|||201101220610|1
13066|13066-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-Mesh|0.20||0|||201101230741|1
13133|13133-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-Mesh|0.31||0|||201101251025|1
13828|13828-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-Mesh|0.43||0|||201101141053|1
13880|13880-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JBRYAN|AI-NeuralNet-Mesh|0.44||0|||201101142256|1
14426|14426-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|VOISCHEV|AI-NeuralNet-SOM|0.01||0|||201101292037|1
14530|14530-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|VOISCHEV|AI-NeuralNet-SOM|0.02||0|||201101042041|1
23502|23502-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|LBROCARD|Acme-Buffy|1.1||0|||201101221815|1
26042|26042-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|LBROCARD|Acme-Buffy|1.2||0|||201101121353|1
36109|36109-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|LBROCARD|Acme-Buffy|1.3||0|||201101271437|1
58944|58944-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JALDHAR|Acme-Brainfuck|1.0.0||0|||201101032115|1
104368|104368-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JESSE|Acme-Buffy|1.3||0|||201101051219|1
128571|128571-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|INGY|Acme|1.00||0|||201101211232|1
128577|128577-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|INGY|Acme|1.11||0|||201101211307|1
128615|128615-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|INGY|Acme|1.111||0|||201101212239|1
131264|131264-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JALDHAR|Acme-Brainfuck|1.1.0||0|||201101060730|1
131340|131340-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JALDHAR|Acme-Brainfuck|1.1.1||0|||201101061825|1
194191|194191-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|INGY|Acme|1.1111||0|||201101270846|1
283938|283938-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|INGY|Acme|1.11111||0|||201101190015|1
286799|286799-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JETEVE|AEAE|0.01||0|||201101311729|1
288796|288796-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JETEVE|AEAE|0.02||0|||201101101119|1
347205|347205-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|LBROCARD|Acme-Buffy|1.4||0|||201101081831|1
469300|469300-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|LBROCARD|Acme-Buffy|1.5||0|||201101281603|1
502506|502506-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.01||0|||201101051723|1
505918|505918-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.02||0|||201101101701|1
509756|509756-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.03||0|||201101142113|1
510429|510429-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.04||0|||201101171333|1
552718|552718-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JJORE|Acme-Anything|0.01||0|||201101020003|1
759609|759609-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|JJORE|Acme-Anything|0.02||0|||201101120124|1
892719|892719-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ISHIGAKI|Acme-CPANAuthors-Japanese|0.071226||0|||201101260945|1
962536|962536-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.05||0|||201101162101|1
1409538|1409538-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.01||0|||201101051729|1
1415536|1415536-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.03||0|||201101062227|1
1498300|1498300-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ISHIGAKI|Acme-CPANAuthors-Japanese|0.080522||0|||201101211910|1
1498366|1498366-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ISHIGAKI|Acme-CPANAuthors-CodeRepos|0.080522||0|||201101211928|1
1506861|1506861-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.06||0|||201101231024|1
1511634|1511634-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.04||0|||201101240233|1
1513135|1513135-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|DRRHO|AI-NeuralNet-SOM|0.07||0|||201101240907|1
1516187|1516187-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.05||0|||201101241805|1
1520619|1520619-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.06||0|||201101251816|1
1565336|1565336-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.07||0|||201101312254|1
1572634|1572634-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.08||0|||201101012045|1
1574627|1574627-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.09||0|||201101020147|1
1645288|1645288-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.10||0|||201101082355|1
2159274|2159274-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.11||0|||201101080024|1
2204397|2204397-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.01||0|||201101130310|1
2214457|2214457-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.02||0|||201101140323|1
2238296|2238296-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.03||0|||201101180204|1
2256533|2256533-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.04||0|||201101210208|1
2265432|2265432-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|GARU|Acme-BOPE|0.01||0|||201101220715|1
2269831|2269831-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.05||0|||201101222335|1
2459148|2459148-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.12||0|||201101191536|1
2518131|2518131-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.06||0|||201101292228|1
2538814|2538814-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|SAPER|Acme-CPANAuthors-French|0.07||0|||201101022251|1
2538875|2538875-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ZOFFIX|Acme-CPANAuthors-Canadian|0.0101||0|||201101022323|1
2676844|2676844-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ADRIANWIT|Abstract-Meta-Class|0.13||0|||201101240039|1
2963931|2963931-ed372d00-b19f-3f77-b713-d32bba55d77f|cpan|201101|ISHIGAKI|Acme-CPANAuthors-Japanese|0.090101||0|||201101311942|1
