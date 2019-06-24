<template lang="pug">
	b-modal#logout-modal(
		v-model='modalShow',
		title='Logout',
		ok-variant='danger',
		ok-title='Logout',
		@ok='submitEvent'
	) Are you sure you want to logout?
</template>

<script lang="coffee">

export default

	data: ->
		return
			modalShow: false

	methods: ->
		submitEvent: (evt) ->
			evt.preventDefault()
			await this.$store.dispatch(
				'setState'
				username: ''
				logged_in: false
				access_token: ''
			)
			await this.$axios.setToken ''
			this.modalShow = false
			this.$router.push '/login'

</script>