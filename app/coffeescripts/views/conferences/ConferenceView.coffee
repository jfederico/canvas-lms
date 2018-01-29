#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!conferences'
  'jquery'
  'Backbone'
  'jst/conferences/newConference'
  'str/htmlEscape'
  'jquery.google-analytics'
  '../../jquery.rails_flash_notifications'
], (I18n, $, {View}, template, htmlEscape) ->

  class ConferenceView extends View

    tagName: 'li'

    className: 'conference'

    template: template

    events:
      'click .edit_conference_link': 'edit'
      'click .delete_conference_link': 'delete'
      'click .close_conference_link': 'close'
      'click .start-button': 'start'
      'click .external_url': 'external'
      'click .delete_recording_link': 'deleteRecording'

    initialize: ->
      super
      @model.on('change', @render)

    edit: (e) ->
      # refocus if edit not finalized
      @$el.find('.al-trigger').focus()

    delete: (e) ->
      e.preventDefault()
      if !confirm I18n.t('confirm.delete', "Are you sure you want to delete this conference?")
        $(e.currentTarget).parents('.inline-block').find('.al-trigger').focus()
      else
        currentCog = $(e.currentTarget).parents('.inline-block').find('.al-trigger')[0]
        allCogs = $('#content .al-trigger').toArray()
        # Find the preceeding cog
        curIndex = allCogs.indexOf(currentCog)
        if (curIndex > 0)
          allCogs[curIndex - 1].focus()
        else
          $('.new-conference-btn').focus()
        @model.destroy success: =>
          $.screenReaderFlashMessage(I18n.t('Conference was deleted'))

    close: (e) ->
      e.preventDefault()
      return if !confirm(I18n.t('confirm.close', "Are you sure you want to end this conference?\n\nYou will not be able to reopen it."))
      $.ajaxJSON($(e.currentTarget).attr('href'), "POST", {}, (data) =>
        window.router.close(@model)
      )

    start: (e) ->
      if @model.isNew()
        e.preventDefault()
        return

      w = window.open(e.currentTarget.href, '_blank')
      if (!w) then return
      e.preventDefault()

      w.onload = () ->
        window.location.reload(true)

      # cross-domain
      i = setInterval(() ->
        if (!w) then return
        try
          href = w.location.href
        catch e
          clearInterval(i)
          window.location.reload(true)
      , 100)

    external: (e) ->
      # TODO: kill this if it's not in use anywhere
      $.trackEvent('Conference', 'External URL')
      e.preventDefault()
      loading_text = I18n.t('loading_urls_message', "Loading, please wait...")
      $self = $(e.currentTarget)
      link_text = $self.text()
      if (link_text == loading_text)
        return

      $self.text(loading_text)
      $.ajaxJSON($self.attr('href'), 'GET', {}, (data) ->
        $self.text(link_text)
        if (data.length == 0)
          $.flashError(I18n.t('no_urls_error', "Sorry, it looks like there aren't any %{type} pages for this conference yet.", {type: $self.attr('name')}))
        else if (data.length > 1)
          $box = $(document.createElement('DIV'))
          $box.append($("<p />").text(I18n.t('multiple_urls_message', "There are multiple %{type} pages available for this conference. Please select one:", {type: $self.attr('name')})))
          for datum in data
            $a = $("<a />", {href: datum.url || $self.attr('href') + '&url_id=' + datum.id, target: '_blank'})
            $a.text(datum.name)
            $box.append($a).append("<br>")

          $box.dialog(
            width: 425,
            minWidth: 425,
            minHeight: 215,
            resizable: true,
            height: "auto",
            title: $self.text()
          )
        else
          window.open(data[0].url)
      )

    deleteRecording: (e) ->
      return if !confirm(I18n.t('recordings.confirm.delete', "Are you sure you want to delete this recording?"))
      e.preventDefault()
      $deleteButton = $(e.currentTarget).parent()
      @toggleActionButton($deleteButton, {state: "processing", action: "delete"})
      @toggleRecordingLink($deleteButton, {state: "processing"})
      $.ajaxJSON($deleteButton.data('url') + "/recording", "DELETE", {
          recording_id: $deleteButton.data("id"),
        }, (data) =>
          if data.deleted == "true"
            @removeRecordingRow($deleteButton)
            return
          @ensureActionPerformed($deleteButton, 1, @removeRecordingRow)
      )

    ensureActionPerformed: ($button, attempt, callback) =>
      $.ajaxJSON($button.data('url') + "/recording", "GET", {
          recording_id: $button.data("id"),
        }, (data) =>
          if $.isEmptyObject(data)
            callback($button)
            return
          if attempt < 5
            attempt += 1
            setTimeout((=> @ensureActionPerformed($button, attempt, callback); return;), attempt * 1000)
            return
          $.flashError(I18n.t('conferences.recordings.action_error', "Sorry, the action performed on this recording failed. Try again later"))
          @toggleActionButton($button, {state: "processed", action: "delete"})
          @toggleRecordingLink($button, {state: "processed"})
      )

    toggleActionButton: ($button, data) =>
      $spinner = $('.ig-loader[data-id="' + $button.data("id") + '"][data-action="' + data.action + '"]')
      if data.state == 'processing'
        $button.hide()
        $spinner.show()
        return
      $spinner.hide()
      $button.show()

    toggleRecordingLink: ($button, data) =>
      $link = $('a[data-id="' + $button.data("id") + '"]')
      if data.state == 'processing'
          $link.bind 'click', ->
            return false
          return
      $link.unbind 'click'

    removeRecordingRow: ($button) =>
      $row = $('.ig-row[data-id="' + $button.data("id") + '"]')
      containerId = $($row.parent().parent().parent()).attr('id')
      $row.parent().remove()
      id = containerId.substring(11, containerId.length)
      @updateConferenceDetails(containerId.substring(11, containerId.length))

    updateConferenceDetails: (id) =>
      $info = $('div.ig-row#conf_' + id).children().children('div.ig-info')
      $detailRecordings = $info.children('div.ig-details').children('div.ig-details__item-recordings')
      $recordings = $('.ig-sublist#conference-' + id)
      recordings = $recordings.children().children().length
      # If it has more than one recording
      if recordings > 1
        $detailRecordings.text(I18n.t('recordings.recordings', "%{count} Recordings", {count: recordings}))
        return
      # If it has only one recording
      if recordings == 1
        $detailRecordings.text(I18n.t('recordings.recording', "%{count} Recording", {count: 1}))
        return
      # If it has no recordings
      $detailRecordings.remove()
      $recordings.remove()
      @shiftLinkToText($info, 'ig-title')

    shiftLinkToText: ($container, target) =>
      $link = $container.children('a.' + target)
      $container.prepend('<span class="' + target + '">' + $link.text() + '</span>')
      $link.remove()
