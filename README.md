# Manubulon SNMP Plugins

## General information

Manubulon SNMP plugins is a set of Icinga/Nagios plugins
to check hosts/devices using snmp protocol. Check
[http://nagios.manubulon.com](http://nagios.manubulon.com) for more details.

This is a [cvs2git import](http://sourceforge.net/projects/nagios-snmp/develop)
with own and collected patches applied.

The original project was last active in 2007 so this project
just helps collect all patches and feature requests.

Feel free to use & distribute it under the original license.

## Requirements

* perl in /usr/bin/perl
* Perl modules `Net::SNMP` and `Getopt::Long` (RHEL: `perl-Net-SNMP perl-Getopt-Long`)
* Icinga user is able to write files in /tmp/ directory

Perl, default directory and temp files location can be changed using the install.sh script.

`utils.pm` from `Monitoring::Plugin::Perl` is no longer required.

## Documentation

The original documentation and sourcecode is located at
[http://nagios.manubulon.com](http://nagios.manubulon.com).
A website copy was added underneath the `doc/` directory.

## Support

You may create [github issues](https://github.com/dnsmichi/manubulon-snmp)
as well, but they will generally remain unanswered due
to my lack of time maintaining these plugins. I'm a long term
Icinga Core developer.

If you want to help maintain this project, just contact
me on [twitter](https://twitter.com/dnsmichi) and I'll
happily grant commit access.

You may head over to the [monitoring portal](http://www.monitoring-portal.org)
for questions and feedback.

The original support tracker is still located at sf.net
[sourceforge](http://sourceforge.net/tracker/?group_id=134917)


