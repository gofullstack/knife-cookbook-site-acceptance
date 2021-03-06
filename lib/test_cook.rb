require 'command_line_helpers'
require 'test_cookbook'

class TestCook
  extend CommandLineHelpers

  def self.create_cookbook(name = RSpec.configuration.starting_time)
    TestCookbook.new(name).tap do |cookbook|
      if cookbook.exists?
        show = run "knife cookbook site show #{cookbook.name}"

        if show.exitstatus != 0
          share(cookbook.name)
        end
      else
        cookbook.create

        unshare(cookbook.name)
        share(cookbook.name)
      end

      cookbook.save
    end
  end

  def self.share(name)
    run! "knife cookbook site share #{name} Other"
  end

  def self.unshare(name)
    run "knife cookbook site unshare #{name} -y"
  end

  def self.publish_new_version(name, version)
    cookbook = find_cookbook(name)
    cookbook.version = version
    cookbook.save

    share(cookbook.name)
  end

  def self.find_cookbook(name)
    cookbooks.find { |cookbook| cookbook.name == "supermarket-test-#{name}" }
  end

  def self.cleanup
    cookbooks.each do |cookbook|
      begin
        run "knife cookbook site unshare #{cookbook.name} -y"
      ensure
        cookbook.destroy
      end
    end

    downloads.each { |tarball| File.unlink(tarball) }
  end

  def self.cookbooks
    Dir.entries('spec/fixtures/cookbooks').select do |entry|
      entry.start_with?('supermarket-test-')
    end.map do |full_name|
      TestCookbook.new(full_name.split('supermarket-test-').last)
    end
  end

  def self.downloads
    Dir.glob('*.tar.gz')
  end

end
