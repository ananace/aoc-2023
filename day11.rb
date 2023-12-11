#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

Point = Struct.new('Point', :x, :y) do
  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def sum
    x + y
  end
end

DAY = 11

class Implementation
  def initialize
    @galaxies = []
    @empty = { x: [], y: [] }
    @dim = Point.new 0, 0
  end

  def input(line)
    @dim.x = line.size
    @dim.y += 1

    line.each_char.with_index { |c, x| @galaxies << Point.new(x, @dim.y - 1) if c == '#' }
  end

  def calc
    @empty[:x] = (0..(@dim.x - 1)).reject { |x| @galaxies.any? { |g| g.x == x } }
    @empty[:y] = (0..(@dim.y - 1)).reject { |y| @galaxies.any? { |g| g.y == y } }
  end

  def output
    puts "Galaxies: #{@galaxies}" if $args.verbose
    puts "Empty: #{@empty}" if $args.verbose

    puts "Part 1:", get_paths(expansion: 2)
    puts "Part 2:", get_paths(expansion: 1000000)
  end

  def get_paths(expansion: 2)
    @galaxies.combination(2).sum do |g_a, g_b|
      g_min = Point.new [g_a.x, g_b.x].min, [g_a.y, g_b.y].min
      g_max = Point.new [g_a.x, g_b.x].max, [g_a.y, g_b.y].max

      [
        (g_max - g_min).sum,
        (expansion - 1) * @empty[:x].count { |x| (g_min.x..g_max.x).include? x },
        (expansion - 1) * @empty[:y].count { |y| (g_min.y..g_max.y).include? y }
      ].sum
    end
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

impl.calc
impl.output
