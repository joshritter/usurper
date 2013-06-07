package Usurper::Settings;

use strict;
use warnings;
use 5.008_000;

use Data::Dumper;

use base qw(Usurper::Controller);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->_loadSettings();
    return $self;

}

sub _loadSettings {

    my $self = shift;
    open(FILE, 'settings.st') or die "Can't read file 'filename' [$!]\n";  
    my $document = <FILE>; 
    close (FILE);
    my $VAR1;
    eval($document);
    
    if($@){
        die "unable to load settings: " . $@;
    }
    $self->{_db_host} = $VAR1->{'db_host'};
    $self->{_db_port} = $VAR1->{'db_port'};
    $self->{_db_user} = $VAR1->{'db_user'};
    $self->{_db_password} = $VAR1->{'db_password'};
    $self->{_db_name} = $VAR1->{'db_name'};
    $self->{_db_ssl} = $VAR1->{'db_ssl'};
}

sub setDailySettings {
    my $self = shift;
    $self->{'_daily_settings'} = shift;
}

sub getDailySettings {
    my $self = shift;
    return $self->{'_daily_settings'};
}
sub getDBHost {
    my $self = shift;
    return $self->{'_db_host'};
}

sub getDBPort {
    my $self = shift;
    return $self->{'_db_port'};
}

sub getDBUser{
    my $self = shift;
    return $self->{'_db_user'};
}

sub getDBPassword{
    my $self = shift;
    return $self->{'_db_password'};
}
sub getDBName {
    my $self = shift;
    return $self->{'_db_name'};
}

sub getUseSSL {
    my $self = shift;
    return $self->{'_db_ssl'};
}

1;
