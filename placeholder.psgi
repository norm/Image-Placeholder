#!/usr/bin/env perl

use Modern::Perl;

use Encode;
use Plack::App::Cascade;
use Plack::App::File;
use Plack::Request;
use Text::Intermixed;
use Text::SimpleTemplate;



my $templates = Text::SimpleTemplate->new( base_dir => 'templates' );

my $static  = Plack::App::File->new( root => 'site' )->to_app;
my $dynamic = get_result();

# serve up static files by preference if they exist
my $cascade = Plack::App::Cascade->new();
$cascade->add( $static );
$cascade->add( $dynamic );

# run the web site
$cascade->to_app;



sub get_result {
    return sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $path = $req->path;
        
        return generate_homepage()
            if '/' eq $path;
        
        return generate_404();
    };
}
sub generate_homepage {
    my $template = $templates->get_template( 'homepage', 'html' );
    return generate_html( $template );
}
sub generate_404 {
    my $template = $templates->get_template( '404', 'html' );
    return generate_html( $template, 404 );
}
sub generate_html {
    my $template = shift;
    my $code     = shift // 200;
    
    my( $output, $errors ) = render_intermixed( $template, {} );
    
    return [
        $code,
        [ 'Content-Type' => 'text/html; charset=utf8', ],
        [ encode_utf8( $output ), ]
    ];
}
