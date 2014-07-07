use Test;

use RethinkDB;
use RethinkDB::AST;
use RethinkDB::Proto;
use JSON::Tiny;

my $tt = RethinkDB::Proto::Term.TermType;

plan 5;

{
    # validate tests
    my $q = RethinkDB::Query.new;
    dies_ok({ $q.validate }, "validate no type");
}

{
    # basic sanity test
    my $q = RethinkDB::Query.new(:type(RethinkDB::Proto::Query.QueryType.START));
    my $ser = $q.json;
    ok from-json($ser) eqv [ RethinkDB::Proto::Query.QueryType.START ], "round trip serialize";
}

{
    # db
    my $q = RQL::DB.new("dbname");
    is $q.term-type, $tt.DB, "db correct term type";
    ok $q.args.perl eq Array.new(RQL::Datum.new("dbname")).perl, "db args correct";
    ok $q.build.perl eq Array.new($tt.DB, $("dbname",)).perl, "db build generates correct structure";
}
