use strict;
use Test;
BEGIN { plan tests => 2 }
require Shell::Parser;

# check that the following functions are available
ok( defined \&Shell::Parser::new                              ); #01
ok( defined \&Shell::Parser::parse                            ); #02
#ok( defined \&Shell::Parser::XXX                              ); #03
