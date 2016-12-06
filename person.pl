use Person;
use Data::Dumper;

my @params = (
        name  => 'Joe',
        id    => 123,
    );

my $person = Person->new(@params);

print Dumper($person);

print $person->meta;
