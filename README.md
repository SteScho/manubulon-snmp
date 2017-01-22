# Manubulon SNMP Plugins

## General information

Manubulon SNMP plugins is a set of Icinga/Nagios plugins
to check hosts/devices using the SNMP protocol. Check
[http://nagios.manubulon.com](http://nagios.manubulon.com) for more details.

This is a fork using a [cvs2git import](http://sourceforge.net/projects/nagios-snmp/develop) which includes community patches.

The original project was last active in 2007 so this project
helps collect all patches and feature requests.

Feel free to use & distribute it under the original license.

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

Distribution-specific packages:
* Debian/Ubuntu: `libnet-snmp-perl` and `libcrypt-des-perl libcrypt-rijndael-perl libdigest-hmac-perl`
* RHEL/CentOS: `perl-Net-SNMP perl-Getopt-Long` and `perl-Crypt-DES perl-Crypt-Rijndael perl-Digest-HMAC`

Perl, default directory and temp files location can be changed using the install.sh script.

`utils.pm` from `Monitoring::Plugin::Perl` is no longer required.

## Documentation

The original documentation and sourcecode is located at
[http://nagios.manubulon.com](http://nagios.manubulon.com).
A website copy was added underneath the `doc/` directory.

## Support

You may create [GitHub issues](https://github.com/dnsmichi/manubulon-snmp)
as well. I do have a lot of things on my plate so best is to send in a tested (!) patch at the same time.

If you want to help maintain this project, just contact
me on [twitter](https://twitter.com/dnsmichi) and I'll
happily grant commit access.

You may head over to [monitoring-portal.org community](http://www.monitoring-portal.org)
for questions and feedback.

The original support tracker is still located on [sourceforge](https://sourceforge.net/p/nagios-snmp/feature-requests/).

## Development

Fork this repository on Github and send in a PR.

There's a `.perltidyrc` file in the main repository tree. If you are uncertain about the coding style,
create your patch and then run:

    $ perltidy -b plugins/*.pl

This requires the `perltidy` module being installed.
