Puppet::Type.newtype(:ftpusers) do
  @doc = "Adds all system users to the named file, preserving any other
          entries currently in the file."

  newparam(:name) do
    isnamevar
    desc 'The file to which to write the values'

    validate do |value|
      value =~ %r{^/} or raise(ArgumentError, 'Error: :name must be an absolute path')
    end
  end

  newparam(:min_id) do
    desc 'The UID below which all values will be considered system users'
    defaultto '500'

    validate do |value|
      unless %r{^\d+$}.match?(value)
        raise(ArgumentError, "Error: '#{value}' is not a numeric UID.")
      end
    end

    munge do |value|
      Integer(value)
    end
  end

  newparam(:always_deny) do
    desc 'Entries to always add to the file'
    defaultto ['nobody', 'nfsnobody']

    munge do |value|
      Array(value)
    end
  end

  newproperty(:to_write) do
    desc 'Ignored, auto-populated from /etc/passwd'
    defaultto 'default'

    def insync?(is)
      require 'etc'

      to_deny = resource[:always_deny]
      ent = Etc.getpwent
      while ent
        if ent.uid < resource[:min_id]
          to_deny << ent.name
        end
        ent = Etc.getpwent
      end
      @should = to_deny

      @old_vals = is
      (@should - @old_vals).empty?
    end

    def sync
      tmpfile = "#{File.dirname(resource[:name])}/.~puppet_#{File.basename(resource[:name])}"
      begin
        File.exist?(tmpfile) and File.unlink(tmpfile)
        tmp_fh = File.open(tmpfile, 'w')

        tmp_fh.puts('#FTP Users file autogenerated by Puppet')
        tmp_fh.puts((@should | @old_vals).join("\n"))
        tmp_fh.close

        FileUtils.mv(tmpfile, resource[:name])
      rescue => e
        debug(e)
        err = true
      ensure
        File.exist?(tmpfile) and File.unlink(tmpfile)
      end
      raise(Puppet::Error, "Error when adding names to #{resource[:name]}") if err
    end

    def retrieve
      vals = []
      begin
        vals = File.read(resource[:name]).split("\n")
        vals.delete_if { |x| x[0].chr == '#' }
      rescue => e
        debug(e)
      end

      vals
    end
  end
end
