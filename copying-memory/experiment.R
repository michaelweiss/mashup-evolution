library(genalg)

apis.actual <- read.table("apis-by-popularity.dat", header=TRUE, sep=",")
number.mashups = 5028

mwm <- function(N, mu, m, n, T=number.mashups, run=1) { 
	m <- round(m)
	n <- round(n)
	T <- round(T);
	out <- paste("mwm", N, round(1000*mu), m, n, T, run, sep="_")
	system(paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep="")))
	source(out)
}

mwm.test <- function(N, mu, m, n, T=number.mashups) { 
	m <- round(m)
	n <- round(n)
	T <- round(T);
	out <- paste("mwm", N, round(1000*mu), m, n, T, sep="_")
	paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep=""))
}

distance <- function(apis) {
	n <- min(length(apis.actual$popularity), length(apis))
	sum((apis[seq(n)] - apis.actual$popularity[seq(n)])^2)
}

experiment.all <- function() {
	rbga.results <- rbga(c(0.0), c(1.0), evalFunc=evaluate.all, mutationChance=0.01,
		popSize=10, iters=10)
	rbga.results
}

experiment.memory <- function() {
	rbga.results <- rbga(c(0.0, 1), c(1.0, number.mashups), 
		evalFunc=evaluate.memory, mutationChance=0.01,
		popSize=100, iters=50)
	rbga.results
}

# source("suggestions_20.R")
# suggestions <- matrix(suggestions, nrow=20, byrow=T)

experiment.memory.n <- function() {
	rbga.results <- rbga(c(0.150, 1, 1), c(0.250, 100, 100), 
#		suggestions = suggestions,
		evalFunc=evaluate.memory.n, mutationChance=0.10,
		popSize=200, iters=10)
	rbga.results
}

evaluate.all <- function(string=c()) {
	mwm(1, string[1], number.mashups, 1, number.mashups)
	distance(apis)
}

evaluate.memory <- function(string=c()) {
	mwm(1, string[1], string[2], 1, number.mashups)
	distance(apis)
}

evaluate.memory.n <- function(string=c()) {
	if (string[2]*string[3] > number.mashups) {
		10000000
	} else {
		runs <- 10
		dist <- sapply(seq(runs), function(run) {
			mwm(1, string[1], string[2], string[3], (number.mashups-1)/string[3], run)
			distance(apis)
		})
		mean(dist)
	}
}

optimize.memory.n.evaluate <- function(x) {
	print(x)
	if (x[1] < 0 | x[1] > 1 |
		x[2] < 0 | x[2] > number.mashups |
		x[3] < 0 | x[3] > number.mashups |
		x[2]*x[3] > number.mashups) {
		NA
	} else {
		runs <- 10
		dist <- sapply(seq(runs), function(run) {
			mwm(1, x[1], x[2], x[3], (number.mashups-1)/x[3], run)
			distance(apis)
		})
		mean(dist)
	}
}

optimize.memory.n <- function() {
	optim(c(0.5, 10, 200), optimize.memory.n.evaluate, method = "SANN", control=c(maxit=100))
}
