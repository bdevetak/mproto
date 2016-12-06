use Moose;
use Moose::Util::TypeConstraints;

subtype 'Natural',
  as 'Int',
  where { $_ > 0 };

subtype 'NaturalLessThanTen',
  as 'Natural',
  where { $_ < 10 },
  message { "This number ($_) is not less than ten!" };

coerce 'Num',
  from 'Str',
  via { 0+$_ };

class_type 'DateTimeClass', { class => 'DateTime' };

role_type 'Barks', { role => 'Some::Library::Role::Barks' };

enum 'RGBColors', [qw(red green blue)];

union 'StringOrArray', [qw( String ArrayRef )];

1;
