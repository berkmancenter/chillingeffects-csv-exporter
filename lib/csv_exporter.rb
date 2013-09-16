require 'mysql2'
require 'csv'
require 'fileutils'
require 'pathname'
require 'open-uri'
require 'original_downloader'

class CsvExporter

  attr_reader :connection

  def self.connect
    new(
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

  def write_csv(sql_query, csv_file)
    Dir.chdir(ENV['destination_dir']) do
      results = query(sql_query)
      headers = results.first.keys

      CSV.open(csv_file, "wb") do |csv|
        csv << headers
      end

      results.each_slice(100) do |rows|
        rows.each do |row|
          CSV.open(csv_file, "ab") do |csv|
            if file_paths = row['OriginalFilePath']
              downloader = OriginalDownloader.new(file_paths)
              downloader.download

              # The actually downloaded name, may differ. Update it so we
              # don't have to duplicate the knowledge on the import side.
              row['OriginalFilePath'] = downloader.downloaded_files.join(',')
            end

            csv << headers.map{|header| encode_string(row[header])}
          end
        end
      end
    end
  end

  def query(*query)
    @connection.query(*query)
  end

  private

  def encode_string(input)
   if input.respond_to?(:encode)
     input.encode('utf-8')
   else
     input
   end
  end

end
