# frozen_string_literal: true

require_relative '../number/game'

RSpec.describe Number::Game, type: :model do
  let(:game) { Number::Game.new }

  before do
    game.structure
  end

  def set_group_candidates(group_id, value, cell_ids)
    ability = game.groups[group_id].ability[value]
    ability.cell_ids = cell_ids.dup
    ability.rest = cell_ids.size
  end

  describe 'TrioOnCoGroup detection and application' do
    it 'detects a move without changing the board' do
      set_group_candidates(0, 5, [0, 1])
      original_abilities = game.cells.map { |cell| cell.ability.dup }

      move = game.detect_trio_on_co_group

      expect(move).to eq(group_id: 0, target_group_id: 18, value: 5, cells: [0, 1])
      expect(game.cells.map(&:ability)).to eq(original_abilities)
    end

    it 'applies the detected move to cells outside the shared set' do
      set_group_candidates(0, 5, [0, 1])

      move = game.detect_trio_on_co_group
      game.apply_trio_on_co_group(move)

      expect(game.cells[0].ability).to include(5)
      expect(game.cells[1].ability).to include(5)
      expect(game.cells[2].ability).not_to include(5)
      expect(game.cells[9].ability).not_to include(5)
    end

    it 'applies moves for multiple source groups in one call' do
      set_group_candidates(0, 1, [0, 1])
      set_group_candidates(1, 2, [9, 10])

      message = game.trio_on_co_group

      expect(message).to include('group 0 V=1', 'group 1 V=2')
      expect(game.cells[2].ability).not_to include(1)
      expect(game.cells[11].ability).not_to include(2)
      expect(game.count['trio_on_co_group']).to eq(2)
    end
  end
end
