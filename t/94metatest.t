use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

eval "use Test::CPAN::Meta 0.12";
plan skip_all => "Test::CPAN::Meta 0.12 required for testing META.yml" if $@;
meta_yaml_ok();


