#!/usr/bin/perl
#
# Build perl-package
# Jonas Thambert 2008

use strict;
use warnings;

my $PERL="/usr/bin/perl";
my @LDD=`ldd /usr/bin/perl`;
my $FILTERED = "";

for my $line (@LDD) {
 if ( $line =~ /[a-z0-9][a-z0-9] [a-z0-9][a-z0-9]/ ) {
 $line =~ s/.* //g;
 chomp $line;
 $FILTERED .= " $line";
 }
}

print "[+] Building perl.tgz...\n";
system("pax -x cpio -wzf perl.tgz $FILTERED"); 
print "[+] Done\n";

print "[+] Building perl_modules.tgz...\n";
system("pax -x cpio -wzf perl_modules.tgz /usr/libdata/perl5/"); 
print "[+] Done\n";
print "------------------------------\nNow copy the archives to your flashboot media:\n perl.tgz -> /pkg\n perl_modules.tgz -> /perl\n------------------------------\n"; 
