class OsgeoProj < Formula
  desc "Cartographic Projections Library"
  homepage "https://proj.org/"
  url "https://download.osgeo.org/proj/proj-9.7.0.tar.gz"
  sha256 "65705ecd987b50bf63e15820ce6bd17c042feaabda981249831bd230f6689709"
  license "MIT"

  bottle do
    root_url "https://bottle.download.osgeo.org"
    rebuild 1
    sha256 cellar: :any, ventura: "PLACEHOLDER"
    sha256 cellar: :any, monterey: "PLACEHOLDER"
    sha256 cellar: :any, sonoma: "PLACEHOLDER"
  end

  head do
    url "https://github.com/OSGeo/PROJ.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "libtiff"
  depends_on "sqlite"

  conflicts_with "proj", because: "both install the same binaries"
  conflicts_with "blast", because: "both install a `libproj.a` library"

  def install
    # PROJ 7+ uses CMake instead of autotools
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args,
                    "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test").write <<~EOS
      45d15n 71d07w Boston, United States
      40d40n 73d58w New York, United States
      48d51n 2d20e Paris, France
      51d30n 7'w London, England
    EOS
    match = <<~EOS
      -4887590.49\t7317961.48 Boston, United States
      -5542524.55\t6982689.05 New York, United States
      171224.94\t5415352.81 Paris, France
      -8101.66\t5707500.23 London, England
    EOS

    output = shell_output("#{bin}/proj +proj=poly +ellps=clrk66 -r #{testpath}/test")
    assert_equal match, output
  end
end
