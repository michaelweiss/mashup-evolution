#!/usr/bin/perl

my $DEBUG = 1;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 3;					# number of agents joining each step
my $mu = 0.6;				# innovation parameter
my $m = 1;					# number of previous steps (-1 is all)
my $t = 0;					# time step
my $T = 5;					 # length of simulation in time steps
	
my @location;				# locations of agents
my $l = $N;					# next available new location

my @memory;					# most $m*$n recent choices

my $seed = time() + $$;		# time + process id

sub init {
	srand($seed);
	foreach $j (0..$N-1) {
		addLocation($j);
		$location[$j] = 1;
	}
}

sub grow {
	foreach $t ($N..$N+$T-1) {
		print "locations at t = $t\n" if ($DEBUG);
		show() if ($DEBUG);
		foreach $i (0..$n-1) {
			if (rand() > $mu) {
				# with probability of 1-$mu
				# the agent copies his location from another agent within the previous m=all steps
				my $k;		# location selected for copying
				$k = selectLocation($t);
				addLocation($k);
				print "k = $k\n" if ($DEBUG);
				$location[$k]++;
			} else {
				# with probability $mu
				# the agent innovates by choosing a new location at random		
				addLocation($l);
				print "k = $l (innovation)\n" if ($DEBUG);
				$location[$l++] = 1;
			}
		}
	}
	# $t = $N-1+$T;
}

sub selectLocation {
	my ($t) = @_;
	# initial implementation of memory
	# select a choice at random
	# this implementation makes an incorrect simplificiation:
	# should only select location from the $m previous time steps
	print "memory at t = $t\n" if ($DEBUG);
	showMemory() if ($DEBUG);
	my $r = int(rand()*$#memory);
	return $memory[$r];
}

sub addLocation {
	my ($location) = @_;
	# initial implementation of memory
	# add new location to the end of the memory
	# remove oldest location from the front
	# this implementation makes an incorrect simplificiation:
	# locations should only be copied from the $m previous time steps
	# so should only remove old locations at end of time step
	push(@memory, $location);
	if ($#memory == $m*$n) {	# $m*$n is one more than allowed
		shift @memory;
	}
}

sub show {
	foreach $j (0..$l-1) {
		print "$j, $location[$j]\n";
	}
}

sub showMemory {
	foreach $j (0..$m*$n-1) {
		print "$j, $memory[$j]\n";
	}
}

init();
grow();
show();

1;