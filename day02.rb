#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 2

class Implementation
  def initialize
    @shown = []
  end

  def input(line)
    $log.debug "Handling #{line}"
    id, cubes = line.split(':').map(&:strip)
    id = id.split.last.to_i

    cubes = cubes.split(';').map(&:strip)

    game = {
      id: id,
      draws: []
    }

    cubes.each do |draw|
      game[:draws] << draw.split(',').map(&:strip).to_h do |cubes|
        data = cubes.split
        [data.last.to_sym, data.first.to_i]
      end
    end

    @shown << game
  end

  def part1(**counts)
    valid = @shown.reject do |game|
      counts.any? do |type, count|
        game[:draws].find { |draw| draw.fetch(type, 0) > count }
      end
    end

    puts "Part 1:"
    puts valid.sum { |game| game[:id] }
  end

  def part2
    res = @shown.sum do |game|
      minimum = { red: 0, green: 0, blue: 0 }
      game[:draws].each do |draw|
        %i[red green blue].each { |col| minimum[col] = draw[col] if draw[col] && draw[col] > minimum[col] }
      end

      $log.debug "Minimum for #{game} is #{minimum}"

      minimum.values.inject(:*)
    end

    puts "Part 2:"
    puts res
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

impl.part1(red: 12, green: 13, blue: 14)
impl.part2
