# frozen_string_literal: true

module Number
  # グループ内で候補位置が一つだけの数字を確定する ReserveSingle。
  module ResolvReserveSingle
    # ReserveSingleを検出する。検出中に盤面は変更しない。
    def detect_reserve_single
      @groups.each do |group|
        ability = group.ability.fixed_by_rest_one.find do |candidate|
          cell = @cells[candidate.cell_ids.first]
          cell && !cell.v
        end
        return { technique: :reserve_single, cell_id: ability.cell_ids.first,
                 value: ability.v, group_id: group.g } if ability
      end
      nil
    end

    # 検出した候補をセルの確定として適用する。
    def apply_reserve_single(move)
      cell = @cells[move[:cell_id]]
      applied = cell.set(move[:value], "grp(#{move[:group_id]}).ReserveSingle")
      raise 'detected ReserveSingle could not be applied' unless applied

      @count[:Group_ability_is_rest_one] += 1
    end
  end
end
