# frozen_string_literal: true

require_relative '../number/game'
require_relative '../number/cell'
require_relative '../number/group'
require_relative '../number/group_ability'

# rubocop: disable Metrics/BlockLength
RSpec.describe Number::Game, type: :model do
  let(:game) { Number::Game.new }
  let(:group) do
    grp = Number::Group.new(game, 9, [])
    grp.cell_ids = (10..18).to_a
    grp
  end
  let(:group_aiblilities) { Number::GroupAbilities.new }

  describe 'single detection and application' do
    before { game.structure }

    it 'detects PrisonSingle without changing the board, then applies it separately' do
      cell = game.cells[0]
      cell.ability = [5]

      move = game.detect_prison_single

      expect(move).to eq(technique: :prison_single, cell_id: 0, value: 5)
      expect(cell.v).to be_nil
      game.apply_prison_single(move)
      expect(cell.v).to eq(5)
    end

    it 'detects ReserveSingle without changing the board, then applies it separately' do
      group = game.groups[0]
      group.ability[5].cell_ids = [0]
      group.ability[5].rest = 1

      move = game.detect_reserve_single

      expect(move).to eq(technique: :reserve_single, cell_id: 0, value: 5, group_id: 0)
      expect(game.cells[0].v).to be_nil
      game.apply_reserve_single(move)
      expect(game.cells[0].v).to eq(5)
      expect(game.count[:Group_ability_is_rest_one]).to eq(1)
    end
  end

  describe 'Prison detection and application' do
    before do
      game.structure
      game.cells[0].ability = [1, 2]
      game.cells[1].ability = [1, 2]
    end

    it 'detects a multi-candidate Prison without changing the board or done list' do
      move = game.detect_prison(2)

      expect(move).to eq([[0, 1], [1, 2]])
      expect(game.cells[2].ability).to include(1, 2)
      expect(game.prison_done[2]).to be_empty
    end

    it 'applies a detected Prison by removing its candidates from peer cells' do
      move = game.detect_prison(2)

      game.apply_prison(move, 2)

      expect(game.cells[2].ability).not_to include(1, 2)
      expect(game.prison_done[2]).to include([0, 1])
    end
  end

  describe 'Prison loop' do
    before do
      game.structure
      game.cells[0].ability = [1, 2]
      game.cells[1].ability = [1, 2]
      game.cells[3].ability = [3, 4]
      game.cells[4].ability = [3, 4]
    end

    it 'applies each distinct Prison candidate before returning' do
      result = game.prison(2)

      expect(game.count['prison2']).to eq(2)
      expect(game.prison_done[2]).to include([0, 1], [3, 4])
      expect(result).to include('[[0, 1], [1, 2]]', '[[3, 4], [3, 4]]')
      expect(game.detect_prison(2)).to be_nil
    end
  end

  describe 'Reserve detection and application' do
    before do
      game.structure
      group = game.groups[0]
      [1, 2].each do |value|
        group.ability[value].cell_ids = [0, 1]
        group.ability[value].rest = 2
      end
      game.cells[0].ability = [1, 2, 3]
      game.cells[1].ability = [1, 2, 3]
    end

    it 'detects a multi-candidate Reserve without changing the board or done list' do
      move = game.detect_reserv(2)

      expect(move).to include(group_id: 0, values: [1, 2], cells: [0, 1])
      expect(game.cells[0].ability).to include(3)
      expect(game.prison_done[2]).to be_empty
    end

    it 'applies a detected Reserve by removing other candidates from its cells' do
      move = game.detect_reserv(2)

      game.apply_reserv(move, 2)

      expect(game.cells[0].ability).to eq([1, 2])
      expect(game.cells[1].ability).to eq([1, 2])
      expect(game.prison_done[2]).to include([0, 1])
    end
  end

  describe :prison do
    let(:cell_abilities_for_prison) do
      # cell 10,11,12には1,2,3のみが有る。cell 13,14 には4,5のみが有る。
      # これらcellには他の数字はない
      # この数字は他のcellにもある
      [[1, 2, 3], [1, 2], [2, 3], [4, 5], [4, 5]] + # cell 10~14の可能性数字
        [[1, 6, 7, 8], [4, 6, 7, 8, 9], [1, 4, 7, 9], [1, 2, 3, 7, 9]]
    end
    let(:cells) do
      [nil] * 10 +
        cell_abilities_for_prison.map.with_index(10) do |ability, cell_no|
          cell = Number::Cell.new(game, cell_no, group, [])
          cell.ability = ability
          cell
        end
    end

    before do
      game.cells = cells
      group.cell_ids = (10..18).to_a
    end

    it '座敷牢2' do
      expect(game.prisonable_cells(group, 2)).to eq [[[13, 14], [4, 5]]]
    end
  end

  let(:abilities_for_reserv) do
    # cell 10,11,12には1,2,3が有る。cell 13,14 には4,5が有る。
    # cell 15,16 には 6,7 がある
    # これらの数字は他のcellにはない
    # 他の数字はこれらのcellにもある
    # 数字１のあるcell、数字2の、数字3の、
    [[10, 11, 12], [11, 12], [10, 12]] +
      [[13, 14], [13, 14]] + # 数字 4, 5のあるcell
      [[15, 16], [15, 16]] + # 数字6, 7のあるcell
      [[13, 17], [10, 13, 18]] # 数字 8, 9のあるcell
  end
  let(:cell_abilities) do
    cell_ability = Hash.new { |h, k| h[k] = [] }
    abilities_for_reserv.map.with_index(1) do |cells, val|
      cells.each { |cell| cell_ability[cell] << val }
    end
    cell_ability
  end
  let(:cells) do
    # pp [:cell_abilities,cell_abilities]
    [nil] * 10 +
      cell_abilities.map.with_index(10) do |_ability, cell_no|
        cell = Number::Cell.new(game, cell_no, group, [])
        cell.ability = cell_abilities[cell_no]
        cell
      end
  end

  let(:ary_groupability) do
    abilities_for_reserv.map.with_index(1) do |ability, value|
      group_aiblilities.ability[value] =
        Number::GroupAbility.new(ability, value)
    end
  end

  let(:combo3) { ary_groupability[0, 3] }
  let(:combo2) { ary_groupability[3, 2] }
  let(:combo22) { ary_groupability[5, 2] }

  describe :reserv do
    context :candidate_reserved_set do
      before do
        game.cells = cells
        group.ability = Number::GroupAbilities.new
        group.ability.ability = ary_groupability
        allow(group.ability)
          .to receive(:each_combination_of_ability_of_rest_is_less_or_equal)
          .and_yield(combo2).and_yield(combo22)
        allow(game).to receive(:prison_done?).and_return(false)
      end

      it 'returns the first matching candidate set' do
        expect(game.candidate_reserved_set(2, group))
          .to eq [[4, 5], [13, 14], combo2]
      end
    end

    it 'applies every detected Reserve before returning' do
      first_move = { group_id: 1, values: [1, 2], cells: [10, 11] }
      second_move = { group_id: 2, values: [3, 4], cells: [20, 21] }
      allow(game).to receive(:detect_reserv).with(2).and_return(first_move, second_move, nil)
      allow(game).to receive(:apply_reserv)

      result = game.reserv(2)

      expect(game).to have_received(:apply_reserv).with(first_move, 2).ordered
      expect(game).to have_received(:apply_reserv).with(second_move, 2).ordered
      expect(game.count['reserv2']).to eq(2)
      expect(result).to eq('reserv(2): cells:[10, 11], values:[1, 2]; cells:[20, 21], values:[3, 4]')
    end
    context :sum_of_cells_and_values do
      it 'combo2 の時' do
        ret = game.sum_of_cells_and_values(combo2)
        expect(ret).to eq [[4, 5], [13, 14]]
      end
      it 'combo3 の時' do
        ret = game.sum_of_cells_and_values(combo3)
        expect(ret).to eq [[1, 2, 3], [10, 11, 12]]
      end
    end
  end
end
# rubocop: enable Metrics/BlockLength
__END__
  it '3個以下のcombintion。数字4,5がcell13,14にある' do
    abilities = group_aiblilities.combination_of_ability_of_rest_is_less_or_equal(3)
    expect(abilities.map{|ab| ab.map{|ablty| [ablty.cell_ids,ablty.v]}}).to match_array [[[[10,11,12],1], [[11,12],2], [[10,12],3]]]
  end
end
end
