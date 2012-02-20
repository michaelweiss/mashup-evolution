#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 1;					# number of agents joining each step
my $mu = 0.5;				# innovation parameter
my $m = -1;					# number of previous steps (-1 is all)
my $t = 0;					# time step
my $T = 5;					# maximum time step
	
my @location;				# locations of agents
my $l = $N;					# next available new location

my $seed = time() + $$;		# time + process id

sub init {
	srand($seed);
	foreach $j (0..$N-1) {
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
				print "k = $k\n" if ($DEBUG);
				$location[$k]++;
			} else {
				# with probability $mu
				# the agent innovates by choosing a new location at random		
				print "k = $l (innovation)\n" if ($DEBUG);
				$location[$l++] = 1;
			}
		}
	}
	# $t = $N-1+$T;
}

sub selectLocation {
	my ($t, $i) = @_;
	my $r = int(rand()*($t*$n));
	print "r = $r\n" if ($DEBUG);
	my $k = findLocationInterval($r);
	return $k;
}

sub findLocationInterval {
	my ($r) = @_;
	my $s = 0;
	foreach $j (0..$l-1) {
		$s += $location[$j];
		if ($r < $s) {
			return $j;
		}
	}
	die "did not find a location";
}

sub show {
	foreach $j (0..$l-1) {
		print "$j, $location[$j]\n";
	}
}

init();
grow();
show();

1;