require "digest/sha2"
require "base64"

PARTNER_CODE = "5jcHE6UZBcDWA_sSDcHheQ6rbmRN"
API_KEY = "5jcHE6UZBcDWA_sSDcHheQ6rbmRN.lA1HN"
API_SECRET = "jHgNmekoQVFbiSRMye-iDyyzoYmWMwcway30xz8s"

module OoyalaApi
  def generate_signature(secret, http_method, request_path, query_string_params, request_body)
    string_to_sign = secret + http_method + request_path
    sorted_query_string = query_string_params.sort { |pair1, pair2| pair1[0] <=> pair2[0] }
    string_to_sign += sorted_query_string.map { |key, value| "#{key}=#{value}"}.join
    string_to_sign += request_body.to_s
    signature = Base64::encode64(Digest::SHA256.digest(string_to_sign))[0..42].chomp("=")
    return signature
  end
end
class OoyalaClient
  include OoyalaApi
  include HTTMultiParty
end
class MainController < ApplicationController
  def index
    query_params =  {"api_key" => API_KEY, "expires" => expires}
    # path = "/v2/assets/E3d3AxMzoe0CZghzVmen5V_SCxsnYmOE/player"
    path = "/v2/assets"
    @ooyala = OoyalaClient.new
    @sig = @ooyala.generate_signature(API_SECRET, "GET", path, query_params, nil)
    
    @response = OoyalaClient.get("http://api.ooyala.com#{path}", :query => query_params.merge("signature" => @sig))
  end
  
  def create
    query_params =  {
      "api_key" => API_KEY,
      "expires" => expires
    }
    body = {
      "name" => params[:video].original_filename,
      "file_name" => params[:video].original_filename,
      "asset_type" => "video",
      "file_size" => params[:video].size
    }
    
    path = "/v2/assets"
    @ooyala = OoyalaClient.new
    @sig = @ooyala.generate_signature(API_SECRET, "POST", path, query_params, body.to_json)
    
    @post_response = OoyalaClient.post("http://api.ooyala.com#{path}", :query => query_params.merge("signature" => @sig), :body => body.to_json, :options => { headers => { 'ContentType' => 'application/json' } })
    
    get_upload_url_path = "/v2/assets/#{@post_response["embed_code"]}/uploading_urls"
    @ooyala = OoyalaClient.new
    get_sig = @ooyala.generate_signature(API_SECRET, "GET", get_upload_url_path, query_params, nil)
    @get_response = OoyalaClient.get("http://api.ooyala.com#{get_upload_url_path}", :query => query_params.merge("signature" => get_sig))
    
    upload_url = @get_response.parsed_response.first
    update_status_sig = @ooyala.generate_signature(API_SECRET, "PUT", "/v2/assets/#{@post_response["embed_code"]}/upload_status", query_params, {"status" => "uploaded"}.to_json)
    @update_status_response = OoyalaClient.put("http://api.ooyala.com/v2/assets/#{@post_response["embed_code"]}/upload_status",
                                               :query => query_params.merge("signature" => update_status_sig),
                                               :body => {"status" => "uploaded"}.to_json)
  end
  
  def expires
    t = Time.now
    Time.local(t.year, t.mon, t.day, t.hour + 1).to_i
  end
end
