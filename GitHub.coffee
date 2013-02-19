class GitHub

	constructor: (delegate) ->
		@delegate = delegate

		@clientID = '317aa0258e1e9866c29e'
		@clientSecret = 'ac1bb001bafe49b4f031c8a2cfeee54d9cfcd065'

		@baseURL = 'https://api.github.com/'
		@userURL = @baseURL + 'user?access_token='
		@notificationsURL = @baseURL + 'notifications?all=true&access_token='

		@oauthAccessTokenURL = 'https://github.com/login/oauth/access_token'
		@oauthAuthURL = 'https://github.com/login/oauth/authorize?scope=notifications,user,repo&client_id='

	authRequirements: (callback) ->
		callbackURL = @oauthAuthURL + @clientID + '&redirect_uri=' + @delegate.callbackURL()
		callback {
			authType: 'oauth',
			url: callbackURL
		}

	authenticate: (params) ->
		@exchange params.code, (err, token) =>
			console.log(token)
			if not token
				return console.log(err)
			@user token, (err, user) =>
				if not user
					return console.log(err)
				@delegate.createAccount {
					name: user.login,
					identifier: user.id.toString(),
					secret: token
				}

	exchange: (code, callback) ->
		HTTP.request {
			url: @oauthAccessTokenURL,
			method: 'POST',
			parameters: {
				code: code,
				client_secret: @clientSecret,
				client_id: @clientID
			},
			headers: {
				'Accept': 'application/json'
			}
		}, (err, response) =>
			if not response
				return callback(err, null)
			token = JSON.parse(response)
			if not token
				return callback('Could not parse response', null)
			callback(null, token.access_token)
			
	user: (token, callback) ->
		HTTP.request {
			url: @userURL + token
		}, (err, response) =>
			if not response
				return callback(err, null)
			callback(null, JSON.parse(response))
	
	update: (user, callback) ->
		HTTP.request {
			url: @notificationsURL + user.secret
		}, (err, response) =>
			if not response
				return callback(err, null)
			response = JSON.parse(response)
			if not response
				return callback('Failed to parse JSON', null)
			notifications = []
			for notification in response
				console.log notification.subject.title
				n = new Notification()
				n.subject = notification.repository.full_name
				n.action = notification.subject.title
				n.id = notification.id
				notifications.push(n)
			callback(null, notifications)


	updatePreferences: (callback) ->
		callback {
			interval: 900,
			min: 600,
			max: 3600
		}

PluginManager.registerPlugin(GitHub, 'me.danpalmer.River.plugins.GitHub')