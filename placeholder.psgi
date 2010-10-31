#!/usr/bin/env perl

use Modern::Perl;

use Encode;
use Plack::App::Cascade;
use Plack::App::File;
use Image::Placeholder;
use Plack::Request;
use Text::Intermixed;
use Text::SimpleTemplate;
use URI::Escape;



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
        
        # parse out the arguments
        my %args = parse_url( $path );
        
        if ( %args ) {
            return generate_image( %args )
                if $path =~ m{\.png$};
        }
        
        return generate_404();
    };
}
sub parse_url {
    my $url = shift;
    
    my $options = qr{
            ^
              /
              # optional changes
              (?: (?'background_colour' [0-9a-f]+ | transparent ) / )?
              (?: (?'line_colour'       [0-9a-f]+ | none )        / )?
              (?: (?'text_colour'       [0-9a-f]+ | none )        / )?
              (?: (?'text'              [^/]+ )                   - )?
              
              # only mandatory bit: 200x100.png
              (?'width' \d+ )
              (?: x (?'height' \d+ ) )?
              \.
              (?'format' png )
            $
        }x;
    
    if ( $url =~ m{$options}ix ) {
        my %match = %+;
        
        $match{'text'} = uri_unescape( $match{'text'} )
            if defined $+{'text'};
        
        if ( $match{'background_colour'} eq 'transparent' ) {
            delete $match{'background_colour'};
            $match{'transparent'} = 1;
        }
        
        return %match;
    }
    
    return;
}
sub generate_image {
    my %args  = @_;
    my $image = Image::Placeholder->new( %args );
    
    return [
        200,
        [
            'Content-Type', 'image/png',
        ],
        [ $image->generate(), ],
    ];
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
