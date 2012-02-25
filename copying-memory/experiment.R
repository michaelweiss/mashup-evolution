# requires library genalg

mwm <- function(N, mu, m, n, T) { 
	out <- paste("mwm", N, round(1000*mu), m, n, T, sep="_")
	system(paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep="")))
	source(out)
}

mwm.test <- function(N, mu, m, n, T) { 
	out <- paste("mwm", N, round(1000*mu), m, n, T, sep="_")
	paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep=""))
}

distance <- function(apis) {
	n <- min(length(apis.actual$popularity), length(apis))
	sum((apis[seq(n)] - apis.actual$popularity[seq(n)])^2)
}

experimentBaseline <- function() {
	rbga.results <- rbga(c(0.0, 1.0), evalFunc(distance), mutationChance=0.01,
		popSize=10, iters=10)
}

evaluateBaseline <- function(string=c()) {
	mwm(1, string[1], 5028, 1, 5027)
	distance(apis)
}