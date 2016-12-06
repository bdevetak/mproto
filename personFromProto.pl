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
my $hex = $test_proto_message;
$hex =~ s/(.)/sprintf("%x",ord($1))/eg;
say "test proto message => " . Dumper($hex);

my $person = $factory->moose_from_proto($test_proto_message);
say "got moose object => " . Dumper($person);

my $bytes = $factory->moose_to_proto($person);
$hex = $bytes;
$hex =~ s/(.)/sprintf("%x",ord($1))/eg;
say "got bytes back => " . Dumper($hex);
