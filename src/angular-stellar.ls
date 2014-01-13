/*global angular:false*/
const {bind, noop, extend} = angular
const delayInFPS = 1000/60

const $requestAnimationFrame = <[
       $window  $log
]> ++ ($window, $log) ->
  #
  # http://caniuse.com/#feat=requestanimationframe
  #
  const NAMES = <[ request webkitRequest mozRequest oRequest msRequest ]>
  for name in NAMES when $window["#{ name }AnimationFrame"]
    return bind $window, that

  $log.warn 'Can\'t find requestAnimationFrame in your browser. Use polyfill.'
  -> $window.setTimeout it, delayInFPS

const stellarConfig = do
  # --- removed attributes
  # There's no need for these in Angular's world:
  # parallaxBackgrounds: true 
  # parallaxElements: true
  #
  # Let's make it responsive by default
  # responsive: false
  #
  # --- removed attributes
  scrollProperty: 'scroll'
  positionProperty: 'position'
  horizontalScrolling: true
  verticalScrolling: true
  horizontalOffset: 0
  verticalOffset: 0
  hideDistantElements: true
  hideElement: !-> it.addClass 'ng-hide'
  showElement: !-> it.removeClass 'ng-hide'
  isElementHidden: -> it.hasClass 'ng-hide'

class Target
  @_lastTime = 0
  @_targets = []

  @getInstance = (name, $element) ->
    Target[name] || new Target name, $element

  # return true if we need to reschedule $requestAnimationFrame
  @handleUpdate = (timestamp) ->
    const justUpdated = timestamp - @_lastTime < delayInFPS
    return true if justUpdated
    @_lastTime = timestamp
    #
    rescheduled = false
    for target in @_targets when target.handleUpdate! and not rescheduled
      rescheduled = true
    rescheduled

  (name, $element) ->
    @@[name] = @
    @@_targets.push @
    @_$element = $element
    @_callbacks = []
    @_props = {}

  addCallbak: ->
    const index = -1+@_callbacks.push it
    bind @_callbacks, @_callbacks.splice, index

  handleUpdate: !->
    const updated = @getOffset!
    updated.scrollTop   = @getTop!
    updated.scrollLeft  = @getLeft!

    return if angular.equals updated, @_props
    extend @_props, updated
    [callback @_props for callback in @_callbacks]

  #
  # https://github.com/markdalgleish/stellar.js/blob/master/src/jquery.stellar.js
  # L226
  handleWebkitBug: !->
    const {scrollTop, scrollLeft} = @_props

    @setTop scrollTop+1
    @setLeft scrollLeft+1

    @setTop scrollTop
    @setLeft scrollLeft

  getLeft: -> @_$element.prop 'scrollLeft'
  setLeft: !-> @_$element.prop 'scrollLeft' it

  getTop: -> @_$element.prop 'scrollTop'
  setTop: !-> @_$element.prop 'scrollTop' it

const $css = <[
       $window
]> ++ ($window) ->
  # $element.css styleName
  #
  # https://github.com/angular-ui/bootstrap/blob/master/src/position/position.js
  # L11~L19
  #
  ($element, cssprop) ->
    const el = $element.0
    const style = if el.currentStyle
      el.currentStyle # IE
    else if $window.getComputedStyle
      $window.getComputedStyle el
    else
      el.style # finally try and get inline style

    if cssprop then style[cssprop] else style

const $vendorPrefix = <[
       $css
]> ++ ($css) ->
  const VENDORS = /^(moz|webkit|khtml|o|ms)(?=[A-Z])/

  for name of $css angular.element('<script></script>') when name.match VENDORS
    prefix = that.0
    break

  (cssprop) ->
    prefix + unless prefix then cssprop
    else "#{ angular.uppercase cssprop.charAt(0) }#{ cssprop.slice 1 }"

const stellarTarget = <[
       $window  $document  $position  $requestAnimationFrame  $css  $vendorPrefix  stellarConfig
]> ++ ($window, $document, $position, $requestAnimationFrame, $css, $vendorPrefix, stellarConfig) ->

  const windowTarget    = Target.getInstance 'window' angular.element($window)
  const documentTarget  = Target.getInstance 'document' $document

  windowTarget.getOffset = documentTarget.getOffset = ->
    const docEl = $document.0.documentElement
    height: docEl.clientHeight
    width: docEl.clientWidth
    top: 0
    left: 0

  windowTarget.getLeft = documentTarget.getLeft = -> $window.pageXOffset
  windowTarget.getTop = documentTarget.getTop = -> $window.pageYOffset

  windowTarget.setLeft = documentTarget.setLeft = !-> $window.scrollTo(it, $window.pageYOffset)
  windowTarget.setTop = documentTarget.setLeft = !-> $window.scrollTo($window.pageXOffset, it)
  #
  # configurable
  #
  const {scrollProperty} = stellarConfig
  extend Target::, do
    getOffset: -> $position.offset @_$element
  , if angular.isObject scrollProperty then scrollProperty
  else let
    const cssInt = ($element, cssprop) -> parseInt $css($element, cssprop), 10
    const prefixedTransform = $vendorPrefix 'transform'
    #
    switch scrollProperty
    | 'position' =>
      getLeft: -> -1*cssInt @_$element, 'left'
      getTop: -> -1*cssInt @_$element, 'top'
    | 'margin' =>
      getLeft: -> -1*cssInt @_$element, 'marginLeft'
      getTop: -> -1*cssInt @_$element, 'marginTop'
    | 'transform' =>
      getLeft: ->
        const transform = $css @_$element, prefixedTransform
        if 'none' is transform then 0
        else -1*parseInt transform.match(/(-?[0-9]+)/g).4, 10

      getTop: ->
        const transform = $css @_$element, prefixedTransform
        if 'none' is transform then 0
        else -1*parseInt transform.match(/(-?[0-9]+)/g).5, 10
    | 'scroll' => fallthrough
    | _ => {}
  #
  const schedule = bind @, $requestAnimationFrame, !(timestamp) ->
    const reschedule = Target.handleUpdate timestamp
    return if 'scroll' is scrollProperty and not reschedule
    # 
    # if not triggered by 'scroll' event, reshedule everytime
    #
    schedule!
  #
  if scrollProperty is 'scroll'
    windowTarget._$element.on 'scroll resize' schedule
  #
  (name, $element) ->
    schedule! and Target.getInstance name, $element

const stellarBackgroundRatio = <[
       $position  $css  stellarTarget
]> ++ ($position, $css, stellarTarget) ->

  const getBackgroundPosition = ($element) ->
    const bgPos = $css $element, 'backgroundPosition' .split ' '
    [parseInt(bgPos.0, 10), parseInt(bgPos.1, 10)]

  const computeRatio = ($element, $attrs) ->
    const stellarBackgroundRatio = $attrs.stellarBackgroundRatio or 1
    const fixedRatioOffset = if 'fixed' is $css $element, 'backgroundAttachment' then 0 else 1
    fixedRatioOffset - stellarBackgroundRatio

  restrict: 'A'
  #
  # @using $attrs
  #   stellarBackgroundRatio
  #   stellarVerticalOffset
  #   stellarHorizontalOffset
  #
  link: !($scope, $element, $attrs) ->
    const finalRatio        = computeRatio $element, $attrs
    const verticalOffset    = $attrs.stellarVerticalOffset or stellarConfig.verticalOffset
    const horizontalOffset  = $attrs.stellarHorizontalOffset or stellarConfig.horizontalOffset
    const selfProperties    = $position.offset $element
    const selfBgPositions   = getBackgroundPosition $element
    const parentProperties  = top: 0, left: 0
    #
    selfProperties.bgTop = selfBgPositions.1
    selfProperties.bgLeft = selfBgPositions.0
    #
    stellarTarget 'window'
    .addCallbak !(targetProps) ->
      const bgTop = finalRatio * do
        targetProps.scrollTop +
        verticalOffset -
        targetProps.top -
        selfProperties.top +
        parentProperties.top - 
        selfProperties.bgTop
      #
      const bgLeft = finalRatio * do
        targetProps.scrollLeft +
        horizontalOffset -
        targetProps.left -
        selfProperties.left +
        parentProperties.left -
        selfProperties.bgLeft
      #
      $element.css 'background-position', "#{ bgLeft }px #{ bgTop }px"
    #
    |> $scope.$on '$destroy' _

const stellarRatio = <[
       $css  $vendorPrefix  $position  stellarConfig  stellarTarget
]> ++ ($css, $vendorPrefix, $position, stellarConfig, stellarTarget) ->

  const {positionProperty, horizontalScrolling, verticalScrolling} = stellarConfig

  const setPosition = if angular.isFunction positionProperty.setPosition
    positionProperty.setPosition
  else let
    const prefixedTransform = $vendorPrefix 'transform'
    switch positionProperty
    | 'position' =>
      setTop = !($element, top) -> $element.css 'top' top
      setLeft = !($element, left) -> $element.css 'left' left
    | 'transform' =>
      return !($element, left, startingLeft, top, startingTop) ->
        $element.css prefixedTransform, "translate3d(#{ left - startingLeft }px, #{ top - startingTop }px, 0)"

    !($element, left, startingLeft, top, startingTop) ->
      setLeft $element, "#{ left }px", "#{ startingLeft }px" if horizontalScrolling
      setTop $element, "#{ top }px", "#{ startingTop }px" if verticalScrolling


  const computeIsFixed = ($element) ->
    'fixed' is $css $element, 'position'

  const computeRatio = ($element, $attrs) ->
    const stellarRatio = $attrs.stellarRatio or 1
    const fixedRatioOffset = if computeIsFixed $element then 1 else 0
    stellarRatio + fixedRatioOffset - 1

  restrict: 'A'
  #
  # @using $attrs
  #   stellarRatio
  #   stellarVerticalOffset
  #   stellarHorizontalOffset
  link: !($scope, $element, $attrs) ->
    const isFixed           = computeIsFixed $element
    const finalRatio        = -1*computeRatio $element, $attrs
    const verticalOffset    = $attrs.stellarVerticalOffset or stellarConfig.verticalOffset
    const horizontalOffset  = $attrs.stellarHorizontalOffset or stellarConfig.horizontalOffset
    const selfProperties    = $position.offset $element
    const selfPositions     = $position.position $element
    const parentProperties  = top: 0, left: 0
    #    
    selfProperties.positionTop = selfPositions.top
    selfProperties.positionLeft = selfPositions.left
    #
    stellarTarget 'window'
    .addCallbak !(targetProps) ->
      #
      newTop = selfProperties.positionTop
      newOffsetTop = selfProperties.top
      if verticalScrolling
        newTop += finalRatio * do
          targetProps.scrollTop +
          verticalOffset +
          targetProps.top +
          selfProperties.positionTop -
          selfProperties.top +
          parentProperties.top
        newOffsetTop += newTop - selfProperties.positionTop        
      #
      newLeft = selfProperties.positionLeft
      newOffsetLeft = selfProperties.left

      if horizontalScrolling
        newLeft += finalRatio * do
          targetProps.scrollLeft +
          horizontalOffset +
          targetProps.left +
          selfProperties.positionLeft -
          selfProperties.left +
          parentProperties.left
        newOffsetLeft += newLeft - selfProperties.positionLeft
      #
      if stellarConfig.hideDistantElements
        targetScrollLeft = if isFixed then 0 else targetProps.scrollLeft
        targetScrollTop  = if isFixed then 0 else targetProps.scrollTop
        #
        isVisibleHorizontal = !horizontalScrolling or do
          newOffsetLeft + selfProperties.width > targetScrollLeft and
          newOffsetLeft < targetProps.width + targetProps.left + targetScrollLeft
        isVisibleVertical = !verticalScrolling or do
          newOffsetTop + selfProperties.height > targetScrollTop and
          newOffsetTop < targetProps.height + targetProps.top + targetScrollTop
      #
      const isHidden = stellarConfig.isElementHidden $element
      if isVisibleHorizontal and isVisibleVertical
        stellarConfig.showElement $element if isHidden
        #
        setPosition $element,  newLeft, selfProperties.positionLeft, newTop, selfProperties.positionTop
      else unless isHidden
        stellarConfig.hideElement $element
    |> $scope.$on '$destroy' _


angular.module 'angular.stellar' <[
  ui.bootstrap.position
]>
.constant 'stellarConfig' stellarConfig
.factory '$requestAnimationFrame' $requestAnimationFrame
.factory '$css' $css
.factory '$vendorPrefix' $vendorPrefix
.factory 'stellarTarget' stellarTarget

.directive 'stellarRatio' stellarRatio
.directive 'stellarBackgroundRatio' stellarBackgroundRatio
