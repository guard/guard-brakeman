require 'spec_helper'

# TODO
# Barely covers happy case, ignores sad case
# Pending tests
describe Guard::Brakeman do
  let(:default_options) { {:cli => '--stuff'} }
  let(:tracker) { double().as_null_object }
  let(:report) { double().as_null_object }

  before(:each) do
    @guard = Guard::Brakeman.new
    @guard.stub(:decorate_warning)
    @guard.instance_variable_set(:@tracker, tracker)
    @guard.instance_variable_set(:@options, {:notifications => false, :app_path => 'tmp/aruba/default_app'})
  end

  describe '#start' do
    let(:scanner) { double(:process => tracker) }

    it 'initializes brakeman by scanning all files' do
      ::Brakeman::Scanner.stub(:new).and_return(scanner)
      scanner.should_receive(:process)
      @guard.start
    end

    context 'with the run_on_start option' do
      before(:each) do
        @guard.instance_variable_set(:@options, @guard.instance_variable_get(:@options).merge({:run_on_start => true}))
      end

      it 'runs all checks' do
        scanner.stub(:process).and_return(tracker)
        @guard.should_receive(:run_all)
        @guard.start
      end
    end

    context 'with the exclude option' do
      let(:options) { {:skip_checks => ['CheckDefaultRoutes']} }
      before(:each) do
        @guard.instance_variable_set(:@options, @guard.instance_variable_get(:@options).merge(options))
      end

      it 'does not run the specified checks' do
        ::Brakeman::Scanner.should_receive(:new).with(hash_including(options)).and_return(scanner)
        @guard.start
      end
    end
  end

  describe '#run_all' do
    it 'runs all checks' do
      @guard.stub(:print_failed)
      tracker.should_receive(:run_checks)
      tracker.stub_chain(:checks, :all_warnings, :any?)
      @guard.run_all
    end
  end

  describe '#reload'

  describe '#run_on_change' do
    it 'rescans changed files, and checks all files' do
      ::Brakeman.should_receive(:rescan).with(tracker, ['files/file']).and_return(report)
      report.stub(:any_warnings?)
      @guard.run_on_changes(['files/file'])
    end
  end

  describe '#print_failed' do
    before(:each) do
      report.stub(:all_warnings).and_return [double(:confidence => 0)]
    end

    context 'with the chatty flag' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:chatty => true})
      end

      it 'notifies the user' do
        ::Guard::Notifier.should_receive :notify
        @guard.send :print_failed, report
      end
    end

    context 'with the output option' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:output_files => ['test.csv']})
      end

      it 'writes the brakeman report to disk' do
        @guard.should_receive(:write_report)
        @guard.send :print_failed, report
      end

      it 'adds the report filename to the growl' do
        @guard.stub(:write_report)
        @guard.instance_variable_set(:@options, @guard.instance_variable_get(:@options).merge({:chatty => true}))
        ::Guard::Notifier.should_receive(:notify).with(/test\.csv/, anything)
        @guard.send :print_failed, report
      end
    end

    context 'with notifications disabled' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:chatty => false})
      end

      it 'does not notify the user' do
        ::Guard::Notifier.should_not_receive :notify
        @guard.send :print_failed, report
      end
    end
  end

  describe '#print_changed' do
    before(:each) do
      report.stub(:all_warnings).and_return [double(:confidence => 3)]
    end

    context 'with the min_confidence setting' do
      let(:options) { {:min_confidence => 2} }
      before(:each) do
        @guard.instance_variable_set(:@options, @guard.instance_variable_get(:@options).merge(options))
      end

      it 'does not alert on warnings below the threshold' do
        ::Guard::Notifier.should_not_receive :notify
        @guard.send :print_changed, report
      end
    end

    context 'with notifications on' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:notifications => true})
      end

      it 'notifies the user' do
        ::Guard::Notifier.should_receive :notify
        @guard.send :print_changed, report
      end
    end

    context 'with notifications disabled' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:notifications => false})
      end

      it 'does not notify the user' do
        ::Guard::Notifier.should_not_receive :notify
        @guard.send :print_changed, report
      end
    end

    context 'with the output option' do
      before(:each) do
        @guard.instance_variable_set(:@options, {:output_files => ['test.csv']})
      end

      it 'writes the brakeman report to disk' do
        File.should_receive(:open).with('test.csv', 'w')
        @guard.send :print_changed, report
      end

      it 'adds the report filename to the growl' do
        @guard.stub(:write_report)
        @guard.instance_variable_set(:@options, @guard.instance_variable_get(:@options).merge({:notifications => true}))
        ::Guard::Notifier.should_receive(:notify).with(/test\.csv/, anything)
        @guard.send :print_changed, report
      end
    end
  end

  describe "#write_report" do
    it 'writes the report to disk' do
      @guard.instance_variable_set(:@options, {:output_files => ['test.csv']})

      File.should_receive(:open).with('test.csv', 'w')
      @guard.send(:write_report)
    end
  end
end