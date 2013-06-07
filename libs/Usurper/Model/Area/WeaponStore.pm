package Usurper::Model::Area::WeaponStore;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Daggers R Us";
    my $self = $class->SUPER::new($input);

    $self->{_weapons} = $input->{'weapons'};

    return $self;
}

sub getWeapons {
    my $self = shift;
    return $self->{'_weapons'};
}

1;
