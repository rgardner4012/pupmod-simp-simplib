require 'spec_helper'

describe 'Simplib::Cron::Hour_entry' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with valid parameters' do
        it { is_expected.to allow_value('22') }
        it { is_expected.to allow_value('*') }
        it { is_expected.to allow_value('*/5') }
        it { is_expected.to allow_value('2/5') }
        it { is_expected.to allow_value(22) }
        it { is_expected.to allow_value('23,20') }
        it { is_expected.to allow_value('20-23') }
        it { is_expected.to allow_value('0-23/2') }
      end
      context 'with invalid parameters' do
        it { is_expected.not_to allow_value('one') }
        it { is_expected.not_to allow_value('-2') }
        it { is_expected.not_to allow_value('/3') }
        it { is_expected.not_to allow_value('24') }
        it { is_expected.not_to allow_value('13/*') }
        it { is_expected.not_to allow_value('13-/15') }
      end
      context 'with silly things' do
        it { is_expected.not_to allow_value([]) }
        it { is_expected.not_to allow_value('.') }
        it { is_expected.not_to allow_value('') }
        it { is_expected.not_to allow_value('1  ') }
        it { is_expected.not_to allow_value('5 1') }
        it { is_expected.not_to allow_value(:undef) }
      end
    end
  end
end
