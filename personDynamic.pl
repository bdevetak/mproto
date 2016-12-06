use strict;
use warnings;

BEGIN {
    eval {
        package Person;
        use Moose;
        1;
    }    
}

use Data::Dumper;

print __PACKAGE__;

my $meta = Person->meta;

$meta->add_attribute(name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
));

$meta->add_attribute(id => (
    is => 'ro',
    isa => 'Int',
    required => 1,
));

$meta->add_attribute(email => (
    is => 'rw',
    isa => 'Str',
    required => 0,
));

my @params = (
        name  => 'Joe',
        id    => 123,
    );

my $person = Person->new(@params);

print Dumper($person);

print $person->meta;
