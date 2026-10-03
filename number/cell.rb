# frozen_string_literal: true

module Number
  # A cell in a standard 9x9 Sudoku.
  class Cell
    SIZE = 9

    # group_idsは行、列、3x3ブロックの順。
    attr_accessor :game, :groups, :valu, :c, :ability, :group_ids, :option

    def self.create(arg_game, cell_no, arg_group_ids, count, option: {})
      new(arg_game, cell_no, arg_group_ids, count, option: option).setup
    end

    def initialize(arg_game, cell_no, arg_group_ids, count, option: {})
      @game = arg_game
      @c = cell_no
      @group_ids = arg_group_ids
      @count = count
      @option = option
    end

    def setup
      # 初期状態では1〜9すべてが候補。値を確定すると同じグループから除く。
      @ability = (1..SIZE).to_a
      @valu = nil
      @groups = @game.groups
      self
    end

    def assign_valu(val)
      # 数字以外は未確定セルとして扱う。
      set_cell(val.to_i, 'initialize') if /\A\d/ =~ val
    end

    def inspect
      super + %i[c valu group_ids ability].map { |sym| "  @#{sym}=#{send(sym).inspect}" }.join
    end

    def v
      @valu
    end

    def fill?
      !!valu
    end

    def valurest
      # このセルに残っている候補数字の数。
      @ability.size
    end

    def vlist
      # 確定済みなら値を、未確定なら候補一覧を返す。
      @valu ? [@valu] : @ability
    end

    def set_if_valurest_equal_one
      # 候補が一つだけのセルを確定する。
      return nil unless valurest == 1 && !v

      set(ability[0])
    end

    def set(val, msg = 'rest_one')
      # 確定前に「候補が一つ」の解法回数を記録する。
      @count['Cell_ability is rest one'] += 1
      @count['rest_one'] += 1
      set_cell(val, msg)
    end

    def set_cell(val, msg = 'rest one')
      return nil if @valu || val && !@ability.include?(val)

      printf "Set cell %2d = %2d. by #{msg} \n", @c, val if option[:verb]
      @valu = val
      msg = "#{msg} : cell #{@c}"
      # 所属グループで、このセルを各数字の候補位置から取り除く。
      rm_cell_ability_from_groups_of_group_list(@ability)
      @ability = []
      # 確定した数字を、所属グループの他のセルの候補から除く。
      @group_ids.each { |grp| @groups[grp].rm_ability(val, [@c], msg) }
    end

    def rm_ability(rm_value, msg = '')
      vv = [rm_value].flatten(1)
      v_remove = vv & @ability
      return unless v_remove.size.positive?

      print " rm_ability cell #{@c} v=[#{v_remove.join(',')}]. by #{msg}\n" if option[:verb]
      @gsw = true
      @ability -= v_remove
      # セルの候補削除をグループ側の候補位置にも反映する。
      rm_cell_ability_from_groups_of_group_list(v_remove)
      true
    end

    def rm_cell_ability_from_groups_of_group_list(v_remove, msg = nil)
      @group_ids.each { |grp| @groups[grp].rm_cell_ability(v_remove, c, msg) }
    end
  end
end
