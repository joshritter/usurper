package Usurper::Model::Area;

use strict;
use warnings;
use 5.008_000;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    
    my $hash = shift;
    $self->{'_name'} = $hash->{'name'};
    $self->{'_owner'} = $hash->{'owner'};

    return $self;
}


sub getName {
    my $self = shift;
    return $self->{'_name'};
}

sub getOwner {
    my $self = shift;
    return $self->{'_owner'};
}

sub getIntroText {
    die "Must implement in subclass";
}

1;
