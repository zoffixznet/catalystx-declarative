use CatalystX::Declarative;

role MyActionYes {
    around match (@args) { $ENV{TESTAPP_ACTIONROLE} ? $self->$orig(@args) : undef }
}

role TestApp::Try::Aliasing::MyActionNo {
    around match (@args) { $ENV{TESTAPP_ACTIONROLE} ? undef : $self->$orig(@args) }
}

class TestApp::Action::Page extends Catalyst::Action {

    around execute ($controller, $ctx, @args) {
        my $page = $ctx->request->params->{page} || 1;
        return $self->$orig($controller, $ctx, @args, page => $page);
    }
}

controller TestApp::Controller::Foo {

    use constant MyActionNo => 'TestApp::Try::Aliasing::MyActionNo';

    #
    #   look, a Moose!
    #

    has title => (
        is      => 'ro',
        isa     => 'Str',
        default => 'TestApp',
    );


    #
    #   normal methods are very useful too
    #

    method welcome_message { sprintf 'Welcome to %s!', $self->title }

    method greet (Str $name) { "Hello, $name!" }


    #
    #   the simple stuff
    #

    action base under '/base' as 'foo';

    action root under base as '' is final {
        $ctx->response->body( $self->welcome_message );
    }

    
    #
    #   with arguments
    #

    action with_args under base;

    action hello (Str $name) under with_args is final {
        $ctx->response->body($self->greet(ucfirst $name));
    }

    action at_end (Int $x, Int $y) under with_args is final { 
        $ctx->response->body( $x * $y );
    }

    action in_the_middle (Int $x, Int $y) under with_args {
        $ctx->stash(result => $x * $y);
    }
    action end_of_the_middle under in_the_middle is final {
        $ctx->response->body($ctx->stash->{result} * 2);
    }

    action all_the_way (Int $x) under with_args as '' {
        $ctx->stash(x => $x);
    }
    action through_the_sky (Int $y) under all_the_way as '' {
        $ctx->stash(y => $y);
    }
    action and_beyond (@rest) under through_the_sky as fhtagn is final {
        $ctx->response->body(join ', ', 
            $ctx->stash->{x},
            $ctx->stash->{y},
            @rest,
        );
    }


    #
    #   under is also a valid keyword
    #

    under base action under_base as under;

    under under_base as '' action even_more_under (Int $i) is final {
        $ctx->response->body("under $i");
    }


    #
    #   too many words? go comma go!
    #

    action comma_base, as '', under base;

    under comma_base, is final, action comma ($str), as ',comma' {
        $ctx->response->body($str);
    }


    #
    #   subnamespacing
    #

    action lower under base;

    under lower {

        action down;

        under down {

            action the;

            under the {

                action stream is final {
                    $ctx->response->body($ctx->action->reverse);
                }
            }
        }
    }


    #
    #   action roles
    #

    action with_role_yes 
        is final 
        as with_role 
     under base 
      with MyActionYes 
           { $ctx->res->body('YES') };

    action with_role_no 
        is final 
        as with_role 
     under base 
      with MyActionNo 
           { $ctx->res->body('NO') };


    #
    #   action classes
    #

    action book (Str $title) under base {
        $ctx->stash(title => $title);
    }

    action view (Str $format, Int :$page) under book isa Page is final {
        $ctx->response->body(
            sprintf 'Page %d of "%s" as %s',
                $page,
                $ctx->stash->{title},
                uc($format),
        );
    }


    #
    #   using final as syntax element
    #

    action final_base as 'finals' under base;

    final action in_front under final_base { $ctx->response->body($ctx->action->reverse) }

    under final_base, final action final_middle { $ctx->response->body($ctx->action->reverse) }

    action final_at_end, final under final_base { $ctx->response->body($ctx->action->reverse) }
}

