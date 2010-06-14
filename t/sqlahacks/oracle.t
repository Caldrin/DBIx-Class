
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper::Concise;
use lib qw(t/lib);
use DBIC::SqlMakerTest;
use DBIx::Class::SQLAHacks::Oracle;

# 
#  Offline test for connect_by 
#  ( without acitve database connection)
# 
my @handle_tests = (
    {
        connect_by  => { 'parentid' => { '-prior' => \'artistid' } },
        stmt        => '"parentid" = PRIOR artistid',
        bind        => [],
        msg         => 'Simple: "parentid" = PRIOR artistid',
    },
    {
        connect_by  => { 'parentid' => { '!=' => { '-prior' => \'artistid' } } },
        stmt        => '"parentid" != ( PRIOR artistid )',
        bind        => [],
        msg         => 'Simple: "parentid" != ( PRIOR artistid )',
    },
    # Examples from http://download.oracle.com/docs/cd/B19306_01/server.102/b14200/queries003.htm

    # CONNECT BY last_name != 'King' AND PRIOR employee_id = manager_id ...
    {
        connect_by  => [
            last_name => { '!=' => 'King' },
            manager_id => { '-prior' => \'employee_id' },
        ],
        stmt        => '( "last_name" != ? OR "manager_id" = PRIOR employee_id )',
        bind        => ['King'],
        msg         => 'oracle.com example #1',
    },
    # CONNECT BY PRIOR employee_id = manager_id and 
    #            PRIOR account_mgr_id = customer_id ...
    {
        connect_by  => {
            manager_id => { '-prior' => \'employee_id' },
            customer_id => { '>', { '-prior' => \'account_mgr_id' } },
        },
        stmt        => '( "customer_id" > ( PRIOR account_mgr_id ) AND "manager_id" = PRIOR employee_id )',
        bind        => [],
        msg         => 'oracle.com example #2',
    },
    # CONNECT BY NOCYCLE PRIOR employee_id = manager_id AND LEVEL <= 4;
    # TODO: NOCYCLE parameter doesn't work
);

my $sqla_oracle = DBIx::Class::SQLAHacks::Oracle->new( quote_char => '"', name_sep => '.' );
isa_ok($sqla_oracle, 'DBIx::Class::SQLAHacks::Oracle');


for my $case (@handle_tests) {
    my ( $stmt, @bind );
    my $msg = sprintf("Offline: %s",
        $case->{msg} || substr($case->{stmt},0,25),
    );
    lives_ok(
        sub {
            ( $stmt, @bind ) = $sqla_oracle->_recurse_where( $case->{connect_by} );
            is_same_sql_bind( $stmt, \@bind, $case->{stmt}, $case->{bind},$msg )
              || diag "Search term:\n" . Dumper $case->{connect_by};
        }
    ,sprintf("lives is ok from '%s'",$msg));
}

is (
  $sqla_oracle->_shorten_identifier('short_id'),
  'short_id',
  '_shorten_identifier for short id without keywords ok'
);

is (
  $sqla_oracle->_shorten_identifier('short_id', [qw/ foo /]),
  'short_id',
  '_shorten_identifier for short id with one keyword ok'
);

is (
  $sqla_oracle->_shorten_identifier('short_id', [qw/ foo bar baz /]),
  'short_id',
  '_shorten_identifier for short id with keywords ok'
);

is (
  $sqla_oracle->_shorten_identifier('very_long_identifier_which_exceeds_the_30char_limit'),
  'VryLngIdntfrWhchExc_72M8CIDTM7',
  '_shorten_identifier without keywords ok',
);

is (
  $sqla_oracle->_shorten_identifier('very_long_identifier_which_exceeds_the_30char_limit',[qw/ foo /]),
  'Foo_72M8CIDTM7KBAUPXG48B22P4E',
  '_shorten_identifier with one keyword ok',
);
is (
  $sqla_oracle->_shorten_identifier('very_long_identifier_which_exceeds_the_30char_limit',[qw/ foo bar baz /]),
  'FooBarBaz_72M8CIDTM7KBAUPXG48B',
  '_shorten_identifier with keywords ok',
);

done_testing;
