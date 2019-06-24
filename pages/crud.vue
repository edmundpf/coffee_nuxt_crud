<template lang="pug">
	b-container(fluid)
		b-alert.mt-3(
			:show='dismissCountDown',
			@dismiss-count-down='countDownChanged',
			variant='success',
			dismissible=''
		) {{ feedbackMessage }}
		b-row.mt-5
			b-col.my-1(md='6')
				b-form-group.mb-0(label-cols-sm='3', label='Filter')
					b-input-group
						b-form-input(v-model='filter', placeholder='Type to Search')
						b-input-group-append
							b-button(:disabled='!filter', @click="filter = ''") Clear
			b-col.my-1(md='6')
				b-form-group.mb-0(label-cols-sm='3', label='Per page')
					b-form-select(v-model='perPage', :options='pageOptions')
		b-row
			b-col.my-1(md='6')
				b-form-group.mb-0(label-cols-sm='3', label='Page')
					b-pagination.my-0(
						v-model='currentPage',
						:total-rows='totalRows',
						:per-page='perPage'
					)
			b-col.my-1(md='6')
				b-form-group.mb-0(label-cols-sm='3', label='Insert record')
					b-button.mr-1.mb-3(@click='createButton($event.target)', variant='success')
						| Create
		b-row.mx-0(align-h='center')
			b-row.stacked-responsive-table
				b-table.table-packed.mb-5(
					striped='',
					hover='',
					bordered='',
					show-empty='',
					small='',
					caption-top='',
					stacked='md',
					:items='items',
					:current-page='currentPage',
					:per-page='perPage',
					:filter='filter',
					:sort-by.sync='sortBy',
					:sort-direction='sortDirection',
					:fields='fields',
					@filtered='onFiltered'
				)
					template(slot='table-caption') {{ pageTitle }}
					template(slot='actions', slot-scope='row')
						b-button.mr-1(
							size='sm',
							@click='editButton(row.item, row.index, $event.target)',
							variant='warning'
						) Edit
						b-button.mr-1(
							size='sm',
							@click='copyButton(row.item, row.index, $event.target)',
							variant='info'
						) Copy
						b-button.mr-1(
							size='sm',
							@click='deleteButton(row.item, row.index, $event.target)',
							variant='danger'
						) Delete
		b-modal(
			:id='editModal.id',
			:title='editModal.title',
			v-model='editShow',
			size='lg',
			ok-variant='success',
			ok-title='Save',
			@ok='editEvent',
			@cancel='editCancel'
		)
			b-alert(
				v-model='editAlert',
				variant='danger',
				dismissible=''
			) {{ this.feedbackMessage }}
			b-form-group.mb-3(
				v-for='field in editFields',
				v-bind:key='field.key',
				label-cols-sm='3',
				:label='titleCase(field.key)'
			)
				b-input-group
					b-form-input(
						v-model='field.value',
						v-if='isPassword(field)',
						type='password'
					)
					b-form-input(v-model='field.value', v-else='')
					b-input-group-append(v-if='field.list')
						b-form-select#inline-form-custom-select-pref.mb-2.mr-sm-2.mb-sm-0(
							v-model='field.list_mode',
							:options="['Set', 'Push', 'Push Unique']"
						)
		b-modal(
			:id='createModal.id',
			:title='createModal.title',
			v-model='createShow',
			size='lg',
			ok-variant='success',
			ok-title='Save',
			@ok='createEvent',
			@cancel='createCancel'
		)
			b-alert(v-model='createAlert', variant='danger', dismissible='') {{ this.feedbackMessage }}
			b-form-group.mb-3(
				v-for='field in createFields',
				v-bind:key='field.key',
				label-cols-sm='3',
				:label='titleCase(field.key)'
			)
				b-form-input(
					v-model='field.value',
					v-if='isPassword(field)',
					type='password'
				)
				b-form-input(v-model='field.value', v-else='')
		b-modal(
			:id='deleteModal.id',
			:title='deleteModal.title',
			v-model='deleteShow',
			size='lg',
			ok-variant='danger',
			ok-title='Delete',
			@ok='deleteEvent',
			@cancel='deleteCancel'
		)
			b-alert(
				v-model='deleteAlert',
				variant='danger',
				dismissible=''
			) {{ this.feedbackMessage }}
			strong Are you sure you want to delete the following record?
			pre {{ deleteModal.content }}
</template>

<script lang="coffee">

import { apiReq } from '~/plugins/misc-functions'
import format from 'date-fns/format'
import { startCase, camelCase } from 'lodash'

export default
	data: ->
		return
			items: []
			feedbackMessage: ''
			editAlert: false
			createAlert: false
			deleteAlert: false
			dismissSecs: 3
			dismissCountDown: 0
			editShow: false
			createShow: false
			deleteShow: false
			totalRows: 1
			currentPage: 1
			perPage: 5
			pageOptions: [5, 10, 25, 50, 100]
			sortBy: null
			sortDirection: 'asc'
			filter: null
			fields: []
			editFields: []
			createFields: []
			primary_key: null
			primaryValTemp: ''
			primary_val: ''
			listKeys: []
			allKeys: []
			pageTitle: ''
			editModal:
				id: 'edit-modal'
				title: ''
			createModal:
				id: 'create-modal'
				title: ''
			deleteModal:
				id: 'delete-modal'
				title: ''
				content: ''

	mounted: ->
		await this.getAttributes()
		await this.apiReset()

	methods:

		getAttributes: ->
			api_req = await apiReq(this, "#{this.$route.query.model}/schema")
			this.primary_key = api_req.response.primary_key
			this.listKeys = api_req.response.list_fields
			this.allKeys = api_req.response.schema
			this.pageTitle = this.titleCase this.$route.query.model

		apiReset: ->
			this.fields = []
			this.editFields = []
			this.createFields = []

			items = await apiReq(this, "#{this.$route.query.model}/get_all")

			if items.status == 'ok'
				delete_keys = ['_id', 'uid', '__v']

				for key in delete_keys
					del_index = this.allKeys.indexOf key
					if del_index >= 0
						this.allKeys.splice(this.allKeys.indexOf(key), 1)

				for i in [0...items.response.length] by -1
					for key in [...this.allKeys, ...delete_keys]
						if this.listKeys.includes key
							items.response[i][key] = items.response[i][key].toString()
						if delete_keys.includes key
							delete items.response[i][key]

					items.response[i].createdAt = format(items.response[i].createdAt, 'YYYY/MM/DD HH:mm:ss')
					items.response[i].updatedAt = format(items.response[i].updatedAt, 'YYYY/MM/DD HH:mm:ss')

				this.items = items.response;
				this.totalRows = this.items.length;

				for key in this.allKeys
					this.fields.push(
						"key": key,
						"sortable": true
					)
					if !['createdAt', 'updatedAt'].includes key

						fields_dict = {
							"key": key,
							"value": '',
							"list_mode": 'Set'
						}

						if this.listKeys.includes key
							fields_dict.list = true
						else
							fields_dict.list = false
						if key == this.primary_key
							fields_dict.primary = true
						else
							fields_dict.primary = false
						this.editFields.push fields_dict
						this.createFields.push fields_dict

				if this.fields.length > 0
					this.fields.push { key: "actions", sortable: false }

			else
				if items.response.message? and items.response.message != ''
					this.errorMessage = items.response.message
				else
					this.errorMessage = 'Could not fetch table data.'
				this.showAlert = true

		onFiltered: (filteredItems) ->
			this.totalRows = filteredItems.length
			this.currentPage = 1

		editButton: (item, index, button) ->
			this.editModal.title = "Edit row #{index}"
			this.populateForms(item, this.editFields)
			this.$root.$emit('bv::show::modal', this.editModal.id, button)
			for i in [0...this.editFields.length]
				if this.editFields[i].key == this.primary_key
					this.primaryValTemp = this.editFields[i].value

		copyButton: (item, index, button) ->
			this.createModal.title = "Copy row #{index}"
			this.populateForms(item, this.createFields)
			this.$root.$emit('bv::show::modal', this.createModal.id, button)

		createButton: (button) ->
			this.createModal.title = 'Create a new record'
			this.$root.$emit('bv::show::modal', this.createModal.id, button)

		deleteButton: (item, index, button) ->
			this.deleteModal.title = "Delete row #{index}?"
			this.deleteModal.content = JSON.stringify(item, null, 2)
			this.$root.$emit('bv::show::modal', this.deleteModal.id, button)
			this.primary_val = item[this.primary_key]

		resetModal: (modal) ->
			modal.title = modal.content = this.primary_val = ''
			this.editAlert = this.createAlert = this.deleteAlert = false

		resetFormModal: (modal, modalFields) ->
			modal.title = ''
			for i in [0...modalFields.length]
				modalFields[i].value = ''
				modalFields[i].list_mode = 'Set'
			this.editAlert = this.createAlert = this.deleteAlert = false

		populateForms: (item, modalFields) ->
			for item_key of item
				for i in [0...modalFields.length]
					if modalFields[i].key == item_key
						modalFields[i].value = item[item_key]

		titleCase: (string) ->
			return startCase(camelCase(string))

		isPassword: (field) ->
			return field.key == 'password'

		countDownChanged: (dismissCountDown) ->
			this.dismissCountDown = dismissCountDown

		createCancel: (evt) ->
			evt.preventDefault()
			this.createShow = false
			this.createAlert = false
			this.resetFormModal(this.createModal, this.createFields)

		editCancel: (evt) ->
			evt.preventDefault()
			this.editShow = false
			this.editAlert = false
			this.resetFormModal(this.editModal, this.editFields)
			this.primaryValTemp = ''

		deleteCancel: (evt) ->
			evt.preventDefault()
			this.deleteShow = false
			this.deleteAlert = false
			this.resetModal(this.deleteModal)

		createEvent: (evt) ->
			evt.preventDefault()
			create_dict = {}
			for i in [0...this.createFields.length]
				if this.createFields[i].value != ''
					create_dict[this.createFields[i].key] = this.createFields[i].value

			if Object.keys(create_dict).length > 0
				api_req = await apiReq(this, "#{this.$route.query.model}/insert", create_dict)
				if api_req.status == 'error'
					if api_req.response.message? and api_req.response.message != ''
						this.feedbackMessage = api_req.response.message
					else
						this.feedbackMessage = api_req.response.errmsg
					this.createAlert = true
				else if api_req.status == 'ok'
					await this.apiReset()
					this.createShow = false
					this.createAlert = false
					this.resetFormModal(this.createModal, this.createFields)
					this.feedbackMessage = 'Record created successfully'
					this.dismissCountDown = this.dismissSecs

		editEvent: (evt) ->
			evt.preventDefault()
			edit_dict = {}
			push_list = []
			push_unique_list = []
			set_list = []
			edit_dict[this.primary_key] = this.primaryValTemp

			for i in [0...this.createFields.length]
				if this.createFields[i].value != ''
					if !this.editFields[i].list
						if this.editFields[i].key != this.primary_key
							edit_dict[this.editFields[i].key] = this.editFields[i].value
						else if this.editFields[i].key == this.primary_key
							edit_dict.update_primary = this.editFields[i].value
					else
						if this.editFields[i].list_mode == 'Set'
							set_list.push { [this.editFields[i].key]: this.editFields[i].value }
						else if this.editFields[i].list_mode == 'Push'
							push_list.push { [this.editFields[i].key]: this.editFields[i].value }
						else if this.editFields[i].list_mode == 'Push Unique'
							push_unique_list.push { [this.editFields[i].key]: this.editFields[i].value }

			actions = []
			if (Object.keys(edit_dict).length > 0)
				actions.push { action: 'update', dict: edit_dict }
			for i in [0...push_list.length]
				push_list[i][this.primary_key] = edit_dict.update_primary
				actions.push { action: 'push', dict: push_list[i] }
			for i in [0...push_unique_list.length]
				push_unique_list[i][this.primary_key] = edit_dict.update_primary
				actions.push { action: 'push_unique', dict: push_unique_list[i] }
			for i in [0...set_list.length]
				set_list[i][this.primary_key] = edit_dict.update_primary
				actions.push { action: 'set', dict: set_list[i] }

			hasError = false
			for i in [0...actions.length]
				api_req = await apiReq(this, "#{this.$route.query.model}/#{actions[i].action}", actions[i].dict)
				if api_req.status == 'error'
					if api_req.response.message? and api_req.response.message != ''
						this.feedbackMessage = api_req.response.message
					else
						this.feedbackMessage = api_req.response.errmsg
					this.editAlert = true
					return
				else if api_req.status == 'ok'
					if i == actions.length - 1
						await this.apiReset()
						this.editShow = false
						this.editAlert = false
						this.resetFormModal(this.editModal, this.editFields)
						this.primaryValTemp = ''
						this.feedbackMessage = 'Record updated successfully'
						this.dismissCountDown = this.dismissSecs
						return

		deleteEvent: (evt) ->
			delete_dict = { [this.primary_key]: this.primary_val }
			if delete_dict[this.primary_key]?
				api_req = await apiReq(this, "#{this.$route.query.model}/delete", delete_dict)
				if api_req.status == 'error'
					if api_req.response.message? and api_req.response.message != ''
						this.feedbackMessage = api_req.response.message
					else
						this.feedbackMessage = api_req.response.errmsg
					this.deleteAlert = true

				else if api_req.status == 'ok'
					await this.apiReset()
					this.deleteShow = false
					this.deleteAlert = false
					this.resetModal(this.deleteModal)
					this.feedbackMessage = 'Record deleted successfully'
					this.dismissCountDown = this.dismissSecs
	middleware: ['authToken']

</script>