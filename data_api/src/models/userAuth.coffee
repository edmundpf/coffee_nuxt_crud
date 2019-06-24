mongoose = require('mongoose')
autoIncrement = require('mongoose-sequence')(mongoose)
hooks = require('../utils/model-hooks')

#: Schema

userAuth = new (mongoose.Schema)({
	username:
		type: String
		unique: true
		required: true
	password:
		type: String
		unique: true
		required: true
},
{
	collection: 'user_auth'
	timestamps: true
})

#: Pre-Save Hook

userAuth.pre 'save', ->
	await hooks.saveEncrypt this, 'password'
	return

#: Pre-Update-One Hook

userAuth.pre 'updateOne', ->
	await hooks.updateEncrypt @getUpdate(), 'password'
	return

#: Auto-Increment

userAuth.plugin autoIncrement,
	id: 'user_auth_uid'
	inc_field: 'uid'

#: Exports

module.exports = mongoose.model('UserAuth', userAuth)

#::: End Program :::