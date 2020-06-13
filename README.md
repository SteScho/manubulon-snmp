# Manubulon SNMP Plugins

#### Table of Contents

1. [About](#about)
2. [License](#license)
3. [Support](#support)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [FAQ](#faq)
8. [Thanks](#thanks)
9. [Contributing](#contributing)

## About

Manubulon SNMP plugins is a set of Icinga/Nagios plugins
to check hosts/devices using the SNMP protocol.

### Plugin Overview

Plugin                        | Description
------------------------------|----------------------------------------
check\_snmp\_storage          | Storage checks (disks, swap, memory, etc.)
check\_snmp\_int              | Interface states, usage on hosts, switches, routers, etc.
check\_snmp\_process          | Running processes, their number, used CPU and memory.
check\_snmp\_load             | Load/CPU checks
check\_snmp\_mem              | Memory and swap usage
check\_snmp\_env              | Environmental status of fan, temp, power supplies.
check\_snmp\_vrrp             | Interface state of a VRRP cluster
check\_snmp\_cpfw             | Checkpoint Firewall-1 status
check\_snmp\_win              | Windows services
check\_snmp\_css              | CSS service states
check\_snmp\_nsbox            | Nsbox VHost and diode status
check\_snmp\_boostedge        | Boostedge services
check\_snmp\_linkproof\_ndr   | Linkproof NHR

## License

These plugins are licensed under the terms of the GNU General Public License.
You will find a copy of this license in the LICENSE file included in the source package.

## Support

## Requirements

* Perl in `/usr/bin/perl`
* Perl modules
  [Net::SNMP](http://search.cpan.org/~dtown/Net-SNMP-v6.0.1/lib/Net/SNMP.pm) and
  [Getopt::Long](http://search.cpan.org/~jv/Getopt-Long-2.49.1/lib/Getopt/Long.pm)
* `icinga` user able to write files in /tmp/ directory
* SNMP v3 authentication: Perl modules
  [Crypt::DES](http://search.cpan.org/~dparis/Crypt-DES-2.07/DES.pm),
  [Crypt::Rijndael](http://search.cpan.org/~leont/Crypt-Rijndael-1.13/Rijndael.pm) and
  [Digest::HMAC](http://search.cpan.org/~gaas/Digest-HMAC-1.03/lib/Digest/HMAC.pm)

## Installation

Detailed installation instructions can be found [here](doc/02-Installation.md).

## Configuration

Proceed [here](doc/03-Configuration.md) to get details on the configuration with Icinga 2, Icinga 1.x, etc.

## FAQ


## Thanks

Patrick Proy for creating and maintaining the original plugins.
[Michael Friedrich](https://twitter.com/dnsmichi) for maintaing the CVS import and adding community patches.

## Contributing

Fork this repository on GitHub and send in a PR.

There's a `.perltidyrc` file in the main repository tree. If you are uncertain about the coding style,
create your patch and then run:

```
$ perltidy -b plugins/*.pl
```

This requires the `perltidy` module being installed.
