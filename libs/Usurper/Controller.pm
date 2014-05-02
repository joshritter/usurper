package Usurper::Controller;

use strict;
use warnings;
use 5.008_000;

use Term::ReadKey;

use base qw(Usurper);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    return $self;
}

sub generateWhiteSpace {
    my $self = shift;
    my $spaces = shift;

    $spaces = 1 unless($spaces);

    return " " x $spaces;
}

#http://www.perlmonks.org/?node_id=653
sub commify {
    my $self = shift;
    local $_  = shift;
    1 while s/^(-?\d+)(\d{3})/$1,$2/;
    return $_;
}

sub formatNumber {
    my $self = shift;
    return $self->commify(shift);
}

sub printPlayerStats {
    my $self = shift;
    my $character = shift;
    my $show_all = shift;

    if(!$show_all){
        $show_all = 0;
    }

    print "---------------- Stats for ".$character->getName() . " ---------------------\n\r\n\r";
    print "Name:            ".$character->getName(). "\n\r";
    print "Level:           ".$character->getLevel(). "\n\r";
    print "Age:             ".$character->getAge(). "\n\r";
    print "Healings:        ".$character->getHealings(). "\n\r";
    print "Health:          ".$self->formatNumber($character->getHitpoints()). " / " . $self->formatNumber($character->getHitpointTotal()) . "\n\r";
    print "Sex:             ".$character->getSex(). "\n\r";
    print "Race:            ".$character->getRace(). "\n\r";
    print "Class:           ".$character->getClass(). "\n\r";
    print "Strength:        ".$self->formatNumber($character->getStrength()). "\n\r";
    print "Defense:         ".$self->formatNumber($character->getDefense()). "\n\r";
    if($show_all){
        print "Money on Hand:   ".$self->formatNumber($character->getMoneyOnHand()). "\n\r";
        print "Money in Bank:   ".$self->formatNumber($character->getMoneyInBank()). "\n\r";
    }
    my $weapon = $character->getWeapon();
    my $armor = $character->getArmor();
    if($weapon){
        print "Equipped weapon: ".$weapon->getName(). "\n\r";
    }
    if($armor){
        print "Equipped armor:  ".$armor->getName(). "\n\r";
    }
    print "Experience:      ".$self->formatNumber($character->getExperience()). "\n\r\n\r-----------------------------------------------------\n\r\n\r";
}

sub killCharacter {
    my $self = shift;
    my $character = shift;
    my $suppress_death_penalty = shift;

    $character->setHitpoints(0);
    #if player A kills player B, player B should not be unable to log in for the day - so don't set a dead date for player B
    if(!$suppress_death_penalty) {
        $character->setDeadDate(DateTime->today(time_zone => 'local')->strftime("%F %T"));
    }
    return $character->store();
}

sub clearScreen {
    print `clear`;
}

sub getUserInput {
    my $self = shift;
    my $text = shift;
    my $supress_key_strokes = shift || 0;

    my $input;
    print $text;
    if($supress_key_strokes) { 
        `stty -echo`;
    }
    $input = <STDIN>;
    if($supress_key_strokes) { 
        `stty echo`;
        print "\r\n";
    }
    $input =~ s/\s$//g;
    return $input;
}

sub pauseForUserInput {
    my $self = shift;
    my $message = shift;
    ReadMode 4; # Turn off controls keys
    print $message;
    my $key;
    while (not defined ($key = ReadKey(-1))) {
        # No key yet
    }
    print "\r\n";
    ReadMode 0; # Reset tty mode before exiting
}

sub wait {
    my $self = shift;
    my $seconds = shift;

    $seconds = (!$seconds) ? 2 : $seconds;

    sleep $seconds;
}
1;
