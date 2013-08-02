package Usurper::Controller::Area::Castle;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller::Area);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{'_store'} = shift;

    my $king = Usurper::Factory::Character->new()->getKing();
    $self->{'_king'} = $king;
    return $self;
}

sub getKing {
    my $self = shift;
    return $self->{'_king'};
}

sub enter {
    my $self = shift;
    my $character = shift;

    $self->clearScreen();
    my $store = $self->{'_store'};

    if($character->getIsKing()){
        return $self->enterCastle($character);
    }

    print "Commoners are not allowed in the castle, so you make your way up the the front gate... What do you do next?\n\r";
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/u/i){
            my $winner = $self->infiltrateCastle($character); 
            if($winner && $winner->getID() == $character->getID()){
                $winner->setIsKing(1);
                $winner->store();
                my $king = $self->{'_king'};
                $king->setIsKing(0);
                $king->store();
                $self->{'_king'} = $winner;
                print "You have defeated the king!  The castle is now yours!!\n\r";
                $self->pauseForUserInput("Press any key to continue...\n\r");
                return $self->enterCastle($character);
            }
            return -1;
            $input = "?";
        }  else {
            $input = $self->getUserInput("\n\rCastle(? for menu)");
        }
    }
}

sub infiltrateCastle {
    my $self = shift;
    my $character = shift;

    my $king = $self->getKing();

    if(!$king){
        $character->setIsKing(1);
        $character->store();
        print "There is no king!  Time to fix that.  You kick open the castle doors, walk into the Kings chambers and place the crown on your head.  Long live the king!\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return $character;
    } else {
        ## add moat/gaurds before you get to the king
        print "You reach the Kings Chambers, the King chuckles loudly as he sees you walk in.  He is ready for you!\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return $self->fight($character, $king);
    }
}

sub enterCastle {
    my $self = shift;
    my $character = shift;

    print "You walk through the gates into the castle.  It is good to be home!\n\r";
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getKingMenuText());
        } elsif($input =~ /s/i){
            print "Good choice, there isn't a much safer place than the castle!\n\r";
            $character->setRestArea('castle');
            $character->store();
            return -1;
        }else {
            $input = $self->getUserInput("\n\rCastle(? for menu)");
        }
    }
    return 1;
}

sub getKingMenuText {
    return "        [K]ings Chamber
        [S]leep here for the night
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}
sub getMenuText {
    return "        [U]usurp the throne! Down with the king! 
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}
1;
