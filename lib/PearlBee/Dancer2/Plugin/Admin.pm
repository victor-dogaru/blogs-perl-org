package PearlBee::Dancer2::Plugin::Admin;
use strict;
use Dancer2::Plugin;
#use PearlBee;
use Dancer2::Plugin::DBIC;

on_plugin_import {
    my $dsl = shift;
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                $dsl->set( layout => 'admin' );
                my $context = shift;
                my $user = $context->session->{'data'}->{'user'};

                $user = $dsl->resultset('Users')->find({ username => $user->{username} }) if ($user);

                my $request = $context->request->path_info;
                my $app_url = $context->config->{'app_url'};
                # Check if the user is logged in
                if (!$user ) {
                 my $redir = $dsl->redirect( $app_url );
                 return $redir;
                }   
                # Restrict access to non-admin users
                if ( $request =~ '/admin/' && !($user->is_admin) ) {

                    my $redir = $dsl->redirect( $app_url );
                    return $redir;
                }
            }
        )
    );
};

register_plugin for_versions => [2];
