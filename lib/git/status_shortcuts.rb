#!/usr/bin/env ruby
# encoding: UTF-8
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# A much faster implementation of git_status_shortcuts() in ruby
# (bash: 0m0.549s, ruby: 0m0.045s)
#
# Last line of output contains the ordered absolute file paths,
# which need to be extracted by the shell and exported as numbered env variables.
#
# Processes 'git status --porcelain', and exports numbered
# env variables that contain the path of each affected file.
# Output is also more concise than standard 'git status'.
#
# Call with optional <group> parameter to just show one modification state
# # groups => 1: staged, 2: unmerged, 3: unstaged, 4: untracked
# --------------------------------------------------------------------

@project_root = File.exist?(".git") ? Dir.pwd : `git rev-parse --git-dir 2> /dev/null`.sub(/\/\.git$/, '').strip

@git_status = `git status --porcelain 2> /dev/null`
# Exit if no changes
exit if @git_status == ""
git_branch = `git branch -v 2> /dev/null`
@branch = git_branch[/^\* ([^ ]*)/, 1]
@ahead = git_branch[/^\* [^ ]* *[^ ]* *\[ahead ?(\d+)\]/, 1]

@changes = @git_status.split("\n")
# Exit if too many changes
exit if @changes.size > ENV["gs_max_changes"].to_i

# Colors
@c = {
  :rst => "\e[0m",
  :del => "\e[0;31m",
  :mod => "\e[0;32m",
  :new => "\e[0;33m",
  :ren => "\e[0;34m",
  :cpy => "\e[0;33m",
  :unt => "\e[0;36m",
  :dark => "\e[2;37m",
  :branch => "\e[1m",
  :header => "\e[0m"
}


# Following colors must be prepended with modifiers e.g. '\e[1;', '\e[0;'
@group_c = {
  :staged    => "33m",
  :unmerged  => "31m",
  :unstaged  => "32m",
  :untracked => "36m"
}

@stat_hash = {
  :staged    => [],
  :unmerged  => [],
  :unstaged  => [],
  :untracked => []
}

@output_files = []

# Counter for env variables
@e = 0

# Heading
ahead = @ahead ? "  #{@c[:dark]}|  #{@c[:new]}+#{@ahead}#{@c[:rst]}" : ""
puts "%s#%s On branch: %s#{@branch}#{ahead}  %s|  [%s*%s]%s => $#{ENV["git_env_char"]}*\n%s#%s" % [
  @c[:dark], @c[:rst], @c[:branch], @c[:dark], @c[:rst], @c[:dark], @c[:rst], @c[:dark], @c[:rst]
]


# Index modification states
@changes.each do |change|
  x, y, file = change[0, 1], change[1, 1], change[3..-1]

  msg, col, group = case change[0..1]
  when "DD"; ["   both deleted", :del, :unmerged]
  when "AU"; ["    added by us", :new, :unmerged]
  when "UD"; ["deleted by them", :del, :unmerged]
  when "UA"; ["  added by them", :new, :unmerged]
  when "DU"; ["  deleted by us", :del, :unmerged]
  when "AA"; ["     both added", :new, :unmerged]
  when "UU"; ["  both modified", :mod, :unmerged]
  when /M./; [" modified",       :mod, :staged]
  when /A./; [" new file",       :new, :staged]
  when /D./; ["  deleted",       :del, :staged]
  when /R./; ["  renamed",       :ren, :staged]
  when /C./; ["   copied",       :cpy, :staged]
  when "??"; ["untracked",       :unt, :untracked]
  end

  # Store data
  @stat_hash[group] << {:msg => msg, :col => col, :file => file} if msg

  # Work tree modification states
  if y == "M"
    @stat_hash[:unstaged] << {:msg => " modified", :col => :mod, :file => file}
  elsif y == "D" && x != "D" && x != "U"
    # Don't show deleted 'y' during a merge conflict.
    @stat_hash[:unstaged] << {:msg => "  deleted", :col => :del, :file => file}
  end
end

def relative_path(base, target)
  back = ""
  while target.sub(base,'') == target
    base = base.sub(/\/[^\/]*$/, '')
    back = "../#{back}"
  end
  "#{back}#{target.sub("#{base}/",'')}"
end


# Output files
def output_file_group(group)
  # Print colored hashes & files based on modification groups
  c_group = "\e[0;#{@group_c[group]}"

  @stat_hash[group].each do |h|
    @e += 1
    padding = (@e < 10 && @changes.size >= 10) ? " " : ""

    rel_file = relative_path(Dir.pwd, File.join(@project_root, h[:file]))

    puts "#{c_group}##{@c[:rst]}     #{@c[h[:col]]}#{h[:msg]}:\
#{padding}#{@c[:dark]} [#{@c[:rst]}#{@e}#{@c[:dark]}] #{c_group}#{rel_file}#{@c[:rst]}"
    # Save the ordered list of output files
    # fetch first file (in the case of oldFile -> newFile) and remove quotes
    @output_files << if h[:file] =~ /^"([^\\"]*(\\.[^"]*)*)"/
      $1.gsub(/\\(.)/,'\1')
    else
      h[:file].match(/^[^ ]*/)[0]
    end
  end

  puts "#{c_group}##{@c[:rst]}" # Extra '#'
end


[[:staged,   'Changes to be committed'],
[:unmerged,  'Unmerged paths'],
[:unstaged,  'Changes not staged for commit'],
[:untracked, 'Untracked files']
].each_with_index do |data, i|
  group, heading = *data

  # Allow filtering by specific group (by string or integer)
  if !ARGV[0] || ARGV[0] == group.to_s || ARGV[0] == (i+1).to_s; then
    if !@stat_hash[group].empty?
      c_arrow="\e[1;#{@group_c[group]}"
      c_hash="\e[0;#{@group_c[group]}"
      puts "#{c_arrow}➤#{@c[:header]} #{heading}\n#{c_hash}##{@c[:rst]}"
      output_file_group(group)
    end
  end
end

print "@@filelist@@::"
puts @output_files.map{|f| File.join(@project_root, f) }.join("|")

