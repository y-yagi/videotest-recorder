require "headless"
require "fileutils"

module Videotest
  module Recorder
    module Rspec
      CHARS_TO_TRANSLATE = ['/', '.', ':', ',', "'", '"', " "].freeze

      class << self
        attr_accessor :headless, :video_dir

        def after_failed_example(example)
          if example.exception
            video = video_dir.join("failures_#{method_name(example)}.mp4")
            headless.video.stop_and_save(video)
            example.metadata[:extra_failure_lines] = [example.metadata[:extra_failure_lines], "[Video]: #{video}"]
          else
            headless.video.stop_and_discard
          end
        end

        def method_name(example)
          example.description.underscore.tr(CHARS_TO_TRANSLATE.join, "_")[0...200] + "_#{rand(1000)}"
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.before do
    Videotest::Recorder::Rspec.video_dir = ::Rails.root.join("tmp", "videos")
    FileUtils.mkdir_p(Videotest::Recorder::Rspec.video_dir)

    Videotest::Recorder::Rspec.headless = Headless.new(video: { provider: :ffmpeg, codec: :libx264, extra: %w(-preset ultrafast) })
    Videotest::Recorder::Rspec.headless.start
    Videotest::Recorder::Rspec.headless.video.start_capture
  end

  config.after(type: :system) do |example|
    Videotest::Recorder::Rspec.after_failed_example(example)
  end

  config.after(type: :feature) do |example|
    Videotest::Recorder::Rspec.after_failed_example(example)
  end
end
