#!/usr/bin/env ruby
# frozen_string_literal: true

# Solve standard 9x9 Sudoku puzzles using logical techniques.
# Input starts with a 9 or STD declaration unless -9 is provided.
# Each puzzle contains 81 cells: digits are givens and other characters are empty.
require 'optparse'
require_relative 'number/game'

class Numple
  attr_reader :infile, :game, :option

  def initialize(infile, option: {})
    @infile = infile.is_a?(String) ? File.open(infile) : infile
    @option = option
  end

  # パズルを解き、出力用にGameを保持する。
  def resolve
    game = create_game
    game.resolve
  end

  # 解答済み、または途中まで解いた9x9盤面を返す。
  def output_form
    game.output_form
  end

  # 未確定セルに残っている候補を返す。
  def cell_out
    game.cell_out
  end

  # 解法ごとの使用回数を返す。
  def output_statistics
    game.output_statistics
  end

  # 入力を読み、SudokuのGameを作成する。
  def create_game
    @game = Number::Game.create(infile, option: option)
  end
end

if $PROGRAM_NAME == __FILE__
  option = {}
  OptionParser.new do |parser|
    parser.banner = 'Usage: ruby numple.rb [options] [puzzle-file ...]'
    parser.on('-S', 'Print solving technique statistics') { option[:stat] = true }
    parser.on('-c', 'Print remaining cell candidates') { option[:cout] = true }
    parser.on('-g', 'Print group structure') { option[:gout] = true }
    parser.on('-v', 'Print solving progress') { option[:verb] = true }
    parser.on('-9', 'Read headerless 81-cell puzzle data') { option[:nine] = true }
    parser.on('-h', 'Show this help') do
      puts parser
      exit
    end
  end.parse!

  inputs = ARGV.empty? ? [STDIN] : ARGV
  inputs.each do |input|
    puts "############ #{input} #######" unless input == STDIN
    numple = Numple.new(input, option: option)
    warn "FAIL #{input}" unless numple.resolve
    print numple.output_form
    puts
    puts numple.cell_out if option[:cout]
    puts numple.output_statistics if option[:stat]
  end
end
