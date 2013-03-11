# Plugin for GitHub that will provide user and repository notifications in River
class GitHub

	# The constructor is required and will be given a delegate that can perform
	# certain actions which are specific to this plugin.
	constructor: (delegate) ->
		@delegate = delegate

		# Also set up the class-scope configuration variables such as access URLs
		# and OAuth credentials.
		@clientID = '317aa0258e1e9866c29e'
		@clientSecret = 'ac1bb001bafe49b4f031c8a2cfeee54d9cfcd065'

		@baseURL = 'https://api.github.com/'
		@userURL = @baseURL + 'user?access_token='
		@notificationsURL = @baseURL + 'notifications?all=true&access_token='

		@oauthAccessTokenURL = 'https://github.com/login/oauth/access_token'
		@oauthAuthURL = 'https://github.com/login/oauth/authorize?scope=notifications,user,repo&client_id='


	# **authRequirements** is called by River to find out how to create a new
	# stream instance.
	authRequirements: (callback) ->
		callbackURL = @oauthAuthURL + @clientID + '&redirect_uri=' + @delegate.callbackURL()
		callback {
			authType: 'oauth',
			url: callbackURL
		}


	# **authenticate** is called by River with the parameters requested in
	# *authRequirements* and should result in a call to *createAccount*.
	#
	# Calls *exchange* to get an access token for the OAuth code that we have
	# been given by the site login.
	#
	# Then calls the *user* method to get the user's profile for extra information
	# required for the account object.
	# 
	# Finally calls *createAccount* on the delegate passing in the user info.
	authenticate: (params) ->
		@exchange params.code, (err, token) =>
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


	# Called by River to get a list of updates to be displayed to the user.
	#
	# Makes an HTTP request to the notifications API endpoint. The response
	# is parsed and looped over to create an array of *Notification* objects.
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
				n = new Notification()
				n.subject = notification.repository.full_name
				n.action = notification.subject.title
				n.id = notification.id
				notifications.push(n)
			callback(null, notifications)


	# Return the update interval preferences in seconds.
	updatePreferences: (callback) ->
		callback {
			interval: 900,
			min: 600,
			max: 3600
		}


	# Helper method for exchanging the OAuth code returned for an access token.
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
	

	# Helper method to get a user profile.
	user: (token, callback) ->
		HTTP.request {
			url: @userURL + token
		}, (err, response) =>
			if not response
				return callback(err, null)
			callback(null, JSON.parse(response))

# All plugins must be registered with the global **PluginManager**. The
# plugin object passed should be a 'class' like object. This is easy with
# CoffeeScript. The identifier passed here must match that given in the
# plugin manifest file.
PluginManager.registerPlugin(GitHub, 'me.danpalmer.River.plugins.GitHub')