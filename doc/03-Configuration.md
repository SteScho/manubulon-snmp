# Manubulon SNMP Plugins Configuration <a href="manubulon-snmp-plugins-configuration"></a>

Each plugin requires a command definition which defines the command line parameters
and arguments passed from service checks.

* [Icinga 2](03-Configuration.md#manubulon-snmp-plugins-configuration-icinga-2) integration
* [Icinga 1.x/Naemon/Nagios](03-Configuration.md#manubulon-snmp-plugins-configuration-icinga-1) integration

## Icinga 2 <a href="manubulon-snmp-plugins-configuration-icinga-2"></a>

The Icinga 2 Template Library (ITL) already provides many [CheckCommand definitions](https://www.icinga.com/docs/icinga2/latest/doc/10-icinga-template-library/#plugin-check-commands-for-manubulon-snmp)
out of the box. This enables you to just use the CheckCommand object and focus
on your service apply rules.

### Icinga 2: Best Practices <a href="manubulon-snmp-plugins-configuration-icinga-2-best-practices"></a>

Best practice is to store the credentials in a separate constant:

```
vim /etc/icinga2/constants.conf

const ManubulonSnmpCommunity = "icingasnmpro"
```

Define a generic SNMP service template and set common attributes.

```
template Service "snmp-template" {
  vars.snmp_community = ManubulonSnmpCommunity
}
```
### Icinga 2: Apply Rules <a href="manubulon-snmp-plugins-configuration-icinga-2-apply"></a>


Define service apply rules like this:

```
apply Service "snmp-memory" {
  import "snmp-template"
  check_command = "snmp-memory"

  vars.snmp_warn = "50,0"
  vars.snmp_crit = "80,0"

  assign where "snmp" in host.groups
}

apply Service "snmp-storage /var" {
  import "snmp-template"
  check_command = "snmp-storage"

  vars.snmp_warn = "50"
  vars.snmp_crit = "80"
  vars.snmp_storage_name = "/var"

  assign where "snmp" in host.groups
}

apply Service "snmp-storage" {
  import "snmp-template"
  check_command = "snmp-storage"

  vars.snmp_warn = "50"
  vars.snmp_crit = "80"

  assign where "snmp" in host.groups
}
```

### Icinga 2: Apply For Rules <a href="manubulon-snmp-plugins-configuration-icinga-2-apply-for"></a>

A more complex example using apply for rules is to store the
monitored storage disks on the host. This allows to generate
service objects in a more efficient way.

```
object Host "snmp-host" {
  check_command = "hostalive"

  vars.snmp_storage["/"] = {
    snmp_warn = "80"
    snmp_crit = "90"
  }
  vars.snmp_storage["/var"] = {
    snmp_warn = "60"
    snmp_crit = "90"
  }
}

apply Service "snmp-storage-" for (storage_name => config in host.vars.snmp_storage) {
  import "snmp-template"

  display_name = "Storage: " + storage_name

  vars += config
  vars.snmp_storage_name = storage_name
}
```


## Icinga 1.x/Naemon/Nagios <a href="manubulon-snmp-plugins-configuration-icinga-1"></a>

You need to write a check command definition and use that in your service definitions.
Please refer to [this documentation](http://nagios.manubulon.com/index_commands.html).

# For the basedir patch to check_snmp_int.pl, add the following to command-plugins-manubulon.conf

 "-b" = { 
        value = "$snmp_interface_basedir$" 
        description = "Basedir and template name for state files" 
  } 
  "--file-history" = { 
        value = "$snmp_interface_filehist$" 
        description = "How many records to keep in each state file" 
  } 