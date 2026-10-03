# frozen_string_literal: true

require_relative './form'
require_relative './cell'
require_relative './group'
require_relative './group_ability'
require_relative './game_board'
require_relative './game_initiate'
require_relative './resolver'

module Number
  class Game
    SIZE = 9
    CELL_COUNT = SIZE * SIZE
    GROUP_COUNT = SIZE * 3

    include Number::GameBoard
    include Number::Resolver
    include Number::GameInitiate

    attr_accessor :groups, :cells, :gsize, :size, :form, :option
    attr_reader :infile, :count, :call_count

    def self.create(infile, option: {})
      # -9指定時は、サイズ宣言なしで81セルのデータを読む。
      unless option[:nine]
        header = read_board_header(infile)
        unless header.match?(/\A\s*(?:9|STD)\s*\z/i)
          raise ArgumentError, "only standard 9x9 Sudoku is supported (got #{header.strip.inspect})"
        end
      end

      instance = new(infile, option: option)
      instance.structure
      instance.gout if option[:gout]
      instance.data_initialize
      puts instance.cell_out if option[:cout]
      instance
    end

    def self.read_board_header(infile)
      line = infile.gets
      line = infile.gets while line && (line.match?(/^\s*#/) || line.match?(/^\s*$/))
      line || ''
    end

    def initialize(infile = nil, option: {})
      @infile = infile
      @option = option
      @groups = []
      @cells = []
      @count = Hash.new(0)
      @call_count = Hash.new(0)
    end

    def output_form
      # 未確定セルはピリオドで表示する。
      form.out cells
    end

    # 解法ごとに盤面を変更した回数。
    def output_statistics
      @count.map { |label, value| format(" Stat: %<l>-10s %<v>3d\n", l: label, v: value) }.join
    end

    def cell_ability
      # 未確定セルと、そこに残っている候補数字。
      cells.select { |cell| cell.v.nil? }.map { |cell| [cell.c, cell.ability] }
    end

    def cell_out
      cell_ability.map { |cell_id, ability| "#{cell_id} : #{ability}" }.join("\n")
    end

    def output(statistics, _count, cellout)
      cell_out if cellout
      statistics && @count.each { |label, value| printf " Stat: %<l>-10s %<v>3d\n", l: label, v: value }
      form.out cells
    end
  end
end
