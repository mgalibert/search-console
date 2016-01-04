require 'google/apis/webmasters_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'Search Console API Ruby'
CLIENT_SECRETS_PATH = 'search_console_client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "search-console.yaml")
SCOPE = Google::Apis::WebmastersV3::AUTH_WEBMASTERS

def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(
    client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(
      base_url: OOB_URI)
    puts "Open the following URL in the browser and enter the " +
         "resulting code after authorization"
    puts url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI)
  end
  credentials
end

WEBSITES = [
  "https://horaires.captaintrain.com",
  "https://orari.captaintrain.com",
  "https://fahrplan.captaintrain.com",
  "https://rozklad.captaintrain.com",
  "https://timetable.captaintrain.com",
  "https://dienstregeling.captaintrain.com",
  "https://menetrend.captaintrain.com",
  "https://koreplaner.captaintrain.com",
  "https://horarios.captaintrain.com",
  "https://tidtabeller.captaintrain.com",
  "https://raspisaniye.captaintrain.com",
  "https://jizdnirady.captaintrain.com",
  "https://horario.captaintrain.com",
  "https://jikokuhyo.captaintrain.com",
  "https://sefersaatleri.captaintrain.com",
  "https://shikebiao.captaintrain.com",
  "https://siganpyo.captaintrain.com",
  "https://horaro.captaintrain.com",
]

ERROR_TYPES = [
  "notFound",
  "serverError",
]

PLATFORMS = [
  "mobile",
  "smartphoneOnly",
  "web"
]

def mark_errors_as_fixed
  service = Google::Apis::WebmastersV3::WebmastersService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = authorize

  WEBSITES.each do |website|

    ERROR_TYPES.each do |error_type|

      PLATFORMS.each do |platform|

        puts "#{website} | #{error_type} | #{platform}"
        response = service.list_errors_samples(website, error_type, platform)

        if !response.url_crawl_error_sample.nil?
          begin
            service.batch do |service|
              puts "Fixing #{response.url_crawl_error_sample.count} urls"

              response.url_crawl_error_sample.each do |sample|
                service.mark_as_fixed(website, sample.page_url, error_type, platform)
              end
            end
          rescue
            retry
          end
        else

          puts "No urls to fix"
        end
      end
    end
  end
end

begin
  mark_errors_as_fixed
end
