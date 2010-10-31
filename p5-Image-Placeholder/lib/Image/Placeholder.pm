package Image::Placeholder;

use Modern::Perl;
use Moose;
use MooseX::Method::Signatures;
use MooseX::FollowPBP;

use GD;

use constant TRUE_COLOUR      => 1;
use constant MAX_TRANSPARENCY => 127;
use constant MAX_USABLE_RATIO => 0.85;

has background_colour => (
    isa     => 'Str',
    is      => 'ro',
    default => 'ddd',
);
has font => (
    isa     => 'Str',
    is      => 'ro',
    default => 'Museo Sans',
);
has height => (
    isa     => 'Int',
    is      => 'ro',
);
has line_colour => (
    isa     => 'Str',
    is      => 'ro',
    default => '444',
);
has size => (
    isa => 'Str',
    is  => 'ro',
);
has text => (
    isa     => 'Str',
    is      => 'rw',
);
has text_colour => (
    isa     => 'Str',
    is      => 'ro',
    default => '36f',
);
has transparent => (
    isa     => 'Bool',
    is      => 'ro',
    default => 0,
);
has width => (
    isa     => 'Int',
    is      => 'ro',
    default => '300',
);

method BUILD {
    $self->set_size_from_string( $self->get_size() )
        if defined $self->get_size();
    
    $self->{'height'} = $self->get_width()
        unless defined $self->get_height();
    
    $self->{'width'} = 300
        unless $self->get_width > 0;
    $self->{'height'} = $self->get_width
        unless $self->get_height > 0;
    
    $self->set_default_text()
        unless defined $self->get_text();
    
    $self->{'_image'} = GD::Image->new(
            $self->get_width(),
            $self->get_height(),
            TRUE_COLOUR
        );
    $self->{'_image'}->saveAlpha(1);
    $self->{'_image'}->alphaBlending(1);
    $self->{'_image'}->useFontConfig(1);
    
    $self->{'_line'} = $self->allocate_colour( $self->get_line_colour() );
    $self->{'_background'} = $self->allocate_colour(
            $self->get_background_colour(),
            $self->get_transparent() * MAX_TRANSPARENCY
        );
    $self->{'_text'} = $self->allocate_colour(
            $self->get_text_colour(),
            int( MAX_TRANSPARENCY * 0.6 )
        );
}

method generate {
    my $image = $self->{'_image'};
    my $line  = $self->{'_line'};
    my $x     = $self->get_width() - 1;
    my $y     = $self->get_height() - 1;
    
    # draw the border and cross
    $image->fill( 0, 0, $self->{'_background'} );
    
    if ( $self->get_line_colour ne 'none' ) {
        $image->setAntiAliased( $line );
        $image->line( 0, 0, $x, $y, gdAntiAliased );
        $image->line( $x, 0, 0, $y, gdAntiAliased );
        $image->rectangle( 0, 0, $x, $y, $line );
    }
    
    if ( $self->get_text_colour ne 'none' ) {
        # work out where (indeed, if) the text fits
        my( $twidth, $theight, $tdropheight, $point_size )
            = $self->get_text_offset();
    
        if ( $twidth ) {
            my $baseline   = $self->get_height() - $tdropheight;
            my $text_total = $theight + $tdropheight;
            my $remainder  = $self->get_height() - $text_total;
        
            my $tx = ( $self->get_width() - $twidth ) / 2;
            my $ty = $baseline - int( $remainder / 2 );
        
            $image->stringFT(
                    $self->{'_text'},
                    $self->{'font'},
                    $point_size,
                    0,                      # angle
                    $tx,
                    $ty,
                    $self->get_text()
                );
        }
    }
    
    return $image->png;
}

method set_default_text {
    my $size = sprintf '%s×%s', $self->get_width(), $self->get_height();
    $self->set_text( $size );
}
method set_size_from_string ( Str $size ) {
    my $width_by_height = qr{
            ^
            ( \d+ )
            x
            ( \d+ )
            $
        }x;
    
    if ( $size =~ $width_by_height ) {
        $self->{'width'}  = $1;
        $self->{'height'} = $2;
    }
}

method get_text_offset {
    my $x             = 0;
    my $y             = 0;
    my $point_size    = 10;
    my $usable_width  = int( $self->get_width  * MAX_USABLE_RATIO );
    my $usable_height = int( $self->get_height * MAX_USABLE_RATIO );
    my @previous      = ( 0, 0, 0, 0 );
    
    while ( 1 ) {
        my @bounds = GD::Image->stringFT(
                $self->{'_line'},       # colour
                $self->{'font'},
                $point_size,
                0,                      # angle
                0,                      # x
                0,                      # y
                $self->get_text(),
            );
        
        if ( @bounds ) {
            my $text_width      = $bounds[2] - $bounds[0];
            my $text_height     = 0 - $bounds[5];
            my $text_dropheight = $bounds[1];
            my $text_total_height = $text_height + $text_dropheight;
            
            # $text_width = $bounds[2] - $bounds[0];
            # $text_height = $bounds[1] + ( 0 - $bounds[5]);
            
            my $too_big = ( $text_width > $usable_width )
                          || ( $text_total_height > $usable_height );
            
            return @previous if $too_big;
            
            @previous =
                ( $text_width, $text_height, $text_dropheight, $point_size );
            $point_size += 5;
        }
        else {
            return @previous;
        }
    }
}

method allocate_colour ( Str $colour, Int $alpha=0 ) {
    my @rgb = $self->rgb_to_hex( $colour );
    my $img = $self->{'_image'};
    
    return $img->colorAllocateAlpha( @rgb, $alpha )
}
method rgb_to_hex ( Str $hex ) {
    # TODO lookup standard colour values
    
    # must be a hex value
    return( 0, 0, 0 )
        unless $hex =~ m{^[0-9a-f]+$}i;
    
    # allow CSS style shorthands (f60 == ff6600)
    $hex = "$1$1$2$2$3$3"
        if $hex =~ m{^([0-9a-f])([0-9a-f])([0-9a-f])$}i;
    
    # must be six chars long
    return( 0, 0, 0 )
        unless 6 == length $hex;
    
    return map { hex($_) } unpack 'a2a2a2', $hex;
}

1;
