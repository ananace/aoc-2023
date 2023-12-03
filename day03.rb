#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 3

Point = Struct.new('Point', :x, :y)
PartNumber = Struct.new('PartNumber', :number, :adjacent) do
  def adjacent?(to)
    adjacent.include? to
  end

  def irrelevant?
    adjacent.empty?
  end

  def to_i
    number
  end
end

class Implementation
  def initialize
    @map = []
    @dim = { width: 0, height: 0 }

    @symbols = []
    @numbers = []
  end

  def input(line)
    @dim[:width] = line.size
    @dim[:height] += 1

    @map += line.chars
  end

  def calc
    puts "Calculating intermediates for #{@dim[:width]}x#{@dim[:height]} input data..."

    for y in (0..@dim[:height]-1) do
      for x in (0..@dim[:width]-1) do
        chr = get(x, y)
        print chr if $args.verbose

        next if chr =~ /\d/
        next unless chr != '.'
        @symbols << Point.new(x, y)
      end
      print "\n" if $args.verbose
    end

    puts "Symbols: #{$args.verbose ? @symbols : @symbols.size}"

    for y in (0..@dim[:height]-1) do
      buf = ""
      adj = []
      for x in (0..@dim[:width]) do
        chr = get(x, y)
        if chr =~ /\d/
          buf += chr

          (-1..1).each do |adj_x|
            (-1..1).each do |adj_y|
              next if adj_x == 0 && adj_y == 0
              next if \
                (x + adj_x < 0) || (x + adj_x >= @dim[:width]) ||
                (y + adj_y < 0) || (y + adj_y >= @dim[:height])

              sym = Point.new(x + adj_x, y + adj_y)
              adj << sym if @symbols.any? sym
            end
          end
        elsif !buf.empty?
          @numbers << PartNumber.new(buf.to_i, adj)

          buf = ""
          adj = []
        end
      end
    end

    puts "Numbers: #{$args.verbose ? @numbers : @numbers.size}"
    puts
  end

  def output
    part1 = @numbers.reject(&:irrelevant?).map(&:to_i).sum

    puts "Part 1:"
    puts part1

    gears = @symbols.select do |sym|
      chr = get(sym)
      next unless chr == '*'

      adj = @numbers.select { |num| num.adjacent? sym }
      next unless adj.size == 2

      true
    end
    part2 = gears.sum { |gear| @numbers.select { |num| num.adjacent? gear }.map(&:to_i).inject(:*) }

    puts "Part 2:"
    puts part2
  end

  private

  def get(x, y = 0)
    y = x.y if x.is_a?(Point)
    x = x.x if x.is_a?(Point)
    y ||= -1

    return unless (0..@dim[:width]-1).include?(x) && (0..@dim[:height]-1).include?(y)

    @map[y * @dim[:width] + x % @dim[:width]]
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
