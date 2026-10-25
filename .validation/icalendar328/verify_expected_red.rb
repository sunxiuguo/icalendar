# Run only after baseline + tzinfo_future_recurrence_spec.rb, with RSpec JSON.
require 'json'
report = JSON.parse(File.read(ARGV.fetch(0)))
expected = [
  'preserves Santiago month 4 boundaries generated on 2026-10-07T00:00:00+00:00',
  'preserves Santiago month 9 boundaries generated on 2026-10-07T00:00:00+00:00',
  'preserves Santiago month 4 boundaries generated on 2030-06-01T00:00:00+00:00',
  'preserves Santiago month 9 boundaries generated on 2030-06-01T00:00:00+00:00',
  'uses the weekday/monthday intersection in 2029-4',
  'uses the weekday/monthday intersection in 2030-9'
]
controls = [
  'retains onset and adjacent-day behavior for Europe/Copenhagen',
  'retains onset and adjacent-day behavior for America/Los_Angeles',
  'retains onset and adjacent-day behavior for Australia/Lord_Howe',
  'retains the legacy path when transitions_up_to is unavailable'
]
# Pinned rspec-core 3.13.0 JsonFormatter supplies every required summary field.
# See SCHEMA.md. Missing fields are errors, never interpreted as zero.
abort 'unexpected RSpec JSON schema version' unless report.fetch('version') == '3.13.0'
examples = report.fetch('examples')
abort 'wrong example count' unless examples.length == 10
summary = report.fetch('summary')
abort 'wrong summary example count' unless summary.fetch('example_count') == 10
abort 'pending examples' unless summary.fetch('pending_count') == 0
abort 'outside-example errors' unless summary.fetch('errors_outside_of_examples_count') == 0
ids = examples.map { |item| item.fetch('id') }
abort 'missing or duplicate example IDs' unless ids.all? { |id| id.is_a?(String) && !id.empty? } && ids.uniq.length == 10
names = examples.map { |item| item.fetch('description') }
abort 'duplicate descriptions' unless names.uniq.length == 10
abort 'unexpected example multiset' unless names.sort == (expected + controls).sort
examples.each do |example|
  if expected.include?(example.fetch('description'))
    abort 'expected assertion failure did not occur' unless example.fetch('status') == 'failed'
    abort 'setup/API error is not a red control' unless example.fetch('exception').fetch('class') == 'RSpec::Expectations::ExpectationNotMetError'
  else
    abort 'unexpected failure or skip' unless example.fetch('status') == 'passed'
  end
end
abort 'wrong failure count' unless report.fetch('summary').fetch('failure_count') == expected.length
puts 'Observed precisely the six intended Santiago assertion failures; all four controls passed.'
