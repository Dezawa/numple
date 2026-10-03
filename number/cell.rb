# frozen_string_literal: true

module Number
  # A cell in a standard 9x9 Sudoku.
  class Cell
    SIZE = 9

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
      @ability = (1..SIZE).to_a
      @valu = nil
      @groups = @game.groups
      self
    end

    def assign_valu(val)
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
      @ability.size
    end

    def vlist
      @valu ? [@valu] : @ability
    end

    def set_if_valurest_equal_one
      return nil unless valurest == 1 && !v

      set(ability[0])
    end

    def set(val, msg = 'rest_one')
      @count['Cell_ability is rest one'] += 1
      @count['rest_one'] += 1
      set_cell(val, msg)
    end

    def set_cell(val, msg = 'rest one')
      return nil if @valu || val && !@ability.include?(val)

      printf "Set cell %2d = %2d. by #{msg} \n", @c, val if option[:verb]
      @valu = val
      msg = "#{msg} : cell #{@c}"
      rm_cell_ability_from_groups_of_group_list(@ability)
      @ability = []
      @group_ids.each { |grp| @groups[grp].rm_ability(val, [@c], msg) }
    end

    def rm_ability(rm_value, msg = '')
      vv = [rm_value].flatten(1)
      v_remove = vv & @ability
      return unless v_remove.size.positive?

      print " rm_ability cell #{@c} v=[#{v_remove.join(',')}]. by #{msg}\n" if option[:verb]
      @gsw = true
      @ability -= v_remove
      rm_cell_ability_from_groups_of_group_list(v_remove)
      true
    end

    def rm_cell_ability_from_groups_of_group_list(v_remove, msg = nil)
      @group_ids.each { |grp| @groups[grp].rm_cell_ability(v_remove, c, msg) }
    end
  end
end
