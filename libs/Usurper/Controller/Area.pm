package Usurper::Controller::Area;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    
    return $self;
}

sub enter {
    my $self = shift;
    my $character = shift;
    print "This area is currently under construction.  You peek your head in, but are quickly shoed away, better try somewhere else.";
}

sub sellItem {
    my $self = shift;
    my $character = shift;
    my $store = $self->{'_store'};

    my $items = $character->getNonEquippedItems();
    my $size = $items->size();
    my $input = $self->getUserInput("Which item would you like to sell [1 - $size] ?\n\r");

    while($input < 1 || $input > $size){
        $input = $self->getUserInput("Invalid number, try again.\n\r");
        if($input =~ /q/i){
            last;
        }
    }

    my $pos = $input - 1;

    my $item_to_sell = $character->getUnequippedItem($pos);
    if(!$item_to_sell){
        print "I'm sorry, I don't understand.  Go somewhere else with your nonsense.\n\r";
        return;
    }
    my $money = int($item_to_sell->getAttribute('cost') / 2);
    $input = $self->getUserInput("You sure you want to sell the ".$item_to_sell->getName().", I will give you $money gold coins for it? [Y]es or [N]o: \n\r");

    if($input =~ /y/i){
        $character->addMoney($money);
        $character->removeUnequippedItem($pos);
        $character->store();
        print $store->getOwner(). " hands you over $money gold coins as you hand him the ". $item_to_sell->getName()."\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
    } else {
        print "Come back when you can make up your mind!\n\r\n\r";
    }
    return;
}

sub printItemList {
    my $self = shift;
    my $store = $self->{'_store'};

    my $items = shift;
    print "__________________________________________________\n\r";
    print "Name:                                     cost:\n\r\n\r" ;
    my $count = 0;
    my $n = 0;
    foreach my $item_id (sort { $items->{$a}->getAttribute('cost') <=> $items->{$b}->getAttribute('cost') } keys %$items){
        my $item = $items->{$item_id};
        my $prefix = $n+1 . ".) ". $item->getName();
        #variable whitespace to keep things aligned
        print "$prefix ".$self->generateWhiteSpace(41-length($prefix)).$self->formatNumber($item->getAttribute('cost')) ."\n\r";
        if($n == $count*15-1){
            $count++;
            $self->pauseForUserInput("Press any key to continue...\n\r");
        }
        $n++;
    }
    print "__________________________________________________\n\r\n\r";
}
1;
