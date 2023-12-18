#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 17

DIRECTIONS = %i[n e s w]

Point = Struct.new('Point', :x, :y) do
  def +(other)
    Point.new(x + other.x, y + other.y)
  end

  def -(other)
    Point.new(x - other.x, y - other.y)
  end

  def abs
    Point.new(x.abs, y.abs)
  end

  def zero?
    x.zero? && y.zero?
  end

  def to_a
    [x, y]
  end

  def <=>(other)
    diff = x <=> other.x
    return diff if diff && !diff.zero?
    y <=> other.y
  end

  def self.zero
    Point.new 0, 0
  end

  def self.for(dir)
    case dir
    when :n
      Point.new(0, -1)
    when :e
      Point.new(1, 0)
    when :s
      Point.new(0, 1)
    when :w
      Point.new(-1, 0)
    else
      raise "Unknown direction #{dir.inspect}"
    end
  end

  def self.dot(a, b)
    a.x * b.x + a.y * b.y
  end
end

Entry = Struct.new('Entry', :cost, :pos, :moment, :superfluous, :path) do
  def <=>(other)
    diff = cost <=> other.cost
    return diff if diff && !diff.zero?
    diff = pos <=> other.pos
    return diff if diff && diff.zero?
    moment <=> other.moment
  end
end

class Array
  def sorted_insert(obj)
    idx = bsearch_index { |val| (val <=> obj) >= 0 }
    if idx
      insert(idx, obj)
    else
      push(obj)
    end
  end
end

class Implementation
  def initialize
    @grid = []
    @dim = Point.zero
  end

  def input(line)
    @grid += line.chars.map(&:to_i)
    @dim.x = line.size
    @dim.y += 1
  end

  def output
    bounds = build_graph
    puts "Built graph, minimum bounds: #{bounds}" if $args.verbose

    puts("Part 1:", find_path(Point.zero, @dim - Point.new(1, 1), 0..3, bounds: bounds).sum { |point| get(point) })
    puts("Part 2:", find_path(Point.zero, @dim - Point.new(1, 1), 4..10, bounds: bounds).sum { |point| get(point) })
  end

  def find_path(from, to, step_limit, bounds:)
    start = Entry.new(bounds[from], from, Point.zero, false, [])

    to_test = [start]
    cache = { [start.pos, start.moment] => start }
    costs = { [start.pos, start.moment] => 0 }

    last_out = Time.now
    puts "Finding path from #{from} to #{to} with #{step_limit} movement limit..." if $args.verbose
    until to_test.empty?
      at = to_test.shift
      next if at.superfluous

      if at.pos == to && at.moment.to_a.any? { |v| v >= step_limit.first}
        puts "Found path: #{at.path}" if $args.verbose
        return at.path 
      end

      DIRECTIONS.each do |dir|
        dot = Point.dot(Point.for(dir), at.moment)
        next if dot < 0 || dot >= step_limit.last
        next if !at.moment.zero? && dot.zero? \
          && at.moment.abs.to_a.all? { |v| v < step_limit.first }

        new_pos = at.pos + Point.for(dir)
        next unless has?(new_pos)

        new_dir = dot.zero? ? Point.for(dir) : at.moment + Point.for(dir)

        new_cost = costs.fetch([at.pos, at.moment]) + get(new_pos)
        next if costs.key?([new_pos, new_dir]) && costs.fetch([new_pos, new_dir]) < new_cost

        cache[[new_pos, new_dir]].superfluous = true if cache.key?([new_pos, new_dir])
        entry = Entry.new(new_cost + bounds[new_pos], new_pos, new_dir, false, at.path + [new_pos])

        costs[[entry.pos, entry.moment]] = new_cost
        cache[[entry.pos, entry.moment]] = entry
        to_test.sorted_insert entry
      end

      if Time.now - last_out > 1
        last_out = Time.now
        puts "Still searching, current queue: #{to_test.size}, testing path with cost #{at.cost} @ #{at.path.size}"
      end
    end

    raise "Failed to find a path"
  end

  def build_graph
    goal = @dim - Point.new(1, 1)
    to_process = [Entry.new(0, goal, Point.zero, false)]
    cache = { goal => to_process.first }
    bounds = { goal => 0 }

    puts "Building graph..." if $args.verbose
    until to_process.empty?
      at = to_process.shift
      next if at.superfluous

      cache.delete at.pos
      bounds[at.pos] = at.cost
      cost = at.cost + get(at.pos)
      DIRECTIONS.each do |dir|
        new_pos = at.pos + Point.for(dir)
        next unless has?(new_pos)
        next if bounds.key?(new_pos) && cost >= bounds[new_pos]

        bounds[new_pos] = cost
        cache[new_pos].superfluous = true if cache.key? new_pos

        new_entry = Entry.new(cost, new_pos, Point.zero, false)
        cache[new_pos] = new_entry
        to_process.sorted_insert new_entry
      end
    end

    bounds
  end

  def has?(point)
    point.x >= 0 && point.y >= 0 \
      && point.x < @dim.x && point.y < @dim.y
  end

  def get(point)
    return unless has?(point)

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
