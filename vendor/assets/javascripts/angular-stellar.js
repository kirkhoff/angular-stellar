(function(){
  var bind, noop, element, extend, delayInFPS, $requestAnimationFrame, stellarConfig, Target, $css, stellarTarget, stellarBackgroundRatio, stellarRatio;
  bind = angular.bind, noop = angular.noop, element = angular.element, extend = angular.extend;
  delayInFPS = 1000 / 60;
  $requestAnimationFrame = ['$window', '$log'].concat(function($window, $log){
    var NAMES, i$, len$, name, that;
    NAMES = ['request', 'webkitRequest', 'mozRequest', 'oRequest', 'msRequest'];
    for (i$ = 0, len$ = NAMES.length; i$ < len$; ++i$) {
      name = NAMES[i$];
      if (that = $window[name + "AnimationFrame"]) {
        return bind($window, that);
      }
    }
    $log.warn('Can\'t find requestAnimationFrame in your browser. Use polyfill.');
    return function(it){
      return $window.setTimeout(it, delayInFPS);
    };
  });
  stellarConfig = {
    scrollProperty: 'scroll',
    positionProperty: 'position',
    horizontalScrolling: true,
    verticalScrolling: true,
    horizontalOffset: 0,
    verticalOffset: 0,
    responsive: false,
    parallaxBackgrounds: true,
    parallaxElements: true,
    hideDistantElements: 1,
    hideElement: function(it){
      it.addClass('ng-hide');
    },
    showElement: function(it){
      it.removeClass('ng-hide');
    },
    isElementHidden: function(it){
      return it.hasClass('ng-hide');
    }
  };
  Target = (function(){
    Target.displayName = 'Target';
    var prototype = Target.prototype, constructor = Target;
    Target._lastTime = 0;
    Target.handleUpdate = function(timestamp){
      var justUpdated, rescheduled, name, target;
      justUpdated = timestamp - this._lastTime < delayInFPS;
      if (justUpdated) {
        return true;
      }
      this._lastTime = timestamp;
      rescheduled = false;
      for (name in this) {
        target = this[name];
        if ((typeof target.handleUpdate === 'function' && target.handleUpdate(timestamp)) && !rescheduled) {
          rescheduled = true;
        }
      }
      return rescheduled;
    };
    function Target(dom){
      this._$element = element(
      dom);
      this._callbacks = [];
      this._props = {};
    }
    prototype.isPropChanged = function(){
      var updated;
      updated = this.getOffset();
      updated.scrollTop = this.getTop();
      updated.scrollLeft = this.getLeft();
      if (angular.equals(updated, this._props)) {
        return false;
      }
      extend(this._props, updated);
      return true;
    };
    prototype.addCallbak = function(it){
      var index;
      index = -1 + this._callbacks.push(it);
      return bind(this._callbacks, this._callbacks.splice, index);
    };
    prototype.handleUpdate = function(timestamp){
      var i$, ref$, len$, callback;
      if (!this.isPropChanged()) {
        return;
      }
      for (i$ = 0, len$ = (ref$ = this._callbacks).length; i$ < len$; ++i$) {
        callback = ref$[i$];
        callback(this._props);
      }
    };
    prototype.handleWebkitBug = function(){
      var ref$, scrollTop, scrollLeft;
      ref$ = this._props, scrollTop = ref$.scrollTop, scrollLeft = ref$.scrollLeft;
      this.setTop(scrollTop + 1);
      this.setLeft(scrollLeft + 1);
      this.setTop(scrollTop);
      this.setLeft(scrollLeft);
    };
    prototype.getLeft = function(){
      return this._$element.prop('scrollLeft');
    };
    prototype.setLeft = function(it){
      this._$element.prop('scrollLeft', it);
    };
    prototype.getTop = function(){
      return this._$element.prop('scrollTop');
    };
    prototype.setTop = function(it){
      this._$element.prop('scrollTop', it);
    };
    return Target;
  }());
  $css = ['$window'].concat(function($window){
    return function($element, cssprop){
      var el;
      el = $element[0];
      if (el.currentStyle) {
        return el.currentStyle[cssprop];
      } else if ($window.getComputedStyle) {
        return $window.getComputedStyle(el)[cssprop];
      } else {
        return el.style[cssprop];
      }
    };
  });
  stellarTarget = ['$window', '$document', '$position', '$requestAnimationFrame', '$css', 'stellarConfig'].concat(function($window, $document, $position, $requestAnimationFrame, $css, stellarConfig){
    var windowTarget, documentTarget, windowScheduled, scrollProperty, updateFn, schedule;
    windowTarget = Target.window = new Target($window);
    documentTarget = Target.document = new Target($document);
    windowScheduled = false;
    windowTarget.getOffset = documentTarget.getOffset = function(){
      var docEl;
      docEl = $document[0].documentElement;
      return {
        height: docEl.clientHeight,
        width: docEl.clientWidth,
        top: 0,
        left: 0
      };
    };
    windowTarget.getLeft = documentTarget.getLeft = function(){
      return $window.pageXOffset;
    };
    windowTarget.getTop = documentTarget.getTop = function(){
      return $window.pageYOffset;
    };
    windowTarget.setLeft = documentTarget.setLeft = function(it){
      $window.scrollTo(it, $window.pageYOffset);
    };
    windowTarget.setTop = documentTarget.setLeft = function(it){
      $window.scrollTo($window.pageXOffset, it);
    };
    scrollProperty = stellarConfig.scrollProperty;
    updateFn = function(timestamp){
      Target.handleUpdate(timestamp);
      schedule();
    };
    extend(Target.prototype, {
      getOffset: function(){
        return $position.offset(this._$element);
      }
    }, angular.isObject(scrollProperty)
      ? scrollProperty
      : function(){
        var cssInt;
        cssInt = function($element, cssprop){
          return parseInt($css($element, cssprop), 10);
        };
        switch (scrollProperty) {
        case 'scroll':
          updateFn = function(timestamp){
            if (Target.handleUpdate(timestamp)) {
              schedule();
            }
          };
          return {};
        case 'position':
          return {
            getLeft: function(){
              return -1 * cssInt(this._$element, 'left');
            },
            getTop: function(){
              return -1 * cssInt(this._$element, 'top');
            }
          };
        case 'margin':
          return {
            getLeft: function(){
              return -1 * cssInt(this._$element, 'marginLeft');
            },
            getTop: function(){
              return -1 * cssInt(this._$element, 'marginTop');
            }
          };
        case 'transform':
          throw Error('unimplemented');
        default:
          throw Error('unimplemented');
        }
      }());
    schedule = bind(this, $requestAnimationFrame, updateFn);
    return function(name, $element){
      schedule();
      if (scrollProperty === 'scroll' && !windowScheduled) {
        windowScheduled = true;
        angular.element($window).on('scroll resize', schedule);
      }
      return Target[name] || (Target[name] = new Target($element));
    };
  });
  stellarBackgroundRatio = ['$window', '$position', '$css', 'stellarTarget'].concat(function($window, $position, $css, stellarTarget){
    var getBackgroundPosition, computeRatio;
    getBackgroundPosition = function($element){
      var bgPos;
      bgPos = $css($element, 'backgroundPosition').split(' ');
      return [parseInt(bgPos[0]), parseInt(bgPos[1])];
    };
    computeRatio = function($element, $attrs){
      var stellarBackgroundRatio, fixedRatioOffset;
      stellarBackgroundRatio = $attrs.stellarBackgroundRatio || 1;
      fixedRatioOffset = 'fixed' === $css($element, 'backgroundAttachment') ? 0 : 1;
      return fixedRatioOffset - stellarBackgroundRatio;
    };
    return {
      restrict: 'A',
      link: function($scope, $element, $attrs){
        var finalRatio, verticalOffset, horizontalOffset, selfProperties, selfBgPositions, parentProperties;
        finalRatio = computeRatio($element, $attrs);
        verticalOffset = $attrs.stellarVerticalOffset || stellarConfig.verticalOffset;
        horizontalOffset = $attrs.stellarHorizontalOffset || stellarConfig.horizontalOffset;
        selfProperties = $position.offset($element);
        selfBgPositions = getBackgroundPosition($element);
        parentProperties = {
          top: 0,
          left: 0
        };
        selfProperties.bgTop = selfBgPositions[1];
        selfProperties.bgLeft = selfBgPositions[0];
        $scope.$on('$destroy', stellarTarget('window', $window).addCallbak(function(targetProps){
          var bgTop, bgLeft;
          bgTop = finalRatio * (targetProps.scrollTop + verticalOffset - targetProps.top - selfProperties.top + parentProperties.top - selfProperties.bgTop);
          bgLeft = finalRatio * (targetProps.scrollLeft + horizontalOffset - targetProps.left - selfProperties.left + parentProperties.left - selfProperties.bgLeft);
          $element.css('background-position', bgLeft + "px " + bgTop + "px");
        }));
      }
    };
  });
  stellarRatio = ['$window', '$css', '$position', 'stellarConfig', 'stellarTarget'].concat(function($window, $css, $position, stellarConfig, stellarTarget){
    var positionProperty, horizontalScrolling, verticalScrolling, setPosition, computeIsFixed, computeRatio;
    positionProperty = stellarConfig.positionProperty, horizontalScrolling = stellarConfig.horizontalScrolling, verticalScrolling = stellarConfig.verticalScrolling;
    setPosition = angular.isFunction(positionProperty.setPosition)
      ? positionProperty.setPosition
      : function(){
        var setTop, setLeft;
        switch (positionProperty) {
        case 'position':
          setTop = function($element, top){
            $element.css('top', top);
          };
          setLeft = function($element, left){
            $element.css('left', left);
          };
          break;
        case 'transform':
          throw Error('unimplemented');
        default:
          throw Error('unimplemented');
        }
        return function($element, left, startingLeft, top, startingTop){
          if (horizontalScrolling) {
            setLeft($element, left + "px", startingLeft + "px");
          }
          if (verticalScrolling) {
            setTop($element, top + "px", startingTop + "px");
          }
        };
      }();
    computeIsFixed = function($element){
      return 'fixed' === $css($element, 'position');
    };
    computeRatio = function($element, $attrs){
      var stellarRatio, fixedRatioOffset;
      stellarRatio = $attrs.stellarRatio || 1;
      fixedRatioOffset = computeIsFixed($element) ? 1 : 0;
      return stellarRatio + fixedRatioOffset - 1;
    };
    return {
      restrict: 'A',
      link: function($scope, $element, $attrs){
        var isFixed, finalRatio, verticalOffset, horizontalOffset, selfProperties, selfPositions, parentProperties;
        isFixed = computeIsFixed($element);
        finalRatio = -1 * computeRatio($element, $attrs);
        verticalOffset = $attrs.stellarVerticalOffset || stellarConfig.verticalOffset;
        horizontalOffset = $attrs.stellarHorizontalOffset || stellarConfig.horizontalOffset;
        selfProperties = $position.offset($element);
        selfPositions = $position.position($element);
        parentProperties = {
          top: 0,
          left: 0
        };
        selfProperties.positionTop = selfPositions.top;
        selfProperties.positionLeft = selfPositions.left;
        $scope.$on('$destroy', stellarTarget('window', $window).addCallbak(function(targetProps){
          var newTop, newOffsetTop, newLeft, newOffsetLeft, targetScrollLeft, targetScrollTop, isVisibleHorizontal, isVisibleVertical, isHidden;
          newTop = selfProperties.positionTop;
          newOffsetTop = selfProperties.top;
          if (verticalScrolling) {
            newTop += finalRatio * (targetProps.scrollTop + verticalOffset + targetProps.top + selfProperties.positionTop - selfProperties.top + parentProperties.top);
            newOffsetTop += newTop - selfProperties.positionTop;
          }
          newLeft = selfProperties.positionLeft;
          newOffsetLeft = selfProperties.left;
          if (horizontalScrolling) {
            newLeft += finalRatio * (targetProps.scrollLeft + horizontalOffset + targetProps.left + selfProperties.positionLeft - selfProperties.left + parentProperties.left);
            newOffsetLeft += newLeft - selfProperties.positionLeft;
          }
          if (stellarConfig.hideDistantElements) {
            targetScrollLeft = isFixed
              ? 0
              : targetProps.scrollLeft;
            targetScrollTop = isFixed
              ? 0
              : targetProps.scrollTop;
            isVisibleHorizontal = !horizontalScrolling || (newOffsetLeft + selfProperties.width > targetScrollLeft && newOffsetLeft < targetProps.width + targetProps.left + targetScrollLeft);
            isVisibleVertical = !verticalScrolling || (newOffsetTop + selfProperties.height > targetScrollTop && newOffsetTop < targetProps.height + targetProps.top + targetScrollTop);
          }
          isHidden = stellarConfig.isElementHidden($element);
          if (isVisibleHorizontal && isVisibleVertical) {
            if (isHidden) {
              stellarConfig.showElement($element);
            }
            setPosition($element, newLeft, selfProperties.positionLeft, newTop, selfProperties.positionTop);
          } else if (!isHidden) {
            stellarConfig.hideElement($element);
          }
        }));
      }
    };
  });
  angular.module('angular.stellar', ['ui.bootstrap.position']).constant('stellarConfig', stellarConfig).factory('$requestAnimationFrame', $requestAnimationFrame).factory('$css', $css).factory('stellarTarget', stellarTarget).directive('stellarRatio', stellarRatio).directive('stellarBackgroundRatio', stellarBackgroundRatio);
}).call(this);
