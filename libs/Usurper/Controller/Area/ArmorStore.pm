package Usurper::Controller::Area::ArmorStore;

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
    
    print "You enter the armor store, you see a sign that reads '".$store->getName()."', you walk up to the front counter hit\n\rthe bell to get someones attention.  The owner, ". $store->getOwner();
    print ", walks in from the back room and asks\n\rwhat you what you need.  What do you want to do next?\n\r\n\r";
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/b/i){
            $self->buyItem($character);
            $input = "?";
        } elsif ($input =~ m/l/i){
            $self->printItemList($store->getArmors());
            $input = "?";
        } elsif ($input =~ m/s/i){
            $self->sellItem($character);
            $input = "?"; 
        } else {
            $input = $self->getUserInput("\n\rArmor Store (? for menu)");
        }
    }
}

sub buyItem {
    my $self = shift;
    my $character = shift;
    my $store = $self->{'_store'};
    my $armors = $store->getArmors();
    my @armors = sort { $a->getAttribute('cost') <=> $b->getAttribute('cost') } values %$armors;

    my $selection = $self->getUserInput("Which armor would you like to buy?\n\r");
            
    while($selection < 1 || $selection > scalar @armors){
        $selection = $self->getUserInput("Invalid number, try again.\n\r");
    }
    my $armor = $armors[$selection-1];
            
    print "You want to buy the " .$armor->getName(). " for " .$armor->getAttribute('cost'). "?\n\r";
    my $check = $self->getUserInput("[Y]es or [N]o?");
    if($check =~ m/y/i){
        if($armor->getAttribute("cost") > $character->getMoneyOnHand()){
            print "You don't have that kind of cash, get out of here!\n\r";
        } else {
            $self->clearScreen();
            $character->spendMoney($armor->getAttribute("cost"));
            $character->addItem($armor);
            print "You hand ".$store->getOwner() ." the money and he hands you the " .$armor->getName(). ", you put it in your inventory.\n\r";
            $character->store();
            $self->pauseForUserInput("Press any key to continue...\n\r");
        }
    }

    return;

}
sub getMenuText {
    return "        [L]ist items
        [B]uy an item
        [S]ell an item
        [R]eturn to main street\n\r\n\rArmor Store (? for menu)";
}
1;
