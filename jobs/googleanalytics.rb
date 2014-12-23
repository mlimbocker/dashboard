require 'google/api_client'
require 'logger'

logger = Logger.new(STDOUT)

visitors = [];
idx = 0

client = Google::APIClient.new
key = Google::APIClient::KeyUtils.load_from_pkcs12('D:\BRUSHFIRE\brushfire_dashboard\assets\keys\gapikey.p12', 'notasecret')
client.authorization = Signet::OAuth2::Client.new(
		:token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
		:audience => 'https://accounts.google.com/o/oauth2/token',
		:scope => 'https://www.googleapis.com/auth/analytics.readonly',
		:issuer => '540020256256-aa65dhaq7ahirc5ueqdb9mf494i6h7e4@developer.gserviceaccount.com',
		:signing_key => key
	)
client.authorization.fetch_access_token!

analytics = client.discovered_api('analytics', 'v3')

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '15s', :first_in => 0 do |job|

	result = client.execute(
		:api_method => analytics.data.realtime.get,
		:parameters => {
							'ids' => 'ga:71912214',
							'metrics' => 'rt:activeUsers',
							'dimensions' => 'rt:browser, rt:operatingSystem, rt:deviceCategory, rt:mobileDeviceBranding'
						}
		)

	#update Visitor Count
	if(visitors.count >= 10)
		visitors.shift 
	end

	visitors << {x: Time.now.to_i, y: result.data['totalsForAllResults']['rt:activeUsers'].to_i}
	idx += 15

  	send_event('ga_currentusers', points: visitors)

  	#update device type statistics
  	desktopCount = 0
  	mobileCount = 0
  	tabletCount = 0
  	osNames = []
 	osCounts = []
 	browserNames = []
 	browserCounts = []

  	rows = result.data["rows"]

  	rows.each do|r|
  		#count Devices
  		if(r[2] == "DESKTOP")
  			desktopCount += r[4].to_i
  		elsif(r[2] == "TABLET")
  			tabletCount += r[4].to_i
  		elsif (r[2] == "MOBILE")
  			mobileCount += r[4].to_i
  		end

  		#count Operating Systems
  		if(!osNames.include? r[1])
  			osNames.push(r[1])
  		end
  		osIndex = osNames.find_index(r[1])

  		if(osCounts[osIndex] == nil)
  			osCounts[osIndex] = 0
  		end

  		osCounts[osIndex] += r[4].to_i

  		#count Browsers
  		if(!browserNames.include? r[0])
  			browserNames.push(r[0])
  		end
  		browserIndex = browserNames.find_index(r[0])

  		if(browserCounts[browserIndex] == nil)
  			browserCounts[browserIndex] = 0
  		end

  		browserCounts[browserIndex] += r[4].to_i
  	end

  	deviceData = [
  		{ label: 'Desktop - ' + desktopCount.to_s, value: desktopCount },
  		{ label: 'Mobile - ' + mobileCount.to_s, value: mobileCount },
  		{ label: 'Tablet - ' + tabletCount.to_s, value: tabletCount }
  	]

	osData = []
  	osCounts.each_with_index do |count, i|
  		osData.push({label: osNames[i] + ' - ' + osCounts[i].to_s, value: osCounts[i]})
  	end

  	browserData = []
  	browserCounts.each_with_index do |count, i|
  		browserData.push({label: browserNames[i] + ' - ' + browserCounts[i].to_s, value: browserCounts[i]})
  	end

  	send_event('ga_devicebreakdown', value: deviceData)
  	send_event('ga_osbreakdown', value: osData)
  	send_event('ga_browserbreakdown', value: browserData)
end
