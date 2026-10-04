# frozen_string_literal: true

module Number
  # グループ内で各数字を置けるセルを管理する。
  class GroupAbilities
    SIZE = 9

    attr_accessor :ability

    def initialize
      @ability = []
    end

    def setup_initial(cell_ids)
      # 初期状態では、各数字をグループ内の全セルに置ける。
      (1..SIZE).each { |v| @ability[v] = Number::GroupAbility.new(cell_ids.dup, v) }
    end

    def rm_cell_ability(values, cell_no, _msg = nil)
      values.each { |v| @ability[v].rm_cell_ability(cell_no) }
    end

    def fixed_by_rest_one
      @ability[1..].select { |abl| abl.rest == 1 }
    end

    def combination_of_ability_of_rest_is_less_or_equal(v_num)
      each_combination_of_ability_of_rest_is_less_or_equal(v_num).to_a
    end

    # 条件に合う組み合わせを一つずつ返す。
    def each_combination_of_ability_of_rest_is_less_or_equal(v_num)
      return enum_for(__method__, v_num) unless block_given?

      # v_num個の数字の候補位置が、合計v_num個のセルに収まる組み合わせを探す。
      # 該当セルには、それらの数字だけを置ける。
      abilities = @ability[1..].select { |abl| abl.rest <= v_num && abl.rest > 1 }
      abilities.combination(v_num) do |ability_combination|
        cells = ability_combination.inject([]) { |cell_ids, ability| cell_ids | ability.cell_ids }
        yield ability_combination if cells.size == v_num
      end
    end

    def [](idx)
      @ability[idx]
    end

    def []=(idx, val)
      @ability[idx] = val
    end

    def dump
      ability[1..].map(&:dump)
    end

    def dup
      ablty = clone
      ablty.ability[1..].each { |abl| abl.cell_ids = abl.cell_ids.dup }
      ablty
    end
  end

  # あるグループにおける、ある数字の候補位置。
  class GroupAbility
    # restは、数字vを置けるセルの数。
    attr_accessor :rest, :cell_ids, :v

    def initialize(arg_cell_ids, arg_v)
      @cell_ids = arg_cell_ids
      @rest = arg_cell_ids.size
      @v = arg_v
    end

    def rm_cell_ability(cell_no, msg = nil)
      return unless cell_ids.delete(cell_no)

      @rest -= 1
      puts msg if msg
    end

    def inspect
      "GroupAbility:[rest:#{rest},cells:[#{cell_ids.join(',')}],v:#{v}]"
    end

    def dump
      [rest, cell_ids, v]
    end
  end
end
