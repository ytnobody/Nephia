use strict;
use warnings;
use Test::More;
use Voson::Incognito;
use Plack::Test;
use HTTP::Request::Common;

Voson::Incognito->incognito(
    app => sub {
        my $name = param('name') || 'tonkichi';
        [200,[],"Hello, $name"];
    },
);

my $v = Voson::Incognito->unmask;
my $app = $v->run;

subtest default => sub {
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        is $res->content, 'Hello, tonkichi';
        $res = $cb->(GET '/?name=ytnobody');
        is $res->content, 'Hello, ytnobody';
    };
};

done_testing;
