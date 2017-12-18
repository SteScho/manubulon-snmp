# Manubulon SNMP Plugins Installation <a href="manubulon-snmp-plugins-installation"></a>

The plugins rely on the `Net::SNMP` Perl library for fetching
data from SNMP enabled hosts.

## Prerequisites <a href="manubulon-snmp-plugins-installation-required-prerequisites"></a>

### RHEL/CentOS EPEL Repository <a href="manubulon-snmp-plugins-installation-epel"></a>

RHEL/CentOS requires the EPEL repository:

```
yum -y install epel-release
yum makecache
```

If you are using RHEL you need enable the `optional` repository and then install
the [EPEL rpm package](https://fedoraproject.org/wiki/EPEL#How_can_I_use_these_extra_packages.3F).

## Perl Dependencies <a href="manubulon-snmp-plugins-installation-perl-dependencies"></a>

Debian/Ubuntu:

```
apt-get -y install libnet-snmp-perl libcrypt-des-perl libcrypt-rijndael-perl libdigest-hmac-perl
```

RHEL/CentOS/Fedora:

```
yum -y install perl-Net-SNMP perl-Getopt-Long perl-Crypt-DES perl-Crypt-Rijndael perl-Digest-HMAC
```

## Plugin Setup <a href="manubulon-snmp-plugins-installation-plugins"></a>

Debian/Ubuntu:

```
install -o root -g root -m755 plugins/*.pl /usr/lib/nagios/plugins/
```

RHEL/CentOS/Fedora:

```
install -o root -g root -m755 plugins/*.pl /usr/lib64/nagios/plugins/
```

Proceed with inspecting the plugins `--help` parameter in [this chapter](04-Plugins.md).

Next up: Integrate the plugins into your monitoring by adding [configuration](03-Configuration.md).

## Advanced Hints <a href="manubulon-snmp-plugins-installation-advanced"></a>

Perl, default directory and temp files location can be changed using the install.sh script.

`utils.pm` from `Monitoring::Plugin::Perl` is no longer required.

