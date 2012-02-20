#!/usr/bin/perl

# mdm-1
# read mashups from spreadsheet
# show mashups

my %mashups;

readMashupEventsFromSpreadsheet();
experimentShowMashups();

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

sub experimentShowMashups {
 	foreach $mashup (sort { $a <=> $b } keys %mashups) {
 		print "$mashup, ";
 		printStringList(@{$mashups{$mashup}});
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