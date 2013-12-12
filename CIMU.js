/*!
 * the project global object of CIMU-EDU
 *
 * Copyright 2013, Ourai Lin
 *
 * Date: Thu Apr 25 16:51:10 2013
 */
;(function( window, $, undefined ) {

"use strict";

var _P = $.noop;
var REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i;
var storage = {
    i18n: {}
  };

/**
 * 生成自定义系统对话框
 * 
 * @private
 * @method  systemDialog
 * @param   {String} type
 * @param   {String} message
 * @param   {Function} okHandler
 * @param   {Function} cancelHandler
 * @return   {Boolean}
 */
function systemDialog( type, message, okHandler, cancelHandler ) {
  var result = false;

  // 确保已经引入 jQuery UI Dialog
  if ( $.fn.dialog && $.type(type) === "string" ) {
    var dlgCls = "CIMU-" + type.toLowerCase();
    var dialog = $("." + dlgCls);

    // 构建对话框
    if ( dialog.size() === 0 ) {
      dialog = $("<div />")
        .addClass( dlgCls )
        .addClass( "system_dialog" )
        .attr({ "data-role": "dialog", "data-type": "system" })
        .append( "<img class=\"dialog_image\" src=\"<%= asset_path('common/dialog/warning.png') %>\"><div class=\"dialog_text\" />" );

      dialog.appendTo( $("body") )
        .dialog({
          "title": _P.i18n("w.n.system", "w.n.tooltip"),
          "width": 400,
          "minHeight": 100,
          "closeText": _P.i18n("w.v.close"),
          "modal": true,
          "autoOpen": false,
          "resizable": false,
          "closeOnEscape": false
        })
        // 为按钮添加标记
        .on("dialogopen", function() {
          var flag = "button_inited";

          if ( $(this).data(flag) !== true ) {
            $(".ui-dialog-buttonset .ui-button", $(this).closest(".ui-dialog")).each(function() {
              var btn = $(this);
              var flag;

              switch( $.trim( btn.text() ) ) {
                case _P.i18n( "w.v.determine" ):
                  flag = "ok";
                  break;
                case _P.i18n( "w.v.cancel" ):
                  flag = "cancel";
                  break;
                case _P.i18n( "w.int.yes" ):
                  flag = "yes";
                  break;
                case _P.i18n( "w.int.no" ):
                  flag = "no";
                  break;
              }

              btn.addClass( "ui-button-" + flag );
            });

            if ( flag !== undefined ) {
              $(this).data(flag, true);
            }
          }
        })
        // 移除关闭按钮
        .closest(".ui-dialog")
        .find(".ui-dialog-titlebar-close")
        .remove();
    }

    result = systemDialogHandler(type, message, okHandler, cancelHandler);
  }

  return result;
}

/**
 * 系统对话框的提示信息以及按钮处理
 * 
 * @private
 * @method  systemDialogHandler
 * @param   {String} type               对话框类型
 * @param   {String} message            提示信息内容
 * @param   {Function} okHandler        确定按钮
 * @param   {Function}  cancelHandler   取消按钮
 */
function systemDialogHandler( type, message, okHandler, cancelHandler ) {
    var btns = [];
    var btnText = {
        "ok": _P.i18n( "w.v.determine" ),
        "cancel": _P.i18n( "w.v.cancel" ),
        "yes": _P.i18n( "w.int.yes" ),
        "no": _P.i18n( "w.int.no" )
    };
    var handler = function( cb, rv ) {
        $(this).dialog("close");

        if ( $.isFunction( cb ) ) {
            cb();
        }

        return rv;
    };

    // 设置按钮以及其处理函数
    if ( type === "confirm" ) {
        btns.push({
            "text": btnText.ok,
            "click": function() { handler.apply(this, [okHandler, true]); }
        });

        btns.push({
            "text": btnText.cancel,
            "click": function() { handler.apply(this, [cancelHandler, false]); }
        });
    }
    else if ( type === "confirmEX" ) {
        btns.push({
            "text": btnText.yes,
            "click": function() { handler.apply(this, [okHandler, true]); }
        });

        btns.push({
            "text": btnText.no,
            "click": function() { handler.apply(this, [cancelHandler, false]); }
        });

        btns.push({
            "text": btnText.cancel,
            "click": function() { handler.apply(this, [null, false]); }
        });
    }
    else {
        type = "alert";

        if ( okHandler !== null ) {
            btns.push({
                "text": btnText.ok,
                "click": function() { handler.apply(this, [okHandler, true]); }
            });
        }
        else {
            btns = null;
        }
    }

    // 将提示信息内容以及按钮添加到系统对话框上并打开
    $(".CIMU-" + type.toLowerCase())
        .children(".dialog_text").html(message || "")
        .closest(".system_dialog").dialog("option", "buttons", btns).dialog("open");
}

/**
 * 将 location.hash 转换为 object
 * 
 * @private
 * @method  parseHash
 * @return  {Object}
 */
function parseHash() {
  var hash = location.hash.substring(1);
  var hashObj = {};

  $.each( hash.split("&"), function( i, str ) {
    str = str.split("=");

    if ( str[0] !== "" ) {
      hashObj[str[0]] = str[1];
    }
  });

  return hashObj;
}

/**
 * 更新 hash
 * 
 * @private
 * @method  updateHash
 * @param   {String} key
 * @param   {String} value
 * @return  {String}
 */
function updateHash( key, value ) {
  var hash = location.hash.substring(1);
  var result = "";

  // 保证 key & value 为字符串并且非空
  if ( $.type(key) === "string" && key !== "" && $.type(value) === "string" && $.trim(value) !== "" ) {
    // 键值对
    var kvGroup = key + "=" + value;

    if ( hash === "" ) {
      result = kvGroup;
    }
    else {
      var hashReg = new RegExp(key + "=\[^&\]*");

      if ( hashReg.test(hash) ) {
        result = hash.replace( hashReg, function( w ) {
          return kvGroup;
        });
      }
      else {
        result = hash + "&" + kvGroup;
      }
    }

    location.hash = result;
  }

  return result;
}

/**
 * 生成组件标识
 * 
 * @private
 * @method  generateFlag
 * @param   {jQuery DOM} j_dom
 * @param   {String} attr_name
 * @return  {String}
 */
function generateFlag( j_dom, attr_name ) {
    var flag = "";
    var selector;
    var prefix;

    // Tab
    if ( j_dom.hasClass("comp_tab_wrapper") ) {
        selector = ".comp_tab_wrapper";
        prefix = "TG_";
    }
    // Pagination
    else if ( j_dom.hasClass("pagination") ) {
        selector = ".pagination";
        prefix = "P_";
    }

    // 当所传组件单元合法时才进行处理
    if ( $.type(selector) === "string" ) {
        var idx = j_dom.index(selector) + 1;
        var attr_val = j_dom.attr( attr_name );

        if ( attr_val === undefined || attr_val === "" ) {
            flag = prefix + idx;
        }
        else {
            var temp = $(selector + "[" + attr_name + "='" + attr_val + "'']");

            // 已经存在其他具有相同标识的
            if ( temp.size() > 0 && temp.is( j_dom ) === false ) {
                flag = attr_val + "_" + idx;
            }
            else {
                flag = attr_val;
            }
        }

        // 将 hash key 与 jQuery DOM 的关系储存
        // setHashData( flag, j_dom );
    }

    return flag;
}

/**
 * 将组件与 hash 的关系储存起来
 * 
 * @private
 * @method  setHashData
 * @param   {String} key
 * @param   {jQuery DOM} j_dom
 * @return
 */
function setHashData( key, j_dom ) {
    var setName = "associatedHashKey";
    var dataSet = $("body").data( setName );

    if ( $.isPlainObject( dataSet ) === false ) {
        dataSet = {};
    }

    if ( dataSet[key] === undefined ) {
        dataSet[key] = j_dom;

        $("body").data( setName, dataSet );
    }
}

/**
 * 通过 hash key 取出相关联的组件
 * 
 * @private
 * @method  getHashData
 * @param   {String} key
 * @return  {jQuery DOM}
 */
function getHashData( key ) {
    var j_dom = null;
    var setName = "associatedHashKey";
    var dataSet = $("body").data( setName );

    if ( $.isPlainObject( dataSet ) ) {
        j_dom = dataSet[key] || null;
    }

    return j_dom;
}

/**
 * Get data from internal storage.
 *
 * @private
 * @method  getStorageData
 * @param   ns_str {String}   Namespace string
 * @return  {String}
 */
function getStorageData( ns_str ) {
    var text = storage;

    $.each( ns_str.split("."), function( idx, part ) {
        return typeof( text = text[ part ] ) in { "string": true, "object": true };
    });

    return text;
}

$.extend( _P, {
  /**
   * 存储数据到内部/从内部获取数据
   */
  data: function() {
    var args = arguments;
    var length = args.length;
    var result;

    if ( length > 0 ) {
      var key = args[0];

      if ( typeof key === "string" && REG_NAMESPACE.test(key) ) {
        if ( length === 1 ) {
          result = getStorageData(key);
        }
        else if ( $.isPlainObject(args[1]) ) {
          if ( !storage.hasOwnProperty(key) ) {
            storage[key] = args[1];
          }
          else {
            $.extend(storage[key], args[1]);
          }

          result = args[1];
        }
      }
      else {
        $.each(args, function(i, n) {
          $.extend(storage, n);
        });
      }
    }

    return result || null;
  },

  /**
   * 自定义警告提示框
   *
   * @method  alert
   * @param   message {String}
   * @param   [callback] {Function}
   * @return  {Boolean}
   */
  alert: function( message, callback ) {
    return systemDialog("alert", message, callback);
  },

  /**
   * 自定义确认提示框（两个按钮）
   *
   * @method  confirm
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'OK' button
   * @param   [cancel] {Function}   Callback for 'CANCEL' button
   * @return  {Boolean}
   */
  confirm: function( message, ok, cancel ) {
    return systemDialog("confirm", message, ok, cancel);
  },

  /**
   * 自定义确认提示框（三个按钮）
   *
   * @method  confirmEX
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'YES' button
   * @param   [cancel] {Function}   Callback for 'NO' button
   * @return  {Boolean}
   */
  confirmEX: function( message, ok, cancel ) {
    return systemDialog("confirmEX", message, ok, cancel);
  },

  /**
   * Get current language
   *
   * @method  lang
   * @return  {String}
   */
  lang: function() {
    return ($("html").attr("lang") || navigator.language || navigator.browserLanguage).split("-")[0];
  },

  /**
   * Internationalization
   *
   * When the first argument is a plain object, is a setter.
   * When the first argument is a string, maybe a getter.
   *
   * @method  i18n
   * @return  {Object}
   */
  i18n: function() {
    var args = arguments;
    var data = args[0];
    var result = null;

    // Save i18n data at internal object.
    if ( $.isPlainObject( data ) ) {
      $.extend( storage.i18n, data );
    }
    // Get i18n text.
    else if ( typeof data === "string" && REG_NAMESPACE.test( data ) ) {
      var pairs = args[1];

      if ( $.isPlainObject( pairs ) ) {
        result = getStorageData( "i18n." + data );
        result = (typeof result === "string" ? result : "").replace( /\{%\s*([A-Z0-9_]+)\s*%\}/ig, function( text, key ) {
          return pairs[ key ];
        });
      }
      else {
        result = "";

        $.each( args, function( i, txt ) {
          if ( typeof txt === "string" && REG_NAMESPACE.test( txt ) ) {
            var r = getStorageData( "i18n." + txt );

            result += (typeof r === "string" ? r : "");
          }
        });
      }
    }

    return result;
  },

  /**
   * 帐号
   */
  account: function() {
    var self = this;
    var ls = window.localStorage;
    var rv = null;

    if ( ls && ls.setItem ) {
      var args = arguments;

      if ( args.length ) {
        // 存储指定帐号信息
        if ( $.isPlainObject(args[0]) ) {
          var info = args[0];

          rv = escape(JSON.stringify(info));

          ls.setItem(("account_" + info.email), rv);
        }
        // 批量存储帐号信息
        else if ( $.isArray(args[0]) ) {
          $.each( args[0], function( n ) {
            self.account( n );
          });
        }
        // 获取指定帐号
        else if ( typeof args[0] === "string" ) {
          rv = ls.getItem("account_" + args[0]);

          if ( rv !== null ) {
            rv = JSON.parse(unescape(rv));
          }
        }
      }
      // 获取列表
      else {
        rv = [];

        $.each( ls, function( i ) {
          var key = ls.key(i);

          if ( key.indexOf("account_") === 0 ) {
            rv.push( JSON.parse(unescape(ls.getItem(key))) );
          }
        });
      }
    }

    return rv;
  },

  /**
   * 获取用户信息
   */
  user: function( user_id, callback ) {
    var isAsync = $.isFunction(callback);
    var returnValue;

    $.ajax({
      url: "/users/user_info_json",
      data: {
          "user_id": user_id
        },
      async: isAsync,
      success: function( data ) {
        if ( isAsync ) {
          callback.call(window, data);
        }
        else {
          returnValue = data;
        }
      }
    });

    return returnValue;
  },

  /**
   * 系统提示
   *
   * @method  notification
   * @param   {String} message
   * @param   {String} type
   * @return
   */
  notification: function( message, type ) {
    var header = $(".layout-header");
    var headerExists = header.size() === 1;
    var headerHeight = header.outerHeight();
    var bread = $("#breadcrumb");
    var breadTop = parseInt(bread.css("padding-top"), 10);
    var block = $("#notification");
    var blockExists = block.size() === 1;
    var allowedState = ["success", "error"];

    if ( $.type(message) === "string" ) {
      if ( blockExists === false ) {
        if ( headerExists ) {
          header.after("<div id=\"notification\" style=\"top: " + headerHeight + "px;\"></div>");
        }
        else {
          $("body").prepend("<div id=\"notification\" style=\"top: 0;\"></div>");
        }
        
        block = $("#notification")
        blockExists = true;
      }

      block.html( message );

      if ( $.inArray(type, allowedState) > -1 ) {
        block.addClass(type);
      }

      if ( headerExists && parseInt(block.css("top"), 10) === 0 ) {
        block.css("top", (headerHeight + "px"));
      }
      else if ( parseFloat(block.css("top")) < 0 ) {
        block.css("top", "0");
      }
    }

    // 存在提示块时才执行代码
    if ( blockExists ) {
        var top = header.size() ? "0" : ("-" + block.outerHeight() + "px");

        bread.css("padding-top", (block.outerHeight() + breadTop) + "px");

        setTimeout(function() {
            bread.animate({ "padding-top": breadTop + "px" }, "normal");
            block.animate({ "top": top }, "normal", function() {
                // 移除提示块的状态 class
                $.each(allowedState, function( i, state ) {
                    block.removeClass( state );
                });
            });
        }, 3000);
    }
  },

  /**
   * 获取当前分页的页码
   * 
   * @method  page
   * @return  {Integer}
   */
  page: function() {
      var page = Number(parseHash()["p"]);

      return isNaN(page) ? 0 : page;
  },

  hash: parseHash,

  /**
   * 将（tab、pagination）组件的位置与 hash 关联
   * 
   * @method  associateHash
   * @param   {DOM} comp_unit
   * @param   {String} value
   * @return
   */
  associateHash: function( comp_unit, value ) {
      var j_dom = $(comp_unit);
      var attrKey = "data-flag";
      var selector;

      // Tab
      if ( j_dom.hasClass("comp_tab_trigger") ) {
          selector = ".comp_tab_wrapper";
      }
      // Pagination
      else if ( j_dom.attr("data-remote") !== undefined && j_dom.attr("data-page") !== undefined ) {
          selector = ".pagination";
      }

      if ( $.type(selector) === "string" ) {
          var wrp = j_dom.closest(selector);
          var flag = generateFlag(wrp, attrKey);

          // 更新容器标识
          wrp.attr( attrKey, flag );
          // 更新 hash
          updateHash( flag, value );
      }
  },

  /**
   * 激活与 hash key 相关联的组件单元
   * 
   * @method  activate
   * @param   {jQuery DOM} collection
   * @return
   */
  activate: function( collection ) {
      var hash = this.hash();

      $(collection).each(function() {
          var j_dom = $(this);
          var key = generateFlag( j_dom, "data-flag" );
          var flag = hash[key];
          var selector = "";
          var comp_unit = null;

          // Tab
          if ( j_dom.hasClass("comp_tab_wrapper") ) {
            selector = ".comp_tab_trigger";

            // 不设置默认 tab
            if ( j_dom.attr("data-setdefault") === "false" ) {
              return;
            }

            // 优先通过 hash 定位
            if ( flag !== undefined ) {
              comp_unit = $((selector + "[data-flag='" + flag + "']"), j_dom);

              if ( comp_unit.size() === 0 ) {
                comp_unit = null;
              }
            }

            if ( comp_unit === null ) {
              comp_unit = $((selector + ".current"), j_dom);

              if ( comp_unit.size() === 0 ) {
                comp_unit = $((selector + ":first"), j_dom);
              }
            }
          }
          // Pagination
          else if ( j_dom.hasClass("pagination") ) {
              if ( $.isNumeric(flag) && flag !== "1" ) {
                  var lastPage = $("[data-remote][data-page]:not(.next_page .last_page):last-child", j_dom);

                  flag *= 1;

                  // 在页码范围内
                  if ( flag > 0 && flag <= lastPage.attr("data-page") * 1 ) {
                      var url = lastPage.attr( "href" ).replace(/\&page=\d+/, function() { return "&page=" + flag; });

                      comp_unit = lastPage.clone();

                      comp_unit.hide().attr({"href": url, "data-page": flag}).appendTo( j_dom );
                  }
              }
          }

          if ( comp_unit !== null ) {
              comp_unit.click();
          }
      });
  },

  /**
   * 返回到顶部
   */
  top: function() {
    if ( $(".comp_return").size() === 0 ) {
      var text = this.i18n("w.v.backtotop");
      var btn = $("<button class=\"comp_return hidden\" type=\"button\" />");

      btn.text(text).appendTo($("body"));

      btn.click(function() {
        if ( document.body.scrollTop ) {
          $("body").animate({scrollTop: 0});
        }
        else if ( document.documentElement.scrollTop ) {
          $("html").animate({scrollTop: 0});
        }

        return false;
      });

      $(window).scroll(function(e) {
        if ( (document.body.scrollTop || document.documentElement.scrollTop) > 200 ) {
          btn.removeClass("hidden");
        }
        else {
          btn.addClass("hidden");
        }
      });
    }
  },

  /**
   * 构造接收人列表所需要的树结构 HTML
   *
   * @method  constructStudents
   * @param   {Array} data
   * @return  {String}
   */
  DL_StudentListHTML: function( data ) {
    var _inst = this,
        htmlObj = {},
        html = [];

    // 班级信息
    $.each( data, function( idx, receiver ) {
        var grade = receiver.class_grade,
            name = grade.name;

        if ( htmlObj[name] === undefined ) {
            htmlObj[name] = { info: grade, students: [] };
        }

        htmlObj[name].students.push( _inst.DL_StudentItemHTML({ "value": receiver.id, "text": receiver.name, "avatar": receiver.avatar }) + "</li>" );
    });

    // 拼装 HTML
    $.each( htmlObj, function( name, grade ) {
        var hasStudents = grade.students.length > 0;

        html.push( _inst.DL_StudentItemHTML({ "value": grade.info.id, "text": name }, hasStudents ) );

        if ( hasStudents ) {
            html.push("<ul class=\"DL-tree\" data-level=\"2\" data-tree=\"" + DoubleList.unique("tree") + "\">");
            html.push( grade.students.join("") );
            html.push("</ul>");
        }

        html.push("</li>");
    });

    return html.join("");
  },

  /**
   * 构建学生双列表中的树节点
   * 
   * @method  constructTreeNode
   * @param   {JSON} data
   * @param   {Boolean} hasChildren
   * @return  {String}
   */
  DL_StudentItemHTML: function( data, hasChildren ) {
      var node = [];

      node.push("<li");

      if ( data.avatar === undefined ) {
          node.push(" class=\"DL-expanded" + (hasChildren ? " DL-haschildren" : "") + "\"");
      }
      // 加上学生的标记
      else {
          node.push(" data-flag=\"student\"");
      }

      node.push(" data-node=\"" + DoubleList.unique("node") + "\" data-value=\"" + data.value + "\"><div class=\"DL-node\">");

      // 班级
      if ( data.avatar === undefined ) {
          node.push("<i class=\"DL-trigger\">trigger</i>");
      }
      // 学生
      else {
          node.push("<img src=\"" + data.avatar + "\" class=\"avatar_16 DL-avatar\" alt=\"" + data.text + "\">");
      }

      node.push("<span>" + data.text + "</span></div>");

      return node.join("");
  },

  /**
   * 计算 ul、ol 列表条目的行及列
   *
   * @method  calculateRowsColumns
   * @return
   */
  calculateRowsColumns: function() {
    $("[data-column-count]").each(function() {
      var list, items, itemSize, count, row;

      if ( $(this).data("calculated") !== true && this.nodeName.toLowerCase() in { "ol": true, "ul": true } ) {
        list = $(this);
        count = list.attr("data-column-count");

        if ( $.isNumeric(count) ) {
          items = list.children("li");
          itemSize = items.size();
          count *= 1;
          row = Math.ceil(itemSize/count);

          items.each(function( idx ) {
            var item = $(this);

            if ( idx < count ) {
              item.addClass("first-row");
            }

            if ( Math.ceil((idx + 1)/count) === row ) {
              item.addClass("last-row");
            }

            if ( (idx + 1) % count === 1 ) {
              item.addClass("first");
            }

            if ( row === 1 ) {
              if ( idx === itemSize - 1 ) {
                item.addClass("last");
              }
            }
            else {
              if ( (idx + 1) % count === 0 ) {
                item.addClass("last");
              }
            }
          });

          list.data("calculated", true);
        }
      }
    });
  },

  /**
   * 计算时间段
   * 
   * @method  timePeriod
   * @return
   */
  timePeriod: function() {
    var lib = this;

    $("[data-timediff]").each(function() {
      var ele = $(this);
      var baseMin = 60;
      var baseHour = 60 * baseMin;
      var baseDay = 24 * baseHour;
      var timeDiff = ele.attr("data-timediff") * 1;
      var timeWarn = ele.attr("data-timewarn") * 1;
      var time;
      var unit;
      var text;
      var isWarn;

      if ( ele.data("has_calculated") !== true ) {
        if ( timeDiff < 0 ) {
          text = lib.i18n( "w.adj.expired" );
        }
        else {
          if ( $.isNumeric(timeWarn) ) {
            isWarn = timeDiff <= timeWarn;
          }

          if ( timeDiff >= baseDay ) {
            time = Math.floor(timeDiff/baseDay);
            unit = lib.i18n( "w.n.day" );
          }
          else if ( timeDiff >= baseHour ) {
            time = Math.floor(timeDiff/baseHour);
            unit = lib.i18n( "w.n.hour" );
          }
          else if ( timeDiff >= baseMin ) {
            time = Math.floor(timeDiff/baseMin);
            unit = lib.i18n( "w.n.minute" );
          }
          else {
            time = timeDiff;
            unit = lib.i18n( "w.n.second" );
          }

          text = CM.i18n(("p.message.time_" + (ele.attr("data-timetype") || "left")), { time: time, unit: unit.toLowerCase() });

          if ( ele.hasClass("label") ) {
            var labelClass;

            if ( isWarn === undefined || isWarn === true ) {
              labelClass = "label-warning";
            }
            else if ( isWarn === false ) {
              labelClass = "label-info";
            }

            if ( labelClass !== undefined ) {
              ele.addClass( labelClass );
            }
          }
        }

        ele.html( text ).data("has_calculated", true);

        if ( ele.hasClass("transparent") ) {
          ele.animate({opacity: 1}, "fast", function() {
            ele.removeClass("transparent");
          });
        }
      }
    });
  },

  /**
   * 批量处理文字省略
   *
   * @method dotx3
   * @return
   */
  dotx3: function() {
      $("[data-ellipsis='true']").each(function() {
          var p = $(this),
              p_h = p.attr("data-dot-height"),
              p_t = p.attr("data-dot-text-expand"),
              p_t_c = p.attr("data-dot-text-collapse"),
              p_href = p.attr("data-dot-href");

          if ( p.data("has_ellipsis") !== true ) {
              if ( $.isNumeric(p_h) ) {
                  p.height(p_h);
              }

              p.wrap("<div class=\"ellipsis-wrapper\" />");

              p.dotdotdot({
                  wrap: "letter",
                  callback: function( isTruncated, orgContent ) {
                      var _p = $(this),
                          link, text;

                      if ( p_t ) {
                          text = _p.text();

                          _p.empty().append("<span>" + text + "</span>")
                          _p.after("<a class=\"ellipsis-read-more fr\" href=\"javascript:void(0);\">" + p_t + "</a>");

                          link = _p.siblings(".ellipsis-read-more");

                          if ( p_href ) {
                              link.attr("href", p_href);
                          }
                          else {
                              link.data("orgContent", orgContent.text());
                              link.data("newContent", $("span", _p).text());

                              link.click(function() {
                                  var l = $(this),
                                      pp = l.siblings("[data-ellipsis]"),
                                      s = pp.find("span"),
                                      attr = "data-dot-expanded";

                                  if ( pp.attr(attr) ) {
                                      s.text(l.data("newContent"));
                                      pp.removeAttr(attr).height(pp.attr("data-dot-height"));
                                      l.text(p_t);
                                  }
                                  else {
                                      s.text(l.data("orgContent"));
                                      pp.attr(attr, "true").css("height", "auto");
                                      l.text(p_t_c);
                                  }

                                  return false;
                              });
                          }
                      }
                  }
              });

              p.data("has_ellipsis", true);
          }
      });
  },

  grades: function( campus, callback ) {
      if ( $.isFunction( callback ) ) {
          $.get(
              "/admin/class_grades/grade_json_list.json",
              { "campus_id": campus },
              function( data ) {
                  callback( data );
              }
          );
      }
  }
});

window.CM = _P;

})( window, window.jQuery );
