use Test;

plan 1;

use RethinkDB;

my $r = RethinkDB.new;

ok $r.connect('localhost', 8080), 'basic connection';
