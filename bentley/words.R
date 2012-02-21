words <- read.table("words.csv", header=TRUE)
plot(abs ~ rank, data=words, log="xy", col="red")

bentley.words <- read.table("bentley_1000_0004_4_450_8000.csv", header=FALSE)
names(bentley.words) <- c("location", "size")

bentley.words.freq <- table(bentley.words$size)
bentley.words.freq.m <- as.matrix(bentley.words.freq)

plot(bentley.words.freq.m, log="xy", xlab="size", ylab="P(size)")