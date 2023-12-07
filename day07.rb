#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 7

$jokers = false

CARD_STRENGTH = 'AKQJT98765432'
REAL_CARD_STRENGTH = 'AKQT98765432J'

def card_value(card)
  return 14 - REAL_CARD_STRENGTH.index(card) if $jokers

  14 - CARD_STRENGTH.index(card)
end

Hand = Struct.new('Hand', :cards, :bid) do
  def type
    # Avoid recalculating type for every comparison, even when jokers are 
    # involved.
    return @type if @type && @jokers == $jokers

    @jokers = $jokers

    counts = {}
    cards.each_char do |card|
      counts[card] ||= 0
      counts[card] += 1
    end

    jokers = 0
    jokers = counts.delete('J') || 0 if $jokers

    cards = counts.values.sort.reverse
    cards << 0 if cards.empty?

    if cards[0] + jokers == 5
      @type = :five_kind
    elsif cards[0] + jokers == 4
      @type = :four_kind
    elsif (cards[0] + jokers == 3 && cards[1] == 2) \
       || (cards[0] == 3 && cards[1] + jokers == 2)
      @type = :full_house
    elsif cards[0] + jokers == 3
      @type = :three_kind
    elsif (cards[0] + jokers == 2 && cards[1] == 2) \
       || (cards[0] == 2 && cards[1] + jokers == 2)
      @type = :two_pair
    elsif cards[0] + jokers == 2
      @type = :one_pair
    else
      @type = :high_card
    end
  end

  def type_score
    %i[
      high_card one_pair two_pair three_kind
      full_house four_kind five_kind
    ].index(type)
  end

  def <=>(other)
    return super unless other.is_a? Hand
    return type_score <=> other.type_score unless type == other.type

    cards.size.times do |i|
      diff = card_value(cards[i]) <=> card_value(other.cards[i])
      return diff unless diff.zero?
    end

    0
  end

  def to_s
    "<#{cards} @ #{bid} - #{type}>"
  end
end

class Implementation
  def initialize
    @hands = []
  end

  def input(line)
    cards, bid = line.split
    bid = bid.to_i
    @hands << Hand.new(cards, bid)
  end

  def output
    sorted = @hands.sort
    puts "Hands:", sorted if $args.verbose

    part1 = sorted.map.with_index { |hand, ind| hand.bid * (ind + 1) }.sum
    puts "Part 1:", part1

    $jokers = true

    sorted = @hands.sort
    puts "Hands:", sorted if $args.verbose

    part2 = sorted.map.with_index { |hand, ind| hand.bid * (ind + 1) }.sum
    puts "Part 2:", part2
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
