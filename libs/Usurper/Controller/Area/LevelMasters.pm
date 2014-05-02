package Usurper::Controller::Area::LevelMasters;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller::Area);

use Usurper::Factory::Character;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{'_store'} = shift;
    $self->{'_level_data'} = shift;

    return $self;
}

sub enter {
    my $self = shift;
    my $character = shift;

    $self->clearScreen();
    my $store = $self->{'_store'};

    print "You walk up to ". $store->getOwner() .", the level master, he looks you over and without saying a word turns around and goes about his business \n\r";
    print "What do you want to ask of him?\n\r\n\r";

    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/l/i){
            $self->getLevelRaise($character, $self->getLevelData());
            $input = "?";
        } elsif ($input =~ m/c/i){
            $self->crystalBall($character);
            $input = "?";
        } else {
            $input = $self->getUserInput("\n\rLevel Master(? for menu)");
        }
    }
    $self->clearScreen();
}

sub crystalBall {
    my $self = shift;
    my $character = shift;

    my $input = $self->getUserInput("Who do you wish to find?");

    my $factory = Usurper::Factory::Character->new();

    my $list = $factory->search($input);
    if($list->size() == 0){
        print "Quit wasting my time!  There is no one in this town with that name!\n\r";
    }

    my $iterator = $list->iterator();
    my $target = undef;
    while(my $current = $iterator->next()){
        $input = $self->getUserInput("Are you looking for ". $current->getName(). "? [Y]es or [N]o: ");


        if($input =~ /y/i){
            if($current->getIsKing()){
                print "You want me to spy on the king?? Get out! Traitor.\n\r\n\r";
                return;
            }

            $target = $current;
            last;
        }
    }

    if(!$target) {
        print "I'm sorry I cannot find the person you seek.  Please come back later.\n\r\n\r";
        return;
    }

    #TODO add cost
    print "Ah ha!  I have found ". $target->getName() .", give me a moment...\n\r";
    $self->wait(1);
    print ".\n\r";
    $self->wait(1);
    print ".\n\r";
    $self->wait(1);
    print ".\n\r\n\r";

    $self->printPlayerStats($target);
    $self->pauseForUserInput("Press any key to continue...\n\r");
}

sub getLevelRaise {
    my $self = shift;
    my $character = shift;

    my $level_data = $self->getLevelData();
    my $current_char_level = $character->getLevel();

    my $experience_for_next_level;
    if($current_char_level) {
        $experience_for_next_level = $level_data->{($current_char_level+1)};
    } else {
        return;
    }

    if(!$experience_for_next_level){
        print "There is nothing more for me to teach you, I hope you use your knowledge well.\n\r\n\r";
        return;
    }

    if($character->getExperience() >= $experience_for_next_level){
        print "You are worthy of a level raise...\n\r";
        sleep 2;
        my $increase_stats = 10;# *$character->getLevel();
        print"You gain $increase_stats strength...\n\r";
        sleep 2;
        print"You gain $increase_stats defense...\n\r";
        sleep 2;
        print"You receive " . ($character->getLevel())*1000 . " gold coins...\n\r\n\r";
        $character->increaseHitpoints(10*$character->getLevel());
        $character->setHitpointTotal($character->getHitpointTotal() + (10*$character->getLevel()));
        $character->increaseDefense($increase_stats);
        $character->increaseStrength($increase_stats);
        $character->addMoney(($character->getLevel())*1000);
        $character->levelRaise();
        $character->store();
        sleep 2;
        $self->pauseForUserInput("Press any key to continue...\n\r");
    } else {
        my $diff = $experience_for_next_level - $character->getExperience();
        print "You don't have enough experience for a level raise, you are ".$self->formatNumber($diff)." short, go and train some more.\n\r\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
    }

}
sub getMenuText {
    return "        [L]evel Raise
        [C]rsytal ball someone
        [R]eturn to main street\n\r\n\rLevel Master(? for menu)";
}

sub getLevelData {
    my $self = shift;
    return $self->{'_level_data'};
}

1;
