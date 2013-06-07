package Usurper::Factory::Character;

use strict;
use warnings;
use 5.008_000;

use Usurper::Database;
use Usurper::List;
use Usurper::Model::Character;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    return $self;
}

sub search {
    my $self = shift;
    my $partial_name = shift;

    if(length($partial_name) < 3){
        return Usurper::List->new();
    }
    $partial_name = "%".$partial_name."%";

    my $db = Usurper::Database->new();
    $db->readQuery("SELECT * FROM Characters where name LIKE ? ORDER BY level DESC, experience DESC", $partial_name);
    return $self->_buildList($db);
}

sub getAllInJail {
    my $self = shift;

    my $db = Usurper::Database->new();

    $db->readQuery("SELECT * FROM Characters where jail_date IS NOT NULL ORDER BY level DESC, experience DESC");

    return $self->_buildList($db);
}

sub getAll {
    my $self = shift;

    my $db = Usurper::Database->new();

    $db->readQuery("SELECT * FROM Characters ORDER BY level DESC, experience DESC");

    return $self->_buildList($db);
}


sub _buildList {
    my $self = shift;
    my $db = shift;

    my $list = Usurper::List->new();
    while(my $row = $db->fetchRow()){
        my $character = Usurper::Model::Character->new($row);
        $list->add($character);
    }

    return $list;

}
1;
