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

@project_root = File.exist?(".git") ? Dir.pwd : `\git rev-parse --show-toplevel 2> /dev/null`.strip

@git_status = `\git status --porcelain -b 2> /dev/null`

git_status_lines = @git_status.split("\n")
git_branch = git_status_lines[0]
@branch = git_branch[/^## (?:Initial commit on )?([^ \.]+)/, 1]
@ahead  = git_branch[/\[ahead ?(\d+).*\]/, 1]
@behind = git_branch[/\[.*behind ?(\d+)\]/, 1]

@changes = git_status_lines[1..-1]
# Exit if too many changes
exit if @changes.size > ENV["gs_max_changes"].to_i

# Colors
@c = {
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


# Following colors must be prepended with modifiers e.g. '\033[1;', '\033[0;'
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

# Show how many commits we are ahead and/or behind origin
difference = ["-#{@behind}", "+#{@ahead}"].select{|d| d.length > 1}.join('/')
difference = difference.length > 0 ? "  #{@c[:dark]}|  #{@c[:new]}#{difference}#{@c[:rst]}" : ""


# If no changes, just display green no changes message and exit here
if @git_status == ""
  puts "%s#%s On branch: %s#{@branch}#{difference}  %s|  \033[0;32mNo changes (working directory clean)%s" % [
    @c[:dark], @c[:rst], @c[:branch], @c[:dark], @c[:rst]
  ]
  exit
end


puts "%s#%s On branch: %s#{@branch}#{difference}  %s|  [%s*%s]%s => $#{ENV["git_env_char"]}*\n%s#%s" % [
  @c[:dark], @c[:rst], @c[:branch], @c[:dark], @c[:rst], @c[:dark], @c[:rst], @c[:dark], @c[:rst]
]

def has_modules?
  @has_modules ||= File.exists?(File.join(@project_root, '.gitmodules'))
end

# Index modification states
@changes.each do |change|
  x, y, file = change[0, 1], change[1, 1], change[3..-1]

  # Fetch the long git status once, but only if any submodules have changed
  if not @git_status_long and has_modules?
    @gitmodules ||= File.read(File.join(@project_root, '.gitmodules'))
    # If changed 'file' is actually a git submodule
    if @gitmodules.include?(file)
      # Parse long git status for submodule summaries
      @git_status_long = `git status`.gsub(/\033\[[^m]*m/, "") # (strip colors)
    end
  end


  msg, col, group = case change[0..1]
  when "DD"; ["   both deleted",  :del, :unmerged]
  when "AU"; ["    added by us",  :new, :unmerged]
  when "UD"; ["deleted by them",  :del, :unmerged]
  when "UA"; ["  added by them",  :new, :unmerged]
  when "DU"; ["  deleted by us",  :del, :unmerged]
  when "AA"; ["     both added",  :new, :unmerged]
  when "UU"; ["  both modified",  :mod, :unmerged]
  when /M./; ["  modified",       :mod, :staged]
  when /A./; ["  new file",       :new, :staged]
  when /D./; ["   deleted",       :del, :staged]
  when /R./; ["   renamed",       :ren, :staged]
  when /C./; ["    copied",       :cpy, :staged]
  when /T./; ["typechange",       :typ, :staged]
  when "??"; [" untracked",       :unt, :untracked]
  end

  # Store data
  @stat_hash[group] << {:msg => msg, :col => col, :file => file} if msg

  # Work tree modification states
  if x == "R" && y == "M"
    # Extract the second file name from the format x -> y
    quoted, unquoted = /^(?:"(?:[^"\\]|\\.)*"|[^"].*) -> (?:"((?:[^"\\]|\\.)*)"|(.*[^"]))$/.match(file)[1..2]
    renamed_file = quoted || unquoted
    @stat_hash[:unstaged] << {:msg => "  modified", :col => :mod, :file => renamed_file}
  elsif x != "R" && y == "M"
    @stat_hash[:unstaged] << {:msg => "  modified", :col => :mod, :file => file}
  elsif y == "D" && x != "D" && x != "U"
    # Don't show deleted 'y' during a merge conflict.
    @stat_hash[:unstaged] << {:msg => "   deleted", :col => :del, :file => file}
  elsif y == "T"
    @stat_hash[:unstaged] << {:msg => "typechange", :col => :typ, :file => file}
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
  c_group = "\033[0;#{@group_c[group]}"

  @stat_hash[group].each do |h|
    @e += 1
    padding = (@e < 10 && @changes.size >= 10) ? " " : ""

    # Find relative path, i.e. ../../lib/path/to/file
    rel_file = relative_path(Dir.pwd, File.join(@project_root, h[:file]))

    # If some submodules have changed, parse their summaries from long git status
    sub_stat = nil
    if @git_status_long && (sub_stat = @git_status_long[/#{h[:file]} \((.*)\)/, 1])
      # Format summary with parantheses
      sub_stat = "(#{sub_stat})"
    end

    puts "#{c_group}##{@c[:rst]}     #{@c[h[:col]]}#{h[:msg]}:\
#{padding}#{@c[:dark]} [#{@c[:rst]}#{@e}#{@c[:dark]}] #{c_group}#{rel_file}#{@c[:rst]} #{sub_stat}"
    # Save the ordered list of output files
    # fetch first file (in the case of oldFile -> newFile) and remove quotes
    @output_files << if h[:msg] == "typechange"
      # Only use relative paths for 'typechange' modifications.
      "~#{rel_file}"
    elsif h[:file] =~ /^"([^\\"]*(\\.[^"]*)*)"/
      # Handle the regex above..
      $1.gsub(/\\(.)/,'\1')
    else
      # Else, strip file
      h[:file].strip
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
      c_arrow="\033[1;#{@group_c[group]}"
      c_hash="\033[0;#{@group_c[group]}"
      puts "#{c_arrow}➤#{@c[:header]} #{heading}\n#{c_hash}##{@c[:rst]}"
      output_file_group(group)
    end
  end
end

print "@@filelist@@::"
puts @output_files.map {|f|
  # If file starts with a '~', treat it as a relative path.
  # This is important when dealing with symlinks
  f.start_with?("~") ? f.sub(/~/, '') : File.join(@project_root, f)
}.join("|")
