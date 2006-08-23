#!/usr/bin/perl -w 
############################## check_snmp_env #################
# Version : 1.0
# Date : Aug 23 2006
# Author  : Patrick Proy ( patrick at proy.org)
# Help : http://www.manubulon.com/nagios/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Changelog : 
# Contributors : Fredrik Vocks
#################################################################
#
# Help : ./check_snmp_env.pl -h
#

use strict;
use Net::SNMP;
use Getopt::Long;

# Nagios specific

use lib "/usr/local/nagios/libexec";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);


my @Nagios_state = ("UNKNOWN","OK","WARNING","CRITICAL"); # Nagios states coding

# SNMP Datas

# CISCO-ENVMON-MIB
my $ciscoEnvMonMIB	=	"1.3.6.1.4.1.9.9.13"; # Cisco env base table
my %CiscoEnvMonState = (1,"normal",2,"warning",3,"critical",4,"shutdown",5,"notPresent",
						6,"notFunctioning"); # Cisco states
my %CiscoEnvMonNagios = (1,1 ,2,2 ,3,3 ,4,3 ,5,0, 6,3); # Nagios states returned for CIsco states (coded see @Nagios_state).
my $ciscoVoltageTable = $ciscoEnvMonMIB.".1.2.1"; # Cisco voltage table
my $ciscoVoltageTableIndex = $ciscoVoltageTable.".1"; #Index table
my $ciscoVoltageTableDesc = $ciscoVoltageTable.".2"; #Description
my $ciscoVoltageTableValue = $ciscoVoltageTable.".3"; #Value
my $ciscoVoltageTableState = $ciscoVoltageTable.".7"; #Status
# CiscoEnvMonVoltageStatusEntry ::=
                # 1 ciscoEnvMonVoltageStatusIndex   Integer32 (0..2147483647),
                # 2 ciscoEnvMonVoltageStatusDescr   DisplayString,
                # 3 ciscoEnvMonVoltageStatusValue   CiscoSignedGauge,
                # 4 ciscoEnvMonVoltageThresholdLow  Integer32,
                # 5 ciscoEnvMonVoltageThresholdHigh Integer32,
                # 6 ciscoEnvMonVoltageLastShutdown  Integer32,
                # 7 ciscoEnvMonVoltageState         CiscoEnvMonState
my $ciscoTempTable = $ciscoEnvMonMIB.".1.3.1"; # Cisco temprature table
my $ciscoTempTableIndex = $ciscoTempTable.".1"; #Index table
my $ciscoTempTableDesc = $ciscoTempTable.".2"; #Description
my $ciscoTempTableValue = $ciscoTempTable.".3"; #Value
my $ciscoTempTableState = $ciscoTempTable.".6"; #Status
# CiscoEnvMonTemperatureStatusEntry ::=
                # ciscoEnvMonTemperatureStatusIndex       Integer32 (0..2147483647),
                # ciscoEnvMonTemperatureStatusDescr       DisplayString,
                # ciscoEnvMonTemperatureStatusValue       Gauge32,
                # ciscoEnvMonTemperatureThreshold         Integer32,
                # ciscoEnvMonTemperatureLastShutdown      Integer32,
                # ciscoEnvMonTemperatureState             CiscoEnvMonState
my $ciscoFanTable = $ciscoEnvMonMIB.".1.4.1"; # Cisco fan table
my $ciscoFanTableIndex = $ciscoFanTable.".1"; #Index table
my $ciscoFanTableDesc = $ciscoFanTable.".2"; #Description
my $ciscoFanTableState = $ciscoFanTable.".3"; #Status
# CiscoEnvMonFanStatusEntry ::=
                # ciscoEnvMonFanStatusIndex       Integer32 (0..2147483647),
                # ciscoEnvMonFanStatusDescr       DisplayString,
                # ciscoEnvMonFanState             CiscoEnvMonState
my $ciscoPSTable = $ciscoEnvMonMIB.".1.5.1"; # Cisco power supply table
my $ciscoPSTableIndex = $ciscoPSTable.".1"; #Index table
my $ciscoPSTableDesc = $ciscoPSTable.".2"; #Description
my $ciscoPSTableState = $ciscoPSTable.".3"; #Status
# CiscoEnvMonSupplyStatusEntry ::=
                # ciscoEnvMonSupplyStatusIndex    Integer32 (0..2147483647),
                # ciscoEnvMonSupplyStatusDescr    DisplayString,
                # ciscoEnvMonSupplyState          CiscoEnvMonState,
                # ciscoEnvMonSupplySource         INTEGER

# Nokia env mib 
my $nokia_temp_tbl="1.3.6.1.4.1.94.1.21.1.1.5";
my $nokia_temp="1.3.6.1.4.1.94.1.21.1.1.5.0";
my $nokia_fan_table="1.3.6.1.4.1.94.1.21.1.2";
my $nokia_fan_status="1.3.6.1.4.1.94.1.21.1.2.1.1.2";
my $nokia_ps_table="1.3.6.1.4.1.94.1.21.1.3";
my $nokia_ps_temp="1.3.6.1.4.1.94.1.21.1.3.1.1.2";
my $nokia_ps_status="1.3.6.1.4.1.94.1.21.1.3.1.1.3";

				
my @valid_types	=("cisco","nokia","lp");			
# Globals

my $Version='0.5';

my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
# check type  : cisco 
my $o_check_type= "cisco";	

my $o_timeout=  undef; 		# Timeout (Default 5)
my $o_perf=     undef;          # Output performance data
my $o_version2= undef;          # use snmp v2c
# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3
my $v3protocols=undef;	# V3 protocol list.
my $o_authproto='md5';		# Auth protocol
my $o_privproto='des';		# Priv protocol
my $o_privpass= undef;		# priv password

# functions

sub p_version { print "check_snmp_env version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -T (cisco|nokia|lp) [-f] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub help {
   print "\nSNMP environemental Monitor for Nagios version ",$Version,"\n";
   print "(c)2004-2006 to my cat Ratoune - Author : Patrick Proy\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information 
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des) 
-P, --port=PORT
   SNMP port (Default 161)
-T, --type=cisco
	Environemental check : 
		cisco : voltage,temp,fan,power supply status
		        will try to check everything present
		nokia : fan and power supply
		lp : 
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
   	'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
	'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
	'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
	'X:s'	=> \$o_privpass,		'privpass:s'	=> \$o_privpass,
	'L:s'	=> \$v3protocols,		'protocols:s'	=> \$v3protocols,   
        't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,

	'2'     => \$o_version2,        'v2c'           => \$o_version2,
        'f'     => \$o_perf,            'perfparse'     => \$o_perf,
	'T:s'	=> \$o_check_type,	'type:s'	=> \$o_check_type
	);
    # check the -T option
    my $T_option_valid=0; 
    foreach (@valid_types) { if ($_ eq $o_check_type) {$T_option_valid=1} };
    if ( $T_option_valid == 0 ) 
       {print "Invalid check type (-T)!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Basic checks
	if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) 
	  { print "Timeout must be >1 and <60 !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (!defined($o_timeout)) {$o_timeout=5;}
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_host) ) # check host and filter 
	{ print_usage(); exit $ERRORS{"UNKNOWN"}}
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
	  { print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if ((defined($o_login) || defined($o_passwd)) && (defined($o_community) || defined($o_version2)) )
	  { print "Can't mix snmp v1,2c,3 protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (defined ($v3protocols)) {
	  if (!defined($o_login)) { print "Put snmp V3 login info with protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	  my @v3proto=split(/,/,$v3protocols);
	  if ((defined ($v3proto[0])) && ($v3proto[0] ne "")) {$o_authproto=$v3proto[0];	}	# Auth protocol
	  if (defined ($v3proto[1])) {$o_privproto=$v3proto[1];	}	# Priv  protocol
	  if ((defined ($v3proto[1])) && (!defined($o_privpass))) {
	    print "Put snmp V3 priv login info with priv protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	}
}

########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT + 5");
  alarm($TIMEOUT+5);
} else {
  verb("no global timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}

# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  verb("SNMPv3 login");
    if (!defined ($o_privpass)) {
  verb("SNMPv3 AuthNoPriv login : $o_login, $o_authproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -timeout          => $o_timeout
    );  
  } else {
    verb("SNMPv3 AuthPriv login : $o_login, $o_authproto, $o_privproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -privpassword	=> $o_privpass,
	  -privprotocol => $o_privproto,
      -timeout          => $o_timeout
    );
  }
} else {
	if (defined ($o_version2)) {
		# SNMPv2 Login
		verb("SNMP v2c login");
		  ($session, $error) = Net::SNMP->session(
		 -hostname  => $o_host,
		 -version   => 2,
		 -community => $o_community,
		 -port      => $o_port,
		 -timeout   => $o_timeout
		);
  	} else {
	  # SNMPV1 login
	  verb("SNMP v1 login");
	  ($session, $error) = Net::SNMP->session(
		-hostname  => $o_host,
		-community => $o_community,
		-port      => $o_port,
		-timeout   => $o_timeout
	  );
	}
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

my $exit_val=undef;
########### Cisco env checks ##############

if ($o_check_type eq "cisco") {

verb("Checking cisco env");

# Get load table
my $resultat = (Net::SNMP->VERSION < 4) ? 
		  $session->get_table($ciscoEnvMonMIB)
		: $session->get_table(Baseoid => $ciscoEnvMonMIB); 
		
if (!defined($resultat)) {
   printf("ERROR: Description table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}
$session->close;

# Get env data index
my (@voltindex,@tempindex,@fanindex,@psindex)=(undef,undef,undef,undef);
my ($voltexist,$tempexist,$fanexist,$psexist)=(0,0,0,0);
my @oid=undef;
foreach my $key ( keys %$resultat) {
   verb("OID : $key, Desc : $$resultat{$key}");
   if ( $key =~ /$ciscoVoltageTableDesc/ ) { 
      @oid=split (/\./,$key);
      $voltindex[$voltexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoTempTableDesc/ ) { 
      @oid=split (/\./,$key);
      $tempindex[$tempexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoFanTableDesc/ ) { 
      @oid=split (/\./,$key);
      $fanindex[$fanexist++] = pop(@oid);
   }
   if ( $key =~ /$ciscoPSTableDesc/ ) { 
      @oid=split (/\./,$key);
      $psindex[$psexist++] = pop(@oid);
   }
}

if ( ($voltexist ==0) && ($tempexist ==0) && ($fanexist ==0) && ($psexist ==0) ) {
  print "No Environemental data found : UNKNOWN";
  exit $ERRORS{"UNKNOWN"};
}

# Get the data
my ($i,$cur_status)=(undef,undef); 
                
my $fan_global=0;
my %fan_status;
if ($fanexist !=0) {
  for ($i=0;$i < $fanexist; $i++) {
    $cur_status=$$resultat{$ciscoFanTableState . "." . $fanindex[$i]};
    verb ($$resultat{$ciscoFanTableDesc .".".$fanindex[$i]});
    verb ($cur_status);
    if (!defined ($cur_status)) { ### Error TODO
      $fan_global=1;
    }
    if ($CiscoEnvMonNagios{$cur_status} ne "OK") {
      $fan_global= 1;
      $fan_status{$$resultat{$ciscoFanTableDesc .".".$fanindex[$i]}}=$cur_status;
    }
  }
}

my $ps_global=0;
my %ps_status;
if ($psexist !=0) {
  for ($i=0;$i < $psexist; $i++) {
    $cur_status=$$resultat{$ciscoPSTableState . "." . $psindex[$i]};
    if (!defined ($cur_status)) { ### Error TODO
      $fan_global=1;
    }
    if ($CiscoEnvMonNagios{$cur_status} ne "OK") {
      $ps_global= 1;
      $ps_status{$$resultat{$ciscoPSTableDesc .".".$psindex[$i]}}=$cur_status;
    }
  }
}

my $global_state=0; 
my $output="";
if ($fanexist !=0) {
	if ($fan_global ==0) {
	   $output .= $fanexist." Fan OK";
	} else {
	  foreach (keys %fan_status) {
	    $output .= "Fan " . $_ . ":" . $CiscoEnvMonState {$fan_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$fan_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$fan_status{$_}} ;
		}
	  }
	}
}

$output .= "," if ($output ne "");
if ($psexist !=0) {
	if ($ps_global ==0) {
	   $output .= $psexist." ps OK";
	} else {
	  foreach (keys %ps_status) {
	    $output .= "ps " . $_ . ":" . $CiscoEnvMonState {$ps_status{$_}} ." ";
		if ($global_state < $CiscoEnvMonNagios{$ps_status{$_}} ) {
		  $global_state = $CiscoEnvMonNagios{$ps_status{$_}} ;
		}
	  }
	}
}

print $output," : ",$Nagios_state[$global_state],"\n";
$exit_val=$ERRORS{$Nagios_state[$global_state]};

exit $exit_val;

}

############# Nokia checks
if ($o_check_type eq "nokia") {

verb("Checking nokia env");

my $resultat;
# status : 0=ok, 1=nok, 2=temp prb
my ($fan_status,$ps_status,$temp_status)=(0,0,0);
my ($fan_exist,$ps_exist,$temp_exist)=(0,0,0);
my ($num_fan,$num_ps)=(0,0);
my ($num_fan_nok,$num_ps_nok)=(0,0);
my $global_status=0;
my $output="";
# get temp
$resultat = (Net::SNMP->VERSION < 4) ? 
		  $session->get_table($nokia_temp_tbl)
		: $session->get_table(Baseoid => $nokia_temp_tbl); 
if (defined($resultat)) {
  verb ("temp found");
  $temp_exist=1;
  if ($$resultat{$nokia_temp} != 1) { 
    $temp_status=2;$global_status=1;
	$output="Temp CRITICAL ";
  } else {
    $output="Temp OK ";
  }
}
		
# Get fan table
$resultat = (Net::SNMP->VERSION < 4) ? 
		  $session->get_table($nokia_fan_table)
		: $session->get_table(Baseoid => $nokia_fan_table); 
		
if (defined($resultat)) {
  $fan_exist=1;
  foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    if ( $key =~ /$nokia_fan_status/ ) { 
      if ($$resultat{$key} != 1) { $fan_status=1; $num_fan_nok++}      
	  $num_fan++;
    }
  }
  if ($fan_status==0) {
    $output.= ", ".$num_fan." fan OK";
  } else {
    $output.= ", ".$num_fan_nok."/".$num_fan." fan CRITICAL";
	$global_status=2;
  }
}

# Get ps table
$resultat = (Net::SNMP->VERSION < 4) ? 
		  $session->get_table($nokia_ps_table)
		: $session->get_table(Baseoid => $nokia_ps_table); 
		
if (defined($resultat)) {
  $ps_exist=1;
  foreach my $key ( keys %$resultat) {
    verb("OID : $key, Desc : $$resultat{$key}");
    if ( $key =~ /$nokia_ps_status/ ) { 
      if ($$resultat{$key} != 1) { $ps_status=1; $num_ps_nok++;}      
	  $num_ps++;
    }
    if ( $key =~ /$nokia_ps_temp/ ) { 
      if ($$resultat{$key} != 1) { if ($ps_status==0) {$ps_status=2;$num_ps_nok++;} }      
    }	
  }
  if ($ps_status==0) {
    $output.= ", ".$num_ps." ps OK";
  } elsif ($ps_status==2) {
    $output.= ", ".$num_ps_nok."/".$num_ps." ps WARNING (temp)";
	if ($global_status != 2) {$global_status=1;}
  } else {
    $output.= ", ".$num_ps_nok."/".$num_ps." ps CRITICAL";
	$global_status=2;
  }
}

$session->close;

verb ("status : $global_status");

if ( ($fan_exist+$ps_exist+$temp_exist) == 0) {
  print "No environemental informations found : UNKNOWN\n";
  exit $ERRORS{"UNKNOWN"};
}

if ($global_status==0) {
  print $output." : all OK\n";
  exit $ERRORS{"OK"};
}

if ($global_status==1) {
  print $output." : WARNING\n";
  exit $ERRORS{"WARNING"};
}

if ($global_status==2) {
  print $output." : CRITICAL\n";
  exit $ERRORS{"CRITICAL"};
}
}

