use JSON::Tiny;

class RethinkDB::Response;

has Int $.token;
has $.type;
has $.data;
has $.backtrace;
has $.profile;

method new(Int :$token!, utf8 :$json!) {
    my %resp = from-json($json.decode);
    self.bless(:$token, :type(%resp{'t'}), :data(%resp{'r'}),
               :backtrace(%resp{'b'}), :profile(%resp{'p'}));
}
