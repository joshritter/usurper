package Usurper::Controller::Area::Castle;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller::Area);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
   
    $self->{'_store'} = shift;

    return $self;
}

sub enter {
    my $self = shift;
    my $character = shift;

    $self->clearScreen();
    my $store = $self->{'_store'};

    if($character->getIsKing()){
        return $self->enterCastle($character);
    }

    print "Commoners are not allowed in the castle, so you make your way up the the front gate... What do you do next?\n\r";
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/u/i){
            $self->infiltrateCastle($character); 
            $input = "?";
        }  else {
            $input = $self->getUserInput("\n\rCastle(? for menu)");
        }
    }
}

sub infiltrateCastle {
    my $self = shift;
    my $character = shift;

    print "try again later";
}

sub enterCastle {
    my $self = shift;
    my $character = shift;

    print "You walk through the gates into the castle.  It is good to be home!\n\r";
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getKingMenuText());
        } else {
            $input = $self->getUserInput("\n\rCastle(? for menu)");
        }
    }
    return 1;
}

sub getKingMenuText {
    return "        [K]ings Chamber
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}
sub getMenuText {
    return "        [U]usurp the throne! Down with the king! 
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}
1;
