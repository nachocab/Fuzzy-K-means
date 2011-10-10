#!/usr/bin/env ruby
# require "rubygems"
# require "ruby-debug"
require 'matrix'

# Analyze
# Rscript analyze_kmeans100.R 100kmeans.txt 

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
        "#{@coordinates.join(" ")}\t#{@cluster}\t#{@true_class}"
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

    def score
        @data_points.inject(0.0){|score,data_point| score + data_point.distance2_to(@centroid) }
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
    puts "USAGE: ./kmeans100.rb input_file K"
else
    data_points_file, k = ARGV

    f = File.new("100kmeans.txt","w")

    100.times do |repetition|
        kmeans = Kmeans.new(data_points_file,k)
        
        iteration = 0
        delta = 0.001
        improvement = 1
        old_centroids = Matrix
        new_centroids = Matrix
        puts "Running repetition #{repetition}"
        while improvement > delta
            iteration += 1
            
            kmeans.assign_clusters

            old_centroids = Matrix.rows(kmeans.clusters.map{|c| c.centroid.coordinates })
            kmeans.calculate_centroids
            new_centroids = Matrix.rows(kmeans.clusters.map{|c| c.centroid.coordinates})

            improvement = (old_centroids - new_centroids).to_a.flatten.max

        end 

        f.print "#{repetition} "
        kmeans.clusters.each do |cluster|
            f.print "#{cluster.centroid} "
        end 
        mu = kmeans.clusters.inject(0.0){|mu,cluster| mu + cluster.score }
        f.print "#{mu} "
        f.print "\n"
        Cluster.name_counter = 0
    end
    f.close
end

