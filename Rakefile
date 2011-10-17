require 'rake'

desc "Run shUnit2 tests"
task :test do
  Dir.glob("test/**/*_test.sh").each do |test|
    ["bash", "zsh"].each do |shell|
      puts "== Running tests with [#{shell}]: #{test}"
      @failed = !system("#{shell} #{test}") || @failed
    end
  end
  exit @failed ? 1 : 0
end

task :default => ['test']

