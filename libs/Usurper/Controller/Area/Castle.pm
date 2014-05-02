package Usurper::Controller::Area::Castle;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller::Area);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();

    $self->{'_castle'} = shift;
    $self->{'_settings'} = shift;

    my $king = Usurper::Factory::Character->new()->getKing();
    $self->{'_king'} = $king;
    return $self;
}

sub getCastle {
    my $self = shift;
    return $self->{'_castle'};
}

sub getKing {
    my $self = shift;
    return $self->{'_king'};
}

sub getSettings {
    my $self = shift;
    return $self->{'_settings'};
}

sub updateCastleSettings {
    my $self = shift;
    my $input = shift;

    my $castle = $self->getCastle();
    $castle->setMoneyInVault($castle->getMoneyInVault() + $input->{'_money_from_taxes'});
    $castle->store();
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
    while($input !~ m/r/i) {
        if($input =~ m/\?/i) {
            $input = $self->getUserInput($self->getKingMenuText());
        } elsif($input =~ m/k/i) {
            $input = $self->enterKingsChambers($character);
        } elsif($input =~ /s/i) {
            print "Good choice, there isn't a much safer place than the castle!\n\r";
            $character->setRestArea('castle');
            $character->store();
            return -1;
        } else {
            $input = $self->getUserInput("\n\rCastle(? for menu)");
        }
    }
    return 1;
}

sub enterKingsChambers {
    my $self = shift;
    my $character = shift;

    my $input = "?";
    while($input !~ m/r/i) {
        if($input =~ m/\?/i) {
            $input = $self->getUserInput($self->getKingsChamberMenuText());
        } elsif($input =~ m/o/i) {
            $input = $self->viewOrders($character);
        } elsif($input =~ m/s/i) {
           return 's';
        } else {
            $input = $self->getUserInput("\n\rKings Chambers(? for menu)");
        }
    }
    return 1;

}

sub viewOrders {
    my $self = shift;
    my $character = shift;

    my $input = "?";
    while($input !~ m/r/i) {
        if($input =~ m/\?/i) {
            $input = $self->getUserInput($self->getOrdersMenuText());
        } elsif($input =~ m/s/i) {
            print "Choose your tax rate wisely! You can tax up to 7% of your subjects money per day.";
            my $rate = $self->getUserInput("What would you like to set your taxes to?: [0-7]");
            while($rate !~ m/\d/ || $rate < 0 || $rate > 7){
                $rate = $self->getUserInput("Invalid input, please enter a valid tax rate [0-7]"); 
            }
            $self->getSettings()->setTaxRate($rate / 100);
            $self->getSettings()->storeSettings(); 
            if($rate > 5) {
                print "You've set the tax rate to $rate %, you can feel the tears of your subjects already!  The people won't stand for this for long."
            }elsif($rate > 3) {
                print "You've set the tax rate to a heafty $rate%.";
            }elsif($rate > 0) {
                print "You've set the tax rate to a mere $rate%.  The people rejoice";
            } else {
                print "You have removed all taxes.  Be careful your subjects don't read your kindess as weakness!";
            }
            print "\n\r";
            $input = "?";
        } elsif($input =~ m/b/i) {
            $input = "?";
        } elsif($input =~ m/h/i) {
            $input = "?";
        } elsif($input =~ m/d/i) {
            $self->depositMoney($character);
            $input = "?";
        } elsif($input =~ m/w/i) {
            $self->withdrawMoney($character);
            $input = "?";
        } else {
            $input = $self->getUserInput("\n\rOrders(? for menu)");
        }
    }
    return 1;

}

sub getOrdersMenuText{
    return "        [S]et taxes
        [B]eef up castle defenses (moat monsters)
        [H]ire gaurds
        [D]eposit money into the Kings's vault
        [W]ithdrawl money from the Kinds's vault
        [R]eturn Chambers\n\r\n\rOrders(? for menu)";
}

sub getKingMenuText {
    return "        [K]ings Chamber
        [S]leep here for the night
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}

sub getKingsChamberMenuText {
    return "        [S]leep
        [O]rders
        [J]ail
        [R]eturn to Castle\n\r\n\rKings Chambers(? for menu)";

}

sub getMenuText {
    return "        [U]usurp the throne! Down with the king! 
        [R]eturn to main street\n\r\n\rCastle(? for menu)";
}

sub withdrawMoney {
    my $self = shift;
    my $character = shift;

    my $max_withdrawl = $self->getCastle()->getMoneyInVault();#$character->getMoneyInBank();

    if($max_withdrawl< 1){
        print "The vault is empty!  You had better raise tax rates!\n\r\n\r";
        return;
    }

    my $input = $self->getUserInput("How much do you want to withdraw? ( 0 - ".$self->formatNumber($max_withdrawl).", [E]mpty the vault): ");

    if($input){
        $input =~ s/,//g;#remove commas if typed in
    }
    if($input =~ /e/i){
        $input = $max_withdrawl;
    } elsif($input =~ /\d+/){
        if($input > $max_withdrawl|| $input < 1){
            print "\n\rQuit messing around, I can't withdraw that amount and you know it!\n\r";
            return;
        }
    } else {
        print "\n\rThat isn't a valid amount, please enter how many gold coins you want to withdraw, or 'e' for all of the money in the vault.\n\r\n\r";
        return;
    }
    print "\n\rYou take your money and put it into your coin purse... let us hope your citizens don't find out.\n\r";
    $character->setMoneyOnHand($character->getMoneyOnHand() + $input);
    $self->getCastle()->setMoneyInVault($self->getCastle()->getMoneyInVault() - $input);
    $self->getCastle()->store();
    $character->store();
}

sub depositMoney {
    my $self = shift;
    my $character = shift;

    my $max_deposit = $character->getMoneyOnHand();

    if($max_deposit < 1){
        print "You don't have any money to deposit, quit wasting your own time!\n\r\n\r";
        return;
    }

    my $input = $self->getUserInput("How much do you want to deposit? ( 0 - ".$self->formatNumber($max_deposit).", [A]ll my money ): ");

    if($input){
        $input =~ s/,//g;#remove commas if typed in
    }

    if($input =~ /a/i){
        $input = $max_deposit;
    } elsif($input =~ /\d+/){
        if($input > $max_deposit || $input < 1){
            print "\n\rQuit messing around, I can't deposit that amount and you know it!\n\r";
            return;
        }
    } else {
        print "\n\rThat isn't a valid amount, please enter how many gold coins you want to deposit, or 'a' for all of the money on you.\n\r";
        return;
    }

    print "\n\rYou hand over your money... good choice, it is much safer here!\n\r";
    $character->setMoneyOnHand($character->getMoneyOnHand() - $input);
    $self->getCastle()->setMoneyInVault($self->getCastle()->getMoneyInVault() + $input);
    $self->getCastle()->store();
    $character->store();
}
1;
