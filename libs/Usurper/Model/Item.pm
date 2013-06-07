package Usurper::Model::Item;

use strict;
use warnings;
use 5.008_000;

use Usurper::Database;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
  
    my $input = shift;
    if($input){
        if(ref $input eq 'HASH'){
            return $self->initFromHash($input);
        }
        return $self->init($input);
    }

  
    return $self;
}

sub init {
    my $self = shift;
    my $id = shift;

    my $db = Usurper::Database->new();
    $db->readQuery("SELECT * from Item where id = ?", $id);

    my $row = $db->fetchRow();

    if(!$row){
        return undef;
    }
    $self->initFromHash($row);
}

sub initFromHash {
    my $self = shift;
    my $row = shift;
    $self->setID($row->{'id'});
    $self->setName($row->{'name'});
    $self->setTypeID($row->{'type_id'});
    $self->setDescription($row->{'description'});
    $self->_loadAttributes($row->{'attributes'});

    return $self;
}

sub store {
    my $self = shift;

    my $db = Usurper::Database->new();

    $Data::Dumper::Indent = 0;

    $db->writeQuery("REPLACE INTO Item 
        (id,name,type_id,description,attributes)
        VALUES(?, ?, ?, ?, ?)",
        $self->getID(),
        $self->getName(),
        $self->getTypeID(),
        $self->getDescription(),
        Dumper($self->getAttributes()),
    );

    if (my $insert_id = $db->getLastInsertID()) {
        $self->setID($insert_id);
    }
}

sub getName {
    my $self = shift;
    return $self->{'_name'};
}

sub setName {
    my $self = shift;
    my $name = shift;
    $self->{'_name'} = $name;
}

sub getID {
    my $self = shift;
    return $self->{'_id'};
}

sub setID {
    my $self = shift;
    my $name = shift;
    $self->{'_id'} = $name;
}

sub getTypeID {
    my $self = shift;
    return $self->{'_type_id'};
}

sub setTypeID {
    my $self = shift;
    my $name = shift;
    $self->{'_type_id'} = $name;
}

sub getDescription {
    my $self = shift;
    return $self->{'_description'};
}

sub setDescription {
    my $self = shift;
    my $name = shift;
    $self->{'_description'} = $name;
}

sub get {
    my $self = shift;
    return $self->getAttribute(@_);
}

sub getAttributes {
    my $self = shift;
    return $self->{"_attributes"};
}

sub setAttribute {
    my $self = shift;
    my $attribute_key = shift;
    my $attribute_value = shift;
    $self->getAttributes()->{$attribute_key} = $attribute_value;
    
}

sub getAttribute {
    my $self = shift;
    my $attribute_key = shift;
    my $attributes = $self->getAttributes();
    return $attributes->{$attribute_key};
    
}

sub _loadAttributes {
    my $self = shift;
    my $VAR1;
    eval(shift);
    if($@){
        die "unable to load attributes " . $@;
    }
    $self->{_attributes} = $VAR1;
}


1;
