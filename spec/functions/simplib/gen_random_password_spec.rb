#!/usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'simplib::gen_random_password' do
  let(:default_chars) do
    (('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a).map do |x|
      Regexp.escape(x)
    end
  end

  let(:safe_special_chars) do
    ['@', '%', '-', '_', '+', '=', '~'].map do |x|
      Regexp.escape(x)
    end
  end

  let(:unsafe_special_chars) do
    (((' '..'/').to_a + ('['..'`').to_a + ('{'..'~').to_a)).map { |x|
      Regexp.escape(x)
    } - safe_special_chars
  end
  let(:base64_regex) do
    '^[a-zA-Z0-9+/=]+$'
  end

  context 'successful password generation' do
    it 'runs successfully with default arguments' do
      result = subject.execute(16) # rubocop:disable RSpec/NamedSubject
      expect(result).to match(%r{^(#{default_chars.join('|')})+$})
    end

    it 'returns a password that contains "safe" special characters if complexity is 1' do
      result = subject.execute(32, 1) # rubocop:disable RSpec/NamedSubject
      expect(result.length).to be(32)
      expect(result).to match(%r{(#{default_chars.join('|')})})
      expect(result).to match(%r{(#{safe_special_chars.join('|')})})
      expect(result).not_to match(%r{(#{unsafe_special_chars.join('|')})})
    end

    it 'returns a password that only contains "safe" special characters if complexity is 1 and complex_only is true' do
      result = subject.execute(32, 1, true) # rubocop:disable RSpec/NamedSubject
      expect(result.length).to be(32)
      expect(result).not_to match(%r{(#{default_chars.join('|')})})
      expect(result).to match(%r{(#{safe_special_chars.join('|')})})
      expect(result).not_to match(%r{(#{unsafe_special_chars.join('|')})})
    end

    it 'returns a password that contains all normal and special characters if complexity is 2' do
      result = subject.execute(32, 2) # rubocop:disable RSpec/NamedSubject
      expect(result.length).to be(32)
      expect(result).to match(%r{(#{default_chars.join('|')})})
      expect(result).to match(%r{(#{unsafe_special_chars.join('|')})})
    end

    it 'returns a password that only contains all special characters if complexity is 2 and complex_only is true' do
      result = subject.execute(32, 2, true) # rubocop:disable RSpec/NamedSubject
      expect(result.length).to be(32)
      expect(result).not_to match(%r{(#{default_chars.join('|')})})
      expect(result).to match(%r{(#{unsafe_special_chars.join('|')})})
    end
  end

  context 'errors' do
    # This test is timing sensitive.  It may not fail if the test machine
    # processes faster than the dev machine.
    it 'raises timeout error if password cannot be generated in specified interval' do
      is_expected.to run.with_params(10**20, 2, false, 0.01).and_raise_error(Timeout::Error)
    end

    it 'fails if length is outside of specified range' do
      is_expected.to run.with_params(7).and_raise_error(ArgumentError)
    end

    it 'fails if complexity is outside of specified range' do
      is_expected.to run.with_params(16, 5).and_raise_error(ArgumentError)
    end

    it 'fails if timeout is outside of specified range' do
      is_expected.to run.with_params(16, nil, false, -0.1).and_raise_error(ArgumentError)
    end
  end
end
