#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 10

Point = Struct.new('Point', :x, :y) do
  def +(point)
    Point.new x + point.x, y + point.y
  end
  def -(point)
    Point.new x - point.x, y - point.y
  end
  def *(point)
    point = Point.new point, point unless point.is_a?(Point)
    Point.new x * point.x, y * point.y
  end

  def size
    x * y
  end

  def to_s
    "[#{x},#{y}]"
  end
end

Link = Struct.new('Link', :a, :b, :at) do
  def connected?(point)
    connections.include? point
  end

  def other(point)
    point == a ? b : a
  end

  def connections
    [at, a, b]
  end

  def to_s
    "#{at}: #{a}<->#{b}"
  end
end

class Implementation
  def initialize
    @grid = []
    @links = {}
    @dim = Point.new 0, 0
    @start = nil
  end

  def input(line)
    @dim.x = line.size
    @dim.y += 1
    @grid += line.chars
  end

  def calc
    (0..(@dim.y - 1)).each do |y|
      (0..(@dim.x - 1)).each do |x|
        point = Point.new x, y
        links = []
        char = @grid[y * @dim.x + x % @dim.x]

        case char
        when '|'
          links << point + Point.new(0, -1)
          links << point + Point.new(0, 1)
        when '-'
          links << point + Point.new(-1, 0)
          links << point + Point.new(1, 0)
        when 'L'
          links << point + Point.new(0, -1)
          links << point + Point.new(1, 0)
        when 'J'
          links << point + Point.new(0, -1)
          links << point + Point.new(-1, 0)
        when '7'
          links << point + Point.new(-1, 0)
          links << point + Point.new(0, 1)
        when 'F'
          links << point + Point.new(1, 0)
          links << point + Point.new(0, 1)
        when 'S'
          @start = point
        end
        next if links.empty?

        @links[point] = Link.new(*links, point)
      end
    end

    start_char = ''
    start_links = @links.values.select { |l| l.connected? @start }.map { |l| l.at - @start }
    if start_links == [Point.new(1, 0), Point.new(0, -1)] || start_links == [Point.new(0, -1), Point.new(1, 0)]
      start_char = 'L'
    elsif start_links == [Point.new(-1, 0), Point.new(0, -1)] || start_links == [Point.new(0, -1), Point.new(-1, 0)]
      start_char = 'J'
    elsif start_links == [Point.new(-1, 0), Point.new(0, 1)] || start_links == [Point.new(0, 1), Point.new(-1, 0)]
      start_char = '7'
    elsif start_links == [Point.new(1, 0), Point.new(0, 1)] || start_links == [Point.new(0, 1), Point.new(1, 0)]
      start_char = 'F'
    elsif start_links == [Point.new(-1, 0), Point.new(1, 0)] || start_links == [Point.new(1, 0), Point.new(-1, 0)]
      start_char = '-'
    elsif start_links == [Point.new(0, -1), Point.new(0, 1)] || start_links == [Point.new(0, 1), Point.new(0, -1)]
      start_char = '|'
    end
    raise "Unable to deduce start (#{start_links})" if start_char.empty?

    puts "Deduced start #{@start} as #{start_char}" if $args.verbose
    @grid[@start.y * @dim.x + @start.x] = start_char
    @links[@start] = Link.new(*start_links.map { |p| @start + p }, @start)
  end

  def output
    walked = walk(@start)

    if $args.verbose
      (0..(@dim.y - 1)).each do |y|
        (0..(@dim.x - 1)).each do |x|
          print "\e[1;32m" if walked.key?(Point.new(x, y))

          print @grid[y * @dim.x + x]

          print "\e[0m"
        end
        puts
      end
    end

    puts "Part 1:", walked.values.max

    map, dim = flood_fill(used: walked.keys)

    if $args.verbose
      (0..(dim.y - 1)).each do |y|
        (0..(dim.x - 1)).each do |x|
          print map[y * dim.x + x]
        end
        puts
      end
    end

    puts "Part 2:", map.count(2)
  end

  private

  def walk(from)
    depth = 0
    walked = {}
    to_walk = [from]

    loop do
      break if to_walk.empty?

      walking = to_walk.dup
      to_walk = []

      walking.each do |at|
        walked[at] = depth
        
        (-1..1).each do |y|
          (-1..1).each do |x|
            next if (x.zero? && y.zero?) || !(x.zero? || y.zero?)

            new = at + Point.new(x, y)
            next if walked.key?(new) || to_walk.include?(new)

            link_at = @links[at]
            next unless link_at.connected? new

            link = @links[new]
            next unless link&.connected? at

            to_walk << new
          end
        end
      end

      depth += 1
    end
    
    walked
  end

  def flood_fill(used: [])
    new_dim = @dim * 3
    new_map = Array.new(new_dim.size, 1)

    puts "Expanding #{@dim} to #{new_dim}, with #{used.size} used..." if $args.verbose

    (0..(new_dim.y - 1)).each do |y|
      (0..(new_dim.x - 1)).each do |x|
        in_point = Point.new x % 3, y % 3
        next unless in_point == Point.new(1, 1)

        real_point = Point.new x / 3, y / 3
        used_p = used.include?(real_point)

        real = get(real_point)
        if real == '.' || !used_p
          new_map[y * new_dim.x + x] = 2
        elsif used_p
          new_map[y * new_dim.x + x] = '#'
          offsets = @links[real_point].connections
          offsets.shift

          offsets.each do |offs|
            diff = offs - real_point
            new_map[(y + diff.y) * new_dim.x + (x + diff.x)] = '#'
          end
        end
      end
    end

    puts "Visiting expanded map..." if $args.verbose

    to_visit = [Point.new(0, 0)]
    out = Time.now

    until to_visit.empty?
      at = to_visit.shift
      new_map[at.y * new_dim.x + at.x] = ' '

      (-1..1).each do |off_y|
        (-1..1).each do |off_x|
          next if (off_x.zero? && off_y.zero?) || (!off_x.zero? && !off_y.zero?)

          off = Point.new off_x, off_y
          off_p = at + off

          next if off_p.x < 0 || off_p.y < 0 \
            || off_p.x >= new_dim.x || off_p.y >= new_dim.y \
            || to_visit.include?(off_p)

          val = new_map[off_p.y * new_dim.x + off_p.x]
          #puts "At #{at}, testing #{off}/#{off_p} (#{val})"

          next if val == 0 || val == '#' || val == ' '

          to_visit << off_p
        end
      end

      if Time.now - out > 1
        puts "Still visiting, queue: #{to_visit.size}" if $args.verbose
        out = Time.now
      end
    end

    return new_map, new_dim
  end

  def get(point)
    return unless point.x >= 0 && point.y >= 0 && point.x < @dim.x && point.y < @dim.y

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
  next if line.start_with?('#') || line.strip.empty?

  impl.input line.strip
end

impl.calc

impl.output
