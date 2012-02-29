library(genalg)

# get this from the programmable web
apis.actual <- read.table("apis-by-popularity.dat", header=TRUE, sep=",")
number.mashups = 5028

# invoke the mwm.pl script from R
mwm <- function(N, mu, m, n, T=number.mashups, run=1) { 
	m <- round(m)
	n <- round(n)
	T <- round(T);
	out <- paste("mwm", N, round(1000*mu), m, n, T, run, sep="_")
	system(paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep="")))
	source(out)
}

# show parameters that will be passed to script
mwm.test <- function(N, mu, m, n, T=number.mashups) { 
	m <- round(m)
	n <- round(n)
	T <- round(T);
	out <- paste("mwm", N, round(1000*mu), m, n, T, sep="_")
	paste("perl mwm.pl", N, mu, m, n, T, paste(">", out, sep=""))
}

# compute distance between simulated and actual apis
# should also consider computing distance to mashup blueprint distribution
distance <- function(apis) {
	n <- min(length(apis.actual$popularity), length(apis))
	sum((apis[seq(n)] - apis.actual$popularity[seq(n)])^2)
}

# run experiment with m=all and n=1
experiment.all <- function() {
	rbga.results <- rbga(c(0.0), c(1.0), evalFunc=evaluate.all, mutationChance=0.01,
		popSize=10, iters=10)
	rbga.results
}

# run experiment with m between 1 and number.mashups and n=1
experiment.memory <- function() {
	rbga.results <- rbga(c(0.000, 1), c(0.250, 5), 
		evalFunc=evaluate.memory, mutationChance=0.01,
		popSize=200, iters=100)
	rbga.results
}

# can add vectors to initial population for genetic algorithm through suggestions param in rbga()
# use suggestions.pl to generate suggestions_X.R file

# source("suggestions_20.R")
# suggestions <- matrix(suggestions, nrow=20, byrow=T)

# run experiment with m and n between 1 and 100
experiment.memory.n <- function() {
	rbga.results <- rbga(c(0.150, 1, 1), c(0.250, 100, 100), 
		evalFunc=evaluate.memory.n, mutationChance=0.01,
		popSize=200, iters=100)
	rbga.results
}

# evaluation function used by experiment.all
evaluate.all <- function(string=c()) {
	mwm(1, string[1], number.mashups, 1, number.mashups)
	distance(apis)
}

# evaluation function used by experiment.memory
evaluate.memory <- function(string=c()) {
	n <- 1000
	if (string[2]*n > number.mashups) {
		Inf
	} else {
		runs <- 10
		dist <- sapply(seq(runs), function(run) {
			mwm(1, string[1], string[2], n, (number.mashups-1)/n, run)
			distance(apis)
		})
		mean.dist <- mean(dist)
		print(string)
		print(mean.dist)
		mean.dist
	}
}

# evaluation function used by experiment.memory.n
# did not have expected result so far: maybe landscape too rough
evaluate.memory.n <- function(string=c()) {
	print(string)
	if (string[2]*string[3] > number.mashups) {
		Inf
	} else {
		runs <- 100
		dist <- sapply(seq(runs), function(run) {
			mwm(1, string[1], string[2], string[3], (number.mashups-1)/string[3], run)
			distance(apis)
		})
		mean.dist <- mean(dist)
		print(mean.dist)
		mean.dist
	}
}

# try built-in optimization function
# did not have expected result so far: maybe landscape too rough
optimize.memory.n <- function() {
	optim(c(0.5, 10, 200), optimize.memory.n.evaluate, method = "SANN", control=c(maxit=100))
}

# evaluation function used by built-in optimization function
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

# c(1,2,3,4,5,6,7,8,9,10,20,30,40,50,60,70,80,90,100)

# create a 3d plot of simulation results
# axes are m, n, and the distance determined through simulation
# mu is fixed at .2, which is close to the optimal value

# first compute the z axis: each value is the average of 10 simulation runs
# combinations of m and n that are out of range result in z <- NA
experiment.3d <- function() {
	z = matrix(1:100, nrow=10, byrow=T) 
	i = 1
	for (m in 10 + 20 * (seq(10)-1)) {
		j = 1
		for (n in 10 + 20 * (seq(10)-1)) {
			if (m*n < number.mashups) {
				print(c(m, n))
				runs <- 10
				dist <- sapply(seq(runs), function(run) {
					mwm(1, 0.2, m, n, (number.mashups-1)/n, run)
					distance(apis)
				})
				z[i, j] <- mean(dist)
			} else {
				z[i, j] <- NA
			}
			j <- j+1
		}
		i <- i+1
	}
	z
}

# plot the simulation results using the persp() function
# the code to calculate color range is for surface3d
experiment.3d.plot <- function() {
	x <- -10 + 20 * (1:nrow(z))
	y <- -10 + 20 * (1:ncol(z))
#	zlim <- range(y)
#	zlen <- zlim[2] - zlim[1] + 1
#	colorlut <- rainbow(zlen)
#	col <- colorlut[ z-zlim[1]+1 ]
	open3d()
	persp(x, y, z, phi=15, theta=120)
}
