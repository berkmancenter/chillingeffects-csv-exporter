require 'mysql2'
require 'csv'
require 'fileutils'
require 'pathname'
require 'open-uri'

class CsvExporter

  attr_reader :connection

  def self.connect
    self.new(
      Mysql2::Client.new(
        host: ENV['mysql_host'],
        username: ENV['mysql_username'],
        password: ENV['mysql_password'],
        port: ENV['mysql_port'].to_i,
        database: ENV['mysql_database']
    )
    )
  end

  def initialize(connection)
    @connection = connection
  end

  def query(*query)
    @connection.query(*query)
  end

  def write_csv(sql_query, csv_file_name)
    results = self.query(sql_query)
    headers = results.first.keys
    csv_file = "#{ENV['destination_dir']}#{csv_file_name}"

    CSV.open(csv_file, "wb") do |csv|
      csv << headers
    end

    results.each_slice(100) do |rows|
      rows.each do |row|
        CSV.open(csv_file, "ab") do |csv|
          csv << headers.map{|header| encode_string(row[header])}
          if original_file_path = row['OriginalFilePath']
            download_files(original_file_path)
          end
        end
      end
    end
  end

  def download_files(file_paths)
    file_paths.split(',').each do |exported_file_name|
      directory_name, file_name = Pathname.new(exported_file_name).split
      local_directory = "#{ENV['destination_dir']}#{directory_name}"

      FileUtils.mkdir_p(local_directory)
      file_to_write = "#{local_directory}/#{file_name}"

      if ! File.exists?(file_to_write)
        begin
          url_to_download = "#{ENV['url_base']}#{exported_file_name}"
          puts "Downloading: #{url_to_download}"

          File.open(file_to_write, "wb") do |file|
            open(url_to_download) do |download|
              file.write(download.read)
            end
          end
        rescue Exception => e
          puts "something bad happened"
          puts e.inspect
          File.unlink(file_to_write)
        end
      end
    end
  end

  def encode_string(input)
   if input.respond_to?(:encode)
     input.encode('utf-8')
   else
     input
   end
  end

end
