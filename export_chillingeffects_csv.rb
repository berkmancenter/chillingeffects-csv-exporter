require './lib/downloader'
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
       group_concat(originals.Location)  AS OriginalFilePath,
       group_concat(supporting.Location) AS SupportingFilePath
  FROM tNotice
LEFT JOIN tNotImage originals
       ON originals.NoticeID   = tNotice.NoticeID
      AND originals.ReadLevel != 0
LEFT JOIN tNotImage supporting
       ON supporting.NoticeID   = tNotice.NoticeID
      AND supporting.ReadLevel != 0
WHERE tNotice.Subject IS NOT NULL
GROUP BY tNotice.NoticeID
ORDER BY tNotice.NoticeID DESC
LIMIT 100
EOSQL

exporter.write_csv(notice_sql, 'tNotice.csv')
