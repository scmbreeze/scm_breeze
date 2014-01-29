#!/usr/bin/env ruby
require 'strscan'

class GitStatus

  COL = {
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

  # following colors must be prepended with modifiers e.g. '\033[1;', '\033[0;'
  GR_COL = {
    :header    => "\033[2;37m",
    :staged    => "33m",
    :unmerged  => "31m",
    :unstaged  => "32m",
    :untracked => "36m"
  }

  GROUPS = {
    staged: 'Changes to be committed',
    unmerged: 'Unmerged paths',
    unstaged: 'Changes not staged for commit',
    untracked: 'Untracked files'
  }

  def initialize(request = nil)
    @request = request
    @status = get_status
    @ahead, @behind = parse_remote_stat
    @grouped_changes = parse_changes
    @index = 0
  end

  def raise_index!
    @index += 1
  end

  def branch
    @status.lines.first.strip[/^On branch (.*)$/, 1]
  end

  def parse_remote_stat
    remote_line = @status.lines[1].strip
    if remote_line.match(/diverged/)
      remote_line.match(/.*(\d*).*(\d*)/).captures
    else
      [remote_line[/is ahead of.*by (\d*).*/, 1], remote_line[/is behind.*by (\d*).*/, 1]]
    end
  end

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

  def extract_changes(str)
    str.lines.map do |line|
      new_git_change(*Regexp.last_match.captures) if line.match(/\t(.*:)?(.*)/)
    end.compact # in case there were any non matching lines left
  end

  def new_git_change(status, file_and_message)
    status = 'untracked' unless status
    GitChange.new(file_and_message, status)
  end

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

  def report
    print_header
    print_groups
    puts filelist if anything_changed?
  end

  def print_header
    puts delimiter(:header) + header
    puts delimiter(:header) if anything_changed?
  end

  def filelist
    "@@filelist@@::#{all_changes.map(&:absolute_path).join('|')}"
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

  def all_changes
    @all_changes ||= @grouped_changes.values.flatten
  end

  def padding
    @padding ||= all_changes.map { |change| change.status.size }.max + 5
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

  # markup
  def mu(str, col_in, col_out = :rst)
    return if str.empty?
    "#{COL[col_in]}#{str}#{COL[col_out]}"
  end

  # group markup
  def gmu(str, group, boldness = 0, col_out = :rst)
    "\033[#{boldness};#{GR_COL[group]}#{str}#{COL[:rst]}"
  end

  def header
    parts = [[:branch, :branch], [:difference, :new]]
    parts << (anything_changed? ? [:hotkey, :dark] : [:clean_state, :mod]) # mod is green
    # compact because difference might return nil
    "On branch: #{parts.map { |meth, col| mu(send(meth), col) }.compact.join('  |  ')}"
  end

  def anything_changed?
    @grouped_changes.any?
  end

  def branch_difference_and_hotkey
    [mu(branch, :branch), mu(difference, :new), mu(hotkey, :dark)].compact.join('  |  ')
  end

  def clean_state
    "No changes (working directory clean)"
  end

  def hotkey
    "[*] => $#{ENV['git_env_char']}"
  end

  def delimiter(col)
    gmu("# ", col)
  end

  def gc(color)
  end

  def get_status
    `git status 2>/dev/null`
  end
end

class GitChange < GitStatus
  attr_reader :status
  def initialize(file_and_message, status)
    # destructively cut out the submodules message
    # strip the remaining for to get rid of padding
    @message = file_and_message.slice!(/\(.*\)/)
    @file = file_and_message.strip
    @status = status.strip
  end

  STATUS_COLORS = {
    "both deleted"    => :del,
    "added by us"     => :new,
    "deleted by them" => :del,
    "added by them"   => :new,
    "deleted by us"   => :del,
    "both added"      => :new,
    "both modified"   => :mod,
    "modified"        => :mod,
    "new file"        => :new,
    "deleted"         => :del,
    "renamed"         => :ren,
    "copied"          => :cpy,
    "typechange"      => :typ,
    "untracked"       => :unt,
  }

  def color_key
    # we most likely have a : with us
    STATUS_COLORS[@status.chomp(':')]
  end

  def report_with_index(index, type, padding = 0)
    "#{pad(padding)}#{mu(@status, color_key)} " +
    "#{mu("[#{index}]", :dark)} #{gmu(@file, type)} #{@message}"
  end

  def pad(padding)
    ' ' * (padding - @status.size)
  end

  def absolute_path
    File.expand_path(@file, Dir.pwd)
  end
end

GitStatus.new('').report
