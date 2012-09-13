# Rack::LargeUploads

Rack middleware for handling large file uploads.Integrates nicely with the
Nginx upload module: http://www.grid.net.ru/nginx/upload.en.html

Includes `Rack::LargeUploads::UploadedFile`, which matches the definition of
`ActionDispatch::Http::UploadedFile`.  So, little-to-no change should be
required when using, e.g., Rails.

Based largely on the [`Rack::Uploads` middleware](https://github.com/mutle/rack-uploads),
but with greater expectations regarding conventions, and specific support for
large files (dealing with memory issues).

Implements **(experimental)** handling of chunked uploads, only passing control
to, e.g., Rails once all uploads for the request are complete. This is very
experimental, because it is currently:

  * dependent upon headers and filename value as set by blueimp's jQuery
    fileupload plugin
  * dependent on the presence of `uploader` request param, which is a UUID or
    similar, and is used to collect the upload chunks
  * untested

## Installation

Add this line to your application's Gemfile:

    gem 'rack-large-uploads'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-large-uploads

## Usage

example middleware configuration:

    use Rack::LargeUploads do
      before do |files|
        # process uploaded files *before* application handling
      end

      after do |files|
        # process uploaded files *after* application handling
      end
    end

example nginx configuration:

    location / {
      try_files $document_root/system/maintenance.html $uri $uri/index.html $uri.html @application;
    }

    location = /uploads {
      # depends on the nginx upload module (http://www.grid.net.ru/nginx/upload.en.html)
      upload_pass         @application;

      # NOTE: if the request is something other than POST, nginx generates a 405.
      # use that to pass the request on to the endpoint, instead of try_files
      # which fails to play nicely with upload_pass.
      #
      # credit:
      # http://www.nickager.com/blog/File-upload-using-Nginx-and-Seaside---step-1
      error_page          405 415 = @application;

      # NOTE: cleaning up 201 & 202 means we need to be sure our app is doing
      # some processing right away. Rack::LargeUploads sends 202 responses for
      # each chunk received during chunked uploads, and the chunk has been
      # appended to the combined file by the time we're back with the response.
      upload_cleanup      201 202 400 404 499 500-505;
      upload_store        /path/to/app/tmp/uploads 1;
      upload_store_access user:rw group:rw all:rw;

      upload_pass_args       on;          # NOTE: handles URI params, not form content.
      upload_pass_form_field "^[a-z_].*"; # ...and here is how we resolve that last.

      # match the request params expected by ActionDispatch
      upload_set_form_field "$upload_field_name[filename]"   "$upload_file_name";
      upload_set_form_field "$upload_field_name[type]"       "$upload_content_type";
      upload_set_form_field "$upload_field_name[tempfile]"   "$upload_tmp_path";

      upload_aggregate_form_field "$upload_field_name[md5]"  "$upload_file_md5";
      upload_aggregate_form_field "$upload_field_name[size]" "$upload_file_size";
    }

    location @application {
      proxy_pass  http://upstream_application;

      # more config...
    }

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
