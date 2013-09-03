require './lib/csv_exporter.rb'

ENV['mysql_host'] ||= 'localhost'
ENV['mysql_port'] ||= '3306'
ENV['mysql_username'] ||= 'chill_user'
ENV['mysql_password'] ||= 'chill_pass'
ENV['mysql_database'] ||= 'chill_prod'

exporter = CsvExporter.connect

notice_sql = 'select * from tNotice limit 10'
exporter.write_csv(notice_sql, 'tmp/tNotice.csv')
