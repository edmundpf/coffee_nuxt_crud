<template lang="pug">
	loginForm
</template>

<script lang="coffee">

import loginForm from '~/components/loginForm'

export default
	components: {
		loginForm
	}
	middleware: ['authenticated']

</script>