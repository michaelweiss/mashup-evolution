#!/usr/bin/perl

# mdm-2
# read mashups from spreadsheet
# compute mashup lifespan

my %mashups;
my %mashupVariants;
my %top5;
my @periods;

readMashupEventsFromSpreadsheet();

# experimentLifespans(249);		# 3 months
experimentLifespans(83);		# 1 month

# experimentShowLifespans();
experimentShowLifespansOverTime("GoogleMaps");
experimentShowLifespansOverTime("Flickr");
experimentShowLifespansOverTime("YouTube");
experimentShowLifespansOverTime("AmazoneCommerce");
experimentShowLifespansOverTime("GoogleMaps/YouTube");
experimentShowLifespansOverTime("Twitter");
experimentShowLifespansOverTime("411Sync");
experimentShowLifespansOverTime("MicrosoftVirtualEarth");
experimentShowLifespansOverTime("GoogleMaps/Twitter");
experimentShowLifespansOverTime("Shopping.com");


# all-time most popular
# experimentLifespans(4983);	# 5 years

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

sub experimentLifespans {
	my ($period) = @_;
	# count how often a mashup appears in the top5 in a given period
	# as there is no natural period, we need to experiment with several
	# one good choice is the length of an epoch in the simulation (n)
	my $k = 1;	# index in current period
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
		my $hash = hash(sort @{$mashups{$mashup}});
		$hash =~ s/[\'\"]//g;
		$mashupVariants{$hash}++;
#		print "$k, $hash\n";
		if ($k == $period) {
			experimentTop5($period, $k);
			my $variants = {};
			foreach $hash (keys %mashupVariants) {
				$variants->{$hash} = $mashupVariants{$hash};
#				print "variants of $hash: $variants->{$hash}\n";
			}
			push(@periods, $variants);
			$k = 1;
			%mashupVariants = [];
		}
		$k++;
	}
}		

sub experimentTop5 {
	my ($period, $k) = @_;
	# print "> $k mashups in $period:\n";
	my $top = 1;
	foreach $hash (sort { $mashupVariants{$b} <=> $mashupVariants{$a} } keys %mashupVariants) {
		# print "$hash, $mashupVariants{$hash}\n";
		$top5{$hash}++;		# count the number of times each mashup occurs in the top5
		last if ($top++ == 10);
	}
}

sub experimentShowLifespans {
	foreach $hash (sort { $top5{$b} <=> $top5{$a} } keys %top5) {
		print "$hash, $top5{$hash}\n";
		# print "$top5{$hash},";
	}
}

sub experimentShowLifespansOverTime {
	my ($hash) = @_;
	print "$hash,";
	foreach $period (@periods) {
		my $times = $period->{$hash};
		unless ($times) { 
			$times = 0; 
		}
		print "$times,";
	}
	print "\n";
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