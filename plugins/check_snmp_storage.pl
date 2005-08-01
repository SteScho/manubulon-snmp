#!/usr/bin/perl
############################## check_snmp_storage ##############
# Version : 1.1
# Date :  Feb 16 2005
# Author  : Patrick Proy ( patrick at proy.org)
# Help : http://www.manubulon.com/nagios/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# TODO : better options in snmpv3
#################################################################
#
# help : ./check_snmp_storage -h
 
use strict;
use Net::SNMP;
use Getopt::Long;

# Nagios specific

use lib "/usr/local/nagios/libexec";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas
my $storage_table= '1.3.6.1.2.1.25.2.3.1';
my $index_table = '1.3.6.1.2.1.25.2.3.1.1';
my $descr_table = '1.3.6.1.2.1.25.2.3.1.3';
my $size_table = '1.3.6.1.2.1.25.2.3.1.5.';
my $used_table = '1.3.6.1.2.1.25.2.3.1.6.';
my $alloc_units = '1.3.6.1.2.1.25.2.3.1.4.';

# Globals

my $Name='check_snmp_storage';
my $Version='1.1';

my $o_host = 	undef; 		# hostname 
my $o_community = undef; 	# community 
my $o_port = 	161; 		# port
my $o_descr = 	undef; 		# description filter 
my $o_warn = 	undef; 		# warning limit 
my $o_crit=	undef; 		# critical limit
my $o_help=	undef; 		# wan't some help ?
my $o_type=	undef;		# pl, pu, mbl, mbu 
my @o_typeok=   ("pu","pl","bu","bl"); # valid values for o_type
my $o_verb=	undef;		# verbose mode
my $o_version=   undef;          # print version
my $o_noreg=	undef;		# Do not use Regexp for name
my $o_sum=	undef;		# add all storage before testing
my $o_index=	undef;		# Parse index instead of description
my $o_negate=	undef;		# Negate the regexp if set
my $o_timeout=  5;            	# Default 5s Timeout
my $o_perf=	undef;		# Output performance data
# SNMP V3 specific
my $o_login=	undef;		# snmp v3 login
my $o_passwd=	undef;		# snmp v3 passwd

# functions

sub p_version { print "$Name version : $Version\n"; }

sub print_usage {
    print "Usage: $Name [-v] -H <host> -C <snmp_community> | (-l login -x passwd) [-p <port>] -m <name in desc_oid> -w <warn_level> -c <crit_level> [-t <timeout>] [-T pl|pu|bl|bu ] [-r] [-s] [-i] [-e]\n";
}

sub round ($$) {
    sprintf "%.$_[1]f", $_[0];
}

# Get the alarm signal (just in case snmp timout screws up)
$SIG{'ALRM'} = sub {
     print ("ERROR: General time-out (Alarm signal)\n");
     exit $ERRORS{"UNKNOWN"};
};

sub help {
   print "\nSNMP Disk Monitor for Nagios version ",$Version,"\n";
   print "(c)2004 to my cat Ratoune - Author : Patrick Proy\n\n";
   print_usage();
   print <<EOT;
By default, plugin will monitor %used on drives :
warn if %used > warn and critical if %used > crit
-v, --verbose
   print extra debugging information (and lists all storages)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1)
-l, --login=LOGIN
   Login for snmpv3 authentication (implies v3 protocol with MD5)
-x, --passwd=PASSWD
   Password for snmpv3 authentication
-p, --port=PORT
   SNMP port (Default 161)
-m, --name=NAME
   Name in description OID (can be mounpoints '/home' or 'Swap Space'...)
   This is treated as a regexp : -m /var will match /var , /var/log, /opt/var ...
   Test it before, because there are known bugs (ex : trailling /)
   No trailing slash for mountpoints !
-r, --noregexp
   Do not use regexp to match NAME in description OID
-s, --sum
   Add all storages that match NAME (used space and total space)
   THEN make the tests.
-i, --index
   Parse index table instead of description table to select storage
-e, --exclude
   Select all storages except the one(s) selected by -m
-T, --type=TYPE
   pl : calculate percent left
   pu : calculate percent used (Default)
   bl : calculate MegaBytes left
   bu : calculate MegaBytes used
-w, --warn=INTEGER
   percent / MB of disk used to generate WARNING state
   you can add the % sign 
-c, --critical=INTEGER
   percent / MB of disk used to generate CRITICAL state
   you can add the % sign 
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
Note : 
  with T=pu or T=bu : OK < warn < crit
  with T=pl ot T=bl : crit < warn < OK
  
  If multiple storage are selected, the worse condition will be returned
  i.e if one disk is critical, the return is critical
 
  example : 
  Browse storage list : <script> -C <community> -H <host> -m <anything> -w 1 -c 2 -v 
  the -m option allows regexp in perl format : 
  Test drive C,F,G,H,I on Windows 	: -m ^[CFGHI]:    
  Test all mounts containing /var      	: -m /var
  Test all mounts under /var      	: -m ^/var
  Test only /var                 	: -m /var -r
  Test all swap spaces			: -m ^Swap
  Test all but swap spaces		: -m ^Swap -e

EOT
}

sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
   	'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
        'l:s'   => \$o_login,           'login:s'       => \$o_login,
        'x:s'   => \$o_passwd,          'passwd:s'      => \$o_passwd,
        'c:s'   => \$o_crit,    	'critical:s'	=> \$o_crit,
        'w:s'   => \$o_warn,    	'warn:s'	=> \$o_warn,
 	't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
        'm:s'   => \$o_descr,		'name:s'	=> \$o_descr,
	'T:s'	=> \$o_type,		'type:s'	=> \$o_type,
        'r'     => \$o_noreg,           'noregexp'      => \$o_noreg,
        's'     => \$o_sum,           	'sum'      	=> \$o_sum,
        'i'     => \$o_index,          	'index'      	=> \$o_index,
        'e'     => \$o_negate,         	'exclude'    	=> \$o_negate,
        'V'     => \$o_version,         'version'       => \$o_version,
	'f'	=> \$o_perf,		'perfparse'	=> \$o_perf
    );
    if (defined($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version) ) { p_version(); exit $ERRORS{"UNKNOWN"}};
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
        { print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Check types
    if ( !defined($o_type) ) { $o_type="pu" ;}
    if ( ! grep( /^$o_type$/ ,@o_typeok) ) { print_usage(); exit $ERRORS{"UNKNOWN"}};   
    # Check compulsory attributes
    if ( ! defined($o_descr) ||  ! defined($o_host) || !defined($o_warn) || 
	!defined($o_crit)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
    # Check for positive numbers
    if (($o_warn < 0) || ($o_crit < 0)) { print " warn and critical > 0 \n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    # check if warn or crit  in % and MB is tested
    if (  ( ( $o_warn =~ /%/ ) || ($o_crit =~ /%/)) && ( ( $o_type eq 'bu' ) || ( $o_type eq 'bl' ) ) ) {
	print "warning or critical cannot be in % when MB are tested\n";
	print_usage(); exit $ERRORS{"UNKNOWN"};
    }
    # Get rid of % sign
    $o_warn =~ s/\%//; 
    $o_crit =~ s/\%//;
    # Check warning and critical values
    if ( ( $o_type eq 'pu' ) || ( $o_type eq 'bu' )) {
	if ($o_warn >= $o_crit) { print " warn < crit if type=",$o_type,"\n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    }
    if ( ( $o_type eq 'pl' ) || ( $o_type eq 'bl' )) {
	if ($o_warn <= $o_crit) { print " warn > crit if type=",$o_type,"\n";print_usage(); exit $ERRORS{"UNKNOWN"}};
    }
    if ( ($o_warn < 0 ) || ($o_crit < 0 )) { print "warn and crit must be > 0\n";print_usage(); exit $ERRORS{"UNKNOWN"}}; 
    if ( ( $o_type eq 'pl' ) || ( $o_type eq 'pu' )) {
        if ( ($o_warn > 100 ) || ($o_crit > 100 )) { print "percent must be < 100\n";print_usage(); exit $ERRORS{"UNKNOWN"}}; 
    } 
}

########## MAIN #######

check_options();

# Check gobal timeout
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT");
  alarm($TIMEOUT);
} else {
  verb("no timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}

# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  verb("SNMPv3 login");
  ($session, $error) = Net::SNMP->session(
      -hostname         => $o_host,
      -version          => '3',
      -username         => $o_login,
      -authpassword     => $o_passwd,
      -authprotocol     => 'md5',
      -privpassword     => $o_passwd,
      -timeout   	=> $o_timeout
   );
} else {
  # SNMPV1 login
  ($session, $error) = Net::SNMP->session(
     -hostname  => $o_host,
     -community => $o_community,
     -port      => $o_port,
     -timeout   => $o_timeout
  );
}

if (!defined($session)) {
   printf("ERROR: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

my $resultat=undef;
if (defined ($o_index)){
  $resultat = $session->get_table( 
	Baseoid => $index_table 
  );
} else {
  $resultat = $session->get_table( 
	Baseoid => $descr_table 
  );
}

if (!defined($resultat)) {
   printf("ERROR: Description table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}

my @tindex = undef;
my @oids = undef;
my @descr = undef;
my $num_int = 0;
my $count_oid = 0;
my $test = undef;
my $perf_out=	undef;
# Select storage by regexp of exact match
# and put the oid to query in an array

verb("Filter : $o_descr");

foreach my $key ( keys %$resultat) {
   verb("OID : $key, Desc : $$resultat{$key}");
   # test by regexp or exact match / include or exclude
   if (defined($o_negate)) {
     $test = defined($o_noreg)
                ? $$resultat{$key} ne $o_descr
                : $$resultat{$key} !~ /$o_descr/;
   } else {
     $test = defined($o_noreg)
                ? $$resultat{$key} eq $o_descr
                : $$resultat{$key} =~ /$o_descr/;
   }  
  if ($test) {
     # get the index number of the interface
     my @oid_list = split (/\./,$key);
     $tindex[$num_int] = pop (@oid_list);
     # get the full description
     $descr[$num_int]=$$resultat{$key};
     # put the oid in an array
     $oids[$count_oid++]=$size_table . $tindex[$num_int];
     $oids[$count_oid++]=$used_table . $tindex[$num_int];
     $oids[$count_oid++]=$alloc_units . $tindex[$num_int];

     verb("Name : $descr[$num_int], Index : $tindex[$num_int]");
     $num_int++;
  }
}
verb("storages selected : $num_int");
if ( $num_int == 0 ) { print "Unknown storage : $o_descr : ERROR\n" ; exit $ERRORS{"UNKNOWN"};}

my $result = $session->get_request(
   Varbindlist => \@oids
);

if (!defined($result)) { printf("ERROR: Size table :%s.\n", $session->error); $session->close;
   exit $ERRORS{"UNKNOWN"};
}

$session->close;

# Only a few ms left...
alarm(0);

# Sum everything if -s and more than one storage
if ( defined ($o_sum) && ($num_int > 1) ) {
  verb("Adding all entries into one");
  $$result{$size_table . $tindex[0]} *= $$result{$alloc_units . $tindex[0]};
  $$result{$used_table . $tindex[0]} *= $$result{$alloc_units . $tindex[0]};
  $$result{$alloc_units . $tindex[0]} = 1;
  for (my $i=1;$i<$num_int;$i++) {
    $$result{$size_table . $tindex[0]} += ($$result{$size_table . $tindex[$i]} 
					  * $$result{$alloc_units . $tindex[$i]}); 
    $$result{$used_table . $tindex[0]} += ($$result{$used_table . $tindex[$i]}
					  * $$result{$alloc_units . $tindex[$i]});
  }
  $num_int=1;
  $descr[0]="Sum of all $o_descr";
}

my $i=undef;
my $warn_state=0;
my $crit_state=0;
my ($p_warn,$p_crit);
for ($i=0;$i<$num_int;$i++) {
  verb("Size :  $$result{$size_table . $tindex[$i]}");
  verb("Used : $$result{$used_table . $tindex[$i]}");
  verb("Alloc : $$result{$alloc_units . $tindex[$i]}");
  my $to = $$result{$size_table . $tindex[$i]} * $$result{$alloc_units . $tindex[$i]} / 1024**2;
  my $pu=undef;
  if ( $$result{$used_table . $tindex[$i]} != 0 ) {
    $pu = $$result{$used_table . $tindex[$i]}*100 / $$result{$size_table . $tindex[$i]};
  }else {
    $pu=0;
  } 
  my $bu = $$result{$used_table . $tindex[$i]} *  $$result{$alloc_units . $tindex[$i]} / 1024**2;
  my $pl = 100 - $pu;
  my $bl = ($$result{$size_table . $tindex[$i]}- $$result{$used_table . $tindex[$i]}) * $$result{$alloc_units . $tindex[$i]} / 1024**2;
  # add a ',' if some data exists in $perf_out
  $perf_out .= " " if (defined ($perf_out)) ;
  ##### Ouputs 
  ##### TODO : subs "," with something
  if ($o_type eq "pu") {
    printf ("%s : %.0f %%used (%.0fMB/%.0fMB) ",$descr[$i],$pu,$bu,$to);
    $p_warn=$o_warn*$to/100;$p_crit=$o_crit*$to/100; 
    ( ($pu >= $o_crit) && ($crit_state=1) ) || ( ($pu >= $o_warn) && ($warn_state=1) );
  }
  
  if ($o_type eq 'bu') {
    printf ("%s : %.0f MB used/%.0f MB (%.0f%%) ",$descr[$i],$bu,$to,$pu);
    $p_warn=$o_warn;$p_crit=$o_crit;
    ( ($bu >= $o_crit) && ($crit_state=1) ) || ( ($bu >= $o_warn) && ($warn_state=1) );
  }
 
  if ($o_type eq 'bl') {
    printf ("%s : %.0f MB left/%.0f MB (%.0f%%) ",$descr[$i],$bl,$to,$pl);
    $p_warn=$to-$o_warn;$p_crit=$to-$o_crit;
    ( ($bl <= $o_crit) && ($crit_state=1) ) || ( ($bl <= $o_warn) && ($warn_state=1) );
  }
  
  if ($o_type eq 'pl') {
    printf ("%s : %.0f %%left (%.0fMB/%.0fMB) ",$descr[$i],$pl,$bl,$to);
    $p_warn=(100-$o_warn)*$to/100;$p_crit=(100-$o_crit)*$to/100;
    ( ($pl <= $o_crit) && ($crit_state=1) ) || ( ($pl <= $o_warn) && ($warn_state=1) );
  }
  $descr[$i] =~ s/'/_/g; 
  $perf_out .= "'".$descr[$i] . "'=" . round($bu,0) . "MB;" . round($p_warn,0) 
	       . ";" . round($p_crit,0) . ";0;" . round($to,0);
}

verb ("Perf data : $perf_out");

my $comp_oper=undef;
if ( ($o_type eq "pu") || ($o_type eq 'bu') ) { $comp_oper ="<";}
if ( ($o_type eq "pl") || ($o_type eq 'bl') ) { $comp_oper =">";}

if ( $crit_state == 1) {
    (defined($o_perf)) ? 
 	  print " (",$comp_oper," ",$o_crit,") : CRITICAL | ",$perf_out,"\n"  
    	: print " (",$comp_oper," ",$o_crit,") : CRITICAL\n";
     exit $ERRORS{"CRITICAL"};
    }
if ( $warn_state == 1) {
     (defined($o_perf)) ?
	  print " (",$comp_oper,"  ",$o_warn,") : WARNING | ",$perf_out,"\n" 
	: print " (",$comp_oper,"  ",$o_warn,") : WARNING\n";
     exit $ERRORS{"WARNING"};
   }
(defined($o_perf)) ?
    print " (",$comp_oper,"  ",$o_warn,") : OK | ",$perf_out,"\n"
  : print " (",$comp_oper,"  ",$o_warn,") : OK\n";
exit $ERRORS{"OK"};