# frozen_string_literal: true

module Number
  # X-wingと言われているらしい
  module ResolvCross
    # こういう関係で１があるとき、＊の位置に１があったらそれは削除
    # *.1..1..1
    # .........
    # .........
    # ..1.*1..1
    # .........
    # .........
    # ..1..1*.1
    # .........
    # .........
    #
    # (1) :holizontal なgroupについて、値vをとり得るcellの数が2または3のグループを集める
    #      grps1 = [ count, group ,[cells], [co_groups] ]  count <- cell数、co_?groups <- (2)
    # (2) そのcellを共有する:verticalなgroupを集める。[co_groups]
    # (3) それぞれのgrps1から2個または3個の組み合わせを作る
    # (4) co_groups のuniq がg_numsに等しい組み合わせを残す
    # 　　　複数のBOXな場合要吟味。重なる:block上に対象となるcellがあるという特殊な場合以外は行けるかも
    #
    # (5) このco_groupsから値vの可能性を削除する。except cells
    #
    # これを2個と3個について、:holizontal と :vertical を入れ替えて行う
    def cross_teiin
      @call_count['cross_teiin'] += 2 # holizontal vertical 各々１回
      moves = []
      while (move = detect_cross_teiin)
        apply_cross_teiin(move)
        @count['cross_teiin'] += 1
        moves << move
      end
      option[:cross] = nil
      moves.empty? ? '' : 'cross_teiin'
    end

    # cross_teiinの対象を検出する。検出中に盤面やoptionは変更しない。
    def detect_cross_teiin
      h_v_table = %i[holizontal vertical]
      # h_v
      h_v_table.each_with_index do |h_v, idx|
        v_h = h_v_table[1 - idx] # 　holizontal と :vertical について
        # value
        (1..Number::Game::SIZE).each do |v| # (1) 1~9の値vについて
          # (2) そのcellを共有する:verticalなgroupを集める。[co_groups]
          grps1 = groups_remain_2_or_m_cells_of_value_is(h_v, v_h, v)
          # [count, group, cells, co_groups]
          # (3) それぞれのcell grps1[2, g_nums]からg_nums個ずつの組み合わせを作る cmb_grp
          # g_nums
          (2..3).each do |g_nums|
            # combination
            grps1.select { |grp| grp[0] <= g_nums }
                 .combination(g_nums).each do |cmb_grp|
              # (4) co_groupsのuniqがg_numsに等しい組み合わせを残す
              rm_grps = cmb_grp.map { |grp| grp[3] }.flatten.uniq
              next unless rm_grps.size == g_nums

              except_cells = cmb_grp.flat_map { |group| group[2] }.uniq
              move = {
                value: v,
                source_group_ids: cmb_grp.map { |group| group[1].g },
                target_group_ids: rm_grps,
                except_cells: except_cells
              }
              # 適用済みの元グループの組み合わせは再検出しない。
              next if cross_done?(move)

              # (5) このco_groupsから値vの可能性を削除する。except cells
              # pp [v, cmb_grp[3]]
              next unless rm_grps.any? do |group_id|
                (@groups[group_id].ability[v].cell_ids - except_cells).any?
              end

              # return true
              return move
            end
          end
        end
      end
      nil
    end

    # 検出したcross_teiinを適用し、対象グループから候補を削除する。
    def apply_cross_teiin(move)
      applied = false
      # (5) 検出時に集めた共通グループから、except_cells以外の候補を削除する。
      move[:target_group_ids].each do |group_id|
        msg = "cross_teiin v=#{move[:value]}, grps=#{move[:source_group_ids].join(',')}"
        removed = @groups[group_id].rm_ability(move[:value], move[:except_cells], msg)
        next unless removed

        option[:gsw] = true
        applied = true
      end
      raise 'detected cross_teiin could not be applied' unless applied

      cross_done << cross_done_key(move)
    end

    # 適用した元パターンを記録し、次の検出で同じ組み合わせを飛ばす。
    def cross_done
      @cross_done ||= []
    end

    def cross_done?(move)
      cross_done.include?(cross_done_key(move))
    end

    def cross_done_key(move)
      [move[:value], move[:source_group_ids].dup, move[:target_group_ids].dup]
    end

    # 値 valu の可能性が2〜3残っている holizontalなgroupを探し
    def groups_remain_2_or_m_cells_of_value_is(h_v, v_h, valu)
      groups_remain = groups_remain_2_or_m_cells(h_v, valu)
      # (2) そのcellを共有する:verticalなgroupを集める。[co_groups]
      co_groups_of(groups_remain, v_h, valu)
    end

    # 値 valu の可能性が2〜3残っているgroupを探す
    def groups_remain_2_or_m_cells(h_v, valu)
      @groups.select do |grp|
        count = grp.ability[valu].rest
        (grp.type == h_v) && (2..3).include?(count) # 　　 :holizontal なgroupについて、
        #           (count <= 3) && # 値valu　をとり得るcellの数が2または3
        #           (count > 1) #      grp を集め
      end
    end

    def co_groups_of(groups_remain, v_h, valu)
      groups_remain.map do |grp|
        count = grp.ability[valu].rest
        cells = grp.ability[valu].cell_ids
        co_groups = cells.map { |c| cogroup([c]).select { |g| @groups[g].type == v_h }.flatten }
        [count, grp, cells, co_groups]
      end.compact
    end
  end
end
