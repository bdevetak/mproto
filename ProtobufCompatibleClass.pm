package ProtobufCompatibleClass;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'UInt',
    as 'Int',
    where { $_ > 0 },
    message { "The number you provided, $_, was not a positive number" }
;

1;
