#!/usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'simplib::passgen::legacy::remove' do
  let(:id) { 'my_id' }
  let(:passwords) do
    [
      'password for my_id 2',
      'password for my_id 1',
      'password for my_id 0',
    ]
  end

  let(:salts) do
    [
      'salt for my_id 2',
      'salt for my_id 1',
      'salt for my_id 0',
    ]
  end

  # DEBUG NOTES:
  #   Puppet[:vardir] is dynamically created as a tmpdir by the test
  #   framework, when the subject is first created. So if you want
  #   to know what vardir is so you can create/modify files in
  #   that directory as part of the test setup, in the 'it' block,
  #   first create the subject yourself and then retrieve the
  #   vardir value as shown below:
  #
  # it 'does something' do
  #   subject()  # vardir created as a tmpdir for this example block
  #   vardir = Puppet[:vardir]
  #
  #   <pre-seed file content here>
  #
  #   is_expected.to run.with_params('spectest')  # run the function
  #
  # end
  context 'success cases' do
    it 'succeeds when no password files exist' do
      is_expected.to run.with_params(id)
    end

    it 'removes all password-related files' do
      subject # rubocop:disable RSpec/NamedSubject
      settings = call_function('simplib::passgen::legacy::common_settings')
      FileUtils.mkdir_p(settings['keydir'])
      password_file = File.join(settings['keydir'], id)
      password_file_last = "#{password_file}.last"
      password_file_last_last = "#{password_file}.last.last"
      File.open(password_file, 'w') { |file| file.puts passwords[0] }
      File.open(password_file_last, 'w') { |file| file.puts passwords[1] }
      File.open(password_file_last_last, 'w') { |file| file.puts passwords[2] }

      salt_file = File.join(settings['keydir'], "#{id}.salt")
      salt_file_last = "#{salt_file}.last"
      salt_file_last_last = "#{salt_file}.last.last"
      File.open(salt_file, 'w') { |file| file.puts salts[0] }
      File.open(salt_file_last, 'w') { |file| file.puts salts[1] }
      File.open(salt_file_last_last, 'w') { |file| file.puts salts[2] }

      is_expected.to run.with_params(id)

      expect(File.exist?(password_file)).to be false
      expect(File.exist?(password_file_last)).to be false
      expect(File.exist?(password_file_last_last)).to be false
      expect(File.exist?(salt_file)).to be false
      expect(File.exist?(salt_file_last)).to be false
      expect(File.exist?(salt_file_last_last)).to be false
    end
  end

  context 'error cases' do
    it 'fails when a password/salt file cannot be removed' do
      subject # rubocop:disable RSpec/NamedSubject
      settings = call_function('simplib::passgen::legacy::common_settings')
      FileUtils.mkdir_p(settings['keydir'])
      password_file = File.join(settings['keydir'], id)
      File.open(password_file, 'w') { |file| file.puts passwords[0] }

      expect(File).to receive(:unlink).with(password_file).and_raise(Errno::EACCES, 'file unlink failed')

      is_expected.to run.with_params(id).and_raise_error(RuntimeError,
        %r{Unable to remove all files:.*#{id}: Permission denied - file unlink failed}m)
    end

    it 'reports all failures' do
      subject # rubocop:disable RSpec/NamedSubject
      settings = call_function('simplib::passgen::legacy::common_settings')
      FileUtils.mkdir_p(settings['keydir'])
      password_file = File.join(settings['keydir'], id)
      password_file_last = "#{password_file}.last"
      password_file_last_last = "#{password_file}.last.last"
      File.open(password_file, 'w') { |file| file.puts passwords[0] }
      File.open(password_file_last, 'w') { |file| file.puts passwords[1] }
      File.open(password_file_last_last, 'w') { |file| file.puts passwords[2] }

      salt_file = File.join(settings['keydir'], "#{id}.salt")
      salt_file_last = "#{salt_file}.last"
      salt_file_last_last = "#{salt_file}.last.last"
      File.open(salt_file, 'w') { |file| file.puts salts[0] }
      File.open(salt_file_last, 'w') { |file| file.puts salts[1] }
      File.open(salt_file_last_last, 'w') { |file| file.puts salts[2] }

      expect(File).to receive(:unlink).with(password_file).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')
      expect(File).to receive(:unlink).with(password_file_last).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')
      expect(File).to receive(:unlink).with(password_file_last_last).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')
      expect(File).to receive(:unlink).with(salt_file).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')
      expect(File).to receive(:unlink).with(salt_file_last).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')
      expect(File).to receive(:unlink).with(salt_file_last_last).exactly(6).times.and_raise(Errno::EACCES, 'file unlink failed')

      [
        password_file,
        password_file_last,
        password_file_last_last,
        salt_file,
        salt_file_last,
        salt_file_last_last,
      ].each do |file|
        is_expected.to run.with_params(id).and_raise_error(RuntimeError,
          %r{#{Regexp.escape(file)}: Permission denied - file unlink failed}m)
      end
    end
  end
end
