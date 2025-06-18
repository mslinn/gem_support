# See https://mslinn.com/jekyll/10700-designing-for-testability.html
module GemSupport
  # This method is also provided in [`jekyll_plugin_helper_attribution.rb`](https://github.com/mslinn/jekyll_plugin_support/blob/v3.1.0/lib/helper/jekyll_plugin_helper_attribution.rb).
  #
  # @param file must be a fully qualified file name
  # @return Gem::Specification of gem that file points into, or nil if not called from a gem
  def current_spec(file)
    return nil unless File.file?(file)

    searcher = if Gem::Specification.respond_to?(:find)
                 Gem::Specification
               elsif Gem.respond_to?(:searcher)
                 Gem.searcher.init_gemspecs
               end

    searcher&.find do |spec|
      file.start_with? spec.full_gem_path
    end
  end

  def self.expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
      ENV.fetch(Regexp.last_match(1), nil)
    end
  end

  def gem_path(file)
    current_spec(file)&.full_gem_path
  end

  def self.validate_gem_name(gem_name)
    require 'rubygems'
    spec = Gem::Specification.new { |s| s.name = gem_name }
    policy = Gem::SpecificationPolicy.new spec
    policy.send :validate_name
    true
  rescue Gem::InvalidSpecificationException => e
    puts "Invalid gem name '#{gem_name}': #{e.message}".red
    false
  end
end
