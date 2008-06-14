open Common

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(* 
 * This file is named gCommon.ml to be coherent with the other lalbgtk files.
 *)

(*****************************************************************************)
(* Widgets composition *)
(*****************************************************************************)

(* 
 * I want to compose widgets easily. I want to have a declarative way to 
 * build the gui, a way where the code looks like the interface :) like
 * a calligramme (cf http://fr.wikipedia.org/wiki/Calligramme).
 * 
 * So I want ideally do do things like 
 *    (build_vbox
 *      [build_menu
 *         build_item "File" callback:(fun () -> some_action);
 *         build_item "Close"  callback:(fun () -> some_other_action);
 *      ]
 *     ....
 * 
 * so that the imbrication, the nestedness of the code corresponds visually
 * to the imbrication of the widgets. Note that sometimes we need
 * from one widget to call some methods on other widgets, so in those
 * case it requires to at least name with a let some intermediate widgets.
 * 
 * 
 * The mk functions below are one attempt to allow this easy composition
 * of widgets. With those functions one can write:
 * 
 * w#add (GCommon.mk (GPack.vbox ~border_width:1 ~spacing:1) (fun vbox -> 
 *   vbox#pack (GCommon.mk (GMenu.menu_bar) (fun m -> 
 *     m#pack    (CCommon.mk (GButton.button) (fun but -> 
 *       do_stuff();
 *     ));
 *   ));
 * ));
 * 
 * instead of the more verbose and more space taking:
 * w#add (
 *   let vbox = GPack.vbox ... in
 *   vbox#add (
 *     let m = Gmenu.menu_bar ... in
 *     m#pack (
 *        let but = GButton.button ... in
 *        do_stuff();
 *        buf#coerce
 *     );
 *     m#coerce;
 *   );
 *   vbox#coerce;
 *  );
 * 
 * or instead of the even more verbose, flat, and so not very clear style
 * described in the lablgtk2 tutorial.
 * 
 * 
 * I could go even further, and as I ideally described before have
 * some  (build_vbox [widget1 ...; widget2 ...;]). But
 * sometimes we want to say that some of the widgets in the vbox must
 * fill the space, must expand, etc, so it would require at least
 * to have inside the list a pair with a specifier and the widget, which
 * gets more complicated. So it's easier to just use the multiple but flexible
 * manual calls to vbox#add. Furthermore it's not very easy to define
 * wrapper over the lablgtk functions because many of them use default
 * parameters and types and wrappers get easily screwed by this.
 * 
 * Nevertheless for some widgets there is very few need for flexibility,
 * because for instance they are just wrappers around one widget, as for
 * viewports, or frames, or are just vbox without parameters, such 
 * as the vpanes and hpanes. In those case I defined some wrappers
 * over lablgtk which are more convienent. Cf the with_xxx below in this file.
 * 
 * 
 * For example of uses, look at one of my gui.ml
 *)


let mk widget f = 
  let widget = widget () in
  f widget;
  widget#coerce 

let mk2 widget f = 
  let widget = widget () in
  f widget;
  widget

(* obsolete ? cos now use of factory is quite short:
 * compare
 *   factory#add_submenu "_Edit" +> (fun menu -> 
 * and
 *   m#add (G.mk_menu (G.menu_item ~label:"_Edit") (fun menu -> 
 *)
let mk_menu menu_item f = 
  let menu_item = menu_item () in
  let menu = GMenu.menu ~packing:menu_item#set_submenu () in
  f menu;
  menu_item


(*---------------------------------------------------------------------------*)

(* Functions to have even more concise style. Can then write 
 *  w +> GCommon.add (GMenu.toolbar) (fun tb -> ...
 *  );
 * 
 * to work, to not having typing pb, you need to specify the same
 * default parameter when you define wrapper.
 *)
let add widget f w = 
  let widget = widget () in
  f widget;
  w#add widget#coerce

let pack ?from ?expand ?fill ?padding = fun widget f w ->
  let widget = widget () in
  f widget;
  w#pack ?from ?expand ?fill ?padding widget#coerce


let add_menu menu_item f w = 
  let menu_item = menu_item () in
  let menu = GMenu.menu ~packing:menu_item#set_submenu () in
  f menu;
  w#add menu_item



(*****************************************************************************)
(* Widget wrappers *)
(*****************************************************************************)

(* Those functions allow to encapsulate some widgets with other one without
 * the need to name those widgets.
 *)
let with_frame widget = 
  let frame = GBin.frame  (*~width:100*) () in
  frame#add widget#coerce;
  frame#coerce


let with_label text widget = 
  let box =  GPack.hbox () in
  let lbl =  GMisc.label ~text () in
  box#add lbl#coerce;
  box#add (* ~expand:true ~fill:true *) widget;
  box#coerce

(* this one works better than viewport2, because when change the selection
 * with keyboard in a clist for instance, then this scolled window will
 * follow automatically whereas viewport2 will not by default.
 *)
let with_viewport widget = 
  let scrw = GBin.scrolled_window ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC ()
  in
  scrw#add widget;
  scrw#coerce

(* apparently to use with widget without scrolling/adjusment built-in 
 * facility *)
let with_viewport2 widget = 
  let scrw = GBin.scrolled_window ~hpolicy: `AUTOMATIC ~vpolicy: `AUTOMATIC ()
  in
  scrw#add_with_viewport widget;
  scrw#coerce


(*****************************************************************************)
(* Composite widgets *)
(*****************************************************************************)
let rec paneds orientation xs = 
  match xs with
  | [] | [_] -> failwith "paneds: need at least 2 elements"
  | [x;y] -> 
      let hp = GPack.paned orientation () in
      hp#add1 x;
      hp#add2 y;
      hp#coerce
  | x::xs -> 
      let hp = GPack.paned orientation () in
      hp#add1 x;
      hp#add2 (paneds orientation xs);
      hp#coerce

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(* used by completion entry code *)
let model_of_list conv l =
  let cols = new GTree.column_list in
  let column = cols#add conv in
  let model = GTree.list_store cols in
  List.iter
    (fun data ->
      let row = model#append () in
      model#set ~row ~column data)
    l ;
  (model, column)



(*****************************************************************************)
(* Keyboards/Mouse *)
(*****************************************************************************)

let pos_of_ev ev = 
  let x = int_of_float (GdkEvent.Button.x ev) in
  let y = int_of_float (GdkEvent.Button.y ev) in
  x,y


let entry_with_completion ~text ~completion = 
  let entry = GEdit.entry ~text () in
  let (model, col) = 
    model_of_list Gobject.Data.string completion in
  let c = GEdit.entry_completion ~model ~entry () in
  c#set_text_column col;
  entry



(*****************************************************************************)
(* CList widget Helpers *)
(*****************************************************************************)
let freeze_thaw f l = 
  begin
    l#freeze ();
    f();
    l#thaw ();
  end

let clist_connect ~callback:f (widget : string GList.clist) = 
  begin
    widget#connect#select_row ~callback:(fun ~row ~column ~event -> 
      let s = widget#cell_text row 0 in
      
      (match widget#row_is_visible row with
      | `FULL -> 
          pr2 "full";
      | _ -> 
          pr2 "here";
          widget#moveto row column;

      );

      f (Some s);
    );


    widget#connect#unselect_row ~callback:(fun ~row ~column ~event ->
      f None
    );
  end

let clist_update xs widget = 
  widget +> freeze_thaw (fun () ->
    widget#clear ();
    xs +> List.iter (fun dir -> 
      widget#append [dir;] +> ignore;
    );
  )

let clist_update_multicol xs widget = 
  widget +> freeze_thaw (fun () ->
    widget#clear ();
    xs +> List.iter (fun props -> 
      widget#append props +> ignore;
    );
  )


(*****************************************************************************)
(* GTree (model based) widget helpers *)
(*****************************************************************************)

(* todo? the manual say that should also disable the sorting of the view to
 * be even faster *)
let model_modif f view = 
  let model = view#model in 
  view#set_model None;
  f model;
  view#set_model (Some model);
  ()

let sort_col column (model : #GTree.model) it_a it_b =
  let a = model#get ~row:it_a ~column in
  let b = model#get ~row:it_b ~column in
  compare a b
(* (String.length a) (String.length b) *)




let view_column ~title ~renderer ()  = 
  let col = GTree.view_column ~title ~renderer () in
  col#set_resizable true;
  col




(*****************************************************************************)
(* Menu *)
(*****************************************************************************)

let menu_item ~label = 
  GMenu.menu_item  ~use_mnemonic:true ~label


let mk_right_click_menu_on_store view fpath = 

  let popup_menu path ev = 
    let menu = GMenu.menu () in
    GToolbox.build_menu menu ~entries:(fpath path);
    menu#popup 
      ~button:(GdkEvent.Button.button ev) ~time:(GdkEvent.Button.time ev);
  in
    
  (* right click *)
  view#event#connect#button_press ~callback:(fun ev -> 
    if GdkEvent.Button.button ev = 3 then begin
      pr2 "Right click";
      let (x,y) = pos_of_ev ev in
      (match view#get_path_at_pos ~x ~y with
      | Some (path, _,_,_) -> 
          popup_menu path ev;
          true
      | None -> false
      )
    end
    else false (* not a right click *)
  )


(*****************************************************************************)
(* Dialogs *)
(*****************************************************************************)
let dialog_text ~text ~title =
  let dialog = GWindow.dialog ~modal:true ~border_width:1 ~title () in
  let _label  = GMisc.label    ~text     ~packing:dialog#vbox#add () in
  let dquit  = GButton.button ~label:"Close" ~packing:dialog#vbox#add () in 
  begin
    dquit#connect#clicked ~callback: (fun _ -> dialog#destroy ());
    dialog#show ();
  end

let todo_gui () = 
  dialog_text ~text:"This feature has not yet been implemented
but I encourage you to implement it yourself
as there is very few chances that I do it one day" 
              ~title: "TODO" 



(* Taken from uigtk2.ml from unison. Quite hard to communicate info between
 * windows. I tried stuff but it does not work. 
 * update: look also at dialog_ask_filename, use a different mechanism.
 *)
let dialog_ask_with_y_or_no_bis ~text ~title callerw = 
  let w = GWindow.dialog ~modal:true ~border_width:1 ~title () in
  let entry = GEdit.entry ~text:"" ~editable:true () in

  w#add_button_stock `YES `YES;
  w#add_button_stock `NO `NO;

  w#set_default_response `NO;

  w#vbox#pack (with_label text entry#coerce);

  w#set_transient_for (callerw#as_window);
  callerw#misc#set_sensitive false;

  w#show ();
  let res = w#run () in
  let text = entry#text in 

  w#destroy();
  callerw#misc#set_sensitive true;

  (match res with
  | `YES -> Some text
  | `NO | `DELETE_EVENT -> None
  )





(* Note that polymorphism and inference works very well here.
 * The 'answer' can be of any type.
 *)
let dialog_ask_generic_bis ~title callerw fbuild fget_val  = 
  let w = GWindow.dialog ~modal:true ~border_width:1 ~title () in

  w#add_button_stock `YES `YES;
  w#add_button_stock `NO `NO;

  w#set_default_response `YES;

  (* oldsimple:
      let entry = GEdit.entry ~text:"" ~editable:true () in
      w#vbox#pack (with_label text entry#coerce); 
  *)
  fbuild w#vbox;
  
  w#set_transient_for (callerw#as_window);
  callerw#misc#set_sensitive false;

  w#show ();
  let res = w#run () in

  (* oldsimple:
      let text = entry#text in 
  *)
  let answer = fget_val () in

  w#destroy();
  callerw#misc#set_sensitive true;

  (match res with
  | `YES -> Some answer
  | `NO | `DELETE_EVENT -> None
  )



(* no need to callerw. src: cameleon ? *)
let dialog_ask_generic ~title fbuild fget_val  = 
  let res = ref None in

  let w = GWindow.dialog ~modal:true ~border_width:1 ~title () in
  w#connect#destroy ~callback: GMain.Main.quit;

  let ok_button = GButton.button ~stock: `YES ()in
  let no_button = GButton.button ~stock: `NO () in
  let hbox = GPack.hbox () in
  hbox#pack ~fill:true ok_button#coerce;
  hbox#pack ~fill:true no_button#coerce;

  fbuild w#vbox;

  w#vbox#pack ~fill:true hbox#coerce;

  ok_button#connect#clicked ~callback:(fun () -> 
    res := Some (fget_val ());
    w#destroy ()
  );
  no_button#connect#clicked ~callback:(fun () -> 
    res := None;
    w#destroy ();
  );

  w#event#connect#key_press ~callback:(fun ev -> 
    let k = GdkEvent.Key.keyval ev in
    if GdkKeysyms._Return = k then begin (* enter = 65293 *)
      res := Some (fget_val ());
      w#destroy ();
      true
    end
    else begin 
      (* pr2 (i_to_s k); *)
      false
    end 
  );


  w#show ();
  GMain.Main.main ();
  !res



let dialog_ask_with_y_or_no ~text ~title  = 
  let entry = GEdit.entry ~text:"" ~editable:true () in
  dialog_ask_generic ~title 
    (fun vbox -> 
      vbox#pack (with_label text entry#coerce); 
    )
    (fun () -> 
      let text = entry#text in 
      text
    )

let dialog_ask_y_or_no ~text ~title  = 
  let lbl =  GMisc.label ~text () in
  let res = 
    dialog_ask_generic ~title 
      (fun vbox -> 
        vbox#pack (lbl#coerce); 
      )
      (fun () -> 
        ()
      )
  in
  match res with
  | Some () -> true
  | None -> false



let dialog_ask_filename ~title ~filename = 

  let (res: filename option ref) = ref None in

  let filew = GWindow.file_selection ~title ~filename ~modal:true () in
  filew#connect#destroy ~callback: GMain.Main.quit;

  filew#ok_button#connect#clicked ~callback:(fun () -> 
    res := Some (filew#filename);
    filew#destroy ()
  );
  filew#cancel_button#connect#clicked ~callback:(fun () -> 
    res := None;
    filew#destroy ();
  );
  filew#show ();
  GMain.Main.main ();
  !res

(*****************************************************************************)
(* Main widget and loop *)
(*****************************************************************************)
  
let mk_gui_main ~title ?(width=800) ?(height=600) f = 
  GtkMain.Main.init();
  let w = GWindow.window ~title ~width ~height () in

  w#event#connect#delete ~callback:(fun _ -> GMain.Main.quit (); true);
  w#connect#destroy      ~callback:          GMain.Main.quit;

  f w;
  (*
  w#event#connect#key_press ~callback:(fun ev -> 
    let k = GdkEvent.Key.keyval ev in
    if Char.code 'q' = k then begin
      quit();
      true
    end
    else begin 
      false
    end
  );
  *)

  w#show ();
  GMain.Main.main ()


(*****************************************************************************)
(* Misc *)
(*****************************************************************************)
let create_menu m label =
  let item = GMenu.menu_item ~label ~packing:m#append () in
  GMenu.menu ~packing:item#set_submenu ()


(* dumb widget *)
(* (G.mk (GMisc.label ~text:"other") (fun x -> ())); *)
