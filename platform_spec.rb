describe 'platform matching' do
  def resolve(platform)
    @ruby_platforms = { Gem::Platform::RUBY => 'any' }
    @ruby_platforms.merge!(
#      'java' => Gem::Platform.new('java').to_s,
      'mingw32' => Gem::Platform.new('x86-mingw32').to_s,
      'x86_64-mingw32' => Gem::Platform.new('x64-mingw32').to_s,
    )

    @ruby_platforms[platform] ||=
      begin
        if platform.start_with? 'universal-ruby-'
          'any'
        else
          normalized = Gem::Platform.new(platform)

          case normalized.os
          when 'java', 'jruby'
            'java'
          when 'mswin32'
            'x86-mswin32'
          when 'mswin64'
            'mswin64'
          else
            normalized.cpu = nil if normalized.cpu == 'universal'
            string = normalized.to_s
            @ruby_platforms[string] || string
          end
        end
      end
  end

  matcher :resolve_to do |expected|
    match { |actual| resolve(actual) == expected }
    failure_message { |actual| %(expected "#{actual}" to resolve to "#{expected}" but got "#{resolve(actual)}") }
  end

  %w(darwin universal-darwin).each do |actual|
    specify { expect(actual).to resolve_to('darwin') }
  end

  specify { expect('powerpc-darwin').to resolve_to('powerpc-darwin') }
  specify { expect('x86_64-darwin').to resolve_to('x86_64-darwin') }

  %w(universal-darwin-8 universal-darwin8.0).each do |actual|
    specify { expect(actual).to resolve_to('darwin-8') }
  end

  %w(powerpc-darwin8.3.0 powerpc-darwin8.10.0).each do |actual|
    specify { expect(actual).to resolve_to('powerpc-darwin-8') }
  end

  %w(x86-darwin-8 i686-darwin8.4.1 i686-darwin8.8.2 i686-darwin8.9.1).each do |actual|
    specify { expect(actual).to resolve_to('x86-darwin-8') }
  end

  %w(universal-darwin-9 universal-darwin9.0).each do |actual|
    specify { expect(actual).to resolve_to('darwin-9') }
  end

  specify { expect('x86-darwin-9').to resolve_to('x86-darwin-9') }
  specify { expect('universal-darwin-10').to resolve_to('darwin-10') }

  %w(x86-darwin-10 i686-darwin10).each do |actual|
    specify { expect(actual).to resolve_to('x86-darwin-10') }
  end

  %w(x86_64-darwin-10 x86_64-darwin10.7.0 x86_64-darwin10.8.0).each do |actual|
    specify { expect(actual).to resolve_to('x86_64-darwin-10') }
  end

  specify { expect('universal-darwin-11').to resolve_to('darwin-11') }
  specify { expect('x86-darwin-11').to resolve_to('x86-darwin-11') }

  %w(x86_64-darwin-11 x86_64-darwin11.3.0).each do |actual|
    specify { expect(actual).to resolve_to('x86_64-darwin-11') }
  end

  %w(x86_64-darwin-12 x86_64-darwin12.0.0).each do |actual|
    specify { expect(actual).to resolve_to('x86_64-darwin-12') }
  end

  specify { expect('universal-darwin-13').to resolve_to('darwin-13') }
  specify { expect('x86_64-darwin-13').to resolve_to('x86_64-darwin-13') }

  specify { expect('universal-dotnet').to resolve_to('dotnet') }

  %w(
    java jruby
    universal-java universal-java-1.5 universal-java-1.6 universal-java-1.7
    universal-jruby-1.2
  ).each do |actual|
    specify { expect(actual).to resolve_to('java') }
  end

  %w(x86-linux i386-linux i486-linux i586-linux i686-linux).each do |actual|
    specify { expect(actual).to resolve_to('x86-linux') }
  end

  %w(linux universal-linux).each do |actual|
    specify { expect(actual).to resolve_to('linux') }
  end

  specify { expect('arm-linux').to resolve_to('arm-linux') }
  specify { expect('x86_64-linux').to resolve_to('x86_64-linux') }

  %w(
    mingw32 i386-mingw32 x86-mingw32 universal-mingw32
    x86-mingw32-1.9.1 x86-mingw32-1.9.2
  ).each do |actual|
    specify { expect(actual).to resolve_to('x86-mingw32') }
  end

  %w(x64-mingw32 x86_64-mingw32).each do |actual|
    specify { expect(actual).to resolve_to('x64-mingw32') }
  end

  %w(
    mswin32 i386-mswin32 i386-mswin32-mq5.3 i386-mswin32-mq6
    x86-mswin32 x86-mswin32-60 x86-mswin32-80 x86-mswin32-100
    x86-mswin32-1.9.1 x86-mswin32-1.9.2
  ).each do |actual|
    specify { expect(actual).to resolve_to('x86-mswin32') }
  end

  specify { expect('x64-mswin64-100').to resolve_to('mswin64') }

  %w(ruby universal-ruby-1.8.7 universal-ruby-1.9.2 universal-ruby-1.9.3).each do |actual|
    specify { expect(actual).to resolve_to('any') }
  end
end
