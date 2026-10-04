# frozen_string_literal: true

module Number
  # 解法
  module ResolvReserv
    ###########################################################
    # 予約席
    # あるgroupで 値  v1,v2,,,vn がr入り得るcellがN個だけだったら、
    # それらの cell にはn他の値は入れない ⇒ 削除対象
    # その数字は他のcellには入らない
    # 似た概念 座敷牢 の方に違いを詳説
    def reserv(v_num)
      @call_count["reserv#{v_num}"] += 1
      moves = []
      while (move = detect_reserv(v_num))
        apply_reserv(move, v_num)
        @count["reserv#{v_num}"] += 1
        moves << move
      end

      return '' if moves.empty?

      details = moves.map { |move| "cells:#{move[:cells]}, values:#{move[:values]}" }
      "reserv(#{v_num}): #{details.join('; ')}"
    end

    # 予約席の対象を検出する。盤面と処理済み記録は変更しない。
    def detect_reserv(v_num)
      # group において、可能性ある cell が v_num個以下の数字を探す
      # それらのcellに他の数字の可能性が有ってもよい。
      # それらの v_num個のcombinationのうち、
      # cell数が v_num 個であるものを得る
      # それらの cell ではそれらの値以外ははいらない
      @groups.each do |group|
        candidate = candidate_reserved_set(v_num, group)
        next unless candidate

        values, reserved_cells, ability_combination = candidate
        return { group_id: group.g, values: values, cells: reserved_cells,
                 ability_combination: ability_combination }
      end
      nil
    end

    # 検出した予約席を適用し、対象セルから他の候補を削除する。
    def apply_reserv(move, v_num)
      rm_value = values_to_rm(move[:cells], move[:values])
      move[:cells].each do |cell_id|
        msg = "reserve#{v_num} group #{move[:group_id]} cells#{move[:cells]} v=#{move[:values]}"
        @cells[cell_id].rm_ability(rm_value, msg)
      end
      prison_done[v_num] << move[:cells]
    end
    # rubocop: enable Lint/UnreachableLoop

    # reserve の対象となる cell set の候補
    def candidate_reserved_set(v_num, group)
      # all_set = group.ability.combination_of_ability_of_rest_is_less_or_equal(v_num).map do |abl_cmb|
      #   values, reserved_cells = sum_of_cells_and_values(abl_cmb)
      #   [values, reserved_cells, abl_cmb]
      # end
      # all_set.select do |values, reserved_cells, _abl_cmb|
      #   !prison_done?(v_num, reserved_cells) && values_to_rm(reserved_cells, values).size.positive?
      # end
      group.ability.each_combination_of_ability_of_rest_is_less_or_equal(v_num) do |abl_cmb|
        values, reserved_cells = sum_of_cells_and_values(abl_cmb)
        next if prison_done?(v_num, reserved_cells)
        next unless values_to_rm(reserved_cells, values).size.positive?

        return [values, reserved_cells, abl_cmb]
      end
      nil
    end

    # abilitys :: [ [grp_ability, grp_abirity], [], , ,]
    #  => [[val1, val2], [[1,2], [3, 4, 5] ]
    def sum_of_cells_and_values(abilitys)
      abilitys.each_with_object([[], []]) do |ac, vc| # ac = [ count,[cells],value]
        vc[0] << ac.v # [2]  # value
        vc[1] |= ac.cell_ids # [1]  # cell
      end
    end

    def values_to_rm(reserved_cells, values)
      (reserved_cells.map { |c| @cells[c].ability }.flatten.uniq - values)
    end
  end
end
