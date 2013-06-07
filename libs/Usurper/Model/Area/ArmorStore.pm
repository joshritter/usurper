package Usurper::Model::Area::ArmorStore;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Armor Store";
    my $self = $class->SUPER::new($input);

    $self->{_armors} = $input->{'armors'};
    
    return $self;
}

sub getArmors {
    my $self = shift;
    return $self->{'_armors'};
}

1;
