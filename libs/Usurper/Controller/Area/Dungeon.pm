package Usurper::Controller::Area::Dungeon;

use strict;
use warnings;
use 5.008_000;
use POSIX;#for ceil

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

    if(!$self->getDungeonLevel() || $self->getDungeonLevel() < $character->getLevel()){
        $self->setDungeonLevel($character->getLevel());
    }

    $self->clearScreen();
    my $store = $self->{'_store'};
   
    print "You enter the dungeon \n\r\n\rAs you slowly descend depper and deepr into the bowls of hell you feel a sweat creep across \n\ryour body and you begin to realize that this was probably a mistake... good luck \n\r\n\r";
    
    $self->pauseForUserInput("Press any key to continue...\n\r");
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText($character));
        } elsif ($input =~ m/l/i){
            my $return = $self->lookForMonsters($character);
            if($return && $return == -1){
                return -1;
            }
            $input = "?"; 
        } elsif($input =~ /s/i){
            $self->printPlayerStats($character, 1);
            $input = "?"; 
        } elsif($input =~ /c/i){
            $self->changeLevel($character);
            $input = "?"; 
        }elsif($input =~ /q/i){
            $self->quickHeal($character);
            $input = "?"; 
        } else {
            $input = $self->getUserInput("\n\rDungeon (? for menu) ( Level: ". $self->getDungeonLevel().", ".$character->getRemainingDungeonFights() ." fights left)");
        }
    }
}

sub changeLevel {
    my $self = shift;
    my $character = shift;

    my $new_level = 'a';
    my $min = $character->getLevel();
    my $max = $character->getLevel() + 10;
    while($new_level !~ /\d+/ || $new_level < $min || $new_level > $max ){
        $new_level = $self->getUserInput("You wish to change dungeon levels?  Enter a number between $min and $max: ");
    }

    $self->setDungeonLevel($new_level);
}

sub lookForMonsters {
    my $self = shift;
    my $character = shift;
    my $model = $self->{'_store'};
   
    if($character->getRemainingDungeonFights() < 1){
        print "You are worn out from all your battles, get some rest, and come back tomorrow before looking for more adventures.\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return;
    }
    my $monsters = Usurper::List->new();
    #Find some monsters
    my $full_list = $model->getMonstersForLevel($self->getDungeonLevel());
    my $monster_count = ceil(rand(6));
    if(!$full_list || scalar @$full_list ==0 || $monster_count == 0){
        print "After an exhausting search you turn up nothing, try again later. \n\r";
        return;
    }
   
    for(my $i = 0; $i < $monster_count; $i++){
        my $monster = @$full_list[floor(rand($monster_count-1))]; 
        
        next if !$monster;

        $monsters->add({ health => $monster->{'health'}, 'low' => $monster->{'low'}, high => $monster->{'high'}, name => $monster->{'name'}, level => $monster->{'level'}});
    }
    
    #Start the fight
    print "Uh oh, now you've done it. You see ". $monsters->size() . " monsters in front of you.\n\r\n\r";
    
    $self->pauseForUserInput("Press any key to continue...\n\r");
    my $damage = ($character->getWeapon() ? ceil(($character->getWeapon()->get('power')*1.1+$character->getStrength())/2) : floor($character->getStrength()/2));
    my $variance = ($damage * 1.23) - ($damage * .85); 
    my $protection = ($character->getArmor() ? ceil(($character->getArmor()->get('power')*1.3+$character->getDefense()) /2) : floor($character->getDefense()/2));
    my $armor_variance = ($protection * 1.20) - ($protection* .70); 

    my $input = "?";
    while($monsters->size()){
        my $monster = $monsters->get(0);
        if($input =~ /r/i){
            my $luck = rand();
            if($luck > .75){
                print "With the stealth of a ninja you sneak away, LUCKY.\n\r";
                return;
            } elsif ($luck <= .25) {
                print "BAD move.  In your attempt to escape one of the monsters hits you square on the back of your head, you die instantly...\n\r";
                $character->setHitpoints(0);
                $character->store();
                $self->wait(2);
                $self->pauseForUserInput("Press any key to continue...\n\r");
                return -1;
            }
        } elsif($input =~ /a/i) {

            #you always get the first blow on the first(for now) monster
            my $attack = ceil(rand($variance) + ($damage * .85));
            print "You hit the ".$monster->{'name'}." for $attack hitpoints!\n\r";
            $self->wait(1);
            $monster->{'health'} -= $damage;
            if($monster->{'health'} <= 0){
                $monsters->remove(0);
                my $gold_variance = $monster->{'high'} * 12 - $monster->{'low'} * 10;
                my $gold = ceil(rand($gold_variance) + $monster->{'low'} * 10);

                my $experience = $monster->{'level'}*500 + $self->getDungeonLevel()*13;
                print "You've killed the monster! You gained $experience experience and $gold gold coins.\n\r";
                $character->addMoney($gold);
                $character->increaseExperience($experience);
                my $remaining = $monsters->size();
                if($remaining == 0){
                    print "You've slain all your foes, good job! \n\r";
                    $self->pauseForUserInput("Press any key to continue...\n\r");
                    last;
                }
                print "There are now ". $monsters->size() . " left to fight...\n\r";
                $self->pauseForUserInput("Press any key to continue...\n\r");
            }

            # now the monsters get a turn to hit you some
            #
            print "Now the monsters take their turn at you!  Watch out.\n\r";
            $self->pauseForUserInput("Press any key to continue...\n\r");

            my $iterator = $monsters->iterator();
            while(my $monster = $iterator->next()){
                my $dmg_variance = $monster->{'high'}*2.0 - $monster->{'low'};
                my $enemy_damage = floor(rand($dmg_variance) + $monster->{'low'});
                my $blocked_damage = floor(rand($armor_variance) + $protection * .70);
                print  "You are hit by a monster, he hits you for ". $enemy_damage ." \n\rand your armor protects you for $blocked_damage points.\n\r\n\r";
                $self->wait(1);
                
                my $gross_damage = $enemy_damage - $blocked_damage;
                if($gross_damage > $character->getHitpoints()){
                    $character->setHitpoints(0);
                    $character->store();
                    print "You take a mortal blow... YOU DIE!!!!\n\r";
                    $self->pauseForUserInput("Press any key to continue...\n\r");
                    return -1;
                }

                #this could be a negative number
                if($gross_damage > 0){
                    $character->decreaseHitpoints($gross_damage); 
                }
            }
        
        } elsif($input =~ /q/i){
            $self->quickHeal($character);
        }
        $input = $self->getUserInput("\n\r( [A]ttack      [Q]uick Heal    [R]un Away ) ");
    }
    $character->setRemainingDungeonFights($character->getRemainingDungeonFights() -1);
    $character->store();
}



sub getMenuText {
    my $self = shift;
    my $character = shift;
    return "        [L]ook for Monsters
        [C]hange Levels
        [S]tatus
        [Q]uick Heal
        [R]eturn to main street\n\r\n\rDungeon(? for menu) ( Level: ". $self->getDungeonLevel().", ".$character->getRemainingDungeonFights() ." fights left) ";
}

sub setDungeonLevel {
    my $self = shift;
    $self->{'_dungeon_level'} = shift;;
}

sub getDungeonLevel {
    my $self = shift;
    return $self->{'_dungeon_level'};
}
1;
