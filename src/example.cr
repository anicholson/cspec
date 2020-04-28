require "spec"
require "./cspec"

include CSpec

at_compile_time "invovked without a source block" do
  source do
    require "../src/cspec"
    include CSpec

    at_compile_time "breaks" do
    end
  end

  it "complains about a missing source block" do
    (err.to_s.includes?("Can't have an empty source block")).should eq(true)
  end
end
