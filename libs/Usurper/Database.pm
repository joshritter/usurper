package Usurper::Database;

=head1 NAME

  Usurper::Database - Wrapper around DBI.

=head1 SYNOPSIS

  use Usurper::Database;

my $db = new Usurper::Database()

# For a read only query that can be sent to any read only servers
# that are syncronized, or the write master otherwise.
$db->readQuery("SELECT fname, lname FROM solstice.Person WHERE person_id=?", 15);

while (my $data_ref = $db->fetchRow()) {
warn "First: ".$data_ref->{'fname'};
warn "Last:".$data_ref->{'lname'};
}

# For any inserts/updates/deletes, that
# must go to the master
$db->writeQuery("INSERT INTO solstice.Person (fname, lname) VALUES (?, ?)", 'Patrick', 'Michaud');

# Get the id of that person
my $id = $db->getLastInsertID();

# Get a read lock (that is, lock other people from reading)
$db->readLock('solstice.Person');

# Get a write lock (that is, lock other people from writing)
$db->writeLock('solstice.Person');

# Unlock any locks
$db->unlockTable('solstice.Person');

=head1 DESCRIPTION

This object is here to make the database connections reliable and consistent
across the Usurper tools source tree. Unlike the most generic methods for
database connectivity, these methods are reliable and efficient in the mod_perl
environment.

**It is strongly recommended that you use this object to make all of your
database connections when programming perl source for the Usurper Tools**

=cut

use 5.008_000;
use strict;
use warnings;

use base qw(Usurper);

use DBI;
use Data::Dumper;
use Time::HiRes qw(gettimeofday tv_interval);
use Carp qw(confess cluck longmess shortmess);

use constant CONNECT_TIMEOUT => 10;
use constant SLAVE_CONNECT_TIMEOUT => 5;
use constant SLOW_QUERY_TIME => 10;
use constant FALSE => 0;
use constant TRUE => 1;

our ($VERSION) = ('$Revision: 2998 $' =~ /^\$Revision:\s*([\d.]*)/);

our %dbh_cache;
our %slave_dbh_cache;
our $slave_delay_max;


=head2 Export

No symbols exported.

=head2 Methods

=over 4

=item new()

Constructor. Creates a database handle and caches it.

=cut

use base qw(Usurper);

sub new {
    my $pkg = shift;

    my $self = $pkg->SUPER::new();
#    my $self = $pkg->SUPER::new(@_);
    $self->{'_dbh'} = $self->_connect();

    return $self;
}


##### Actual DB interaction

=item readQuery($sqlCommand [, $param]*)

For a read only query that can be sent to any read only servers that
are synchronized, or the write master. Dies on error, and returns undef.

=cut

sub readQuery {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for readQuery" unless $dbh;

    $self->_query( $dbh, @_ );

    return;
}

sub slaveQuery {
    my $self = shift;

    my $dbh = $self->_hasSlaves() ? $self->_getSlave() : $self->{'_dbh'};
    die "No database handle found for slaveQuery" unless $dbh;

    $self->_query( $dbh, @_ );

    return;
}



=item writeQuery($sql_command [, $param]*)

For any inserts/updates/deletes that must go to the master.
Dies on error, and returns undef.

=cut

sub writeQuery {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for writeQuery" unless $dbh;

    $self->_query( $dbh, @_ );

    return;
}


=item readLock($table_name)

Gets a read lock (lock other people from reading).
Dies on error, and returns undef.

=cut

sub readLock {
    my $self = shift;
    my $table_name = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for readLock" unless $dbh;

    my $statement = "LOCK TABLES $table_name READ";
    $self->_query($dbh, $statement);

    return;
}


=item writeLock($table_name)

Gets a write lock (lock other people from writing or reading).
Dies on error, and returns undef.

=cut

sub writeLock {
    my $self = shift;
    my $table_name = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for writeLock" unless $dbh;

    my $statement = "LOCK TABLES $table_name WRITE";
    $self->_query($dbh, $statement);

    return;
}


=item unlockTables()

Release any table locks. Dies on error, and returns undef.

=cut

sub unlockTables {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for writeLock" unless $dbh;

    my $statement = 'UNLOCK TABLES';
    $self->_query($dbh, $statement);

    return;
}







### Interact with data

=item fetchRow()

After a read query, fetches a row of results. Returns undef when
there aren't any more rows to read, otherwise returns a hash ref.

=cut

sub fetchRow {
    my $self = shift;

    return if !defined $self->{'_read_cursor'};

    my $row = $self->{'_read_cursor'}->fetchrow_hashref();
    if (!$row) {
        $self->{'_read_cursor'}->finish();
        delete $self->{'_read_cursor'};
    }
    return $row;
}


=item rowCount()

Return a count of rows returned by the last read query, or undef
if a read cursor is not defined.

=cut

sub rowCount {
    my $self = shift;

    return if !defined $self->{'_read_cursor'};
    return $self->{'_read_cursor'}->rows();
}


=item getLastInsertID()

Gets the id of the most recently inserted row.

=cut

sub getLastInsertID {
    my $self = shift;
    return $self->{'_last_insert_id'};
}

sub begin {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for begin" unless $dbh;
    $dbh->begin_work();
    return;
}

sub commit {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for commit" unless $dbh;
    $dbh->commit();
    return;
}

sub rollback {
    my $self = shift;

    my $dbh = $self->{'_dbh'};
    die "No database handle found for rollback" unless $dbh;
    $dbh->rollback();
    return;
}



=item DESTROY()

Destructor.

=cut

sub DESTROY {
    my $self = shift;
    $self->_releaseCursor();
}


=back

=head2 Private methods

=over 4

=cut

=item _query

performs the actual query, does timing and error checking

=cut

sub _query {
    my $self = shift;
    my $dbh = shift;
    my $statement = shift;
    my @params = @_;

    $self->_releaseCursor();

    my $diagnostic = 1;#$config->getDevelopmentMode() || $self->getDebugService()->useTag('slow_sql');
    my $time_taken;

    eval { $time_taken = $self->_queryInner($diagnostic, $dbh, $statement, @params); };
    my $error = $@;

    #error in a transaction
    if ($error && $dbh->{'AutoCommit'} == 0) {

        $dbh->rollback();
        $self->_disconnect();
        _reportErrorAndDie("In transaction:\n$error", $statement, \@params);


    }elsif($error){ #Error, no transaction

    #we retry a few types of errors outside of transactions
        if(
            $error =~ /^DBD::mysql::st execute failed: MySQL server has gone away/ ||
            $error =~ /^DBD::mysql::st execute failed: Deadlock found/ ||
            $error =~ /^DBD::mysql::st execute failed: Lost connection to MySQL server during query/
        ){
            $self->_disconnect();
            $dbh = $self->_connect();

            eval { $time_taken = $self->_queryInner($diagnostic, $dbh, $statement, @params); };
            if($@){
                _reportErrorAndDie("On retry:\n$@", $statement, \@params);
            }
        }else{
            _reportErrorAndDie("Plain statement:\n$error", $statement, \@params);
        }
    }

    if ( $diagnostic && ($time_taken > SLOW_QUERY_TIME) ) {
        cluck "SQL took $time_taken seconds";
    }

    return;
}

sub _queryInner {
    my $self = shift;
    my $diagnostic = shift;
    my $dbh = shift;
    my $statement = shift;
    my @params = @_;
    my $start_time;
    my $time_taken;

    $start_time = [gettimeofday] if $diagnostic;
    my $cursor = $dbh->prepare($statement);

# This is here to make it possible to track down warnings - there's usually no context at all w/o it
    local $SIG{__WARN__} = sub { cluck $_[0]; };

    $cursor->execute(@params);
    $time_taken = tv_interval($start_time, [gettimeofday]) if $diagnostic;
    $self->{'_last_insert_id'} = $cursor->{'mysql_insertid'};
    $self->{'_read_cursor'} = $cursor;

    return $time_taken;
}

=item _getSlave

Returns the database handle to a slave db.
If there are no slaves, returns the master database handle.

=cut


sub _getSlave {
    my $self = shift;

    my $slaves = undef;#$config->getDBSlaves();

    $self->_shuffle($slaves);

    for my $slave (@$slaves){
        my $hostname = $slave->{'host_name'};

        my $dbh = $slave_dbh_cache{$$}{$hostname};

        unless($dbh){
            $dbh = $self->_connectToSlave($slave);
            next unless $dbh;
            $slave_dbh_cache{$$}{$hostname} = $dbh;
        }

        if($self->_isSlaveCurrent($dbh)){
            return $dbh;
        }
    }

#oops, none of the slaves worked out
    return $self->{'_dbh'};
}

=item _hasSlaves

Returns a count of slaves available for connecting.

=cut

sub _hasSlaves {
    my $self = shift;
    return 0;
}




=item _isSlaveCurrent($dbh)

Takes a database handle and returns true or false if it is caught up with the master

=cut

sub _isSlaveCurrent {
    my $self = shift;
    my $dbh = shift;
    return FALSE unless defined $dbh;

    unless( defined $slave_delay_max ){
#        my $config = $self->getConfigService();
        $slave_delay_max = 60;
    }

    if($slave_delay_max){
        my $cursor = $dbh->prepare('SHOW SLAVE STATUS');
        $cursor->execute();
        $self->{'_read_cursor'} = $cursor;

        my $data = $self->fetchRow();
        $self->_releaseCursor();

        return FALSE unless $data;

        return ($data->{'Seconds_Behind_Master'} < $slave_delay_max);

    }else{
        return TRUE;
    }
}

=item _releaseCursor()

Releases the statement handle that was used for reading.

=cut

sub _releaseCursor {
    my $self = shift;
    if ($self->{'_read_cursor'}) {
        $self->{'_read_cursor'}->finish();
        delete $self->{'_read_cursor'};
    }
}

=item _disconnect()
=cut

sub _disconnect {
    my $self = shift;

    eval { $dbh_cache{$$}->disconnect(); };
    delete $dbh_cache{$$};
}



=item _connect()

Opens and returns the database handle.

=cut

sub _connect {
    my $self = shift;

    if (defined $dbh_cache{$$}){
        return $dbh_cache{$$};
    }

# get the configuration information
    my $host = $self->getSettings()->getDBHost();#"localhost";#$config->getDBHost();
    my $port = $self->getSettings()->getDBPort();#"3306";
    my $user = $self->getSettings()->getDBUser();#
    my $password = $self->getSettings()->getDBPassword();
    my $name = $self->getSettings()->getDBName();#"usurper";#$config->getDBName();
    my $ssl = $self->getSettings()->getUseSSL();#0;#$config->getDBUseSSL();

    my $connection_string = "DBI:mysql:$name:$host:$port:mysql_connect_timeout=".CONNECT_TIMEOUT;
    if($ssl){
        $connection_string .= ";mysql_ssl=1";
    }

# attempt to connect
    my $dbh = DBI->connect($connection_string, $user, $password,
        {RaiseError => TRUE});
    if (!$dbh) {
        _reportErrorAndDie("DBI->connect failed: ".$DBI::errstr, 'n/a');
    }

    $dbh->{'mysql_auto_reconnect'} = 1;
    $dbh->{'mysql_enable_utf8'} = 1;
    $dbh_cache{$$} = $dbh;
    return $dbh;
}

=item _connectToSlave(\%slave_params)

=cut

sub _connectToSlave {
    my $self = shift;
    my $slave_info = shift;

#return master if no slaves have been specified
    return $self->_connect() if !defined $slave_info;

    my $host = $slave_info->{'host_name'};
    my $port = $slave_info->{'port'};
    my $user = $slave_info->{'user'};
    my $password = $slave_info->{'password'};
    my $name = $slave_info->{'database_name'};
    my $connection_string = "DBI:mysql:$name:$host:$port:mysql_connect_timeout=".SLAVE_CONNECT_TIMEOUT;

# attempt to connect
    my $dbh;
    eval{
        $dbh = DBI->connect($connection_string, $user, $password,
            {RaiseError => TRUE});
    };

    warn "Slave not connecting: $@\n" if $@;

    return $dbh;
}

=back

=head2 Private functions

=over 4

=cut

=item _reportErrorAndDie($error, $sql, \@params)

Sends an email to the admin, and dies.

=cut

sub _reportErrorAndDie {
    my ($error, $sql, $params) = @_;

    local $Data::Dumper::Useperl = 1;
    my $param_string = Dumper $params;

    my $error_text = "$error\n\n".
    "The SQL statement that was being executed was:\n$sql\n\n".
    "With params:\n$param_string\n\n".
    "Stack trace ".Carp::longmess()."\n\n";

    confess $error_text;
    die $error_text;

}


=item _processMySQLDump($dbh, '/path/to/dumpfile.sql')

Takes a mysqldump file, and runs it.

=cut

sub processMySQLDump {
    my $self = shift;
    my $file = shift;
    my $dbh = shift || $self->{'_dbh'};


    open (my $DUMP_FILE, "<", $file);

    my $tables_def;
    my @inserts;
    my @deletes;
    while (<$DUMP_FILE>) {
# Strip out any comments and drop table lines
        next if (/^--/);
        next if (/^\/\*/);
        next if (/^DROP TABLE/);
        if (/^DELETE FROM/) {
            push @deletes, $_;
            next;
        }
        if (/^INSERT INTO/ || /^LOCK TABLES/ || /^UNLOCK TABLES/) {
            push @inserts, $_;
            next;
        }

        $tables_def .= $_;
    }

    close $DUMP_FILE;

    my @creates = split(/CREATE TABLE/, $tables_def);

# Remove the empty first entry...
    shift @creates;

    foreach (@creates) {
        if (!$dbh->do("CREATE TABLE $_")) {
            warn "Error on $_: $DBI::errstr\n";
            return;
        }
    }

    foreach (@deletes, @inserts) {
        if (!$dbh->do($_)) {
            warn "Error in $_: $DBI::errstr\n";
            return;
        }
    }
}

sub _shuffle {
    my $self = shift;
    my $deck = shift;
    my $i = @$deck;
    while ($i--) {
        my $j = int rand ($i+1);
        @$deck[$i,$j] = @$deck[$j,$i];
    }
}



1;

__END__

=back

=head2 Modules Used

L<DBI|DBI>,
L<Date::Dumper|Data::Dumper>,
L<Time::HiRes|Time::HiRes>,

=head1 AUTHOR

=head1 VERSION

$Revision: 2998 $



=cut
