library(ggplot2)

args <- commandArgs(T)
input_name <- args[1]
clusters <- read.table(paste(input_name,"cluster_file",sep="."))
centroids <- read.table(paste(input_name,"centroids",sep="."))

ggplot(clusters,aes(V1,V2)) + 
    geom_point(data=clusters, aes(V1,V2,col=V4,shape=V3+15,size=7)) + 
    geom_point(data=centroids, aes(V1,V2, col=V3),size=10) + 
    opts(legend.position="none")

ggsave(paste(input_name,".png",sep=""), width = 8, height = 8)


