class OsgeoPostgresql < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  url "https://ftp.postgresql.org/pub/source/v17.2/postgresql-17.2.tar.bz2"
  sha256 "82ef27c0af3751695d7f64e2d963583005fbb6a0c3df63d0e4b42211d7021164"
  license "PostgreSQL"

  bottle do
    root_url "https://bottle.download.osgeo.org"
    rebuild 1
    sha256 cellar: :any, ventura: "PLACEHOLDER"
    sha256 cellar: :any, monterey: "PLACEHOLDER"
    sha256 cellar: :any, sonoma: "PLACEHOLDER"
  end

  head "https://github.com/postgres/postgres.git", branch: "master"

  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "icu4c"
  depends_on "krb5"
  depends_on "lz4"
  depends_on "openldap"
  depends_on "openssl@3"
  depends_on "perl"
  depends_on "python@3.12"
  depends_on "readline"
  depends_on "tcl-tk"
  depends_on "zstd"

  uses_from_macos "libxml2"
  uses_from_macos "libxslt"
  uses_from_macos "zlib"

  on_macos do
    depends_on "llvm" if DevelopmentTools.clang_build_version <= 1200
  end

  on_linux do
    depends_on "linux-pam"
  end

  conflicts_with "postgresql", because: "both install the same binaries"

  def install
    ENV["XML2_CONFIG"] = "xml2-config --exec-prefix=/usr"
    ENV.prepend "LDFLAGS", "-L#{Formula["openssl@3"].opt_lib} -L#{Formula["readline"].opt_lib}"
    ENV.prepend "CPPFLAGS", "-I#{Formula["openssl@3"].opt_include} -I#{Formula["readline"].opt_include}"

    ENV["PYTHON"] = which("python3.12")

    args = %W[
      --disable-debug
      --enable-thread-safety
      --with-gssapi
      --with-icu
      --with-ldap
      --with-libxml
      --with-libxslt
      --with-lz4
      --with-zstd
      --with-openssl
      --with-perl
      --with-python
      --with-tcl
      --with-uuid=e2fs
      --enable-dtrace
      --enable-nls
      --prefix=#{prefix}
      --datadir=#{pkgshare}
      --libdir=#{lib}
      --includedir=#{include}
      --sysconfdir=#{etc}
      --docdir=#{doc}
    ]

    # Add PAM support only on macOS
    args << "--with-pam" if OS.mac?
    args << "--with-bonjour" if OS.mac?

    # The CLT is required to build Tcl support
    if OS.mac? && File.exist?("#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework/tclConfig.sh")
      args << "--with-tclconfig=#{MacOS.sdk_path}/System/Library/Frameworks/Tcl.framework"
    end

    # Add include and library directories of dependencies, so that
    # they can be used for compiling extensions.  Superenv does this
    # when compiling this package, but won't record it for pg_config.
    deps = %w[gettext icu4c openldap openssl@3 readline tcl-tk]
    with_includes = deps.map { |f| Formula[f].opt_include }.join(":")
    with_libraries = deps.map { |f| Formula[f].opt_lib }.join(":")
    args << "--with-includes=#{with_includes}"
    args << "--with-libraries=#{with_libraries}"

    system "./configure", *args
    system "make"
    system "make", "install-world", "datadir=#{pkgshare}",
                                     "libdir=#{lib}",
                                     "pkglibdir=#{lib}/postgresql",
                                     "includedir=#{include}",
                                     "pkgincludedir=#{include}/postgresql",
                                     "includedir_server=#{include}/postgresql/server",
                                     "includedir_internal=#{include}/postgresql/internal"
  end

  def post_install
    (var/"log").mkpath
    (var/"postgres").mkpath
    return if File.exist?("#{var}/postgres/PG_VERSION")

    system bin/"initdb", "--locale=C", "-E", "UTF-8", var/"postgres"
  end

  def caveats
    <<~EOS
      To start postgresql:
        brew services start #{name}

      Or, if you don't want/need a background service you can just run:
        pg_ctl -D #{var}/postgres start

      To stop postgresql:
        brew services stop #{name}

      Or, if you don't use services:
        pg_ctl -D #{var}/postgres stop

      To migrate existing data from a previous major version:
        pg_upgrade -b #{HOMEBREW_PREFIX}/opt/osgeo-postgresql@<old_version>/bin \\
                   -B #{opt_bin} \\
                   -d #{var}/postgres@<old_version> \\
                   -D #{var}/postgres

      For more information:
        https://www.postgresql.org/docs/17/
    EOS
  end

  service do
    run [opt_bin/"postgres", "-D", var/"postgres"]
    keep_alive true
    log_path var/"log/postgresql.log"
    error_log_path var/"log/postgresql.log"
    working_dir HOMEBREW_PREFIX
  end

  test do
    system bin/"initdb", testpath/"test"
    assert_equal "#{pkgshare}", shell_output("#{bin}/pg_config --sharedir").chomp
    assert_equal "#{lib}", shell_output("#{bin}/pg_config --libdir").chomp
    assert_equal "#{lib}/postgresql", shell_output("#{bin}/pg_config --pkglibdir").chomp
  end
end
