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

1;
