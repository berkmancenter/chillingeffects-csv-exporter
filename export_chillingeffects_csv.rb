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
       group_concat(supporting.Location) AS SupportingFilePath,
       tCat.CatName as CategoryName
  FROM tNotice
LEFT JOIN tNotImage originals
       ON originals.NoticeID   = tNotice.NoticeID
      AND originals.ReadLevel != 0
LEFT JOIN tNotImage supporting
       ON supporting.NoticeID   = tNotice.NoticeID
      AND supporting.ReadLevel != 0
LEFT JOIN tCat
       ON tCat.CatId = tNotice.CatId
WHERE tNotice.Subject IS NOT NULL
GROUP BY tNotice.NoticeID
ORDER BY tNotice.NoticeID DESC
LIMIT 100
EOSQL

exporter.write_csv(notice_sql, 'tNotice.csv')

blog_sql = <<EOBLOG
SELECT tNews.NewsID, concat_ws(', ', tNews.Byline, tNews.Source) as author,
  tNews.Headline as title,
  URL as url,
  CAST(tNews.Abstract as char CHARACTER SET UTF8) as abstract,
  CAST(tNews.Body as char CHARACTER SET UTF8) as content,
  tNews.add_date as published_at, tNews.add_date as created_at,
  tNews.alter_date as updated_at, tCat.CatName as CategoryName
FROM tNews
LEFT JOIN tCat
       ON tCat.CatId = tNews.CatId
where tNews.Readlevel = 0
EOBLOG

exporter.write_csv(blog_sql, 'tNews.csv')
