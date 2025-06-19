# See https://mslinn.com/jekyll/10700-designing-for-testability.html
module GemSupport
  # @param file must be a fully qualified file name
  # @return Gem::Specification of gem that file points into, or nil if not called from a gem
  def self.current_spec(file)
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

  # Expand environment variables in a string.
  # Supports $VAR, ${VAR}, and %VAR% syntax.
  # If the variable is not set, it will be replaced with nil.
  #
  # @param str [String] the string to expand
  # @return [String] the string with environment variables expanded
  # @example
  #   expand_env("Path is $PATH and home is ${HOME} and user is %USER%")
  #   # => "Path is /usr/bin and home is /home/user and user is user"
  #
  # @note This method does not raise an error if an environment variable is not set.
  #       It simply replaces it with nil.
  def expand_env(str)
    str.gsub(/\$([a-zA-Z_][a-zA-Z0-9_]*)|\${\g<1>}|%\g<1>%/) do
      ENV.fetch(Regexp.last_match(1), nil)
    end
  end

  # Returns the full path of the gem that contains the given file.
  # If the file is not part of a gem, it returns nil.
  #
  # @param file [String] the file path to check
  # @return [String, nil] the full path of the gem or nil if not found
  #
  # @example
  #   gem_path("/path/to/my_gem/lib/my_gem.rb")
  #   # => "/path/to/my_gem"
  def gem_path(file)
    current_spec(file)&.full_gem_path
  end

  # Validates a gem name according to RubyGems naming conventions.
  # It checks if the gem name is valid and prints an error message if it is not.
  #
  # @param gem_name [String] the name of the gem to validate
  # @return [Boolean] true if the gem name is valid, false otherwise
  #
  # @example
  #   validate_gem_name("my_gem")
  #   # => true
  #   validate_gem_name("my-gem")
  #   # => false (prints error message)
  def validate_gem_name(gem_name)
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
