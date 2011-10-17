throttle = (delta, cb) -> _.throttle(cb, delta)

window.timesheet = 
  module: do ->
    modules = {}
    (name) -> modules[name] or modules[name] = { views: {} }

((form) ->
  class form.Model extends Backbone.Model  
    defaults: ->
      id: null
      allDay: false
      title: ""
      start: new Date
      end: new Date
  
  class form.View extends Backbone.View
    el: "#form"
    events:
      "click button.cancel": "cancel"
      "click button.save": "save"
      "click button.delete": "delete"
      
    initialize: ->
      @model.view = @
      @model.bind "change", @render
      
      self = @
      
      $("#date").datepicker
        dateFormat: "yy-mm-dd"
      $("#title").autocomplete
        source: (request, response) ->
          console.log self.collection.pluck("title")
          response _(self.collection.pluck("title")).unique().filter((title) -> title.match(new RegExp(request.term, "i")))
      
      $(@el).modal
        backdrop: true
    
    render: =>
      @$("#title").val @model.get("title")
      @$("#startTime").val $.fullCalendar.formatDate(@model.get("start"), "hh:mmtt")
      @$("#endTime").val $.fullCalendar.formatDate(@model.get("end"), "hh:mmtt")
      @$("#description").val @model.get("description")
      @$("#date").val $.fullCalendar.formatDate(@model.get("start"), "yyyy-MM-dd")
      if @model.id then @$("button.delete").removeClass("disabled")
      else @$("button.delete").addClass("disabled")
      
    
    save: =>
      @model.set
        title: @$("#title").val()
        description: @$("#description").val()
        start: Date.parseExact(@$("#date").val() + " " + @$("#startTime").val(), "yyyy-MM-dd hh:mmtt")
        end: Date.parseExact(@$("#date").val() + " " + @$("#endTime").val(), "yyyy-MM-dd hh:mmtt")
        
      self = @
      @collection.upsert @model.toJSON(),
        success: -> $(self.el).modal("hide")
        error: -> alert "Houston we have a problem"

          
    edit: (json) =>
      @model.clear().set(json)
      $(@el).modal("show")

    cancel: =>
      $(@el).modal("hide")
    
    delete: =>
      if (model = @collection.get(@model.id)) and confirm("Are you sure that you would like to delete this event?")
        model.destroy
          success: @cancel
    
)(window.timesheet.module("calendar.form"))

((block) ->
  class block.Model extends Backbone.Model
    defaults: ->
      allDay: false
      title: ""
      start: new Date
      end: new Date
    parse: (json) ->
      console.log "Parsing", json
      json.start = $.fullCalendar.parseDate(json.start, false)
      json.end = $.fullCalendar.parseDate(json.end, false)
      delete json.color if json.color?
      json
    initialize: ->
      #@bind "change:title", =>
      #  @set color: 
  
  class block.Collection extends Backbone.Collection
    localStorage: new Store("timesheet.blocks")
    model: block.Model
    url: "block"
    
    parse: (json) ->
      _.map json, (json) ->
        json.start = $.fullCalendar.parseDate(json.start, false)
        json.end = $.fullCalendar.parseDate(json.end, false)
        json.color = if json.title.match(/^work/i) then "red" else "blue"
        json
    
    upsert: (json, options) ->
      console.log "Upsert", arguments...
      if model = @get(json.id) then model.save(json, options)
      else @create(json, options)
        
  
  class block.View extends Backbone.View
    initialize: ->
      @model.view = @

)(window.timesheet.module('calendar.block'))

((calendar) ->
  block = timesheet.module("calendar.block")
  form = timesheet.module("calendar.form")
  
  class calendar.Model extends Backbone.Model
  
  class calendar.View extends Backbone.View
    el: "#calendar"
    initialize: ->
      @collection = new block.Collection
      @collection.bind "all", throttle 100, =>
        $(@el).fullCalendar("refetchEvents")
        
      @form = new form.View
        model: new form.Model
        collection: @collection

      @render()

      @collection.fetch()

      self = @
      self.bind "select", (startDate, endDate) ->
        self.form.edit 
          start: startDate
          end: endDate
          title: ""
      
      self.bind "click", (event) ->
        self.form.edit(event)

    render: =>
      self = @
      
      #$(window).resize _.throttle(@resize, 200)
      $(@el).fullCalendar
        defaultView: "agendaDay"
        allDayDefault: false
        allDaySlot: false
        slotMinutes: 15
        selectable: true
        ignoreTimezone: false
        editable: true
        firstDay: 6
        header:
          left: "agendaDay,agendaWeek"
          center: "title"
          right: "today prev,next"
        #height: $(window).height()
        events: (start, end, cb) -> cb(self.collection.toJSON())
        #eventRender: (event, element, view) ->
        #  new block.View model: self.collection.get(event.id)
        #  element
        select: -> self.trigger "select", arguments...
        eventClick: -> self.trigger "click", arguments...
        eventDrop: (event, dayDelta, minuteDelta, allDay, revertFunc) ->
          if block = self.collection.get(event.id)
            block.save event,
              failure: revertFunc
        eventResize: (event, dayDelta, minuteDelta, revertFunc) ->
          console.log "Trying to resize", arguments...
          if block = self.collection.get(event.id)
            console.log "Resized", block, event
            block.save event,
              failure: revertFunc
        
    resize: => $(@el).fullCalendar "option", "height", $("div.content").innerHeight()    

      
)(window.timesheet.module('calendar'))


  
$ ->
  calendar = timesheet.module("calendar")
  
  app = new calendar.View
  
  
exports.init = ->
  console.log "Initted", arguments...