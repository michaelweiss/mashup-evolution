#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 1;					# number of agents joining each step
my $mu = 0.5;				# innovation parameter
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
testHash();

setup();
testAssignCopiedComponents();

setup();
testAssignRandomComponents();

setup();
testCopyFromMashup();

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
	foreach (0..5) {
		generateApi();
	}
	my @mashup = copyFromMashup("0/1/2");
	print "copy from mashup = ", hash(@mashup), "\n";
}

sub testHash {
	my @mashup = (0, 2);
	my $mashup = hash(@mashup);
	$mashup eq "0/2" || die "hash expected 0/2, found $mashup";	
	my @template = unhash($mashup);
	$template[0] == 0 || die "templatep[0] == 0, found $template[0]";
	$template[1] == 2 || die "templatep[1] == 2, found $template[2]";
}

sub testAssignCopiedComponents {
	my @mashup;
	my @template = unhash("0/2/5");
	my @choices = assignCopiedComponents(\@mashup, \@template);
	print "choices = ", hash(@choices), "\n";
}

sub testAssignRandomComponents {
	foreach (0..9) {
		generateApi();
	}
	my @mashup = (0, 1, 2);
	my @choices = (1, 0, 1);
	assignRandomComponents(\@mashup, \@choices);
	print "copy = ", hash(@mashup), "\n";
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
	return hash(sort {$a <=> $b} @mashup);
}

sub copyFromMashup {
	my ($template) = @_;
	my @mashup;
	my @template = unhash($template);
	my @choices = assignCopiedComponents(\@mashup, \@template);
	assignRandomComponents(\@mashup, \@choices);
	return hash(sort {$a <=> $b} @mashup);;
}

sub assignCopiedComponents {
	my ($mashup, $template) = @_;
	my @choices;				# vector of innovations (0: copy, 1: innovate)
	my $i = 0;
	foreach $k (@{$template}) {
		if (rand() < 1-$mu) {
			# with probability 1-$mu, the component is copied from the template
			$mashup->[$i] = $k;
			push(@choices, 0);	# copy
		} else {
			# with probability $mu, the component is chosen at random, ie the
			# mashup creator innovates on the templates
			push(@choices, 1);	# innovate
		}
		$i++;
	}	
	return @choices;
}

sub assignRandomComponents {
	my ($mashup, $choices) = @_;
	my %component; 
	# mark copied components so that random components 
	# cannot duplicate copied components
	my $i = 0;
	foreach $choice (@{$choices}) {
		if ($choice == 0) {		# copy
			$component{$mashup->[$i]} = 1;
		}
		$i++;
	}
	my $i = 0;	
	foreach $choice (@{$choices}) {
		if ($choice == 1) {		# innovate
			do {
				$k = int(rand()*($#apis+1));
			} while ($component{$k});
			$component{$k} = 1;
			$mashup->[$i] = $k;
		}
		$i++;
	}	
}

sub hash {
	return join('/', @_);
}

sub unhash {
	my ($hash) = @_;
	return split('/', $hash);
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