require "./spec_helper"

at_compile_time "invovked without a source block" do
  source do
    require "../src/cspec"
    include CSpec

    at_compile_time "breaks" do
    end
  end

  it "complains about a missing source block" do
    (stderr.to_s.includes?("Can't have an empty source block")).should eq(true)
  end

  describe "debug output" do
    it "is included" do
      stderr.to_s.includes?("Deleting temporary spec")
    end
  end
end

at_compile_time "capturing compile-time output", should_build: true do
  source do
    {% puts "Some example compiler output" %}
  end

  it "outputs the result" do
    stdout.includes?("Some example compiler output").should eq(true)
  end
end

at_compile_time "capturing compile-time error output", should_build: false do
  source do
    {% puts "This goes to stdout" %}
    {% raise "This goes to stderr" %}
  end

  it "outputs the result to stderr, not stdout" do
    stdout.includes?("This goes to stdout").should eq(true)
    stderr.includes?("This goes to stderr").should eq(true)
  end
end
