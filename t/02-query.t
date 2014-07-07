use Test;

use RethinkDB;
use RethinkDB::AST;
use RethinkDB::Proto;
use JSON::Tiny;

my $tt = RethinkDB::Proto::Term.TermType;
my $qt = RethinkDB::Proto::Query.QueryType;

plan 5;

{
    # basic sanity test
    my $q = RethinkDB::Query.new(:type($qt.START), :token(1));
    my $ser = $q.json;
    ok from-json($ser) eqv [ $qt.START, ().hash.item ], "round trip serialize";
}

{
    # db
    my $t = RQL::DB.new("dbname");
    is $t.term-type, $tt.DB, "db correct term type";
    ok $t.args.perl eq Array.new(RQL::Datum.new("dbname")).perl, "db args correct";
    ok $t.build.perl eq Array.new($tt.DB, $("dbname",)).perl, "db build generates correct structure";
}
{
    # db serialize
    my $t = RQL::DB.new('dbname');
    my $q = RethinkDB::Query.new(:type($qt.START),:token(1),:term($t));
    ok from-json($q.json) eqv [$qt.START, [$tt.DB, ['dbname']], ().hash.item], "db query json";
}
