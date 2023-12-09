#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 9

Sample = Struct.new('Sample', :values) do
  def succ
    diffs = extrapolate
    succ = values.last + diffs.first.last

    puts "Extrapolating #{succ} as succeeding" if $args.verbose

    succ
  end

  def prec
    diffs = extrapolate
    prec = values.first - diffs.first.first

    puts "Extrapolating #{prec} as preceeding " if $args.verbose

    prec
  end

  private

  def extrapolate
    diffs = []
    cur = values

    until cur.all?(&:zero?) do
      cur = (1..(cur.size-1)).map { |i| cur[i] - cur[i - 1] }
      diffs << cur
    end

    diffs.reverse_each do |diff|
      next_diff = diffs[diffs.index(diff) + 1]
      
      if next_diff
        diff.push diff.last + next_diff.last
        diff.unshift diff.first - next_diff.first
      else
        diff.push 0
        diff.unshift 0
      end
    end

    puts "Extrapolated #{values} into #{diffs}" if $args.verbose

    diffs
  end
end

class Implementation
  def initialize
    @samples = []
  end

  def input(line)
    @samples << Sample.new(line.split.map(&:to_i))
  end

  def output
    puts "Part 1:", @samples.map(&:succ).sum
    puts "Part 2:", @samples.map(&:prec).sum
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
