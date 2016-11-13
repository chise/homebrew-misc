require 'formula'

class BerkeleyDb5 < Formula
  homepage 'http://www.oracle.com/technology/products/berkeley-db/index.html'
  url 'http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz'
  sha256 'e0a992d740709892e81f9d93f06daf305cf73fb81b545afe72478043172c3628'

  def options
    [['--without-java', 'Compile without Java support.']]
  end

  # Fix build under Xcode 4.6
  patch :DATA

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

__END__
diff -ur db-5.3.28/src/dbinc/atomic.h db-5.3.28-fixed/src/dbinc/atomic.h
--- db-5.3.28/src/dbinc/atomic.h	2013-09-10 00:35:08.000000000 +0900
+++ db-5.3.28-fixed/src/dbinc/atomic.h	2016-11-13 18:36:18.000000000 +0900
@@ -144,7 +144,7 @@
 #define	atomic_inc(env, p)	__atomic_inc(p)
 #define	atomic_dec(env, p)	__atomic_dec(p)
 #define	atomic_compare_exchange(env, p, o, n)	\
-	__atomic_compare_exchange((p), (o), (n))
+	__atomic_compare_exchange_db((p), (o), (n))
 static inline int __atomic_inc(db_atomic_t *p)
 {
 	int	temp;
@@ -176,7 +176,7 @@
  * http://gcc.gnu.org/onlinedocs/gcc-4.1.0/gcc/Atomic-Builtins.html
  * which configure could be changed to use.
  */
-static inline int __atomic_compare_exchange(
+static inline int __atomic_compare_exchange_db(
 	db_atomic_t *p, atomic_value_t oldval, atomic_value_t newval)
 {
 	atomic_value_t was;
