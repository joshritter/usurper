package Usurper::Model::Character;

use strict;
use warnings;
use 5.008_000;

use Usurper::Database;
use Usurper::Factory::Item;
use Usurper::List;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless {}, $class;


    $self->{'_item_factory'} = Usurper::Factory::Item->new();
    my $login = shift;
    if($login){
        if(ref $login eq 'HASH'){
            return $self->initFromHash($login);
        }
        return $self->init($login);
    }

    return $self;
}




sub init {
    my $self = shift;
    my $login = shift;

    my $db = Usurper::Database->new();
    $db->readQuery("SELECT * from Characters where name = ?", $login);

    my $row = $db->fetchRow();

    if(!$row){
        #warn "Unable to load character with name: $login";
        return undef;
    }
    $self->initFromHash($row);

    $db->readQuery("SELECT *, ci.id as character_item_id from CharacterItem as ci LEFT JOIN Item as i on (i.id = ci.item_id) where character_id = ?", $self->getID());
    my $items = $self->{'_items'};
    while( $row = $db->fetchRow() ){
        $row->{'id'} = $row->{'item_id'};
        my $item = Usurper::Model::Item->new($row);
        $item->setAttribute("equipped", $row->{"equipped"});
        $item->setAttribute('character_item_id', $row->{'character_item_id'});
        $items->add($item);
    }
    return $self;
}

sub initFromHash {
    my $self = shift;
    my $row = shift;
    $self->setDefense($row->{'defense'});
    $self->setName($row->{'name'});
    $self->setExperience($row->{'experience'});
    $self->setSex($row->{'sex'});
    $self->setAge($row->{'age'});
    $self->setStrength($row->{'strength'});
    $self->setLevel($row->{'level'});
    $self->setPassword($row->{'password'});
    $self->setRace($row->{'race'});
    $self->setID($row->{'id'});
    $self->setClass($row->{'class'});
    $self->setMoneyOnHand($row->{'money_on_hand'});
    $self->setMoneyInBank($row->{'money_in_bank'});
    $self->setIsNPC($row->{'is_npc'});
    $self->setIsKing($row->{'is_king'});
    $self->setHitpointTotal($row->{'hitpoint_total'});
    $self->setHitpoints($row->{'hitpoints'});
    $self->setHealings($row->{'healings'});
    $self->setRemainingDungeonFights($row->{'dungeon_fights_per_day'});
    $self->setRestArea($row->{'rest_area'});
    $self->setJailDate($row->{'jail_date'});
    $self->setDeadDate($row->{'dead_date'});
    $self->{'_items'} = Usurper::List->new(); 

    return $self;
}

sub store {
    my $self = shift;
    my $db = Usurper::Database->new();

    $db->writeQuery("REPLACE INTO Characters 
        (id,name,password,age,sex,race,class,strength,defense,experience,level, money_on_hand, money_in_bank, is_npc, is_king,hitpoint_total,hitpoints, healings, dungeon_fights_per_day, rest_area, jail_date, dead_date)
        VALUES(?, ?, ?, ?, ?, ?, ?,? , ?, ? ,?,?,?,?,?,?,?,?,?,?,?,?)",
        $self->getID(),
        $self->getName(),
        $self->getPassword(),
        $self->getAge(),
        $self->getSex(),
        $self->getRace(),
        $self->getClass(),
        $self->getStrength(),
        $self->getDefense(),
        $self->getExperience(),
        $self->getLevel(),
        $self->getMoneyOnHand(),
        $self->getMoneyInBank(),
        $self->getIsNPC(),
        $self->getIsKing(),
        $self->getHitpointTotal(),
        $self->getHitpoints(),
        $self->getHealings(),
        $self->getRemainingDungeonFights(),
        $self->getRestArea(),
        $self->getJailDate() ? $self->getJailDate()->ymd("-") : undef,
        $self->getDeadDate() ? $self->getDeadDate()->ymd("-") : undef,
    );

    if (my $insert_id = $db->getLastInsertID()) {
        $self->setID($insert_id);
    }
    my $items = $self->{'_items'}->iterator();

    my $placeholder = "";
    my $values = [];
    while(my $item = $items->next()){
        $placeholder .= "(?, ?, ?),";
        push(@$values, $self->getID(), $item->getID(), $item->getAttribute('equipped') ? 1 : 0);
    }
    $db->writeQuery("DELETE FROM CharacterItem where character_id = ?", $self->getID());
    if($placeholder ne ""){
        chop $placeholder;
        $db->writeQuery("INSERT INTO CharacterItem (character_id, item_id, equipped) VALUES $placeholder", @$values);
    }
    
}

# returns the characters equipped weapon
sub getWeapon {
    my $self = shift;
    return $self->getItem('weapon');
}

sub getArmor {
    my $self = shift;
    return $self->getItem('armor');
}

# returns the characters equipped item by type 
sub getItem {
    my $self = shift;
    my $type = shift;

    my $iterator = $self->getItems()->iterator();

    my $item_types = $self->getItemFactory()->getItemTypes();
    while(my $item = $iterator->next()){
        if($item_types->{$type} == $item->getTypeID() && $item->getAttribute('equipped')){
            return $item;
        }
    }
    return undef;
}

sub getNonEquippedItems {
    my $self = shift;

    my $list = Usurper::List->new();
    my $iterator = $self->getItems()->iterator();
    while(my $item = $iterator->next()){
        if($item->getAttribute('equipped')){
            next;
        }
        $list->add($item);
    }
    return $list;
}

sub removeUnequippedItem {
    my $self = shift;
    my $pos = shift;

    my $current_pos = 0;
    my $iterator = $self->getItems()->iterator();

    #find the desired item to equip
    while(my $item = $iterator->next()){
        if($item->getAttribute('equipped')){
            next;
        }

        if($pos == $current_pos){
            $self->removeItem($iterator->index());
            last;
        }

        $current_pos++;
    }

}
sub getUnequippedItem {
    my $self = shift;
    my $unequipped_position = shift;

    my $current_pos = 0;
    my $item_to_equip = undef;
    my $iterator = $self->getItems()->iterator();

    my $pos;
    #find the desired item to equip
    while(my $item = $iterator->next()){
        if($item->getAttribute('equipped')){
            next;
        }

        if($unequipped_position == $current_pos){
            $item_to_equip = $item;
            $pos = $iterator->index();
            last;
        }

        $current_pos++;
    }
    return $item_to_equip;
}

sub equipItem {
    my $self = shift;
    
    my $unequipped_position = shift;

    my $current_pos = 0;
    my $item_to_equip = undef;
    my $iterator = $self->getItems()->iterator();

    my $pos;
    #find the desired item to equip
    while(my $item = $iterator->next()){
        if($item->getAttribute('equipped')){
            next;
        }

        if($unequipped_position == $current_pos){
            $item_to_equip = $item;
            $pos = $iterator->index();
            last;
        }

        $current_pos++;
    }
    
    if(!$item_to_equip){
        return undef;
    }

    $iterator = $self->getItems()->iterator();

    my $i= 0;
    #unequip any item of the same type
    while(my $item = $iterator->next()){
        if($item->getTypeID() == $item_to_equip->getTypeID()){
            $self->getItems()->get($i)->setAttribute('equipped', 0);
        }
        $i++;
    }

    #finally equip new item
    $self->getItems()->get($pos)->setAttribute('equipped', 1);
    $self->store();
    return $item_to_equip;

}

sub getItems {
    my $self = shift;
    return $self->{'_items'};
}

sub addItem {
    my $self = shift;
    my $item = shift;

    #XXX validation of actual item would be great
    $self->{'_items'}->add($item);
    return;
}

sub removeItem {
    my $self = shift;
    my $pos = shift;
    return $self->{'_items'}->remove($pos);
}

#
# geting stats of a character
#
sub getID{
    my $self = shift;
    return $self->{'_id'};
}

sub getPassword {
    my $self = shift;
    return $self->{'_password'};
}

sub getAge {
    my $self = shift;
    return $self->{'_age'};
}

sub getIsKing{
    my $self = shift;
    return $self->{'_is_king'};
}

sub getIsNPC{
    my $self = shift;
    return $self->{'_is_npc'};
}
sub getDefense {
    my $self = shift;
    return $self->{'_defense'};
}

sub getClass {
    my $self = shift;
    return $self->{'_class'};
}
sub getRace{
    my $self = shift;
    return $self->{'_race'};
}

sub getSex {
    my $self = shift;
    return $self->{'_sex'};
}
sub getLevel {
    my $self = shift;
    return $self->{'_level'};
}

sub getDaysInJail {
    my $self = shift;

    return unless $self->isJailed();
    my $now = DateTime->now;
    
    return $now->delta_days($self->getJailDate())->days;
}

sub isJailed {
    my $self = shift;
    return ($self->getJailDate() ? 1 : 0);
}

sub getJailDate {
    my $self = shift;
    return $self->{'_jail_date'};
}

sub setJailDate {
    my $self = shift;
    my $date_str = shift;

    if($date_str){
        my @split = split(/\s+/,$date_str);
        $date_str = $split[0];
        if($date_str){
            @split = split(/-/,$date_str);
            $self->{'_jail_date'} = DateTime->new(year=> $split[0], month => $split[1], day   => $split[2] );
        }
    }else {
        $self->{'_jail_date'} = undef;
    }

}

sub getDaysDead {
    my $self = shift;

    return unless $self->isDead();
    my $now = DateTime->now;
    
    return $now->delta_days($self->getDeadDate())->days;
}

sub isDead {
    my $self = shift;
    return ($self->getDeadDate() ? 1 : 0);
}

sub getDeadDate {
    my $self = shift;
    return $self->{'_dead_date'};
}

sub setDeadDate {
    my $self = shift;
    my $date_str = shift;

    if($date_str){
        my @split = split(/\s+/,$date_str);
        $date_str = $split[0];
        if($date_str){
            @split = split(/-/,$date_str);
            $self->{'_dead_date'} = DateTime->new(year=> $split[0], month => $split[1], day   => $split[2] );
        }
    }else {
        $self->{'_dead_date'} = undef;
    }

}

sub getRestArea {
    my $self = shift;
    return $self->{'_rest_area'};
}

sub setRestArea {
    my $self = shift;
    $self->{'_rest_area'} = shift;
}

sub getRemainingDungeonFights {
    my $self = shift;
    return $self->{'_dungeon_fights'};
}

sub setRemainingDungeonFights {
    my $self = shift;
    $self->{'_dungeon_fights'} = shift;
}


sub getHitpoints {
    my $self = shift;
    return $self->{'_hitpoints'};
}

sub setIsKing{
    my $self = shift;
    $self->{'_is_king'} = shift;
}

sub setIsNPC {
    my $self = shift;
    $self->{'_is_npc'} = shift;
}

sub setMoneyOnHand {
    my $self = shift;
    $self->{'_money_on_hand'} = shift;
}

sub setMoneyInBank {
    my $self = shift;
    $self->{'_money_in_bank'} = shift;
}

sub getMoneyOnHand {
    my $self = shift;
    return $self->{'_money_on_hand'};
}

sub getMoneyInBank {
    my $self = shift;
    return $self->{'_money_in_bank'};
}

sub getWeaponPrice {
    my $self = shift;
    return $self->{'_weapon_price'};
}

sub getWeaponPower {
    my $self = shift;
    return $self->{'_weapon_power'};
}

sub getArmorPower {
    my $self = shift;
    return $self->{'_armor_power'};
}

sub getArmorPrice{
    my $self = shift;
    return $self->{'_armor_price'};
}

sub getExperience {
    my $self = shift;
    return $self->{'_experience'};
}

sub getStrength {
    my $self = shift;
    return $self->{'_strength'};
}

sub getArmorName {
    my $self = shift;
    return $self->{'_armor_name'};
}

sub setName {
    my $self = shift;
    $self->{'_name'} = shift;
}

sub getName {
    my $self = shift;
    return $self->{'_name'};
}

sub getWeaponName {
    my $self = shift;
    return $self->{'_weapon_name'};
}

sub getState {
    my $self = shift;
    return $self->{'_state'};
}

sub getSleep {
    my $self = shift;
    return $self->{'_sleep'};
}

sub getHealings {
    my $self = shift;
    return $self->{'_healings'};
}

# changing stats
#

sub setID {
    my $self = shift;
    $self->{'_id'} = shift;
}

sub setPassword {
    my $self = shift;
    $self->{'_password'} = shift;
}

sub setLevel {
    my $self = shift;
    $self->{'_level'} = shift;
}

sub setAge {
    my $self = shift;
    $self->{'_age'} = shift;
}


sub setExperience{
    my $self = shift;
    $self->{'_experience'} = shift;
}

sub setDefense{
    my $self = shift;
    $self->{'_defense'} = shift;
}

sub setRace {
    my $self = shift;
    $self->{'_race'} = shift;
}

sub setSex {
    my $self = shift;
    $self->{'_sex'} = shift;
}

sub setClass {
    my $self = shift;
    $self->{'_class'} = shift;
}

sub setStrength {
    my $self = shift;
    $self->{'_strength'} = shift;
}
sub setHealings {
    my $self = shift;
    $self->{'_healings'} = shift;
}

sub levelRaise {
    my $self = shift;
    $self->{'_level'} = $self->{'_level'} +1;
}

sub increaseHitpoints {
    my $self = shift;
    my $increase = shift;
    $self->setHitpoints($self->getHitpoints() + $increase);
}

sub decreaseHitpoints {
    my $self = shift;
    $self->setHitpoints($self->getHitpoints() - shift);
}

sub increaseExperience {
    my $self = shift;
    $self->{'_experience'} = $self->getExperience() + shift;
}

sub increaseStrength {
    my $self = shift;
    $self->{'_strength'} = $self->getStrength() +shift;
}

sub increaseDefense {
    my $self = shift;
    $self->{'_defense'} = $self->getDefense() +shift;
}

sub spendMoney {
    my $self = shift;
    $self->{'_money_on_hand'} = $self->{'_money_on_hand'} - shift;
}


sub addMoney {
    my $self = shift;
    $self->{'_money_on_hand'} = $self->{'_money_on_hand'} + shift;
}

sub setState {
    my $self = shift;
    $self->{'_state'} = shift;
}

sub setSleep {
    my $self = shift;
    $self->{'_sleep'} = shift;
}

sub getHitpointTotal {
    my $self = shift;
    return $self->{'_hitpoint_total'};
}

sub setHitpoints {
    my $self = shift;
    $self->{'_hitpoints'} = shift;
}

sub setHitpointTotal {
    my $self = shift;
    $self->{'_hitpoint_total'} = shift;
}

sub getItemFactory {
    my $self = shift;
    return $self->{'_item_factory'};
}

1;
