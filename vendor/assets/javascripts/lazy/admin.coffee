class Loader
  @show: ->
    @_instance().show()
  @hide: ->
    @_instance().hide()
  @_instance: ->
    unless @__instance
      @__instance = new Loader()
    @__instance
  constructor: ->
    @loader = $('body > div#lazy-loader')
    if @loader.length == 0
      @loader = $('<div>')
        .attr('id', 'lazy-loader')
        .css(display: 'none')
        .appendTo 'body'
  show: ->
    @loader.fadeIn()
  hide: ->
    @loader.fadeOut()


class Sortable
  constructor: (options = {})->
    url = '' + $('ul.items-list.sortable').parents('ul.sortable').data('url')

    if url.length == 0
      throw "Element ul.sortable must have data-url."

    if url.indexOf(':id') < 0 || url.indexOf(':target_id') < 0
      throw "Url has to have :id and :target_id placeholders."

    $("ul.items-list.sortable li:not(.header)").draggable appendTo: 'body',
      revert: 'invalid',
      cursor: 'move'
    
    $("ul.items-list.sortable li:not(.header)").droppable hoverClass: 'ui-state-hover',
      greedy: true,
      drop: (event, ui) ->
        object = $(ui.draggable)
        id = object.find('input[type=checkbox]').val()

        target = $(this)
        target_id = target.find('input[type=checkbox]').val()

        Loader.show()

        $.post(url, (data) ->
          object.insertAfter(target)
        )
        .fail( (jqXHR, textStatus) ->
          $('#notice')
            .html(jqXHR.responseJSON.join('. '))
            .show()
          setTimeout ->
            $('#notice').fadeOut(3000);
          , 3000
        )
        .always( ->
          object.css(top: '', left: '')
          Loader.hide()
        )

class LazyAdmin
  constructor: ->
    @_custom_select()
    @_custom_file_input()
    @_locales_tabs()
    @_fileupload()

  loader: ->
    Loader

  action_on_selected: (url, options = {}) ->
    self = this

    selector = options.selector ? '.selection'

    _method = options.method ? 'get'
    type = if _method == 'get' then 'get' else 'post'
    dataType = options.type || 'script'

    ids = $(selector)
      .filter(':checked')
      .map ->
        $(this).val()

    action_counter = ids.length

    @loader().show()

    ids.each ->
      $.ajax
        url: url.replace(':id', this),
        dataType: dataType,
        type: type,
        data : {_method: _method },
        complete: ->
          action_counter -= 1
          if action_counter == 0
            self.loader().hide()
            window.location.reload()

    # if ids.length > 0
      # window.location.reload()

    false

  _locales_tabs: ->
    $('.tabs_container').each ->
      if $(this).children('ul').first().children('li').length == 1
        $(this).children('ul').first().hide()
      else
        $(this).tabs()

  _custom_select: ->
    $('select').customSelect();

  _custom_file_input: ->
    $("input[type=file].custom-file-input.fileupload").customFileInput({path: false});
    $("input[type=file].custom-file-input").customFileInput();

  _fileupload: ->
    $("input[type=file].fileupload").fileupload sequentialUploads: true,
      singleFileUploads: true,
      add: (e, data) ->
        queue = data.fileInput.data('queue');
        
        if queue
          file = data.files[0];

          remove = $('<a>')
            .attr('href', '#')
            .html('&times;')
            .addClass('close')
            .click (event) ->
              event.preventDefault();
              data.jqXHR.abort();

          name = $('<p>').html file.name 

          progress = $('<div>')
            .addClass('progress')
            .progressbar();

          context = data.context = $('<div>')
            .append( remove )
            .append( name )
            .append( progress )
            .addClass('queue-item')
            .appendTo "##{queue}"

        data.submit()
      , progress: (e, data) ->
        
        if data.context
          progress = parseInt(data.loaded / data.total * 100, 10)
          data.context
            .find('.progress')
            .progressbar 'value', progress
      , always: (e, data) ->
        if data.context
          setTimeout( ->
            data.context
              .fadeOut('slow', ->
                $(this).remove()
              )
          , 3000)

jQuery ->
  window.lazy = new LazyAdmin()
