package PearlBee::Dancer2::Plugin::Admin;
use strict;
use Dancer2::Plugin;
#use PearlBee;
use Dancer2::Plugin::DBIC;

on_plugin_import {
    my $dsl = shift;
    #$dsl->prefix('/admin');  
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                my $context = shift;
                my $user = $context->session->{'data'}->{'user'};
                my $request = $context->request->path_info;

                $dsl->set( layout => 'admin' );

                $user = $dsl->resultset('Users')->
                    find({ username => $user->{username} }) if ($user);

                # Check if the user is logged in
                if ( !$user && $request =~ /admin/ ) {
#                    my $redir = $dsl->redirect( '/admin' );
#                    return $redir;
                    return;
                }

                # Check if the user is activated
                if ( $request !~ /\/dashboard/ && $user) {
#                    my $redir = $dsl->redirect( $app_url . '/dashboard' ) if ( $user->status eq 'inactive' );
#                    return $redir;
                    return;
                }

                # Restrict access to non-admin users
                if ( $request =~ '/admin/' && $user->is_author ) {
#                    my $redir = $dsl->redirect( $app_url . '/author/posts' );
#                    return $redir;
                    return;
                }
            }
        )
    );
};


register_plugin for_versions => [2];
