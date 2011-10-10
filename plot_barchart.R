
# awk 'NR!=1 && NR!=152 {print $2,$4}' results_translation.txt > translation_barchart.txt

args <- commandArgs(T)
input_name <- args[1]
data <- read.table(input_name)
colnames(data) <- c("cluster","size")
ggplot(data, aes(cluster,size)) + geom_bar(stat="identity") + opts(title="Cluster sizes")
ggsave("output.png", width=8, height=6)