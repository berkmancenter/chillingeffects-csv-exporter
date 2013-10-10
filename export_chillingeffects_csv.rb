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

ids = exporter.query('select NoticeID from tNotice order by rand()').map do |row|
  row['NoticeID']
end

slice_count = 1
ids.each_slice((ids.length / 9).ceil + 1) do |slice|
  exporter.write_csv(<<EOSQL, "tNotice-#{slice_count}.csv")
SELECT tNotice.*,
       group_concat(originals.Location)  AS OriginalFilePath,
       group_concat(supporting.Location) AS SupportingFilePath,
       tCat.CatName as CategoryName, rSubmit.sID as SubmissionID
  FROM tNotice
LEFT JOIN tNotImage originals
       ON originals.NoticeID   = tNotice.NoticeID
      AND originals.ReadLevel != 0
LEFT JOIN tNotImage supporting
       ON supporting.NoticeID   = tNotice.NoticeID
      AND supporting.ReadLevel  = 0
LEFT JOIN tCat
       ON tCat.CatId = tNotice.CatId
LEFT JOIN rSubmit
       ON rSubmit.NoticeID = tNotice.NoticeID
WHERE tNotice.NoticeID in (#{slice.join(',')})
GROUP BY tNotice.NoticeID
ORDER BY tNotice.NoticeID ASC
EOSQL
  slice_count += 1
end

exporter.write_csv(<<EOSQL, 'tNews.csv')
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
EOSQL

exporter.write_csv(<<EOSQL, 'tQuestion.csv')
SELECT rQueNot.NoticeID as OriginalNoticeID,
       tQuestion.Question
  FROM rQueNot
  JOIN tQuestion
    ON tQuestion.QuestionID = rQueNot.QuestionID
EOSQL
