bcrypt = require('bcrypt')
SALT_WORK_FACTOR = 10

#: Pre-Save hook to save CSV lists for array fields

listCreate = (doc, fields) ->
	try
		for field in fields
			vals = doc[field][0].split(',')
			doc[field] = []
			for val in vals
				doc[field].push(val)
	catch error
		return Promise.resolve
			message: 'Could not set array field value.'
			errorMsg: error
	return Promise.resolve doc

#: Pre-Save hook to encrypt field

saveEncrypt = (doc, key) ->
	if !doc.isModified(key) and !doc.isNew
		return
	try
		salt = await bcrypt.genSalt SALT_WORK_FACTOR
		doc[key] = await bcrypt.hash doc[key], salt
	catch error
		return {
			message: 'Could not create encrypted field.'
			errorMsg: error
		}
	return doc

#: Pre-Update hook to encrypt field

updateEncrypt = (query, key) ->
	try
		salt = await bcrypt.genSalt SALT_WORK_FACTOR
		query[key] = await bcrypt.hash query[key], salt
	catch error
		return {
			message: 'Could not update encrypted field.'
			errorMsg: error
		}
	return query

#: Exports

module.exports =
	listCreate: listCreate
	saveEncrypt: saveEncrypt
	updateEncrypt: updateEncrypt

#::: End Program :::