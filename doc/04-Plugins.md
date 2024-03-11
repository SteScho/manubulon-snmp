# Manubulon SNMP Plugins <a href="manubulon-snmp-plugins"></a>

## Plugin Overview

Plugin                                                                | Description
----------------------------------------------------------------------|----------------------------------------
[check_snmp_storage](04-Plugins.md#manubulon-snmp-plugins-storage)    | Storage checks (disks, swap, memory, etc.)
[check_snmp_int](04-Plugins.md#manubulon-snmp-plugins-int)            | Interface states, usage on hosts, switches, routers, etc.
[check_snmp_process](04-Plugins.md#manubulon-snmp-plugins-process)    | Running processes, their number, used CPU and memory.
[check_snmp_load](04-Plugins.md#manubulon-snmp-plugins-load)          | Load/CPU checks
[check_snmp_mem](04-Plugins.md#manubulon-snmp-plugins-mem)            | Memory and swap usage
[check_snmp_env](04-Plugins.md#manubulon-snmp-plugins-env)            | Environmental status of fan, temp, power supplies.
[check_snmp_vrrp](04-Plugins.md#manubulon-snmp-plugins-vrrp)          | Interface state of a VRRP cluster
[check_snmp_cpfw](04-Plugins.md#manubulon-snmp-plugins-cpfw)          | Checkpoint Firewall-1 status
[check_snmp_win](04-Plugins.md#manubulon-snmp-plugins-win)            | Windows services
[check_snmp_css](04-Plugins.md#manubulon-snmp-plugins-css)            | CSS service states
[check_snmp_nsbox](04-Plugins.md#manubulon-snmp-plugins-nsbox)        | Nsbox VHost and diode status
[check_snmp_boostedge](04-Plugins.md#manubulon-snmp-plugins-hostedge) | Boostedge services
[check_snmp_linkproof_ndr](04-Plugins.md#manubulon-snmp-plugins-ndr)  | Linkproof NHR


## check\_snmp\_storage<a href="manubulon-snmp-plugins-storage"></a>

```
$ ./check_snmp_storage.pl --help

SNMP Disk Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
(c)2004-2007 Patrick Proy

Usage: check_snmp_storage [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) [-p <port>] [-P <protocol>] -m <name in desc_oid> [-q storagetype] -w <warn_level> -c <crit_level> [-t <timeout>] [-T pl|pu|bl|bu ] [-r -s -i -G] [-e] [-S 0|1[,1,<car>]] [-o <octet_length>] [-R <% reserved>]
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
-x, --passwd=PASSWD
   Password for snmpv3 authentication
-p, --port=PORT
   SNMP port (Default 161)
-P, --protocol=PROTOCOL
   Network protocol to be used
   ['udp/ipv4'] : UDP over IPv4
    'udp/ipv6'  : UDP over IPv6
    'tcp/ipv4'  : TCP over IPv4
    'tcp/ipv6'  : TCP over IPv6
-m, --name=NAME
   Name in description OID (can be mounpoints '/home' or 'Swap Space'...)
   This is treated as a regexp : -m /var will match /var , /var/log, /opt/var ...
   Test it before, because there are known bugs (ex : trailling /)
   No trailing slash for mountpoints !
-q, --storagetype=[Other|Ram|VirtualMemory|FixedDisk|RemovableDisk|FloppyDisk
                    CompactDisk|RamDisk|FlashMemory|NetworkDisk]
   Also check the storage type in addition of the name
   It is possible to use regular expressions ( "FixedDisk|FloppyDisk" )
-r, --noregexp
   Do not use regexp to match NAME in description OID
-s, --sum
   Add all storages that match NAME (used space and total space)
   THEN make the tests.
-i, --index
   Parse index table instead of description table to select storage
-e, --exclude
   Select all storages except the one(s) selected by -m
   No action on storage type selection
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
-R, --reserved=INTEGER
   % reserved blocks for superuser
   For ext2/3 filesystems, it is 5% by default
-G, --gigabyte
   output, warning & critical levels in gigabytes
-f, --perfparse, --perfdata
   Performance data output
-S, --short=<type>[,<where>,<cut>]
   <type>: Make the output shorter :
     0 : only print the global result except the disk in warning or critical
         ex: "< 80% : OK"
     1 : Don't print all info for every disk
         ex : "/ : 66 %used  (<  80) : OK"
   <where>: (optional) if = 1, put the OK/WARN/CRIT at the beginning
   <cut>: take the <n> first caracters or <n> last if n<0
-o, --octetlength=INTEGER
  max-size of the SNMP message, usefull in case of Too Long responses.
  Be carefull with network filters. Range 484 - 65535, default are
  usually 1472,1452,1460 or 1440.
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
```

## check\_snmp\_int <a href="manubulon-snmp-plugins-int"></a>

```
$ ./check_snmp_int.pl --help

SNMP Network Interface Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2007 Patrick Proy

Usage: ./check_snmp_int.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>)  [-p <port>] -n <name in desc_oid> [-N -A -i -a -D --down] [-r] [-f[eSyY]] [-k[qBMGu] -g -w<warn levels> -c<crit levels> -d<delta>] [-o <octet_length>] [-t <timeout>] [-s] --label [-V]
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
-r, --noregexp
   Do not use regexp to match NAME in description OID
-N, --use-ifname
   Use IF-MIB::ifName as source for NIC name instead of IF-MIB::ifDescr
-A, --use-ifalias
   Use IF-MIB::ifAlias as source for NIC name instead of IF-MIB::ifDescr
-i, --inverse
   Make critical when up
-a, --admin
   Use administrative status instead of operational
-D, --dormant
   Dormant state is an OK state
--down
   Down state is an OK state
-o, --octetlength=INTEGER
  max-size of the SNMP message, usefull in case of Too Long responses.
  Be carefull with network filters. Range 484 - 65535, default are
  usually 1472,1452,1460 or 1440.
-f, --perfparse, --perfdata
   Performance data output (no output when interface is down).
-W, --weather
   Output data for "weathermap" lines in NagVis with performance data
-e, --error
   Add error & discard to Perfparse output
-S, --intspeed
   Include speed in performance output in bits/s
-y, --perfprct ; -Y, --perfspeed
   -y : output performance data in % of max speed
   -Y : output performance data in bits/s or Bytes/s (depending on -B)
-k, --perfcheck ; -q, --extperfcheck
   -k check the input/ouput bandwidth of the interface
   -q also check the error and discard input/output
--label
   Add label before speed in output : in=, out=, errors-out=, etc...
-g, --64bits
   Use 64 bits counters instead of the standard counters when checking
   bandwidth & performance data for interface >= 1Gbps.
   You must use snmp v2c or v3 to get 64 bits counters.
-d, --delta=seconds
   make an average of <delta> seconds (default 300=5min)
-B, --kbits
   Make the warning and critical levels in K|M|G Bits/s instead of K|M|G Bytes/s
-G, --giga ; -M, --mega ; -u, --prct
   -G : Make the warning and critical levels in Gbps (with -B) or GBps
   -M : Make the warning and critical levels in Mbps (with -B) or MBps
   -u : Make the warning and critical levels in % of reported interface speed.
-w, --warning=input,output[,error in,error out,discard in,discard out,interface speed]
   warning level for input / output bandwidth (0 for no warning)
     unit depends on B,M,G,u options and interface speed is in bps
   warning for error & discard input / output in error/min (need -q)
-c, --critical=input,output[,error in,error out,discard in,discard out,interface speed]
   critical level for input / output bandwidth (0 for no critical)
     unit depends on B,M,G,u options and interface speed is in bps
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
```

## check\_snmp\_process <a href="manubulon-snmp-plugins-process"></a>

```
$ ./check_snmp_process.pl --help

SNMP Process Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2006 Patrick Proy

Usage: ./check_snmp_process.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd) [-p <port>] [-P <IP Protocol>] -n <name> [-w <min_proc>[,<max_proc>] -c <min_proc>[,max_proc] ] [-m<warn Mb>,<crit Mb> -a -u<warn %>,<crit%> -d<delta> ] [-t <timeout>] [-o <octet_length>] [-f -A -F ] [-r] [-V] [-g]
-v, --verbose
   print extra debugging information (and lists all storages)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1 or v2c with option)
-l, --login=LOGIN ; -x, --passwd=PASSWD, -2, --v2c
   Login and auth password for snmpv3 authentication
   If no priv password exists, implies AuthNoPriv
   -2 : use snmp v2c
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des)
-p, --port=PORT
   SNMP port (Default 161)
-P, --protocol=PROTOCOL
   Network protocol to be used
   ['udp/ipv4'] : UDP over IPv4
    'udp/ipv6'  : UDP over IPv6
    'tcp/ipv4'  : TCP over IPv4
    'tcp/ipv6'  : TCP over IPv6
-n, --name=NAME
   Name of the process (regexp)
   No trailing slash !
-r, --noregexp
   Do not use regexp to match NAME in description OID
-f, --fullpath
   Use full path name instead of process name
   (Windows doesn't provide full path name)
-A, --param
   Add parameters to select processes.
   ex : "named.*-t /var/named/chroot" will only select named process with this parameter
-F, --perfout
   Add performance output
   outputs : memory_usage, num_process, cpu_usage
-w, --warn=MIN[,MAX]
   Number of process that will cause a warning
   -1 for no warning, MAX must be >0. Ex : -w-1,50
-c, --critical=MIN[,MAX]
   number of process that will cause an error (
   -1 for no critical, MAX must be >0. Ex : -c-1,50
Notes on warning and critical :
   with the following options : -w m1,x1 -c m2,x2
   you must have : m2 <= m1 < x1 <= x2
   you can omit x1 or x2 or both
-m, --memory=WARN,CRIT
   checks memory usage (default max of all process)
   values are warning and critical values in Mb
-a, --average
   makes an average of memory used by process instead of max
-u, --cpu=WARN,CRIT
   checks cpu usage of all process
   values are warning and critical values in % of CPU usage
   if more than one CPU, value can be > 100% : 100%=1 CPU
-d, --delta=seconds
   make an average of <delta> seconds for CPU (default 300=5min)
-g, --getall
  In some cases, it is necessary to get all data at once because
  process die very frequently.
  This option eats bandwidth an cpu (for remote host) at breakfast.
-o, --octetlength=INTEGER
  max-size of the SNMP message, usefull in case of Too Long responses.
  Be carefull with network filters. Range 484 - 65535, default are
  usually 1472,1452,1460 or 1440.
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
Note :
  CPU usage is in % of one cpu, so maximum can be 100% * number of CPU
  example :
  Browse process list : <script> -C <community> -H <host> -n <anything> -v
  the -n option allows regexp in perl format :
  All process of /opt/soft/bin  	: -n /opt/soft/bin/ -f
  All 'named' process			: -n named
```

## check\_snmp\_load <a href="manubulon-snmp-plugins-load"></a>

```
$ ./check_snmp_load.pl --help

SNMP Load & CPU Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2007 Patrick Proy

Usage: ./check_snmp_load.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] [-P <protocol>] -w <warn level> -c <crit level> -T=[stand|netsl|netsc|as400|cisco|cata|cisg|nsc|fg|bc|nokia|hp|lp|hpux] [-f] [-t <timeout>] [-V]
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
-p, --port=PORT
   SNMP port (Default 161)
-P, --protocol=PROTOCOL
   Network protocol to be used
   ['udp/ipv4'] : UDP over IPv4
    'udp/ipv6'  : UDP over IPv6
    'tcp/ipv4'  : TCP over IPv4
    'tcp/ipv6'  : TCP over IPv6

   Network protocol (Default udp/ipv4)
-w, --warn=INTEGER | INT,INT,INT
   1 value check : warning level for cpu in percent (on one minute)
   3 value check : comma separated level for load or cpu for 1min, 5min, 15min
-c, --crit=INTEGER | INT,INT,INT
   critical level for cpu in percent (on one minute)
   1 value check : critical level for cpu in percent (on one minute)
   3 value check : comma separated level for load or cpu for 1min, 5min, 15min
-T, --type=stand|netsl|netsc|as400|cisco|cisg|bc|nokia|hp|lp
	CPU check :
		stand : standard MIBII (works with Windows),
		        can handle multiple CPU.
		netsl : linux load provided by Net SNMP (1,5 & 15 minutes values)
		netsc : cpu usage given by net-snmp (100-idle)
		as400 : as400 CPU usage
		cisco : Cisco CPU usage
		n5k   : Cisco Nexus CPU Usage
		cata  : Cisco catalyst CPU usage
		cisg  : Cisco small business (SG500) CPU usage (1,5 & 15 minutes values)
		nsc   : NetScreen CPU usage
		fg    : Fortigate CPU usage
		bc    : Bluecoat CPU usage
		nokia : Nokia CPU usage
		hp    : HP procurve switch CPU usage
		lp    : Linkproof CPU usage
		hpux  : HP-UX load (1,5 & 15 minutes values)
-f, --perfparse, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_mem <a href="manubulon-snmp-plugins-mem"></a>

```
$ ./check_snmp_mem.pl --help

SNMP Memory Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2007 Patrick Proy

Usage: ./check_snmp_mem.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] [-P <protocol>] -w <warn level> -c <crit level> [-I|-N|-E] [-f] [-m -b] [-t <timeout>] [-V]
-v, --verbose
   print extra debugging information
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1 or v2c with option)
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
-p, --port=PORT
   SNMP port (Default 161)
-P, --protocol=PROTOCOL
   Network protocol to be used
   ['udp/ipv4'] : UDP over IPv4
    'udp/ipv6'  : UDP over IPv6
    'tcp/ipv4'  : TCP over IPv4
    'tcp/ipv6'  : TCP over IPv6
-w, --warn=INTEGER | INT,INT
   warning level for memory in percent (0 for no checks)
     Default (-N switch) : comma separated level for Real Memory and Swap
     -I switch : warning level
-c, --crit=INTEGER | INT,INT
   critical level for memory in percent (0 for no checks)
     Default (-N switch) : comma separated level for Real Memory and Swap
     -I switch : critical level
-N, --netsnmp (default)
   check linux memory & swap provided by Net SNMP
-m, --memcache
   include cached memory in used memory (only with Net-SNMP)
-b, --membuffer
   exclude buffered memory in used memory (only with Net-SNMP)
-I, --cisco
   check cisco memory (sum of all memory pools)
-E, --hp
   check HP Procurve memory
-f, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_env <a href="manubulon-snmp-plugins-env"></a>

```
$ ./check_snmp_env.pl --help

SNMP environmental Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL License, (c)2006-2007 Patrick Proy

Usage: ./check_snmp_env.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -T (cisco|nokia|bc|iron|foundry|linux) [-F <rpm>] [-c <celcius>] [-f] [-t <timeout>] [-V]
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
-T, --type=cisco|nokia|bc|iron|foundry
   Environemental check :
	cisco : All Cisco equipements : voltage,temp,fan,power supply
	        (will try to check everything in the env mib)
	nokia : Nokia IP platforms : fan and power supply
	bc : BlueCoat platforms : fans, power supply, voltage, disks
	iron : IronPort platforms : fans, power supply, temp
	foundry : Foundry Network platforms : power supply, temp
	linux : Net-SNMP with LM-SENSORS : temp, fan, volt, misc
-F, --fan=<rpm>
   Minimum fan rpm value (only needed for 'iron' & 'linux')
-c, --celcius=<celcius>
   Maximum temp in degree celcius (only needed for 'iron' & 'linux')
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_vrrp <a href="manubulon-snmp-plugins-vrrp"></a>

```
$ ./check_snmp_vrrp.pl --help

SNMP VRRP Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2007 Patrick Proy

Usage: ./check_snmp_vrrp.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) -s <master|backup|num,%> [-T <nokia|alteon|lp|nsc|ipsocluster|foundry>] [-p <port>] [-t <timeout>] [-V]
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
-T, --type=<nokia|alteon|lp|nsc|ipso>
   Type of vrrp router to check
   nokia (default) : Nokia vrrp. Should be working for most vrrp routers
   alteon : for Alteon AD4 Loadbalancers
   lp : Radware Linkproof
   nsc : Nescreen (ScreenOS 5.x NSRP)
   ipso : Nokia IPSO clustering
   foundry : Foundry VRRP
-s, --state=master|backup|num,%
   Nokia ipso clustering : number of members, max % assigned to nodes.
   Other : check vrrp interface to be master or backup
-g, --long
   Make output long even is all is OK
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_cpfw <a href="manubulon-snmp-plugins-cpfw"></a>

```
$ ./check_snmp_cpfw.pl --help

SNMP Checkpoint FW-1 Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL License, (c)2004-2007 - Patrick Proy

Usage: ./check_snmp_cpfw.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) [-s] [-w [-p=pol_name] [-c=warn,crit]] [-m] [-a [standby] ] [-f] [-p <port>] [-t <timeout>] [-V]
-v, --verbose
   print extra debugging information (including interface list on the system)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
2, --v2c
   Use snmp v2c
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication
   If no priv password exists, implies AuthNoPriv
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des)
-s, --svn
   check for svn status
-w, --fw
   check for fw status
-a, --ha[=standby]
   check for ha status and node in "active" state
   If using SecurePlatform and monitoring a standby unit, put "standby" too
-m, --mgmt
   check for management status
-p, --policy=POLICY_NAME
   check if installed policy is POLICY_NAME (must have -w)
-c, --connexions=WARN,CRIT
   check warn and critical number of connexions (must have -w)
-f, --perfparse, --perfdata
   performance data output (only works with -c)
-P, --port=PORT
   SNMP port (Default 161)
-t, --timeout=INTEGER
   timeout for SNMP (Default: Nagios default)
-V, --version
   prints version number
```

## check\_snmp\_win <a href="manubulon-snmp-plugins-win"></a>

```
$ ./check_snmp_win.pl --help

SNMP Windows Monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL license, (c)2004-2007 Patrick Proy

Usage: check_snmp_win [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd) [-p <port>] -n <name>[,<name2] [-T=service] [-r] [-s] [-N=<n>] [-t <timeout>] [-V]
-v, --verbose
   print extra debugging information (and lists all services)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1 or v2c with option)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN
   Login for snmpv3 authentication (implies v3 protocol with MD5)
-x, --passwd=PASSWD
   Password for snmpv3 authentication
-p, --port=PORT
   SNMP port (Default 161)
-T, --type=service
   Check type :
     - service (default) checks service
-n, --name=NAME[,NAME2...]
   Comma separated names of services (perl regular expressions can be used for every one).
   By default, it is not case sensitive.
-N, --number=<n>
   Compare matching services with <n> instead of the number of names provided.
-s, --showall
   Show all services in the output, instead of only the non-active ones.
-r, --noregexp
   Do not use regexp to match NAME in service description.
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
Note :
  The script will return
    OK if ALL services are in active state,
    WARNING if there is more than specified (ex 2 service specified, 3 active services matching),
    CRITICAL if at least one of them is non active.
  The -n option will allows regexp in perl format
  -n "service" will match 'service WINS' 'sevice DNS' etc...
  It is not case sensitive by default : WINS = wins
```

## check\_snmp\_css <a href="manubulon-snmp-plugins-css"></a>

```
$ ./check_snmp_css.pl --help

SNMP Cisco CSS monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
(c)2004-2006 Patrick Proy

Usage: ./check_snmp_css.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) -n <name> [-d directory] [-w <num>,<resp>,<conn> -c <num>,<resp>,<conn>]  [-p <port>] [-f] [-t <timeout>] [-V]
-v, --verbose
   print extra debugging information
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-n, --name=<name>
   regexp to select service
-w, --warning=<num>,<resp>,<conn>
   Optional. Warning level for
   - minimum number of active & alive service
   - average response time
   - number of connexions
   For no warnings, put -1 (ex : -w5,-1,3).
   When using negative numbers, dont put space after "-w"
-d, --dir=<directory to put file>
   Directory where the temp file with index, created by check_snmp_css_main.pl, can be found
   If no directory is set, /tmp will be used
-c, --critical=<num>,resp>,<conn>
   Optional. Critical levels (-1 for no critical levels)
   See warning levels.
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
-f, --perfparse
   Perfparse compatible output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_nsbox <a href="manubulon-snmp-plugins-nsbox"></a>

```
$ ./check_snmp_nsbox.pl --help

SNMP NetSecureOne Netbox monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
(c)2004-2006 Patrick Proy

Usage: ./check_snmp_nsbox.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) -d <diode> -s <vhost> -n <ndiode>,<nvhost> [-p <port>] [-f] [-t <timeout>] [-V]
Check that diode and vhost selected by regexp are active.
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
-d, --diode=<diode>
	Diode selection by regexp
-s, --vhost=<vhost>
	Vhost selection by regexp
-n, --number=<ndiode>,<nvhost>
	number of diode and vhost that must be up.
-P, --port=PORT
   SNMP port (Default 161)
-f, --perfparse, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_boostedge <a href="manubulon-snmp-plugins-boostedge"></a>

```
$ ./check_snmp_boostedge.pl --help

SNMP Boostedge service monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
GPL License, (c)2006-2007 Patrick Proy

Usage: ./check_snmp_boostedge.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) -s <service> -n <number> [-p <port>] [-f] [-t <timeout>] [-V]
-v, --verbose
   print extra debugging information
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies v1 protocol)
-s, --service=<service>
   Regexp of service to select
-n, --number=<number>
   Number of services selected that must be in running & enabled state
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
-f, --perfparse, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

## check\_snmp\_linkproof\_nhr <a href="manubulon-snmp-plugins-linkproof-nhr"></a>

```
$ ./check_snmp_linkproof_nhr.pl --help

SNMP Radware Linkproof NHR monitor for Icinga/Nagios/Naemon/Shinken, Version 2.1.0
(c)2004-2006 Patrick Proy

Usage: ./check_snmp_linkproof_nhr.pl [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>]) [-p <port>] [-f] [-t <timeout>] [-V]
The plugin will test all nhr configured and will return
OK if all nhr are active
WARNING if one nhr at least is in "no new session" or "inactive" mode.
CRITICAL if all nhr are inactive.
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
-f, --perfparse, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
```

