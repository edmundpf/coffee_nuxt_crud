express = require('express')
mongoose = require('mongoose')
cors = require('cors')
bcrypt = require('bcrypt')
p = require('print-tools-js')

userAuth = require('./utils/config-wrapper').userAuth
secretKey = require('./utils/config-wrapper').secretKey
list_routes = require('./utils/config-wrapper').list_routes
normal_routes = require('./utils/config-wrapper').normal_routes
app_routes = require('./utils/config-wrapper').app_routes
list_methods = require('./utils/config-wrapper').list_methods
normal_methods = require('./utils/config-wrapper').normal_methods
route_methods = require('./utils/config-wrapper').route_methods

serverPort = require('./utils/config-wrapper').serverPort || process.env.PORT
corsPort = require('./utils/config-wrapper').corsPort
mongoosePort = require('./utils/config-wrapper').mongoosePort
databaseName = require('./utils/config-wrapper').databaseName

objOmit = require('./utils/data-api-functions').objOmit
schemaAsync = require('./utils/data-api-functions').schemaAsync
updateQuery = require('./utils/data-api-functions').updateQuery
responseFormat = require('./utils/data-api-functions').responseFormat
incorrectSecretKey = require('./utils/data-api-functions').incorrectSecretKey
incorrectUserOrPass = require('./utils/data-api-functions').incorrectUserOrPass
userNotFound = require('./utils/data-api-functions').userNotFound
noCurrentPass = require('./utils/data-api-functions').noCurrentPass
allowedPassword = require('./utils/data-api-functions').allowedPassword
signToken = require('./utils/data-api-functions').signToken
verifyToken = require('./utils/data-api-functions').verifyToken

#: MongoDB Config

db = mongoose.connect("mongodb://localhost:#{mongoosePort}/#{databaseName}",
	useNewUrlParser: true,
	useCreateIndex: true,
	useFindAndModify: false
)

#: Express Config

app = express()

app.use(cors(
	origin: "http://localhost:#{corsPort}",
	exposedHeaders: [ 'X-Access-Token' ],
))

app.listen(serverPort, => p.titleBox(
	'Data API Server'
	titleDesc: "Running on port #{serverPort}"
	tagLine: "Connected to Mongo database: #{databaseName} on port #{mongoosePort}"
))

#: All Routes

app.all("/:path(#{Object.keys(app_routes).join('|')})/:method(#{normal_methods.join('|')})",
	verifyToken, (req, res) =>

		model = app_routes[req.params.path].model
		primary_key = app_routes[req.params.path].primary_key

		#: Insert

		if req.params.method == 'insert'
			await responseFormat(
				model.create.bind(model),
				[req.query], req, res)

		#: Update

		else if req.params.method == 'update'
			await responseFormat(
				model.updateOne.bind(model),
				[{ [primary_key]: req.query[primary_key] },
						updateQuery(req, primary_key)], req, res)

		#: Delete

		else if req.params.method == 'delete'
			await responseFormat(
				model.deleteOne.bind(model),
				[{ [primary_key]: req.query[primary_key] }], req, res)

		#: Delete All

		else if req.params.method == 'delete_all'
			await responseFormat(model.deleteMany.bind(model), [{}], req, res)

		#: Get

		else if req.params.method == 'get'
			await responseFormat(
				model.find.bind(model),
				[{ [primary_key]: req.query[primary_key] }], req, res)

		#: Get All

		else if req.params.method == 'get_all'
			await responseFormat(
				model.find.bind(model),
				[{}], req, res)

		#: Get Schema Info

		else if req.params.method == 'schema'
			await responseFormat(schemaAsync, [model, primary_key], req, res)

		#: Sterilize

		else if req.params.method == 'sterilize'
			unset_dict = {}
			fields = req.query.fields.split ','
			for field in fields
				unset_dict[field] = 1;
			await responseFormat(
				model.updateMany.bind(model),
				[{}, { $unset:unset_dict },
				{ multi: true, strict: false }],
				req, res)
)

#: List Routes

app.all("/:path(#{Object.keys(list_routes).join('|')})/:method(#{list_methods.join('|')})",
	verifyToken, (req, res) =>

		model = app_routes[req.params.path].model;
		primary_key = app_routes[req.params.path].primary_key;

		if ['push', 'push_unique', 'set'].includes req.params.method
			update_dict = {};
			for key of req.query
				if ![primary_key, 'auth_token', 'refresh_token'].includes key
					if req.params.method != 'set'
						update_dict[key] = $each: req.query[key].split(',')
					else
						update_dict[key] = req.query[key].split(',')

			#: Push

			if req.params.method == 'push'
				await responseFormat(
					model.updateOne.bind(model),
					[{ [primary_key]: req.query[primary_key] },
					{ $push: update_dict }], req, res)

			#: Push Unique

			else if req.params.method == 'push_unique'
				await responseFormat(
					model.updateOne.bind(model),
					[{ [primary_key]: req.query[primary_key] },
					{ $addToSet: update_dict }], req, res)

			#: Set

			else if req.params.method == 'set'
				await responseFormat(
					model.updateOne.bind(model),
					[{ [primary_key]: req.query[primary_key] },
					{ $set: update_dict }], req, res)
)

#: Login

app.all('/login', (req, res) =>

	try
		user = await userAuth.findOne username: req.query.username
		if user
			pass_match = await bcrypt.compare req.query.password, user.password
			if !pass_match
				return incorrectUserOrPass res
			else
				token = signToken user
				return res.json status: 'ok', response: token
		else
			return userNotFound res
	catch error
		return res.status(500).json(
			status: 'error'
			response: error
		)
)

#: Sign Up

app.all('/:path(signup)', verifyToken, (req, res) =>

	try
		if req.query.secret_key?

			key = await secretKey.find {}
			if key.length > 0
				key_match = await bcrypt.compare req.query.secret_key, key[key.length - 1].key
				if !key_match
					return incorrectSecretKey(res);

			allowedPassword req, res
			response = await userAuth.create req.query

			if req.query.username == response.username
				token = signToken(response)
				return res.json(
					status: 'ok'
					response: token
				)
			else
				return res.status(401).json(
					status: 'error'
					response: response
				)

		else
			return res.status(401).json(
				status: 'error'
				response:
					message: 'Not Authorized.'
			)

	catch error
		return res.status(500).json(
			status: 'error'
			response: error
		)
)

#: Update Password

app.all('/update_password', (req, res) =>

	try
		user = await userAuth.findOne username: req.query.username

		if user && req.query.current_password?
			pass_match = await bcrypt.compare req.query.current_password, user.password
			if !pass_match
				return incorrectUserOrPass res
		else if !user
			return userNotFound res
		else if !req.query.current_password?
			return noCurrentPass res

		allowedPassword req, res
		pass_update = await userAuth.updateOne(
			{ username: req.query.username },
			objOmit(req.query, ['username']))

		if pass_update.nModified == 1
			return res.json(
				status: 'ok'
				response:
					message: 'Password updated.'
				)
		else
			return res.status(401).json(
				status: 'error'
				response: pass_update
			)
	catch error
		return res.status(500).json(
			status: 'error'
			response: error
		)
)

#: Verify Token

app.all('/verify_token', verifyToken, (req, res) =>
	if res.locals.refresh_token?
		return res.json(
			status: 'ok',
			refresh_token: res.locals.refresh_token
			response:
				message: 'Token verified.'
		)
	else
		return res.json(
			status: 'ok'
			response:
				message: 'Token verified.'
		)
)

#: Exports

module.exports =
	path: '/api'
	handler: app