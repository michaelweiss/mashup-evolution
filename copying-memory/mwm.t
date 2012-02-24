#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 1;					# number of agents joining each step
my $mu = 0.875;				# innovation parameter
my $m = 4;					# number of previous steps
my $t = 0;					# time step
my $T = 10;					# length of simulation in time steps
	
my %location;				# locations of agents
my $l = $N;					# next available new location (not needed, but confirm with test)

my $M0 = 2;					# initial number of apis
my $M = 2;					# number of apis per mashup (ie links created per mashup)
my $r = 0.4;				# ratio of apis to mashups

my @apis;					# apis
my $nextApi = 0;
		
my @memory;					# most $m*$n recent choices

sub setup {
	%location = [];			# generic
	@memory = ();
	@apis = ();				# mashup-specific
	$nextApi = 0;
}	

setup();
testGenerateApis();

setup();
testGenerateMashup();

setup();
testCreateInitialMashup();

setup();
testSelectLocation();

setup();
# testCopyFromMashup();

setup();
testPseudoRandomNumbers();

setup();
testAssignCopiedComponents();

sub testGenerateApis {
	generateApi() == 0 || die "expected api 0";
	generateApi() == 1 || die "expected api 1";
}

sub testCreateInitialMashup {
	my $mashup = hash(generateApi(), generateApi());
	addLocation($mashup);
	$location{$mashup} = 1;
	$memory[-1] eq "0/1" || die "memory expected to contain 0/1, found $memory[-1]";
	$location{"0/1"} == 1 || die "initial location expected to be 1";
}

sub testGenerateMashup {
	foreach (0..$M0-1) {
		generateApi();
	}
	my $mashup = generateMashup();
	$mashup eq "0/1" || die "mashup expected to be 0/1, found $mashup";
	my $anotherMashup = generateMashup();
	$anotherMashup eq "0/1" || die "mashup expected to be 0/1, found $anotherMashup";
}

sub testSelectLocation {
	my @mashups;
	foreach (0..$M0-1) {
		generateApi();
	}
	foreach $i (0..2) {
		$mashup[$i] = generateMashup();
		addLocation($mashup[$i]);
	}
	$mashup = selectLocation();
	$mashup eq $mashup[0] || $mashup eq $mashup[1] || $mashup eq $mashup[2] || 
		die "select did not return mashup from memory";
}

sub testCopyFromMashup {
	my $mashup = copyFromMashup("1/2");
	$mashup eq "1/2" || die "copying mashup, found $mashup";
}

sub testPseudoRandomNumbers {
	pseudo() == 0.1 || die "expected pseudo random 0.1";
	pseudo() == 0.8 || die "expected pseudo random 0.8";
	pseudo() == 0.2 || die "expected pseudo random 0.2";
	pseudo() == 0.5 || die "expected pseudo random 0.5";
	pseudo() == 0.3 || die "expected pseudo random 0.3";
	pseudo() == 0.7 || die "expected pseudo random 0.7";
	pseudo() == 0.4 || die "expected pseudo random 0.4";
	pseudo() == 0.9 || die "expected pseudo random 0.9";
	pseudo() == 0.0 || die "expected pseudo random 0.0";
	pseudo() == 0.6 || die "expected pseudo random 0.6";
	pseudo() == 0.1 || die "expected pseudo random 0.1";
}

sub testAssignCopiedComponents {
	my @mashup;
	my @template = unhash("0/1");
	$mu = 0.8;
	my @random = assignCopiedComponents(\@mashup, \@template);
	$random[0] == 1 || die "expected random[0] == 1, found $random[0]";
}

sub generateApi {
	push(@apis, $nextApi++);
	return $apis[-1];	
}

sub generateMashup {
	my @mashup;
	my %component; 
	foreach $i (0..$M-1) {
		do {
			$k = int(rand()*($#apis+1));
		} while ($component{$k});
		$component{$k} = 1;
		push(@mashup, $k);
	}
	return hash(sort @mashup);
}

sub copyFromMashup {
	my ($template) = @_;
	my @mashup;
	my @template = unhash($template);
	# assign copied components first to the copy, so that random components 
	# cannot duplicate copied components
	my @random;
	foreach $i (@template) {
		if (rand() < 1-$mu) {
			# with probability 1-$mu, the component is copied from the template
			$mashup[$i] = $template[$i];
		} else {
			# with probability $mu, the component is chosen at random, ie the
			# mashup creator innovates on the templates
			push(@random, $i);
		}
	}
	# assign random components next
	my %component; 
	foreach $i (@random) {
		do {
			$k = int(rand()*($#apis+1));
		} while ($component{$k});
		$component{$k} = 1;
		$mashup[$i] = $k;
	}
	return hash(sort @mashup);;
}

sub assignCopiedComponents {
	my ($mashup, $template) = @_;
	my @random;
	foreach $i (@{$template}) {
		if (pseudo() < 1-$mu) {
			# with probability 1-$mu, the component is copied from the template
			$mashup->[$i] = $template->[$i];
		} else {
			# with probability $mu, the component is chosen at random, ie the
			# mashup creator innovates on the templates
			push(@random, $i);
		}
	}	
	return @random
}

# pseudo random number sequence used by pseudo()
my @pseudo = (0.1, 0.8, 0.2, 0.5, 0.3, 0.7, 0.4, 0.9, 0.0, 0.6);
my $nextPseudo = 0;

# produce known "random" numbers to allow us to run tests
sub pseudo {
	my $r = $pseudo[$nextPseudo];
	$nextPseudo = ($nextPseudo+1) % 10;
	return $r;
}

sub assignRandomComponents {
	my ($mashup, $random) = @_;
	my %component; 
	foreach $i (@{$random}) {
		do {
			$k = int(rand()*($#apis+1));
		} while ($component{$k});
		$component{$k} = 1;
		$mashup->[$i] = $k;
	}	
}

sub hash {
	return join('/', @_);
}

sub unhash {
	return split('/', @_);
}

sub selectLocation {
	my ($t) = @_;
	print "memory at t = $t\n" if ($DEBUG);
	showMemory() if ($DEBUG);
	# pick a random number in the range 0..size(memory)
	# don't include locations chosen in the current time step
	my $r = int(rand()*min($#memory+1, $m*$n));
	return $memory[$r];
}

sub min {
	my ($x, $y) = @_;
	return $x if ($x < $y);
	return $y;
}

sub addLocation {
	my ($location) = @_;
	# implementation may be overly complex: should work, but it would
	# be easier to understand if we kept two lists
	push(@memory, $location);
	# memory contains two groups of locations:
	#   0..$m*$n-1 for choices at previous time steps
	#   $m*$n..$m*$n+$n-1 for choices at the current time step
	# when memory reaches $m*$n+$n-1 locations, all choices have been
	# made at the current time step, therefore:
	if ($#memory == $m*$n+$n-1) {		
		# shifting $n times at end of time step is like a watermark in a
		# buffering algorithm: all choices from the oldest time step
		# are removed in a single step and replaced by the choices from
		# the most recent time step
		foreach (0..$n-1) {
			shift @memory;
		}
	}
}

sub show {
	foreach $k (sort keys %location) {
		print "$k, $location{$k}\n";
	}
}

sub showMemory {
	# previous time steps
	foreach $j (0..$m*$n-1) {
		print "$j, $memory[$j]\n";
	}
	# current time step
	foreach $j ($m*$n..$m*$n+$n-1) {
		print "*$j, $memory[$j]\n";
	}	
}