#!perl

use strict;
use warnings;
$|=1;
use Test::More tests => 1;
use DBI;
use DBD::SQLite;
use File::Spec;
use File::Path;
use File::Basename;

my $f = File::Spec->catfile('t','_DBDIR','test.db');
unlink $f if -f $f;
mkpath( dirname($f) );

my $dbh = DBI->connect("dbi:SQLite:dbname=$f", '', '', {AutoCommit=>1});
$dbh->do(q{
  CREATE TABLE cpanstats (
                          id            INTEGER PRIMARY KEY,
                          state         TEXT,
                          postdate      TEXT,
                          tester        TEXT,
                          dist          TEXT,
                          version       TEXT,
                          platform      TEXT,
                          perl          TEXT,
                          osname        TEXT,
                          osvers        TEXT,
                          date          TEXT
  )
});

while(<DATA>){
  chomp;
  $dbh->do('INSERT INTO cpanstats ( id, state, postdate, tester, dist, version, platform, perl, osname, osvers, date ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )', {}, split(/\|/,$_) );
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
104440|unknown|200310|kriegjcb@mi.ruhr-uni-bochum.de ((Jost Krieger))|AI-NeuralNet-Mesh|0.44|sun4-solaris|5.8.1|solaris|2.8|200310061151
1396564|unknown|200805|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.5.5|freebsd|6.1-release|200805022114
1544358|na|200805|jj@jonallen.info ("JJ")|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.3|darwin|7.9.0|200805290833
1587804|na|200806|jj@jonallen.info ("JJ")|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.1|darwin|7.9.0|200806030648
1717321|na|200806|srezic@cpan.org|Abstract-Meta-Class|0.10|i386-freebsd|5.5.5|freebsd|6.1-release|200806171653
1994346|unknown|200808|srezic@cpan.org|AI-NeuralNet-SOM|0.02|i386-freebsd|5.6.2|freebsd|6.1-release|200808062212
2538246|fail|200811|bingos@cpan.org|Acme-CPANAuthors-French|0.06|i386-freebsd-thread-multi-64int|5.8.8|freebsd|6.2-release|200811021014
2549071|fail|200811|bingos@cpan.org|Acme-CPANAuthors-French|0.07|OpenBSD.i386-openbsd-thread-multi-64int|5.8.8|openbsd|4.2|200811042025
2603754|fail|200811|JOST@cpan.org ("Josts Smokehouse")|AI-NeuralNet-SOM|0.02|i86pc-solaris-64int|5.8.8 patch 34559|solaris|2.11|200811122105
2613077|fail|200811|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.8.9|freebsd|6.1-release-p23|200811132053
2725989|pass|200812|stro@cpan.org|Acme-CPANAuthors-Canadian|0.0101|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.00|200812011303
2959417|pass|200812|rhaen@cpan.org (Ulrich Habel)|Abstract-Meta-Class|0.11|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.1|200812301529
2964284|pass|200901|imacat@mail.imacat.idv.tw|Acme|1.11111|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010443
2964285|pass|200901|imacat@mail.imacat.idv.tw|Acme-Buffy|1.5|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010443
2964537|pass|200901|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-CodeRepos|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010609
2964541|pass|200901|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-Japanese|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010611
2965412|pass|200901|imacat@mail.imacat.idv.tw|Acme-Brainfuck|1.1.1|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010929
2965930|pass|200901|imacat@mail.imacat.idv.tw|AI-NeuralNet-BackProp|0.89|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011103
2965931|pass|200901|imacat@mail.imacat.idv.tw|AI-NeuralNet-Mesh|0.44|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011103
2966360|pass|200901|cpan@sourcentral.org ("Oliver Paukstadt")|AI-NeuralNet-SOM|0.07|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|200901010542
2966429|pass|200901|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-BOPE|0.01|s390x-linux|5.8.8|linux|2.6.16.60-0.31-default|200901010558
2966541|pass|200901|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-Canadian|0.0101|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|200901010628
2966560|fail|200901|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-French|0.07|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|200901010635
2966567|pass|200901|cpan@sourcentral.org ("Oliver Paukstadt")|Acme-CPANAuthors-CodeRepos|0.080522|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|200901010638
2966771|pass|200901|imacat@mail.imacat.idv.tw|AEAE|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011502
2967174|pass|200901|imacat@mail.imacat.idv.tw|AOL-TOC|0.340|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011645
2967432|fail|200901|andreas.koenig.gmwojprw@franz.ak.mind.de|Acme-CPANAuthors-French|0.07|x86_64-linux|5.10.0|linux|2.6.24-1-amd64|200901011038
2967647|pass|200901|imacat@mail.imacat.idv.tw|Acme-Anything|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011830
2969433|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010115
2969661|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010303
2969663|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010303
2970367|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.11.0 patch GitLive-blead-163-g28b1dae|linux|2.6.24-19-generic|200901010041
2975969|pass|200901|rhaen@cpan.org (Ulrich Habel)|Acme-CPANAuthors-Japanese|0.090101|MSWin32-x86-multi-thread|5.10.0|MSWin32|5.1|200901021220
11278|cpan|200006|JHARDING|AOL-TOC|0.32||0|||200006281749
11422|cpan|200007|JHARDING|AOL-TOC|0.33||0|||200007040912
11989|cpan|200007|JBRYAN|AI-NeuralNet-BackProp|0.40||0|||200007220918
12095|cpan|200007|JBRYAN|AI-NeuralNet-BackProp|0.42||0|||200007261138
12605|cpan|200008|JBRYAN|AI-NeuralNet-BackProp|0.77||0|||200008121011
12822|cpan|200008|JBRYAN|AI-NeuralNet-BackProp|0.89||0|||200008170921
13051|cpan|200008|JHARDING|AOL-TOC|0.340||0|||200008220610
13066|cpan|200008|JBRYAN|AI-NeuralNet-Mesh|0.20||0|||200008230741
13133|cpan|200008|JBRYAN|AI-NeuralNet-Mesh|0.31||0|||200008251025
13828|cpan|200009|JBRYAN|AI-NeuralNet-Mesh|0.43||0|||200009141053
13880|cpan|200009|JBRYAN|AI-NeuralNet-Mesh|0.44||0|||200009142256
14426|cpan|200009|VOISCHEV|AI-NeuralNet-SOM|0.01||0|||200009292037
14530|cpan|200010|VOISCHEV|AI-NeuralNet-SOM|0.02||0|||200010042041
23502|cpan|200105|LBROCARD|Acme-Buffy|1.1||0|||200105221815
26042|cpan|200108|LBROCARD|Acme-Buffy|1.2||0|||200108121353
36109|cpan|200203|LBROCARD|Acme-Buffy|1.3||0|||200203271437
58944|cpan|200209|JALDHAR|Acme-Brainfuck|1.0.0||0|||200209032115
104368|cpan|200310|JESSE|Acme-Buffy|1.3||0|||200310051219
128571|cpan|200403|INGY|Acme|1.00||0|||200403211232
128577|cpan|200403|INGY|Acme|1.11||0|||200403211307
128615|cpan|200403|INGY|Acme|1.111||0|||200403212239
131264|cpan|200404|JALDHAR|Acme-Brainfuck|1.1.0||0|||200404060730
131340|cpan|200404|JALDHAR|Acme-Brainfuck|1.1.1||0|||200404061825
194191|cpan|200503|INGY|Acme|1.1111||0|||200503270846
283938|cpan|200601|INGY|Acme|1.11111||0|||200601190015
286799|cpan|200601|JETEVE|AEAE|0.01||0|||200601311729
288796|cpan|200602|JETEVE|AEAE|0.02||0|||200602101119
347205|cpan|200609|LBROCARD|Acme-Buffy|1.4||0|||200609081831
469300|cpan|200704|LBROCARD|Acme-Buffy|1.5||0|||200704281603
502506|cpan|200706|DRRHO|AI-NeuralNet-SOM|0.01||0|||200706051723
505918|cpan|200706|DRRHO|AI-NeuralNet-SOM|0.02||0|||200706101701
509756|cpan|200706|DRRHO|AI-NeuralNet-SOM|0.03||0|||200706142113
510429|cpan|200706|DRRHO|AI-NeuralNet-SOM|0.04||0|||200706171333
552718|cpan|200708|JJORE|Acme-Anything|0.01||0|||200708020003
759609|cpan|200711|JJORE|Acme-Anything|0.02||0|||200711120124
892719|cpan|200712|ISHIGAKI|Acme-CPANAuthors-Japanese|0.071226||0|||200712260945
962536|cpan|200801|DRRHO|AI-NeuralNet-SOM|0.05||0|||200801162101
1409538|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.01||0|||200805051729
1415536|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.03||0|||200805062227
1498300|cpan|200805|ISHIGAKI|Acme-CPANAuthors-Japanese|0.080522||0|||200805211910
1498366|cpan|200805|ISHIGAKI|Acme-CPANAuthors-CodeRepos|0.080522||0|||200805211928
1506861|cpan|200805|DRRHO|AI-NeuralNet-SOM|0.06||0|||200805231024
1511634|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.04||0|||200805240233
1513135|cpan|200805|DRRHO|AI-NeuralNet-SOM|0.07||0|||200805240907
1516187|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.05||0|||200805241805
1520619|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.06||0|||200805251816
1565336|cpan|200805|ADRIANWIT|Abstract-Meta-Class|0.07||0|||200805312254
1572634|cpan|200806|ADRIANWIT|Abstract-Meta-Class|0.08||0|||200806012045
1574627|cpan|200806|ADRIANWIT|Abstract-Meta-Class|0.09||0|||200806020147
1645288|cpan|200806|ADRIANWIT|Abstract-Meta-Class|0.10||0|||200806082355
2159274|cpan|200809|ADRIANWIT|Abstract-Meta-Class|0.11||0|||200809080024
2204397|cpan|200809|SAPER|Acme-CPANAuthors-French|0.01||0|||200809130310
2214457|cpan|200809|SAPER|Acme-CPANAuthors-French|0.02||0|||200809140323
2238296|cpan|200809|SAPER|Acme-CPANAuthors-French|0.03||0|||200809180204
2256533|cpan|200809|SAPER|Acme-CPANAuthors-French|0.04||0|||200809210208
2265432|cpan|200809|GARU|Acme-BOPE|0.01||0|||200809220715
2269831|cpan|200809|SAPER|Acme-CPANAuthors-French|0.05||0|||200809222335
2459148|cpan|200810|ADRIANWIT|Abstract-Meta-Class|0.12||0|||200810191536
2518131|cpan|200810|SAPER|Acme-CPANAuthors-French|0.06||0|||200810292228
2538814|cpan|200811|SAPER|Acme-CPANAuthors-French|0.07||0|||200811022251
2538875|cpan|200811|ZOFFIX|Acme-CPANAuthors-Canadian|0.0101||0|||200811022323
2676844|cpan|200811|ADRIANWIT|Abstract-Meta-Class|0.13||0|||200811240039
2963931|cpan|200812|ISHIGAKI|Acme-CPANAuthors-Japanese|0.090101||0|||200812311942