package Person;

use Moose;

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'id' => (
    is => 'ro',
    isa => "Int",
    required => 1,
);

has 'email' => (
    is => 'rw',
    isa => 'Str',
    required => 0,
);

1;
