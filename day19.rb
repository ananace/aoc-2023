#!/bin/env ruby
# frozen_string_literal: true

require 'logger'
require 'ostruct'

$log = Logger.new($stdout, level: Logger::WARN)
$args = OpenStruct.new

#
# Daily challenge
#

DAY = 19

Comparison = Struct.new('Comparison', :op, :source, :value) do
  def match?(against)
    to_match = against[source]
    case op
    when :>
      to_match > value
    when :<
      to_match < value
    end
  end
end

Task = Struct.new('Task', :action, :comparison) do
  def match(against)
    return unless comparison

    action if comparison.match?(against)
  end

  def self.parse(string)
    comparison, action = string.split(':')
    action, comparison = comparison, action unless action
    action = action.to_sym if action != action.downcase

    if comparison
      op = comparison.index /[><]/
      comparison = Comparison.new comparison[op].to_sym, comparison[...op].to_sym, comparison[op.succ..].to_i
    end

    new(action, comparison)
  end
end

Workflow = Struct.new('Workflow', :tasks) do
  def match(against)
    tasks.lazy.map { |t| t.comparison ? t.match(against) : t.action }.reject(&:nil?).first
  end
end


class Implementation
  def initialize
    @workflows = {}
    @parts = []
  end

  def add_workflow(line)
    name, data = line.chop.split('{')
    @workflows[name.to_s] = Workflow.new(data.split(',').map { |task| Task.parse(task) })
  end

  def add_part(line)
    comps = line[1..-2].split(',')
    part = comps.to_h do |comp|
      key, value = comp.split '='
      [key.to_sym, value.to_i]
    end
    @parts << part
  end

  def output
    puts("Part 1:", @parts.select { |p| examine_part(p) }.map { |p| p.values.sum }.sum)
    puts "Part 2:", calc_valid('in', 0, { x: 1..4000, m: 1..4000, a: 1..4000, s: 1..4000 })
  end

  def examine_part(part)
    at = @workflows['in']
    loop do
      result = at.match(part)
      return true if result == :A
      return false if result == :R

      at = @workflows[result]
    end
  end

  def calc_valid(workflow, task, limits)
    return limits.values.map(&:size).inject(:*) if workflow == :A
    return 0 if workflow == :R || limits.map(&:size).any?(:zero?)

    puts "Calculating valid for #{task}@#{workflow} - #{limits}" if $args.verbose

    task_obj = @workflows[workflow].tasks[task]
    range = limits[task_obj.comparison.source] if task_obj.comparison
    case task_obj.comparison&.op
    when :>
      range_follow = Range.new([range.first, task_obj.comparison.value + 1].max, range.last)
      range_skip = Range.new(range.first, [range.last, task_obj.comparison.value].min)
      [
        calc_valid(task_obj.action, 0, limits.merge({ task_obj.comparison.source => range_follow })),
        calc_valid(workflow, task + 1, limits.merge({ task_obj.comparison.source => range_skip })),
      ].sum
    when :<
      range_follow = Range.new(range.first, [range.last, task_obj.comparison.value - 1].min)
      range_skip = Range.new([range.first, task_obj.comparison.value].max, range.last)
      [
        calc_valid(task_obj.action, 0, limits.merge({ task_obj.comparison.source => range_follow })),
        calc_valid(workflow, task + 1, limits.merge({ task_obj.comparison.source => range_skip })),
      ].sum
    else
      return calc_valid(task_obj.action, 0, limits)
    end
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

state = :workflows
open(datafile).each_line do |line|
  next state = :parts if line.strip.empty?

  impl.add_workflow line.strip if state == :workflows
  impl.add_part line.strip if state == :parts
end

impl.output
