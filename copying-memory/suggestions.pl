#!/usr/bin/perl

my $T = 5028;				# length of simulation in time steps
my $N = shift @ARGV;

sub suggestions {
	my $first = 1;
	my $M = int($T/$N);
	print "suggestions <- c(";
	foreach $_m (1..$N) {
		$_m *= $M;
		my $_mu = int(1000*rand())/1000;
		my $_n = int($T/$_m);
			if ($first) {
				$first = 0;
			} else {
				print ",";
			}
		print "$_mu,$_m,$_n";
	}
	print ")\n";
}

suggestions();