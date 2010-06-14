use lib qw(t/lib);
use DBICTest;
use Test::More;
use Test::Exception;

my $model         = DBICTest->init_schema->connect;

throws_ok {$model->source()} qr/source\(\) expects a source name/, 'Empty args for source caught';

done_testing();
