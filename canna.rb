require 'formula'

class Canna < Formula
  homepage 'http://canna.sourceforge.jp/'
  url 'http://sourceforge.jp/frs/redir.php?m=jaist&f=%2Fcanna%2F9565%2FCanna37p3.tar.bz2'
  #md5 '0b8c241f63ab4cd3c0b9be569456dc33'
  sha1 'e39eece7c70c669dd46dd74b26121a60a2496fde'
  version '3.7p3'

  depends_on 'imake' => :build
  depends_on 'gcc' => :build

  def patches
    # From Fink.
    #{ 'p1' =>
    #  "http://fink.cvs.sourceforge.net/viewvc/fink/dists/10.4/stable/main/finkinfo/utils/canna.patch?revision=1.2"
    #}
    DATA
  end

  def install
    inreplace 'Canna.conf', '@PREFIX@', prefix
    inreplace 'Canna.conf', '@HOMEBREW_VAR@', var

    inreplace 'update-canna-dics-dir', '@PREFIX@', prefix
    inreplace 'update-canna-dics-dir', '@HOMEBREW_VAR@', var

    cpp_program = Formula["gcc"].prefix/"bin/cpp-#{Formula["gcc"].version_suffix}"
    ENV['IMAKECPP'] = cpp_program

    system "xmkmf"

    previous_makeflags = ENV['MAKEFLAGS']
    ENV.deparallelize
    system "make canna"
    system "make install"
    system "make install.man"
    ENV['MAKEFLAGS'] = previous_makeflags

    ln_sf HOMEBREW_PREFIX+"include", include+"canna"

    system "install -c -m 755 update-canna-dics-dir #{prefix}/sbin/"

    system "install -d -m 755 #{etc}/canna"
    system "install -c -m 644 hosts.canna #{etc}/canna/"
    system "install -c -m 755 misc/rc.canna #{etc}/canna/"

    system "mv #{etc}/canna/rc.canna #{etc}/canna/rc.canna-root"
    system "sed 's/ -u canna / /' < #{etc}/canna/rc.canna-root > #{etc}/canna/rc.canna"
    system "chmod 755 #{etc}/canna/rc.canna"
    plist_path.write startup_plist
    plist_path.chmod 0644

    #system "install -d -m 755 #{var}/lib/canna/dics.d"
    #system "mv #{var}/lib/canna/dic/canna/dics.dir #{var}/lib/canna/dics.d/00default"
    #system "touch #{var}/lib/canna/dic/canna/dics.dir"
  end

  def caveats; <<-EOS.undent
    To run as, for instance, user "canna", you may need to `sudo`:
        sudo #{etc}/canna/rc.canna-root start

    Start Canna manually with:
        #{etc}/canna/rc.canna start

    To launch on startup:
    * if this is your first install:
        mkdir -p ~/Library/LaunchAgents
        cp #{plist_path} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    * if this is an upgrade and you already have the #{plist_path.basename} loaded:
        launchctl unload -w ~/Library/LaunchAgents/#{plist_path.basename}
        #{etc}/canna/rc.canna stop
        cp #{plist_path} ~/Library/LaunchAgents/
        launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}
    EOS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>KeepAlive</key>
  <false/>
  <key>Label</key>
  <string>#{plist_name}</string>
  <key>ProgramArguments</key>
  <array>
    <string>#{HOMEBREW_PREFIX}/etc/canna/rc.canna</string>
    <string>start</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>#{HOMEBREW_PREFIX}</string>
  <key>StandardErrorPath</key>
  <string>#{var}/log/canna/server.log</string>
</dict>
</plist>
    EOPLIST
  end

  def test
    # This test will fail and we won't accept that! It's enough to just
    # replace "false" with the main program this formula installs, but
    # it'd be nice if you were more thorough. Test the test with
    # `brew test Canna`. Remove this comment before submitting
    # your pull request!
    system "false"
  end
end

__END__
diff -Naur Canna37p3.orig/Canna.conf Canna37p3/Canna.conf
--- Canna37p3.orig/Canna.conf	2004-05-19 11:48:47.000000000 -0400
+++ Canna37p3/Canna.conf	2011-04-03 08:18:18.000000000 -0400
@@ -140,19 +140,23 @@
 # define ModernElfLinkAvailable NO
 #endif
 
-cannaPrefix = DefCannaPrefix
+#define MyCCOptions -no-cpp-precomp -Wall -Wpointer-arith -Wno-implicit-int -Wno-return-type
+#undef LibraryCCOptions
+#define LibraryCCOptions MyCCOptions -fno-common
+CCOPTIONS = MyCCOptions
+
+cannaPrefix = @PREFIX@
 cannaExecPrefix = $(cannaPrefix)
 cannaBinDir = $(cannaExecPrefix)/bin
 cannaSrvDir = DefCannaSrvDir
 XCOMM cannaLibDir = /var/lib/canna
 XCOMM cannaLibDir = /var/db/canna
 cannaLibDir = DefCannaLibDir
-XCOMM cannaManDir = $(cannaPrefix)/share/man
-cannaManDir = $(cannaPrefix)/man
+cannaManDir = $(cannaPrefix)/share/man
 cannaIncDir = $(cannaPrefix)/include/canna
 
 libCannaDir = DefLibCannaDir
-ErrDir  = DefErrDir
+ErrDir  = @HOMEBREW_VAR@/log/canna
 
 /* 旧バージョンとの互換APIを無効にする場合は0と定義してください */
 #define SupportOldWchar 1
@@ -169,8 +173,8 @@
 #define ModernElfLink NO /* experimental */
 
 
-cannaOwner = bin
-cannaGroup = bin
+cannaOwner = daemon
+cannaGroup = daemon
 
 #ifdef InstallAsUser
 cannaOwnerGroup =
@@ -199,13 +203,13 @@
 CHGRP = :
 CHMOD = :
 #else
-CHOWN = chown
-CHGRP = chgrp
-CHMOD = chmod
+CHOWN = /usr/sbin/chown
+CHGRP = /usr/bin/chgrp
+CHMOD = /bin/chmod
 #endif
 
 /* 日本語マニュアルを使わないのであればコメントアウト */
-#define JAPANESEMAN
+/* #define JAPANESEMAN */
 
 /* #define engineSwitch */
 
@@ -237,7 +241,7 @@
 /* #define UseInstalledLibCanna YES */
 #define UseInstalledLibCanna NO
 
-DicDir   = $(cannaLibDir)/dic
+DicDir   = @HOMEBREW_VAR@/lib/canna/dic
 
 /* ここから下は変更不要です */
 
@@ -343,7 +347,7 @@
 AccessFile = $(cannaPrefix)/etc/hosts.canna
 #else
 UnixSockDir = /tmp/.iroha_unix
-AccessFile = /etc/hosts.canna
+AccessFile = $(cannaPrefix)/etc/canna/hosts.canna
 #endif
 UnixSockName = IROHA
 
@@ -622,7 +626,7 @@
 step::									@@\
 	@case '${MFLAGS}' in *[i]*) set +e;; esac;			@@\
 	DirFailPrefix@for i in dirs; do if [ -d $(DESTDIR)$$i ]; then \	@@\
-		set +x; else (set -x; $(MKDIRHIER) $(DESTDIR)$$i;$(CHOWN) owner $(DESTDIR)$$i;$(CHGRP) group $(DESTDIR)$$i); fi; \	@@\
+		set +x; else (set -x; $(MKDIRHIER) $(DESTDIR)$$i); fi; \	@@\
 	done
 #endif /* MakeDirectoriesLong */
 
diff -Naur Canna37p3.orig/canna/widedef.h Canna37p3/canna/widedef.h
--- Canna37p3.orig/canna/widedef.h	Sat Dec 27 17:15:20 2003
+++ Canna37p3/canna/widedef.h	Sun May 29 15:00:31 2005
@@ -32,12 +32,12 @@
 #endif
 
 #if (defined(__FreeBSD__) && __FreeBSD_version < 500000) \
-    || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__APPLE__)
+    || defined(__NetBSD__) || defined(__OpenBSD__)
 # include <machine/ansi.h>
 #endif
 
 #if (defined(__FreeBSD__) && __FreeBSD_version < 500000) \
-    || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__APPLE__)
+    || defined(__NetBSD__) || defined(__OpenBSD__)
 # ifdef _BSD_WCHAR_T_
 #  undef _BSD_WCHAR_T_
 #  ifdef WCHAR16
@@ -45,10 +45,6 @@
 #  else
 #   define _BSD_WCHAR_T_ unsigned long
 #  endif
-#  if defined(__APPLE__) && defined(__WCHAR_TYPE__)
-#   undef __WCHAR_TYPE__
-#   define __WCHAR_TYPE__ _BSD_WCHAR_T_
-#  endif
 #  include <stddef.h>
 #  define _WCHAR_T
 # endif
@@ -59,6 +55,14 @@
 # endif
 # include <stddef.h>
 # define _WCHAR_T
+#elif defined(__APPLE__)
+# ifdef WCHAR16
+typedef unsigned short wchar_t;
+# else
+typedef unsigned long wchar_t;
+# endif
+# define _BSD_WCHAR_T_DEFINED_ /* <= 10.3 */
+# define _WCHAR_T /* >= 10.4 */
 #else
 #if !defined(WCHAR_T) && !defined(_WCHAR_T) && !defined(_WCHAR_T_) \
  && !defined(__WCHAR_T) && !defined(_GCC_WCHAR_T) && !defined(_WCHAR_T_DEFINED)
diff -Naur Canna37p3.orig/dic/ideo/grammar/Imakefile Canna37p3/dic/ideo/grammar/Imakefile
--- Canna37p3.orig/dic/ideo/grammar/Imakefile	2003-09-27 02:18:38.000000000 -0400
+++ Canna37p3/dic/ideo/grammar/Imakefile	2011-04-03 08:24:11.000000000 -0400
@@ -77,9 +77,5 @@
 
 MakeDirectories(install,$(CANNADICDIR))
 
-InstallMultipleFlags($(ALLDIC),$(CANNADICDIR),-m 0664 $(cannaOwnerGroup))
+InstallMultipleFlags($(ALLDIC),$(CANNADICDIR),-m 0664)
 
-install::
-	$(CHGRP) $(cannaGroup) $(DESTDIR)$(CANNADICDIR)
-	$(CHOWN) $(cannaOwner) $(DESTDIR)$(CANNADICDIR)
-	$(CHMOD) ug+w $(DESTDIR)$(CANNADICDIR)
diff -Naur Canna37p3.orig/dic/ideo/words/Imakefile Canna37p3/dic/ideo/words/Imakefile
--- Canna37p3.orig/dic/ideo/words/Imakefile	2003-09-27 02:18:39.000000000 -0400
+++ Canna37p3/dic/ideo/words/Imakefile	2011-04-03 08:35:53.000000000 -0400
@@ -63,7 +63,7 @@
 
 MakeDirectories(install,$(CANNADICDIR))
 
-InstallMultipleFlags($(TARGETS),$(CANNADICDIR),-m 0664 $(cannaOwnerGroup))
+InstallMultipleFlags($(TARGETS),$(CANNADICDIR),-m 0664)
 
 #ifdef USE_OBSOLETE_STYLE_FILENAME
 InstallNamedNonExec(obsolete.dir,dics.dir,$(CANNADICDIR))
@@ -98,7 +98,7 @@
 #else
     TEXTDICS = necgaiji.t kanasmpl.t software.t chimei.t \
                hojomwd.t hojoswd.t suffix.t number.t katakana.t keishiki.t
-InstallMultipleFlags($(TEXTDICS),$(CANNADICDIR),-m 0664 $(cannaOwnerGroup))
+InstallMultipleFlags($(TEXTDICS),$(CANNADICDIR),-m 0664)
 #endif
 
 depend::
diff -Naur Canna37p3.orig/dic/ideo/words/chimei.t Canna37p3/dic/ideo/words/chimei.t
--- Canna37p3.orig/dic/ideo/words/chimei.t	Sat Sep 27 06:18:39 2003
+++ Canna37p3/dic/ideo/words/chimei.t	Sun May 29 14:59:54 2005
@@ -714,7 +714,7 @@
 じょうせき #CN 城跡
 じょうとうく #CNS 城東区
 じょうなんく #CNS 城南区
-じょうばんせん #CNS 常盤線
+じょうばんせん #CNS 常磐線
 じょうようし #CNS 城陽市
 じょほーる #CN ジョホール
 じんぐうまえ #CN 神宮前
diff -Naur Canna37p3.orig/dic/phono/Imakefile Canna37p3/dic/phono/Imakefile
--- Canna37p3.orig/dic/phono/Imakefile	Sat Oct 19 08:27:40 2002
+++ Canna37p3/dic/phono/Imakefile	Sun May 29 14:59:54 2005
@@ -25,7 +25,11 @@
                 KPDIC = $(CMDDIR)/kpdic/kpdic
 #endif
 
+#ifdef HasGcc
+       ROMAJI_DIC_DEF = -DSHIFT -traditional
+#else
        ROMAJI_DIC_DEF = -DSHIFT
+#endif
 
                DICDIR = $(cannaLibDir)/dic
             SAMPLEDIR = $(cannaLibDir)/sample
diff -Naur Canna37p3.orig/hosts.canna Canna37p3/hosts.canna
--- Canna37p3.orig/hosts.canna	Thu Jan  1 00:00:00 1970
+++ Canna37p3/hosts.canna	Sun May 29 14:59:54 2005
@@ -0,0 +1,2 @@
+unix
+localhost
diff -Naur Canna37p3.orig/lib/canna/lisp.c Canna37p3/lib/canna/lisp.c
--- Canna37p3.orig/lib/canna/lisp.c	Mon Apr 26 22:49:21 2004
+++ Canna37p3/lib/canna/lisp.c	Thu Mar 23 17:24:20 2006
@@ -2643,15 +2643,21 @@
 int n;
 {
   list p, t;
-  FILE *instream, *fopen();
+  list noerror = NIL;
+  FILE *instream;
 
-  argnchk("load",1);
+  if (n != 1 && n != 2)
+    argnerr("load");
+  if (n == 2)
+    noerror = pop1();
   p = pop1();
   if ( !stringp(p) ) {
     error("load: illegal file name  ",p);
     /* NOTREACHED */
   }
   if ((instream = fopen(xstring(p), "r")) == (FILE *)NULL) {
+    if (noerror)
+      return NIL;
     error("load: file not found  ",p);
     /* NOTREACHED */
   }
diff -Naur Canna37p3.orig/server/util.c Canna37p3/server/util.c
--- Canna37p3.orig/server/util.c	Sun Sep 21 12:56:29 2003
+++ Canna37p3/server/util.c	Sat Jun  4 15:28:41 2005
@@ -24,10 +24,10 @@
 static char rcs_id[] = "$Id: util.c,v 1.8 2003/09/21 12:56:29 aida_s Exp $";
 #endif
 
-#include "server.h"
-#if 1 /* unused */
+#if 0 /* unused */
 #include "widedef.h"
 #endif
+#include "server.h"
 
 size_t
 ushort2euc(src, srclen, dest, destlen)
@@ -104,7 +104,7 @@
   return j;
 }
 
-#if 1 /* unused */
+#if 0 /* unused */
 size_t
 wchar2ushort32(src, srclen, dest, destlen)
 register const wchar_t *src;
diff -Naur Canna37p3.orig/update-canna-dics-dir Canna37p3/update-canna-dics-dir
--- Canna37p3.orig/update-canna-dics-dir	Thu Jan  1 00:00:00 1970
+++ Canna37p3/update-canna-dics-dir	Sun May 29 14:59:54 2005
@@ -0,0 +1,15 @@
+#!/bin/sh -e
+
+PATH=/bin:/sbin:/usr/bin:/usr/sbin:@PREFIX@/bin:@PREFIX@/sbin
+export PATH
+
+LIST_FILE=@HOMEBREW_VAR@/lib/canna/dic/canna/dics.dir
+LIST_DIR=@HOMEBREW_VAR@/lib/canna/dics.d
+
+TMPFILE=`tempfile`
+cat ${LIST_DIR}/* >>${TMPFILE}
+mv ${TMPFILE} ${LIST_FILE}
+chmod 0644 ${LIST_FILE}
+chown canna:canna ${LIST_FILE}
+
+exit 0
