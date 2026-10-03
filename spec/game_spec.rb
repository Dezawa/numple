# frozen_string_literal: true

require_relative '../number/game'
require 'stringio'

RSpec.describe Number::Game do
  let(:puzzle) { "123......\n" + (".........\n" * 8) }

  describe '.create' do
    it 'builds 81 cells and 27 standard groups from a 9 header' do
      game = described_class.create(StringIO.new("# puzzle\n9\n#{puzzle}"))

      expect(game.cells.size).to eq 81
      expect(game.groups.size).to eq 27
      expect(game.cells.map(&:v)).to eq [1, 2, 3] + [nil] * 78
      expect(game.cells[0].group_ids).to eq [0, 9, 18]
      expect(game.cells[3].group_ids).to eq [0, 12, 19]
      expect(game.cells[3].ability).to eq [4, 5, 6, 7, 8, 9]
    end

    it 'accepts a standard Sudoku declaration' do
      expect { described_class.create(StringIO.new("STD\n#{puzzle}")) }.not_to raise_error
    end

    it 'requires -9 mode for headerless puzzle data' do
      game = described_class.create(StringIO.new(puzzle), option: { nine: true })
      expect(game.cells.first.v).to eq 1
    end

    it 'rejects nonstandard board declarations' do
      expect { described_class.create(StringIO.new("6x6\n#{puzzle}")) }
        .to raise_error(ArgumentError, /only standard 9x9 Sudoku/)
      expect { described_class.create(StringIO.new("9 ARROW\n#{puzzle}")) }
        .to raise_error(ArgumentError, /only standard 9x9 Sudoku/)
    end
  end

  it 'solves the existing standard 9x9 sample to the same answer' do
    game = described_class.create(File.open('./sample/np101001'), option: { nine: true })
    game.resolve
    expected = '876159423321487965945326187452978631638241759719635842594762318183594276267813594'
    expect(game.cells.map(&:v).join).to eq expected
  end

  it 'formats an 81-cell board as nine rows' do
    game = described_class.create(StringIO.new("9\n#{puzzle}"))
    expect(game.output_form.lines.size).to eq 9
    expect(game.output_form.lines.first.chomp).to eq '123...... '
  end
end
