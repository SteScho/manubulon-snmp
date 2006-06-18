#!/usr/bin/perl -w 
############################## check_snmp_vrrp ##############
# Version : 1.2
# Date : Dec 19 2004
# Author  : Patrick Proy (patrick at proy.org)
# Help : http://www.manubulon.com/nagios/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Contrib : C. Maser (Alteon + Netscreen) 
#################################################################
#
# Help : ./check_snmp_vrrp.pl -h
#

use strict;
use Net::SNMP;
use Getopt::Long;

# Nagios specific

use lib "/usr/local/nagios/libexec";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas

######### Nokia (standard ???)
my $all_vrrp  = "1.3.6.1.2.1.68";
my $nokia_base_vrrp = "1.3.6.1.2.1.68.1.3.1";   # oid for vrrp
my $nokia_vrrp_oper = "1.3.6.1.2.1.68.1.3.1.3";   # vrrp operational status
my $nokia_vrrp_admin ="1.3.6.1.2.1.68.1.3.1.4";   # vrrp admin status
my $nokia_vrrp_prio = "1.3.6.1.2.1.68.1.3.1.5";   # vrrp vrid priority

######### LinkProof
my $lp_base_vrrp = "1.3.6.1.2.1.68.1.3.1";   # oid for vrrp
my $lp_vrrp_oper = "1.3.6.1.2.1.68.1.3.1.4";   # vrrp operational status
my $lp_vrrp_admin ="1.3.6.1.2.1.68.1.3.1.5";   # vrrp admin status
my $lp_vrrp_prio = "1.3.6.1.2.1.68.1.3.1.6";   # vrrp vrid priority

######### Alteon (AD4 Loadbalancers)
my $alteon_base_vrrp = "1.3.6.1.4.1.1872.2.1.9.4"; 
my $alteon_vrrp_oper = "1.3.6.1.4.1.1872.2.1.9.4.1.1.2";
my $alteon_vrrp_admin = "";
my $alteon_vrrp_prio = "1.3.6.1.4.1.1872.2.1.9.4.1.1.3";

######### Netscreen (ScreenOS 5.1)
### .0 is always the queried device itself 
### so in a cluster every device has its own numbering of members
my $ns_base_vrrp = "1.3.6.1.4.1.3224.6.2";
my $ns_vrrp_oper = "1.3.6.1.4.1.3224.6.2.2.1.3";
my $ns_vrrp_admin = "";
my $ns_vrrp_prio = "1.3.6.1.4.1.3224.6.2.2.1.4";

######### Make an array
my %base_vrrp = ("nokia",$nokia_base_vrrp,
		"lp",$lp_base_vrrp,
		"alteon",$alteon_base_vrrp,
		"nsc",$ns_base_vrrp
		);
my %vrrp_oper = ("nokia",$nokia_vrrp_oper,
		"lp",$lp_vrrp_oper,
		"alteon",$alteon_vrrp_oper,
		"nsc",$ns_vrrp_oper
		);
my %vrrp_admin =("nokia",$nokia_vrrp_admin,
		"lp",$lp_vrrp_admin,
		"alteon",$alteon_vrrp_admin,
		"nsc",$ns_vrrp_admin
		);
my %vrrp_prio = ("nokia",$nokia_vrrp_prio,
		"lp",$lp_vrrp_prio,
		"alteon",$alteon_vrrp_prio,
		"nsc",$ns_vrrp_prio);
my %state_master=("nokia",3,"alteon",2,"lp",3,"nsc",2);
my %state_backup=("nokia",2,"alteon",3,"lp",2,"nsc",3);

# Globals

my $Version='1.2';

my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_version2	= undef;	#use snmp v2c
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
my $o_state=	undef;		# Check master or backup state for ok
my $o_type=	'nokia';	# Check type : nokia|alteon|lp|nsc
my $o_long=		undef;		# Make output long
my $o_timeout=  5;              # Default 5s Timeout

# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3

# functions

sub p_version { print "check_snmp_vrrp version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd) -s <master|backup> [-T <nokia|alteon|lp|nsc>] [-p <port>] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub help {
   print "\nSNMP VRRP Monitor for Nagios version ",$Version,"\n";
   print "(c)2004-2005 to my cat Ratoune - Author : Patrick Proy\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information (including interface list on the system)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN
   Login for snmpv3 authentication (implies v3 protocol with MD5)
-x, --passwd=PASSWD
   Password for snmpv3 authentication
-P, --port=PORT
   SNMP port (Default 161)
-T, --type=<nokia|alteon|lp|nsc>
   Type of vrrp router to check
   nokia (default) : should be working for most vrrp routers
   alteon : for Alteon AD4 Loadbalancers
   lp : Radware Linkproof
   nsc : Nescreen (ScreenOS 5.x NSRP)
-s, --state=master|backup
   check vrrp interface to be master or backup
-g, --long
   Make output long even is all is OK   
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

# Get the alarm signal (just in case snmp timout screws up)
$SIG{'ALRM'} = sub {
     print ("ERROR: Alarm signal (Nagios time-out)\n");
     exit $ERRORS{"UNKNOWN"};
};

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
        't:i'   => \$o_timeout,         'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,
	'g'	=> \$o_long,		'long'		=> \$o_long,
	'T:s'	=> \$o_type,		'type:s'		=> \$o_type,
	'2'	=> \$o_version2,	'v2c'		=> \$o_version2,
	's:s'	=> \$o_state,		'state:s'	=> \$o_state
    );
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_host) ) # check host and filter 
	{ print_usage(); exit $ERRORS{"UNKNOWN"}}
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
	{ print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    # Check state
    if ( !defined($o_state) || ($o_state ne "master") && ($o_state ne "backup") ) 
 	{ print "state must be master or backup\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
     # Check type
     if ( !defined($o_type) || (($o_type ne "nokia") && ($o_type ne "alteon") && ($o_type ne "lp") && ($o_type ne"nsc")) ) 
  	{ print "type must be alteon,nokia,lp or nsc\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}

}

########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
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
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> 'md5',
      -privpassword	=> $o_passwd,
      -timeout          => $o_timeout
   );
} else {
  if (defined ($o_version2)) {
    # SNMPv2 Login
	($session, $error) = Net::SNMP->session(
       -hostname  => $o_host,
	   -version   => 2,
       -community => $o_community,
       -port      => $o_port,
       -timeout   => $o_timeout
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
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

########### get vrrp table ############

# Get vrrp table
my $resultat;
if (Net::SNMP->VERSION < 4) {
  $resultat = $session->get_table( $base_vrrp{$o_type} );
} else {
  $resultat = $session->get_table( Baseoid => $base_vrrp{$o_type} );
}
if (!defined($resultat)) {
   printf("ERROR: Description table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}
$session->close;

my @vrid=undef;
my $nvrid=0;
my $oid0=undef;
my @oid=undef;

if ( $o_type eq 'nsc' ) {
  $nvrid = 1;
  $vrid[0] = '0';
} else {
  foreach my $key ( keys %$resultat) {
     if ( $key =~ /$vrrp_oper{$o_type}/){
        # Get rid of the vrrp oper part
        $key =~ s/$vrrp_oper{$o_type}\.//;
        @oid=split (/\./,$key);
        $vrid[$nvrid]=pop(@oid);
        $oid0=pop(@oid);
        while ( defined ($oid0)) { 
           $vrid[$nvrid] = $oid0 . "." . $vrid[$nvrid];
           $oid0=pop(@oid);
        } 
        verb("Added vrid $vrid[$nvrid]");
        $nvrid++;
     }
  }
}

if ( $nvrid == 0 ) 
{ printf("No vrid found : CRITICAL\n");exit $ERRORS{"CRITICAL"};}

my $ok=0;
my $key;
my $value;
my $output=undef;
my $vrid_out;
for (my $i=0;$i<$nvrid;$i++) {
   $output .= ", " if  (defined($output)); 
   # Get last part of oid to output the vrid
   $vrid_out = $vrid[$i];
   $vrid_out =~ s/.*\.//;
   $output .= "$vrid_out(";
   # Get the state
   $key=$vrrp_oper{$o_type}.".".$vrid[$i];
   
   $value = ($$resultat{$key} == $state_master{$o_type}) ? "master" : 
	    ($$resultat{$key} == $state_backup{$o_type}) ? "backup" : "initialise : ".$$resultat{$key};
   $output.=$value . "/";
   ($value eq $o_state) && $ok++;
   # Get the administrative status
   if (($o_type eq 'alteon' )|| ($o_type eq 'nsc') ) {
     $ok++
   } else {
     $key= $vrrp_admin{$o_type} . "." . $vrid[$i];
     $value = ($$resultat{$key} == 1) ? "up" : "down";
     $output.= $value . "/";
     ($value eq "up" ) && $ok++;
   }
   # Get the priority
   $key=$vrrp_prio{$o_type}.".".$vrid[$i];
   $value = $$resultat{$key};
   $output.=$value . ")"; 
}

verb("verif : $ok");

if ( $ok == (2*$nvrid) ) { 
   if (defined($o_long)) {
      printf("Vrid : %s : %s %s : OK\n",$output,$nvrid,$o_state) ;
   } else {
     printf("%s vrid %s :OK\n",$nvrid,$o_state) ;
   }
   exit $ERRORS{"OK"} 
}
printf("Vrid : %s : not all %s : NOK\n",$output,$o_state);
exit $ERRORS{"CRITICAL"};
