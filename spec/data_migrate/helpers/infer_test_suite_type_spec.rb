require 'spec_helper'

describe DataMigrate::Helpers::InferTestSuiteType do
  subject(:infer_test_suite) { described_class.new }

  describe '#call' do
    before do
      allow(Rails).to receive(:root).and_return(Pathname.new('/fake/path'))
    end

    context 'when RSpec is detected' do
      before do
        allow(File).to receive(:exist?).with(Rails.root.join('spec', 'spec_helper.rb')).and_return(true)
        allow(File).to receive(:exist?).with(Rails.root.join('test', 'test_helper.rb')).and_return(false)
      end

      it 'returns :rspec' do
        expect(infer_test_suite.call).to eq(:rspec)
      end
    end

    context 'when Minitest is detected' do
      before do
        allow(File).to receive(:exist?).with(Rails.root.join('spec', 'spec_helper.rb')).and_return(false)
        allow(File).to receive(:exist?).with(Rails.root.join('test', 'test_helper.rb')).and_return(true)
      end

      it 'returns :minitest' do
        expect(infer_test_suite.call).to eq(:minitest)
      end
    end

    context 'when no test suite is detected' do
      before do
        allow(File).to receive(:exist?).with(Rails.root.join('spec', 'spec_helper.rb')).and_return(false)
        allow(File).to receive(:exist?).with(Rails.root.join('test', 'test_helper.rb')).and_return(false)
      end

      it 'raises an error' do
        expect { infer_test_suite.call }.to raise_error(StandardError, 'Unable to determine test suite')
      end
    end
  end
end
