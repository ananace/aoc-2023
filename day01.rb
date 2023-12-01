#!/bin/env ruby
# frozen_string_literal: true

require 'ostruct'

$args = OpenStruct.new

#
# Daily challenge
#

DAY = 1

class String
  def to_numberstring(digits_only: false)
    tokens = %w[ 
      one two three
      four five six
      seven eight nine
    ].freeze
    ret = ""

    i = 0
    loop do
      if self[i] =~ /\d/
        ret += self[i]
      elsif !digits_only
        tok = tokens.find { |k| self[i, k.size] == k }
        ret += (tokens.index(tok) + 1).to_s if tok
      end
      
      i += 1
      break if i >= size
    end

    ret
  end
end

class Implementation
  def initialize
    @calibration = [0, 0]
  end

  def input(line)
    puts "Before: #{line}" if $args.verbose
    first = line.to_numberstring(digits_only: true)
    second = line.to_numberstring
    puts "After: #{first} / #{second}" if $args.verbose

    [first, second].each.with_index do |line, i|
      numbers = line.scan(/\d/)
      num = [numbers.first, numbers.last].join
      @calibration[i] += num.to_i
    end
  end

  def output
    puts "Part 1:"
    puts @calibration[0]
    puts "Part 2:"
    puts @calibration[1]
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

  parser.on '-v', '--verbose', 'Run verbosely' do
    $args.verbose = true
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

#
# Actual input/output action
#

open(datafile).each_line do |line|
  next if line.strip.empty? || line.start_with?('#')

  impl.input line.strip
end

impl.output
