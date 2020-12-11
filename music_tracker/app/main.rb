require "lib/music_tracker/music_tracker.rb"

def tick args
  MusicTracker.instance_variable_set "@active", true if args.tick_count.zero?
  return if MusicTracker.tick args

  args.outputs.labels  << [640, 500, 'Hello World!', 5, 1]
  args.outputs.labels  << [640, 460, 'Go to docs/docs.html and read it!', 5, 1]
  args.outputs.labels  << [640, 420, "Join the Discord! http://discord.dragonruby.org", 5, 1]
  args.outputs.sprites << [576, 280, 128, 101, 'dragonruby.png']
end
