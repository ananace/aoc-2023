#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 8

Graph = Struct.new('Graph', :nodes) do
  def traverse(from, to, map)
    count_steps(from, map) { |node| node == to }
  end

  def traverse_parallel(map)
    nodes.keys
      .select { |n| n.end_with? 'A' }
      .map { |n| count_steps(n, map) { |at| at.end_with? 'Z' } }
      .inject(1, &:lcm)
  end

  private

  def count_steps(from, map)
    steps = 0
    at = from
    traverse = map.chars
    puts "At #{at}" if $args.verbose

    until yield(at)
      step = traverse.shift
      traverse.push step
      steps += 1

      node = nodes[at]
      new = step == 'L' ? node[0] : node[1]
      puts "Moving #{at} #{step} to #{new} (#{steps})" if $args.verbose
      at = new
    end

    steps
  end
end

class Implementation
  def initialize
    @graph = Graph.new({})
    @map = nil
  end

  def input(line)
    if @map
      node, paths = line.split('=').map(&:strip)
      paths = paths.delete('()').split(',').map(&:strip)
      @graph.nodes[node] = paths
    else
      @map = line
    end
  end

  def output
    puts @graph if $args.verbose
    
    puts "Part 1:", @graph.traverse('AAA','ZZZ', @map) if @graph.nodes.keys.include? 'AAA'
    puts "Part 2:", @graph.traverse_parallel(@map)
  end
end

impl = Implementation.new

#
# Boilerplate input handling
#

require 'optparse'

OptionParser.new do |parser|
  parser.banner = "Usage: #{$0} [args...]"

  parser.on '-s', '--sample', 'Use sample data even if real data is available' do
    $args.sample = true
  end

  parser.on '-v', '--verbose', 'Run more verbosely' do
    $args.verbose = true
    $log.level = [$log.level - 1, 0].max
  end

  parser.on '-h', '--help', 'Shows this help' do
    puts parser
    exit
  end
end.parse!

datafiles = %w[inp.real inp inp.sample]
datafiles.unshift datafiles.pop if $args.sample
datafile = datafiles.map { |ext| format("day%<day>02i.%<ext>s", day: DAY, ext: ext) }.find { |file| File.exist? file }
raise "No input data for day #{DAY}" unless datafile
$log.debug "Using input data from #{datafile}"

#
# Actual input/output action
#

open(datafile).each_line do |line|
  next if line.strip.empty?
  next if line.start_with? '#'

  impl.input line.strip
end

impl.output
