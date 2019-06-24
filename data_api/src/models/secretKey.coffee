mongoose = require('mongoose')
autoIncrement = require('mongoose-sequence')(mongoose)
hooks = require('../utils/model-hooks')

#: Schema

secretKey = new (mongoose.Schema)({
	key:
		type: String
		unique: true
		required: true
},
{
	collection: 'secret_key'
	timestamps: true
})

#: Pre-Save Hook

secretKey.pre 'save', ->
	await hooks.saveEncrypt this, 'key'
	return

#: Pre-Update-One Hook

secretKey.pre 'updateOne', ->
	await hooks.updateEncrypt @getUpdate(), 'key'
	return

#: Auto Increment

secretKey.plugin autoIncrement,
	id: 'secret_key_uid'
	inc_field: 'uid'

#: Exports

module.exports = mongoose.model('SecretKey', secretKey)

#::: End Program :::