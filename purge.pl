#!/usr/bin/perl -W

use Infoblox;

my $server   = "ipam.name.ufl.edu";
my $username = "clas-svc-infoblox";
my $password = "";
my $filter   = "CLAS_Allow";

print "Connecting to Infoblox ... ";
my $session = Infoblox::Session->new(
    master   => $server,
    username => $username,
    password => $password,
);

unless ($session) {
    die("FAILED!\n", Infoblox::status_code() . ":" . Infoblox::status_detail());
} 
print "SUCCESS!\n";


printf "Retrieving MAC addresses from filter: '%s' ... ", $filter;
@CLAS_Allowed = $session->search(
     object => "Infoblox::DHCP::MAC",
     filter => $filter,
);

my $object = $CLAS_Allowed[0];

unless ($object) {
    die("no records found\n", $session->status_code() . ":" . $session->status_detail());
}
printf "%s records found.\n", $#CLAS_Allowed;

my $AllowedMac = "";
my $PurgeCount = 0;
my $RetainCount = 0;

print "Scanning for fixed addresses or leases ...\n";

foreach $object (@CLAS_Allowed) {

    $AllowedMac = $object->mac();

    #printf "MAC: %s", $AllowedMac;
    if($AllowedMac eq "9c:93:4e:28:dc:05") { print " !!! Barf !!!\n"; next; }

    #printf "Geting lease info for [%s] ... ", $AllowedMac;
    my $objLease = $session->get(
        object   => "Infoblox::DHCP::Lease",
        mac      => $AllowedMac,
    );
    my $objFixed = $session->get(
        object   => "Infoblox::DHCP::FixedAddr",
        mac      => $AllowedMac,
    );
    if(($objLease) || ($objFixed)) {
        $RetainCount += 1;
        printf "MAC: %s   ", $AllowedMac;
        if($objLease) { printf "Lease End: %s IP: %s\n", $objLease->ends(), $objLease->ip_address(); }
        if($objFixed) { printf "Reserved IP: %s\n", $objFixed->ipv4addr(); }
        $object->guest_last_name("");
        my $response = $session->modify( $object );
        last;
    } else {
        printf "MAC: %s   PURGE  Comment: \"%s\"\n", $AllowedMac, $object->comment();
        $object->guest_last_name("*** PURGE ***");
        $object->filter("CLAS_Deny");
        my $response = $session->modify( $object );
#        printf "Update = %s\n", $response;

        $PurgeCount += 1;
        next;
    }

#    printf "IP Address : %s\n", $objLease->ip_address();
#    printf "Lease Start: %s\n", $objLease->starts();
#    printf "Lease End  : %s\n", $objLease->ends();

}

printf "Fixed Adresses or Leases found: %s\n", $RetainCount;
printf "Possible records to purge: %s\n\n", $PurgeCount;
printf "<<<EOF>>>\n\n";    


$session->logout();
