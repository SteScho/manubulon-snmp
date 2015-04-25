# Manubulon SNMP Plugins

## General information

Manubulon SNMP plugins is a set of Icinga/Nagios plugins
to check hosts/devices using snmp protocol. Check
http://nagios.manubulon.com for more details.


## What's that repository for?

This is an unofficial cvs2git import from
http://sourceforge.net/projects/nagios-snmp/develop
with own and collected patches applied.

The original project was last active in 2007 so this repository
just helps collect all patches and feature requests.

Feel free to use & distribute it under the original license.

## Requirements

* perl in /usr/bin/perl
* Net::SNMP and Getopt::Long
* File `utils.pm` in Nagios plugin directory (default /usr/local/icinga/libexec)
* Icinga user is able to write files in /tmp/ directory

Perl, default directory and temp files location can be changed using the install.sh script.

> **NOTE:** If you're missing utils.pm, either install the
> nagios-plugins-common debian package or copy plugins/utils.pm
> to your perl lib path, or the one included like
> `use lib "/usr/local/icinga/libexec";`

## Documentation

The original documentation and sourcecode is located at
http://nagios.manubulon.com

## Support

The support tracker is still located at sf.net
http://sourceforge.net/tracker/?group_id=134917

You may create github issues here as well, but they will generally
remain unanswered due to my lack of time maintaining these plugins.

You may head over to http://www.monitoring-portal.org
for questions and feedback.


