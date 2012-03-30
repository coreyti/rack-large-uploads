require 'spec_helper'

describe Rack::LargeUploads do
  it "is defined" do
    Rack::LargeUploads.should be_a(Class)
  end
end
