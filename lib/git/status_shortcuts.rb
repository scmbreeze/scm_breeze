#!/usr/bin/env ruby
# encoding: UTF-8
# ------------------------------------------------------------------------------
# SCM Breeze - Streamline your SCM workflow.
# Copyright 2011 Nathan Broadbent (http://madebynathan.com). All Rights Reserved.
# Released under the LGPL (GNU Lesser General Public License)
# ------------------------------------------------------------------------------
#
# Original work by Nathan Broadbent
# Rewritten by LFDM
#
# A much faster implementation of git_status_shortcuts() in ruby
# (original benchmarks - bash: 0m0.549s, ruby: 0m0.045s, the updated
# version is twice as fast, especially noticable in big repos)
#
#
# Last line of output contains the ordered absolute file paths,
# which need to be extracted by the shell and exported as numbered env variables.
#
# Processes 'git status', and exports numbered
# env variables that contain the path of each affected file.
# Output is also more concise than standard 'git status'.
#
# Call with optional <group> parameter to just show one modification state
# # groups => 1: staged, 2: unmerged, 3: unstaged, 4: untracked
# --------------------------------------------------------------------
#
require 'strscan'

class GitStatus
  def initialize(request = nil)
    @request = request.to_s # capture nils
    @status = get_status
    @ahead, @behind = parse_remote_stat
    @grouped_changes = parse_changes
    @index = 0
  end

  def report
    exit if all_changes.length > ENV["gs_max_changes"].to_i
    print_header
    print_groups
    puts filelist if @grouped_changes.any?
  end


  ######### Parsing methods #########

  def get_status
    `git status 2>/dev/null`
  end

  # Remote info is always on the second line of git status
  def parse_remote_stat
    remote_line = @status.lines[1].strip
    if remote_line.match(/diverged/)
      remote_line.match(/.*(\d*).*(\d*)/).captures
    else
      [remote_line[/is ahead of.*by (\d*).*/, 1], remote_line[/is behind.*by (\d*).*/, 1]]
    end
  end

  # We have to resort to the StringScanner to stay away from overly complex
  #   regular expressions.
  # The individual blocks are always formatted the same
  #
  # identifier                        Changes not staged for commit
  # helper text                         (use "git add <file>..." ...
  # empty line
  # changed files, leaded by a tab          modified: file
  #                                         deleted:  other_file
  # empty line
  # next identifier                   Untracked files
  # ...
  #
  # We parse each requested group and return a grouped hash, its values are
  # arrays of GitChange objects.
  def parse_changes
    scanner = StringScanner.new(@status)
    requested_groups.each_with_object({}) do |(type, identifier), h|
      if scanner.scan_until(/#{identifier}/)
        scan_until_next_empty_line(scanner)
        file_block = scan_until_next_empty_line(scanner)
        h[type] = extract_changes(file_block)
      end
      scanner.reset
    end
  end

  def scan_until_next_empty_line(scanner)
    scanner.scan_until(/\n\n/)
  end

  # Matches
  #      modified: file                       # usual output in git status
  #      modified: file (untracked content)   # output for submodules
  #      file                                 # untracked files have no additional info
  def extract_changes(str)
    str.lines.map do |line|
      new_git_change(*Regexp.last_match.captures) if line.match(/\t(.*:)?(.*)/)
    end.compact # in case there were any non matching lines left
  end

  def new_git_change(status, file_and_message)
    status = 'untracked:' unless status
    GitChange.new(file_and_message, status)
  end

  GROUPS = {
    staged:    'Changes to be committed',
    unmerged:  'Unmerged paths',
    unstaged:  'Changes not staged for commit',
    untracked: 'Untracked files'
  }

  # Returns all possible groups when there was no request at all,
  # otherwise selects groups by name or integer
  def requested_groups
    @request.empty? ? GROUPS : select_groups
  end

  def select_groups
    req = parse_request
    GROUPS.select { |k, _| k == req }
  end

  def parse_request
    if @request.match(/\d/)
      GROUPS.keys[@request.to_i - 1]
    else
      @request.to_sym
    end
  end


  ######### Outputting methods #########

  def print_header
    puts delimiter(:header) + header
    puts delimiter(:header) if anything_changed?
  end

  def print_groups
    @grouped_changes.each do |type, changes|
      print_group_header(type)
      puts delimiter(type)
      changes.each do |change|
        raise_index!
        print delimiter(type)
        puts change.report_with_index(@index, type, padding)
      end
      puts delimiter(type)
    end
  end

  def print_group_header(type)
    puts "#{gmu('➤', type, 1)} #{GROUPS[type]}"
  end


  ######### Items of interest #########

  def branch
    @status.lines.first.strip[/^On branch (.*)$/, 1]
  end

  def ahead
    "+#{@ahead}" if @ahead
  end

  def behind
    "-#{@behind}" if @behind
  end

  def difference
    [behind, ahead].compact.join('/')
  end

  def header
    parts = [[:branch, :branch], [:difference, :new]]
    parts << (anything_changed? ? [:hotkey, :dark] : [:clean_state, :mod]) # mod is green
    # compact because difference might return nil
    "On branch: #{parts.map { |meth, col| mu(send(meth), col) }.compact.join('  |  ')}"
  end

  def clean_state
    "No changes (working directory clean)"
  end

  def hotkey
    "[*] => $#{ENV['git_env_char']}"
  end

  # used to delimit the left side of the screen - looks nice
  def delimiter(col)
    gmu("# ", col)
  end

  def filelist
    "@@filelist@@::#{all_changes.map(&:absolute_path).join('|')}"
  end


  ######### Helper Methods #########

  # To know about changes we could ask if there are any parsing results, as in
  # @grouped_changes.any?, but that is not a good idea, since
  # we might have selected a requested group before parsing already.
  # Groups could be empty while there are in fact changes present,
  # there we look into the original status string once
  def anything_changed?
    @any_changes ||=
      ! @status.match(/nothing to commit.*working directory clean/)
  end

  # needed by hotkey filelist
  def raise_index!
    @index += 1
  end

  def all_changes
    @all_changes ||= @grouped_changes.values.flatten
  end

  # Dynamic padding, always looks for the longest status string present
  # and adds a little whitespace
  def padding
    @padding ||= all_changes.map { |change| change.status.size }.max + 5
  end


  ######### Markup/Color methods #########

  COL = {
    :rst    => "0",
    :header => "0",
    :branch => "1",
    :del    => "0;31",
    :mod    => "0;32",
    :new    => "0;33",
    :ren    => "0;34",
    :cpy    => "0;33",
    :typ    => "0;35",
    :unt    => "0;36",
    :dark   => "2;37",
  }

  GR_COL = {
    :staged    => "33",
    :unmerged  => "31",
    :unstaged  => "32",
    :untracked => "36",
  }

  # markup
  def mu(str, col_in, col_out = :rst)
    return if str.empty?
    col_in  = "\033[#{COL[col_in]}m"
    col_out = "\033[#{COL[col_out]}m"
    with_color(str, col_in, col_out)
  end

  # group markup
  def gmu(str, group, boldness = 0, col_out = :rst)
    group_col = "\033[#{boldness};#{GR_COL[group]}m"
    col_out   = "\033[#{COL[col_out]}m"
    with_color(str, group_col, col_out)
  end

  def with_color(str, col_in, col_out)
    "#{col_in}#{str}#{col_out}"
  end
end

class GitChange < GitStatus
  attr_reader :status

  # Restructively singles out the submodules message and
  # strips the remaining string to get rid of padding
  def initialize(file_and_message, status)
    @message = file_and_message.slice!(/\(.*\)/)
    @file = file_and_message.strip
    @status = status.strip
  end

  def absolute_path
    File.expand_path(@file, Dir.pwd)
  end

  STATUS_COLORS = {
    "copied"          => :cpy,
    "both deleted"    => :del,
    "deleted by us"   => :del,
    "deleted by them" => :del,
    "deleted"         => :del,
    "both modified"   => :mod,
    "modified"        => :mod,
    "added by them"   => :new,
    "added by us"     => :new,
    "both added"      => :new,
    "new file"        => :new,
    "renamed"         => :ren,
    "typechange"      => :typ,
    "untracked"       => :unt,
  }

  # Looks like this
  #
  # PADDING   STATUS   INDEX    FILE       MESSAGE (optional)
  #           modified: [1]  changed_file (untracked content)
  #
  def report_with_index(index, type, padding = 0)
    "#{pad(padding)}#{mu(@status, color_key)} " +
    "#{mu("[#{index}]", :dark)} #{gmu(@file, type)} #{@message}"
  end

  # we most likely have a : with us which we don't need here
  def color_key
    STATUS_COLORS[@status.chomp(':')]
  end

  def pad(padding)
    ' ' * (padding - @status.size)
  end
end

GitStatus.new(ARGV.first).report
