#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 18

DIRECTION=%i[R D L U]

Point = Struct.new('Point', :x, :y) do
  def +(other)
    Point.new(x + other.x, y + other.y)
  end
  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def *(other)
    other = Point.new(other, other) unless other.is_a?(Point)
    Point.new(x * other.x, y * other.y)
  end

  def self.for(dir)
    case dir
    when :U
      Point.new(0, -1)
    when :R
      Point.new(1, 0)
    when :D
      Point.new(0, 1)
    when :L
      Point.new(-1, 0)
    end
  end
end

Task = Struct.new('Task', :direction, :length, :color)

class Implementation
  def initialize
    @program = []
  end

  def input(line)
    dir, len, col = line.split
    @program << Task.new(dir.to_sym, len.to_i, col.delete('()'))
  end

  def output
    puts "Part 1:", dig

    rebuild_program

    puts "Part 2:", dig
  end

  def dig
    at = Point.new(0, 0)
    points = [at]
    perimeter = 0
    @program.each do |task|
      at += Point.for(task.direction) * task.length
      perimeter += task.length
      points << at
    end

    min = Point.new(points.map(&:x).min, points.map(&:y).min)
    max = Point.new(points.map(&:x).max, points.map(&:y).max)
    dim = max - min

    puts "Program results in #{dim} area (#{perimeter})" if $args.verbose

    # Shoelace formula
    ((points
      .zip(points[1..] + [points[0]])
      .sum { |a, b| a.x * b.y - b.x * a.y } / 2)
      .abs + perimeter * 0.5 + 1)
      .to_i
  end

  def rebuild_program
    @program.map! do |task|
      col = task.color.delete '#'
      Task.new DIRECTION[col[-1].to_i], col[0..4].to_i(16), '#000'
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

impl.output
