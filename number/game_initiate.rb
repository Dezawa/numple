# frozen_string_literal: true

module Number
  module GameInitiate
    # Read the 81 givens, accepting compact rows or whitespace-separated cells.
    def data_initialize
      values = []
      while values.size < @size && (line = gets_skip_comment(infile))
        fields = line.split
        values.concat(fields.flat_map { |field| field.each_char.to_a })
      end
      raise ArgumentError, "expected 81 cell values, got #{values.size}" unless values.size == @size

      values.each_with_index { |value, index| @cells[index].assign_valu(value) }
    end

    def structure
      initialize_board
      @form = Number::Form.new
    end

    def gets_skip_comment(input)
      line = input.gets
      line = input.gets while line && (line.match?(/^\s*#/) || line.match?(/^\s*$/))
      line
    end
  end
end
