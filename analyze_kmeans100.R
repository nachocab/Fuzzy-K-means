args <- commandArgs(T)
input <- args[1]

repetitions <- read.table(input)
std_dev <- sd(repetitions[[length(repetitions)]])
average <- mean(repetitions[[length(repetitions)]])
min_value <- min(repetitions[[length(repetitions)]])

print(c("average",average,"sd",std_dev,"min",min_value))


