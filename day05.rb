#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 5

DualRange = Struct.new('DualRange', :source, :destination) do
  def include?(value)
    source.include? value
  end

  def map(value)
    return value unless source.include? value

    offset = value - source.first
    destination.first + offset
  end

  def rev_map(value)
    return value unless destination.include? value
    
    offset = value - destination.first
    source.first + offset
  end
end

SeedMap = Struct.new('SeedMap', :source, :destination, :ranges) do
  def map(value)
    range = ranges.find { |range| range.include?(value) }
    return value unless range

    range.map(value)
  end

  def rev_map(value)
    range = ranges.find { |range| range.destination.include?(value) }
    return value unless range

    range.rev_map(value)
  end
end

class Implementation
  def initialize
    @seeds = []
    @maps = []
    @curmap = nil
  end

  def input(line)
    if line.start_with? 'seeds:'
      @seeds = line.split(':').last.split.map(&:to_i)
    elsif line.include? 'map:'
      from, to = line.split.first.split('-to-').map(&:to_sym)
      map = @maps.find { |map| map.source == from && map.destination == to }
      unless map
        map = SeedMap.new(from, to, [])
        @maps << map
      end
      @curmap = map
    else
      dest_start, source_start, length = line.split.map(&:to_i)
      @curmap.ranges << DualRange.new((source_start..(source_start+length-1)), (dest_start..(dest_start+length-1)))
    end
  end

  def output
    puts "Part 1: ", @seeds.map { |seed| fully_map(seed) }.min
    seed_ranges = []
    @seeds.each_slice(2) { |from, len| seed_ranges << (from..(from+len-1)) }
    puts "Seed ranges: #{seed_ranges}" if $args.verbose

    lowest = nil
    last_out = Time.now
    (1..).each do |loc_test|
      fully_rev_mapped = fully_rev_map(loc_test)
      if Time.now - last_out > 5
        puts "Currently testing #{loc_test}"
        last_out = Time.now
      end
      next unless seed_ranges.any? { |r| r.include? fully_rev_mapped }

      lowest = loc_test
      break
    end
    puts "Part 2: ", lowest
  end

  def fully_map(value, from: :seed, to: :location)
    return value if from == to

    map = @maps.find { |map| map.source == from }
    raise "Failed to find a map from #{from}" unless map

    new_value = map.map(value)
    puts "Mapped #{from}[#{value}] to #{map.destination}[#{new_value}]" if $args.verbose
    fully_map(new_value, from: map.destination)
  end

  def fully_rev_map(value, from: :location, to: :seed)
    return value if from == to

    map = @maps.find { |map| map.destination == from }
    raise "Failed to find a map from #{from}" unless map

    new_value = map.rev_map(value)
    puts "Mapped #{from}[#{value}] to #{map.source}[#{new_value}]" if $args.verbose
    fully_rev_map(new_value, from: map.source)
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

  impl.input line.strip
end

impl.output
