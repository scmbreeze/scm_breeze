#!/usr/bin/env ruby
# encoding: UTF-8

PROJECT_ROOT = File.exist?(".git") ? Dir.pwd : `\git rev-parse --show-toplevel 2> /dev/null`.strip

COLORS = {
  :rst => "\033[0m",
  :del => "\033[0;31m",
  :mod => "\033[0;32m",
  :new => "\033[0;33m",
  :ren => "\033[0;34m",
  :cpy => "\033[0;33m",
  :typ => "\033[0;35m",
  :unt => "\033[0;36m",
  :dark => "\033[2;37m",
  :branch => "\033[1m",
  :header => "\033[0m"
}

COLOR_MATCH = /\e\[[0-9;]*[mK]/

output_files = []

stdin = STDIN.set_encoding(Encoding::ASCII_8BIT)

while stdin.gets
  if $. > 1000
    puts "Only showing first 1000 results. Please refine your search."
    break
  end
  print "#{COLORS[:dark]}[#{COLORS[:rst]}#{$.}#{COLORS[:dark]}]#{COLORS[:rst]} "
  matches = $_.match(/(^.+?)#{COLOR_MATCH}?:#{COLOR_MATCH}?(\d+)?/)
  file = matches[1]
  line = matches[2]
  output_files << "#{file}#{line ? ":#{line}" : ""}"
  puts $_
end

print "@@filelist@@::"

output_files.each_with_index {|f,i|
  # If file starts with a '~', treat it as a relative path.
  # This is important when dealing with symlinks
  print "|" unless i == 0
  print f.start_with?("~") ? f.sub(/~/, '') : File.join(PROJECT_ROOT, f)
}
puts
