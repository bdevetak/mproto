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

# TODO: make proper Moose subtypes so there is a more precise mapping
my %proto_to_moose_type_map = (
    "double"    => 'Num',
    "float"     => 'Num',
    "int32"     => 'Int',
    "int64"     => 'Int',
    "uint32"    => 'Int',
    "uint64"    => 'Int',
    "sint32"    => 'Int',
    "sint64"    => 'Int',
    "fixed32"   => 'Int',
    "fixed64"   => 'Int',
    "sfixed32"  => 'Int',
    "sfixed64"  => 'Int',
    "bool"      => 'Bool',
    "string"    => 'Str',
    "bytes"     => 'Str',
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
my $proto_string = get_test_message_2();

say "proto string => " .  $proto_string;

my ($parsedPackageDef) = Google::ProtocolBuffers::Compiler->parse({ text => $proto_string });

my $parsedMessageDef;
my @mooseClassesDefinitions = ();
for my $message_name (keys %$parsedPackageDef) {

    $parsedMessageDef = $parsedPackageDef->{$message_name};

    if ($parsedMessageDef->{kind} eq 'message') {

        # replace codes with meaningfull strings
        map
        {
                ($_->[0] = { required      => $label_codes{$_->[0]}     })
                &&
                ($_->[1] = { field_type    => ($_->[1]=~m/[a-zA-z]/g ? $_->[1] : $primitive_codes{$_->[1]}) })
                &&
                ($_->[2] = { field_name    => $_->[2]                   })
                &&
                ($_->[3] = { field_id      => $_->[3]                   })
                &&
                ($_->[4] = { default_value => $_->[4]                   })
        }
        @{$parsedMessageDef->{fields}};

        my $mooseClassDef;
        $mooseClassDef->{package_name} = ucfirst(join('::',split("\\.",$message_name)));
        map
        {
            push @{$mooseClassDef->{attributes}}, {
                name => $_->[2]->{field_name},
                isa  => (
                    ($_->[1]->{field_type}=~/m[a-zA-Z]/g)
                        ? ucfirst(join('::',split("\\.",$_->[1]->{field_type})))
                        : $proto_to_moose_type_map{$_->[1]->{field_type}}
                ),
                presence => $_->[0]->{required},
                default  => $_->[4]->{default_value},
            }
        }
        @{$parsedMessageDef->{fields}};

        push @mooseClassesDefinitions, $mooseClassDef;
    }
    elsif ($parsedMessageDef->{kind} eq 'enum') {

        map
        {
            ($_->[0] = { enum_value    => $_->[0]                   })
            &&
            ($_->[1] = { value_id      => $_->[1]                   })
            
        }
        @{$parsedMessageDef->{fields}};
        
        my $mooseClassDef;
        $mooseClassDef->{package_name} = ucfirst(join('::',split("\\.",$message_name)));
        map
        {
            push @{$mooseClassDef->{enum_items}}, {
                enum_value => $_->[0]->{enum_value},
                value_id   => $_->[1]->{value_id},
            }
        }
        @{$parsedMessageDef->{fields}};

        # enum 'My:Enum:Task', [qw(profit world_domination)];
        # has task => ( isa => 'My:Enum:Task' );

        $mooseClassDef->{create_as} = '
        use Moose::Util::TypeConstraints;
        enum ' .
            "'" .
            $mooseClassDef->{package_name} .
            "' , [qw(" .
            join(" ", map { $_->{enum_value} } @{$mooseClassDef->{enum_items}} ) .
            ")];"
        ;

        push @mooseClassesDefinitions, $mooseClassDef;
    }
    else {
        die "Unsupported type " . $parsedMessageDef->{kind};
    }
}

#TODO:
# 1. establish the order of dependecies
# 2. create Moose classes:
#       a. enums and packages by evals
#       b. attributes by meta
print Dumper(\@mooseClassesDefinitions);

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

sub get_test_message_2 {

    return q|
        
        syntax = "proto2";
         
        package humans;

        message Person {
          required string name = 1;
          required int32 id = 2;
          optional string email = 3;

          enum PhoneType {
            MOBILE = 0;
            HOME = 1;
            WORK = 2;
          }

          message PhoneNumber {
            required string number = 1;
            optional PhoneType type = 2 [default = HOME];
          }

          repeated PhoneNumber phone = 4;
        }
    
    |;
}
