constant CURDIR = $*SPEC.splitpath($?FILE)[1];
constant FN = $*SPEC.catdir(CURDIR, 'Proto', 'ql2_13x.proto');

module RethinkDB::Proto {
    use PB::Model::Generator FN;

    class RethinkDB::Proto::VersionDummy is VersionDummy {}

    class RethinkDB::Proto::Query is Query {}

    class RethinkDB::Proto::Frame is Frame {}

    class RethinkDB::Proto::Backtrace is Backtrace {}

    class RethinkDB::Proto::Response is Response {}

    class RethinkDB::Proto::Datum is Datum {}

    class RethinkDB::Proto::Term is Term {}
}
