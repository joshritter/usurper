package Usurper::Model::Area::Castle;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Castle";
    my $db = shift;
    my $self = $class->SUPER::new($input);

    $self->{'_db'} = $db;
    $self->_init();

    return $self;
}

sub store {
    my $self = shift;
    my $db = $self->{'_db'};

    $db->writeQuery("DELETE FROM Castle");
    $db->writeQuery("REPLACE INTO Castle (money) VALUES (?)", $self->getMoneyInVault());
    return $self;
}

sub _init {
    my $self = shift;
    my $db = $self->{'_db'};
    $db->readQuery("SELECT * from Castle");

    my $row = $db->fetchRow();

    if(!$row){
        #warn "Unable to load character with name: $login";
        return undef;
    }
    $self->initFromHash($row);

}

sub initFromHash {
    my $self = shift;
    my $data = shift;

    $self->setMoneyInVault($data->{'money'});
}

sub setMoneyInVault {
    my $self = shift;
    $self->{'_money_in_vault'} = shift;
}

sub getMoneyInVault {
    my $self = shift;
    return $self->{'_money_in_vault'};
}

1;
