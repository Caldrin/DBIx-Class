use Test::More;
use lib qw(t/lib);
use DBICTest;
use DBICTest::HelperRels;

require "t/run/22cascade_copy.tl";
run_tests(DBICTest->schema);