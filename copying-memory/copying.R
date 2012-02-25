apis.actual <- read.table("apis-by-popularity.dat", header=TRUE, sep=",")
plot(apis.actual, log="xy", xlab="Rank", ylab="Number of mashups")

apis <- sort(apis, decreasing=T)
points(apis, pch=6, col="green")