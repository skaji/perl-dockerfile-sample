package App;
use 5.34.0;
use warnings;
use experimental 'signatures';

sub new ($class, %argv) {
    bless { %argv }, $class;
}

sub to_psgi ($self) {
    return sub ($env) {
        [200, [], ["Hello world!\n"]];
    };
}

1;
