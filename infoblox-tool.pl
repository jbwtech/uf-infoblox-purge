#!/usr/bin/perl


use Term::ReadKey;
use Infoblox;

my $session;

my $strMACSource = "";

my $strFileIn = "";
my $strFileOut = "";

my $strFilterSource = "CLAS_Allow";
my $strFilterTarget = "CLAS_Purge";

my $strRegGuestLast  = "CURRENT";
my $strRegGuestFirst = "2015-JAN-20";

sub main_menu();
sub show_defaults();
sub set_source();
sub set_files();
sub set_filters();
sub set_regInfo();

sub get_file();
sub get_maclist();
sub get_filters();

sub menu_ChangeFilter();
sub menu_RegUpdate();
sub menu_S1Purge();
sub menu_S2Purge();
sub menu_3();

sub open_session();
sub close_session();
sub process_ChangeFilter();
sub process_RegUpdate();

sub process_file2();



until( main_menu() == 0 ) {
    # do nothing
}

exit;

############################################
#
# PROCEDURES
#
############################################

sub main_menu() {

    show_defaults;
    print "\n\nMain Menu\n\n";
    print "1) Set Source\n";
    print "2) Set Filters\n";
    print "3) Set Registration Info\n";
    print "4) Change a MAC's IPv4 filter\n";
    print "5) Registration Update\n";
    print "6) Stage 1 Purge\n";
    print "7) Stage 2 Purge\n";
#    print "2) Check for Lease\n";
    print "\nEnter choice (0 to quit): ";

    my $choice = <STDIN>;

    chomp($choice);

    print "\n";

#    if( $choice == 1 ) { set_files(); }
    if( $choice == 1 ) { set_source(); }
    if( $choice == 2 ) { set_filters(); }
    if( $choice == 3 ) { set_regInfo(); }
    if( $choice == 4 ) { menu_ChangeFilter(); }
    if( $choice == 5 ) { menu_RegUpdate(); }
    if( $choice == 6 ) { menu_S1Purge(); }
    if( $choice == 7 ) { menu_S2Purge(); }
    return $choice;

}


############################################
sub show_defaults() {

    printf "\n\n";
    printf "-" x 60 . "\n";
    printf "MAC Source      :  %s\n", $strFileIn;
    printf "Output file     :  %s\n", $strFileOut;
    printf "-" x 60 . "\n";
    printf "Source Filter   :  %s\n", $strFilterSource;
    printf "Target Filter   :  %s\n", $strFilterTarget;
    printf "-" x 60 . "\n";
    printf "Guest Last Name :  %s\n", $strRegGuestLast;
    printf "Guest First Name:  %s\n", $strRegGuestFirst;
    printf "-" x 60 . "\n";

}

############################################
sub set_source() {

    print "\n\n";
    print "[F]ile - A file containing MAC address, one per line\n";
    print "[L]ist - Manually enter a list\n";
    print "F[i]lter - An Infoblox DHCP IPv4 Filter name\n";
    print "\n Choose: ";

    my $strChoice = <STDIN>;

    chomp( $strChoice );

    $_ = $strChoice;
    if( /^[Ff]/ ) { get_file; }
    if( /^[Ll]/ ) { get_maclist; }
    if( /^[Ii]/ ) { get_filters; }

}


############################################
sub get_file() {

    my $tempFile = "";

    print "Enter MAC Source file: ";
    chomp( $tempFile = <STDIN> );
    print "\n";

    if(($tempFile ne "" ) && -e $tempFile ){
	$strFileIn = $tempFile;
    } else {
	print "File not found!\n\n";
    }

    return;
}

############################################
sub get_maclist() {

    my @strMACList;
    my $intListCount = 0;

    print "\n\nEnter MAC adresses, then press <Enter>, blank line to exit.\n";

    while( 1 ) {

	
        print $intListCount++ . ">";
	my $strTemp = <STDIN>;
	chomp( $strTemp );

	$_ = lc $strTemp;

	if( $_ ) {
	    if( ! /\:/ ) {
		s/([[:xdigit:]]{2})\B/$1:/g;
	    }
	   push @strMACList, $_;
	}
	else { last; }
    }

    foreach $_ (@strMACList ) {
	print "$_\n"; 
    }
}

############################################
sub get_filters() {

    open_session;

    my @objFilters = $session->get(
	object => "Infoblox::DHCP::Filter::MAC"
	);

    foreach $filter ( @objFilters ) {
	printf "Filter: %s\n", $filter->name();
    }

    my $objFilter = Infoblox::DHCP::Filter::MAC->new(
	name => "CLAS_Purge"
	);

    unless( $objFilter ) {
	print "Create MAC Filter failed!\n";
	die();
    }

    my $result = $session->add( $objFilter );

    printf "%s\n", $result;

    close_session;
}

############################################
sub set_files() {

    my $tempFile = "";

    print "Enter MAC Source file: ";
    chomp( $tempFile = <STDIN> );
    print "\n";

    if(($tempFile ne "" ) && -e $tempFile ){
	$strFileIn = $tempFile;
    } else {
	print "File not found!\n\n";
	return;
    }

    $tempFile = "";

    print "\"LOG-\" will be prefixed to the file name you choose.\n";
    print "Enter Output file: ";
    chomp( $tempFile = <STDIN> );
    print "\n";

    if( $tempFile ne "" ) {
	$strFileOut = "LOG-" . $tempFile;
    }
    return;
}

############################################
sub set_filters() {

    my $tempFilter = "";
    print "Enter source filter name (default: $strFilterSource): ";
    chomp( $tempFilter = <STDIN> );

    if( $tempFilter ne "" ) {
	$strFilterSource = $tempFilter;
    }

    $tempFilter = "";
    print "Enter destination filter name (default: $strFilterTarget): ";
    chomp( $tempFilter = <STDIN> );

    if( $tempFilter ne "" ) {
	$strFilterTarget = $tempFilter;
    }
    return;
}

############################################
sub set_regInfo() {

    my $tempStr = "";
    print "Enter Guest Last Name (default: $strRegGuestLast): ";
    chomp( $tempStr = <STDIN> );

    if( $tempStr ne "" ) {
	$strRegGuestLast = $tempStr;
    }

    $tempStr = "";
    print "Enter Guest First Name (default: $strRegGuestFirst): ";
    chomp( $tempStr = <STDIN> );

    if( $tempStr ne "" ) {
	$strRegGuestFirst = $tempStr;
    }
    return;
}

############################################
sub open_session() {

    my $server = "ipam.name.ufl.edu";
    my $username = "clas-svc-infoblox";
    my $password = "";

    if( $password eq "" ) {
	printf "Enter password for %s: ", $username;
	ReadMode('noecho');
	chomp( $password = <STDIN> );
	ReadMode(0);
	print "\n";
    }

    print "Connecting to Infoblox ... ";
    $session = Infoblox::Session->new(
	master   => $server,
	username => $username,
	password => $password,
	);

    unless ($session) {
	die("FAILED!\n", Infoblox::status_code() . ":" . Infoblox::status_detail());
    }
    print "connected.\n\n";
    return;
}

############################################
sub close_session() {

    print "Closing session ... ";
    if( $session->logout() == 0 ) {
	print "closed.\n";
    }
    return;
}


############################################
sub menu_ChangeFilter() {

    printf "MAC Source   : %s\n", $strFileIn;
    printf "Change Log   : %s\n", $strFileOut;
    printf "Filter Source: %s\n", $strFilterSource;
    printf "Filter Target: %s\n\n", $strFilterTarget;

    print "Process file (y/N)? ";
    my $answer = <STDIN>;
    chomp( $answer );
    print "\n";

    if( $answer ne "y" ) {
	print "\nAborting!\n";
	return;
    }

    if( $strFileIn ) { process_ChangeFilter; }
    return;
}

############################################
sub process_ChangeFilter() {

    my $recCount = 0;
    my $thisMAC = "";

    open_session;

    open( FILEIN , $strFileIn ) or die( "Input file not opened !!\n");
    open( FILEOUT, ">" . $strFileOut ) or die( "Output file not opened !!\n" );
    print FILEOUT "mac_address,source_filter,target_filter,modified_status\n";

    while( $thisMAC = <FILEIN> ) {

	$recCount++;

	chomp( $thisMAC );
	$thisMAC = lc $thisMAC;

	$_ = $thisMAC;

	if( ! /\:/ ) {
	    $thisMAC =~ s/([[:xdigit:]]{2})\B/$1:/g;
	}
	
	my $objMAC = $session->get(
	    object => "Infoblox::DHCP::MAC",
	    filter => $strFilterSource,
	    mac    => $thisMAC,
	    );

	unless ($objMAC) {
	    print $thisMAC . " not found\n";
	    next;
	}

	printf STDOUT "%s,%s,%s,", $thisMAC, $strFilterSource, $strFilterTarget;
	printf FILEOUT "%s,%s,%s,", $thisMAC, $strFilterSource, $strFilterTarget;

	$objMAC->filter( $strFilterTarget );

	my $result = 0;
#	my $result = $session->modify( $objMAC );

	printf STDOUT "%s\n", $result;
	printf FILEOUT "%s\n", $result;

    }

    printf "\n\n%s record(s) processed.\n", $recCount;
    close_session;

    return;
}


############################################
sub menu_RegUpdate() {

    printf "MAC Source      : %s\n", $strFileIn;
    printf "Change Log      : %s\n", $strFileOut;
    printf "Guest Last Name : %s\n", $strRegGuestLast;
    printf "Guest First Name: %s\n\n", $strRegGuestFirst;

    print "Process file (y/N)? ";
    my $answer = <STDIN>;
    chomp( $answer );
    print "\n";

    if( $answer ne "y" ) {
	print "\nAborting!\n";
	return;
    }

    if( $strFileIn ) { process_RegUpdate; }

    return;
}

############################################
sub process_RegUpdate() {

    my $thisMAC = "";
    my $recCount = 0;

    open( FILEIN , $strFileIn ) or die( "Input file not opened !!\n");
    open( FILEOUT, ">" . $strFileOut ) or die( "Output file not opened !!\n" );
    print FILEOUT "mac_address,old_guest_last_name,old_guest_first_name,new_guest_last_name,new_guest_first_name,modified_status\n";

    open_session;

    while( $thisMAC = <FILEIN> ) {

	$recCount++;

	chomp( $thisMAC );
	$thisMAC = lc $thisMAC;

	$_ = $thisMAC;

	if( ! /\:/ ) {
	    $thisMAC =~ s/([[:xdigit:]]{2})\B/$1:/g;
	}
	
	my $strOldLastName  = "";
	my $strOldFirstName = "";

	my $objMAC = $session->get(
	    object => "Infoblox::DHCP::MAC",
	    filter => $strFilterSource,
	    mac    => $thisMAC
	    );

	unless ($objMAC) {
	    print $thisMAC . " not found\n";
	    next;
	}

	# get the current values for guest_last_name and guest_first_name from Infoblox for the device
	$strOldLastName  = $objMAC->guest_last_name();
	$strOldFirstName = $objMAC->guest_first_name();

	printf STDOUT "%s,%s,%s,%s,%s,", $thisMAC, $strOldLastName, $strOldFirstName, $strRegGuestLast,$strRegGuestFirst;
	printf FILEOUT "%s,%s,%s,%s,%s,", $thisMAC, $strOldLastName, $strOldFirstName, $strRegGuestLast,$strRegGuestFirst;

	$objMAC->guest_last_name( $strRegGuestLast );
	$objMAC->guest_first_name( $strRegGuestFirst );

#	my $result = 0;
	my $result = $session->modify( $objMAC );

	printf STDOUT "%s\n", $result;
 	printf FILEOUT "%s\n", $result;
    }

    printf "\n\n%s record(s) processed.\n", $recCount;
    close_session;

    return;

}


############################################
sub menu_2() {

    printf "File   : %s\n", $fileSrc;
    #printf "Filter : %s\n", $filterSrc;
    #printf "Destination: %s\n", $filterDest;

    print "Process file (y/N)? ";
    my $answer = <STDIN>;
    chomp( $answer );
    print "\n";

    if( $answer ne "y" ) {
	print "\nAborting!\n";
	return;
    }

    if( $strFileIn ) { process_file2; }
    return;
}

############################################
sub process_file2() {

    $fileDest = $fileSrc;
    $fileDest =~ s/\./-found\./l;
    my $thisMAC = "";
    my $recCount = 0;
    my $leasesFound = 0;

    open( FILEIN , $strFileIn ) or die( "Input file not opened !!\n");
    open( FILEOUT, ">" . $strFileOut ) or die( "Output file not opened !!\n" );
    print FILEOUT "mac_address,old_guest_last_name,old_guest_first_name,new_guest_last_name,new_guest_first_name,modified_status\n";

    open_session;

    while( $thisMAC = <FILEIN> ) {

	$recCount++;

	# discard the newlin character and convert the string to lowercase
	chomp( $thisMAC );
	$thisMAC = lc "$thisMAC";

	# If the MAC address string is longer than 12 characters,
	# don't do anything, just go to the next line of the file
	if( length $thisMAC > 12 ) { next; }

	# Insert colons into the MAC address string
	#$thisMAC = Net::MAC->new( mac => $thisMAC )->as_IEEE();
	$thisMAC =~ s/([[:xdigit:]]{2})\B/$1:/g;

	my $objLease = $session->get(
	    object   => "Infoblox::DHCP::Lease",
	    mac      => $thisMAC
	    );

	# If there is already a lease object, don't waste time
	# searching for a Fixed Address
	unless( $objLease ) {
	    my $objFixed = $session->get(
		object   => "Infoblox::DHCP::FixedAddr",
		mac      => $thisMAC
		);
	}

	if(($objLease) || ($objFixed)) {
	    printf "%s - %s\n", $thisMAC, ++$leasesFound;
	    print FILEOUT $thisMAC . "\n";
	}
    }
    printf "\n\n%s record(s) processed.\n", $recCount;
    return;
}

############################################
sub menu_S1Purge() {

# show filters
    show_defaults;

# show description of process
    print "*" x 80 . "\n";
    print "* This process will move a batch of MAC objects from one filter list to another\n";
    print "* If a lease exists for a MAC object, it will be marked as \"CURRENT\" and will\n";
    print "* be moved.  The objects that are moved will be marked with the date they are\n";
    print "* moved to aid in selecting them for final deletion using a Stage 2 Purge.\n";
    print "*" x 80 . "\n";

# batch size (default 500)
    my $intBatchSize = 500;
    printf "BatchSize: %s\n", $intBatchSize;

    open_session;

    print "Retrieving MAC objects from Infoblox...\n";

    my @macObjects = $session->get(
	object => "Infoblox::DHCP::MAC",
	filter => $strFilterSource );

    printf "Filter Objects retrieved: %s\n", $#macObjects;
   
    print "Begin Stage 1 Purge (y/N)? ";
    $answer = <STDIN>;
    chomp( $answer );
    print "\n";

    if( $answer ne "y" ) {
	print "\nAborting!\n";
	return;
    }

    my $intCounter = 0;

MACOBJECT:
    foreach $thisMAC ( @macObjects ) {

	if( ($thisMAC->guest_last_name() ) && ($thisMAC->guest_first_name() ) ) {
	    # If there is something already defined in either of the name fileds
	    # on the allow list then, it can be ignored and skipped
	    next MACOBJECT;
	} 

	while( $intCounter < $intBatchSize ) {

	    # check for a lease
	    my @objLease = $session->get(
		object => "Infoblox::DHCP::Lease",
		mac    => $thisMAC );

	    # If a current lease is found 
	    if( $objLease[0] ) {

		# mark as current
		# mark date 

		$thisMac->guest_last_name( "CURRENT" );
		$thisMac->guest_first_name( $strRegGuestFirst );

		printf "%s! %s, %s, Filter: %s\n", $thisMAC->guest_last_name(), $thisMAC->mac(), $thisMAC->guest_first_name(), $thisMAC->filter();
		next MACOBJECT;

	    } else {

		# mark as purge
		# mark date
		$thisMAC->guest_last_name( "PURGE" );
		$thisMAC->guest_first_name( $strRegGuestFirst );

		# set filter to CLAS_Purge
		$thisMAC->filter( $strFilterTarget );

		$session->modify( $thisMAC ) 
		    or die("Modify MAC Address object failed: ", $session->status_code() . ":" . $session->status_detail());

		# increment counter
		printf "%s: ", ++$intCounter;
		printf "%s! %s, %s, Filter: %s\n", $thisMAC->guest_last_name(), $thisMAC->mac(), $thisMAC->guest_first_name(), $thisMAC->filter();
		next MACOBJECT;

	    }
	}
    }
}

############################################
