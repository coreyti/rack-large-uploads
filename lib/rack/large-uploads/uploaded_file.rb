module Rack
  class LargeUploads
    class UploadedFile < ActionDispatch::Http::UploadedFile
      def initialize(hash)
        tempfile = hash[:tempfile]
        hash[:tempfile] = ::File.new(tempfile) if tempfile.is_a?(String)

        @uploaded_md5  = hash.delete(:md5)
        @uploaded_size = hash.delete(:size)
        super(hash)
        @uploaded_path = path
      end

      def clean!(nilify = true)
        raise "No such file or directory - #{@uploaded_path}" unless present?
        ::File.delete(@tempfile.path)

        # NOTE: it appears that an open file descriptor (or similar) remains
        # after the file is removed on the filesystem.  in most cases, we
        # should expect to be unable to interact with the file after cleaning,
        # but we make it optionally allowed.
        if nilify
          @tempfile = nil
        end

        self
      end

      def present?
        @tempfile != nil
      end
    end
  end
end
