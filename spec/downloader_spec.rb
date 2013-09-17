require 'spec_helper'
require 'fileutils'

describe Downloader do

  it "downloads the expected remote files" do
    Downloader::RemoteFile.any_instance.stub(:fetch).and_return(true)
    downloader = Downloader.new(
      'foo.txt,bar.html,files_by_time/4444/22/22/22/baz.html,sub/bat.html'
    )

    downloader.download

    # N.B. we actually care about order
    expect(downloader.downloaded_files).to eq %w(
      foo.txt
      bar.txt
      files_by_time/4444/22/22/22/baz.txt
      sub/bat.txt
    )
  end

  context 'Downloader::RemoteFile' do
    before { ENV['url_base'] = 'http://example.com' }

    after { FileUtils.rm_rf './sub' }

    it "downloads to a local location" do
      remote_file = Downloader::RemoteFile.new('sub/foo.txt')
      remote_file.stub(:puts)
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
