#!/usr/bin/env ruby
# require "rubygems"
# require "ruby-debug"
require 'matrix'

# Plot
# Rscript plot_kmeans.R prueba50_k2

class Array
    def sum
      inject(0.0) { |result, el| result + el }
    end

    def mean 
      sum / size
    end
end

class DataPoint
    attr_accessor :cluster, :true_class, :coordinates
    
    def initialize(*args)
        @coordinates = args.shift
        @true_class = args.shift
    end

    # Calculate the N-dimensional (squared) euclidean distance between two data_points
    def distance2_to(data_point)
        [@coordinates,data_point.coordinates].transpose.map{|arr| arr.inject{|sum, coordinate| (sum - coordinate)**2}}.inject(:+)
    end

    def to_s
        "#{@coordinates.join("\t")}\t#{@true_class}\t#{@cluster}"
    end
end

class Cluster
    attr_accessor :name, :centroid, :data_points, :true_class
    @@name_counter = 0
    
    def initialize(centroid)
        @centroid = centroid
        @name = (Cluster.name_counter+=1)
        @data_points = []
    end

    def add(data_point)
        data_point.cluster = self
        @data_points << data_point
    end

    def calculate_centroid
        centroid_coordinates = @data_points.map(&:coordinates).transpose.map(&:mean)

        @centroid = DataPoint.new(centroid_coordinates, nil)
        puts "cluster #{@name} size #{@data_points.size} centroid #{@centroid}"
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
end

class Kmeans

    attr_accessor :clusters, :data_points

    def initialize(data_points_file,k)
        @data_points = Kmeans.parse(data_points_file)
        @k = k.to_i

        @clusters = generate_random_clusters
    end

    def self.parse(input_file)
        data_points = []
        File.open(input_file, "r") do |input_file|
            while line = input_file.gets
                columns = line.split("\t")
                # true_class = columns.pop.chomp
                coordinates = columns.map(&:to_f)
                data_points << DataPoint.new(coordinates,nil)
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

    def reset_cluster_data_points
        @clusters.each do |cluster|
            cluster.data_points = []
        end
    end

    # assign each observation to the centroid with the closest mean
    def assign_clusters
        reset_cluster_data_points
        @data_points.each do |data_point|
            closest_cluster = nil
            minimum_distance = nil
            @clusters.each do |cluster|
                distance_to_current_cluster = data_point.distance2_to(cluster.centroid)
                if minimum_distance.nil? || distance_to_current_cluster < minimum_distance
                    minimum_distance = distance_to_current_cluster
                    closest_cluster = cluster
                end
            end
            closest_cluster.add(data_point)
        end
    end

    def calculate_centroids
        @clusters.each do |cluster|
            cluster.calculate_centroid
        end
    end
end

if ARGV.size != 2
    puts "USAGE: ./kmeans.rb input_file K"
else
    srand(999)
    data_points_file, k = ARGV
    kmeans = Kmeans.new(data_points_file,k)

    iteration = 0
    delta = 0.001
    improvement = 1
    old_centroids = Matrix
    new_centroids = Matrix
    while improvement > delta
        iteration += 1
        puts "Running iteration #{iteration}"
        
        kmeans.assign_clusters

        old_centroids = Matrix.rows(kmeans.clusters.map{|c| c.centroid.coordinates })
        kmeans.calculate_centroids
        new_centroids = Matrix.rows(kmeans.clusters.map{|c| c.centroid.coordinates})

        improvement = (old_centroids - new_centroids).to_a.flatten.max
        puts "improvement #{improvement}"
    end 

    cluster_file = "#{data_points_file}_k#{k}.cluster_file"
    File.open(cluster_file, 'w') do |f|  
          f.puts kmeans.data_points
    end
    puts "\n\nClusters saved to #{cluster_file}"  
    
    centroid_file = "#{data_points_file}_k#{k}.centroids"
    File.open(centroid_file, 'w') do |f|  
         kmeans.clusters.each do |cluster|
            f.puts "#{cluster.centroid} #{cluster}"
         end 
    end
    puts "\n\nCentroids saved to #{centroid_file}"  
end

