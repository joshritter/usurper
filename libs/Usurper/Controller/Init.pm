package Usurper::Controller::Init;

use strict;
use warnings;
use 5.008_000;

use Usurper::Controller::CreateCharacter;
use Usurper::Model::Character;
use Usurper::Factory::Item;
use Usurper::Database;
use Usurper::Settings;

use POSIX;#for ceil
use Digest::MD5 qw(md5_hex);

#test
use base qw(Usurper::Controller);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'_db'} = Usurper::Database->new();
    $self->{'_settings'} = shift;
    return $self;

}

sub initCharacter {
    my $self = shift;
    my $character;
    my $login;
    my $password;
    while(!$character){
        $login = $self->getUserInput("Username(Type 'New' to create a new character): "); 
        if($login =~ m/new/i){
            $character = Usurper::Controller::CreateCharacter->new()->createNewCharacter($login, $password);
        } else {
            $password = md5_hex($self->getUserInput("Password: ", 1)); 
            $character = Usurper::Model::Character->new($login, $password);
            if(!$character){
                print "Couldn't find a character with that login, please try again \n\r";
            }
        }
    }
        
    return $character;
}

sub needsDailyReset {
    my $self = shift;
    my $db = $self->{'_db'};
    my $date = shift;

    my @split = split(/\s+/,$date);
    $date = $split[0];
    @split = split(/-/,$date);
    use Data::Dumper;
    my $last_update = DateTime->new(year=> $split[0], month => $split[1], day   => $split[2] );
    my $now = DateTime->now;

#    return 1;
    return $now->delta_days($last_update)->days;
}

sub dailyReset {
    my $self = shift;
    my $date = shift;
    my $db = $self->{'_db'};
    
    $db->writeQuery("DELETE from Settings");
    $db->writeQuery("INSERT INTO Settings (last_update, had_jail_escape_attempt) VALUES (NOW(), 0)");
    my $days = $self->needsDailyReset($date);
    my $rate = 1 + $self->{'_settings'}->getInterestRate() ;#interest
    if($days && $days > 1){
        $rate = $rate ** $days;
    }
    my $tax_rate = $self->{'_settings'}->getTaxRate();

    if($days && $days > 1){
        $tax_rate = $tax_rate ** $days;
    }

    $db->readQuery("SELECT sum(money_in_bank) as total from Characters");
    my $row = $db->fetchRow();
    my $sum = $row->{'total'};
    $db->writeQuery("UPDATE Characters SET dungeon_fights_per_day = ?, money_in_bank = money_in_bank * ? - money_in_bank * ?", 25, $rate, $tax_rate);
    return ($sum * $tax_rate)
}

sub reset {
    my $self = shift;
    my $db = $self->{'_db'};
    
    $db->writeQuery("DELETE from Settings");
    $db->writeQuery("INSERT INTO Settings (last_update) VALUES (NOW())");
    $self->initItems();
    $self->initMonsters();
    $self->initCharacters();

}

sub initCharacters {
    my $self = shift;
    my $db = $self->{'_db'};

    $db->writeQuery("DELETE from Characters");
    $db->writeQuery("ALTER TABLE Characters AUTO_INCREMENT = 1");

    #TODO init NPCS
    my $char = Usurper::Model::Character->new({ name => "Goku", defense => 1000, experience => 1600000, sex => 'm', age => 20, strength => 1500, level => 25, password => 'n/a',
                                                race => 'Sayian', class => 'Fighter', money_in_bank => 3000000, money_on_hand => 0, is_npc => 1, is_king => 1,
                                                hitpoint_total => 7000, hitpoints=> 7000, healings => 150, dungeon_fights_per_day => 25, rest_area => 'castle'});
    $char->store();
}

sub initItems {
    my $self = shift;
    my $db = $self->{'_db'};

    $db->writeQuery("DELETE from Item");
    $db->writeQuery("ALTER TABLE Item AUTO_INCREMENT = 1");
    $db->writeQuery("DELETE from CharacterItem");
    $db->writeQuery("ALTER TABLE CharacterItem AUTO_INCREMENT = 1");
    $self->initWeapons();
    $self->initArmors();
}

sub initWeapons {
    my $self = shift;
    my $db = $self->{'_db'};
    my $item = Usurper::Model::Item->new({ name => "Dagger", description => "A small measly weapon", type_id => 4, attributes => "\$VAR1 = {'cost' => 500, 'power' => 5}" });
    $item->store();
    $item = Usurper::Model::Item->new({ name => "Knife", description => "Is this made for cutting butter?", type_id => 4, attributes => "\$VAR1 = {'cost' => 1000, 'power' => 10}"});
    $item->store();
    $item = Usurper::Model::Item->new({ name => "Spear", description => "Good luck", type_id => 4, attributes => "\$VAR1 = {'cost' => 1500, 'power' => 15}"});
    $item->store();
    my $weapons = [
        { name => 'Whip', cost => 2500, power => 30, },{ name => 'ShortSword', cost => 3500, power => 50, },{ name => 'Cleaver', cost => 5000, power => 75, },{ name => 'Bloody-Cleaver', cost => 10000, power => 100, },{ name => 'Spirit-Blade', cost => 20000, power => 120, },{ name => 'Highland-Mace', cost => 30000, power => 130, },{ name => 'RustyNail', cost => 50000, power => 145, },{ name => 'DesertEagle', cost => 75000, power => 155, },{ name => 'Nija-Blade', cost => 90000, power => 170, },{ name => 'BloodSword', cost => 100000, power => 180, },{ name => 'SlayingStaff', cost => 500000, power => 200, },{ name => 'Ballista', cost => 600000, power => 220, },{ name => 'EagleHorn', cost => 700000, power => 230, },{ name => 'Windforce', cost => 900000, power => 275, },{ name => 'DeathFromAbove', cost => 1000000, power => 300, },{ name => 'MachineGun', cost => 2000000, power => 325, },{ name => 'Iron-Death', cost => 3000000, power => 350, },{ name => 'Trolls-Axe', cost => 3500000, power => 360, },{ name => 'Gilberts-Sling', cost => 4000000, power => 370, },{ name => 'Diamond-Fist', cost => 4500000, power => 400, },{ name => 'Aldairs-Axe', cost => 4750000, power => 415, },{ name => 'ColosusBlade', cost => 5000000, power => 430, },{ name => 'Martel-of-Pain', cost => 7500000, power => 450, },{ name => 'HolySword', cost => 10000000, power => 500, },{ name => 'DemonSword', cost => 50000000, power => 600, },{ name => 'WrathOfGod', cost => 100000000, power => 820, },{ name => 'Light-Sabre', cost => 200000000, power => 1000, },{ name => 'Cruel-Colosus', cost => 250000000, power => 1500, },{ name => 'GrandFather', cost => 400000000, power => 2500, },{ name => 'Last-Blade', cost => 900000000, power => 5000, },
    ];

    my $placeholder = "";
    my $values = [];
    foreach my $weapon (@$weapons) {
        $placeholder .= "(?, ?, ?, ?),";
        my $attributes = "\$VAR1 = {'cost' => ".$weapon->{cost}.",'power' => ".$weapon->{power}."};";
        push @$values, $weapon->{name}, "", $attributes, "4";
    }
    chop $placeholder;
    $db->writeQuery("INSERT INTO Item (name, description, attributes, type_id) VALUES $placeholder", @$values);
}

sub initArmors {
    my $self = shift;

    my $db = $self->{'_db'};
    my $item = Usurper::Model::Item->new({ name => "Grass Skirt", description => "Is this really helpful?", type_id => 5, attributes => "\$VAR1 = {'cost' => 500, 'power' => 12}" });
    $item->store();
    $item = Usurper::Model::Item->new({ name => "Toga", description => "Toga Toga Toga", type_id => 5, attributes => "\$VAR1 = {'cost' => 1000, 'power' => 30}"});
    $item->store();
    $item = Usurper::Model::Item->new({ name => "Bloody Shield", description => "Is that blood yours?", type_id => 5, attributes => "\$VAR1 = {'cost' => 3000, 'power' => 60}"});
    $item->store();
    my $armors = [{ name => 'Bronze_Helmet', cost => 10000, power => 150,    },{ name => 'Body_Armor', cost => 50000, power => 250,    },{ name => 'Air_Ellite', cost => 100000, power => 400,    },{ name => 'Kelvar_Suit', cost => 1000000, power => 800,    },{ name => 'DwarvenBodyArmor', cost => 10000000, power => 1000,    },{ name => 'Coat-O-Mail', cost => 300000000, power => 3000,    },];

    my $placeholder = "";
    my $values = [];
    foreach my $armor (@$armors) {
        $placeholder .= "(?, ?, ?, ?),";
        my $attributes = "\$VAR1 = {'cost' => ".$armor->{cost}.",'power' => ".$armor->{power}."};";
        push @$values, $armor->{name}, "", $attributes, "5";
    }
    chop $placeholder;
    $db->writeQuery("INSERT INTO Item (name, description, attributes, type_id) VALUES $placeholder", @$values);

}

sub initMonsters {
    my $self = shift;
    my $db = $self->{'_db'};
    my @names = (
        'Corpse', 'Mutant', 'Snake', 'Begger', 'Hacker', 'Bully', 'Fiend', 'Deviant', 'Ghoul', 'Witch', 'Corpse Flinger', 'Raider', 'Miscreant', 'Poo Flinger', 'Deathbringer', 'Peacemaker',
"Skeleton Frisky","Enkidu","Black Fomor","Werebat","Grave Digger","Weapon Master","Sea Demon","Skull Spider","Gelso","Nominon","Sea Stinger","Banshee","Arthro Skeleton","Abiondarg","Alastor","Aliorumnas","Altair","Alura Une","Amalric Sniper","Amduscias","Amphisbaena","Anaconda","Andras","Anthro Skeleton","Ape Skeleton","Arachne","Arabaki","Archer","Armor Knight","Armor Lord","Armored Fleaman","Armored Sprinter","Assassin Zombie","Astral Fighter","Astral Knight","Astral Warrior","Axe Armor","Axe Armor Lv. 2","Axe Knight","Azaghal","Bael","Bone-Throwing Skelton","Ball of Destruction","Balloon","Balloon Pod","Barbariccia","Basilisk","Bats","Beam Skeleton","Bee Hive","Beehive","Big Balloon","Biphron","Big Skeleton","Bitterfly","Black Crow","Black Panther","Blade","Blade Master","Blade Soldier","Blaze Master","Blaze Phantom","Blood Skeleton","Bloody Sword","Bloody Zombie","Blue Crow","Blue Raven","Blue Venus Weed","Bomber Armor","Bone Archer","Bone Ark","Bone Halberd","Bone Head","Bone Liquid","Bone Musket","Bone Pillar","Bone Scimitar","Bone Tower","Boomerang Armor","Bronze Guarder","Buer","Bugbear","Buster Armor","Cagnazzo","Catoblepas","Cave Troll","Centipod","Cerberus","Chaos Sword","Chronomage","Clear Bone","Cloaked Knight","Cockatrice","Coppelia","Corner Guard","Corpseweed","The Creature","The Creature From the Black Lagoon","Crossbow Armor","Crossbow Knight","Cthulhu","Curly","Cyclops","Dark Octopus","Dark Warlock","Dead Baron","Dead Crusader","Dead Fencer","Dead Mate","Dead Pirate","Dead Warrior","Deadly Toys","Death Mask","Death Reaper","Decarabia","Demon","Demon Lord","Demon Head","Devil","Devil Wheel","Dhuron","Diplocephalus","Disc Armor","Disc Armor Lv. 2","Discus Lord","Dodo","Dodo Bird","Dogether","Double Axe Armor","Dracula","Draghignazzo","Dragon Rider","Dragon Zombie","Dragonfly","Dryads","Duke Mirage","Dullahan","Durga","Eagle","Ectoplasm","Efreet","Elgiza","Erinys","Evil Butcher","Evil Core","Evil Stabber","Evil Sword","Executioner","Exploding Skeleton","Fire Man","Feather Demon","Fenrir","Final Guard","Fire Demon","Fire Warg","Fish Head","Fishman","Flail Guard","Flame Demon","Flame Knight","Flame Sword","Flame Zombie","Flea Armor","Flea Man","Flea Rider","Flesh Golem","Flying Armor","Flying Humanoid","Flying Skull","Flying Zombie","Forneus","Frankensteins Monster","Frog","Frost Demon","Frost Dragon","Frost Sword","Frost Zombie","Frozen Half","Frozen Shade","Gaap","Gaibon","Gargoyles","Gate Guarder","Gates of Death","Ghosts","Ghost Dancer","Ghost Dancer","Ghost Knight","Ghost Soldier","Ghost Warrior","Ghouls","Ghoul King","Gi-Lee","Giant Skeleton","Giant Slug","Giant Worm","Gladiator","Glaysa Labolas","Gold Medusa","Gold Skeleton","Golden Bones","Golden Knight","Golem","Gorgon","Grave Keeper","Great Armor","Great Axe Armor","Great Ghost","Gremlin","Gremlin (Fire)","Guardian","Guardian Armor","Guillotiner","Gurkha","Hammer-Hammer","Hammer Knight","Hanged Bones","Hanged Man","Harpy","Heart Eater","Heavy Armor","Hell Boar","Hellfire Beast","Hellhound","Hippogryph","Hill Guard","Homunculus","Hunchback","Hunting Girl","Imp","Invisible Man","Iron Gladiator","Iron Golem","Jack o Bones","Jin","Jp Bone Pillar","Kicker Skeleton","Killer Bee","Killer Clown","Killer Doll","Killer Fish","Killer Mantle","Knight","Kyoma Demon","Large Slime","Larva","Laura","Lerajie","Lesser Demon","Lilith","Lilim","Lightkeeper","Lightning Doll","Lion","Lizard Knight","Lizard Man","Lizard Shaman","Long Axe Knight","Lossoth","Lubicant","Mace Knight","Mace Skeleton","Mad Frog","Maggot","Magic Tome","Malachi","Malacoda","Malphas","Man-Eater","Maneating Plant","Man-Eating Plant","Mandragora","Manticore","Marionette","Master Lizard","Medusa Head","Melty Zombie","Merman","Mimic","Mimic (Treasure)","Mini Devil","Minotaur","Mirage Skeleton","Mist","Moldy Corpse","Mollusca","Mothman","Mud Demon","Mud Man","Mud Woman","Mummies","Mushussu","Necromancer","Needles","Nemesis","Nightmare","Nyx","O","Old Axe Armor","Orc","Orobourous","Ouija Table","Owl","Owl Knight","Paranoia Decoy","Paranthropus","Peeping Eye","Persephone","Phantom","Phantom Skull","Phantom Sword","Pike Master","Pillar of Bones","Pixie","Plate Lord","Poison Lizard","Poison Worm","Poison Zombie","Poltergeist","Procel","Quetzalcoatl","Rapid Sniper","Rare Ghost","Raven","Razor Bat","Red Axe Armor","Red Crow","Red Minotaur","Red Ogre","Red Skeleton","Ripper","Rock Armor","Rolling Stone","Rock Knight","Rolling Mirror","Rulers Sword","Rulers Sword Lv. 2","Rulers Sword Lv. 3","Rune Spirit","Rycuda","Salem Witch","Salomé","Sand Worm","Scarecrow","Schmoo","Shadow Knight","Shadow Wolf","Simon Wraith","Sirens","Skeledragon","Skelerang","Skeletons","Skeleton Ape","Skeleton Athletes","Skeleton Blaze","Skeleton Farmer","Skeleton Flail","Skeleton Flower","Skeleton Glass","Skeleton Guardian","Skeleton Gunman","Skeleton Hunter","Skeleton Knight","Skeleton Mirror","Skeleton Rib","Skeleton Rider","Skeleton Soldier","Skeleton Spider","Skeleton Spear","Skeleton Swordsman","Skeleton Tree","Skeleton Trooper","Skeleton Warrior","Skull Archer","Skull Bartender","Skull Lord","Skull Millione","Sky Fish","Slaughterer","Slime","Slinger","Slogra","Sniper of Goth","Sniper Orc","Soulless","Spartacus","Spear Guard","Specter","Spectral Sword","Spell Book","Spider Skeleton","Spin Devil","Spine","Spirits","Spittle Bone","Spriggan","Stain-Glass Ghost","Stain-Glass Knight","Stone Archer","Stone Rose","Stone Skull","Stolas","Storm Skeleton","Student Witch","Succubus","Sword Knight","Sword Lord","Sylph","Two-Headed Creature","Tanjelly","Testtube Zombie","Thief","Thornweed","Thunder Demon","Thunder Dragon","Thunder Sword","Tin Man","Tiny Devil","Tiny Slime","Toad","Tombstone","Tortured Soul","Treant","Triton","Tsuchinoko","Two-Headed Beast","Ukoback","Undead Lord","Une","Unicorn","Valhalla Knight","Valkyrie","Vampire","Vandal Sword","Vapula","Vassago","Venus Weed","Vice Beetle","Victory Armor","Waiter Skeleton","Wakwak Tree","Wall Widow","Warg","Warg Rider","Water Blob","Water Leaper","Werecat","Werejaguar","Wereskeleton","Weretiger","Werewolf","Whip-Toting Skeletons","White Dragon","White Dragon Lv. 2","White Dragon Lv. 3","White Gravial","Wight","Will o the wisp","Winged Guard","Winged Skeleton","Witches","Wizard","Wolf Skeleton","Wooden Golem","Wraith","Wyrm", 
"Blasphemer-master","Blaspheming Swimmer","Cosmic Freezer-blasphemer","Cursed Goblin","Dijinn Attacker","Fear Twister","Fen Mystic","Forgotten Snail","Goblin Choker","Grub-creature","Horror Wolf","Illuminated Cutter","Illuminated Master-chiller","Illusionmist","Lost Herder-enveloper","Penta Vision","Planetary Returned","Queen Cyclops","Returning Gibberer-brood","Rock Spectre","Seeking Bloom","Omega","Alpha","Underwater Lurk","Warrior Grub",);
    my $name_length = scalar(@names);

    $db->writeQuery("DELETE from Monster");
    $db->writeQuery("ALTER TABLE Monster AUTO_INCREMENT = 1");
    my $base_data = {
        level   => 1,
        low     => 9,
        high   => 35,
        health  => 55,
    };
    my $values = "";
    my $pos = 0;
    for(my $i =0;$i<101;$i++){
        my $dmg_multplier = .1;
        my $health_multplier = .25;
        if($i< 10){

        } elsif($i < 25){
            $dmg_multplier =  .22;
            $health_multplier = .30;
        } elsif($i < 50) {
            $dmg_multplier =  .33;
            $health_multplier = .39;
        }elsif($i< 75){
            $dmg_multplier =  .49;
            $health_multplier = .59;
        }elsif($i<99){
            $dmg_multplier = .85;
            $health_multplier = .75;
        }else {
            $dmg_multplier = 1.55;
            $health_multplier = 1.55;
        }
        my $level = $base_data->{'level'}+$i;
        my $low = ceil($base_data->{'low'}+$i*($base_data->{'low'}*$dmg_multplier));#10% dmg increase per level?
        my $high = ceil($base_data->{'high'}+$i*($base_data->{'high'}*$dmg_multplier));#10% dmg increase per level?
        my $health = ceil($base_data->{'health'}+$i*($base_data->{'health'}*$health_multplier));#10% dmg increase per level?
        for(my $j = 0; $j < 5; $j++){
            #my $pos = floor(rand($name_length-1));
            my $name = $names[$pos];
            $values .= "($level, '$name', $low, $high, $health),";
            $pos++;
        }
    }
    chop $values;#remove extra comma

    $db->writeQuery("INSERT INTO Monster (level, name, low, high, health) VALUES $values");
}
1;
