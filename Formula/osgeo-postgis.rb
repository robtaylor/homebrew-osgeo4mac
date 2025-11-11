class OsgeoPostgis < Formula
  desc "Adds support for geographic objects to PostgreSQL"
  homepage "https://postgis.net/"
  url "https://download.osgeo.org/postgis/source/postgis-3.6.0.tar.gz"
  sha256 "8caffef4b457ed70d5328bf4e5a21f9306b06c271662e03e1a65d30090e5f25f"
  license "GPL-2.0-or-later"

  bottle do
    root_url "https://bottle.download.osgeo.org"
    rebuild 1
    sha256 cellar: :any, ventura: "PLACEHOLDER"
    sha256 cellar: :any, monterey: "PLACEHOLDER"
    sha256 cellar: :any, sonoma: "PLACEHOLDER"
  end

  head "https://github.com/postgis/postgis.git", branch: "master"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gpp" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build

  depends_on "geos"
  depends_on "json-c"
  depends_on "libxml2"
  depends_on "libxslt"
  depends_on "osgeo-gdal"
  depends_on "osgeo-postgresql"
  depends_on "osgeo-proj"
  depends_on "pcre2"
  depends_on "protobuf-c"
  depends_on "sfcgal"

  uses_from_macos "perl"

  conflicts_with "postgis", because: "both install the same binaries"

  def install
    # Work around an Xcode 15 linker issue which causes linkage against LLVM's
    # libunwind due to us using `-L/usr/local/lib` to pick up Homebrew's libs.
    ENV.remove "HOMEBREW_LIBRARY_PATHS", Formula["llvm"].opt_lib if DevelopmentTools.clang_build_version >= 1500

    ENV.deparallelize

    args = %W[
      --with-projdir=#{Formula["osgeo-proj"].opt_prefix}
      --with-jsondir=#{Formula["json-c"].opt_prefix}
      --with-pgconfig=#{Formula["osgeo-postgresql"].opt_bin}/pg_config
      --with-geosconfig=#{Formula["geos"].opt_bin}/geos-config
      --with-gdalconfig=#{Formula["osgeo-gdal"].opt_bin}/gdal-config
      --with-sfcgal=#{Formula["sfcgal"].opt_bin}/sfcgal-config
      --with-protobufdir=#{Formula["protobuf-c"].opt_bin}
    ]

    system "./autogen.sh" if build.head?
    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  def post_install
    # Ensure the extension directory exists
    Formula["osgeo-postgresql"].var.mkpath
  end

  def caveats
    <<~EOS
      To use PostGIS with your PostgreSQL installation:

      1. Start PostgreSQL if it's not running:
           brew services start osgeo-postgresql

      2. Create a spatial database:
           createdb mydb
           psql -d mydb -c "CREATE EXTENSION postgis;"
           psql -d mydb -c "CREATE EXTENSION postgis_topology;"
           psql -d mydb -c "CREATE EXTENSION postgis_raster;"

      3. Check PostGIS version:
           psql -d mydb -c "SELECT postgis_full_version();"

      Documentation: https://postgis.net/documentation/
    EOS
  end

  test do
    pg_version = Formula["osgeo-postgresql"].version.major
    expected = /'PostGIS built for PostgreSQL % cannot be loaded in PostgreSQL #{pg_version}'/
    postgis_sql = Formula["osgeo-postgresql"].opt_share/"postgresql/contrib/postgis-#{version.major_minor}/postgis.sql"
    assert_match expected, (testpath/"postgis.sql").read if File.exist?(postgis_sql)

    require "base64"
    (testpath/"brew.shp").write ::Base64.decode64 <<~EOS
      AAAnCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAoOgDAAAAAAAIAAAAAAAAAAAAAAAA
      AAAAAAAAAAAAAAAAAAAAAAAA
    EOS
    result = shell_output("#{bin}/shp2pgsql #{testpath}/brew.shp")
    assert_match "Point", result
    assert_match "AddGeometryColumn", result
  end
end
