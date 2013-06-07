package Usurper;

use strict;
use warnings;
use 5.008_000;

use Usurper::Settings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    return $self;
}

sub getSettings {
    my $self = shift;
    if(!$self->{'_usurper_game_settings'}) {
        $self->{'_usurper_game_settings'} = Usurper::Settings->new();
    }
    return $self->{'_usurper_game_settings'};
}

sub setSettings {
    my $self = shift;
    $self->{'_usurper_game_settings'} = shift;
}

1;
