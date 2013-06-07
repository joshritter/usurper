package Usurper::Controller::Area::WeaponStore;

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
    
    print "You enter the weapon store, you see a sign that reads '".$store->getName()."', you walk up to the front counter hit\n\rthe bell to get someones attention.  The owner, ". $store->getOwner();
    print ", walks in from the back room and asks\n\rwhat you what you need.  What do you want to do next?\n\r\n\r";
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/b/i){
            $self->buyItem($character);
            $input = "?";
        } elsif ($input =~ m/l/i){
            $self->printItemList();
            $input = "?";
        } elsif ($input =~ m/s/i){
            $input = "?"; 
        } else {
            $input = $self->getUserInput("\n\rWeapon Store (? for menu)");
        }
    }
}

sub printItemList {
    my $self = shift;
    my $store = $self->{'_store'};

    my $weapons = $store->getWeapons();
    print "__________________________________________________\n\r";
    print "Name:                       cost:\n\r\n\r" ;
    my $count = 0;
    my $n = 0;
    foreach my $weapon_id (keys %$weapons){
        my $weapon = $weapons->{$weapon_id};
        print $n+1 . ".) ". $weapon->getName();
        print "                     ".$weapon->getAttribute('cost') ."\n\r";
        if($n == $count*15-1){
            $count++;
            $self->getUserInput("Press enter to continue.");
        }
        $n++;
    }
    print "__________________________________________________\n\r\n\r";
}

sub buyItem {
    my $self = shift;
    my $character = shift;
    my $store = $self->{'_store'};
    my $weapons = $store->getWeapons();
    my @weapons = values %$weapons;

    my $selection = $self->getUserInput("Which weapon would you like to buy?\n\r");
            
    while($selection < 1 || $selection > scalar @weapons){
        $selection = $self->getUserInput("Invalid number, try again.\n\r");
    }
    my $weapon = $weapons[$selection-1];
            
    print "You want to buy the " .$weapon->getName(). " for " .$weapon->getAttribute('cost'). "?\n\r";
    my $check = $self->getUserInput("[Y]es or [N]o?");
    if($check =~ m/y/i){
        if($weapon->getAttribute("cost") > $character->getMoneyOnHand()){
            print "You don't have that kind of cash, get out of here!\n\r";
        } else {
            $self->clearScreen();
            $character->spendMoney($weapon->getAttribute("cost"));
            $character->addItem($weapon);
            print "You hand ".$store->getOwner() ." the money and he hands you the " .$weapon->getName(). ", you put it in your inventory.\n\r";
            $character->store();
        }
    }

    return;

}
sub getMenuText {
    return "        [L]ist items
        [B]uy an item
        [S]ell an item
        [R]eturn to main street\n\r\n\rWeapon Store (? for menu)";
}
1;
