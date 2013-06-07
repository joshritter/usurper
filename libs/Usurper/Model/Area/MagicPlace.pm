package Usurper::Model::Area::MagicPlace;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Merlin's Magic";
    my $self = $class->SUPER::new($input);

    return $self;
}


1;
