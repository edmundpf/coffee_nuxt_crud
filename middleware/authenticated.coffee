export default ({store, redirect }) ->
	if store.state.logged_in
		return redirect('/')