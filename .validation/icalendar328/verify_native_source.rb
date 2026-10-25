# Required by RSpec before examples; assertions run after spec_helper loads the
# project normally, preserving SimpleCov startup and original suite behavior.
require 'digest'
require 'rspec/core'

RSpec.configure do |config|
  config.before(:suite) do
    root = File.realpath(ENV.fetch('ICALENDAR_EXPECTED_ROOT'))
    expected = {
      'Gemfile.ci' => ENV.fetch('ICALENDAR_EXPECTED_GEMFILE_SHA256'),
      'Gemfile.ci.lock' => ENV.fetch('ICALENDAR_EXPECTED_LOCK_SHA256'),
      'lib/icalendar.rb' => ENV.fetch('ICALENDAR_EXPECTED_LIBRARY_SHA256'),
      'lib/icalendar/tzinfo.rb' => ENV.fetch('ICALENDAR_EXPECTED_TZINFO_SHA256')
    }
    raise 'Wrong Bundler Gemfile' unless File.realpath(ENV.fetch('BUNDLE_GEMFILE')) == File.join(root, 'Gemfile.ci')
    expected.each do |relative, hash|
      path = File.join(root, relative)
      raise "Wrong physical source: #{relative}" unless File.realpath(path) == path
      raise "Wrong source hash: #{relative}" unless Digest::SHA256.file(path).hexdigest == hash
    end
    library = File.join(root, 'lib/icalendar.rb')
    raise 'Own library was not loaded' unless $LOADED_FEATURES.any? { |path| path.end_with?('/icalendar.rb') && File.realpath(path) == library }
    location = TZInfo::Timezone.instance_method(:ical_timezone).source_location
    raise 'Wrong ical_timezone implementation' unless location && File.realpath(location.first) == File.join(root, 'lib/icalendar/tzinfo.rb')
    # A shared candidate gemspec or installed gem must not supply baseline code.
    $LOADED_FEATURES.each do |path|
      next unless path.match?(%r{/lib/icalendar(?:\.rb$|/)})
      raise "Foreign iCalendar feature: #{path}" unless File.realpath(path).start_with?(File.join(root, 'lib') + '/')
    end
    puts "Verified own iCalendar source and reviewed Gemfile/lock at #{root}"
  end
end
