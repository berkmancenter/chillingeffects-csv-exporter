require './lib/original_downloader'
require './lib/csv_exporter.rb'

ENV['mysql_host'] ||= 'localhost'
ENV['mysql_port'] ||= '3306'
ENV['mysql_username'] ||= 'chill_user'
ENV['mysql_password'] ||= 'chill_pass'
ENV['mysql_database'] ||= 'chill_prod'
ENV['url_base'] ||= 'http://www.example.com/'
ENV['destination_dir'] ||= 'downloads/'

exporter = CsvExporter.connect

notice_sql = <<EOSQL
SELECT tNotice.*,
       GROUP_CONCAT(tNotImage.Location) AS OriginalFilePath
  FROM tNotice
  JOIN tNotImage
    ON tNotImage.NoticeID = tNotice.NoticeID
GROUP BY tNotice.NoticeID
ORDER BY RAND() LIMIT 100
EOSQL

exporter.write_csv(notice_sql, 'tNotice.csv')
