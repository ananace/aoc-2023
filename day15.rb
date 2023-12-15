#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 15

Lens = Struct.new('Lens', :label, :focus)

class Implementation
  def initialize
    @components = []
  end

  def input(line)
    @components += line.split(',')
  end

  def output
    puts("Part 1:", @components.sum { |comp| hash comp })
    puts("Part 2:", sort_lenses.sum do |box, lenses|
      next 0 if lenses.empty?

      lenses.map.with_index do |lens, idx|
        (box + 1) * (idx + 1) * lens.focus
      end.sum
    end)
  end

  private

  def hash(string)
    cur = 0
    string.each_codepoint do |num|
      cur += num
      cur *= 17
      cur %= 256
    end
    cur
  end

  def sort_lenses
    array = {}
    @components.each do |oper|
      separator = oper.index(/[=-]/)
      label = oper[0, separator]
      box = hash(label)

      array[box] ||= []
      if oper.end_with? '-'
        array[box].delete_if { |l| l.label == label }
      else
        lens = array[box].find { |l| l.label == label }
        lens ||= (array[box] << Lens.new(label, 0)).last
        lens.focus = oper[(separator + 1)..].to_i
      end
    end
    array
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
