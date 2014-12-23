require 'zendesk_api'

client = ZendeskAPI::Client.new do|config|
	config.url = "https://brushfire.zendesk.com/api/v2"
	config.username = "matt@brushfiretech.com"
	config.token = 'G05ZZ0IbnaRKVg1nVPA4LT7OiVxSraA2IOjbYj7m'
end

logger = Logger.new(STDOUT)

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1m', :first_in => 0 do |job|
	query = client.search(:query => 'type:ticket assignee:none status:new')
	tickets = query.fetch

	if tickets
		tickets = tickets.map do |t|
			{ label: t.subject, value: t.description.length > 75 ? t.description[0..75] + '...' : t.description, url: 'https://brushfire.zendesk.com/agent/tickets/' + t.id.to_s }
		end
	end

  	send_event('zendesk_unassigned', { items: tickets })

  	today = Date.today
  	yesterday = today - 1
  	tomorrow = today + 1

  	query = client.search(:query => 'type:ticket updated>' + yesterday.strftime("%F") + ' updated<' + tomorrow.strftime("%F"))
	tickets = query.fetch

	if tickets
		tickets = tickets.map do |t|
			{ label: t.subject, value: t.description.length > 75 ? t.description[0..75] + '...' : t.description, url: 'https://brushfire.zendesk.com/agent/tickets/' + t.id.to_s }
		end
	end

	send_event('zendesk_recent_updates', { items: tickets})

  	query = client.search(:query => 'type:ticket status:solved updated>' + yesterday.strftime("%F") + ' updated<' + tomorrow.strftime("%F"))
	tickets = query.fetch

	if tickets
		tickets = tickets.map do |t|
			{ label: t.subject, value: t.description.length > 75 ? t.description[0..75] + '...' : t.description, url: 'https://brushfire.zendesk.com/agent/tickets/' + t.id.to_s }
		end
	end

	send_event('zendesk_recent_closed', { items: tickets})
end