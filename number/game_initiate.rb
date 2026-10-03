# frozen_string_literal: true

module Number
  module GameInitiate
    # 81セルの初期値を読む。各行の連続表記と、空白区切りに対応する。
    # ピリオドなど数字以外の文字は未確定セルを表す。
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
      # 9x9盤面のセル、行、列、3x3ブロックを作成する。
      initialize_board
      @form = Number::Form.new
    end

    def gets_skip_comment(input)
      # 入力中のコメント行と空行を読み飛ばす。
      line = input.gets
      line = input.gets while line && (line.match?(/^\s*#/) || line.match?(/^\s*$/))
      line
    end
  end
end
