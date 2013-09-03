require 'mysql2'
require 'csv'

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

  def write_csv(sql_query, file_path)
    results = self.query(sql_query)
    headers = results.first.keys

    CSV.open(file_path, "wb") do |csv|
      csv << headers
      results.each do |row|
        csv << headers.map{|header| row[header]}
      end
    end
  end

end
