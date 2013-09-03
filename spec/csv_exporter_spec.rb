require 'spec_helper'
require 'pry'
require 'csv'

describe CsvExporter do
  before(:all) do
    configure_mysql_connection
  end

  before(:each) do
    initialize_mysql_database
  end

  it 'can connect to mysql' do
    connection = CsvExporter.connect
    expect(connection.query('show variables', as: :array).count).to be > 1
  end

  it 'exports valid csv' do
    exporter = CsvExporter.connect
    exporter.write_csv('select * from tNotice', 'tmp/test_export.csv')

    csv = load_csv('tmp/test_export.csv')

    expect(csv).to eq(
      [
        {'id' => '1', 'body' => 'body 0', 'subject' => 'subject 0'},
        {'id' => '2', 'body' => 'body 1', 'subject' => 'subject 1'}
      ])
  end

 private

 def load_csv(path)
   csv = []
   CSV.foreach(path, headers: true) do |csv_row|
     csv << csv_row.to_hash
   end
   csv
 end

  def configure_mysql_connection
    ENV['mysql_host'] = 'localhost'
    ENV['mysql_port'] = '3306'
    ENV['mysql_username'] = 'chill_user'
    ENV['mysql_password'] = 'chill_pass'
    ENV['mysql_database'] = 'chill_prod'
  end

  def initialize_mysql_database
    connection = CsvExporter.connect
    connection.query('drop table `tNotice`')
    connection.query(
      'CREATE TABLE `tNotice` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `body` longtext,
  `subject` varchar(85) DEFAULT NULL,
  PRIMARY KEY (`id`)
  )')

  2.times do |i|
    connection.query(
      "insert into tNotice(body, subject) 
      values('body #{i}', 'subject #{i}')"
    )
  end

  end

end
