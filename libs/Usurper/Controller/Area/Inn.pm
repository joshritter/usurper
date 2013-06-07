package Usurper::Controller::Area::Inn;

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
    
    print "You enter the inn, you see a sign that reads '".$store->getName()."', you walk up to the front counter hit\n\rthe bell to get someones attention.  The owner, ". $store->getOwner();
    print ", walks in from the back room and asks\n\rwhat you what you need.  What do you want to do next?\n\r\n\r";
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/g/i){
            my $return = $self->getRoomForNight($character);
            if($return == -1){
                return -1;
            }
            $input = "?";
        } elsif ($input =~ m/s/i){
            #XXX implement
            $input = "?";
        } elsif ($input =~ m/b/i){
            #XXX implement
            $input = "?"; 
        } else {
            $input = $self->getUserInput("\n\rInn (? for menu)");
        }
    }
}

sub getRoomForNight {
    my $self = shift;
    my $character = shift;
    my $store = $self->{'_store'};
    my $owner = $store->getOwner();
    my $cost= 500;

    if($character->getMoneyOnHand() < $cost ){
        print "You don't have enough money to get a room at this classy joint.  Come back when you have at least $cost gold coins on you.\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
    }

    my $input = $self->getUserInput("You motion to $owner, tell her you'd like a room.  She asks if you have the money for it, it will cost $cost to get a room for the night.  
\n\rGive her the money? [Y]es / [N]o : ");

    if($input !~ /y/i){
        print "You change your mind and tell $owner you need time to think it over first\n\r";
        return;
    }
    
    print "You hand over $cost to $owner.  She grins a big grin and takes your money.  She grabs a set of keys and hands them to you.  You walk upstairs, find your room, and lock the door behind you.  Lets hope you survive the night.\n\r";
    $character->spendMoney($cost);
    $character->setRestArea('inn');
    $character->store();
    return -1;
}

sub getMenuText {
    return "        [G]et a room for the night
        [S]neak a look at the guest register 
        [B]ribe your way into someones room
        [R]eturn to main street\n\r\n\rInn (? for menu)";
}
1;
