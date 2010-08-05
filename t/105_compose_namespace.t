use lib qw(t/lib);
use DBICTest;
use Test::More;

my $dsn = "dbi:SQLite:dbname=:memory:";

eval {
    local $SIG{__WARN__} = sub {};
    package DBICNSTest;
    use base qw/DBIx::Class::Schema/;
    __PACKAGE__->load_namespaces;
};
ok(!$@, 'load_namespaces does not die') or diag $@;

eval {
    package Derived::Schema::Result::A;
    use base qw/DBICNSTest::Result::A/;
    sub whoami { 'derived result' }
};
ok(!$@, 'Deriving result does not die') or diag $@;


my $derived_model = DBICNSTest->compose_namespace('Derived::Schema')->connect($dsn);
$derived_model->storage->dbh_do(sub { $_[1]->do('CREATE TABLE a (a INT)')});
$derived_model->populate('A', [ [ 'a' ], [  17 ] ]);

my $rset   = DBICNSTest->resultset('A');
isa_ok($rset, 'DBICNSTest::ResultSet::A');

my $rset   = $derived_model->resultset('A');
isa_ok($rset, 'Derived::Schema::ResultSet::A','Derived resultset');

my $result = $rset->search({})->first;
is($result->a(), 17, 'Value of base result seen in derived result');
isa_ok($result, 'Derived::Schema::Result::A', 'Derived schema result');
can_ok($result, 'whoami');

done_testing();
