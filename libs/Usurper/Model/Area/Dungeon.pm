package Usurper::Model::Area::Dungeon;

use strict;
use warnings;
use 5.008_000;

use base qw(Usurper::Model::Area);

sub new {
    my $class = shift;
    my $input = shift;
    $input->{'name'} = "Dungeon";
    my $self = $class->SUPER::new($input);

    $self->_init();

    return $self;
}

sub _init {
    my $self = shift;

    my $db = Usurper::Database->new();

    $db->readQuery("SELECT * FROM Monster");

    while(my $row = $db->fetchRow()){
        $self->{'_monsters'}->{$row->{'id'}} = $row;
        push @{$self->{'_monster_buckets'}->{$row->{'level'}}}, $row;
    }
}

sub getMonsters{
    my $self = shift;
    return values%{$self->{'_monsters'}};
}

sub getMonstersForLevel {
    my $self = shift;
    my $level = shift;
    return $self->{'_monster_buckets'}->{$level};
}

1;
