#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 4

class Implementation
  def initialize
    @cards = []
    @winnings = []
  end

  def input(line)
    card, numbers = line.split(':').map(&:strip)
    card_numbers, winning_numbers = numbers.split('|').map { |num| num.split.map(&:to_i) }
    card = { 
      id: card.split.last.to_i,
      numbers: card_numbers,
      winning: winning_numbers
    }

    @cards << card
  end

  def output
    @winnings = Array.new(@cards.size, 1)
    part1 = @cards.sum do |card|
      points = card[:numbers] & card[:winning]
      puts "Card #{card[:id]} has #{points.size} matches" if $args.verbose

      score = 0
      unless points.empty?
        score = 2 ** (points.size - 1)

        mult = @winnings[card[:id] - 1]

        puts "Card #{card[:id]} gets a #{mult}x multiplier" if $args.verbose
        points.size.times do |adj|
          new_card = card[:id] + adj + 1
          next if new_card > @cards.size

          @winnings[new_card - 1] += @winnings[card[:id] - 1]
        end
      end

      score
    end

    puts "Part 1:", part1
    puts "Part 2:", @winnings.compact.sum
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
