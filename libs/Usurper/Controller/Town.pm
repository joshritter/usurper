package Usurper::Controller::Town;

use strict;
use warnings;
use 5.008_000;

use Usurper::Controller::Area::WeaponStore;
use Usurper::Controller::Area::ArmorStore;
use Usurper::Controller::Area::CharacterStats;
use Usurper::Controller::Area::LevelMasters;
use Usurper::Controller::Area::Dungeon;
use Usurper::Controller::Area::MagicStore;
use Usurper::Controller::Area::Inn;
use Usurper::Controller::Area::Bank;
use Usurper::Controller::Area::Jail;
use Usurper::Factory::Character;

use base qw(Usurper::Controller);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    my $town = shift;
    my $game_settings = shift;
    $self->{'_town'} = $town;
    $self->setSettings($game_settings);
    $self->{'_controllers'}->{'weapon_store'} = Usurper::Controller::Area::WeaponStore->new($town->getWeaponStore());
    $self->{'_controllers'}->{'armor_store'} = Usurper::Controller::Area::ArmorStore->new($town->getArmorStore());
    $self->{'_controllers'}->{'level_masters'} = Usurper::Controller::Area::LevelMasters->new($town->getLevelMasters(), $self->_getLevelData());
    $self->{'_controllers'}->{'dungeon'} = Usurper::Controller::Area::Dungeon->new($town->getDungeon());
    $self->{'_controllers'}->{'magic_store'} = Usurper::Controller::Area::MagicStore->new($town->getMagicPlace());
    $self->{'_controllers'}->{'inn'} = Usurper::Controller::Area::Inn->new($town->getInn());
    $self->{'_controllers'}->{'bank'} = Usurper::Controller::Area::Bank->new($town->getBank());
    $self->{'_controllers'}->{'jail'} = Usurper::Controller::Area::Jail->new($town->getJail(), $game_settings->getDailySettings()->{'had_jail_escape_attempt'});
    $self->{'_controllers'}->{'stats'} = Usurper::Controller::Area::CharacterStats->new();
    return $self;
}

sub enter {
    my $self = shift;
    my $character = shift;

    if(!$character){
        return
    }

    if($character->isDead() && $character->getDaysDead() < 1){
        print "You already died today.  Try again tomorrow.  Hopefully you will have more luck!\n\r";
        $self->wait(2);
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return;
    }

    if($character->getHitpoints() == 0){
        $character->setHitpoints(1);#no longer dead
        $character->setDeadDate(undef);
    }

    $self->printIntroMessage($character);
    $self->wait(2);
    
    my $input = "?";
    my $just_released = 0;
    if($character->isJailed() && $character->getDaysInJail() >=2){
        print "Looks like today is your lucky day, you are being let out of jail today!  Behave yourself.\n\r";
        $input = "j";
        $character->setJailDate(undef);
        $character->setRestArea('');
        $just_released = 1;

    } elsif($character->isJailed()){
        $input = "j";
    } else {
        print "\n\rYou are standing on Main street right in the middle the town, where do you wish to go?\n\r\n\r";
        $character->setRestArea('');
    }
    $character->store();
    $self->pauseForUserInput("Press any key to continue...\n\r");
    $self->clearScreen();

    # main town loop
    while($input !~ m/q/i){
        my $return = 0;
        if($input =~ m/\?/i) {
            $input = $self->getUserInput($self->getMenuText());
            $self->clearScreen();
        } elsif ($input =~ m/v/i) {
            $self->getController('level_masters')->enter($character);
            $input = '?';
        } elsif($input =~ /j/){
            $return = $self->getController('jail')->enter($character, $just_released);
            $input = '?';
            $just_released = 0;
        }elsif ($input =~ m/m/i) {
            $self->getController('magic_store')->enter($character);
            $input = '?';
        } elsif ($input =~ m/w/i) {
            $self->getController('weapon_store')->enter($character);
            $input = '?';
        } elsif ($input =~ m/a/i) {
            $self->getController('armor_store')->enter($character);
            $input = '?';
        } elsif($input =~ m/b/i) {
            $return = $self->getController('bank')->enter($character);
            $input = '?';
        } elsif($input =~ m/i/i) {
            $return = $self->getController('inn')->enter($character);
            $input = '?';
        } elsif($input =~ m/s/i) {
            $self->getController('stats')->enter($character);
            $input = '?';
        } elsif($input =~ m/d/i) {
            $return = $self->getController('dungeon')->enter($character);
            $input = '?';
        } elsif($input =~ m/l/i) {
            $self->printCharacters();
            $input = '?';
        } else {
            $input = $self->getUserInput("\n\rMain Street (? for menu)");
        }
        if($return == -1){
            return -1;
        }
    }

    $character->setRestArea('dorm');
    $character->store();
    print "Your adventure is done for now, lets hope you stay alive while you are away.\n\r";
}

sub printIntroMessage {
    my $self = shift;
    my $character = shift;
    if($character->isJailed()){
        if($character->getDaysInJail() < 2 && $character->getRestArea() ne 'tunnel'){
            print "You wake up to a cold floor and bars on the doors and window.  You are in jail!\n\r";
        }
    } elsif($character->getRestArea() && $character->getRestArea() eq 'inn'){
        print "You leave your cozy suite, and head out the door to face the day.\n\r";
    } elsif($character->getRestArea() && $character->getRestArea() eq 'dorm') {
        print "You wake up in a pool of your own sweat.  The terrible noises from the previous night still linger in your head.  You force yourself up and head out the door to face the day.\n\r";
    } elsif($character->getRestArea() && $character->getRestArea() eq 'castle') {
        print "You leave the confines of the castle feeling rested and rejunvenated, you head out past the draw bridge to face the day\n\r";
    } elsif($character->getRestArea() && $character->getRestArea() eq 'new'){
        print "Welcome to ". $self->{'_town'}->getTownName() . ".  You aren't sure what you are getting yourself into, but you've heard interesting things are going on in this town.  Have fun exploring, and try not to die. \n\r";  
    }else {
        print "What happened last night?  You wake up in the middle of the street with no memory of how you got there.  You pick yourself up, dust yourself off and head down the street to face the day\n\r"
    }

}
sub printCharacters {
    my $self = shift;

    my $characters = Usurper::Factory::Character->new()->getAll();#not caching on purpose!(this way if you get a level raise or something else changes it will show up)
    my $character_iter = $characters->iterator();
	print "__________________________________________________\n\r\n\r";
	print "Level:   Name:                           Experience:\n\r";

    while(my $character = $character_iter->next()){
        my $is_npc = $character->getIsNPC() ? "(NPC)" : "";
        my $is_king = $character->getIsKing() ? "*K" : "";
        my $is_dead = $character->getHitpoints() == 0  ? "  *DEAD*" : "";
        print $character->getLevel() . "        ". $character->getName()."$is_npc $is_king $is_dead                            ". $character->getExperience(). "\n\r";
    }
	print "__________________________________________________\n\r";
    print "*K = King\n\r\n\r";
}

sub getController {
    my $self = shift;
    my $controller_name = shift;
    return $self->{'_controllers'}->{$controller_name};
}

sub getMenuText {
    return "            [W]eapon Shop           [R]esearch Center
            [A]rmor Shop            Al[c]hemist Place
            [V]isit Level Masters   B[E]ER HUT!!!!
            [M]agic Shop            [B]ank
            W[h]ore House           [D]ungeon
            [L]ist Characters       [K]ings Castle
            [S]tats                 D[o]rmitory
            [I]nn                   [Q]uit
\n\rMain Street (? for menu)";
}

sub _getLevelData {
    return {
        1=>1000,
        2=>3000,
        3=>7000,
        4=>15000,
        5=>30000,
        6=>45000,
        7=>50000,
        8=>65000,
        9=>80000,
        10=>100000,
        11=>130000,
        12=>160000,
        13=>190000,
        14=>220000,
        15=>255000,
        16=>290000,
        17=>330000,
        18=>360000,
        19=>400000,
        20=>500000,
        21=>600000,
        22=>800000,
        23=>1000000,
        24=>1300000,
        25=>1600000,
        26=>2000000,
        27=>2350000,
        28=>2700000,
        29=>3100000,
        30=>3700000,
        31=>4200000,
        32=>4900000,
        33=>5200000,
        34=>5500000,
        35=>5900000,
        36=>6200000,
        37=>7000000,
        38=>7100000,
        39=>7200000,
        40=>7300000,
        41=>7400000,
        42=>7500000,
        43=>7600000,
        44=>7700000,
        45=>7800000,
        46=>7900000,
        47=>8100000,
        48=>8300000,
        49=>8500000,
        50=>9000000,
    };

}
1;
