#!/usr/bin/env ruby
# require "rubygems"
# require "ruby-debug"

require 'matrix'

# Plot
# Rscript plot_fuzzy_kmeans.R fuzzy_prueba50.k2


class DataPoint
    attr_accessor :coordinates, :memberships, :true_class

     def initialize(*args)
        @coordinates = args.shift
        @true_class = args.shift
        @memberships = {}
    end

    def to_s
        "#{@coordinates.join(" ")}\t#{@true_class}\t{ #{print_memberships}}"
    end

    def print_memberships
        str = ""
        @memberships.each_pair do |k,v|
            str += "#{k} => #{@memberships[k]} "
        end
        str
    end

    # Calculate the N-dimensional euclidean distance (squared) between two points
    def distance2_to(data_point)
        [@coordinates,data_point.coordinates].transpose.map{|arr| arr.inject{|sum, coordinate| (sum - coordinate)**2}}.inject(:+)
    end

    def calculate_membership(clusters,fuzzifier)
        distances_to_clusters = {}
        clusters.each do |cluster|
            distances_to_clusters[cluster.name] = distance2_to(cluster.centroid)
        end

        if distances_to_clusters.has_value?(0)
            distances_to_clusters.each do |cluster,distance|
                @memberships[cluster] = distance == 0 ? 1 : 0
            end
        else
            distances_to_clusters.each do |cluster_i_name, distance_to_i|
                membership_value = 0
                distances_to_clusters.each do |cluster_j_name, distance_to_j|
                    membership_value += (distance_to_i/distance_to_j)**(1/fuzzifier)
                end
                @memberships[cluster_i_name] = 1/membership_value
            end
        end
    end

    def membership(cluster_name)
        @memberships[cluster_name]
    end
end

class Cluster
    attr_accessor :centroid, :name
    @@name_counter = 0

    def initialize(centroid)
        @centroid = centroid
        @name = (Cluster.name_counter+=1)
    end

    def self.name_counter
        @@name_counter
    end

    def self.name_counter=(value)
        @@name_counter = value
    end

    def to_s
        "#{@name}"
    end

    def calculate_centroid(data_points)
        memberships = Matrix.row_vector(data_points.map{|dp| dp.membership(@name)})
        coordinates = Matrix[*data_points.map(&:coordinates)]
        sum_memberships = memberships.row(0).to_a.inject(:+)

        @centroid = DataPoint.new( ((memberships*coordinates)/sum_memberships).row(0).to_a, nil)
        puts "cluster #{@name} centroid #{@centroid}"
    end
end

class FuzzyKmeans
    attr_accessor :data_points, :clusters

    def initialize(data_points_file, k, fuzzifier=2)
        @data_points = FuzzyKmeans.parse(data_points_file)
        @k = k.to_i
        @fuzzifier = fuzzifier.to_i - 1

        @clusters = generate_random_clusters
    end

    def self.parse(input_file)
        data_points = []
        File.open(input_file, "r") do |input_file|
            while line = input_file.gets
                columns = line.split("\t")
                true_class = columns.pop.chomp
                coordinates = columns.map(&:to_f)
                data_points << DataPoint.new(coordinates,true_class)
            end
        end
        data_points
    end

    def generate_random_clusters
        clusters = []
        @data_points.sort_by{rand}[1..@k].each do |random_data_point|
            clusters << Cluster.new(random_data_point)
        end
        clusters
    end

    def calculate_centroids
        @clusters.each do |cluster|
            cluster.calculate_centroid(@data_points)
        end
    end

    def calculate_memberships
        @data_points.each do |point|
            point.calculate_membership(@clusters, @fuzzifier)
        end
    end

end

if ARGV.size != 2
    puts "USAGE: ./fuzzy_kmeans.rb input_file K"
else
    srand(999)
    data_points_file, k = ARGV
    fuzzifier = 2
    fuzzy_kmeans = FuzzyKmeans.new(data_points_file,k,fuzzifier)

    iteration = 0
    delta = 0.001
    improvement = 1
    old_centroids = Matrix
    new_centroids = Matrix
    while improvement > delta
        iteration += 1
        puts "Running iteration #{iteration}"
        
        fuzzy_kmeans.calculate_memberships

        old_centroids = Matrix.rows(fuzzy_kmeans.clusters.map{|c| c.centroid.coordinates })
        fuzzy_kmeans.calculate_centroids
        new_centroids = Matrix.rows(fuzzy_kmeans.clusters.map{|c| c.centroid.coordinates})

        improvement = (old_centroids - new_centroids).to_a.flatten.max
        puts "improvement #{improvement}"
    end

    cluster_file = "fuzzy_#{data_points_file}.k#{k}.cluster_file"
    File.open(cluster_file, 'w') do |f|  
          f.puts fuzzy_kmeans.data_points
    end
    puts "\n\nClusters saved to #{cluster_file}"  
    
    centroid_file = "fuzzy_#{data_points_file}.k#{k}.centroids"
    File.open(centroid_file, 'w') do |f|  
         fuzzy_kmeans.clusters.each do |cluster|
            f.puts "#{cluster.centroid} #{cluster}"
         end 
    end
    puts "\n\nCentroids saved to #{centroid_file}"  
end
