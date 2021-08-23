#!/usr/bin/perl -w
# Revision April 18,2005
# added delete command for *.arc.gz only
# and a shell script addition to gather information from the control file (Becky Hall)
# Revision January 5, 2006
# Added bouncehot option to first bounce the database and then run a HOT backup.i
# Removed delete of archive logs. (Becky Hall)
# Revision May 1, 2006
# At ~ line 340 added 4 lines to change the udump directory then create a text verion of the cotrolfile and
# then reset the udump directory.  The UDUMPDEST variable  will be set by running the following SQL.
# select value from v$parameter where name = 'user_dump_dest'; See the udumpdest subroutine.
# Revision June 30, 2006
# Added backup of temp files, this isn't strickly required but some of the databases don't like to come up without a temp files
# so now we have a copy to work with. (Becky Hall)
# Change backup of control to specify the file instead of changing the user_dump_dest. (Becky Hall)
# Executes a command or query within SVRMGR.  The output result is returned
# as an list of lines.
#
sub dbcmd {
  my ($cmd) = @_;
  my (@buf);

  $cmd =~ s/\$/\\\$/g;
  if ( -f "$ENV{ORACLE_HOME}/bin/svrmgrl" ) {
    open DATA, "$ENV{ORACLE_HOME}/bin/svrmgrl <<!
connect internal
$cmd;
quit
! |";
  } else {
    open DATA, "$ENV{ORACLE_HOME}/bin/sqlplus /nolog <<!
connect /as sysdba
set pagesize 777;
$cmd;
quit
! |";
  }

  @buf = ();
  while ($line = <DATA>) {
    chomp $line;
    if ($line) { push @buf, $line; }
  }
  close DATA;
  return @buf;
}

#
# Scans SVRMGR response strings looking for database errors.
#
sub dberror {
  my (@buf) = @_;
  my ($line, $err);

  $err = 0;
  foreach $line (@buf) {
    if ($line =~ /ORA-/) {
      print "$line\n";
      $err++;
    }
  }
  return $err;
}

#
# Returns a list of table space names.
#
sub tablespaces {
  my (@buf, $line);

  @DB = dbcmd(q{select tablespace_name from dba_tablespaces});
  while ($line = shift @DB) {
    if ($line =~ /^--------/) { last; }
  }
  while ($line = shift @DB) {
    if ($line =~ /^\d/) { last; }		# svrmgrl
    if ($line =~ /^SQL/) { last; }		# sqlplus
    $line =~ s/[ ]*//g;
    push @buf, $line;
  }
  return @buf;
}
#
# Returns a hash of datafiles vs. tablespace names.  Calculates the total
# size of all files and saves it in a global.
#
sub datafiles {
  my (@list) = @_;
  my (%hash, @file, $tbl, $line);

  $SIZE = 0;
  foreach $tbl (@list) {
    @DB = dbcmd(qq{select file_name from dba_data_files where tablespace_name = '$tbl'});
    while ($line = shift @DB) {                                 
      if ($line =~ /^--------/) { last; }                       
    }
    @file = ();
    while ($line = shift @DB) {          
      if ($line =~ /^\d/) { last; }		# svrmgrl
      if ($line =~ /^SQL/) { last; }		# sqlplus
      $line =~ s/[ ]*//g;
      push @{ $hash{$tbl} }, $line;
      (@sbuf) = stat $line;
      $SIZE += ($sbuf[7] / 1000);		# size in kb
    }                              
  }
  return %hash;
}

#
# Returns a list of redo log files.
#
sub redofiles {
  my (@buf, $line);

  @DB = dbcmd(q{select member from v$logfile union select file_name from dba_temp_files});
  while ($line = shift @DB) {
    if ($line =~ /^--------/) { last; }
  }
  while ($line = shift @DB) {
    if ($line =~ /^\d/) { last; }		# svrmgrl
    if ($line =~ /^SQL/) { last; }		# sqlplus
    $line =~ s/[ ]*//g;
    push @buf, $line;
  }
  return @buf;
}

#
# Returns a list of all other database files. PFILE is scaned for IFILE and
# CONTROL files.  IFILE if found is then searched for CONTROL FILES.
# Add the orapw file to the list. Archive log location is set in a global.
#
sub dbfiles {
  my (@buf, $line, $file, $tmp, $ifile, $pwfile, $spfile);

  $ifile = "";
  $file = sprintf "%s/dbs/init%s.ora", $ENV{ORACLE_HOME}, $ENV{ORACLE_SID};
  $spfile = sprintf "%s/dbs/spfile%s.ora", $ENV{ORACLE_HOME}, $ENV{ORACLE_SID};
  $pwfile = sprintf "%s/dbs/orapw%s", $ENV{ORACLE_HOME}, $ENV{ORACLE_SID};
  push @buf, $file;
  push @buf, $spfile;
#
# Scan pfile
#
  open DATA, $file;
  read DATA, $line, 200000;
  close DATA;
  $line =~ s/["']//g;
  if ($line =~ /ifile/) {
    ($tmp) = $line =~ /.*ifile\s+=\s+(\S+).*/;
    push @buf, $tmp
  }
#
# Grab control files
#
  @DB = dbcmd(q{select name from v$controlfile});
  while ($line = shift @DB) {
    if ($line =~ /^--------/) { last; }
  }
  while ($line = shift @DB) {
    if ($line =~ /^\d/) { last; }		# svrmgrl
    if ($line =~ /^SQL/) { last; }		# sqlplus
    $line =~ s/[ ]*//g;
    push @buf, $line;
  }
#
# Add the password file if present
#
  if (-f $pwfile) { push @buf, $pwfile; }

  return @buf;
}

#
# Function determines if database in in archive mode and sets the destination
# directory as a global.
#
sub archive_status {
  my ($line, $mode);

  @DB = dbcmd(q{archive log list});
  foreach $line (@DB) {
    if ($line =~ /Database log mode/) {
      if ($line =~ /No Archive/) { $mode = 0; }
      else { $mode = 1; }
    }
    if ($line =~ /Archive destination/) {
      $line =~ s/Archive destination//;
      $line =~ s/\s//g;
      $ARCLOGD = $line;
    }
  }
  if ($mode == 1) {		    	    # get archive file list
    dbcmd(qq{alter system switch logfile}); # Advance logfile
    sleep(3);                               # let archive complete

    open AFILE, "ls $ARCLOGD |";
    while ($afile = <AFILE>) {
      chomp $afile;
      push @AFILES, $afile;
    }
    close AFILE;
  }
  return $mode;
}

#
# Function determines if database in in archive mode and sets the destination
# directory as a global.
#
sub udumpdest {
  my ($line, $dumpdest);

  @DB = dbcmd(q{select value from v$parameter where name = 'user_dump_dest'});
  while ($line = shift @DB) {
    if ($line =~ /^--------/) { last; }
  }
  while ($line = shift @DB) {
    if ($line =~ /^\d/) { last; }               # svrmgrl
    if ($line =~ /^SQL/) { last; }              # sqlplus
    $line =~ s/[ ]*//g;
    $dumpdest = $line;
  }
  return $dumpdest;
}

#
# Returns the amount of space available on a filesystem (in KB).
#
sub sfree {
  my ($path) = @_;
  my (@arr, $line);

  if (! -e $path) { die "$path does not exist."; }

  open TMP, "df -k $path |";
  $line = <TMP>;			# the header
  $line = <TMP>;		# uncomment for linux systems
  @arr = split " ", <TMP>;
  close TMP;
  return $arr[2]; 	# replace $arr[3] with $arr[2] for linux systems
}

#
# Returns the amount of space used by a file or under a directory hierarchy
#
sub sused {
  my ($path) = @_;
  my (@arr, $line);

  if (! -e $path) { die "$path does not exist."; }

  open TMP, "du -sk $path |";
  @arr = split " ", <TMP>;
  close TMP;
  return $arr[0];
}

sub getoption {
  my ($arg) = @_;

  if ($arg =~ /c/) {
    if ( -f "/usr/bin/gzip") {
      $GZIP = "/usr/bin/gzip --fast";
    } elsif ( -f "/usr/local/bin/gzip") {
      $GZIP = "/usr/local/bin/gzip --fast";
    } else {
      die "Cannot perform compression, unable to locate gzip!";
    }
    $COMPRESS = 1;
  }
}

$GZIP = "";
$SIZE = 0;
$ARCMODE = 0;			# Default to No Archive Mode 
$COMPRESS = 0;
$ARCLOGD = "";
$BACKDIR = "/oraback";
$SCRIPTSOURCE = "/app/oracle/admin/maint";
if ( ! -d $BACKDIR) { die "$BACKDIR does not exist."; }

while ($ARGV[0] =~ /^-/) { getoption($ARGV[0]); shift @ARGV; }

if ( ! -f "/etc/oratab") { die "No ORATAB file"; }
if ($ARGV[0] eq "") { die "No instance specified"; }
if ($ARGV[1] eq "") { die "No backup type specified"; }
 

# set the environment
$ENV{ORACLE_HOME}="";
open TAB, "/etc/oratab";
while ($line = <TAB>) {
  @arr = split ':', $line;
  if ($arr[0] eq $ARGV[0]) {
    $ENV{ORACLE_HOME} = $arr[1];
    last;
  }
}
close TAB;
if ("$ENV{ORACLE_HOME}" eq "") { die "Instance $ARGV[0] not in ORATAB" }
$ENV{ORACLE_SID} = $ARGV[0];

$BACKDEST = "${BACKDIR}/backup/$ENV{ORACLE_SID}";
if ( ! -d $BACKDEST) { system("mkdir -p  $BACKDEST"); }
$ARCHDEST = "${BACKDIR}/archive/$ENV{ORACLE_SID}";
if ( ! -d $ARCHDEST) { system("mkdir -p  $ARCHDEST"); }


#
# Verify that the database is available
#
@DB = dbcmd(q{select * from v$database});
if (dberror(@DB)) { exit(1); }

# Check archive log mode
$ARCMODE = archive_status();

#
# Now get lists of required files
#   - TABLESPACES
#   - DATAFILES per tablespace
#   - REDO logs
#   - CONTROL files
#   - PFILE (opt. CONFIG file)
#   - location of archived redo logs
#
@tablespaces = tablespaces();
%files = datafiles(@tablespaces);
if ($COMPRESS) { $SIZE /= 10; }
if ($SIZE > (sfree($BACKDIR) + sused($BACKDIR))) {
   die "Insufficent space for backup of $ENV{ORACLE_SID} ${SIZE}Kb.";
}
@redologs = redofiles();
@cfiles = dbfiles();

# Now we're ready to go, clean up old backup
system("rm $BACKDEST/*");
#system("rm $ARCHDEST/*.arc.gz");
system("sh $SCRIPTSOURCE/filelist.sh $BACKDEST");

#system("$SCRIPTSOURCE/filelist.sh  $BACKDEST"); 

dbcmd(qq{create pfile from spfile});
$UDUMPDEST = udumpdest();
#dbcmd(qq{alter system set user_dump_dest = '$BACKDEST'});
dbcmd(qq{alter database backup controlfile to trace as '$BACKDEST/create_control.sql'});
#dbcmd(qq{alter system set user_dump_dest = '$UDUMPDEST'}); 
print "Udump Dest is: $UDUMPDEST \n";

# Go for it
if (($ARGV[1] eq "HOT") || ($ARGV[1] eq "BOUNCEHOT")){
  if ($ARCMODE == 0) {
    die "$ARGV[0] not in archive log mode, HOT backup cannot be done";
  }
  if ($ARGV[1] eq "BOUNCEHOT"){
    dbcmd(qq{shutdown abort});
    dbcmd(qq{startup });
  }
  # Now ensure that all tablespaces are not in backup mode.
  foreach $tbl (@tablespaces) { dbcmd(qq{alter tablespace $tbl end backup}); }

  # Open file log
  open LIST, "> $BACKDEST/dbfiles.lst";

  # Copy datafiles for each tablespace, after performing begin backup
  foreach $tbl (@tablespaces) {
    system("date '+%c:   start tablespace $tbl'");
    print LIST "Tablespace $tbl\n";
    dbcmd(qq{alter tablespace $tbl begin backup});
    foreach $entry (@{$files{$tbl}}) {
      if ($COMPRESS) {
        ($fname) = $entry =~ /^.+\/([^\/]+)$/;
        system("cat $entry | $GZIP -c > ${BACKDEST}/${fname}.gz");
      } else {
        system("cp $entry $BACKDEST");
      }
    }
    dbcmd(qq{alter tablespace $tbl end backup});
  }

  # Copy database files
  print LIST "Redologs\n";
  foreach $line (@redologs) { system("cp $line $BACKDEST"); }
  print LIST "Other files\n";
  foreach $line (@cfiles) { system("cp $line $BACKDEST"); }
  close LIST;
  system("date '+%c:   end backup'");
  # Transfer archived redo logs to backup location
  system("date '+%c:   start archive backup'");

  if ( "$ARCLOGD" eq "$ARCHDEST" ) {
    print "Archive Log destination is identical to Archive backup location.";
  } else {
    foreach $atmp (@AFILES) { system("mv $ARCLOGD/$atmp $ARCHDEST"); }
  }
  system("date '+%c:   archive maintance complete'");

} elsif ($ARGV[1] eq "COLD") {

  # Open file log
  open LIST, "> $BACKDEST/dbfiles.lst";

  # Take the database down
  dbcmd(qq{shutdown abort});
  dbcmd(qq{startup restricted}); 
  dbcmd(qq{shutdown}); 


  # Copy datafiles for each tablespace, after performing begin backup
  foreach $tbl (@tablespaces) {
    print LIST "Tablespace $tbl\n";
    system("date '+%c:   start tablespace $tbl'");
    foreach $entry (@{$files{$tbl}}) {
      if ($COMPRESS) {
        ($fname) = $entry =~ /^.+\/([^\/]+)$/;
        system("cat $entry | $GZIP -c > ${BACKDEST}/${fname}.gz");
      } else {
        system("cp $entry $BACKDEST");
      }
    }
  }

  # Copy database files
  print LIST "Redologs\n";
  foreach $line (@redologs) { system("cp $line $BACKDEST"); }
  print LIST "Other files\n";
  foreach $line (@cfiles) { system("cp $line $BACKDEST"); }
  close LIST;

  # Bring the database back up;
  dbcmd(qq{startup});
  system("date '+%c:   end backup'");
  if ($ARCMODE == 1) {
    # Transfer archived redo logs to backup location
    system("date '+%c:   start archive backup'");

    if ( "$ARCLOGD" eq "$ARCHDEST" ) {
      print "Archive Log destination is identical to Archive backup location.";
    } else {
      foreach $atmp (@AFILES) { system("mv $ARCLOGD/$atmp $ARCHDEST"); }
    }
    system("date '+%c:   archive maintance complete'");
  }

} else {
  die "$ARGV[1] is not a valid backup type.";
}

exit 0;

