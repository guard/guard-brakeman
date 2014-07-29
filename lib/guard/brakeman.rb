require 'guard'
require 'guard/guard'
require 'brakeman'
require 'brakeman/scanner'

module Guard

  # The Brakeman guard that gets notifications about the following
  # Guard events: `start`, `stop`, `reload`, `run_all` and `run_on_changes`.
  #
  class Brakeman < Guard
    def initialize(watchers = [], options = { })
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
        :min_confidence => 1,
        :quiet => false
      }.merge!(options)
    end

    # Gets called once when Guard starts.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def start
      @scanner_opts = ::Brakeman::set_options({:app_path => '.'}.merge(@options))
      @options.merge!(@scanner_opts)
      @tracker = ::Brakeman::Scanner.new(@scanner_opts).process

      if @options[:run_on_start]
        run_all
      elsif @options[:chatty]
        ::Guard::Notifier.notify("Brakeman is ready to work!", :title => "Brakeman started", :image => :pending)
      end
    end

    # Gets called when all checks should be run.
    #
    # @raise [:task_has_failed] when stop has failed
    #
    def run_all
      @tracker.run_checks
      ::Brakeman.filter_warnings @tracker, @scanner_opts
      print_failed(@tracker)
      throw :task_has_failed if @tracker.filtered_warnings.any?
    end

    # Gets called when watched paths and files have changes.
    #
    # @param [Array<String>] paths the changed paths and files
    # @raise [:task_has_failed] when stop has failed
    #
    def run_on_changes paths
      return run_all unless @tracker.checks
      info "\n\nrescanning #{paths}, running all checks"
      report = ::Brakeman::rescan(@tracker, paths)
      print_changed(report)
      throw :task_has_failed if report.any_warnings?
    end

    private

    def print_failed tracker
      info "\n------ brakeman warnings --------\n"
      all_warnings = tracker.filtered_warnings
      icon = all_warnings.count > 0 ? :failed : :success
      message = "#{all_warnings.count} brakeman findings"

      if @options[:output_files]
        write_report
        message += "\nResults written to #{@options[:output_files]}"
      end

      if @options[:chatty] && all_warnings.any?
        ::Guard::Notifier.notify(message, :title => "Full Brakeman results", :image => icon)
      end

      info(message, 'yellow')
      warning_info(all_warnings.sort_by { |w| w.confidence })
    end

    def print_changed report
      info "\n------ brakeman warnings --------\n"

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
        ::Guard::Notifier.notify(message.join(", ").chomp, :title => title, :image => icon)
      end
    end

    def write_report
      @options[:output_files].each_with_index do |output_file, i|
        File.open output_file, "w" do |f|
          f.puts @tracker.report.send(@options[:output_formats][i])
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
      UI.info(UI.send(:color, message, color))
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

      output =  UI.send(:color, ::Brakeman::Warning::TEXT_CONFIDENCE[warning.confidence], color)
      output << " - #{warning.warning_type} - #{warning.message}"
      output << " near line #{warning.line}" if warning.line
      if warning.file
        # fix this ish or wait for brakeman to be fixed
        filename = warning.file.gsub(@options[:app_path], '')
        output << " in #{filename}"
      end
      output << ": #{warning.format_code}" if warning.code
      output
    end
  end
end
