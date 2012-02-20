#!/usr/bin/perl
# Model to generate a network by copying (multiple links)

my $N = 6;		# number of timesteps
# my $N = 2500;
my $m_0 = 4;		# initial number of apis
my $m = 4;			# number of apis per mashup (ie links created per mashup)
my $r = 0.4;		# ratio of apis to mashups
my $p = $r/(1+$r);	# proportion of apis
my $alpha = 0.875;	# ratio of copied apis when copying a mashup

my $plot = 0;

my %graph;
my %apis;

# Read parameters from the command line
$m = shift @ARGV;
if ($m_0 < $m) { $m_0 = $m }

$alpha = (shift @ARGV)/1000;

my $seed = time() + $$;		# time + process id

initializeGraph($m, $m_0);
growGraph($m_0, $N, $m);
printGraph();

# Add one mashup and $m new links to apis
# No preferential attachment here as no edges exist
sub initializeGraph {
	my ($m, $m_0) = @_;
	%graph = %apis = ();
	srand($seed);
	foreach $j (0..$m_0-1) {
#		print "> timestep: ", $j, "\n";
#		print "create api: ", $j, "\n";
		$apis{$j} = 1;
	}
#	print "> timestep: ", $m_0, "\n";
#	print "create new mashup\n";
	foreach $i (1..$m) {
		do {
			$j = int($m_0*rand());
		} while ($graph{$m_0}{$j});
		$graph{$m_0}{$j} = 1;	
#		print "create $m_0--$j\n";
	}
}

# Grow graph by randomly copying an existing mashup
sub growGraph {
	my ($m_0, $N, $m) = @_;
	my %degree;
	my $t, $i, $j;	
	foreach $t ($m_0+1..$N) {
#		print "> timestep: $t\n";
		if (rand() < $p) {
#			print "create api: $t\n";
			$apis{$t} = 1;
		} else {
			my $selnode;
			# choose an existing mashup in 0..$t-1 uniformly at random
			do {
				$selnode = int($t*rand());
			} until (!$apis{$selnode});
			# for each link decide whether to copy or select a random api
			my @links = sort keys %{$graph{$selnode}};
#			print "copy mashup $selnode: @links\n";
			my @random;
			foreach $i (1..$m) {
				# assign copied links first to avoid the scenario where a
				# random link in slot $i < $j is the same as a copy in slot $j
				if (rand() < $alpha) {
					$graph{$t}{$links[$i-1]} = 1;
#					print "create $t--$links[$i-1] (copy)\n";
				} else {
					push @random, $i;
				}
			}
			foreach $i (@random) {
				# choose $m apis in 0..$t-1 uniformly at random
				# make sure the apis are unique
				do {
					$j = int($t*rand());
				} until ($apis{$j} && !$graph{$t}{$j});
				$graph{$t}{$j} = 1;
#				print "create $t--$j (random)\n";
			}
		}
	}
}

sub printGraph {
	my $i, $j;
	my $first = 1;
	my $n = $N+1;
	print "g <- graph(n=$n, c( ";
	foreach $i (sort { $a <=> $b } keys %graph) {
		foreach $j (keys %{$graph{$i}}) {
			if ($first) {
				$first = 0;
			} else {
				print ", ";
			}
			print "$i, $j";
		}
	}
	print " ))\n";
	
	my @mashups = mashups();
	my @apis = apis();
		
	print <<END;
V(g)\$size <- log(1+degree(g))+1
V(g)\$shape <- "circle"
V(g)\$color <- "green"
END
	
	print "V(g)[";
	showVector(@mashups);
	print "]\$shape <- \"square\"\n";
	
	print "V(g)[";
	showVector(@mashups);
	print "]\$color <- \"red\"\n";

	if ($plot) {
		if ($N <= 1) {
			print <<END
	plot(as.undirected(g), layout=layout.fruchterman.reingold, vertex.label=V(g)$label)
END
		} else {
			print <<END
	plot(as.undirected(g), layout=layout.fruchterman.reingold, vertex.label="")
END
		}
	}
	
	print "mashups <- ";
	showVector(@mashups);
	print "\n";

	print "apis <- ";
	showVector(@apis);
	print "\n";
}

sub printApis {
	print "apis <- ";
	showVector(@_);
	print "\n";
}

sub apis {
	return sort { $a <=> $b } keys %apis;
}

sub mashups {
	my @mashups;
	foreach $i (sort { $a <=> $b } keys %graph) {
		unless ($apis{$i}) {
			push @mashups, $i;
		}
	}
	return @mashups;
}

sub showVector {
	print "c(";
	my $first = 1;
	foreach $i (@_) {
		unless ($first) {
			print ", $i";
		} else {
			print "$i";
			$first = 0;
		}
	}
	print ")";
}

