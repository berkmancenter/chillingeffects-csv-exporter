class OriginalDownloader

  attr_reader :downloaded_files

  def initialize(file_paths)
    @file_paths = file_paths.split(',')
    @downloaded_files = []
  end

  def download
    file_paths.each do |file_path|
      potential_paths(file_path).each do |remote_file|
        file = RemoteFile.new(remote_file)
        file.fetch and downloaded_files << remote_file
      end
    end
  end

  private

  attr_reader :file_paths

  def potential_paths(file_path)
    [
      file_path,
      file_path.sub(/\.html$/, '.txt'),
      file_path.sub(%r{files_by_time/\d{4}/(\d{2}/){3}}, '')
    ].uniq
  end

  class RemoteFile
    include FileUtils

    def initialize(file_path)
      @file_path = file_path
      @directory = File.dirname(file_path)
    end

    def fetch
      return if File.exists?(file_path)

      mkdir_p(directory)

      File.open(file_path, "wb") do |file|
        open(remote_url) do |download|
          file.write(download.read)
        end
      end
    rescue Exception => ex
      $stderr.puts "Error (#{file_path})", ex.inspect
      rm file_path; false
    end

    private

    attr_reader :file_path, :directory

    def remote_url
      URI.join(ENV['url_base'], file_path).to_s
    end
  end

end
