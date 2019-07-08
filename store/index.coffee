import Vuex from 'vuex'
import Cookies from 'js-cookie'
import createPersistedState from 'vuex-persistedstate'

createStore = () =>
	return new Vuex.Store(
		state: () => (
			username: ''
			access_token: ''
			logged_in: false
		),
		plugins: [
			createPersistedState(
				storage:
					getItem: (key) -> Cookies.get(key)
					setItem: (key, value) -> Cookies.set(key, value, { expires: 7, secure: false })
					removeItem: (key) -> Cookies.remove(key)
			)],
		mutations:
			mutateState: (state, payload) ->
				for key of payload
					if state[key]?
						state[key] = payload[key]
		actions:
			setState: (context, payload) ->
				context.commit('mutateState', payload);
)

export default createStore