#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 1;					# number of agents joining each step
my $mu = 0.875;				# innovation parameter
my $m = 4;					# number of previous steps
my $t = 0;					# time step
my $T = 10;					# length of simulation in time steps
	
my @location;				# locations of agents
my $l = $N;					# next available new location

my $M0 = 2;					# initial number of apis
my $M = 2;					# number of apis per mashup (ie links created per mashup)

my @apis;					# apis
my $nextApi = 1;

my @memory;					# most $m*$n recent choices

my $seed = time() + $$;		# time + process id

sub init {
	srand($seed);
	foreach $i (0..$M0-1) {
		generateApi();
	}
	foreach $i (0..$N-1) {
		my $mashup = generateMashup();
		addLocation($mashup);
		$location{$mashup}++;
	}
	foreach ($m*$n..$N-1) {
		shift @memory;
	}
}

sub grow {
}

sub show {
	foreach $k (keys %location) {
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

sub hash {
	return join('/', @_);
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

init();
grow();

print "Locations:\n";
show();

print "Memory:\n";
showMemory();