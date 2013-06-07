package Usurper::Controller::CreateCharacter;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Controller);

use Usurper::Database;
use Data::Dumper;

sub createNewCharacter {
    my $self = shift;
    my $login = shift;

    print "\n\rSo you want to enter the fray!?\n\r";
    my $new_login;
    while(!$new_login){
        $new_login = $self->getUserInput("\n\rWhat do you wish to be called? ");
        if($self->userNameExists($new_login)){
            $new_login = undef;
            print "\n\rTry again... someone with that name exists in this world already\n\r";
        }
    }

    my $char_data;
    $char_data->{'name'} = $new_login;
    my $race_char = $self->getUserInput("What race do you want to be?\n\r[T]roll\n\r[H]uman\n\r[M]utant\n\rH[o]bit\n\rm[i]dget\n\r[f]airy\n\r[g]nome\n\r[A]ndroid\n\r");

    if($race_char =~ m/t/i) {
        $char_data->{'race'} = "Troll";
    } elsif($race_char =~ m/h/i) {
        $char_data->{'race'} = "Human";
    }elsif($race_char =~ m/m/i) {
        $char_data->{'race'} = "Mutant";
    }elsif($race_char =~ m/o/i) {
        $char_data->{'race'} = "Hobit";
    }elsif($race_char =~ m/i/i) {
        $char_data->{'race'} = "Midget";
    }elsif($race_char =~ m/f/i) {
        $char_data->{'race'} = "Fairy";
    }elsif($race_char =~ m/g/i) {
        $char_data->{'race'} = "Gnome";
    }elsif($race_char =~ m/a/i) {
        $char_data->{'race'} = "Android";
    } else { 
        $char_data->{'race'} = "Human";
    }

    my $class_char = $self->getUserInput("What class do you want to be?\n\r[S]cientist\n\r[B]arbarian\n\r[A]lcehmist\n\r[P]aladin\n\rP[e]rvert\n\r");
    $char_data->{'strength'} = 10;
    $char_data->{'defense'} = 20;

    if($class_char =~ m/s/i){
        $char_data->{'class'} = "Scientist";
    }elsif($class_char =~ m/b/i){
        $char_data->{'class'} = "Barbarian";
        $char_data->{'strength'} = 40;
        $char_data->{'defense'} = 40;
    }elsif($class_char =~ m/a/i){
        $char_data->{'class'} = "Alcehmist";
        $char_data->{'strength'} = 15;
        $char_data->{'defense'} = 25;
    }elsif($class_char =~ m/p/i){
        $char_data->{'class'} = "Paladin";
        $char_data->{'strength'} = 35;
        $char_data->{'defense'} = 45;
    }elsif($class_char =~ m/e/i){
        $char_data->{'class'} = "Pervert";
        $char_data->{'defense'} = 10;
    }else {
        $char_data->{'class'} = "Scientist";
    }

    $char_data->{'password'} = "TODOFIX";
    $char_data->{'age'} = 18;
    $char_data->{'sex'} = 'm';
    $char_data->{'level'} = 1;
    $char_data->{'experience'} = 1000;
    $char_data->{'money_in_bank'} = 0;
    $char_data->{'money_on_hand'} = 10000;
    $char_data->{'is_npc'} = 0;
    $char_data->{'is_king'} = 0;
    $char_data->{'hitpoints'} = 500;
    $char_data->{'hitpoint_total'} = 500;
    $char_data->{'healings'} = 150;
    $char_data->{'dungeon_fights_per_day'} = 25;
    $char_data->{'rest_area'} = 'new';
    my $new_char = Usurper::Model::Character->new($char_data);
    $new_char->store();
    return $new_char;

}

sub userNameExists {
    my $self = shift;
    my $loginName = shift;
    my $db = new Usurper::Database();
    $db->readQuery("SELECT * from Characters where name = ?", $loginName);

    my $row = $db->fetchRow();

    if ($row) {
        return 1;
    }
    return 0;
}

1;
