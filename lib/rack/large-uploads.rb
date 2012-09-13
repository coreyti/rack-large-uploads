require 'fileutils'
require 'rack/large-uploads/version'

# TODO: remove these dependencies:
require 'action_dispatch'
require 'active_support/core_ext'

module Rack
  class LargeUploads
    autoload :UploadedChunk, 'rack/large-uploads/uploaded_chunk'
    autoload :UploadedFile,  'rack/large-uploads/uploaded_file'

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
      params  = request.params

      if request.post? && request.form_data?
        files = extract_files(request, params)
      end

      if files.present?
        if files.all? { |f| f.is_a?(Rack::LargeUploads::UploadedFile) }
          filter(:before, env, files)
          response = @app.call(env)
          filter(:after, env, files)

          return response
        else
          return [202, {}, []]
        end
      else
        @app.call(env)
      end
    end


    def before(&block)
      @filters[:before] = block
    end

    def after(&block)
      @filters[:after] = block
    end

    private

      def filter(position, env, files)
        @filters[position] && @filters[position].call(env, files)
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

      # TODO:
      #   * make chunked check configurable (:filename value at least, maybe other)
      #   * make chunked storage path configurable
      #   * make 'uploader' param configurable, and per-upload rather than per-request
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
            # check for "chunked" upload
            if attributes[:filename] == 'blob'
              temppath = tempfile.is_a?(String) ? tempfile : tempfile.path
              storage  = ::File.expand_path(::File.join(temppath, '../../chunked'))
              uploader = request.params['uploader']
              combined = ::File.join(storage, uploader)
              fullsize = request.env['HTTP_X_FILE_SIZE'].to_i

              # append chunk to "combined" File
              FileUtils.mkdir_p(storage)
              ::File.open(combined, 'ab') do |f|
                f.write(::File.read(tempfile))
              end

              # finished?
              if ::File.size(combined) == fullsize
                attributes = {
                  :filename => request.env['HTTP_X_FILE_NAME'],
                  :size     => request.env['HTTP_X_FILE_SIZE'],
                  :type     => request.env['HTTP_X_FILE_TYPE'],
                  :tempfile => ::File.new(combined)
                }

                return Rack::LargeUploads::UploadedFile.new(attributes)
              else
                return Rack::LargeUploads::UploadedChunk.new(attributes)
              end
            else
              return Rack::LargeUploads::UploadedFile.new(attributes)
            end
          end
        end

        nil
      end

      def replace_param(params, key, file)
        params[key] = file
      end
  end
end
