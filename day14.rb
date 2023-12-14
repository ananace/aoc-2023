#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 14

Point = Struct.new('Point', :x, :y)

class Implementation
  def initialize
    @dim = Point.new 0, 0
    @grid = ''
  end

  def input(line)
    @dim.x = line.size
    @dim.y += 1
    @grid += line
  end

  def output
    print_grid

    roll_ns(-1)
    puts if $args.verbose

    cost = 0
    @dim.y.times do |y|
      @dim.x.times do |x|
        cost += @dim.y - y if get(x, y) == 'O'
      end
    end

    puts "Part 1:", cost

    first = true
    repeat_point = nil
    cycles = {}
    cycle_count = 1_000_000_000
    cycle_count.times do |cycle|
      if cycles.key? @grid.hash
        repeat_point = (cycles[@grid.hash]..cycle)
        break
      end

      cycles[@grid.hash] = cycle
      if $args.verbose
        puts "At cycle #{cycle}"
        print_grid
        puts
      end
      cycle(first)

      first = false
    end

    puts "Cycle found at #{repeat_point}" if $args.verbose

    num = (cycle_count - repeat_point.first) / (repeat_point.last - repeat_point.first)
    remain = cycle_count - repeat_point.first - (num * (repeat_point.last - repeat_point.first))
    remain.times { cycle }

    cost = 0
    @dim.y.times do |y|
      @dim.x.times do |x|
        cost += @dim.y - y if get(x, y) == 'O'
      end
    end

    puts "Part 2:", cost
  end

  def print_grid
    @dim.y.times do |y|
      @dim.x.times do |x|
        print get(x, y) if $args.verbose
      end
      puts if $args.verbose
    end
  end

  def cycle(skip_first = false)
    roll_ns(-1) unless skip_first
    roll_ew(-1)
    roll_ns(1)
    roll_ew(1)
  end

  def roll_ns(dir)
    (@dim.y).times do |iter|
      (0..(@dim.y - 1 - iter)).each do |row|
        y = row
        y = @dim.y - row if dir < 0
        next unless get(0, y + dir)

        @dim.x.times do |x|
          next unless get(x, y) == 'O'
          next if get(x, y + dir) != '.'

          # puts "At [#{x},#{row}] => #{get(x, row)}"

          set(x, y + dir, 'O')
          set(x, y, '.')
        end
      end
    end
  end

  def roll_ew(dir)
    (@dim.x).times do |iter|
      (0..(@dim.x - 1 - iter)).each do |col|
        x = col
        x = @dim.x - col if dir < 0
        next unless get(x + dir, 0)

        @dim.y.times do |y|
          next unless get(x, y) == 'O'
          next if get(x + dir, y) != '.'

          # puts "At [#{x},#{row}] => #{get(x, row)}"

          set(x + dir, y, 'O')
          set(x, y, '.')
        end
      end
    end
  end

  def get(x, y)
    return unless x >= 0 && y >= 0 \
      && x < @dim.x && y < @dim.y

    @grid[y * @dim.x + x]
  end

  def set(x, y, char)
    return unless x >= 0 && y >= 0 \
      && x < @dim.x && y < @dim.y

    @grid[y * @dim.x + x] = char
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
