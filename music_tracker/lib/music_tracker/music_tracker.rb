module MusicTracker
  @active = false

  # MAIN METHODS
  def self.tick args
    return unless inpt args
    updt args
    rndr args
    return true
  end

  def self.init args
    @current_song = 0
    @project = {
       tracks: {},
       songs: [
         { tempo: 120,
           rows: 16,
           order: [0] * 16,
           patterns: [],
           channels: [0, 0, 0, 0, 0, 0] }
       ]
     }

    @cursor = Cursor.new
    @cursor_highlight = [[0, 0, 0], [202, 101, 101]]

    @blocks = Blocks.new.tap do |blocks|
      blocks.set_row 0, "Music Tracker | Song: 0 | Tempo: #{@project[:songs][0][:tempo]} | Rows: #{@project[:songs][0][:rows]}"
      blocks.set_row 1, "Order: #{@project[:songs][0][:order].map { |i| "%02d" % i }.join(' ')}"
      blocks.set_row 2, "Pattern: %02d" % 0
      blocks.set_row 3, ["LN", 6.times.map { |i| "Track: #{"%02d" % @project[:songs][0][:channels][i]}".ljust(8) }, ''].join('|')
      24.times.map { |i| blocks.set_row 4 + i, get_row_text(i) }
    end

    @notes = %i[c c# d d# e f f# g g# a a# b]
    @frequencies = @notes.map.with_index { |s, i| [s, 440.0 * 2 ** ((i - 9) / 12)] }
                     .to_h
    @octave_mults = (0..8).map { |i| [i, 2 ** (i - 4)] }.to_h
    @note_keys = %i[z s x d c v g b h n j m q two w three e r five t six y seven u]
    @note_octave = 3
    @selected_instrument = 0

    @bg_color = [0, 0, 0]

    ranges = [[0,1], [2,2], [3,4], [5,5], [6,8]]
    colors = [ [174, 189, 56],
               [236, 150, 164],
               [104, 130, 158],
               [251, 101, 66],
               [76, 181, 245]]
    (4...@blocks.h).each do |row|
      6.times.each do |i|
        ranges.each_with_index do |(a, b), j|
          range = 3+a+10*i..3+b+10*i
          @blocks[row][range].each { |b| b.fg = colors[j] }
        end
      end
    end

    @blocks[0][0].fg_bg @cursor_highlight

    return true
  end

  def self.inpt args
    toggle if args.inputs.keyboard.char == '#'
    return unless @active
    @loaded ||= init args
    kd = args.inputs.keyboard.key_down
    ms = args.inputs.mouse

    # if args.inputs.keyboard.key_held.enter && args.tick_count % 6 == 0
    #   proc = lambda do
    #     frequency = frequency_for %i[c d e f g a b].sample, [3, 4, 5].sample
    #     sample_rate = 48000

    #     period_size = (sample_rate.fdiv frequency).ceil
    #     wave = period_size.map_with_index do |i|
    #       Math::sin((2.0 * Math::PI) / (sample_rate.to_f / frequency.to_f) * i)
    #     end.to_a

    #     sample_size = (sample_rate.fdiv (1000.fdiv 60)).floor
    #     copy_count  = (sample_size.fdiv wave.length).ceil
    #     wave * copy_count
    #   end

    #   args.audio[0] = {
    #     input: [1, 48000, proc.call],
    #     gain: 0.1,
    #     pitch: 1.0,
    #     looping: false,
    #     paused: false,
    #   }
    # end

    # ox, oy = @cursor.xy
    # @cursor.x += kd.left_right
    # @cursor.y -= kd.up_down
    # @cursor.x = @cursor.x.clamp(0, @blocks.w-1)
    # @cursor.y = @cursor.y.clamp(0, @blocks.h-1)

    # c = ms.click
    # if c && c.inside_rect?([0, 8, 640, 704])
    #   @cursor.x = (c.x / 10).floor
    #   @cursor.y = ((712-c.y) / 22).floor
    # end
    # x, y = @cursor.xy
    # if ox != x || oy != y
    #   @blocks[oy][ox].reset_fg_bg
    #   @blocks[y][x].fg_bg @cursor_highlight
    # end

    # return true if kd.control
    # i = @note_keys.find_index { |key| kd.send key }
    # puts tracker_note(note: @notes[i % @notes.length].to_s.ljust(2, '-'),
    #                   octave: (@note_octave + (i > @notes.length ? 1 : 0)).to_s,
    #                   instrument: "%02d" % @selected_instrument
    #                  ) if i

    return true
  end

  def self.updt args
    return
  end

  def self.rndr args
    args.outputs.background_color = @bg_color
    args.outputs.primitives << @blocks

    # args.outputs.debug << $gtk.current_framerate_primitives
    return
  end

  # MUSIC TRACKER
  def self.toggle
    @active = !@active
  end

  class Project
    # Project Structure
    # =================
    # { tracks: {},
    #   songs: [
    #     tempo: 120,
    #     rows: 16,
    #     order: [],
    #     patterns: [],
    #     channels: []]}
    # =================

    def initialize
      @path = 'lib/music_tracker/project.json'
      @project = load_project @path
    end

    def [] arg
      return @project[arg]
    end

    def project
      @project
    end

    def __obj_to_json__ obj, indent = 4
      case obj
      when Hash
        return "{}" if obj.empty?
        str = "{\n"
        str += obj.map { |k, v| "#{__obj_to_json__(k)}: #{__obj_to_json__(v)}" }.join(",\n")
        return "#{str.indent_lines(indent)}\n}"
      when Array
        return "[]" if obj.empty?
        str = "[\n"
        str += obj.map { |v| __obj_to_json__(v) }.join(",\n")
        return "#{str.indent_lines(indent)}\n]"
      when String, Symbol
        return obj.to_s.quote
      else
        return obj.to_s
      end
    end

    def save_project path, hash = @project
      $gtk.write_file path, __obj_to_json__(hash)
    end

    def load_project path
      hash = $gtk.parse_json_file path
      return hash if hash
      save_project path, ({ tracks: {},
                            songs: [
                              { tempo: 120,
                                rows: 16,
                                order: [0] * 16,
                                patterns: [],
                                channels: [0, 0, 0, 0, 0, 0] }
                            ]
                          })
      return load_project path
    end
  end

  # TRACKER
  def self.get_row_text row
    song = @project[:songs][@current_song]
    return '' if row > song[:rows]
    return ["%02d" % row, song[:channels].map { |i| @project[:tracks][i]&.[](row) || tracker_note }, '' ].join(row % 4 == 0 ? ':' : '|')
  end

  def self.tracker_note note: '--', octave: '-', instrument: '--', gain: '-', effect: '---'
    return "#{note}#{octave}#{instrument}#{gain}#{effect}"
  end

  # SOUND
  def self.frequency_for note, octave
    return @frequencies[note] * @octave_mults[octave]
  end

  # MISCELLANEOUS
  module RGBA
    def prev_rgba
      return @prev_rgba ||= rgba
    end

    def rgba
      return @r, @g, @b, @a
    end

    def rgba= arr
      @prev_rgba = rgba
      @r, @g, @b, @a = arr
    end
  end

  class Cursor
    attr :x, :y

    def initialize
      @x = 0; @y = 0
    end

    def xy
      return @x, @y
    end
  end

  class Label
    include RGBA
    attr :x, :y, :text,
         :size_enum, :alignment_enum,
         :r, :g, :b, :a,
         :font
    def primitive_marker; return :label end

    def initialize x:, y:, text:, se: 0, ae: 0, r: 255, g: 255, b: 255, font: nil
      @x = x; @y = y
      @text = text
      @size_enum = se
      @alignment_enum = ae
      @r = r; @g = g; @b = b
      @font = font
    end

    def draw_override ffi_draw
      return ffi_draw.draw_label @x, @y, @text, @alignment_enum, @size_enum, @r, @g, @b, @a, @font
    end
  end

  class Solid
    include RGBA
    attr :x, :y, :w, :h,
         :r, :g, :b, :a
    def primitive_marker; return :solid end

    def initialize x:, y:, w:, h:, r: 0, g: 0, b: 0
      @x = x; @y = y; @w = w; @h = h
      @r = r; @g = g; @b = b
      @a = nil
    end

    def draw_override ffi_draw
      return ffi_draw.draw_solid @x, @y, @w, @h, @r, @g, @b, @a
    end
  end

  class LabelBlock
    def primitive_marker; return :label end
    def initialize x:, y:, w:, h:, char:, fg: [225, 225, 225], bg: [15, 15, 15], font: nil
      @x = x; @y = y; @w = w; @h = h;
      @char = char
      @char_w = 10; @char_h = 22

      @solid = Solid.new x: x, y: y, w: w, h: h
      @label = Label.new x: x, y: y, text: char, font: font

      send :fg=, fg
      send :bg=, bg

      label_x
      label_y
    end

    def x= x
      @solid.x = @x = x
      label_x
    end

    def y= y
      @solid.y = @y = y
      label_y
    end

    def w= w
      @solid.w = @w = w
      label_x
    end

    def h= h
      @solid.h = @h = h
      label_y
    end

    def label_x
      @label.x = @x + @w.half - @char_w.half
    end

    def label_y
      @label.y = @y + @h.half + @char_h.half
    end

    def char= char
      @label.text = @char = char
    end

    def fg= arr
      @fg = arr
      @label.rgba = arr
    end

    def bg= arr
      @bg = arr
      @solid.rgba = arr
    end

    def fg_bg((arr1, arr2))
      send :fg=, arr1
      send :bg=, arr2
    end

    def reset_fg_bg
      send :fg=, @label.prev_rgba
      send :bg=, @solid.prev_rgba
    end

    def draw_override ffi_draw
      @solid.draw_override ffi_draw
      @label.draw_override ffi_draw if @char.length > 0
    end
  end

  class Blocks
    # FONT = 'lib/music_tracker/SourceCodePro-Regular.ttf'
    # FONT = 'lib/music_tracker/Hack-Regular.ttf'
    FONT = nil
    attr_reader :w, :h
    def primitive_marker; return :label end

    def initialize
      @w, @h = 64, 32
      @grid = @h.times.map do |i|
        [i, @w.times.map { |j| LabelBlock.new x: 10*j, y: 712 - 22 - 22*i, w: 10, h: 22, char: '', font: FONT }]
      end.to_h

      @renderables = @grid.values.flatten
    end

    def [] row
      return @grid[row]
    end

    def set_row_col row, col, text
      text.each_char.with_index do |char, i|
        break unless i < @w
        @grid[row][col + i].char = char
      end
    end

    def set_row row, text
      text.each_char.with_index do |char, i|
        break unless i < @w
        @grid[row][i].char = char
      end
    end

    def set_col col, text
      text.each_char.with_index do |char, i|
        break unless i < @h
        @grid[i][col].char = char
      end
    end

    def set_col_row col, row, text
      text.each_char.with_index do |char, i|
        break unless i < @h
        @grid[row + i][col].char = char
      end
    end

    def draw_override ffi_draw
      i = 0
      ilen = @renderables.length
      while i < ilen
        @renderables[i].draw_override ffi_draw
        i += 1
      end
    end
  end
end





# def tick args
#   args.state.sine_waves  ||= {}
#   args.state.audio_queue ||= []

#   process_audio_queue args

#   sender = { type: :sine, note: :c, octave: 4 }
#   play_note args, sender if args.inputs.keyboard.key_down.enter
# end

# def play_note args, sender
#   method_to_call = :queue_sine_wave

#   send method_to_call, args,
#        frequency: (frequency_for note: sender[:note], octave: sender[:octave]),
#        duration: 1.seconds,
#        fade_out: true
# end

# def queue_sine_wave args, opts = {}
#   opts        = defaults_queue_sine_wave.merge opts
#   frequency   = opts[:frequency]
#   sample_rate = 48000

#   sine_wave = sine_wave_for frequency: frequency, sample_rate: sample_rate
#   args.state.sine_waves[frequency] ||= sine_wave_for frequency: frequency, sample_rate: sample_rate

#   proc = lambda do
#     generate_audio_data args.state.sine_waves[frequency], sample_rate
#   end

#   audio_state = new_audio_state args, opts
#   audio_state[:input] = [1, sample_rate, proc]
#   queue_audio args, audio_state: audio_state, wave: sine_wave
# end

# def defaults_queue_sine_wave
#   { frequency: 440, duration: 60, gain: 1.0, fade_out: false, queue_in: 0 }
# end

# def sine_wave_for opts = {}
#   opts = defaults_sine_wave_for.merge opts
#   frequency   = opts[:frequency]
#   sample_rate = opts[:sample_rate]
#   period_size = (sample_rate.fdiv frequency).ceil
#   period_size.map_with_index do |i|
#     Math::sin((2.0 * Math::PI) / (sample_rate.to_f / frequency.to_f) * i)
#   end.to_a
# end

# def defaults_sine_wave_for
#   { frequency: 440, sample_rate: 48000 }
# end

# begin # region: musical note mapping
#   def defaults_frequency_for
#     { note: :a, octave: 5, sharp: false, flat: false }
#   end

#   def frequency_for opts = {}
#     opts = defaults_frequency_for.merge opts
#     octave_offset_multiplier  = opts[:octave] - 5
#     note = note_frequencies_octave_5[opts[:note]]
#     if octave_offset_multiplier < 0
#       note = note * 1 / (octave_offset_multiplier.abs + 1)
#     elsif octave_offset_multiplier > 0
#       note = note * (octave_offset_multiplier.abs + 1) / 1
#     end
#     note
#   end

#   def note_frequencies_octave_5
#     {
#       a: 440.0,
#       a_sharp: 466.16, b_flat: 466.16,
#       b: 493.88,
#       c: 523.25,
#       c_sharp: 554.37, d_flat: 587.33,
#       d: 587.33,
#       d_sharp: 622.25, e_flat: 659.25,
#       e: 659.25,
#       f: 698.25,
#       f_sharp: 739.99, g_flat: 739.99,
#       g: 783.99,
#       g_sharp: 830.61, a_flat: 830.61
#     }
#   end
# end

# def defaults_new_audio_state
#   { frequency: 440, duration: 60, gain: 1.0, fade_out: false, queue_in: 0 }
# end

# def new_audio_state args, opts = {}
#   opts        = defaults_new_audio_state.merge opts
#   decay_rate  = 0
#   decay_rate  = 1.fdiv(opts[:duration]) * opts[:gain] if opts[:fade_out]
#   frequency   = opts[:frequency]
#   sample_rate = 48000

#   {
#     id:               (new_id! args),
#     frequency:        frequency,
#     sample_rate:      48000,
#     stop_at:          args.tick_count + opts[:queue_in] + opts[:duration],
#     gain:             opts[:gain].to_f,
#     queue_at:         args.state.tick_count + opts[:queue_in],
#     decay_rate:       decay_rate,
#     pitch:            1.0,
#     looping:          true,
#     paused:           false
#   }
# end

# def new_id! args
#   args.state.audio_id ||= 0
#   args.state.audio_id  += 1
# end

# def queue_audio args, opts = {}
#   # graph_wave args, opts[:wave], opts[:audio_state][:frequency]
#   args.state.audio_queue << opts[:audio_state]
# end

# def generate_audio_data sine_wave, sample_rate
#   sample_size = (sample_rate.fdiv (1000.fdiv 60)).ceil
#   copy_count  = (sample_size.fdiv sine_wave.length).ceil
#   sine_wave * copy_count
# end

# def process_audio_queue args
#   to_queue = args.state.audio_queue.find_all { |v| v[:queue_at] <= args.tick_count }
#   args.state.audio_queue -= to_queue
#   to_queue.each { |a| args.audio[a[:id]] = a }

#   args.audio.find_all { |k, v| v[:decay_rate] }
#     .each     { |k, v| v[:gain] -= v[:decay_rate] }

#   sounds_to_stop = args.audio
#                      .find_all { |k, v| v[:stop_at] && args.state.tick_count >= v[:stop_at] }
#                      .map { |k, v| k }

#   sounds_to_stop.each { |k| args.audio.delete k }
# end
