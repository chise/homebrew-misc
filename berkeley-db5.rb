require 'formula'

class BerkeleyDb5 < Formula
  homepage 'http://www.oracle.com/technology/products/berkeley-db/index.html'
  url 'http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz'
  sha256 'e0a992d740709892e81f9d93f06daf305cf73fb81b545afe72478043172c3628'

  def options
    [['--without-java', 'Compile without Java support.']]
  end

  def install
    # BerkeleyDB5 dislikes parallel builds
    ENV.deparallelize

    args = ["--disable-debug",
            "--prefix=#{prefix}", "--mandir=#{man}",
            "--enable-cxx"]
    args << "--enable-java" unless ARGV.include? "--without-java"

    # BerkeleyDB5 requires you to build everything from the build_unix subdirectory
    cd 'build_unix' do
      system "../dist/configure", *args
      system "make install"

      # use the standard docs location
      doc.parent.mkpath
      mv prefix+'docs', doc
    end
  end
end
