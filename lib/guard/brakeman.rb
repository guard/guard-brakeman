# Don't require "guard/plugin" here or in any other plugin's files
require 'guard/compat/plugin'

require 'brakeman'
require 'brakeman/scanner'

module Guard

  # The Brakeman guard that gets notifications about the following
  # Guard events: `start`, `stop`, `reload`, `run_all` and `run_on_changes`.
  #
  class Brakeman < Plugin
    def initialize(options = { })
      super

      ::Brakeman.instance_variable_set(:@quiet, options[:quiet])

      if options[:skip_checks]
        options[:skip_checks] = options[:skip_checks].map do |val|
          # mimic Brakeman::set_options behavior
          val[0,5] == "Check" ? val : "Check" << val
        end
      end

      if options[:url_safe_methods]
        options[:url_safe_methods]=
          options[:url_safe_methods].map do |val|
             val.to_sym
        end
      end

      # chatty implies notifications
      options[:notifications] = true if options[:chatty]

      # TODO mixing the use of this attr, good to match?  Bad to couple?
      @options = {
        :notifications => true,
        :run_on_start => false,
        :chatty => false,
        :min_confidence => 2,
        :quiet => false,
        :support_rescanning => true, # Will be needed for Brakeman 7.0
      }.merge!(options)
      @scanner_opts = ::Brakeman::set_options({:app_path => '.'}.merge(@options))
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def start
      @scanner_opts = ::Brakeman::set_options({:app_path => '.'}.merge(@options))
      @options.merge!(@scanner_opts)

      if @options[:run_on_start]
        run_all
      elsif @options[:chatty]
        Guard::Compat::Notifier.notify("Brakeman is ready to work!", :title => "Brakeman started", :image => :pending)
      end
    end

    # Gets called when all checks should be run.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      fail "no scanner opts (start not called?)!" if @scanner_opts.nil?
      tracker.run_checks
      ::Brakeman.filter_warnings tracker, @scanner_opts
      print_failed
      throw :task_has_failed if tracker.filtered_warnings.any?
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when stop has failed
    #
    def run_on_changes paths
      return run_all unless tracker.checks
      info "\n\nrescanning #{paths}, running all checks" unless options[:quiet]
      report = ::Brakeman::rescan(tracker, paths)
      print_changed(report)
      throw :task_has_failed if report.any_warnings?
    end

    private

    def tracker
      @tracker ||= ::Brakeman::Scanner.new(@scanner_opts).process
    end

    def print_failed
      info "\n------ brakeman warnings --------\n" unless options[:quiet]
      all_warnings = tracker.filtered_warnings
      icon = all_warnings.count > 0 ? :failed : :success
      message = "#{all_warnings.count} brakeman findings"

      if @options[:output_files]
        write_report
        message += "\nResults written to #{@options[:output_files]}"
      end

      if @options[:chatty] && all_warnings.any?
        Guard::Compat::UI.notify(message, :title => "Full Brakeman results", :image => icon)
      end

      info(message, 'yellow')
      warning_info(all_warnings.sort_by { |w| w.confidence })
    end

    def print_changed report
      info "\n------ brakeman warnings --------\n" unless options[:quiet]

      message = []
      should_alert = false

      fixed_warnings = report.fixed_warnings
      if fixed_warnings.any?
        results_notification = pluralize(fixed_warnings.length,  "fixed warning")
        info(results_notification, 'green')
        warning_info(fixed_warnings.sort_by { |w| w.confidence })

        message << results_notification
        should_alert = true
        icon = :success
      end

      new_warnings = report.new_warnings
      if new_warnings.any?
        new_warning_message = pluralize(new_warnings.length,  "new warning")
        info(new_warning_message, 'red')
        warning_info(new_warnings.sort_by { |w| w.confidence })

        message << new_warning_message
        should_alert = true
        icon = :failed
      end

      existing_warnings = report.existing_warnings
      if existing_warnings.any?
        existing_warning_message = pluralize(existing_warnings.length, "previous warning")
        info(existing_warning_message, 'yellow')
        warning_info(existing_warnings.sort_by { |w| w.confidence })

        message << existing_warning_message
        should_alert = true if @options[:chatty]
        icon ||= :pending
      end

      if @options[:output_files]
        write_report
        message << "\nResults written to #{@options[:output_files]}"
      end

      title = case icon
      when :success
        pluralize(fixed_warnings.length, "Warning") + " fixed."
      when :pending
        pluralize(existing_warnings.length, "Warning") + " left to fix."
      when :failed
        pluralize(new_warnings.length, "Warning") + " introduced."
      end

      if @options[:notifications] && should_alert
        Guard::Compat::UI.notify(message.join(", ").chomp, :title => title, :image => icon)
      end
    end

    def write_report
      @options[:output_files].each_with_index do |output_file, i|
        File.open output_file, "w" do |f|
          f.puts tracker.report.send(@options[:output_formats][i])
        end
      end
    end

    def pluralize(count, singular, plural = nil)
      "#{count || 0} " + ((count == 1 || count =~ /^1(\.0+)?$/) ? singular : (plural || pluralize_word(singular)))
    end

    # try ActiveSupport or naive pluralize
    def pluralize_word(singular)
      singular.respond_to?(:pluralize) ? singular.pluralize : singular + 's'
    end

    def info(message, color = :white)
      Guard::Compat::UI.info(Guard::Compat::UI.color(message, color))
    end

    def warning_info(warnings, color = :white)
      warnings.each do |warning|
        info(decorate_warning(warning))
      end
    end

    def decorate_warning(warning)
      color = case warning.confidence
      when 0
        :red
      when 1
        :yellow
      when 2
        :white
      end

      msg = ::Brakeman::Warning::TEXT_CONFIDENCE[warning.confidence]
      output =  Guard::Compat::UI.color(msg, color)
      output << " - #{warning.warning_type} - #{warning.message}"
      output << " near line #{warning.line}" if warning.line

      if path = relative_warning_path(warning)
        output << " in #{path}"
      end

      output << ": #{warning.format_code}" if warning.code
      output
    end

    def relative_warning_path warning
      case
      when warning.file.nil? # This should never really happen
        nil
      when warning.respond_to?(:relative_path) # For Brakeman < 4.5.1
        warning.relative_path
      else # Must be new Brakeman::FilePath, Brakeman >= 4.5.1
        warning.file.relative
      end
    end
  end
end
