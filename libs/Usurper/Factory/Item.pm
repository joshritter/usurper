package Usurper::Factory::Item;

use strict;
use warnings;
use 5.008_000;

use Usurper::Database;
use Usurper::Model::Item;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    $self->{'_types'} = {
        'weapon'    => 4,
        'armor'     => 5,
    };

    return $self;
}

sub getItemTypes {
    my $self = shift;
    return $self->{'_types'};
}


sub getByType {
    my $self = shift;
    my $type = shift;

    my $items = {};
    my $type_id = $self->{'_types'}->{$type};

    if(!$type_id){
        warn "unsupported type $type";
        return $items;
    }

    my $db = Usurper::Database->new();

    $db->readQuery("SELECT * from Item where type_id = ?", $type_id);

    while(my $row = $db->fetchRow()){
        my $item = Usurper::Model::Item->new($row);
        $items->{$item->getID()} = $item;
    }

    return $items;

}

1;
