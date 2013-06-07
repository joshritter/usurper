package Usurper::Controller::Area::Jail;

use strict;
use warnings;
use 5.008_000;

use DateTime;
use base qw(Usurper::Controller::Area);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
   
    $self->{'_store'} = shift;
    my $escape_attempt = shift;
    $self->{'_can_escape'} = $escape_attempt ? 0 : 1;#only 1 attempt per day

    return $self;
}

sub canEscape {
    my $self = shift;
    return $self->{'_can_escape'};
}

sub setCanEscape {
    my $self = shift;
    $self->{'_can_escape'} = shift;
}

sub enter {
    my $self = shift;
    my $character = shift;
    my $just_released = shift;

    $self->clearScreen();
    my $store = $self->{'_store'};
   
    if($character->isJailed()){
        return $self->enterCell($character);
    }

    if($just_released){
        print "The lead gaurd walks up to the jail door, opens it up, and lets you out.  You take your belongings, what do you do next?\n\r";
    } else {
        print "You walk through the gate of the jail, you see a sign that reads '".$store->getName()."', you walk up to who appears to be the lead gaurd\n\r, ". $store->getOwner();
        print ".  He looks at you funny, what do you want to do next?\n\r\n\r";
    }
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif($input =~ /v/i) {
            $self->displayInmates();
            $input = "?";
        } elsif($input =~ /f/i) {
            $input = "?";
        } elsif($input =~ /b/i) {
            $input = "?";
        } else {
            $input = $self->getUserInput("\n\rPrison (? for menu) ");
        }
    }
}

sub enterCell {
    my $self = shift;
    my $character = shift;

    if($character->getRestArea() eq 'tunnel'){
        my $return = $self->enterTunnel($character, 1);
        if($return){
            return $return;
        }
    }
    print "You are in your cold dark cell.  \n\r\n\r";

    my $gaurd_tries = 0;
    my $input = "?";
    while($input !~ m/l/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getCellMenuText());
        } elsif($input =~ /o/i) {
            print "You are in a very plain cell.  No windows.  The door is made of solid iron, with one small rectangular piece that can slide up so they can feed you.  
Your bed is made of wood, there is no mattress, and no there are no sheets (hopefully you are a sound sleeper).  You do notice some cracks under the bed, you may want to move the bed
and look at this further.\n\r";
            $self->pauseForUserInput("Press any key to continue...\n\r");
            $input = "?";
        } elsif($input =~ /t/i) {
            if($gaurd_tries < 2){
                print "You shout at the gaurd to grab his attention.  You got it alright! He pulls you out of the cell beats you and throws you back.  Don't do that again!\n\r";
                $gaurd_tries++;
                $self->pauseForUserInput("Press any key to continue...\n\r");
            } elsif($gaurd_tries < 3){
                print "You are really pissing this gaurd off.  He beats you within an inch of your life.  I'd leave him alone if I were you!\n\r";  
                $gaurd_tries++;
                $self->pauseForUserInput("Press any key to continue...\n\r");
            } else {
                print "This time the gaurd seems really mad!  He pulls you out of the cell, takes his sword and beheads you!  You are DEAD! \n\r";
                $self->killCharacter($character);
                $self->pauseForUserInput("Press any key to continue...\n\r");
                return -1;
            }
            $input = "?";
        } elsif($input =~ /e/i) {
            print "You think escape is that easy?  If you want out of this place you are going to have to use your brain and find a way out!\n\r\n\r";
            $self->pauseForUserInput("Press any key to continue...\n\r");
            $input = "?";
        } elsif($input =~ /w/i) {
            $self->displayInmates($character);
            $input = "?";
        } elsif($input =~ /m/i) {
            my $return = $self->moveBed($character);
            if($return){
                return $return;
            }
            $input = "?";
        } else {
            $input = $self->getUserInput("\n\rPrison Cell(? for menu) ");
        }
    }

    print "You curl up into a ball and try to let you mind go blank so the time will pass you by.  Hopefully tomorrow will bring you more luck.\n\r";
    $self->pauseForUserInput("Press any key to continue...\n\r");

    return -1;
}

sub displayInmates {
    my $self = shift;
    my $character = shift;#current logged in inmate
    my $factory = Usurper::Factory::Character->new();

    my $inmates = $factory->getAllInJail();
    my $iterator = $inmates->iterator();

    #is this an inmate looking at the list?
    if($character && $inmates->size() == 1){
        print "Yours is the only name on the prison roster.  How lonely.\n\r";
        return;
    } elsif(!$character && !$inmates->size()){
        print "The prison roster is empty.  What a clean town this must be! \n\r";
        return;
    }

    print "You glance at the prisoner roster hanging in the hallway, it has the following names written on it.\n\r";
    my $inmate_string = "";
    while(my $inmate = $iterator->next()){
        if($character) {
            next if ($inmate->getID() == $character->getID());
        }
        $inmate_string .= $inmate->getName() . ", ";
    }
    chop $inmate_string;
    chop $inmate_string;
    print $inmate_string . "\n\r";
    $self->pauseForUserInput("Press any key to continue...\n\r");
    return;
}
sub moveBed {
    my $self = shift;
    my $character = shift;
    my $char_weapon = $character->getWeapon();

    if(!$char_weapon){
        print "You move the bed to the side and see what looks to be some very old, easy to break cement.  Unfortunetly you don't have any means of breaking it.  Good thinking though.\n\r\n\r";
        return;
    }

    if(!$self->canEscape()){
        print "You move the bed to the side and see what looks to be freshly poured cement under the bed.  Looks like someone had the same idea as you.  There is no getting through this cement. \n\r\n\r";
        return;
    }

    print "An idea strikes you all of a sudden, maybe you've seen to many old movies but you move your bed aside the ground looks pretty solid but there are some big cracks that catch your eye 
You pull out your " . $char_weapon->getName() . " and begin chipping away at the ground under the bed.\n\r\n\r";
    $self->wait(2);
    $self->pauseForUserInput("Press any key to continue...\n\r");
    print "Low and behold, all the movies were right!  Big chunks of the cement begin to break off, after swinging for what seems like hours the hole opens up into a dark musty tunnel (someone has done this before). \n\r\n\r"; 
    $self->wait(2);
    
    $self->pauseForUserInput("Press any key to continue...\n\r");
    print "You waste no time in cleaning up your mess and slipping down the hole, moving the bed over the hole as you go down in it.\n\r\n\r";
    $self->wait(2);
    $self->pauseForUserInput("Press any key to continue...\n\r");

    return $self->enterTunnel($character);
}

sub enterTunnel {
    my $self = shift;
    my $character = shift;
    my $is_returning = shift;

    my $db = Usurper::Database->new();
    $db->writeQuery("UPDATE Settings set had_jail_escape_attempt = 1");
    $self->setCanEscape(0);#update in memory as well as in the db

    $character->setRestArea('tunnel');
    $character->store();
    #they died or logged off somewhere in the tunnel, so reset them
    if($is_returning){
        print "You wake up in the tunnel, it seems you haven't made any progress through this maze yet, you see 2 paths before you, which way do you go?\n\r\n\r";
    } else {
        print "After waiting for 30 seconds for your eyes to adjust you see a split in the tunnel 15 feet ahead of you.  You walk up to the split, decision time!  Which way do you go?\n\r\n\r";
    }
    $self->pauseForUserInput("Press any key to continue...\n\r");

    my $input = "?";
    while($input !~ /l/i && $input !~ /r/i && $input !~ /b/i){
        $input = $self->getUserInput("\n\r[L]eft or [R]ight or [B]ack: ");
    }

    if($input =~ /b/i){
        return $self->exitTunnel($character);
    }

    print "You start walking down the path...\n\r";
    $self->wait(1);
    if($input =~ /r/i){
        $self->killCharacter($character); 
        print "A reflection catches your eye, you approach it slowly.\n\r";
        $self->pauseForUserInput("Press any key to continue...\n\r");
        print "The ground gives out underneath you, you fall for what seems like forever, you smash into rocks, you are DEAD.\n\r";
        return -1;
    }

    print "You come to yet another fork in the tunnel.  You hear the faint sound of water down the left path.  You can't be sure, but the path to the right seems brighter to you.  Which way?\n\r";
    
    $input = "?";
    while($input !~ /l/i && $input !~ /r/i && $input !~ /b/i){
        $input = $self->getUserInput("\n\r[L]eft or [R]ight or [B]ack: ");
    }

    if($input =~ /b/i){
        return $self->exitTunnel($character);
    }

    print "You start walking down the path...\n\r";
    $self->wait(1);

    if($input =~ /r/i){
        $self->killCharacter($character); 
        print "You walk cautiously down the tunnel path.  The tunnel gets lighter and lighter.  You start to feel warmth coming from up ahead...\n\r";
        $self->wait(2);
        print "A loud noise start to fill the room... you are DEAD.  You entered a lava tube and were just burned up by a lava flow. \n\r";
        return -1;
    }

    print "You walk for ages, the sound of water gets louder and louder.  It sounds like you are quickly approaching a very fast flowing body of water.\n\r";
    $self->pauseForUserInput("Press any key to continue...\n\r");
    
    print "The tunnel dead-ends with a huge raging underground river before your feet.  It looks like your only options are jumping in or going back.  What do you want to do? \n\r";
    $input = "?";
    while($input !~ /j/i && $input !~ /b/i){
        $input = $self->getUserInput("\n\r[J]ump in or [B]ack: ");
    }

    if($input =~ /b/i){
        return $self->exitTunnel($character);
    }

    my $chance = rand(10);
    if($chance <= .5){
        print "You jump in and the current immediately takes hold of you.  You are swept under the water.  You can't seem to gain control, you can't hold your breath any more.  Water pours down your throat.\n\r You are DEAD.\n\r\n\r";
        $self->killCharacter($character); 
        $self->pauseForUserInput("Press any key to continue...\n\r");
        return -1;
    }
    print "You jump in and the current immediately takes hold of you.  You are swept under and nearly drown.  Somehow you get control back in time to surface so you can breath. \n\r The current sweeps you down the tunnel until you are deposited on dry land, with yet more tunnel before you...\n\r";
    $self->wait(2);
    $self->pauseForUserInput("Press any key to continue...\n\r");
    print "You continue down the path...\n\r";
    $self->pauseForUserInput("Press any key to continue...\n\r");
    $character->setJailDate(undef);
    $character->store();
    print "You emerge from the tunnel into an alley adjacent from main street.  You replace the man hole cover, dust yourself off and head back to main street.  You escaped!\n\r";
    $self->wait(2);
    $self->pauseForUserInput("Press any key to continue...\n\r");
    return 1;

}

sub exitTunnel {
    my $self = shift;
    my $character = shift;
    $character->setRestArea('');
    $character->store();
    print "You head back out of this creepy tunnel.  As you poke your head out of the hole a gaurd grabs you by the hair, and pulls you out.  He takes you to a holding cell for about an hour. \n\r He takes you from the holding cell right back to your cell, they must be full!\n\r";
    $self->pauseForUserInput("Press any key to continue...\n\r");
    return;
}

sub getCellMenuText {
    return "        [W]ho else is in here with you?
        [T]alk to gaurd
        L[o]ok around your cell
        [E]scape
        [L]eave the game\n\r\n\rPrison Cell(? for menu) ";

}
sub getMenuText {
    return "        [V]iew prisoners
        [F]ree prisoner
        [B]ribe the gaurd
        [R]eturn to main street\n\r\n\rPrison(? for menu) ";
}
1;
