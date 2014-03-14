"use strict"

# Config of library
LIB_CONFIG =
  name: "Hanger"
  version: "0.1.1-alpha"

# Node-types
ELEMENT_NODE = 1
ATTRIBUTE_NODE = 2
TEXT_NODE = 3
CDATA_SECTION_NODE = 4
ENTITY_REFERENCE_NODE = 5
ENTITY_NODE = 6
PROCESSING_INSTRUCTION_NODE = 7
COMMENT_NODE = 8
DOCUMENT_NODE = 9
DOCUMENT_TYPE_NODE = 10
DOCUMENT_FRAGMENT_NODE = 11
NOTATION_NODE = 12

# Regular expressions
REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i

# Main objects
_H = {}
$ = jQuery

# JavaScript API's support
support =
  storage: !!window.localStorage

# 限制器
limiter =
  ###
  # 键
  #
  # @property  key
  # @type      {Object}
  ###
  key:
    # 限制访问的 storage key 列表
    storage: ["sandboxStarted", "config", "fn", "buffer", "pool", "i18n", "web_api"]

# 内部数据载体
storage =
  ###
  # 沙盒运行状态
  #
  # @property  sandboxStarted
  # @type      {Boolean}
  ###
  sandboxStarted: false

  ###
  # 配置
  #
  # @property  config
  # @type      {Object}
  ###
  config:
    debug: true
    platform: ""
    # Web API 版本
    api: ""
    lang: (document.documentElement.lang ||
      document.documentElement.getAttribute("lang") ||
      navigator.language ||
      navigator.browserLanguage).split("-")[0]

  ###
  # 函数
  #
  # @property  fn
  # @type      {Object}
  ###
  fn:
    # DOM tree 构建未完成（sandbox 启动）时调用的处理函数
    prepare: []
    # DOM tree 构建已完成时调用的处理函数
    ready: []
    # 初始化函数
    init:
      # 系统对话框创建后
      systemDialog: $.noop
      # Ajax 请求
      ajaxHandler: ( succeed, fail ) ->
        return {
          # 状态码为 200
          success: ( data, textStatus, jqXHR ) ->
            args = slicer arguments
            ###
            # 服务端在返回请求结果时必须是个 JSON，如下：
            #    {
            #      "code": {Integer}       # 处理结果代码，code > 0 为成功，否则为失败
            #      "message": {String}     # 请求失败时的提示信息
            #    }
            ###
            if data.code > 0
              succeed.apply($, args) if $.isFunction succeed
            else
              if $.isFunction fail
                fail.apply $, args
              # 默认弹出警告对话框
              else
                systemDialog "alert", data.message
          # 状态码为非 200
          error: $.noop
        }
    handler: {}

  ###
  # 缓冲区，存储临时数据
  #
  # @property  buffer
  # @type      {Object}
  ###
  buffer: {}

  ###
  # 对象池
  # 
  # @property  pool
  # @type      {Object}
  ###
  pool: {}

  ###
  # 国际化
  #
  # @property  i18n
  # @type      {Object}
  ###
  i18n:
    _SYS:
      dialog:
        zh:
          title: "系统提示"
          close: "关闭"
          ok: "确定"
          cancel: "取消"
          yes: "是"
          no: "否"
        en:
          title: "System"
          close: "Close"
          ok: "Ok"
          cancel: "Cancel"
          yes: "Yes"
          no: "No"

  ###
  # Web API
  #
  # @property  api
  # @type      {Object}
  ###
  web_api: {}

###
# 切割 Array Like 片段
#
# @private
# @method  slicer
# @return
###
slicer = ( args, index ) ->
  return [].slice.call args, (Number(index) || 0)

###
# 取得数组或类数组对象中最后一个元素
#
# @private
# @method  last
# @return
###
last = ( array ) ->
  return slicer(array, -1)[0]

###
# 全局配置
# 
# @private
# @method    setup
###
setup = ->
  # Ajax 全局配置
  $.ajaxSetup type: "post", dataType: "json"
  
  # Ajax 出错
  $(document).ajaxError ( event, jqXHR, ajaxSettings, thrownError ) ->
    response = jqXHR.responseText
    
    # if response isnt undefined
      # To do sth.
    
    return false
  
  # $( document ).bind({
  #   "keypress": function( e ) {
  #     var pointer = this;
      
  #     // 敲击回车键
  #     if ( e.keyCode == 13 ) {
  #       var CB_Enter = bindHandler( "CB_Enter" );
  #       var dialogs = $(":ui-dialog:visible");
        
  #       // 有被打开的对话框
  #       if ( dialogs.size() ) {
  #         // 按 z-index 值从大到小排列对话框数组
  #         [].sort.call(dialogs, function( a, b ) {
  #           return $(b).closest(".ui-dialog").css("z-index") * 1 - $(a).closest(".ui-dialog").css("z-index") * 1;
  #         });
  #         // 触发对话框的确定/是按钮点击事件
  #         $("[data-button-flag='ok'], [data-button-flag='yes']", $([].shift.call(dialogs)).closest(".ui-dialog")).each(function() {
  #           $(this).trigger("click");
  #           return false;
  #         });
  #       }
  #       else if ( $.isFunction(CB_Enter) ) {
  #         CB_Enter.call(pointer);
  #       }
  #     }
  #   }
  # });

###
# 生成自定义系统对话框
# 
# @private
# @method  systemDialog
# @param   type {String}
# @param   message {String}
# @param   okHandler {Function}
# @param   cancelHandler {Function}
# @return  {Boolean}
###
systemDialog = ( type, message, okHandler, cancelHandler ) ->
  result = false

  if $.type(type) is "string"
    type = type.toLowerCase()

    # jQuery UI Dialog
    if $.isFunction $.fn.dialog
      poolName = "systemDialog"
      i18nText = storage.i18n._SYS.dialog[_H.config "lang"]
      storage.pool[poolName] = {} if not storage.pool.hasOwnProperty poolName
      dlg = storage.pool[poolName][type]

      if not dlg
        dlg = $("<div data-role=\"dialog\" data-type=\"system\" />")
          .appendTo $("body")
          .on
            # 初始化后的额外处理
            dialogcreate: initializer "systemDialog"
            # 为按钮添加标记
            dialogopen: ( e, ui ) ->
              $(".ui-dialog-buttonset .ui-button", $(this).closest(".ui-dialog")).each ->
                btn = $(this)

                switch $.trim btn.text()
                  when i18nText.ok
                    type = "ok"
                  when i18nText.cancel
                    type = "cancel"
                  when i18nText.yes
                    type = "yes"
                  when i18nText.no
                    type = "no"

                btn.addClass "ui-button-#{type}"
          .dialog
            title: i18nText.title
            width: 400
            minHeight: 100
            closeText: i18nText.close
            modal: true
            autoOpen: false
            resizable: false
            closeOnEscape: false

        storage.pool[poolName][type] = dlg

        # 移除关闭按钮
        dlg.closest(".ui-dialog").find(".ui-dialog-titlebar-close").remove()

      result = systemDialogHandler type, message, okHandler, cancelHandler
    # 使用 window 提示框
    else
      result = true

      if type is "alert"
        window.alert message
      else
        if window.confirm message
          okHandler() if $.isFunction okHandler
        else
          cancelHandler() if $.isFunction cancelHandler

  return result

###
# 系统对话框的提示信息以及按钮处理
# 
# @private
# @method  systemDialogHandler
# @param   type {String}             对话框类型
# @param   message {String}          提示信息内容
# @param   okHandler {Function}      确定按钮
# @param   cancelHandler {Function}  取消按钮
# @return
###
systemDialogHandler = ( type, message, okHandler, cancelHandler ) ->
  i18nText = storage.i18n._SYS.dialog[_H.config "lang"]
  handler = ( cb, rv ) ->
    $(this).dialog "close"

    cb() if $.isFunction cb

    return rv

  btns = []
  btnText =
    ok: i18nText.ok
    cancel: i18nText.cancel
    yes: i18nText.yes
    no: i18nText.no

  dlg = storage.pool.systemDialog[type]
  dlgContent = $("[data-role='dialog-content']", dlg)
  dlgContent = dlg if dlgContent.size() is 0

  # 设置按钮以及其处理函数
  if type is "confirm"
    btns.push
      text: btnText.ok
      click: -> 
        handler.apply this, [okHandler, true]
        return true
    btns.push
      text: btnText.cancel
      click: ->
        handler.apply this, [cancelHandler, false]
        return true
  else if type is "confirmex"
    btns.push
      text: btnText.yes
      click: ->
        handler.apply this, [okHandler, true]
        return true
    btns.push
      text: btnText.no
      click: ->
        handler.apply this, [cancelHandler, false]
        return true
    btns.push
      text: btnText.cancel
      click: ->
        handler.apply this, [null, false]
        return true
  else
    type = "alert"

    if okHandler isnt null
      btns.push
        text: btnText.ok,
        click: ->
          handler.apply this, [okHandler, true]
          return true
    else
      btns = null

  # 提示信息内容
  dlgContent.html message || ""

  # 添加按钮并打开对话框
  dlg
    .dialog "option", "buttons", btns
    .dialog "open"

###
# 将处理函数绑定到内部命名空间
# 
# @private
# @method  bindHandler
# @return
###
bindHandler = ->
  args = arguments
  name = args[0]
  handler = args[1]
  fnList = storage.fn.handler
  
  # 无参数时返回函数列表
  if args.length is 0
    handler = clone fnList
  # 传入函数名
  else if typeof name is "string"
    # 保存
    if $.isFunction handler
      fnList[name] = handler
    # 获取
    else
      handler = fnList[name]
  # 传入函数列表
  else if $.isPlainObject name
    fnList[funcName] = func for funcName, func of name when $.isFunction func
    
  return handler

###
# 执行指定函数
# 
# @private
# @method  runHandler
# @param   name {String}         函数名
# @param   [args, ...] {List}    函数的参数
# @return  {Variant}
###
runHandler = ( name ) ->
  args = slicer arguments, 1
  func = storage.fn.handler[name]
  result = null
  
  # 指定函数名时，从函数池里提取对应函数
  if typeof name is "string" and $.isFunction func
    result = func.apply window, args
  # 指定函数列表（数组）时
  else if $.isArray name
    func.call window for func in name when $.isFunction func
  
  return result

###
# 将函数加到指定队列中
# 
# @private
# @method  pushHandler
# @param   handler {Function}    函数
# @param   queue {String}        队列名
###
pushHandler = ( handler, queue ) ->
  storage.fn[queue].push handler if $.isFunction handler

###
# 克隆对象并返回副本
# 
# @private
# @method  clone
# @param   source {Object}       源对象，只能为数组或者纯对象
# @return  {Object}
###
clone = ( source ) ->
  result = null
  
  if $.isArray(source) or source.length isnt undefined
    result = [].concat [], slicer source
  else if $.isPlainObject source
    result = $.extend true, {}, source
  
  return result

###
# 获取初始化函数
# 
# @private
# @method  initializer
# @return  {Function}
###
initializer = ( key ) ->
  return storage.fn.init[key]

###
# Get data from internal storage
#
# @private
# @method  getStorageData
# @param   ns_str {String}   Namespace string
# @param   ignore {Boolean}  忽略对 storage key 的限制
# @return  {String}
###
getStorageData = ( ns_str, ignore ) ->
  parts = ns_str.split "."
  result = null

  if ignore || !isLimited parts[0], limiter.key.storage
    result = storage

    $.each parts, ( idx, part ) ->
      rv = result.hasOwnProperty part
      result = result[part]
      return rv

  return result

###
# Set data into internal storage
#
# @private
# @method  setStorageData
# @param   ns_str {String}   Namespace string
# @param   data {Variant}    
# @return  {Variant}
###
setStorageData = ( ns_str, data ) ->
  parts = ns_str.split "."
  length = parts.length
  isObj = $.isPlainObject data

  if length is 1
    key = parts[0]
    result = setData storage, key, data, storage.hasOwnProperty key
  else
    result = storage

    $.each parts, ( i, n ) ->
      if i < length - 1
        result[n] = {} if not result.hasOwnProperty n
      else
        result[n] = setData result, n, data, $.isPlainObject result[n]
      result = result[n]
      return true

  return result

setData = ( target, key, data, condition ) ->
  if condition && $.isPlainObject data
    $.extend true, target[key], data
  else
    target[key] = data

  return target[key]

###
# Determines whether a propery belongs an object
#
# @private
# @method  isExisted
# @param   host {Object}   A collection of properties
# @param   prop {String}   The property to be determined
# @param   type {String}   Limits property's variable type
# @return  {Boolean}
###
isExisted = ( host, prop, type ) ->
  return $.type(host) is "object" and $.type(prop) is "string" and host.hasOwnProperty(prop) and $.type(host[prop]) is type

###
# Determines whether a key in a limited key list
#
# @private
# @method  isLimited
# @param   key {String}   Key to be determined
# @param   list {Array}   Limited key list
# @return  {Boolean}
###
isLimited = ( key, list ) ->
  return $.inArray(key, list) > -1

###
# 添加到内部存储对象的访问 key 限制列表中
#
# @private
# @method  limit
# @param   key {String}  Key to be limited
# @return
###
limit = ( key ) ->
  limiter.key.storage.push key

$.extend _H,
  ###
  # 自定义警告提示框
  #
  # @method  alert
  # @param   message {String}
  # @param   [callback] {Function}
  # @return  {Boolean}
  ###
  alert: ( message, callback ) ->
    return systemDialog "alert", message, callback
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirm: ( message, ok, cancel ) ->
    return systemDialog "confirm", message, ok, cancel
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirmEX: ( message, ok, cancel ) ->
    return systemDialog "confirmEX", message, ok, cancel

  ###
  # 将外部处理函数引入到沙盒中
  # 
  # @method  queue
  # @return
  ###
  queue: ->
    return bindHandler.apply window, slicer arguments
  
  ###
  # 执行指定函数
  # 
  # @method  run
  # @return  {Variant}
  ###
  run: ->
    return runHandler.apply window, slicer arguments

  url: ->
    loc = window.location
    url =
      search: loc.search.substring(1)
      hash: loc.hash.substring(1)
      query: {}

    $.each url.search.split("&"), ( i, str ) ->
      str = str.split("=")
      url.query[str[0]] = str[1] if $.trim(str[0]) isnt ""

    return url

  ###
  # Save web resource to local disk
  #
  # @method  download
  # @param   fileURL {String}
  # @param   fileName {String}
  # @return
  ###
  download: ( fileURL, fileName ) ->
    # for non-IE
    if not window.ActiveXObject
      save = document.createElement "a"

      save.href = fileURL
      save.target = "_blank"
      save.download = fileName || "unknown"

      event = document.createEvent "Event"
      event.initEvent "click", true, true
      save.dispatchEvent event
      (window.URL || window.webkitURL).revokeObjectURL save.href
    # for IE
    else if !! window.ActiveXObject && document.execCommand
      _window = window.open fileURL, "_blank"
      
      _window.document.close()
      _window.document.execCommand "SaveAs", true, fileName || fileURL
      _window.close()

  ###
  # Determines whether a function has been defined
  #
  # @method  functionExists
  # @param   funcName {String}
  # @param   isWindow {Boolean}
  # @return  {Boolean}
  ###
  functionExists: ( funcName, isWindow ) ->
    return isExisted (if isWindow is true then window else storage.fn.handler), funcName, "function"

  ###
  # 用指定占位符填补字符串
  # 
  # @method  pad
  # @param   string {String}         源字符串
  # @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
  # @param   placeholder {String}    占位符
  # @return  {String}
  ###
  pad: ( string, length, placeholder ) ->
    if $.type(string) of { string: true, number: true }
      # 占位符只能指定为一个字符
      # 占位符默认为空格
      placeholder = "\x20" if $.type(placeholder) isnt "string" or placeholder.length isnt 1
      # Set length to 0 if it isn't an integer.
      length = 0 if not ($.isNumeric(length) and /^-?[1-9]\d*$/.test(length))
      string = String string
      index = 1
      unit = String placeholder
      len = Math.abs(length) - string.length

      if len > 0
        # 补全占位符
        while index < len
          placeholder += unit
          index++

        string = if length > 0 then string + placeholder else placeholder + string

    return string

  ###
  # 补零（前导零）
  # 
  # @method  zerofill
  # @param   number {Number}   源数字
  # @param   digit {Integer}   数字位数，正数为在后面补充，负数则在前面补充
  # @return  {String}
  ###
  zerofill: ( number, digit ) ->
    result = ""

    if $.isNumeric(number) and $.isNumeric(digit) and /^-?[1-9]\d*$/.test digit
      rfloat = /^([-+]?\d+)\.(\d+)$/
      isFloat = rfloat.test number
      prefix = ""

      digit = parseInt digit

      # 浮点型数字时 digit 则为小数点后的位数
      if digit > 0 and isFloat
        number = "#{number}".match rfloat
        prefix = "#{number[1] * 1}."
        number = number[2]
      # Negative number
      else if number * 1 < 0
        prefix = "-"
        number = "#{number}".substring(1)

      result = this.pad number, digit, "0"

      if digit < 0 and isFloat
        result = ""
      else
        result = prefix + result

    return result

###
# 重新配置系统参数
# 
# @private
# @method  resetConfig
# @param   setting {Object}      配置参数
# @return  {Object}              （修改后的）系统配置信息
###
resetConfig = ( setting ) ->
  return clone if $.isPlainObject(setting) then $.extend(storage.config, setting) else storage.config

$.extend _H,
  ###
  # 沙盒
  #
  # 封闭运行环境的开关，每个页面只能运行一次
  # 
  # @method  sandbox
  # @param   setting {Object}      系统环境配置
  # @return  {Object/Boolean}      （修改后的）系统环境配置
  ###
  sandbox: ( setting ) ->
    if storage.sandboxStarted isnt true
      # 返回值为修改后的系统环境配置
      result = resetConfig setting

      # 全局配置
      # setup();
      # DOM tree 构建前的函数队列
      runHandler storage.fn.prepare
      
      # DOM tree 构建后的函数队列
      $(document).ready ->
        runHandler storage.fn.ready
      
      storage.sandboxStarted = true
    
    return result || false

  ###
  # DOM 未加载完时调用的处理函数
  # 主要进行事件委派等与 DOM 加载进程无关的操作
  #
  # @method  prepare
  # @param   handler {Function}
  # @return
  ###
  prepare: ( handler ) ->
    return pushHandler handler, "prepare"

  ###
  # DOM 加载完成时调用的处理函数
  #
  # @method  ready
  # @param   handler {Function}
  # @return
  ###
  ready: ( handler ) ->
    return pushHandler handler, "ready"

###
# 设置初始化函数
# 
# @private
# @method   initialize
# @return
###
initialize = ->
  args = arguments
  key = args[0]
  func = args[1]

  if $.isPlainObject key
    $.each key, initialize
  else if $.type(key) is "string" and storage.fn.init.hasOwnProperty(key) and $.isFunction func
    storage.fn.init[key] = func

###
# 获取 Web API 版本
# 
# @private
# @method   api_ver
# @return   {String}
###
api_ver = ->
  ver = _H.config "api"

  if $.type(ver) is "string" && $.trim(ver) isnt ""
    ver = "/" + ver
  else
    ver = ""

  return ver

$.extend _H,
  ###
  # 更改 LIB_CONFIG.name 以适应项目「本土化」
  # 
  # @method   mask
  # @param    guise {String}    New name for library
  # @return   {Boolean}
  ###
  mask: ( guise ) ->
    result = false

    if $.type(guise) is "string"
      if window.hasOwnProperty guise
        console.error "'#{guise}' has existed as a property of Window object." if window.console
      else
        window[guise] = window[LIB_CONFIG.name]
        result = delete window[LIB_CONFIG.name]
        LIB_CONFIG.name = guise

    return result

  ###
  # 获取系统信息
  # 
  # @method  config
  # @param   [key] {String}
  # @return  {Object}
  ###
  config: ( key ) ->
    return if $.type(key) is "string" then storage.config[key] else clone storage.config
  
  ###
  # 设置初始化信息
  # 
  # @method  init
  # @return
  ###
  init: ->
    return initialize.apply window, slicer arguments

  ###
  # 设置及获取国际化信息
  # 
  # @method  i18n
  # @return  {String}
  ###
  i18n: ->
    args = arguments
    key = args[0]
    result = null

    # 批量存储
    # 调用方式：func({})
    if $.isPlainObject key
      $.extend storage.i18n, key
    else if REG_NAMESPACE.test key
      data = args[1]

      # 单个存储（用 namespace 格式字符串）
      if args.length is 2 and typeof data is "string" and not REG_NAMESPACE.test data
        # to do sth.
      # 取出并进行格式替换
      else if $.isPlainObject data
        result = getStorageData "i18n.#{key}", true
        result = (if typeof result is "string" then result else "").replace  /\{%\s*([A-Z0-9_]+)\s*%\}/ig, ( txt, k ) ->
          return data[k]
      # 拼接多个数据
      else
        result = ""

        $.each args, ( i, txt ) ->
          if typeof txt is "string" and REG_NAMESPACE.test txt
            r = getStorageData "i18n.#{txt}", true
            result += (if typeof r is "string" then r else "")

    return result

  ###
  # 设置及获取 Web API
  # 
  # @method  api
  # @return  {String}
  ###
  api: ->
    args = arguments
    key = args[0]
    result = null

    if $.isPlainObject key
      $.extend storage.web_api, key
    else if $.type(key) is "string"
      regexp = /^([a-z]+)_/
      match = (key.match(regexp) ? [])[1]
      data = args[1]
      type = undefined

      $.each ["front", "admin"], ( i, n ) ->
        if match is n
          type = n
          return false

      if type
        key = key.replace regexp, ""
      else
        type = "common"

      result = api_ver() + getStorageData "web_api.#{type}.#{key}", true

      if $.isPlainObject data
        result = result.replace /\:([a-z_]+)/g, ( m, k ) ->
          return data[k]

    return result

###
# 通过 HTML 构建 dataset
# 
# @private
# @method  constructDatasetByHTML
# @param   html {HTML}   Node's outer html string
# @return  {JSON}
###
constructDatasetByHTML = ( html ) ->
  dataset = {}
  fragment = html.match /<[a-z]+[^>]*>/i

  if fragment isnt null
    $.each fragment[0].match(/(data(-[a-z]+)+=[^\s>]*)/ig) || [], ( idx, attr ) ->
      attr = attr.match /data-(.*)="([^\s"]*)"/i
      dataset[$.camelCase attr[1]] = attr[2]
      return true

  return dataset

###
# 通过属性列表构建 dataset
# 
# @private
# @method  constructDatasetByAttributes
# @param   attributes {NodeList}   Attribute node list
# @return  {JSON}
###
constructDatasetByAttributes = ( attributes ) ->
  dataset = {}

  $.each attributes, ( idx, attr ) ->
    dataset[$.camelCase match(1)] = attr.nodeValue if attr.nodeType is ATTRIBUTE_NODE and (match = attr.nodeName.match /^data-(.*)$/i)
    return true

  return dataset

$.extend _H,
  ###
  # 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
  # 
  # @method  data
  # @return  {Object}
  ###
  data: ->
    args = arguments
    length = args.length

    if length > 0
      target = args[0]

      try
        # 当 target 是包含有 "@" 的字符串时会抛出异常。
        # Error: Syntax error, unrecognized expression: @
        node = $(target).get(0)
      catch error
        node = target

      # 获取 DOM 的「data-*」属性集
      if node and node.nodeType is ELEMENT_NODE
        result = {}

        if node.dataset
          result = node.dataset
        else if node.outerHTML
          result = constructDatasetByHTML node.outerHTML
        else if node.attributes and $.isNumeric node.attributes.length
          result = constructDatasetByAttributes node.attributes
      # 存储数据到内部/从内部获取数据
      else
        if typeof target is "string" and REG_NAMESPACE.test(target)
          result = if length is 1 then getStorageData(target) else setStorageData target, args[1]

          # 将访问的 key 锁住，在第一次设置之后无法再读写到内部
          limit(target.split(".")[0]) if length > 1 and last(args) is true
        # 有可能覆盖被禁止存取的内部 key，暂时不允许批量添加
        # else {
        #   $.each(args, function( i, n ) {
        #     $.extend(storage, n);
        #   });
        # }

    return result || null

  ###
  # Save data
  ###
  save: ->
    args = arguments
    key = args[0]
    val = args[1]

    # Use localStorage
    if support.storage
      if typeof key is "string"
        oldVal = this.access key

        localStorage.setItem key, escape if $.isPlainObject(oldVal) then JSON.stringify($.extend oldVal, val) else val
    # Use cookie
    # else

  ###
  # Access data
  ###
  access: ->
    key = arguments[0]

    if typeof key is "string"
      # localStorage
      if support.storage
        result = localStorage.getItem key

        if result isnt null
          result = unescape result

          try
            result = JSON.parse result
          catch error
            result = result
      # Cookie
      # else

    return result || null

  # clear: ->

###
# AJAX & SJAX 请求处理
# 
# @private
# @method  request
# @param   options {Object/String}   请求参数列表/请求地址
# @param   succeed {Function}        请求成功时的回调函数
# @param   fail {Function}           请求失败时的回调函数
# @param   synch {Boolean}           是否为同步，默认为异步
# @return  {Object}
###
request = ( options, succeed, fail, synch ) ->
  # 无参数时跳出
  if arguments.length is 0
    return
  
  # 当 options 不是纯对象时将其当作 url 来处理（不考虑其变量类型）
  options = url: options if $.isPlainObject(options) is false
  handlers = initializer("ajaxHandler") succeed, fail
  options.success = handlers.success if not $.isFunction options.success
  options.error = handlers.error if not $.isFunction options.error

  return $.ajax $.extend options, async: synch isnt true

$.extend _H,
  ###
  # Asynchronous JavaScript and XML
  # 
  # @method  ajax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数
  # @param   fail {Function}           请求失败时的回调函数
  # @return
  ###
  ajax: ( options, succeed, fail ) ->
    return request options, succeed, fail
  
  ###
  # Synchronous JavaScript and XML
  # 
  # @method  sjax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数
  # @param   fail {Function}           请求失败时的回调函数
  # @return
  ###
  sjax: ( options, succeed, fail ) ->
    return request options, succeed, fail, true

$.extend _H,
  encodeEntities: ( string ) ->
    return if $.type(string) is "string" then string.replace /([<>&\'\"])/, ( match, chr ) ->
      switch chr
        when "<"
          et = lt
        when ">"
          et = gt
        when "\""
          et = quot
        when "'"
          et = apos
        when "&"
          et = amp

      return "&#{et};"
    else string

  decodeEntities: ( string ) ->

window[LIB_CONFIG.name] = _H