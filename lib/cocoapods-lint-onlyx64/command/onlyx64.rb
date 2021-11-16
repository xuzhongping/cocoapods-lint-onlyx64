module Pod
  class Validator
    attr_accessor :only_x64
    def xcodebuild(action, scheme, configuration)
      require 'fourflusher'
      command = %W(clean #{action} -workspace #{File.join(validation_dir, 'App.xcworkspace')} -scheme #{scheme} -configuration #{configuration})
      case consumer.platform_name
      when :osx, :macos
        command += %w(CODE_SIGN_IDENTITY=)
      when :ios
        command += %w(CODE_SIGN_IDENTITY=- -sdk iphonesimulator)
        command += Fourflusher::SimControl.new.destination(:oldest, 'iOS', deployment_target)
        xcconfig = consumer.pod_target_xcconfig
        if xcconfig
          archs = xcconfig['VALID_ARCHS']
          if archs && (archs.include? 'armv7') && !(archs.include? 'i386') && (archs.include? 'x86_64')
            # Prevent Xcodebuild from testing the non-existent i386 simulator if armv7 is specified without i386
            command += %w(ARCHS=x86_64)
          end
          if @only_x64 && !(command.include? 'ARCHS=x86_64')
            command += %w(ARCHS=x86_64)
          end
        end
      when :watchos
        command += %w(CODE_SIGN_IDENTITY=- -sdk watchsimulator)
        command += Fourflusher::SimControl.new.destination(:oldest, 'watchOS', deployment_target)
      when :tvos
        command += %w(CODE_SIGN_IDENTITY=- -sdk appletvsimulator)
        command += Fourflusher::SimControl.new.destination(:oldest, 'tvOS', deployment_target)
      end

      if analyze
        command += %w(CLANG_ANALYZER_OUTPUT=html CLANG_ANALYZER_OUTPUT_DIR=analyzer)
      end

      begin
        _xcodebuild(command, true)
      rescue => e
        message = 'Returned an unsuccessful exit code.'
        message += ' You can use `--verbose` for more information.' unless config.verbose?
        error('xcodebuild', message)
        e.message
      end
    end
  
  end

  class Command
    class Lib < Command
      class Lint < Lib
        class << self
          alias_method :original_options, :options
        end
        def self.options
          original_options.concat([['--onlyx64', 'Lint uses only x86-64 iphonesimulator']])
        end

        alias_method :original_initialize, :initialize

        def initialize(argv)
          @only_x64 = argv.flag?('onlyx64', false)
          original_initialize(argv)
        end

        def run
          UI.puts
          podspecs_to_lint.each do |podspec|
            validator                = Validator.new(podspec, @source_urls, @platforms)
            validator.local          = true
            validator.quick          = @quick
            validator.no_clean       = !@clean
            validator.fail_fast      = @fail_fast
            validator.allow_warnings = @allow_warnings
            validator.no_subspecs    = !@subspecs || @only_subspec
            validator.only_subspec   = @only_subspec
            validator.use_frameworks = @use_frameworks
            validator.use_modular_headers = @use_modular_headers
            validator.ignore_public_only_results = @private
            validator.swift_version = @swift_version
            validator.skip_import_validation = @skip_import_validation
            validator.skip_tests = @skip_tests
            validator.analyze = @analyze
            validator.include_podspecs = @include_podspecs
            validator.external_podspecs = @external_podspecs
            validator.only_x64 = @only_x64
            validator.validate

            unless @clean
              UI.puts "Pods workspace available at `#{validator.validation_dir}/App.xcworkspace` for inspection."
              UI.puts
            end
            if validator.validated?
              UI.puts "#{validator.spec.name} passed validation.".green
            else
              spec_name = podspec
              spec_name = validator.spec.name if validator.spec
              message = "#{spec_name} did not pass validation, due to #{validator.failure_reason}."

              if @clean
                message << "\nYou can use the `--no-clean` option to inspect " \
                  'any issue.'
              end
              raise Informative, message
            end
          end
        end
      end
    end
  end

  class Command
    class Spec < Command
      class Lint < Spec

        class << self
          alias_method :original_options, :options
        end
        def self.options
          original_options.concat([['--onlyx64', 'Lint uses only x86-64 iphonesimulator']])
        end

        alias_method :original_initialize, :initialize

        def initialize(argv)
          @only_x64 = argv.flag?('onlyx64', false)
          original_initialize(argv)
        end

        def run
          UI.puts
          failure_reasons = []
          podspecs_to_lint.each do |podspec|
            validator                = Validator.new(podspec, @source_urls, @platforms)
            validator.quick          = @quick
            validator.no_clean       = !@clean
            validator.fail_fast      = @fail_fast
            validator.allow_warnings = @allow_warnings
            validator.no_subspecs    = !@subspecs || @only_subspec
            validator.only_subspec   = @only_subspec
            validator.use_frameworks = @use_frameworks
            validator.use_modular_headers = @use_modular_headers
            validator.ignore_public_only_results = @private
            validator.swift_version = @swift_version
            validator.skip_import_validation = @skip_import_validation
            validator.skip_tests = @skip_tests
            validator.analyze = @analyze
            validator.only_x64 = @only_x64
            validator.validate
            failure_reasons << validator.failure_reason

            unless @clean
              UI.puts "Pods workspace available at `#{validator.validation_dir}/App.xcworkspace` for inspection."
              UI.puts
            end
          end

          count = podspecs_to_lint.count
          UI.puts "Analyzed #{count} #{'podspec'.pluralize(count)}.\n\n"

          failure_reasons.compact!
          if failure_reasons.empty?
            lint_passed_message = count == 1 ? "#{podspecs_to_lint.first.basename} passed validation." : 'All the specs passed validation.'
            UI.puts lint_passed_message.green << "\n\n"
          else
            raise Informative, if count == 1
                                 "The spec did not pass validation, due to #{failure_reasons.first}."
                               else
                                 "#{failure_reasons.count} out of #{count} specs failed validation."
                               end
          end
          podspecs_tmp_dir.rmtree if podspecs_tmp_dir.exist?
        end
      end
    end
  end

  class Command
    class Repo < Command
      class Push < Repo

        class << self
          alias_method :original_options, :options
        end
        def self.options
          original_options.concat([['--onlyx64', 'Lint uses only x86-64 iphonesimulator']])
        end

        alias_method :original_initialize, :initialize

        def initialize(argv)
          @only_x64 = argv.flag?('onlyx64', false)
          original_initialize(argv)
        end

        def validate_podspec_files
          UI.puts "\nValidating #{'spec'.pluralize(count)}".yellow
          podspec_files.each do |podspec|
            validator = Validator.new(podspec, @source_urls)
            validator.allow_warnings = @allow_warnings
            validator.use_frameworks = @use_frameworks
            validator.use_modular_headers = @use_modular_headers
            validator.ignore_public_only_results = @private
            validator.swift_version = @swift_version
            validator.skip_import_validation = @skip_import_validation
            validator.skip_tests = @skip_tests
            validator.only_x64 = @only_x64
            begin
              validator.validate
            rescue => e
              raise Informative, "The `#{podspec}` specification does not validate." \
                                 "\n\n#{e.message}"
            end
            raise Informative, "The `#{podspec}` specification does not validate." unless validator.validated?
          end
        end
      end
    end
  end
  
end