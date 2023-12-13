#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 13

Point = Struct.new('Point', :x, :y)
Grid = Struct.new('Grid', :map, :dim) do
  def mirror
    puts "Checking #{self}" if $args.verbose
    mirror = {
      clean: 0,
      smudged: 0
    }

    (1..dim.x-1).each do |x|
      misses = x.times.map do |i|
        next if x + i >= dim.x

        dim.y.times.count { |y| get(x - i - 1, y) != get(x + i, y) }
      end.compact.sum

      puts "Found horizontal mirror on X #{x}" if $args.verbose && misses.zero?
      puts "Found smudged horizontal mirror on X #{x}" if $args.verbose && misses == 1
      mirror[:clean] += x if misses.zero?
      mirror[:smudged] += x if misses == 1
    end

    (1..dim.y-1).each do |y|
      misses = y.times.map do |i|
        next if y + i >= dim.y

        dim.x.times.count { |x| get(x, y - i - 1) != get(x, y + i) }
      end.compact.sum

      puts "Found vertical mirror on Y #{y}" if $args.verbose && misses.zero?
      puts "Found smudged vertical mirror on Y #{y}" if $args.verbose && misses == 1
      mirror[:clean] += y * 100 if misses.zero?
      mirror[:smudged] += y * 100 if misses == 1
    end
    mirror
  end

  def get(x, y)
    return unless \
      x >= 0 && y >= 0 && \
      x < dim.x && y < dim.y

    map[y * dim.x + x]
  end
end

class Implementation
  def initialize
    @grids = []
    @cur = nil
  end

  def input(line)
    @cur ||= Grid.new('', Point.new(0, 0))

    if line.empty?
      @grids << @cur unless @cur.map.empty?
      @cur = nil
    else
      @cur.dim.x = line.size
      @cur.dim.y += 1
      @cur.map += line
    end
  end

  def output
    mirrored = @grids.map(&:mirror)
    puts "Part 1:", mirrored.sum { |m| m[:clean] }
    puts "Part 2:", mirrored.sum { |m| m[:smudged] }
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
impl.input ''

impl.output
