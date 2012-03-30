require "rack/large-uploads/version"

# TODO: remove these dependencies:
require "action_dispatch"
require "active_support/core_ext"

module Rack
  class LargeUploads
    autoload :UploadedFile, 'rack/large-uploads/uploaded_file'

    def initialize(app, options = {}, &block)
      @app     = app
      @filters = {}

      if block
        if block.arity == 1
          block.call(self)
        else
          instance_eval(&block)
        end
      end
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.post? && request.form_data?
        files = extract_files(request, request.params)
      end

      filter(:before, files) if files.present?
      response = @app.call(env)
      filter(:after, files) if files.present?

      response
    end

    def before(&block)
      @filters[:before] = block
    end

    def after(&block)
      @filters[:after] = block
    end

    private

      def filter(position, files)
        @filters[position] && @filters[position].call(files)
      end

      def extract_files(request, params, files = [])
        params.each do |key, value|
          if file = file_from(request, key, value)
            files << replace_param(params, key, file)
          elsif value.is_a?(Hash)
            files = extract_files(request, value, files)
          end
        end

        files
      end

      def file_from(request, key, value)
        # direct to rails...
        # ----->
        #   key: file,
        #   value: {
        #     :filename =>"file.mov",
        #     :type     =>"video/quicktime",
        #     :tempfile =>#<File:/var/folders/xn/x665dh2j6qx_t7w5bqcsfgcr0000gn/T/RackMultipart20120330-11052-1ysyd0c>,
        #     :name     =>"video[file]",
        #     :head     =>"Content-Disposition: form-data; name=\"video[file]\"; filename=\"file.mov\"\r\nContent-Type: video/quicktime\r\n"
        #   }

        # with nginx upload (configured per README)...
        # ----->
        #   key: file,
        #   value: {
        #     "filename"=>"file.mov",
        #     "type"    =>"video/quicktime",
        #     "tempfile"=>"/path/to/app/tmp/uploads/1/0000000001",
        #     "md5"     =>"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        #     "size"    =>"5242880000"
        #   }
        if value.is_a?(Hash)
          attributes = HashWithIndifferentAccess.new(value)
          tempfile   = attributes[:tempfile]

          if tempfile.present?
            tempfile = ::File.new(tempfile) if tempfile.is_a?(String)
            return Rack::LargeUploads::UploadedFile.new(attributes.merge({ :tempfile => tempfile }))
          end
        end

        nil
      end

      def replace_param(params, key, file)
        params[key] = file
      end
  end
end
