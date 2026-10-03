# frozen_string_literal: true

module Number
  # Candidate locations for each digit in one standard Sudoku group.
  class GroupAbilities
    SIZE = 9

    attr_accessor :ability

    def initialize
      @ability = []
    end

    def setup_initial(cell_ids)
      (1..SIZE).each { |v| @ability[v] = Number::GroupAbility.new(cell_ids.dup, v) }
    end

    def rm_cell_ability(values, cell_no, _msg = nil)
      values.each { |v| @ability[v].rm_cell_ability(cell_no) }
    end

    def fixed_by_rest_one
      @ability[1..].select { |abl| abl.rest == 1 }
    end

    def combination_of_ability_of_rest_is_less_or_equal(v_num)
      @ability[1..].select { |abl| abl.rest <= v_num && abl.rest > 1 }
              .combination(v_num)
              .select { |abl_cmb| abl_cmb.inject([]) { |cells, abl| cells | abl.cell_ids }.size == v_num }
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

  class GroupAbility
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
