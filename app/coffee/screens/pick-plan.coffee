Screen = require 'screens/screen'
pickPlan = require 'jade/pick-plan'
Form = require 'screens/form'

module.exports = class PickPlan extends Form

  @plans :
    individual : {name:"Individual", cost:10, is_a_team:false}
    team       : {name:"Team", cost:15, is_a_team:true}

  @getPlan : (plan)->
    if @plans[plan]? then return @plans[plan]
    else console.log("Could not get `#{plan}`, because `#{plan}` is not a plan.");

  constructor: (@$el, @config, @refreshPage, @gotoHome, @gotoAddPayment) ->
    @build @config
    super()

  build : (@config) ->
    @$node = $ pickPlan( @config )
    if @config.showLegacy
      $('.col.team', @$node).addClass('hidden').removeClass 'default'
      $('.col.individual', @$node).addClass 'default'
    else if @config.isTeam || (@config.buyNow && @config.buyNowPlan != 'individual')
      $('.col.individual', @$node).addClass 'hidden'

    @$el.append @$node
    castShadows @$node
    lexify @$node

    # Next / Activate plan
    $("#next", @$node).on 'click', ()=> @next()
    $("form", @$node).on 'submit', (e)=> e.preventDefault(); @next()

    $(".back-btn", @$node).on 'click', @gotoHome

    # Column Clicking
    $col = $('.col', @$node)
    $col.on 'click', (e)=>
      @selectedPlan = e.currentTarget.dataset.id
      $col.removeClass 'active'
      $(e.currentTarget, @$node).addClass 'active'
      if $(e.currentTarget).hasClass 'individual'
        @$node.removeClass 'name-team'
      else
        @$node.addClass 'name-team'

    # Set Default:
    # TODO: We probably want to allow the currently active plan to be passed in
    $defualtColumn = $ ".col.default", @$node
    $defualtColumn.trigger 'click'
    $('input', $defualtColumn).trigger 'click'


  getSelectedPlan : () -> PickPlan.getPlan @selectedPlan

  proceed : (cb) ->
    # We may want to actually create the team next step...

    @clearErrors()
    # If they selected a team plan && they haven't already created the team
    if @getSelectedPlan().is_a_team && !@config.isTeam
      teamName = $("#team-name", @$node).val()
      @config.createTeam teamName, (result)=>
        if result.error?
          @showErrors result.error
        else
          cb(result)
    else
      cb()

  next : () ->
    # If they already have a payment method
    if @config.hasPaymentMethod
      @setPlan (data)=>
        @config.hasPaymentMethod = true
        @refreshPage()
    # else, they don't have a plan, proceed to add a payment method
    else
      @proceed (data)=> @gotoAddPayment()
