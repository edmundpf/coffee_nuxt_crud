<template lang="pug">
	div
		b-navbar(
			toggleable='lg',
			type='dark',
			variant='primary'
		)
			b-navbar-brand(href='/') Home
			b-navbar-toggle(target='nav-collapse')
			b-collapse#nav-collapse(v-if='$store.state.logged_in', is-nav='')
				b-navbar-nav
					b-nav-item-dropdown(text='Data', left='')
						b-dropdown-item(
							v-for='link in links',
							v-bind:key='link.path',
							:href='crudUrl(link)'
						) {{ link.title }}
				b-navbar-nav.ml-auto
					b-nav-form
						b-button.nav-button(v-b-modal.logout-modal='')
							| Logout
		logoutmodal
</template>

<script lang="coffee">

import logoutModal from '~/components/logoutModal'
import schemaConfig from '~/data_api/config/schema-config.json'
import { startCase, camelCase } from 'lodash'

export default

	data: ->
		links = []
		for key of schemaConfig
			links.push(
				title: startCase(camelCase(schemaConfig[key].path)),
				path: schemaConfig[key].path
			)
		return {
			links
		}

	components: {
		logoutModal
	}

	methods:
		crudUrl: (link) ->
			return "/crud?model=#{link.path}"

</script>