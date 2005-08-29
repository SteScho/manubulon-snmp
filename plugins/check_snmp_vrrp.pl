#!/usr/bin/perl -w 
############################## check_snmp_vrrp ##############
# Version : 1.0
# Date : Sept 5 2004
# Author  : Patrick Proy (patrick at proy.org)
# Help : http://www.manubulon.com/nagios/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
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

my $base_vrrp = "1.3.6.1.2.1.68";   # oid for vrrp
my $vrrp_oper = "1.3.6.1.2.1.68.1.3.1.3";   # vrrp operational status
my $vrrp_admin ="1.3.6.1.2.1.68.1.3.1.4";   # vrrp admin status
my $vrrp_prio = "1.3.6.1.2.1.68.1.3.1.5";   # vrrp admin status

# Globals

my $Version='1.0';

my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
my $o_state=	undef;		# Check master or backup state for ok
my $o_timeout=  5;              # Default 5s Timeout

# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3

# functions

sub p_version { print "check_snmp_vrrp version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> | (-l login -x passwd) -s <master|backup> [-p <port>] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub help {
   print "\nSNMP VRRP Monitor for Nagios version ",$Version,"\n";
   print "(c)2004 to my cat Ratoune - Author : Patrick Proy\n\n";
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
-l, --login=LOGIN
   Login for snmpv3 authentication (implies v3 protocol with MD5)
-x, --passwd=PASSWD
   Password for snmpv3 authentication
-P, --port=PORT
   SNMP port (Default 161)
-s, --state=master|backup
   check vrrp interface to be master or backup 
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
        't:i'   => \$o_timeout,         'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,
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
}

########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT + 5");
  alarm($TIMEOUT+5);
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
  # SNMPV1 login
  ($session, $error) = Net::SNMP->session(
     -hostname  => $o_host,
     -community => $o_community,
     -port      => $o_port,
     -timeout   => $o_timeout
  );
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

########### get vrrp table ############

# Get vrrp table
my $resultat = $session->get_table(
        Baseoid => $base_vrrp
); 
if (!defined($resultat)) {
   printf("ERROR: Description table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}
$session->close;

my @vrid=undef;
my @vrid2=undef;
my $nvrid=0;
my @oid=undef;

foreach my $key ( keys %$resultat) {
   if ( $key =~ /$vrrp_oper/){
      @oid=split (/\./,$key);
      $vrid[$nvrid]=pop(@oid);
      $vrid2[$nvrid]=pop(@oid);
      verb("Added vrid $vrid2[$nvrid]:$vrid[$nvrid]");
      $nvrid++;
   }
}

if ( $nvrid == 0 ) 
{ printf("No vrid found : CRITICAL\n");exit $ERRORS{"CRITICAL"};}

my $ok=0;
my $key;
my $value;
print "Vrid : ";
for (my $i=0;$i<$nvrid;$i++) {
   printf("$vrid[$i](");
   $key=$vrrp_oper.".0.".$vrid2[$i].".".$vrid[$i];
   $value = ($$resultat{$key} == 3) ? "master" : ($$resultat{$key} == 2) ? "backup" : "initialise".$$resultat{$key};
   printf("%s/",$value);
   ($value eq $o_state) && $ok++;

   $key=$vrrp_admin.".0.".$vrid2[$i].".".$vrid[$i];
   $value = ($$resultat{$key} == 1) ? "up" : "down";
   printf("%s/",$value);
   ($value eq "up" ) && $ok++;
   
   $key=$vrrp_prio.".0.".$vrid2[$i].".".$vrid[$i];
   $value = $$resultat{$key};
   printf("%s), ",$value); 
}
verb("verif : $ok");

if ( $ok == (2*$nvrid) ) { 
   print " : All $o_state :OK\n" ;
   exit $ERRORS{"OK"} 
}
print " : Not all $o_state :NOK\n";
exit $ERRORS{"CRITICAL"};
