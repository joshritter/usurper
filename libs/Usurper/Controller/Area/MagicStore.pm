package Usurper::Controller::Area::MagicStore;

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
    
    print "You enter the magic store, you see a sign that reads '".$store->getName()."', you walk up to the front counter hit\n\rthe bell to get someones attention.  The owner, ". $store->getOwner();
    print ", walks in from the back room and asks\n\rwhat you what you need.  What do you want to do next?\n\r\n\r";
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/b/i){
            $self->buyPotions($character);
            $input = "?";
        } elsif ($input =~ /i/i){
            #TODO implement
            $input = "?";   
        }else {
            $input = $self->getUserInput("\n\rMagic Shop(? for menu)");
        }
    }
}

sub buyPotions {
    my $self = shift;
    my $character = shift;

    my $store = $self->{'_store'};
    my $input = $self->getUserInput("How many would you like to buy? (".($character->getLevel() * 5)." gold coins per potion) [0 - 150] [M]ax:");

    my $healings = 0;
    if($input =~ /m/i){
        $healings = 150 - $character->getHealings();
    } else {
        $healings = $input;
    }
    if($healings =~ /\d+/){
        my $cost = $character->getLevel() * 5 * $healings;
    
        if($healings > 0 && $healings+$character->getHealings() <= 150 && $character->getMoneyOnHand() > $cost) {
            $character->setHealings($character->getHealings() + $healings);
            $character->spendMoney($cost);
            $character->store();
            print ("You hand ".$store->getOwner()." $cost coins, he hands you $healings potions. \n\r");
        }else {
            print "You can't buy that amount of healings! Get out!\n\r";
        }
    } else {
        print "You aren't making sense!  Come back when you are ready to answer the question with a valid answer.\n\r";
    }
    
}
sub getMenuText {
    return "        [B]uy Potions 
        [I]dentify an Item
        [R]eturn to main street\n\r\n\rMagic Shop (? for menu)";
}
1;
