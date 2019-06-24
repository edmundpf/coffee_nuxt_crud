module.exports = (grunt) ->
	grunt.loadNpmTasks('grunt-contrib-coffee')
	grunt.loadNpmTasks('grunt-contrib-watch')
	grunt.registerTask('sync', [
		'coffee:compile'
	])

	grunt.initConfig
		watch:
			coffee:
				files: 'data_api/src/**/*.coffee'
				tasks: ['coffee:compile']

		coffee:
			compile:
				options:
					bare: true
					sourceMap: true
				expand: true
				flatten: false
				cwd: 'data_api/src'
				src: '**/*.coffee'
				dest: 'data_api/js/'
				ext: '.js'