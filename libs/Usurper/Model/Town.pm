package Usurper::Model::Town;

use strict;
use warnings;
use 5.008_000;

use Usurper::Model::Area::Dorm;
use Usurper::Model::Area::Inn;
use Usurper::Model::Area::WeaponStore;
use Usurper::Model::Area::ArmorStore;
use Usurper::Model::Area::Dungeon;
use Usurper::Model::Area::Brothel;
use Usurper::Model::Area::Bank;
use Usurper::Model::Area::ScienceCenter;
use Usurper::Model::Area::AlchemyAlcove;
use Usurper::Model::Area::Pub;
use Usurper::Model::Area::MagicPlace;
use Usurper::Model::Area::LevelMasters;
use Usurper::Model::Area::Jail;
use Usurper::Factory::Item;

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my $name = shift;
    my $db = shift;

    $self->init($name, $db);

    return $self;
}


sub init {
    my $self = shift;
    my $name = shift;
    my $db = shift;

    my $itemFactory = Usurper::Factory::Item->new();
    my $weapons = $itemFactory->getByType('weapon');
    my $armor = $itemFactory->getByType('armor');
    
    # XXX this should eventually be db backed - could have multiple towns??
    $self->{'_town_name'} = $name;
    $self->setArea('_dorm', Usurper::Model::Area::Dorm->new({"owner"=>"Radison"}));
    $self->setArea('_inn', Usurper::Model::Area::Inn->new({"owner" => "Bertha" }));
    $self->setArea('_weapon_store', Usurper::Model::Area::WeaponStore->new({"owner" => "Adolfo", "weapons" => $weapons }));
    $self->setArea('_armor_store', Usurper::Model::Area::ArmorStore->new({"owner" => "Mudolfo", "armors" => $armor }));
    $self->setArea('_dungeon', Usurper::Model::Area::Dungeon->new({"owner" => "Eegor" }));
    $self->setArea('_brothel', Usurper::Model::Area::Brothel->new({"owner" => "Chasey" }));
    $self->setArea('_bank', Usurper::Model::Area::Bank->new({"owner" => "Donald" }));
    $self->setArea('_science_center', Usurper::Model::Area::ScienceCenter->new({"owner" => "Steven" }));
    $self->setArea('_alchemy_alcove', Usurper::Model::Area::AlchemyAlcove->new({"owner" => "Albert" }));
    $self->setArea('_pub', Usurper::Model::Area::Pub->new({"owner" => "Boris" }));
    $self->setArea('_magic_place', Usurper::Model::Area::MagicPlace->new({"owner" => "Merlin" }));
    $self->setArea('_level_masters', Usurper::Model::Area::LevelMasters->new({"owner" => "Kai" }));
    $self->setArea('_jail', Usurper::Model::Area::Jail->new({"owner" => "Bert" }));
    $self->setArea('_castle', Usurper::Model::Area::Castle->new({"owner" => "Bert" }, $db));

}

sub getTownName {
    my $self = shift;
    return $self->{'_town_name'};
}

sub setArea {
    my $self = shift;
    my $area_key = shift;
    my $area = shift;
    $self->{'_areas'}->{$area_key} = $area;
}

sub getArea {
    my $self = shift;
    my $area = shift;
    return $self->{'_areas'}->{$area};
}

sub getCastle {
    my $self = shift;
    return $self->getArea('_castle');
}

sub getJail {
    my $self = shift;
    return $self->getArea('_jail');
}

sub getInn {
    my $self = shift;
    return $self->getArea('_inn');
}

sub getDorm {
    my $self = shift;
    return $self->getArea("_dorm");
}

sub getWeaponStore {
    my $self = shift;
    return $self->getArea('_weapon_store');
}

sub getLevelMasters {
    my $self = shift;
    return $self->getArea('_level_masters');
}

sub getArmorStore {
    my $self = shift;
    return $self->getArea('_armor_store');
}

sub getDungeon {
    my $self = shift;
    return $self->getArea('_dungeon');
}

sub getBrothel {
    my $self = shift;
    return $self->getArea('_brothel');
}

sub getBank {
    my $self = shift;
    return $self->getArea('_bank');
}

sub getScienceCenter {
    my $self = shift;
    return $self->getArea('_science_center');
}

sub getAlchemyAlcove {
    my $self = shift;
    return $self->getArea('_alchemy_alcove');
}

sub getPub {
    my $self = shift;
    return $self->getArea('_pub');
}

sub getMagicPlace{
    my $self = shift;
    return $self->getArea('_magic_place');
}


1;
