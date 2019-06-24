uuid = require('uuid/v4')
jwt = require('jsonwebtoken')
schemaInfo = require('./config-wrapper').schemaInfo
userAuth = require('./config-wrapper').userAuth
secretKey = require('./config-wrapper').secretKey
SECRET_KEY = uuid()

#: Omit Properties from Object and get Copy

objOmit = (obj, keys) ->
	clone = Object.assign({}, obj)
	for key in keys
		delete obj[key]
	return clone

 #: Response/Error JSON

responseFormat = (method, args, req, res) ->
	try
		response = await method(...args);
		ret_json =
			status: 'ok'
			response: response
		if res.locals.refresh_token?
			ret_json.refresh_token = res.locals.refresh_token
		return res.json(ret_json)
	catch error
		err_json =
			status: 'error'
			response: error
		if res.locals.refresh_token?
			err_json.refresh_token = res.locals.refresh_token
		return res.status(500).json(err_json)

#: Update Query

updateQuery = (req, primary_key) ->
  update_query = objOmit(req.query, [ primary_key ])
  if update_query.update_primary?
    update_query[primary_key] = update_query.update_primary
    update_query.update_primary = null
  return update_query

#: Get Schema Info Async

schemaAsync = (model, primary_key) ->
  Promise.resolve schemaInfo(model, primary_key)

#: Incorrect Secret Key

incorrectSecretKey = (res) ->
  res.status(401).json
    status: 'error'
    response:
      message: 'Incorrect secret key.'
      codes: [ 'INCORRECT' ]

#: Incorrect Username or Password JSON

incorrectUserOrPass = (res) ->
  res.status(401).json
    status: 'error'
    response:
      message: 'Incorrect username or password.'
      codes: [ 'INCORRECT' ]

#: User Not Found JSON

userNotFound = (res) ->
  res.status(401).json
    status: 'error'
    response:
      message: 'User does not exist.'
      codes: [ 'USER_NOT_FOUND' ]

#: No Current Password JSON

noCurrentPass = (res) ->
  res.status(401).json
    status: 'error'
    response:
      message: 'Must include current password.'
      codes: [ 'NO_CURRENT_PASS' ]

#: Allowed Password Check

allowedPassword = (req, res) ->
  error_msg = ''
  error_codes = []
  if req.query.username.length < 8
    error_msg += 'Username must be at least 8 characters. '
    error_codes.push 'USER_LENGTH'
  if req.query.password.length < 8
    error_msg += 'Password must be at least 8 characters. '
    error_codes.push 'PASS_LENGTH'
  if !/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(req.query.password)
    error_msg += 'Password must have at least 1 letter and at least 1 character. '
    error_codes.push 'PASS_CHAR'
  if error_msg.length > 0
    error_msg = error_msg.substring(0, error_msg.length - 1)
    error =
      message: error_msg
      codes: error_codes
    return res.status(401).json(
      status: 'error'
      response: error)
  return

#: Sign JSON Web Token

signToken = (user) ->
  expires_in = 24 * 60 * 60
  access_token = jwt.sign({
    username: user.username
    uid: user.uid
  }, SECRET_KEY, expiresIn: expires_in)

  return
    username: user.username
    uid: user.uid
    access_token: access_token
    expires_in: expires_in

# Verify JSON Web Token

verifyToken = (req, res, next) ->

  if req.params.path?
    if req.params.path == 'secret_key'
      get_all = await secretKey.find({})
      if get_all.length <= 0
        return next()
    else if req.params.path == 'signup'
      get_all = await userAuth.find({})
      if get_all.length <= 0
        return next()

  token = req.query.auth_token or req.headers['x-access-token'] or req.headers['authorization']

  if !token
    return res.status(401).json(
      status: 'error'
      response: message: 'No token provided.')

  else
    jwt.verify token, SECRET_KEY, (error, decoded) ->
      current_time = Math.round(Date.now() / 1000)
      expires_in = 24 * 60 * 60
      one_hour = 60 * 60
      if error
        return res.status(401).json(
          status: 'error'
          response: message: 'Invalid token.')
      else if current_time < decoded.exp and current_time + expires_in > decoded.exp + one_hour
        res.locals.refresh_token = signToken(decoded)
        next()
      else
        next()
      return
  return

module.exports =
  objOmit: objOmit
  responseFormat: responseFormat
  schemaAsync: schemaAsync
  updateQuery: updateQuery
  incorrectUserOrPass: incorrectUserOrPass
  userNotFound: userNotFound
  noCurrentPass: noCurrentPass
  allowedPassword: allowedPassword
  signToken: signToken
  verifyToken: verifyToken

#::: End Program :::