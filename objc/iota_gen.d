module objc.iota_gen;
import objc.meta;
import objc.runtime;
import metal;

import  cocoa.foundation,
	cocoa.nsapplication,
	cocoa.nscursor,
	cocoa.gamecontroller,
	cocoa.nsdate,
	cocoa.nsevent,
	cocoa.nsopengl,
	cocoa.nsscreen,
	cocoa.nstextinput,
	cocoa.nsview,
	cocoa.nsmenu,
	cocoa.nsnotification,
	cocoa.nsappdelegate,
	cocoa.nswindow;

mixin ObjcLinkModule!(metal);
mixin ObjcLinkModule!(cocoa.foundation);
mixin ObjcLinkModule!(cocoa.nsapplication);
mixin ObjcLinkModule!(cocoa.nscursor);
mixin ObjcLinkModule!(cocoa.nsdate);
mixin ObjcLinkModule!(cocoa.gamecontroller);
mixin ObjcLinkModule!(cocoa.nsevent);
mixin ObjcLinkModule!(cocoa.nsopengl);
mixin ObjcLinkModule!(cocoa.nsscreen);
mixin ObjcLinkModule!(cocoa.nstextinput);
mixin ObjcLinkModule!(cocoa.nsview);
mixin ObjcLinkModule!(cocoa.nsmenu);
mixin ObjcLinkModule!(cocoa.nsnotification);
mixin ObjcLinkModule!(cocoa.nsappdelegate);
mixin ObjcLinkModule!(cocoa.nswindow);
mixin ObjcInitSelectors!(__traits(parent, {}));
