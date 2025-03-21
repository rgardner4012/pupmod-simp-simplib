require 'spec_helper'

describe 'Simplib::Cron::Minute' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with valid parameters' do
        it { is_expected.to allow_value([22]) }
        it { is_expected.to allow_value(['22']) }
        it { is_expected.to allow_value(['20-23', '10-14/2', 3, 5, '19']) }
        it { is_expected.to allow_value('*') }
        it { is_expected.to allow_value(22) }
        it { is_expected.to allow_value('22') }
        it { is_expected.to allow_value('20-23') }
        it { is_expected.to allow_value('*/5') }
        it { is_expected.to allow_value('0-23/2') }
      end
      context 'with invalid parameters' do
        it { is_expected.not_to allow_value(['20-23', '10-14/2', 3, 60, 5, '19']) }
        it { is_expected.not_to allow_value(['0,1,12-19,5']) }
        it { is_expected.not_to allow_value(["'0','1','12-19','5'"]) }
      end
    end
  end
end
