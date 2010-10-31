package Image::Placeholder;

use Modern::Perl;
use Moose;
use MooseX::Method::Signatures;
use MooseX::FollowPBP;

has height => (
    isa     => 'Int',
    is      => 'ro',
);
has text => (
    isa     => 'Str',
    is      => 'rw',
);
has width => (
    isa     => 'Int',
    is      => 'ro',
    default => '300',
);

method BUILD {
    $self->{'height'} = $self->get_width()
        unless defined $self->get_height();
    
    $self->{'width'} = 300
        unless $self->get_width > 0;
    $self->{'height'} = $self->get_width
        unless $self->get_height > 0;
    
    $self->set_default_text()
        unless defined $self->get_text();
}

method set_default_text {
    my $size = sprintf '%s×%s', $self->get_width(), $self->get_height();
    $self->set_text( $size );
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
