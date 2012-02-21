ba <- read.table("bentley_1_6000_X_10_20000.csv", header=FALSE)
names(ba) <- c("location", "size")

ba.freq <- table(ba$size)
ba.freq.m <- as.matrix(ba.freq)

plot(ba.freq.m, log="xy", xlab="size", ylab="P(size)")

# plfit from http://tuvalu.santafe.edu/~aaronc/powerlaws
a <- plfit(ba.freq.m[,1])
lines(1:50, ba.freq.m[[1]]*(1:50)^(-a$alpha-1))

ba$bins <- cut(ba$size, breaks=c(1, 2, 4, 8, 16, 32, 64, 128, 256), include.lowest=TRUE)
bins <- tapply(ba$size, ba$bins, sum)

# plot(bins, log="y")
