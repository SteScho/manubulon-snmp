#!/usr/bin/perl -w
############################## check_snmp_int ##############
# Version : 1.4
# Date : Jun 30 2006
# Author  : Patrick Proy ( patrick at proy.org )
# Help : http://www.manubulon.com/nagios/
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# TODO : 
# Check isdn "dormant" state
# Maybe put base directory for performance as an option
#################################################################
#
# Help : ./check_snmp_int.pl -h
#
use strict;
use Net::SNMP;
use Getopt::Long;

############### BASE DIRECTORY FOR TEMP FILE ########
my $o_base_dir="/tmp/tmp_Nagios_int.";
my $file_history=200;   # number of data to keep in files.

# Nagios specific

use lib "/usr/local/nagios/libexec";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 5;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas

my $inter_table= '.1.3.6.1.2.1.2.2.1';
my $index_table = '1.3.6.1.2.1.2.2.1.1';
my $descr_table = '1.3.6.1.2.1.2.2.1.2';
my $oper_table = '1.3.6.1.2.1.2.2.1.8.';
my $admin_table = '1.3.6.1.2.1.2.2.1.7.';
my $in_octet_table = '1.3.6.1.2.1.2.2.1.10.';
my $in_error_table = '1.3.6.1.2.1.2.2.1.14.';
my $in_discard_table = '1.3.6.1.2.1.2.2.1.13.';
my $out_octet_table = '1.3.6.1.2.1.2.2.1.16.';
my $out_error_table = '1.3.6.1.2.1.2.2.1.20.';
my $out_discard_table = '1.3.6.1.2.1.2.2.1.19.';

my %status=(1=>'UP',2=>'DOWN',3=>'TESTING',4=>'UNKNOWN',5=>'DORMANT',6=>'NotPresent',7=>'lowerLayerDown');

# Globals

my $Version='1.4';

my $o_host = 		undef; 	# hostname
my $o_community = 	undef; 	# community
my $o_version2	= undef;	#use snmp v2c
my $o_port = 		161; 	# port
my $o_descr = 		undef; 	# description filter
my $o_help=		undef; 	# wan't some help ?
my $o_admin=		undef;	# admin status instead of oper
my $o_inverse=  	undef;	# Critical when up
my $o_verb=		undef;	# verbose mode
my $o_version=		undef;	# print version
my $o_noreg=		undef;	# Do not use Regexp for name
my $o_perf=     	undef;  # Output performance data
my $o_perfe=		undef;	# Output discard/error also in perf data
my $o_checkperf=	undef;	# checks in/out/err/disc values
my $o_delta=		300;	# delta of time of perfcheck (default 5min)
my $o_ext_checkperf=	undef;  # extended perf checks (+error+discard) 
my $o_warn_opt=		undef;  # warning options
my $o_crit_opt=		undef;  # critical options
my $o_kbits=	undef;	# Warn and critical in Kbits instead of KBytes
my @o_warn=		undef;  # warning levels of perfcheck
my @o_crit=		undef;  # critical levels of perfcheck
my $o_short=		undef;	# set maximum of n chars to be displayed

my $o_timeout=  undef; 		# Timeout (Default 5)
# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3
my $v3protocols=undef;	# V3 protocol list.
my $o_authproto='md5';		# Auth protocol
my $o_privproto='des';		# Priv protocol
my $o_privpass= undef;		# priv password

# functions

sub read_file { 
	# Input : File, items_number
	# Returns : array of value : [line][item] 
  my ($traffic_file,$items_number)=@_;
  my ($ligne,$n_rows)=(undef,0);  
  my (@last_values,@file_values,$i);
  open(FILE,"<".$traffic_file) || return (1,0,0); 
  
  while($ligne = <FILE>)
  {
    chomp($ligne);
    @file_values = split(":",$ligne);
    #verb("@file_values");
    if ($#file_values >= ($items_number-1)) { 
	# check if there is enough data, else ignore line
      for ( $i=0 ; $i< $items_number ; $i++ ) {$last_values[$n_rows][$i]=$file_values[$i];}
      $n_rows++;
    } 
  }
  close FILE;
  if ($n_rows != 0) { 
    return (0,$n_rows,@last_values);
  } else {
    return (1,0,0);
  }
}

sub write_file { 
  	# Input : file , rows, items, array of value : [line][item]
        # Returns : 0 / OK, 1 / error
  my ($file_out,$rows,$item,@file_values)=@_;
  my $start_line= ($rows > $file_history) ? $rows -  $file_history : 0;
  if ( open(FILE2,">".$file_out) ) {
    for (my $i=$start_line;$i<$rows;$i++) {
      for (my $j=0;$j<$item;$j++) {
	print FILE2 $file_values[$i][$j];
	if ($j != ($item -1)) { print FILE2 ":" };
      }
      print FILE2 "\n";
    }
    close FILE2;
    return 0;
  } else {
    return 1;
  }
}

sub p_version { print "check_snmp_int version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>)  [-p <port>] -n <name in desc_oid> [-i] [-a] [-r] [-f[e]] [-k[qB] -w<warn levels> -c<crit levels> -d<delta>] [-t <timeout>] [-s] [-V]\n";
}

sub help {
   print "\nSNMP Network Interface Monitor for Nagios version ",$Version,"\n";
   print "(c)2004-2006 to my cat Ratoune - Author : Patrick Proy\n\n";
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
-l, --login=LOGIN ; -x, --passwd=PASSWD, -2, --v2c
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
   -2 : use snmp v2c
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des) 
-P, --port=PORT
   SNMP port (Default 161)
-n, --name=NAME
   Name in description OID (eth0, ppp0 ...).
   This is treated as a regexp : -n eth will match eth0,eth1,...
   Test it before, because there are known bugs (ex : trailling /)
-i, --inverse
   Make critical when up
-a, --admin
   Use administrative status instead of operational
-f, --perfparse
   Perfparse compatible output (no output when interface is down).
-e, --error
   Add error & discard to Perfparse output
-r, --noregexp
   Do not use regexp to match NAME in description OID
-k, --perfcheck ; -q, --extperfcheck
   -k check the input/ouput bandwidth of the interface
   -q also check the error and discard input/output
-d, --delta=seconds
   make an average of <delta> seconds (default 300=5min)
-B, --kbits
   Make the warning and critical levels in KBits/s instead of KBytes/s
-w, --warning=input,output[,error in,error out,discard in,discard out]
   warning level for input / output bandwidth in KBytes/s (0 for no warning)
   warning for error & discard input / output in error/min (need -q)
-c, --critical=input,output[,error in,error out,discard in,discard out]
   critical level for input / output bandwidth in KBytes/s (0 for no critical)
   critical for error & discard input / output in error/min (need -q)
-s, --short=int
   Make the output shorter : only the first <n> chars of the interface(s)
   If the number is negative, then get the <n> LAST caracters.
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)   
-V, --version
   prints version number
Note : when multiple interface are selected with regexp, 
       all be must be up (or down with -i) to get an OK result.
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
	'n:s'   => \$o_descr,           'name:s'        => \$o_descr,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
		'2'	=> \$o_version2,	'v2c'		=> \$o_version2,		
	'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
	'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
	'X:s'	=> \$o_privpass,		'privpass:s'	=> \$o_privpass,
	'L:s'	=> \$v3protocols,		'protocols:s'	=> \$v3protocols,   
        't:i'   => \$o_timeout,    	'timeout:i'	=> \$o_timeout,
	'i'	=> \$o_inverse,		'inverse'	=> \$o_inverse,
	'a'	=> \$o_admin,		'admin'		=> \$o_admin,
	'r'	=> \$o_noreg,		'noregexp'	=> \$o_noreg,
	'V'	=> \$o_version,		'version'	=> \$o_version,
        'f'     => \$o_perf,            'perfparse'     => \$o_perf,
        'e'     => \$o_perfe,           'error'     	=> \$o_perfe,
        'k'     => \$o_checkperf,       'perfcheck'   	=> \$o_checkperf,
        'q'     => \$o_ext_checkperf,   'extperfcheck'  => \$o_ext_checkperf,
        'w:s'   => \$o_warn_opt,       	'warning:s'   	=> \$o_warn_opt,
        'c:s'   => \$o_crit_opt,      	'critical:s'   	=> \$o_crit_opt,
        'B'     => \$o_kbits,   'kbits'  => \$o_kbits,		
        's:i'   => \$o_short,      	'short:i'   	=> \$o_short,
        'd:i'   => \$o_delta,           'delta:i'     	=> \$o_delta
    );
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_descr) ||  ! defined($o_host) ) # check host and filter 
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
	if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) 
	  { print "Timeout must be >1 and <60 !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (!defined($o_timeout)) {$o_timeout=5;}
    # check if -e without -f
    if ( defined($o_perfe) && !defined($o_perf))
        { print "Cannot output error without -f option!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
    if (defined ($o_short)) {
      #TODO maybe some basic tests ? caracters return empty string
    }
    if (defined ($o_checkperf)) {
      @o_warn=split(/,/,$o_warn_opt);
      if (defined($o_ext_checkperf) && ($#o_warn != 5)) {
        print "6 warning levels for extended checks \n"; print_usage(); exit $ERRORS{"UNKNOWN"}
      } 
      if (!defined($o_ext_checkperf) &&($#o_warn !=1 )){
	print "2 warning levels for bandwidth checks \n"; print_usage(); exit $ERRORS{"UNKNOWN"}
      }
      @o_crit=split(/,/,$o_crit_opt);
      #verb(" $o_crit_opt :: $#o_crit : @o_crit"); 
      if (defined($o_ext_checkperf) && ($#o_crit != 5)) {
        print "6 critical levels for extended checks \n"; print_usage(); exit $ERRORS{"UNKNOWN"}
      } 
      if (!defined($o_ext_checkperf) && ($#o_crit !=1 )) {
	print "2 critical levels for bandwidth checks \n"; print_usage(); exit $ERRORS{"UNKNOWN"}
      }
      for (my $i=0;$i<=$#o_warn;$i++) { 
        if (($o_crit[$i]!=0)&&($o_warn[$i] > $o_crit[$i])) {
          print "Warning must be < Critical level \n"; print_usage(); exit $ERRORS{"UNKNOWN"}
        }
      }
    }
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
    # SNMPv2c Login
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

# Get desctiption table
my $resultat = $session->get_table( 
	Baseoid => $descr_table 
);

if (!defined($resultat)) {
   printf("ERROR: Description table : %s.\n", $session->error);
   $session->close;
   exit $ERRORS{"UNKNOWN"};
}
my @tindex = undef;
my @oids = undef;
my @descr = undef;
my (@oid_perf,@oid_perf_outoct,@oid_perf_inoct,@oid_perf_inerr,@oid_perf_outerr,@oid_perf_indisc,@oid_perf_outdisc)=
   (undef,undef,undef,undef,undef,undef,undef);
my $num_int = 0;

# Select interface by regexp of exact match 
# and put the oid to query in an array

verb("Filter : $o_descr");
foreach my $key ( keys %$resultat) {
   verb("OID : $key, Desc : $$resultat{$key}");
   # test by regexp or exact match
   my $test = defined($o_noreg) 
		? $$resultat{$key} eq $o_descr
		: $$resultat{$key} =~ /$o_descr/;
  if ($test) {
     # get the index number of the interface 
     my @oid_list = split (/\./,$key); 
     $tindex[$num_int] = pop (@oid_list); 
     # get the full description
     $descr[$num_int]=$$resultat{$key};
     # put the admin or oper oid in an array
     $oids[$num_int]= defined ($o_admin) ? $admin_table . $tindex[$num_int] 
			: $oper_table . $tindex[$num_int] ;
     # Put the performance oid 
     if (defined($o_perf) || defined($o_checkperf)) {
       $oid_perf_inoct[$num_int]= $in_octet_table . $tindex[$num_int];
       $oid_perf_outoct[$num_int]= $out_octet_table . $tindex[$num_int];
       if (defined($o_ext_checkperf) || defined($o_perfe)) {
	 $oid_perf_indisc[$num_int]= $in_discard_table . $tindex[$num_int];
	 $oid_perf_outdisc[$num_int]= $out_discard_table . $tindex[$num_int];
	 $oid_perf_inerr[$num_int]= $in_error_table . $tindex[$num_int];
	 $oid_perf_outerr[$num_int]= $out_error_table . $tindex[$num_int];
       }
     }
     verb("Name : $descr[$num_int], Index : $tindex[$num_int]");
     $num_int++;
  }
}
# No interface found -> error
if ( $num_int == 0 ) { print "ERROR : Unknown interface $o_descr\n" ; exit $ERRORS{"UNKNOWN"};}

my ($result,$resultf)=(undef,undef);
# Get the requested oid values
$result = $session->get_request(
   Varbindlist => \@oids
);
if (!defined($result)) { printf("ERROR: Status table : %s.\n", $session->error); $session->close;
   exit $ERRORS{"UNKNOWN"};
}
# Get the perf value if -f (performance) option defined or -k (check bandwidth)
if (defined($o_perf)||defined($o_checkperf)) {
  @oid_perf=(@oid_perf_outoct,@oid_perf_inoct,@oid_perf_inerr,@oid_perf_outerr,@oid_perf_indisc,@oid_perf_outdisc);
  $resultf = $session->get_request(
   Varbindlist => \@oid_perf
  );
  if (!defined($resultf)) { printf("ERROR: Statistics table : %s.\n", $session->error); $session->close;
     exit $ERRORS{"UNKNOWN"};
  }
}


$session->close;

my $num_ok=0;
my @checkperf_out=undef;
### Bandwidth test variables
my $temp_file_name;
my ($return,@file_values)=(undef,undef);
my $n_rows=0;
my $n_items_check=(defined($o_ext_checkperf))?7:3;
my $timenow=time;
my $trigger=$timenow - ($o_delta - ($o_delta/10));
my $trigger_low=$timenow - 3*$o_delta;
my ($old_value,$old_time)=undef;

# define the OK value depending on -i option
my $ok_val= defined ($o_inverse) ? 2 : 1;
my $final_status = 0;
my ($print_out,$perf_out)=(undef,undef);

# make all checks and output for all interfaces
for (my $i=0;$i < $num_int; $i++) { 
  $print_out.=", " if (defined($print_out));
  $perf_out .= " " if (defined ($perf_out)) ;

  # Get the status of the current interface
  my $int_status= defined ($o_admin) ? $$result{$admin_table . $tindex[$i]} 
		:  $$result{ $oper_table . $tindex[$i] };

  # Make the bandwith & error checks if necessary 
  if (defined ($o_checkperf) && $int_status==1) {
    $temp_file_name=$descr[$i];
    $temp_file_name =~ s/[ ;\/]/_/g;
    $temp_file_name = $o_base_dir . $o_host ."." . $temp_file_name; 
    # First, read entire file
    my @ret_array=read_file($temp_file_name,$n_items_check);
    $return = shift(@ret_array);
    $n_rows = shift(@ret_array);
    if ($n_rows != 0) { @file_values = @ret_array };     
    verb ("File read returns : $return with $n_rows rows");
    #make the checks if the file is OK  
    if ($return ==0) {
      my $j=$n_rows-1;
      @checkperf_out=undef;
      do {
	if ($file_values[$j][0] < $trigger) {
	  if ($file_values[$j][0] > $trigger_low) {
	    # check if the counter is back to 0 after 2^32.
	    my $overfl = ($$resultf{$oid_perf_inoct[$i]} >= $file_values[$j][1] ) ? 0 : 4294967296;
		my $speed_metric = (defined($o_kbits))? 128 : 1024;
	    $checkperf_out[0] = ( ($overfl + $$resultf{$oid_perf_inoct[$i]} - $file_values[$j][1])/
	      			      ($timenow - $file_values[$j][0] ))/$speed_metric;
	    
	    $overfl = ($$resultf{$oid_perf_outoct[$i]} >= $file_values[$j][2] ) ? 0 : 4294967296;
	    $checkperf_out[1] = ( ($$resultf{$oid_perf_outoct[$i]} - $file_values[$j][2])/
				      ($timenow - $file_values[$j][0] ))/$speed_metric;
	    
	    if (defined($o_ext_checkperf)) {
	      $checkperf_out[2] = ( ($$resultf{$oid_perf_inerr[$i]} - $file_values[$j][3])/
				($timenow - $file_values[$j][0] ))*60;
	      $checkperf_out[3] = ( ($$resultf{$oid_perf_outerr[$i]} - $file_values[$j][4])/
				($timenow - $file_values[$j][0] ))*60;
	      $checkperf_out[4] = ( ($$resultf{$oid_perf_indisc[$i]} - $file_values[$j][5])/
				($timenow - $file_values[$j][0] ))*60;
	      $checkperf_out[5] = ( ($$resultf{$oid_perf_outdisc[$i]} - $file_values[$j][6])/
				($timenow - $file_values[$j][0] ))*60;
	    }
	  }
	}
	$j--;
      } while ( ($j>=0) && (!defined($checkperf_out[0])) );
    } 
    # Put the new values in the array and write the file
    $file_values[$n_rows][0]=$timenow;
    $file_values[$n_rows][1]=$$resultf{$oid_perf_inoct[$i]};
    $file_values[$n_rows][2]=$$resultf{$oid_perf_outoct[$i]};
    if (defined($o_ext_checkperf)) { # Add other values (error & disc)
      $file_values[$n_rows][3]=$$resultf{$oid_perf_inerr[$i]};
      $file_values[$n_rows][4]=$$resultf{$oid_perf_outerr[$i]};
      $file_values[$n_rows][5]=$$resultf{$oid_perf_indisc[$i]};
      $file_values[$n_rows][6]=$$resultf{$oid_perf_outdisc[$i]};
    } 
    $n_rows++;
    $return=write_file($temp_file_name,$n_rows,$n_items_check,@file_values);
    verb ("Write file returned : $return");
    # Print the basic status
    if (defined ($o_short)) {
      my $short_desc=undef;
      if ($o_short < 0) {$short_desc=substr($descr[$i],$o_short);}
      else {$short_desc=substr($descr[$i],0,$o_short);}
      $print_out.=sprintf("%s:%s",$short_desc, $status{$int_status} );
    } else {
      $print_out.=sprintf("%s:%s",$descr[$i], $status{$int_status} );
    }
    if ($return !=0) { # On error writing, return Unknown status
      $final_status=3;
      $print_out.= " !!Unable to write file ".$temp_file_name." !! ";
    }
    # print the other checks if it was calculated
    if (defined($checkperf_out[0])) {
      $print_out.= " (";
      # check 2 or 6 values depending on ext_check_perf
      my $num_checkperf=(defined($o_ext_checkperf))?6:2;
      for (my $l=0;$l < $num_checkperf;$l++) {
        if ($l!=0) {$print_out.="/";}
	    if (($o_crit[$l]!=0) && ($checkperf_out[$l]>$o_crit[$l])) { 
          $final_status=2;
          $print_out.= sprintf("CRIT : %.1f",$checkperf_out[$l]); 
        } elsif (($o_warn[$l]!=0) && ($checkperf_out[$l]>$o_warn[$l])) { 
	  $final_status=($final_status==2)?2:1;
          $print_out.= sprintf("WARN : %.1f",$checkperf_out[$l]);
	} else {
          $print_out.= sprintf("%.1f",$checkperf_out[$l]);
	}
      }
      $print_out .= ")";
    } else { # Return unknown when no data
      $print_out.= " No usable data on file (".$n_rows." rows) ";
      $final_status=3;
    }
  } else {
    if (defined ($o_short)) {
      my $short_desc=undef;
      if ($o_short < 0) {$short_desc=substr($descr[$i],$o_short);}
      else {$short_desc=substr($descr[$i],0,$o_short);}
      $print_out.=sprintf("%s:%s",$short_desc, $status{$int_status} );
    } else {
      $print_out.=sprintf("%s:%s",$descr[$i], $status{$int_status} );
    }
  }
  # Get rid of special caracters for performance in description
  $descr[$i] =~ s/'/_/g;
  if ( $int_status == $ok_val) {
    $num_ok++;
  }
  if (( $int_status == 1 ) && defined ($o_perf)) {
    $perf_out .= "'" . $descr[$i] ."_in_octet'=". $$resultf{$oid_perf_inoct[$i]} ."c ";  
    $perf_out .= "'" . $descr[$i] ."_out_octet'=". $$resultf{$oid_perf_outoct[$i]} ."c";  
    if (defined ($o_perfe)) {
      $perf_out .= " '" . $descr[$i] ."_in_error'=". $$resultf{$oid_perf_inerr[$i]} ."c ";
      $perf_out .= "'" . $descr[$i] ."_in_discard'=". $$resultf{$oid_perf_indisc[$i]} ."c ";
      $perf_out .= "'" . $descr[$i] ."_out_error'=". $$resultf{$oid_perf_outerr[$i]} ."c ";
      $perf_out .= "'" . $descr[$i] ."_out_discard'=". $$resultf{$oid_perf_outdisc[$i]} ."c";
    }
  } 
}

# Only a few ms left...
alarm(0);

# Check if all interface are OK 
if ($num_ok == $num_int) {
  if ($final_status==0) {
    print $print_out,":", $num_ok, " UP: OK";
    if (defined ($o_perf)) { print " | ",$perf_out; }
    print "\n";
    exit $ERRORS{"OK"};
  } elsif ($final_status==1) {
    print $print_out,":(", $num_ok, " UP): WARNING";
    if (defined ($o_perf)) { print " | ",$perf_out; }
    print "\n";
    exit $ERRORS{"WARNING"};
  } elsif ($final_status==2) {
    print $print_out,":(", $num_ok, " UP): CRITICAL";
    if (defined ($o_perf)) { print " | ",$perf_out; }
    print "\n";
    exit $ERRORS{"CRITICAL"};
  } else {
    print $print_out,":(", $num_ok, " UP): UNKNOWN";
    if (defined ($o_perf)) { print " | ",$perf_out; }
    print "\n";
    exit $ERRORS{"UNKNOWN"};    
  }
}

# else print the not OK interface number and exit (return is always critical if at least one int is down).

print $print_out,": ", $num_int-$num_ok, " int NOK : CRITICAL";
if (defined ($o_perf)) { print " | ",$perf_out; }
print "\n";
exit $ERRORS{"CRITICAL"};

