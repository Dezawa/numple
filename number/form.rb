# frozen_string_literal: true

module Number
  # Formats a standard 9x9 Sudoku board.
  class Form
    def out(cells)
      cells.each_slice(9).map do |row|
        "#{row.map { |cell| cell.v || '.' }.join} \n"
      end.join
    end
  end
end
