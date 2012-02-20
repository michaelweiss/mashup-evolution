#!/usr/bin/perl

my $N = 1;					# initial number of agents
my $n = 10;					# number of agents joining each step
my $mu = 0.6;				# innovation parameter
my $m = -1;					# number of previous steps (-1 is all)
my $t = 0;					# time step
my $T = 10;					# maximum time step
	
my %location;				# locations of agents
my $seed = time() + $$;		# time + process id

sub init {
	srand($seed);
	foreach $j (0..$N-1) {
		$location{$j} = $j;
	}
}

sub grow {
	$t = $N-1+$T;
}

sub show {
	foreach $j (0..$t) {
		print "$j, $location{$j}\n";
	}
}

init();
grow();
show();