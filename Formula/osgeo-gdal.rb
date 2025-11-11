class OsgeoGdal < Formula
  desc "GDAL: Geospatial Data Abstraction Library"
  homepage "https://www.gdal.org/"
  url "https://download.osgeo.org/gdal/3.11.5/gdal-3.11.5.tar.xz"
  sha256 "79f66756f1c843b5ee52c8482d4f6bd2a8b7706d6161cc11f0b27c83d638796a"
  license "MIT"

  bottle do
    root_url "https://bottle.download.osgeo.org"
    rebuild 1
    sha256 cellar: :any, ventura: "PLACEHOLDER"
    sha256 cellar: :any, monterey: "PLACEHOLDER"
    sha256 cellar: :any, sonoma: "PLACEHOLDER"
  end

  head do
    url "https://github.com/OSGeo/gdal.git", branch: "master"
    depends_on "doxygen" => :build
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build

  # Core libraries
  depends_on "cfitsio"
  depends_on "curl"
  depends_on "expat"
  depends_on "freexl"
  depends_on "geos"
  depends_on "giflib"
  depends_on "hdf5"
  depends_on "json-c"
  depends_on "libdap"
  depends_on "libgeotiff"
  depends_on "libpng"
  depends_on "libpq"
  depends_on "libtiff"
  depends_on "libxml2"
  depends_on "jpeg-turbo"
  depends_on "libspatialite"
  depends_on "netcdf"
  depends_on "openjpeg"
  depends_on "openssl@3"
  depends_on "osgeo-proj"
  depends_on "pcre2"
  depends_on "python@3.12"
  depends_on "qhull"
  depends_on "sfcgal"
  depends_on "sqlite"
  depends_on "unixodbc"
  depends_on "webp"
  depends_on "xerces-c"
  depends_on "xz"
  depends_on "zstd"

  uses_from_macos "zlib"

  conflicts_with "gdal", because: "both install the same binaries"

  def python3
    "python3.12"
  end

  def install
    # GDAL 3.x uses CMake
    args = %W[
      -DBUILD_PYTHON_BINDINGS=ON
      -DBUILD_JAVA_BINDINGS=OFF
      -DGDAL_USE_PROJ=ON
      -DGDAL_USE_GEOS=ON
      -DGDAL_USE_SFCGAL=ON
      -DGDAL_USE_CURL=ON
      -DGDAL_USE_EXPAT=ON
      -DGDAL_USE_LIBXML2=ON
      -DGDAL_USE_ZLIB=ON
      -DGDAL_USE_ZSTD=ON
      -DGDAL_USE_PNG=ON
      -DGDAL_USE_JPEG=ON
      -DGDAL_USE_GIF=ON
      -DGDAL_USE_WEBP=ON
      -DGDAL_USE_TIFF=ON
      -DGDAL_USE_GEOTIFF=ON
      -DGDAL_USE_SQLITE3=ON
      -DGDAL_USE_POSTGRESQL=ON
      -DGDAL_USE_SPATIALITE=ON
      -DGDAL_USE_HDF5=ON
      -DGDAL_USE_NETCDF=ON
      -DGDAL_USE_OPENJPEG=ON
      -DGDAL_USE_CFITSIO=ON
      -DGDAL_USE_JSONC=ON
      -DGDAL_USE_FREEXL=ON
      -DGDAL_USE_ODBC=ON
      -DGDAL_USE_OPENCL=OFF
      -DGDAL_USE_QHULL=ON
      -DPython_EXECUTABLE=#{which(python3)}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Install Python bindings
    cd "swig/python" do
      system python3, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."
    end
  end

  def caveats
    <<~EOS
      GDAL has been installed with support for most common formats.

      To see all available formats:
        gdalinfo --formats

      Python bindings have been installed for #{python3}.

      Documentation: https://gdal.org/
    EOS
  end

  test do
    # Test GDAL utilities
    system bin/"gdalinfo", "--version"
    assert_match "GTiff", shell_output("#{bin}/gdalinfo --formats")
    assert_match "PostgreSQL", shell_output("#{bin}/ogrinfo --formats")

    # Test Python bindings
    system python3, "-c", "from osgeo import gdal; print(gdal.__version__)"

    # Test basic conversion
    (testpath/"test.geojson").write <<~JSON
      {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [0.0, 0.0]
        },
        "properties": {
          "name": "test"
        }
      }
    JSON

    system bin/"ogr2ogr", "-f", "ESRI Shapefile", testpath/"test.shp", testpath/"test.geojson"
    assert_predicate testpath/"test.shp", :exist?
  end
end
