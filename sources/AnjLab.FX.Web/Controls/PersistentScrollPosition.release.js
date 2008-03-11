﻿Type.registerNamespace('AnjLab.FX.Web.Controls'); AnjLab.FX.Web.Controls.PersistentScrollPosition = function(element) { AnjLab.FX.Web.Controls.PersistentScrollPosition.initializeBase(this, [element]); this._scrollDelegate = null; this._endRequestDelegate = null; this._storage = null;}
AnjLab.FX.Web.Controls.PersistentScrollPosition.prototype = { _getScrollPosition : function() { var el = this.get_element(); if (el) { return { x: el.scrollLeft || 0, y: el.scrollTop || 0
};}
}, get_storage : function() { return this._storage;}, set_storage : function(value) { this._storage = value;}, initialize : function() { AnjLab.FX.Web.Controls.PersistentScrollPosition.callBaseMethod(this, 'initialize'); this._scrollDelegate = Function.createDelegate(this, this._onScroll); this._endRequestDelegate = Function.createDelegate(this, this._onEndRequest); var prm = Sys.WebForms.PageRequestManager.getInstance(); prm.add_endRequest(this._endRequestDelegate); $addHandler(this.get_element(), 'scroll', this._scrollDelegate);}, dispose : function() { AnjLab.FX.Web.Controls.PersistentScrollPosition.callBaseMethod(this, 'dispose'); var prm = Sys.WebForms.PageRequestManager.getInstance(); prm.remove_endRequest(this._endRequestDelegate); delete this._endRequestDelegate; delete this._scrollDelegate;}, _onScroll : function(e) { this._storage.value = Sys.Serialization.JavaScriptSerializer.serialize(this._getScrollPosition());}, _onEndRequest : function(sender, args) { var o = null; if(this._storage.value !== '')
o = Sys.Serialization.JavaScriptSerializer.deserialize(this._storage.value); if (o) { var el = this.get_element(); el.scrollLeft = o.x; el.scrollTop = o.y; this._storage.value = '';}
}
}
AnjLab.FX.Web.Controls.PersistentScrollPosition.registerClass('AnjLab.FX.Web.Controls.PersistentScrollPosition', Sys.UI.Behavior); if(typeof(Sys) !== 'undefined')
Sys.Application.notifyScriptLoaded(); 