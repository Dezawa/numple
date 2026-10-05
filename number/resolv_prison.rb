# frozen_string_literal: true

module Number
  # 解法
  module ResolvPrison
    ########
    # 座敷牢
    # N個のcellには v1,v2,,,vn なるN種の数字しか入らないとき、
    # これらのcellが属するgroupの他のcell には　v1,v2,,,は入らない
    # この数字が N個以外のcellに可能性が有ってもよい。それは削除対象
    #
    # 世の中では 指定席 と呼ばれているが、これには２種ある。
    # CASE-1
    # 　　cell 12,13 には 数字1,2 しか入らない。
    # 　　　　つまり cell 12,13 には 3〜9は入れない
    # 　　　　  　　　　数字1,2は 他のcellに入る可能性は残っている
    # CASE-2
    # 　　数字1,2はcell 12,13にしか入れない
    # 　　　　つまり cell 12,13には3〜9は入る可能性は残っている
    # 　　　　　　　　　　数字]1,2は他には入れない
    # いずれも Cell 12,13 には 数字1,2が入ることになるのだが
    # CASE-1 は：1,2は他にも行けるのだが Cell12,13に閉じ込めておく ⇒ 座敷牢
    # CASE-2 は：3〜9には Cell12,13に入るのは遠慮していただく ⇒ 予約席
    # と区別することにした。
    # 人は(てか、私は) CASE-2を探すのは難しい。特に 3,4Cellになると
    ########
    ###########################################################
    def prison(v_num)
      @call_count["prison#{v_num}"] += 1
      moves = []
      while (move = detect_prison(v_num))
        apply_prison(move, v_num)
        @count["prison#{v_num}"] += 1
        moves << move
      end
      return '' if moves.empty?

      "prison(#{v_num}): [cells, values] #{moves}"
    end

    # 座敷牢の対象を一つ検出する。盤面と処理済み記録は変更しない。
    def detect_prison(v_num)
      @groups.each do |group|
        each_prisonable_cells(group, v_num) do |cell_ids, values|
          next if prison_done?(v_num, cell_ids)

          return [cell_ids, values]
        end
      end
      nil
    end

    # 検出した組み合わせを適用し、同じ対象の再処理を記録する。
    def apply_prison(move, v_num)
      rm_ability_of_other_cells([move], v_num)
    end

    # 座敷牢の候補組み合わせを一つずつ列挙する。
    def each_prisonable_cells(group, v_num)
      able_cells = group.cell_ids_avility_le_than(v_num)
      able_cells.combination(v_num) do |cell_ids|
        values = cell_ids.flat_map { |cell_id| cells[cell_id].ability }.uniq
        yield cell_ids, values if values.size == v_num
      end
    end

    # このcellを含むgrpの 他のcellにあるｖの可能性を消す
    def rm_ability_of_other_cells(ret, v_num)
      ret.each do |cc, values|
        cogroup(cc).each do |grp0|
          msg = "prison#{v_num} grp #{grp0} val #{values} cells exept #{cc}"
          @groups[grp0].rm_ability(values, cc, msg)
        end
        prison_done[v_num] << cc
      end
    end

    # prison対象のcellの組み合わせを返す。
    # grp にて、
    # 可能性残り数が v_num個以下のcellの
    # v_num個の組み合わせの中で
    # 可能性数字種類が v_num個の組み合わせを返す。
    # それらの 数字が他のcellに有っても良い。それは可能性削除対象
    # 戻り値 :: [ [cell_ids, 数字list], [ ],,, ]
    def prisonable_cells(grp, v_num)
      # 数字残り可能性数 が v_num以下のcell
      able_cells = grp.cell_ids_avility_le_than(v_num)

      # それらの v_num個のcombinationのうち、数字種類がv_num個のもの
      # [ [cell_ids, valus], [ ],,]
      able_cells.combination(v_num).map do |cc|
        values = cc.map { |c| cells[c].ability }.flatten.uniq
        [cc, values] if values.size == v_num
      end.compact
    end
  end
end
