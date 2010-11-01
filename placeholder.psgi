#!/usr/bin/env perl

use Modern::Perl;

use Encode;
use Image::Placeholder;
use Plack::App::Cascade;
use Plack::App::File;
use Plack::Builder;
use Plack::Middleware::ConditionalGET;
use Plack::Middleware::Expires;
use Plack::Request;
use Text::Intermixed;
use Text::SimpleTemplate;
use URI::Escape;

use constant MAX_IMAGE_DIMENSION => 2047;
use constant ETAG_VALUE          => '2';



my $templates = Text::SimpleTemplate->new( base_dir => 'templates' );

my $static  = Plack::App::File->new( root => 'site' )->to_app;
my $dynamic = get_result();
my $builder = Plack::Builder->new();

$builder->add_middleware( 'ConditionalGET' );
$builder->add_middleware( 
        'Expires', 
        content_type => qr{^image/},
        expires      => 'access plus 3 months',
    );
$dynamic = $builder->mount( '/' => $dynamic );
$dynamic = $builder->to_app( $dynamic );

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
        
        return redirect_to_image( $req )
            if '/create' eq $path && 'POST' eq $req->method;
        
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
        
        # let's not go crazy with image sizes
        return
            if ( $match{'width'} > MAX_IMAGE_DIMENSION );
        return
            if ( $match{'height'} > MAX_IMAGE_DIMENSION );
        
        $match{'text'} = uri_unescape( $match{'text'} )
            if defined $+{'text'};
        
        if ( ( $match{'background_colour'} // '' ) eq 'transparent' ) {
            delete $match{'background_colour'};
            $match{'transparent'} = 1;
        }
        
        return %match;
    }
    
    return;
}
sub redirect_to_image {
    my $req = shift;
    
    my $host   = $req->base;
    my $text   = $req->param( 'text' )              // '';
    my $tcol   = $req->param( 'text_colour' )       // '';
    my $lcol   = $req->param( 'line_colour' )       // '';
    my $bcol   = $req->param( 'background_colour' ) // '';
    my $width  = $req->param( 'width' )             // 300;
    my $height = $req->param( 'height' )            // 300;
    
    # fill in the default values if not provided and a later
    # part of the URL has been specified
    $tcol = '36f' if !length $tcol && length $text;
    $lcol = '444' if !length $lcol && length $tcol;
    $bcol = 'ddd' if !length $bcol && length $lcol;
    
    $width  = 300    unless $width  =~ m{^\d+$};
    $height = $width unless $height =~ m{^\d+$};
    
    my $size = sprintf '%s%sx%s',
                    ( length $text ? "${text}-" : '' ),
                    $width,
                    ( length $height ? $height : $width );
    
    my $path = join( '/', '', $bcol, $lcol, $tcol, $size ) . '.png';
    $path =~ s{/+}{/}gs;
    $path =~ s{^/}{};
    
    return [
        301,
        [ 'Location' => "${host}${path}", ],
        [],
    ];
}
sub generate_image {
    my %args  = @_;
    my $image = Image::Placeholder->new( %args );
    
    return [
        200,
        [
            'Content-Type', 'image/png',
            'ETag',         ETAG_VALUE,
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
