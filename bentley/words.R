words <- read.table("words.csv", header=TRUE)
plot(abs ~ rank, data=words, log="xy", col="red")