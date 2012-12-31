#!perl

use strict;
use warnings;
use Test::More tests => 1;
use DBI;
use File::Spec;
use File::Path;
use File::Basename;

my $f = File::Spec->catfile('t','_DBDIR','test.db');
#unlink $f if -f $f;
mkpath( dirname($f) );

my $dbh = DBI->connect("dbi:SQLite:dbname=$f", '', '', {AutoCommit=>1});
$dbh->do(q{
    CREATE TABLE `ixlatest` (
      `dist`        text    NOT NULL,
      `version`     text    NOT NULL,
      `released`    int		NOT NULL,
      `author`      text    NOT NULL,
      `oncpan`      int     DEFAULT '0',
      PRIMARY KEY  (`dist`)
    );
});

while(<DATA>){
  chomp;
  $dbh->do('INSERT INTO ixlatest ( dist, version, released, author, oncpan ) VALUES ( ?, ?, ?, ?, ? )', {}, split(/\|/,$_) );
}

my ($ct) = $dbh->selectrow_array('select count(*) from ixlatest');

$dbh->disconnect;

is($ct, 15, "row ct");


#select * from ixlatest where author in ('LBROCARD', 'DRRHO', 'VOISCHEV', 'INGY', 'ISHIGAKI', 'SAPER', 'ZOFFIX', 'GARU', 'JESSE', 'JETEVE', 'JJORE', 'JBRYAN', 'JALDHAR', 'JHARDING', 'ADRIANWIT');
#dist|version|released|author|oncpan
__DATA__
Acme-Buffy|1.5|1177769034|LBROCARD|1
AI-NeuralNet-SOM|0.07|1211612835|DRRHO|1
Acme|1.11111|1137626100|INGY|1
Acme-CPANAuthors-CodeRepos|0.080522|1211390902|ISHIGAKI|1
Acme-CPANAuthors-Japanese|0.090101|1230748955|ISHIGAKI|1
Acme-CPANAuthors-French|0.07|1225662681|SAPER|1
Acme-CPANAuthors-Canadian|0.0101|1225664601|ZOFFIX|1
Acme-BOPE|0.01|1222060546|GARU|1
AEAE|0.02|1139566791|JETEVE|1
Acme-Anything|0.02|1194827066|JJORE|1
AI-NeuralNet-BackProp|0.89|966496907|JBRYAN|1
AI-NeuralNet-Mesh|0.44|968964981|JBRYAN|1
Acme-Brainfuck|1.1.1|1081268735|JALDHAR|1
AOL-TOC|0.340|966917420|JHARDING|1
Abstract-Meta-Class|0.13|1227483540|ADRIANWIT|1
