use strict;
use warnings;

use feature 'say';

use PersonFactory;

use Data::Dumper;

my $factory = PersonFactory->new();

#############################
# decoding: moose_from_proto:
#
my $test_proto_message =  "\x0a\x03foo\x10\x1f";

my $person = $factory->moose_from_proto($test_proto_message);

say "got moose object => " . Dumper($person);
