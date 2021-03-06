use strict;
use warnings;
use Test::More;
use Nephia::Core;
use t::Util 'mock_env';

my $env = mock_env;

my $app = sub {
    my ($self, $context) = @_;
    [200, [], 'Hello, World!'];
};

subtest normal => sub {
    my $v = Nephia::Core->new(app => $app);

    isa_ok $v, 'Nephia::Core';
    is $v->caller_class, __PACKAGE__;
    isa_ok $v->loaded_plugins, 'Nephia::Chain';
    isa_ok $v->action_chain, 'Nephia::Chain';
    isa_ok $v->filter_chain, 'Nephia::Chain';
    is $v->dsl, $v->{dsl};
    is_deeply [ map {ref($_)} $v->loaded_plugins->as_array ], [qw[Nephia::Plugin::Basic Nephia::Plugin::Cookie]], 'Basic and Cookie plugins loaded';
    is $v->app, $app;

    my $psgi = $v->run;
    isa_ok $psgi, 'CODE';

    $v->export_dsl;
    can_ok __PACKAGE__, qw/run app req param/;

    isa_ok $v->run, 'CODE';
    my $res = $v->run->($env);
    isa_ok $res, 'ARRAY';
    is_deeply $res, [200, [], ['Hello, World!']];
};

subtest caller_class => sub {
    my $v = Nephia::Core->new(app => $app, caller => 'MyApp');
    isa_ok $v, 'Nephia::Core';
    is $v->caller_class, 'MyApp';
};

subtest load_plugin => sub {
    {
        package Nephia::Plugin::Test;
        use parent 'Nephia::Plugin';
        sub new {
            my ($class, %opts) = @_;
            my $self = $class->SUPER::new(%opts);
            $self->app->filter_chain->append(slate => sub {
                my $content = shift;
                my $world = $opts{world};
                $content =~ s/World/$world/g;
                return $content;
            });
            return $self;
        };
    };

    my $v = Nephia::Core->new(plugins => [Test => {world => 'MyHome'}], app => $app);
    isa_ok $v, 'Nephia::Core';
    is_deeply [ map {ref($_)} $v->loaded_plugins->as_array ], [qw[Nephia::Plugin::Basic Nephia::Plugin::Cookie Nephia::Plugin::Test]], 'plugins';
};

done_testing;
