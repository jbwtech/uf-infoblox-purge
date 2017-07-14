# infoblox-purge
UF CLAS InfoBlox Allow list maintenance

This project contains code to access the InfoBlox IP Management system at the University of Florida for the College of Liberal Arts and Sciences. The code is designed to remove MAC addresses from the DHCP Allow list for devices that have been damaged, taken out of service, or otherwise no longer used by the college.

Access to the InfoBlox system is only available from within the UF Campus network. A UF GatorLink account and password is required and depends on a user account having privileges to make the necessary changes.

This program is intended to be run from a management workstation and will interface with the appliance to retrieve information and act on it.  I aslo relies on a local list of MAC addresses in a plain text file, one per lin with no special formatting of the address necessary.


## System Requirements

This program depends on the Infoblox AP perl module, which can be downloaded from the appliance. The API documentation is accessible online directly from the appliance. The UF appliance is [here](https://ipam.name.ufl.edu/api/doc/). Past experience indicates that the API may be specific to the version of firmware running on the appliance, so a mismatch in versions may have unintended consequences. This program was originally written for Infoblox API v.6.x and was executed on a Red Hat Enterprise Linux 7.x Workstation.

### Preparing Your Workstation 

Use the yum package manager to install perl and perll-CPAN and the necessary dependencies.

```
$ sudo yum install perl perl-CPAN
```

Next, open a perl shell with the CPAN module loaded.

```
$ perl -e shell -MCPAN
```

In addition to the perl modules listed below, install the following using CPAN:

```
perl> install ExtUtils::CBuilder
```

>
For IPv4 connections the following are required

- Perl 5.8.8 or later

- Crypt::SSLeay version 0.51 or later

- LWP::UserAgent version 5.813 or later

- XML::Parser

For IPv6 connections the following are required

- Perl 5.14.2 or later

- LWP::UserAgent version 6.02 or later and relevant dependencies, including LWP::Protocol::https

- Net::INET6Glue

- XML::Parser

to easily install the required libraries it is recommented to use CPAN, after installing perl run

 perl -e shell -MCPAN
and once configured simply run

 install LWP::UserAgent
 install XML::Parser

and the other packages you need depending on IPv4 or IPv6 accessibility.
>

