<template lang="pug">
	b-container
		b-row.mt-5(align-h='center')
			b-col
				h1.text-center
					| {{ welcomeMessage }}
</template>

<script lang="coffee">

export default
	computed:
		welcomeMessage: ->
			return "Welcome #{this.$store.state.username}!"
	middleware: ['authToken']

</script>