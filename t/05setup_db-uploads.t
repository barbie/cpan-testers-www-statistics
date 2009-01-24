#!perl

use strict;
use warnings;
use Test::More tests => 1;
use DBI;
use DBD::SQLite;
use File::Spec;
use File::Path;
use File::Basename;

my $f = File::Spec->catfile('t','_DBDIR','test2.db');
unlink $f if -f $f;
mkpath( dirname($f) );

my $dbh = DBI->connect("dbi:SQLite:dbname=$f", '', '', {AutoCommit=>1});
$dbh->do(q{
    CREATE TABLE `uploads` (
     `type`        text    NOT NULL,
     `author`      text    NOT NULL,
     `dist`        text    NOT NULL,
     `version`     text    NOT NULL,
     `filename`    text    NOT NULL,
     `released`    int     NOT NULL,
     PRIMARY KEY  (`author`,`dist`,`version`)
    );
});

while(<DATA>){
  chomp;
  $dbh->do('INSERT INTO uploads ( type, author, dist, version, filename, released ) VALUES ( ?, ?, ?, ?, ?, ? )', {}, split(/\|/,$_) );
}

my ($ct) = $dbh->selectrow_array('select count(*) from uploads');

$dbh->disconnect;

is($ct, 63, "row ct");


#select * from uploads where dist in ('AEAE', 'AI-NeuralNet-BackProp', 'AI-NeuralNet-Mesh', 'AI-NeuralNet-SOM', 'AOL-TOC', 'Abstract-Meta-Class', 'Acme', 'Acme-Anything', 'Acme-BOPE', 'Acme-Brainfuck', 'Acme-Buffy', 'Acme-CPANAuthors-Canadian', 'Acme-CPANAuthors-CodeRepos', 'Acme-CPANAuthors-French', 'Acme-CPANAuthors-Japanese');
#type|author|dist|version|filename|released
__DATA__
cpan|LBROCARD|Acme-Buffy|1.3|Acme-Buffy-1.3.tar.gz|1017236268
cpan|LBROCARD|Acme-Buffy|1.5|Acme-Buffy-1.5.tar.gz|1177769034
cpan|LBROCARD|Acme-Buffy|1.4|Acme-Buffy-1.4.tar.gz|1157733085
backpan|LBROCARD|Acme-Buffy|1.1|Acme-Buffy-1.1.tar.gz|990548103
backpan|LBROCARD|Acme-Buffy|1.2|Acme-Buffy-1.2.tar.gz|997617194
cpan|DRRHO|AI-NeuralNet-SOM|0.04|AI-NeuralNet-SOM-0.04.tar.gz|1182080003
cpan|DRRHO|AI-NeuralNet-SOM|0.06|AI-NeuralNet-SOM-0.06.tar.gz|1211531083
cpan|DRRHO|AI-NeuralNet-SOM|0.05|AI-NeuralNet-SOM-0.05.tar.gz|1200513667
cpan|DRRHO|AI-NeuralNet-SOM|0.01|AI-NeuralNet-SOM-0.01.tar.gz|1181057025
cpan|DRRHO|AI-NeuralNet-SOM|0.03|AI-NeuralNet-SOM-0.03.tar.gz|1181848391
cpan|DRRHO|AI-NeuralNet-SOM|0.07|AI-NeuralNet-SOM-0.07.tar.gz|1211612835
cpan|DRRHO|AI-NeuralNet-SOM|0.02|AI-NeuralNet-SOM-0.02.tar.gz|1181487612
cpan|VOISCHEV|AI-NeuralNet-SOM|0.01|AI-NeuralNet-SOM-0.01.tar.gz|970252633
cpan|VOISCHEV|AI-NeuralNet-SOM|0.02|AI-NeuralNet-SOM-0.02.tar.gz|970684892
cpan|INGY|Acme|1.11111|Acme-1.11111.tar.gz|1137626100
backpan|INGY|Acme|1.111|Acme-1.111.tar.gz|1079905156
backpan|INGY|Acme|1.11|Acme-1.11.tar.gz|1079870865
backpan|INGY|Acme|1.00|Acme-1.00.tar.gz|1079868743
backpan|INGY|Acme|1.1111|Acme-1.1111.tar.gz|1111906013
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.071226|Acme-CPANAuthors-Japanese-0.071226.tar.gz|1198658704
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.080522|Acme-CPANAuthors-Japanese-0.080522.tar.gz|1211389830
cpan|ISHIGAKI|Acme-CPANAuthors-CodeRepos|0.080522|Acme-CPANAuthors-CodeRepos-0.080522.tar.gz|1211390902
cpan|SAPER|Acme-CPANAuthors-French|0.04|Acme-CPANAuthors-French-0.04.tar.gz|1221955693
backpan|SAPER|Acme-CPANAuthors-French|0.01|Acme-CPANAuthors-French-0.01.tar.gz|1221268256
cpan|SAPER|Acme-CPANAuthors-French|0.05|Acme-CPANAuthors-French-0.05.tar.gz|1222119306
backpan|SAPER|Acme-CPANAuthors-French|0.02|Acme-CPANAuthors-French-0.02.tar.gz|1221355420
backpan|SAPER|Acme-CPANAuthors-French|0.03|Acme-CPANAuthors-French-0.03.tar.gz|1221696260
cpan|SAPER|Acme-CPANAuthors-French|0.06|Acme-CPANAuthors-French-0.06.tar.gz|1225315698
upload|SAPER|Acme-CPANAuthors-French|0.07|Acme-CPANAuthors-French-0.07.tar.gz|1225662681
upload|ZOFFIX|Acme-CPANAuthors-Canadian|0.0101|Acme-CPANAuthors-Canadian-0.0101.tar.gz|1225664601
cpan|GARU|Acme-BOPE|0.01|Acme-BOPE-0.01.tar.gz|1222060546
backpan|JESSE|Acme-Buffy|1.3|Acme-Buffy-1.3.tar.gz|1065349193
cpan|JETEVE|AEAE|0.02|AEAE-0.02.tar.gz|1139566791
cpan|JETEVE|AEAE|0.01|AEAE-0.01.tar.gz|1138724959
backpan|JJORE|Acme-Anything|0.01|Acme-Anything-0.01.tar.gz|1186005823
cpan|JJORE|Acme-Anything|0.02|Acme-Anything-0.02.tar.gz|1194827066
cpan|JBRYAN|AI-NeuralNet-Mesh|0.43|AI-NeuralNet-Mesh-0.43.zip|968921615
cpan|JBRYAN|AI-NeuralNet-BackProp|0.40|AI-NeuralNet-BackProp-0.40.zip|964250318
cpan|JBRYAN|AI-NeuralNet-Mesh|0.31|AI-NeuralNet-Mesh-0.31.zip|967191936
cpan|JBRYAN|AI-NeuralNet-BackProp|0.77|AI-NeuralNet-BackProp-0.77.zip|966067868
cpan|JBRYAN|AI-NeuralNet-BackProp|0.42|AI-NeuralNet-BackProp-0.42.zip|964604318
cpan|JBRYAN|AI-NeuralNet-Mesh|0.44|AI-NeuralNet-Mesh-0.44.zip|968964981
cpan|JBRYAN|AI-NeuralNet-BackProp|0.89|AI-NeuralNet-BackProp-0.89.zip|966496907
cpan|JBRYAN|AI-NeuralNet-Mesh|0.20|AI-NeuralNet-Mesh-0.20.zip|967009309
backpan|JALDHAR|Acme-Brainfuck|1.1.0|Acme-Brainfuck-1.1.0.tar.gz|1081229428
cpan|JALDHAR|Acme-Brainfuck|1.1.1|Acme-Brainfuck-1.1.1.tar.gz|1081268735
backpan|JALDHAR|Acme-Brainfuck|1.0.0|Acme-Brainfuck-1.0.0.tar.gz|1031080554
cpan|JHARDING|AOL-TOC|0.32|AOL-TOC-0.32.tar.gz|962207388
cpan|JHARDING|AOL-TOC|0.340|AOL-TOC-0.340.tar.gz|966917420
cpan|JHARDING|AOL-TOC|0.33|AOL-TOC-0.33.tar.gz|962694743
cpan|ADRIANWIT|Abstract-Meta-Class|0.09|Abstract-Meta-Class-0.09.tar.gz|1212364076
backpan|ADRIANWIT|Abstract-Meta-Class|0.07|Abstract-Meta-Class-0.07.tar.gz|1212267288
backpan|ADRIANWIT|Abstract-Meta-Class|0.04|Abstract-Meta-Class-0.04.tar.gz|1211589222
cpan|ADRIANWIT|Abstract-Meta-Class|0.08|Abstract-Meta-Class-0.08.tar.gz|1212345949
backpan|ADRIANWIT|Abstract-Meta-Class|0.01|Abstract-Meta-Class-0.01.tar.gz|1210001395
backpan|ADRIANWIT|Abstract-Meta-Class|0.05|Abstract-Meta-Class-0.05.tar.gz|1211645127
cpan|ADRIANWIT|Abstract-Meta-Class|0.10|Abstract-Meta-Class-0.10.tar.gz|1212962154
cpan|ADRIANWIT|Abstract-Meta-Class|0.12|Abstract-Meta-Class-0.12.tar.gz|1224423414
cpan|ADRIANWIT|Abstract-Meta-Class|0.11|Abstract-Meta-Class-0.11.tar.gz|1220826243
backpan|ADRIANWIT|Abstract-Meta-Class|0.03|Abstract-Meta-Class-0.03.tar.gz|1210105676
backpan|ADRIANWIT|Abstract-Meta-Class|0.06|Abstract-Meta-Class-0.06.tar.gz|1211732184
upload|ADRIANWIT|Abstract-Meta-Class|0.13|Abstract-Meta-Class-0.13.tar.gz|1227483540
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.090101|Acme-CPANAuthors-Japanese-0.090101.tar.gz|1230748955
