require 'spec_helper'

test_data_type = 'Simplib::Port::Dynamic'

describe test_data_type, type: :class do
  describe 'valid handling' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) { os_facts }
        let(:pre_condition) do
          <<~END
            class #{class_name} (
              #{test_data_type} $param,
            ) { }

            class { '#{class_name}':
              param => #{param},
            }
          END
        end

        context 'with valid ports' do
          [49_152, 56_789, 65_535].each do |param|
            let(:param) { param }

            it "works with port #{param}" do
              is_expected.to compile
            end
          end
        end

        context 'with invalid ports' do
          [0, 49_151, 65_536, '22', true].each do |param|
            let(:param) { param }

            it "fails on port #{param}" do
              is_expected.to compile.and_raise_error(%r{parameter 'param' expects})
            end
          end
        end
      end
    end
  end
end
