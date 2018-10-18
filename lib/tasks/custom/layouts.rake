namespace :custom do
  namespace :layouts do

    desc "Install custom layouts"
    task install: :environment do
      puts "[START] Installing layouts for #{Rails.env} environment"

      BUCKET_ENV = Rails.env.development? ? :dev : Rails.env
      BUCKET_PREFFIX = "https://gobierto-budgets-comparator-#{BUCKET_ENV}.s3.eu-west-1.amazonaws.com/gencat/custom_views/"
      DEST_DIR = Rails.root.join("app", "views", "custom", "layouts")
      PAGE_SIZE_THRESHOLD = 100

      FILE_NAMES = [
        "_header_ca.html.erb",
        "_footer_ca.html.erb",
        "_custom_head_content_ca.html.erb"
      ]

      file_names = ["_header_", "_footer_", "_custom_head_content_"].map do |name_fragment|
        # TODO: only use catalan until template is available in all locales
        ["ca"].map { |lc| "#{name_fragment}#{lc}.html.erb" }
        #I18n.available_locales.map { |lc| "#{name_fragment}#{lc}.html.erb" }
      end.flatten

      file_names.each do |file_name|
        file_uri = URI.parse(BUCKET_PREFFIX + file_name)
        dest_file = DEST_DIR + file_name

        puts "\nInstalling template:\n\tOrigin: #{file_uri}\n\tDest: #{dest_file}"

        file_content = Net::HTTP.get(file_uri)

        if file_content.size < PAGE_SIZE_THRESHOLD
          puts "\t[ERR] Skipped. Check the file is not incomplete."
          next
        else
          bytes_written = File.write(dest_file, file_content.force_encoding("utf-8"))
          puts "\t[OK] Wrote #{bytes_written} bytes"
        end
      end

      puts "[END] Installing layouts"
    end

  end
end
