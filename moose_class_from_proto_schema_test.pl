use strict;
use warnings;

use feature 'say';

use Google::ProtocolBuffers::Compiler;
use Google::ProtocolBuffers::Dynamic;
use Google::ProtocolBuffers::Constants qw/:types :labels/;

use Data::Dumper;

my %primitive_types = (
    "double"    => TYPE_DOUBLE,
    "float"     => TYPE_FLOAT,
    "int32"     => TYPE_INT32,
    "int64"     => TYPE_INT64,
    "uint32"    => TYPE_UINT32,
    "uint64"    => TYPE_UINT64,
    "sint32"    => TYPE_SINT32,
    "sint64"    => TYPE_SINT64,
    "fixed32"   => TYPE_FIXED32,
    "fixed64"   => TYPE_FIXED64,
    "sfixed32"  => TYPE_SFIXED32,
    "sfixed64"  => TYPE_SFIXED64,
    "bool"      => TYPE_BOOL,
    "string"    => TYPE_STRING,
    "bytes"     => TYPE_BYTES,
);

# TODO: extend this with mapping to Moose types
my %primitive_codes = map { $primitive_types{$_} => $_ } keys %primitive_types;

my %labels = (
    'required'  => LABEL_REQUIRED,
    'optional'  => LABEL_OPTIONAL,
    'repeated'  => LABEL_REPEATED,
);

my %label_codes = map { $labels{$_} => $_ } keys %labels;

my $moose_class_name = "Person";
my $proto_message_name = lc($moose_class_name) . "proto";

#my $proto_string = generate_proto_string_from_moose_object();
my $proto_string = get_test_message();

print $proto_string;

my @x = Google::ProtocolBuffers::Compiler->parse({ text => $proto_string });

my $parsedMessageDef = $x[0];

map {
    push @{$parsedMessageDef->{'humans.Person'}->{readable}}, +{
        required   => $label_codes{$_->[0]},
        field_type => $primitive_codes{$_->[1]},
        field_name => $_->[2],
        field_id   => $_->[3],
        unknown_1  => $_->[4],
        unknown_2  => $_->[5],
    }
} @{$parsedMessageDef->{'humans.Person'}->{fields}};

say "parsed proto schema => " . Dumper($parsedMessageDef);

#####################################################
# Serializer:
my $dynamic = Google::ProtocolBuffers::Dynamic->new();
$dynamic->load_string(
    $proto_message_name,
    $proto_string
);
$dynamic->map({ package => 'humans', prefix => 'Humans' });

##########################################################
# TESTS:

# encoding/decoding
my $person = Humans::Person->decode("\x0a\x03foo\x10\x1f");
# say Dumper($person);

$person = Humans::Person->decode_json('{"id":31,"name":"John Doe"}');
# say Dumper($person);

my $bytes = Humans::Person->encode($person);
# say Dumper($bytes);

$bytes = Humans::Person->encode_json($person);
# say Dumper($bytes);
 
# field accessors
$person = Humans::Person->new;
$person->set_id(77);

my $id = $person->get_id;
# print Dumper($id);

####################################################
# SUBS:
#
# moose obect => proto schema
sub generate_proto_string_from_moose_object {

    my $proto = q|
syntax = "proto2";

package humans;

message |;

    $proto .= $moose_class_name . "{\n";

    # array of Moose class attributes, sorted in the way they are in 
    # in the proto message
    my $moose_obj_attributes_example = [
        {
             name     => "name"  ,
             type     => "Str"   ,
             required => "1"     ,
             proto_id => 1       ,
        },
        {
             name     => "id"    ,
             type     => "Int"   ,
             required => "1"     ,
             proto_id => 2       ,
        },
        {
             name     => "email" ,
             type     => "Str"   ,
             required => "0"     ,     
             proto_id => 3       ,
        },
    ];


    # TODO: move this mapping to constants module
    my %moose_type_to_proto_type = (
        Str => 'string',
        Int => 'int32',
    );

    for my $att (@$moose_obj_attributes_example) {
        #print Dumper($att);
        $proto .= "\t";
        $proto .= ($att->{required} ? "required" : "optional");
        $proto .= " ";
        $proto .= $moose_type_to_proto_type{$att->{type}};
        $proto .= " ";
        $proto .= $att->{name};
        $proto .= " = ";
        $proto .= $att->{proto_id};
        $proto .= ";\n";

    }

    $proto .= "}\n";
    return $proto;
}

sub get_test_message {

    return  q|

        syntax = "proto2";
         
        package humans;
         
        message Person{
          required string name  = 1;
          required int32  id    = 2;
          optional string email = 3;
        }

|;

}
