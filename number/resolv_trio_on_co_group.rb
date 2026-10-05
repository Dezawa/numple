# frozen_string_literal: true

module Number
  # 解法
  module ResolvTrioOnCoGroup
    # prison(2,3)と等価?
    def trio_on_co_group
      @call_count["trio_on_co_group"] += 1
      moves = []
      while (move = detect_trio_on_co_group)
        apply_trio_on_co_group(move)
        @count["trio_on_co_group"] += 1
        moves << move
      end
      return '' if moves.empty?

      moves.map do |move|
        "## trio_on_co_group:group #{move[:group_id]} V=#{move[:value]} cells=#{move[:cells].join(',')}"
      end.join('; ')
    end

    # TrioOnCoGroupの対象を検出する。検出中に盤面は変更しない。
    def detect_trio_on_co_group
      @groups.each do |grp|
        (1..Number::Game::SIZE).each do |v|
          cnt = grp.ability[v].rest
          next unless cnt > 1 && cnt < 4 ## -> 1.

          # 値vの可能性をもつcellを得る
          w = grp.ability[v].cell_ids
          # これと同じcellを全て含むグループを探す
          cogroup(w).each do |g|
            grp0 = @groups[g]
            # 適用時に実際に候補を削除できる対象だけ返す。
            next unless (grp0.ability[v].cell_ids - w).any?

            return { group_id: grp.g, target_group_id: g, value: v, cells: w.dup }
          end
        end
      end
      nil
    end

    # 検出したTrioOnCoGroupを適用し、共有セル以外から候補を削除する。
    def apply_trio_on_co_group(move)
      msg = "## trio_on_co_group:group #{move[:group_id]} V=#{move[:value]} cells=#{move[:cells].join(',')}"
      removed = @groups[move[:target_group_id]].rm_ability(move[:value], move[:cells], msg)
      raise 'detected TrioOnCoGroup could not be applied' unless removed
    end
  end
end
