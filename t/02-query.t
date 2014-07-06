use Test;

use RethinkDB;
use JSON::Tiny;

plan 1;

{
    # basic sanity test
    my $q = RethinkDB::Query.new(:type(RethinkDB::Proto::Query.QueryType.START));
    my $ser = $q.json;
    ok from-json($ser) eq { :type(RethinkDB::Proto::Query.QueryType.START) };
}
