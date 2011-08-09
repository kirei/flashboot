#!/usr/bin/perl

# Generate short /etc/moduli by randomly picking a couple of entries for 
# each modulus size

use strict;
use warnings;

my $MODULI_PER_SIZE = 4;

open EM, "</etc/moduli" or die "open(/etc/moduli): $!";

my %moduli;

while (<EM>) {
	s/#.*//g;
	my $modulus = $_;
	my $size;
	
	($size) = /^\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+[0-9A-Fa-f]+\s*$/
		or next;
	
	$moduli{$size} = [] if not defined $moduli{$size};
	push @{$moduli{$size}}, $modulus;
}

close EM;

srand; # No, it doesn't matter that I am using a LCG RNG here...

foreach my $size (sort keys %moduli) {
	my @moduli_of_size = @{$moduli{$size}};

	print STDERR "Picking $MODULI_PER_SIZE moduli of size $size " . 
	    "from " . scalar(@moduli_of_size) . "\n";

	for (my $i = 0; $i < $MODULI_PER_SIZE; $i++) {
		my $n = scalar(@moduli_of_size);

		if ($n == 0) {
			print STDERR "Ran out of moduli for size $size\n";
			last;
		}
		my $ndx = int(rand($n));
		print $moduli_of_size[$ndx];
		# Delete this modulus so we don't get it again
		splice @moduli_of_size, $ndx, 1;
	}
}

sub min
{
	my $min;

	foreach my $c (@_) {
		$min = $c if not defined $min or $c < $min;
	}
	return $min;
}
