require 'spec_helper'

module StringsFileValidator
end

describe StringsFileValidator do
  it 'raises when there are duplicated keys' do
    Dir.mktmpdir do |dir|
      utput_path = File.join(dir, 'output.po')
      dummy_text = <<~PO
      expect(true).to be_falsy
    end
  end
end
