# frozen_string_literal: true

module Number
  # A row, column, or 3x3 box.
  class Group
    # atrivuteは行・列・ブロックの種別、cell_idsは所属セル番号。
    attr_accessor :game, :g, :ability, :cell_ids, :atrivute, :count

    def initialize(arg_game, arg_gnr, count, atr = [])
      @game = arg_game
      @g = arg_gnr
      @ability = Number::GroupAbilities.new
      @cell_ids = []
      @atrivute = atr
      @count = count
    end

    def inspect
      g_atrivute_cell_ids = %i[g atrivute cell_ids].map { |sym| "  @#{sym}=#{send(sym).inspect}" }.join
      ability = @ability.ability.map { |abl| "         #{abl.inspect}" }.join("\n")
      "#<Group:#{object_id} #{g_atrivute_cell_ids}\n  @ability=[\n#{ability}"
    end

    def holizontal?
      atrivute == :holizontal
    end

    def vertical?
      atrivute == :vertical
    end

    def block?
      atrivute == :block
    end

    def cells
      # 保持しているセル番号からGame内のCellを得る。
      cell_ids.map { |c_no| game.cells[c_no] }
    end

    def co_cell_ids(pair_grp)
      # このグループとpair_grpの両方に属するセル。
      cell_ids & pair_grp.cell_ids
    end

    def cell_ids_avility_le_than(v_num)
      # 予約席・座敷牢の候補となるセルを抽出する。
      cell_ids.select { |c_no| (1..v_num).include?(game.cells[c_no].valurest) }
    end

    def type
      @atrivute
    end

    def addcell_ids(cell_id)
      @cell_ids << cell_id
    end

    def line_groups_join_with
      # このグループのセルと交差する行・列グループ。
      cell_ids.inject([]) { |g_nrs, c| g_nrs | @game.cells[c].group_ids } - [g]
    end

    def block_groups_join_with
      # このグループのセルが属する3x3ブロック。
      cell_ids.inject([]) { |g_nrs, c| g_nrs << @game.cells[c].group_ids[2] }.uniq
    end

    def rm_cell_ability(values, cell_no, msg = nil)
      @ability.rm_cell_ability(values, cell_no, msg)
    end

    def set_cell_if_some_value_s_ability_is_rest_one
      # グループ内で置ける場所が一つだけの数字を確定する。
      cells = []
      @ability.fixed_by_rest_one.each do |group_ability|
        next unless @game.cells[group_ability.cell_ids.first]
        next unless @game.cells[group_ability.cell_ids.first].set(
          group_ability.v, "grp(#{g}).ability #{group_ability.cell_ids}"
        )

        game.count[:Group_ability_is_rest_one] += 1
        game.count['rest_one'] += 1
        cells += group_ability.cell_ids
      end
      cells
    end

    def rm_ability(rm_value, except_cells = [], msg = '')
      # 指定したセルを除き、このグループのセルから数字候補を取り除く。
      rm_value = [rm_value].flatten
      rm_cells = @cell_ids - except_cells
      ret = nil
      rm_cells.each do |c0|
        if (@game.cells[c0].ability & rm_value).size.positive?
          @game.cells[c0].rm_ability(rm_value, msg)
          ret = true
        end
      end
      ret
    end
  end
end
