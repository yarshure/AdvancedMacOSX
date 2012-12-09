#!/usr/bin/perl

# schedule with
# launchctl load ./minimal-service.plist 
# launchctl unload ./minimal-service.plist 

use English;

# force auto-flush on standard out
$OUTPUT_AUTOFLUSH = 1;

while (<>) {
    chomp;
    print scalar reverse $ARG;
    print "\n";
}

