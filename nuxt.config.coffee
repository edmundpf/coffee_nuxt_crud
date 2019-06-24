import webConfig from './assets/json/webConfig.json'
module.exports =

	#: Web Server Config
	server:
		port: webConfig.port

	#: Page Headers
	head:
		title: webConfig.site_title
		meta: [
			{ charset: 'utf-8' }
			{ name: 'viewport', content: 'width=device-width, initial-scale=1' }
			{ hid: 'description', name: 'description', content: webConfig.site_desc }
		]
		link: [
			{ rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' }
		]

	#: Mode
	mode: 'spa'

	#: Modules
	modules: [
		'bootstrap-vue/nuxt'
		'@nuxtjs/axios'
		'~/modules/coffeescript'
	]

	#: Data Server Config
	serverMiddleware: [
		'~/data_api/js/index.js',
	]

	#: Bootstrap Vue
	bootstrapVue:
		bootstrapCSS: false
		bootstrapVueCSS: false

	#: CSS
	css: [
		{ src: '~/assets/css/custom.scss', lang: 'scss' }
	]

	#: Progress Bar Color

	loading:
		color: '#3B8070'

	#: Build Configuration

	build:
		extend = (config, { isDev, isClient }) ->
			if (isDev && isClient)
				pass

#::: End Program :::