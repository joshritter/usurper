package Usurper::Controller::Area::CharacterStats;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller::Area);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
   
    return $self;
}

sub enter {
    my $self = shift;
    my $character = shift;

    $self->printPlayerStats($character,1);
    my $input = "?";
    while($input !~ /r/i){
        if($input =~ /s/i){
            $self->printPlayerStats($character,1);
        } elsif ($input =~ /l/i) {
            $self->printInventory($character); 
        } elsif ($input =~ /d/i) {

        } elsif ($input =~ /e/i) {
            $self->equipItem($character);
        } elsif ($input =~ /h/i) {

        }
        $input = $self->getUserInput($self->getMenuText());
    }
}

sub equipItem {
    my $self = shift;
    my $character = shift;

    my $items = $character->getNonEquippedItems();
    my $size = $items->size();
    my $input = $self->getUserInput("Which item would like to equip? [1 - $size]");

    while($input < 1 || $input > $size){
        $input = $self->getUserInput("Invalid number, try again.\n\r");
        if($input =~ /q/i){
            last;
        }
    }

    my $pos = $input - 1;
    my $item = $character->equipItem($pos); 

    print "You put on the ". $item->getName(). ".\n\r";
}

sub printInventory {
    my $self = shift;
    my $character = shift;

    my $iterator = $character->getItems()->iterator();

    my $display_pos = 1;
    while(my $item = $iterator->next()){
        if($item->getAttribute('equipped')){
            next;
        }
        print $display_pos . ") ". $item->getName() . "\n\r";
        $display_pos++
    }
    print "\n\r\n\r";
}



sub getMenuText {
    return "[S]tats     [L]ook in your inventory   [E]quip an item    [D]rop an item      Drink [H]ealing potion      [R]eturn to main street\n\r\n\r";
}
1;
