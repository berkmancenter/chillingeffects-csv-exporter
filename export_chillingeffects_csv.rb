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

notice_slices = [
  [0, 250000],
  [250000, 500000],
  [500000, 600000],
  [600000, 700000],
  [700000, 800000],
  [800000, 900000],
  [900000, 1000000],
  [1000000, 1100000],
  [1100000, 1500000]
]

notice_slices.each do |notice_slice|
exporter.write_csv(<<EOSQL, "tNotice-#{notice_slice[0]}.csv")
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
WHERE tNotice.Subject IS NOT NULL AND
(tNotice.NoticeID > #{notice_slice[0]} and tNotice.NoticeID <= #{notice_slice[1]})
GROUP BY tNotice.NoticeID
ORDER BY tNotice.NoticeID ASC
EOSQL
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
