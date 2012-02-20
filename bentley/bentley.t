#!/usr/bin/perl

my $N = 1;
my $l = $N;

my @location;

sub testFindLocationOneInterval {
	$location[0] = 5;
	my $k = findLocationInterval(2);
	$k == 0 || die "expected 0, but got $k";
}

sub testFindLocationTwoIntervals {
	$location[0] = 5;
	$location[1] = 2;
	$l = 2;
	my $k = findLocationInterval(6);
	$k == 1 || die "expected 1, but got $k";
}

sub testFindLocationIntervalBoundary {
	$location[0] = 5;
	$location[1] = 2;
	$l = 2;
	my $k1 = findLocationInterval(4);
	$k1 == 0 || die "expected 0, but got $k1";
	my $k2 = findLocationInterval(5);
	$k2 == 1 || die "expected 1, but got $k2";
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

testFindLocationOneInterval();
testFindLocationTwoIntervals();
testFindLocationIntervalBoundary();