require 'spec_helper'

if Puppet.version.to_f >= 4.5
  test_data_type = 'Simplib::Syslog::UpperPriority'

  singular_item = 'priority'
  plural_item = 'priorities'

  valid_data = [
    'KERN.WARNING',
    'LOCAL6.NOTICE'
  ]

  invalid_data = [
    'KERN.warning',
    'kern.warn',
    'local6.NOTICE',
    'local6.notice'
  ]

  describe test_data_type, type: :class do
    describe 'valid handling' do
      let(:pre_condition) {%(
        class #{class_name} (
          #{test_data_type} $param
        ){ }

        class { '#{class_name}':
          param => #{param}
        }
      )}

      context "with valid #{plural_item}" do
        valid_data.each do |data|
          context "with #{singular_item} #{data}" do
            let(:param){ data.is_a?(String) ? "'#{data}'" : data }

            it 'should compile' do
              is_expected.to compile
            end
          end
        end
      end

      context "with invalid #{plural_item}" do
        invalid_data.each do |data|
          context "with #{singular_item} #{data}" do
            let(:param){
              data.is_a?(String) ? "'#{data}'" : data
            }

            it 'should fail to compile' do
              is_expected.to compile.and_raise_error(/parameter 'param'/)
            end
          end
        end
      end
    end
  end
end
