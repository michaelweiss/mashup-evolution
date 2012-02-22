#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1000;				# initial number of agents
my $n = 450;				# number of agents joining each step
my $mu = 0.004;				# innovation parameter
my $m = 4;					# number of previous steps
my $t = 0;					# time step
my $T = 8000;				# length of simulation in time steps
	
my @location;				# locations of agents
my $l = $N;					# next available new location

my @memory;					# most $m*$n recent choices

my $seed = time() + $$;		# time + process id

sub init {
	srand($seed);
	# need to better understand circumstances when $N > $m*$n
	# in the current simulation such choices can never be copied
	foreach $j (0..$N-1) {
		addLocation($j);
		$location[$j] = 1;
	}
	foreach ($m*$n..$N-1) {
		shift @memory;
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
	foreach $j (0..$l-1) {
		print "$j, $location[$j]\n";
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

init();
grow();
show();