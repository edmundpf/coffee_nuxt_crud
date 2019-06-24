import serverConfig from '~/data_api/config/server-config.json'

export apiReq = (obj, endpoint, params) ->
	param_str = ''
	login_req = ''
	if params?
		keys = Object.keys(params);
		if keys.length > 0
			param_str = '?'
			for i in [0...keys.length]
				if i == keys.length - 1
					param_str += "#{keys[i]}=#{params[keys[i]]}"
				else
					param_str += "#{keys[i]}=#{params[keys[i]]}&"

	try
		login_req = await obj.$axios.$get "http://localhost:#{serverConfig.serverPort}/#{endpoint}#{param_str}"
	catch error
		login_req = error.response.data
	return login_req;

export tokenAuth = (obj) ->
	tokenReq = await apiReq obj, 'verify_token'
	try
		refresh_token = tokenReq.refresh_token.access_token
	catch
		refresh_token = null;
	if tokenReq.status == 'ok'
		return
			status: true
			refresh_token: refresh_token
	if tokenReq.status == 'error'
		return
			status: false
			refresh_token: refresh_token