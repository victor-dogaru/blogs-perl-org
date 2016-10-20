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

                my $context = shift;
                my $user = $context->session->{'data'}->{'user'};
                $user = $dsl->resultset('Users')->find({ id => $user->{id} }) if ($user);

                my $request = $context->request->path_info;

                # Check if the user is logged in
                if (($request =~ '/author/' && !$user) || 
                    ($request =~ '/admin/' && !$user) ) {

                    my $redir = $dsl->redirect( '/' ) unless $request =~ '/profile/author/' ;
                    return $redir;
                }   

                # Restrict access to non-admin users
                if ( $request =~ '/admin/' && !($user->is_admin) ) {

                    my $redir = $dsl->redirect( '/' );
                    return $redir;
                }
            }
        )
    );
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {

                my $context = shift;
                my $user_obj = $context->session->{'data'}->{'user'};
                        $user_obj = $dsl->resultset('Users')->find({ id => $user_obj->{id} }) if ($user_obj);
                if ( $user_obj ) {
                    my $counter = 0;
                     $counter  = $dsl->resultset('Notification')->search({
                    user_id      => $user_obj->id,
                    name         =>  'changed role',
                    viewed       => 0
                    })->count;
                     $counter   += $dsl->resultset('Notification')->search({
                    user_id      => $user_obj->id,
                    name         =>  'comment',
                    viewed       => 0
                    })->count;
                    $counter    += $dsl->resultset('Notification')->search({
                    user_id      => $user_obj->id,
                    name         =>  'invitation',
                    viewed       => 0
                    })->count;
                    $counter     += $dsl->resultset('Notification')->search({
                    sender_id    => $user_obj->id,
                    name         => 'response',
                    viewed       => 0
                    })->count;
                    
                    $dsl->vars->{notification_counter}= $counter;
                }
            }

        )
    );
};

register_plugin for_versions => [2];
