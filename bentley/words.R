words <- read.table("words.csv", header=TRUE)
plot(abs ~ rank, data=words, log="xy", col="red", xlab="Rank", ylab="Size")

bentley.words <- read.table("bentley_1000_0004_4_450_8000.csv", header=FALSE)
names(bentley.words) <- c("location", "size")
top.1000 <- sort(bentley.words$size, decreasing=T)[1:1000]
points(top.1000)

alpha.words <- power.law.fit(words$abs)
# lines(1:100, words$abs[1]*(1:100)^(-coef(alpha.words)+1), col="red")

alpha.bentley.words <- power.law.fit(top.1000)
# lines(1:100, top.1000[1]*(1:100)^(-coef(alpha.bentley.words)+1), col="black")
