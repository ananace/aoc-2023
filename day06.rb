#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 6

class Implementation
  def initialize
    @races = []
  end

  def input(line)
    input = line.split.map(&:strip)
    unit = input.shift.downcase.delete(':').to_sym

    input.map(&:to_i).each.with_index do |val, i|
      @races[i] ||= {}
      @races[i][unit] = val
    end
  end

  def output
    part1 = @races.map do |race|
      dist = (0..race[:time]).map do |press_dur|
        press_dur * (race[:time] - press_dur)
      end

      puts "For #{race}: #{dist}" if $args.verbose
      dist.select { |distance| distance > race[:distance] }.size
    end.inject(:*)

    puts "Part 1:", part1

    full_race_time = @races.map { |r| r[:time].to_s }.join.to_i
    full_race_dist = @races.map { |r| r[:distance].to_s }.join.to_i

    potentials = (0..full_race_time).count do |press_dur|
      press_dur * (full_race_time - press_dur) > full_race_dist
    end

    puts "Part 2:", potentials
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
  impl.input line.strip
end

impl.output
