package Usurper::Controller::Area;

use strict;
use warnings;
use 5.008_000;

use POSIX;#for ceil
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

###
# 
# takes to Usurper::Model::Character objects, and returns the 'winner' of the fight (the person who goes below 0 hitpoints loses)
#
# #
sub fight {
    my $self = shift;
    my $attacker = shift;
    my $defender = shift;
    my $defender_goes_first = shift;

    my $attacker_dmg = (($attacker->getWeapon() ? $attacker->getWeapon()->getAttribute('power'): 0) + $attacker->getStrength()) / 2;
    my $attacker_armor = (($attacker->getArmor() ? $attacker->getArmor()->getAttribute('power') : 0) +$attacker->getDefense()) /2;
    my $attacker_dmg_v = ($attacker_dmg * 1.20) - ($attacker_dmg * .70);
    my $attacker_armor_v = ($attacker_armor* 1.20) - ($attacker_armor* .70);

    my $defender_dmg = (($defender->getWeapon() ? $defender->getWeapon()->getAttribute('power'): 0) + $defender->getStrength()) / 2;
    my $defender_armor = (($defender->getArmor() ? $defender->getArmor()->getAttribute('power') : 0) +$defender->getDefense()) /2;
    my $defender_dmg_v = ($defender_dmg * 1.20) - ($defender_dmg * .70);
    my $defender_armor_v = ($defender_armor* 1.20) - ($defender_armor* .70);

    my $defender_name = $defender->getName();
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ /a/i){
            my $attack = ceil(rand($attacker_dmg_v) + ($attacker_dmg));
            my $defender_block = ceil(rand($defender_armor_v) + ($defender_armor * .75));
            my $damage_taken = $attack - $defender_block;
            $damage_taken = ($damage_taken < 0) ? 0 : $damage_taken;

            print "You hit $defender_name for $damage_taken!\n\r";
            $self->pauseForUserInput("Press any key to continue...\n\r");

            #dead
            if($defender->getHitpoints() <= $damage_taken){
                $self->killCharacter($defender, 1);
                print "$defender_name falls to the floor.  You won!!\n\r";
                $self->pauseForUserInput("Press any key to continue...\n\r");
                return $attacker;
            }

            $defender->setHitpoints($defender->getHitpoints() - $damage_taken);
            my $healed_for = $self->useMaxHealings($defender);
            if($healed_for > 0){
                print "$defender_name healed for $healed_for hitpoints, he isn't giving up easy!\n\r";

                $self->pauseForUserInput("Press any key to continue...\n\r");
            }

            #now the defender goes on the attack!
            $attack = ceil(rand($defender_dmg_v) + ($defender_dmg));
            $defender_block = ceil(rand($attacker_armor_v) + ($attacker_armor *.75));
            $damage_taken = $attack - $defender_block;
            $damage_taken = ($damage_taken < 0) ? 0 : $damage_taken;

            print "$defender_name takes his swing at you, damaging you for $damage_taken hitpoints!\n\r";

            #dead
            if($attacker->getHitpoints() <= $damage_taken){
                $self->killCharacter($attacker);
                $self->pauseForUserInput("Press any key to continue...\n\r");
                print "You take a mortal blow!  You are dead!\n\r";
                $self->pauseForUserInput("Press any key to continue...\n\r");
                return $defender;
            }
            $self->pauseForUserInput("Press any key to continue...\n\r");
            $attacker->setHitpoints($attacker->getHitpoints() - $damage_taken);
            $input = "?";
        } elsif($input =~ /q/i){
            $self->quickHeal($attacker);
            $input = "?"; 
        }else {
            $input = $self->getUserInput("\n\r[A]ttack! or [Q]uick heal \n\r");
        }
    }

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

sub getNeededHealing {
    my $self = shift;
    my $character = shift;

    return ceil(($character->getHitpointTotal() - $character->getHitpoints())/ 5);
}

sub useMaxHealings {
    my $self = shift;
    my $character = shift;

    my $need = ceil(($character->getHitpointTotal() - $character->getHitpoints())/ 5);
    my $have = $character->getHealings();

    my $hitpoints = 0;
    if($need > $have) {
        $hitpoints = 5*$have;
    } else {
        $hitpoints = 5*$need;
    }

    $hitpoints = ($character->getHitpointTotal() < $character->getHitpoints() + $hitpoints) ? $character->getHitpointTotal()- $character->getHitpoints() : $hitpoints;
    $character->setHitpoints($character->getHitpoints()+$hitpoints);
    $character->setHealings($need > $have ? 0 : $have - $need);

    return $hitpoints;
}

sub quickHeal {
    my $self = shift;
    my $character = shift;

    my $need = ceil(($character->getHitpointTotal() - $character->getHitpoints())/ 5);
    my $have = $character->getHealings();
    if($have < 1){
        print "You don't have any healings.\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return;
    }
    if($need < 0){
        print "You don't need any healing.\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return;
    }

    my $hitpoints = 0;
    if($need > $have) {
        $hitpoints = 5*$have;
        print "You need $need healing potions but only have $have.  You will heal for $hitpoints hitpoints \n\r";
    } else {
        $hitpoints = 5*$need;
        print "You have $have healing potions and need $need, you will use $need.  You will heal for $hitpoints hitpoints \n\r";
    }
    $hitpoints = ($character->getHitpointTotal() < $character->getHitpoints() + $hitpoints) ? $character->getHitpointTotal()- $character->getHitpoints() : $hitpoints;
    $character->setHitpoints($character->getHitpoints()+$hitpoints);
    $character->setHealings($need > $have ? 0 : $have - $need);
    $self->pauseForUserInput("Press any key to continue...\n\r");
}
1;
