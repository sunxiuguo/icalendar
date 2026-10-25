# Synthetic contract fixtures only. This does NOT execute project regressions.
require 'open3'
require 'rbconfig'
validator = File.expand_path('verify_expected_red.rb', __dir__)
fixtures = Dir[File.expand_path('validator-fixtures/*.json', __dir__)].sort
abort 'fixtures missing' unless fixtures.length == 10
fixtures.each do |path|
  stdout, stderr, status = Open3.capture3(RbConfig.ruby, validator, path)
  expected_success = File.basename(path) == 'positive-synthetic.json'
  abort "Wrong validator result for #{File.basename(path)}: #{stdout} #{stderr}" unless status.success? == expected_success
end
puts 'All ten synthetic validator contracts behaved as expected (not project-test evidence).'
