require 'spec_helper'
require 'fileutils'

describe OriginalDownloader do

  it "downloads the expected remote files" do
    OriginalDownloader::RemoteFile.any_instance.stub(:fetch).and_return(true)
    downloader = OriginalDownloader.new(
      'foo.txt,bar.html,files_by_time/4444/22/22/22/baz.html,sub/bat.html'
    )

    downloader.download

    # N.B. we actually care about order
    expect(downloader.downloaded_files).to eq %w(
      foo.txt
      bar.html bar.txt
      files_by_time/4444/22/22/22/baz.html
      files_by_time/4444/22/22/22/baz.txt baz.html
      sub/bat.html sub/bat.txt
    )
  end

  context 'OriginalDownloader::RemoteFile' do
    before { ENV['url_base'] = 'http://example.com' }

    after { FileUtils.rm_rf './sub' }

    it "downloads to a local location" do
      remote_file = OriginalDownloader::RemoteFile.new('sub/foo.txt')
      remote_file.should_receive(:open).
        with("http://example.com/sub/foo.txt").and_yield(response)

      remote_file.fetch

      expect(File.read('sub/foo.txt')).to eq "Some content"
    end

    private

    def response
      double('Response', read: "Some content")
    end
  end

end