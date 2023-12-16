#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'
require 'set'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 16

DIRECTIONS = %i[n e s w]

Point = Struct.new('Point', :x, :y) do
  def +(other)
    Point.new x + other.x, y + other.y
  end
end
Ray = Struct.new('Ray', :pos, :dir) do
  def move
    Ray.new(pos + direction, dir)
  end

  def move!
    pos += direction
  end

  def direction
    case dir
    when :n
      Point.new 0, -1
    when :e
      Point.new 1, 0
    when :s
      Point.new 0, 1
    when :w
      Point.new -1, 0
    else
      raise "Unknown direction #{dir.inspect}"
    end
  end

  def turn(sign)
    Ray.new(pos, DIRECTIONS[(DIRECTIONS.index(dir) + sign) % 4])
  end

  def turn!(sign)
    self.dir = DIRECTIONS[(DIRECTIONS.index(dir) + sign) % 4]
  end
end

class Implementation
  def initialize
    @grid = ''
    @dim = Point.new 0, 0
  end

  def input(line)
    @dim.x = line.size
    @dim.y += 1
    @grid += line
  end

  def output
    visited = trace(Point.new(0, 0), :e)
    points = visited.map(&:pos).uniq

    if $args.verbose
      @dim.y.times do |y|
        @dim.x.times do |x|
          print "\e[1;32m" if points.include?(Point.new(x, y))
          print get(Point.new(x, y))
          print "\e[0m"
        end
        puts
      end
    end

    puts "Part 1:", points.size

    best = 0
    @dim.x.times do |x|
      best = [best, trace(Point.new(x, 0), :s).map(&:pos).uniq.size].max
      best = [best, trace(Point.new(x, @dim.y - 1), :n).map(&:pos).uniq.size].max
    end
    @dim.y.times do |y|
      best = [best, trace(Point.new(0, y), :e).map(&:pos).uniq.size].max
      best = [best, trace(Point.new(@dim.x - 1, y), :w).map(&:pos).uniq.size].max
    end

    puts "Part 2:", best
  end

  def trace(point, dir)
    visited = Set.new
    active = [Ray.new(point, dir)]

    until active.empty?
      to_iter = active.dup
      active.clear

      to_iter.each do |ray|
        next unless get(ray.pos)
        next unless visited.add?(ray)

        case get(ray.pos)
        when '.'
          active << ray.move
        when '/'
          case ray.dir
          when :w, :e
            ray.turn!(-1)
          else
            ray.turn!(1)
          end
          active << ray.move
        when '\\'
          case ray.dir
          when :n, :s
            ray.turn!(-1)
          else
            ray.turn!(1)
          end
          active << ray.move
        when '|'
          if %i[w e].include? ray.dir
            active << ray.turn(-1).move
            active << ray.turn(1).move
          else
            active << ray.move
          end
        when '-'
          if %i[n s].include? ray.dir
            active << ray.turn(-1).move
            active << ray.turn(1).move
          else
            active << ray.move
          end
        end
      end
    end

    visited.to_a
  end

  def get(point)
    return unless point.x >= 0 && point.y >= 0 \
      && point.x < @dim.x && point.y < @dim.y

    @grid[point.y * @dim.x + point.x]
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
