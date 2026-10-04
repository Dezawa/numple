# frozen_string_literal: true

module Number
  # 候補が一つになったセルを確定する PrisonSingle。
  module ResolvPrisonSingle
    # 対象セルに残る候補が一つだけなら検出結果を返す。
    # 検出中に盤面は変更しない。
    def detect_prison_single
      cell = @cells.find { |candidate| !candidate.v && candidate.valurest == 1 }
      { technique: :prison_single, cell_id: cell.c, value: cell.ability.first } if cell
    end

    # 検出した候補をセルの確定として適用する。
    def apply_prison_single(move)
      applied = @cells[move[:cell_id]].set(move[:value], 'PrisonSingle')
      raise 'detected PrisonSingle could not be applied' unless applied
    end
  end
end
