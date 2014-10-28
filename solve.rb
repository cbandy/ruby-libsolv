#require 'solv'

module RubySolv

  def self.extended(other)
    ruby_platforms = { Gem::Platform::RUBY => Solv::ARCH_ANY }
    ruby_platforms.merge!(
      'java' => other.str2id('java'),
      'mingw32' => other.str2id('x86-mingw32'),
      'x86_64-mingw32' => other.str2id('x64-mingw32'),
    )

    other.instance_variable_set(:@ruby_platforms, ruby_platforms)
  end

  attr_reader :ruby_platforms

  def archid_from_platform(gem_platform)
    platform = gem_platform.to_s
    @ruby_platforms[platform] ||=
      if platform.start_with? 'universal-ruby-'
        Solv::ARCH_ANY
      else
        normalized = Gem::Platform.new(platform)
        case normalized.os
        when 'java', 'jruby'
          str2id('java')
        when 'mswin32'
          str2id('x86-mswin32')
        when 'mswin64'
          str2id('mswin64')
        else
          normalized.cpu = nil if normalized.cpu == 'universal'
          platform = normalized.to_s
          @ruby_platforms[platform] || str2id(platform)
        end
      end
  end

  def relids_from_dependency(gem_dependency)
    relations = []

    gem_dependency.requirement.requirements.each do |(operation, version)|
      case operation
      when '='
        relations << [gem_dependency.name, version.to_s, Solv::REL_EQ]
      when '!='
        relations << [gem_dependency.name, version.to_s, Solv::REL_GT | Solv::REL_LT]
      when '>'
        relations << [gem_dependency.name, version.to_s, Solv::REL_GT]
      when '<'
        relations << [gem_dependency.name, version.to_s, Solv::REL_LT]
      when '>='
        relations << [gem_dependency.name, version.to_s, Solv::REL_EQ | Solv::REL_GT]
      when '<='
        relations << [gem_dependency.name, version.to_s, Solv::REL_EQ | Solv::REL_LT]
      when '~>'
        relations << [gem_dependency.name, version.to_s, Solv::REL_EQ | Solv::REL_GT]
        relations << [gem_dependency.name, version.bump.to_s, Solv::REL_LT]
      end
    end

    relations.map do |(name, version, flags)|
      rel2id(str2id(name), str2id(version), flags)
    end
  end

end

pool = Solv::Pool.new
pool.extend RubySolv
pool.installed = pool.add_repo('installed')

require 'benchmark'
report = Benchmark::Report.new(20)

report.report('Read installed gems') do
  Gem::Specification.find_all.each do |gem|
    solvable = pool.installed.add_solvable
    solvable.name = gem.name
    solvable.evr = gem.version.to_s
    solvable.archid = pool.archid_from_platform(gem.platform)

    gem.dependencies.select { |dep| dep.type == :runtime }.each do |gem_dep|
      pool.relids_from_dependency(gem_dep).each do |relation|
        solvable.add_deparray(Solv::SOLVABLE_REQUIRES, relation)
      end
    end
  end
end

#puts pool.installed.solvables.to_a


require 'rubygems/name_tuple'
require 'rubygems/remote_fetcher'

rubygems = pool.add_repo('https://rubygems.org')

tuples = nil
report.report('Fetch RubyGems index') do
  tuples = Gem::Source.new('https://rubygems.org').load_specs(:released)
end

report.report('Read RubyGems index') do
  tuples.each do |tuple|
    solvable = rubygems.add_solvable
    solvable.name = tuple.name
    solvable.evr = tuple.version.to_s
    solvable.archid = pool.archid_from_platform(tuple.platform)
  end
end

report.report('Write RubyGems solv') do
  File.open('rubygems.solv', 'w') do |file|
    rubygems.write(Solv::xfopen_fd('', file.fileno))
  end
end

report.report('Read RubyGems solv') do
  Solv::Pool.new.add_repo('rubygems').add_solv('rubygems.solv')
end

#count_platforms = {}
#source.load_specs(:released).each do |tuple|
#  count_platforms[tuple.platform] ||= 0
#  count_platforms[tuple.platform] += 1
#end
#
#count_platforms.each do |k, v|
#  puts "#{v}\t#{k}\t#{Gem::Platform.new(k)}"
#end
