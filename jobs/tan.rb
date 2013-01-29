require 'net/http'
require 'uri'
require 'json'

# Stations codes from https://open.tan.fr/ewp/arrets.json
codesLieux = ['TPOD','VGAC']
# Lines that you want to track
lines = ["2","3","4"]
# Number of times displayed
quantity = 7


# Custom times comparator
def tri temp1,temp2

  if ((temp1 == "Close") && (temp2 == "Close"))
    0
  elsif ((temp1 == "Close") && (temp2 != "Close"))
    1
  elsif ((temp1 != "Close") && (temp2 == "Close"))
    -1
  elsif ((temp1 == ">1h") && (temp2 == ">1h"))
    0
  elsif ((temp1 == ">1h") && (temp2 != ">1h"))
    1
  elsif ((temp1 != ">1h") && (temp2 == ">1h"))
    -1
  else
    # minutes
    min1 = temp1.split(" ")[0].to_i
    min2 = temp2.split(" ")[0].to_i
    if min1 == min2
      0
    elsif min1 > min2
      1
    elsif min1 < min2
      -1
    end
  end
end

SCHEDULER.every '10s', :first_in => 0 do |job|
  tempsRes = []

  codesLieux.each do |code| 
    uri = URI("https://open.tan.fr/ewp/tempsattente.json/#{code}")
    response={}
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    http.start do |h|
      response = h.request Net::HTTP::Get.new(uri.request_uri)
    end

    temps = JSON.parse(response.body)
 
    temps.each do |temp|
      line = temp.fetch("ligne").fetch("numLigne")

      # Adding special classes to color the lines
      if line == "4"
        temp["lineFour"] = true
      elsif line == "3"
        temp["lineThree"] = true
      elsif line == "2"
        temp["lineTwo"] = true
      end
        
      if lines.include? line
        tempsRes<<temp
      end
    end
  end


  tempsRes.sort! {|x,y|
    tri x.fetch("temps"),y.fetch("temps") 
  }

  send_event('tan', { temps: tempsRes[0,quantity] })
end
