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
end
class MainController < ApplicationController
  def index
    t = Time.now
    expires = Time.local(t.year, t.mon, t.day, t.hour + 1).to_i
    query_params =  {"api_key" => API_KEY, "expires" => expires}
    path = "/v2/assets/E3d3AxMzoe0CZghzVmen5V_SCxsnYmOE/player"
    @ooyala = OoyalaClient.new
    @sig = @ooyala.generate_signature(API_SECRET, "GET", path, query_params, nil)
    
    
    @response = HTTParty.get("http://api.ooyala.com#{path}", :query => query_params.merge("signature" => @sig))
  end
end
