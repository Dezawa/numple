# frozen_string_literal: true

require_relative './resolv_reserv'
require_relative './resolv_curb'
require_relative './resolv_prison'
require_relative './resolv_prison_single'
require_relative './resolv_reserve_single'
require_relative './resolv_trio_on_co_group'
require_relative './resolv_cross'
require_relative './resolv_xy_wing'
module Number
  # 解法
  module Resolver
    include ResolvReserv
    include ResolvCurb
    include ResolvPrison
    include ResolvPrisonSingle
    include ResolvReserveSingle
    include ResolvTrioOnCoGroup
    include ResolvCross
    include ResolvXyWing

    RESOLVE_PATH =
      [[:rest_one],
       [:reserv, 2],
       [:prison, 2],
       # [:optional_test],
       [:reserv, 3],
       [:prison, 3],
       [:reserv, 4],
       # [:prison, 4],
       [:trio_on_co_group],
       [:cross_teiin],
       [:xy_wing],
       # [:curb]
      ].freeze
    RESOLVE_KEY = RESOLVE_PATH.map{|k,v| "#{k}#{v}" }.to_a
    
    def resolve
      @try_count = 400
      # self.rest_one
      sw = true
      while !fill? && (sw || @try_count.positive?)
        sw = nil
        RESOLVE_PATH.each do |method, arg|
          msg = arg ? send(method, arg) : send(method)
          next if msg.to_s.empty?

          print " #{method}(#{arg}):#{msg}\n" if option[:verb]
          # アクションが有ったら、易しい解法に戻る
          break
        end

        # puts count
        @try_count -= 1
      end
      fill?
    end

    # Cell達に共通なGroup
    # cell_ids :: Cell#c
    # 戻り値 :: [group_id, group_id, , ,] まあ有っても最大4つ。
    def cogroup(cell_ids)
      return [] if cell_ids.empty?

      cell_ids[1..].inject(@cells[cell_ids[0]].group_ids) { |groups, c| groups & @cells[c].group_ids }
    end

    # Group達に共通なCell
    # group_ids :: Group#g
    # 戻り値 :: [cell_id, cell_id, , ]
    def cocell(group_ids)
      return [] if group_ids.size < 2

      group_ids[1..].inject(groups[group_ids[0]].cell_ids) { |cells, group_id| cells & groups[group_id].cell_ids }
    end

    # 全て埋まったら true
    def fill?
      @cells.select { |cell| cell.v.nil? }.empty?
    end

    # option -g のときに Groupの状態を印刷
    def gout
      pp( # .ability.map { |abl| [grp.g, abl] if (abl[0]).positive? }.compact })
        groups.map do |grp|
          ["Group #{grp.g}:", grp.cell_ids]
        end
      )
    end

    # option -c のときに 埋まっていないCellの残ってる可能性を印刷
    def cout
      @cells.each { |cell| puts "#{cell.c} : #{cell.ability}" unless cell.v }
    end

    ##### 解への技 #########
    # PrisonSingle と ReserveSingle を検出・適用する。
    # 検出メソッドは盤面を変更せず、適用メソッドだけが値を確定する。
    def rest_one
      @call_count["rest_one"] += 1
      cells = []
      loop do
        # 旧 rest_one と同じく、セル候補が一つのものを先に確定する。
        move = detect_prison_single || detect_reserve_single
        break unless move

        apply_single_move(move)
        cells << move[:cell_id]
      end

      cells.empty? ? '' : " rest_one cells=#{cells}"
    end

    # 検出結果に対応するSingle技を適用する。
    def apply_single_move(move)
      case move[:technique]
      when :prison_single
        apply_prison_single(move)
      when :reserve_single
        apply_reserve_single(move)
      end
    end

    def prison_done
      @prison_done ||= Hash.new { |h, k| h[k] = [] }
    end

    def prison_done?(v_num, cells)
      prison_done[v_num].include? cells
    end

    def not_fill
      ret = nil
      (1..@cells.size - 1).each { |c| @cells[c].ability[0].zero? && ret = true }
      ret
    end

    def fail
      @cells[1..].inject([]) { |values, cell| values | cell.ability }.size.positive?
    end

    ########################### 上級モード Level-1
    # cross_teiin(X-wing)、 座敷牢、予約席、curb はくくりだしてある
    # curb はひねり出したが使われていない感
    # xy-wing は実装していないが、これもなくても行けてる
    ##########################
    ##########################
  end
end
