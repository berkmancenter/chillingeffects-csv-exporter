require 'spec_helper'
require 'pry'
require 'csv'

describe CsvExporter do
  before(:all) do
    configure_exporter
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
    exporter.write_csv('select * from tNotice_test', 'test_export.csv')

    csv = load_csv('tmp/test_export.csv')

    expect(csv).to eq(
      [
        {'id' => '1', 'body' => 'body 0', 'subject' => 'subject 0'},
        {'id' => '2', 'body' => 'body 1', 'subject' => 'subject 1'}
      ])
  end

  %w( OriginalFilePath SupportingFilePath ).each do |field|
    it "uses Downloader and updates #{field}" do
      downloader = Downloader.new('')
      downloader.should_receive(:download)
      downloader.should_receive(:downloaded_files).and_return([
        'foo/bar.txt', 'baz.txt'
      ])
      Downloader.should_receive(:new).
        with('foo/bar.html,baz.txt').and_return(downloader)
      exporter = CsvExporter.connect

      exporter.write_csv("select *, \"foo/bar.html,baz.txt\" as #{field} from tNotice_test limit 1", 'test_export.csv')

      csv = load_csv('./tmp/test_export.csv')
      expect(csv.first[field]).to eq 'foo/bar.txt,baz.txt'
    end
  end

  private

  def load_csv(path)
    csv = []
    CSV.foreach(path, headers: true) do |csv_row|
      csv << csv_row.to_hash
    end
    csv
  end

  def configure_exporter
    ENV['mysql_host'] = 'localhost'
    ENV['mysql_port'] = '3306'
    ENV['mysql_username'] = 'chill_user'
    ENV['mysql_password'] = 'chill_pass'
    ENV['mysql_database'] = 'chill_prod'
    ENV['destination_dir'] = 'tmp/downloads/'
    ENV['url_base'] = 'http://www.example.com/'
  end

  def initialize_mysql_database
    connection = CsvExporter.connect
    connection.query('DROP TABLE IF EXISTS `tNotice_test`')
    connection.query(<<-EOSQL)
      CREATE TABLE `tNotice_test` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `body` longtext,
        `subject` varchar(85) DEFAULT NULL,
        PRIMARY KEY (`id`)
      )
    EOSQL

    2.times do |i|
      connection.query(<<-EOSQL)
        INSERT INTO tNotice_test(body, subject)
        VALUES('body #{i}', 'subject #{i}')
      EOSQL
    end
  end

end
