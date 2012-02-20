#!/usr/bin/perl

# mdm-2
# read mashups from spreadsheet
# show mashups

my %mashups;

readMashupEventsFromSpreadsheet();

experimentVariants();
experimentShowVariants("variants");

sub readMashupEventsFromSpreadsheet {
	my @entries;
	while (<>) {
		push @entries, $_;
	}
	my $N = 0;
	foreach (@entries) {
		# remove trailing nl and extra spaces from entry
		chomp;
		my ($date, @apis) = split(/,/);
		if (scalar(@apis) > 0) {
			$N++;		
			# remove extra spaces
			@apis = map { s/\s*//g; $_ } @apis;
			$mashups{$N} = \@apis;
		} 	# otherwise, it's an error in the data
	}
	return $N;
}

sub experimentVariants {
	# count copies of mashups using hashing
	# also compute markers for first and last occurrence of mashup, ie lifespan
	# we can uniquely represent each mashup by a string combining the names of the apis
	# in sorted order; then all we need to do is tally then
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
#		printStringList(@{$mashups{$mashup}});
		my $hash = hash(sort @{$mashups{$mashup}});
		$hash =~ s/[\'\"]//g;
#		print "\t$hash\n";
		unless ($mashupVariants{$hash}) {
			$mashupVariantsFirst{$hash} = $mashup;
		}
		$mashupVariantsLast{$hash} = $mashup;
		$mashupVariants{$hash}++;
	}
}		

sub experimentShowVariants {
	my ($mode) = @_;
	if ($mode eq "all") {
		foreach $variant (sort { $mashupVariants{$b} <=> $mashupVariants{$a} } keys %mashupVariants) {
			print "$variant, $mashupVariants{$variant}, $mashupVariantsFirst{$variant}, $mashupVariantsLast{$variant}\n";
		}
	} elsif ($mode eq "variants") {
		print "variant, n\n";
		foreach $variant (sort { $mashupVariants{$b} <=> $mashupVariants{$a} } keys %mashupVariants) {
			print "$variant, $mashupVariants{$variant}\n";
		}
	}
}

sub printStringList {
	my @list = @_;
	# TODO: replace with call to map and printList
	my $s;
	foreach $item (@list) {
		unless ($s) {
			$s = "'$item'";
		} else {
			$s .= ", '$item'";
		}
	}
	print "c( $s )\n";
}	

sub hash {
	my @list = @_;
	# TODO: replace with call to map and printList
	my $s;
	foreach $item (@list) {
		unless ($s) {
			$s = "$item";
		} else {
			$s .= "/$item";
		}
	}
	return $s;
}