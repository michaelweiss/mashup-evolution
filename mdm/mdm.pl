#!/usr/bin/perl
# mashups distance

# hash to test whether an api has already been created
my %mashups;
my %mashupName;
my %mashupCreationDate;
my %dist;
my %mashupCopies;
my %mashupVariants;
my %mashupVariantsFirst;
my %mashupVariantsLast;

# set $invidivuals to 1 if you want to include all mashups
# set $individuals to 0 if you want to only include one mashup of each species
my $individuals = 1;
my $species = !$individuals;
my %excluded;

my %apis;

readMashupEventsFromSpreadsheet();
experimentShowMashups();

exit();

# experimentCluster();

experimentVariants();
experimentShowVariants("variants");

sub experimentShowMashups {
 	foreach $mashup (sort { $a <=> $b } keys %mashups) {
 		print "$mashup, $mashupName{$mashup}, ";
 		printStringList(@{$mashups{$mashup}});
 	}
}

sub experimentCluster {
	my $napis = $#apis + 1;
	experimentMashupDistanceMatrix($napis);
}

sub experimentCopies {
	my $napis = $#apis + 1;
	experimentMashupDistanceMatrix($napis);
	computeMashupCopies(0.0);
	
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
		my $copies = $mashupCopies{$mashup};
		unless ($copies) { 
			$copies = 0;
		}
	 	print "$mashup, $mashupName{$mashup}, $copies, ";
	 	printStringList(@{$mashups{$mashup}}); 
	}
}

sub experimentVariants {
	# alternative to experimentCopies() which does not compute the distance
	# matrix (time-cosuming), but relies on hashing instead. For each mashup, we
	# can uniquely represent it by a string combining the names of the apis
	# in sorted order); all we need to do is to tally then
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
		my $hash = hash(sort @{$mashups{$mashup}});
		$hash =~ s/[\'\"]//g;
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
		foreach $variant (sort { $mashupVariantsFirst{$a} <=> $mashupVariantsFirst{$b} } keys %mashupVariantsFirst) {
			print "$variant, $mashupVariantsFirst{$variant}, $mashupVariantsLast{$variant}, $mashupVariants{$variant}\n";
		}
	} elsif ($mode eq "variants") {
		print "variant, n\n";
		foreach $variant (sort { $mashupVariants{$b} <=> $mashupVariants{$a} } keys %mashupVariants) {
			print "$variant, $mashupVariants{$variant}\n";
		}
	}
}
		
# experimentMashupComplexity(1);
# experimentMashupDistanceMatrix(2);

sub experimentMashupDistanceMatrix {
	my ($n) = @_;	# number of top APIs
	
	# compute top n apis
	%apis = computeApiUsage();
	print "apis = ";
#	printStringList(keys %apis);

	my @apis = keys %apis; 		# topNApis($n);
	
	print "top <- ";
	printStringList(@apis);
	
	# identify mashups that use those APIs
	# filter out other mashups
	my @uses = mashupsUsingApis(@apis);
	my %newMashups;
	foreach $mashup (@uses) {
		$newMashups{$mashup} = $mashups{$mashup};
	}
	%mashups = %newMashups;
	
	createDistanceMatrix();
	printDistanceMatrix();
}


sub experimentMashupComplexity {
	my ($n) = @_;		# number of top APIs
	
	# compute top n apis
	%apis = computeApiUsage();
	my @apis = topNApis($n);
	
	print "top <- ";
	printStringList(@apis);
	
	my @uses = mashupsUsingApis(@apis);
	my @complexity = mashupComplexity(@uses);
	
	print "complexity <- ";
	printList(@complexity);
}


#foreach $mashup (@uses) {
#	print "$mashup ";
#}
#print "\n";

#foreach $api (@apis) {
#	my @uses = mashupsUsingApis($api);
#	my $times = $#uses + 1;
#	print "$api, $times\n";
#}

# createDistanceMatrix();
# printDistanceMatrix();


# read mashup events from a file whose lines conform to the format:
# mashup(id, number?, mashup, description, ['api1', 'api2', ...], date).
# create netlogo instructions for adding events to the replay
sub readMashupEvents {
	while (<>) {
	    # read the next mashup event
	    if (/mashup\(\d+, '(\d+)', '(.+?)', '.+?', \[(.+?)\]/) {
	        my ($mashup, $name, $apis) = ($1, $2, $3);
	        my @apis;
	        # read through the list of apis used by the mashup
	        while ($apis =~ /'(.+?)'/g) {
	            my $api = $1;
	            push @apis, $api;
	        }
			$mashups{$mashup} = \@apis;
			$mashupName{$mashup} = $name;
	    }
	}
}

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
			$mashupCreationDate{$N} = $date;
			$mashupName{$N} = $N;
			# remove extra spaces
			@apis = map { s/\s*//g; $_ } @apis;
			$mashups{$N} = \@apis;
		} 	# otherwise, it's an error in the data
	}
	return $N;
}

sub readMashupEventsFromSpreadsheetOriginal {
	my @entries;
	while (<>) {
		push @entries, $_;
	}
	@entries = reverse @entries;
	my $N = 0;
	foreach (@entries) {
		# remove trailing nl and extra spaces from entry
		chomp;
		$N++;		
		if (/</) {
			if (/(\d{2}\/\d{2}\/\d{4}),(.+?)</) {
				$mashupCreationDate{$N}	= $1;
				$mashupName{$N} = $2;
			}
			if (/<td>(<a href=".+?">.+?<\/a>.+?)/) {
				my @entry = split(/,\s?/, $1);
				print "$N, ";
				printStringList(@entry);
				@entry = cleanApiData(@entry);
				$mashups{$N} = \@entry;
			}
		} else {
			my @entry = split(/,\s?/);
			$mashupCreationDate{$N} = shift @entry;
			$mashupName{$N} = shift @entry;
			$mashups{$N} = \@entry;
		}
	}
	return $N;
}

sub cleanApiData {
	my @apis = @_;
	my @cleanApis;
	my $api;
	foreach $api (@apis) {
		$api =~ s/<a.+?>//;
		$apis =~ s/<\/a.+//;
		if (/^[A-Z]\w+$/) {
			push @cleanApis, $api;
		}
	}
	return @cleanApis;
}

# compute how often each api is used by a mashup
sub computeApiUsage {
	my %apis;
	my $mashup, $api;
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
		my @apis = @{$mashups{$mashup}};
#		print "mashup: $mashup, apis: ";
#		printStringList(@apis);
		# iterate through all apis in mashup
		foreach $api (@apis) {
			# increment usage counter for each api
			$apis{$api}++;
#			print "api{", $api, "} = ", $apis{$api}, "\n";
		}
	}
	return %apis;
}

# sort apis by usages and return top n
sub topNApis {
	my ($top) = @_;
	my @top;
	foreach $api (sort { $apis{$b} <=> $apis{$a} } keys %apis) {
		if ($top-- > 0) {
			push @top, $api;
		} else {
			break;
		}
	}
	return @top;
}

# filter mashups using at least one of the given apis
sub mashupsUsingApis {
	my @apis = @_;
	my @mashups;
	foreach $used (@apis) {
		foreach $mashup (sort { $a <=> $b } keys %mashups) {
			my @apis = @{$mashups{$mashup}};
			my $found = 0;
			foreach $api (@apis) {
				if ($api eq $used) {
					$found = 1;
					break;
				}
			}
			if ($found) {
				push @mashups, $mashup;
			}
		}
	}
	return dedup(@mashups);
}

# remove duplicates from list
sub dedup {
	my @list = @_;
	my @newlist;
	@list = sort { $a <=> $b } @list;
	my $lastAdded;
	foreach $item (@list) {
		unless ($lastAdded eq $item) {
			push @newlist, $item;
			$lastAdded = $item;
		}
	}
	return @newlist;
}

# report complexity of mashups as measured by the number of APIs in a mashups
sub mashupComplexity {
	my @mashups = @_;
	my @sizes;
	foreach $mashup (@mashups) {
		my @apis = @{$mashups{$mashup}};
#		print "complexity.mashup: $mashup, apis: ", @apis, "\n";
		push @sizes, $#apis + 1;
	}
	return @sizes;
}

# create a distance matrix using the jaccard metric to compare mashups
sub createDistanceMatrix {
	my @exclude;
	foreach $mashup_i (sort { $a <=> $b } keys %mashups) {
		foreach $mashup_j (sort { $a <=> $b } keys %mashups) {
			if ($mashup_j > $mashup_i) {
				my $d = 1-jaccard($mashup_i, $mashup_j);
				$dist{$mashup_i}->{$mashup_j} = $d;		
				$dist{$mashup_j}->{$mashup_i} = $d;	
				if ($d == 0) {
					push @exclude, $mashup_j;
				}
			} elsif ($mashup_j == $mashup_i) {
				$dist{$mashup_i}->{$mashup_j} = 0;
			}
		}
	}
	if ($species) {
		foreach $mashup_i (@exclude) {
			$excluded{$mashup_i} = $mashups{$mashup_i};
			delete $mashups{$mashup_i};
		}
	}
}

# print the distance matrix
sub printDistanceMatrix {
	my @mashups = keys %mashups;
	my $size = @mashups;
	print <<END;
library(ape)
	
END
	dumpRMatrix($size);
	
	print <<END;
# tr <- bionj(M)
# plot(tr, "u")
END
}

sub jaccard  {
	my ($i, $j) = @_;
	my @apis_i = @{$mashups{$i}};
#	print "i: ", @apis_i, "\n";
	my @apis_j = @{$mashups{$j}};
#	print "j: ", @apis_j, "\n";
	my %join;
	my %union;
	my $joinlen;
	my $unionlen;
	foreach $api_i (@apis_i) {
		$union{$api_i} = 1;
		foreach $api_j (@apis_j) {
			$union{$api_j} = 1;
			if ($api_j eq $api_i) {
				$join{$api_i} = 1;
			}
		}
	}
	$joinlen = scalar(keys %join);
	$unionlen = scalar(keys %union);
#	print "($i,$j) = $joinlen/$unionlen\n";
#	foreach $i (keys %union) {
#		print "$i ";
#	}
#	print "\n";
#	return 1;
	unless ($unionlen > 0) {
		return 0.0;
	}
	return 1.0*$joinlen/$unionlen;
}

# TODO: compute individual as well as species counts
# currently only determines individual count
sub computeMashupCopies {
	my ($threshold) = @_;
	foreach $mashup_i (sort { $a <=> $b } keys %mashups) {
		foreach $mashup_j (sort { $a <=> $b } keys %mashups) {
			if ($mashup_j > $mashup_i) {
				if ($dist{$mashup_i}->{$mashup_j} <= $threshold) {	
					$mashupCopies{$mashup_i}++;
				}
			}
		}
	}	
}

sub testDump {
	foreach $mashup (sort keys %mashups) {
		print "$mashup: ";
		foreach $api (@{$mashups{$mashup}}) {
			print "($api) ";
		}
		print "\n";
	}
}

sub testDumpMatrix {
	foreach $mashup_j (sort keys %mashups) {
		print "$mashup_j ";
	}
	print "\n";
	
	foreach $mashup_i (sort keys %mashups) {
		print "$mashup_i ";
		foreach $mashup_j (sort keys %mashups) {
			print $dist{$mashup_i}->{$mashup_j};
			print " ";
		}
		print "\n";
	}
}

sub dumpRMatrix {
	my ($size) = @_;
	print "x <- c( ";
	my $first = 1;
	foreach $mashup_i (sort { $a <=> $b } keys %mashups) {
		foreach $mashup_j (sort { $a <=> $b } keys %mashups) {
			if ($first) {
				$first = 0;
			} else {
				print ", ";
			}
			print $dist{$mashup_i}->{$mashup_j};
		}
	}
	print " )\n";
	
	my $cols = "";
	foreach $mashup (sort { $a <=> $b } keys %mashups) {
		unless ($cols) {
			$cols = "'$mashupName{$mashup}'";
		} else {
			$cols .= ", '$mashupName{$mashup}'";
		}
	}
	print <<END;
M <- matrix(x, $size, $size)
rownames(M) <- colnames(M) <- c($cols)
END
}

# utility functions to print lists
sub printList {
	my @list = @_;
	my $s;
	foreach $item (@list) {
		unless ($s) {
			$s = "$item";
		} else {
			$s .= ", $item";
		}
	}
	print "c( $s )\n";
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