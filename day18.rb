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

DIRECTION=%i[U R D L]

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
    area, dim = dig
    if $args.verbose
      dim.y.times do |y|
        dim.x.times do |x|
          print area[y * dim.x + x]
        end
        puts
      end
    end
    
    puts "Part 1:", area.count('#')
  end

  def dig
    at = Point.new(0, 0)
    points = [at]
    @program.each do |task|
      at += Point.for(task.direction) * task.length
      points << at
    end

    min = Point.new(points.map(&:x).min, points.map(&:y).min)
    max = Point.new(points.map(&:x).max, points.map(&:y).max)
    dim = max - min + Point.new(1, 1)

    puts "Program results in #{min} -> #{max} area (#{dim})" if $args.verbose

    grid = ''
    dim.y.times do |y|
      dim.x.times do |x|
        grid += '.'
      end
    end

    at = Point.new(0, 0)
    @program.each do |task|
      task.length.times do
        grid[(at.y - min.y) * dim.x + (at.x - min.x)] = '#'
        at += Point.for(task.direction)
      end
    end

    flood(grid, dim, Point.new(1, 1) - min, '#')

    return grid, dim
  end

  def flood(area, size, at, char)
    puts "Flooding area..." if $args.verbose

    to_flood = [at]
    area[at.y * size.x + at.x] = '#'

    until to_flood.empty?
      point = to_flood.shift

      DIRECTION.each do |dir|
        new = point + Point.for(dir)
        next if new.x < 0 || new.y < 0 || new.x >= size.x || new.y >= size.y
        next if area[new.y * size.x + new.x] != '.'

        area[new.y * size.x + new.x] = '#'

        to_flood << new
      end
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
