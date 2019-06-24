import { tokenAuth } from '~/plugins/misc-functions'

export default ({ app, store, redirect }) ->
	await app.$axios.setToken store.state.access_token
	auth = await tokenAuth app

	if !store.state.logged_in or !auth.status
		await store.dispatch(
			'setState',
			username: ''
			logged_in: false
			access_token: ''
		)
		await app.$axios.setToken ''
		return redirect '/login'

	else if auth.status and auth.refresh_token?
			await store.dispatch(
				'setState',
				access_token: auth.refresh_token
			)
			await app.$axios.setToken auth.refresh_token