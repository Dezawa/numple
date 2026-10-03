# frozen_string_literal: true

module Number
  # Builds the 27 standard Sudoku groups and their 81 cells.
  module GameBoard
    SIZE = 9
    BOX_SIZE = 3

    def initialize_board
      @groups = Array.new(SIZE * 3) do |group_id|
        type = group_id < SIZE ? :holizontal : (group_id < SIZE * 2 ? :vertical : :block)
        Number::Group.new(self, group_id, @count, type)
      end
      @cells = Array.new(SIZE * SIZE) do |cell_id|
        Number::Cell.create(self, cell_id, [], @count, option: option)
      end

      @cells.each do |cell|
        row = cell.c / SIZE
        column = cell.c % SIZE
        block = SIZE * 2 + (row / BOX_SIZE) * BOX_SIZE + column / BOX_SIZE
        [row, SIZE + column, block].each do |group_id|
          cell.group_ids << group_id
          @groups[group_id].addcell_ids(cell.c)
        end
      end
      @groups.each { |group| group.ability.setup_initial(group.cell_ids) }
      @gsize = @groups.size
      @size = @cells.size
    end
  end
end
