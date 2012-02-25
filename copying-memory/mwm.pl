#!/usr/bin/perl

my $DEBUG = 0;				# show debug messages

my $N = 1;					# initial number of agents
my $n = 1;					# number of agents joining each step
my $mu = 0.005;				# innovation parameter
my $m = 100;				# number of previous steps
my $t = 0;					# time step
my $T = (5028-$N)/$n;		# length of simulation in time steps
	
my $location;				# locations of agents
my $l = $N;					# next available new location

my $M0 = 4;					# initial number of apis (ensure that $M0 >= $M)
my $M = 2;					# number of apis per mashup
my $r = 0.4;				# ratio of apis to mashups

my @apis;					# apis
my $nextApi = 1;
my %apis;

my @memory;					# most $m*$n recent choices

my $seed = time() + $$;		# time + process id

# Read parameters from the command line
$N = $ARGV[0] if ($ARGV[0]);
$mu = $ARGV[1] if ($ARGV[1]);
$m = $ARGV[2] if ($ARGV[2]);
$n = $ARGV[3] if ($ARGV[3]);
$T = $ARGV[4] if ($ARGV[4]);

sub init {
	srand($seed);
	foreach (0..$M0-1) {
		generateApi();
	}
	foreach (0..$N-1) {
		my $mashup = generateMashup();
		addLocation($mashup);
		$location{$mashup}++;
	}
	foreach ($m*$n..$N-1) {
		shift @memory;
	}
}

sub grow {
	foreach $t ($N..$N+$T-1) {
		print "locations at t = $t\n" if ($DEBUG);
		show() if ($DEBUG);
		foreach (0..$n-1) {
			if (rand() < $r) {						# for each mashup generate $r apis on average
				generateApi();
			}
			my $template = selectLocation($t);		# location selected for copying
			my $mashup = copyFromMashup($template);
			addLocation($mashup);
			$location{$mashup}++;
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
	countApiUsage(@mashup);
	return hash(sort {$a <=> $b} @mashup);
}

sub copyFromMashup {
	my ($template) = @_;
	my @mashup;
	my @template = unhash($template);
	my @choices = assignCopiedComponents(\@mashup, \@template);
	assignRandomComponents(\@mashup, \@choices);
	countApiUsage(@mashup);
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

sub countApiUsage {
	my @mashup = @_;
	foreach my $k (@mashup) {
		$apis{$k}++;
	}
}

sub showApiUsage {
	my $first = 1;
	print "apis <- c(";
	foreach $k (sort { $b <=> $a } values %apis) {
		if ($k) {
			if ($first) {
				$first = 0;
			} else {
				print ",";
			}
			print "$k";
		}
	}
	print ")\n";
}

init();
grow();
# show();

showApiUsage();