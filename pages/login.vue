<template lang="pug">
	loginform
</template>

<script lang="coffee">

import loginForm from '~/components/loginForm'

export default
	components: {
		loginForm
	}
	middleware: ['authenticated']

</script>