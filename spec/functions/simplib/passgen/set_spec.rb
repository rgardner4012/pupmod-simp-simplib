#!/usr/bin/env ruby -S rspec
require 'spec_helper'

describe 'simplib::passgen::set' do
  let(:key_root_dir) { 'gen_passwd' }
  let(:id) { 'my_id' }
  let(:key) { "#{key_root_dir}/#{id}" }
  let(:password) { 'password for my_id' }
  let(:salt) { 'salt for my_id' }

  # The bulk of simplib::passgen::set testing is done in tests for
  # simplib::passgen::legacy::set and simplib::passgen::simpkv::set.
  # The  primary focus of this test is to spot check that the correct
  # function is called and failures are appropriately reported.

  context 'legacy passgen::set' do
    let(:passwords) do
      [
        'password for my_id 1',
        'password for my_id 0',
      ]
    end

    let(:salts) do
      [
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
      it 'creates password and salt files when password does not exist' do
        is_expected.to run.with_params(id, passwords[0], salts[0], {})

        settings = call_function('simplib::passgen::legacy::common_settings')
        password_file = File.join(settings['keydir'], id)
        salt_file = File.join(settings['keydir'], "#{id}.salt")
        expect(Dir.exist?(settings['keydir'])).to be true
        expect(File.exist?(password_file)).to be true
        expect(IO.read(password_file).chomp).to eq passwords[0]
        expect(File.stat(password_file).mode & 0o777).to eq(settings['file_mode'])
        expect(File.exist?(salt_file)).to be true
        expect(IO.read(salt_file).chomp).to eq salts[0]
        expect(File.stat(salt_file).mode & 0o777).to eq(settings['file_mode'])

        expect(File.exist?("#{password_file}.last")).to be false
        expect(File.exist?("#{salt_file}.last")).to be false
        expect(File.exist?("#{password_file}.last.last")).to be false
        expect(File.exist?("#{salt_file}.last.last")).to be false
      end

      it 'backups existing password and salt files and create current ones' do
        subject # rubocop:disable RSpec/NamedSubject
        settings = call_function('simplib::passgen::legacy::common_settings')
        FileUtils.mkdir_p(settings['keydir'])
        password_file = File.join(settings['keydir'], id)
        File.open(password_file, 'w') { |file| file.puts passwords[1] }
        salt_file = File.join(settings['keydir'], "#{id}.salt")
        File.open(salt_file, 'w') { |file| file.puts salts[1] }

        is_expected.to run.with_params(id, passwords[0], salts[0], {})

        expect(IO.read(password_file).chomp).to eq passwords[0]
        expect(IO.read(salt_file).chomp).to eq salts[0]

        password_file_last = "#{password_file}.last"
        salt_file_last = "#{salt_file}.last"
        expect(IO.read(password_file_last).chomp).to eq passwords[1]
        expect(IO.read(salt_file_last).chomp).to eq  salts[1]
      end
    end

    context 'error cases' do
      it 'fails when the key directory cannot be created' do
        subject # rubocop:disable RSpec/NamedSubject
        settings = call_function('simplib::passgen::legacy::common_settings')
        expect(FileUtils).to receive(:mkdir_p).with(
            settings['keydir'], { mode: settings['dir_mode'] }
          ).and_raise(Errno::EACCES, 'dir create failed')

        is_expected.to run.with_params(id, password, salt, {})
                          .and_raise_error(RuntimeError, %r{Could not make directory})
      end

      it 'fails when a password/salt file cannot be created' do
        subject # rubocop:disable RSpec/NamedSubject
        settings = call_function('simplib::passgen::legacy::common_settings')
        password_file = File.join(settings['keydir'], id)
        allow(File).to receive(:chmod).with(any_args).and_call_original
        expect(File).to receive(:chmod).with(settings['file_mode'], password_file)
                                       .and_raise(Errno::EACCES, 'file chmod failed')

        is_expected.to run.with_params(id, password, salt, {})
                          .and_raise_error(Errno::EACCES, %r{Permission denied})
      end
    end
  end

  context 'simpkv passgen::set' do
    let(:hieradata) { 'simplib_passgen_simpkv' }
    let(:complexity) { 0 }
    let(:complex_only) { false }
    let(:password_options) do
      {
        'complexity' => complexity,
        'complex_only' => complex_only,
      }
    end

    after(:each) do
      # This is required for GitLab, because the spec tests are run by a
      # privileged user who ends up creating a global file store in
      # /var/simp/simpkv/file/auto_default, instead of a set of per-test,
      # temporary file stores, each within its test-specific Puppet
      # environment.
      #
      # If we wanted to be truly safe from privileged user issues, we would
      # either configure simpkv to use the file plugin with an appropriate
      # per-test path, or, convert all the unit test to use rspec-mocks
      # instead of mocha and then use an appropriate pair of
      # `allow(FileUtils).to receive(:mkdir_p).with...` that fail the global
      # file store directory creation but allow other directory creations.
      # (See spec tests in pupmod-simp-simpkv).
      #
      call_function('simpkv::deletetree', key_root_dir)
    end

    context 'successes' do
      it 'stores a new password' do
        is_expected.to run.with_params(id, password, salt, password_options)

        # retrieve what has been stored by simpkv and validate
        stored_info = call_function('simpkv::get', key)
        expect(stored_info['value']['password']).to eq password
        expect(stored_info['value']['salt']).to eq salt
        expected_meta = {
          'complexity' => complexity,
          'complex_only' => complex_only,
          'history' => [],
        }
        expect(stored_info['metadata']).to eq(expected_meta)
      end

      it 'retains the history of the last 10 passwords with their salts' do
        expected_history = []
        (1..12).each do |run|
          rpassword = "#{password} run #{run}"
          rsalt = "#{salt} run #{run}"
          subject.execute(id, rpassword, rsalt, password_options) # rubocop:disable RSpec/NamedSubject
          expected_history << [rpassword, rsalt]
        end

        # remove the current value and the oldest value and then reverse
        current_password, current_salt = expected_history.pop
        expected_history.delete_at(0)
        expected_history.reverse!

        # retrieve what has been stored by simpkv and validate
        stored_info = call_function('simpkv::get', key)
        expect(stored_info['value']['password']).to eq current_password
        expect(stored_info['value']['salt']).to eq current_salt
        expected_meta = {
          'complexity' => complexity,
          'complex_only' => complex_only,
          'history' => expected_history,
        }
        expect(stored_info['metadata']).to eq(expected_meta)
      end
    end

    context 'failures' do
      it 'fails when password_options is missing complexity' do
        bad_password_options = password_options.dup
        bad_password_options.delete('complexity')

        is_expected.to run.with_params(
          id, password, salt, bad_password_options
        ).and_raise_error(
          ArgumentError,
          %r{simplib::passgen::set: password_options must contain 'complexity' in simpkv mode},
        )
      end

      it 'fails when password_options is missing complex_only' do
        bad_password_options = password_options.dup
        bad_password_options.delete('complex_only')

        is_expected.to run.with_params(
          id, password, salt, bad_password_options
        ).and_raise_error(
          ArgumentError,
          %r{simplib::passgen::set: password_options must contain 'complex_only' in simpkv mode},
        )
      end

      it 'fails when simpkv operation fails' do
        simpkv_options = {
          'backend'  => 'oops',
          'backends' => {
            'oops' => {
              'type' => 'does_not_exist_type',
              'id'   => 'test',
            },
          },
        }

        is_expected.to run.with_params(
            id, password, salt, password_options, simpkv_options
          ).and_raise_error(ArgumentError, %r{simpkv Configuration Error})
      end
    end
  end
end
