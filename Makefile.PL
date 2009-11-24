use 5.006; #due to 'warnings' pragma
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'             => 'CPAN::Testers::WWW::Statistics',
    'VERSION_FROM'     => 'lib/CPAN/Testers/WWW/Statistics.pm',
    'PREREQ_PM'        => {

        Class::Accessor::Fast           => 0,
        Config::IniFiles                => 0,
        CPAN::Testers::Common::DBUtils  => 0.03,
        GD::Graph::lines                => 0,
        File::Basename                  => 0,
        File::Copy                      => 0,
        File::Path                      => 0,
        Getopt::ArgvFile                => 0,
        Getopt::Long                    => 0,
        HTML::Entities                  => 0,
        IO::File                        => 0,
        Sort::Versions                  => 0,
        Template                        => 2.19,
        WWW::Mechanize                  => 0,

        # for the CGI tools
        CGI                             => 0,
        Email::Simple                   => 0,
        Time::Piece                     => 0,

        DBD::mysql                      => 0,
        DBD::SQLite                     => 0,

        Test::Differences               => 0,     # for testing
        Archive::Zip                    => 0,     # for testing
        Archive::Extract                => 0,     # for testing
        File::Slurp                     => 0,     # for testing
        File::Spec                      => 0,     # for testing
    },

    NO_META         => 1,

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT     => 'Scripts to create the cpanstats website',
       AUTHOR       => 'Barbie <barbie@cpan.org>') : ()),
);
