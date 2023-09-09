class Version
  attr_accessor :major, :minor, :patch, :build_number

  def initialize(major, minor, patch, build_number)
    @major = major
    @minor = minor
    @patch = patch
    @build_number = build_number
  end

  def to_s
    "#{@major}.#{@minor}.#{@patch}.#{@build_number}"
  end

  def release_version
    "#{@major}.#{@minor}"
  end

  def patch_version
    "#{@major}.#{@minor}.#{@patch}"
  end
end
