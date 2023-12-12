#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 12

Record = Struct.new('Record', :data, :blocks) do
  def permutations
    print "Generating permutations for #{data}, #{blocks.inspect}: " if $args.verbose

    ret = Record.calc_permutations(data, blocks.dup)
    puts ret if $args.verbose

    ret
  end

  def unfold
    Record.new ([data] * 5).join('?'), blocks * 5
  end

  class << self
    def calc_permutations(line, unchecked)
      # Cache known permutation counts
      @perms ||= {}
      id = [line, unchecked].hash
      return @perms[id] if @perms.key? id

      @perms[id] ||= _calc_permutations(line, unchecked)
    end

    private

    def _calc_permutations(line, unchecked)
      found = 0
      wanted = 0
      matching = false

      line.each_char.with_index do |chr, i|
        if matching
          if wanted.zero?
            return found if chr == '#'

            matching = false
          else
            return found if chr == '.'

            wanted -= 1
          end
        else
          next if chr == '.'

          found += calc_permutations(line[(i + 1)..], unchecked.dup) if chr == '?'
          return found if unchecked.empty?

          wanted = unchecked.shift - 1
          matching = true
        end
      end

      found += 1 if unchecked.empty? && (!matching || wanted.zero?)
      found
    end
  end
end

class Implementation
  def initialize
    @records = []
  end

  def input(line)
    data, blocks = line.split
    @records << Record.new(data, blocks.split(',').map(&:to_i))
  end

  def output
    puts "Part 1:", @records.sum(&:permutations)
    puts "Part 2:", @records.map(&:unfold).sum(&:permutations)
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
