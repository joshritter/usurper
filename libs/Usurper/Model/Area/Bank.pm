package Usurper::Model::Area::Bank;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Bank";
    my $self = $class->SUPER::new($input);

    return $self;
}


1;
