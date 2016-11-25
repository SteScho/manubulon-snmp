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

* perl in /usr/bin/perl
* Perl modules `Net::SNMP` and `Getopt::Long` (RHEL: `perl-Net-SNMP perl-Getopt-Long`)
* `icinga` user able to write files in /tmp/ directory

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


