package Usurper::Controller::Area::Bank;

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
    
    print "You enter the bank, you see a sign that reads '".$store->getName()."', you walk up to the front counter hit\n\rthe bell to get someones attention.  The owner, ". $store->getOwner();
    print ", walks in from the back room and asks\n\rwhat you what you need.  What do you want to do next?\n\r\n\r";
    
    my $input = "?";
    while($input !~ m/r/i){
        if($input =~ m/\?/i){
            $input = $self->getUserInput($self->getMenuText());
        } elsif ($input =~ m/d/i){
            $self->depositMoney($character); 
            $input = "?";
        } elsif ($input =~ m/w/i){
            $self->withdrawMoney($character);
            $input = "?";
        } elsif ($input =~ m/s/i){
            print "You aren't near strong enough to pull that off!\n\r";
            #XXX implement
            $input = "?"; 
        } else {
            $input = $self->getUserInput("\n\rInn (? for menu)");
        }
    }
}

sub withdrawMoney {
    my $self = shift;
    my $character = shift;

    my $max_withdrawl = $character->getMoneyInBank();

    if($max_withdrawl< 1){
        print "You don't have any money to withdraw, quit wasting your own time!";
        return;
    }

    my $input = $self->getUserInput("How much do you want to withdraw? ( 0 - ".$self->formatNumber($max_withdrawl).", [A]ll my money ): ");

    if($input){
        $input =~ s/,//g;#remove commas if typed in
    }
    if($input =~ /a/i){
        $input = $max_withdrawl;
    } elsif($input =~ /\d+/){
        if($input > $max_withdrawl|| $input < 1){
            print "\n\rQuit messing around, I can't withdraw that amount and you know it!\n\r";
            return;
        }
    } else {
        print "\n\rThat isn't a valid amount, please enter how many gold coins you want to withdraw, or 'a' for all of the money in the bank.";
        return;
    }
    print "\n\rYou take your money and put it into your coin purse... lets hope someone doesn't try to take it from you.\n\r";
    $character->setMoneyOnHand($character->getMoneyOnHand() + $input);
    $character->setMoneyInBank($character->getMoneyInBank() - $input);
    $character->store();
}

sub depositMoney {
    my $self = shift;
    my $character = shift;

    my $max_deposit = $character->getMoneyOnHand();

    if($max_deposit < 1){
        print "You don't have any money to deposit, quit wasting your own time!";
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
    $character->setMoneyInBank($character->getMoneyInBank() + $input);
    $character->store();
}

sub getMenuText {
    return "        [D]eposit money
        [W]ithdrawl money
        [S]teal
        [R]eturn to main street\n\r\n\rBank (? for menu)";
}
1;
