# frozen_string_literal: true

require_relative '../number/game'

RSpec.describe Number::Game, type: :model do
  let(:game) { Number::Game.new }

  before do
    game.structure
    set_group_candidates(0, 5, [1, 4])
    set_group_candidates(3, 5, [28, 31])
  end

  def set_group_candidates(group_id, value, cell_ids)
    ability = game.groups[group_id].ability[value]
    ability.cell_ids = cell_ids.dup
    ability.rest = cell_ids.size
  end

  describe 'cross_teiin detection and application' do
    it 'detects an X-wing without changing the board' do
      original_abilities = game.cells.map { |cell| cell.ability.dup }

      move = game.detect_cross_teiin

      expect(move).to include(value: 5, source_group_ids: [0, 3],
                              target_group_ids: [10, 13], pattern_cells: [1, 4, 28, 31])
      expect(game.cells.map(&:ability)).to eq(original_abilities)
    end

    it 'applies the detected move to the intersecting columns' do
      move = game.detect_cross_teiin

      game.apply_cross_teiin(move)

      [1, 4, 28, 31].each { |cell_id| expect(game.cells[cell_id].ability).to include(5) }
      expect(game.cells[10].ability).not_to include(5)
      expect(game.cells[13].ability).not_to include(5)
      expect(game.option[:gsw]).to be(true)
    end

    it 'keeps cross_teiin as the detect-and-apply entry point' do
      message = game.cross_teiin

      expect(message).to eq('cross_teiin')
      expect(game.cells[10].ability).not_to include(5)
      expect(game.count['cross_teiin']).to be_positive
      expect(game.call_count['cross_teiin']).to eq(2)
    end

    it 'skips an applied pattern and detects another pattern for the same value' do
      set_group_candidates(1, 5, [15, 16])
      set_group_candidates(4, 5, [42, 43])

      first_move = game.detect_cross_teiin
      game.apply_cross_teiin(first_move)
      second_move = game.detect_cross_teiin

      expect(first_move[:source_group_ids]).to eq([0, 3])
      expect(game.cross_done).to include(game.cross_done_key(first_move))
      expect(second_move).to include(value: 5, source_group_ids: [1, 4],
                                     target_group_ids: [15, 16])
    end
  end
end
