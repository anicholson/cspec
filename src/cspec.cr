require "uuid"
require "file_utils"

require "./debug"

module CSpec
  macro at_compile_time(description, should_build = false, debug = false, cleanup = true, &block)
    {% annotated_name = "[C] " + description %}

    describe {{annotated_name}} do
      {% if debug %}
        debugger = CSpec::DEBUG
      {% else %}
        debugger = CSpec::NopDebugger.new
      {% end %}

      test_id = UUID.random
      tempdir_path = Path.new("./spec").expand

      file_name = "#{test_id}_compile_time_spec"
      file_path = Path.new(tempdir_path, "#{file_name}.cr")

      {% expressions = block.body.is_a?(Expressions) ? block.body.expressions : [block.body] %}
      {% spec_blocks = [] of Call %}
      {% source = "" %}
      {% for exp in expressions %}
        {% if exp.class_name == "Call" && ([:it, :describe, :pending, :context].includes?(exp.name.symbolize)) %}
          {% spec_blocks << exp %}
        {% elsif exp.class_name == "Call" && (exp.name.symbolize == :source) %}
          {% source = exp.block.body.stringify %}
        {% end %}
      {% end %}

      {% if source.empty? %}
        {% raise "Can't have an empty source block" %}
        {% else %}
          File.open(file_path, "w") do |f|
            f.write_utf8({{source}}.to_slice)
          end
      {% end %}

      stdout_sb = String::Builder.new
      stderr_sb = String::Builder.new
      result = Process.run("crystal", ["build", "--error-trace", "--no-color", file_path.expand.to_s], nil, false, true, Process::Redirect::Close, stdout_sb, stderr_sb, Dir.current)

      stdout : String = stdout_sb.to_s
      stderr : String = stderr_sb.to_s

      debugger.info { "STDOUT: \n #{output}" }
      debugger.info { "STDERR: \n #{err}" }

      describe "basic checks" do
        it "creates output" do
          some_output = !(stdout.empty? && stderr.empty?)
          some_output.should eq(true)
        end

        {% if should_build %}
          it "succeeds" do
            result.success?.should eq(true)
          end
        {% else %}
          it "fails" do
            result.success?.should eq(false)
          end
        {% end %}
      end

      {% for spec in spec_blocks %}
        {{ spec }}
      {% end %}


      at_exit do
        {% if cleanup == false %}
          warning = <<-WARNING
Generated spec for '{{description}}' has been left at #{file_path}.
Please remove it before running `crystal spec` again, otherwise it will be
executed next time (and cause you a lot of confusion!)
WARNING
          debugger.warn { warning }
        {% else %}
          debugger.info { "Deleting temporary spec #{file_path}" }
          FileUtils.rm(file_path.to_s)
          FileUtils.rm(file_name) if result.success?
        {% end %}
      end
    end
  end
end
