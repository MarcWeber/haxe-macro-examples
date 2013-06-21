import haxe.macro.Expr;
import haxe.macro.Context;


/* while its possible to have the macro class in the same file
   it might be best to have the code separate */
class MacroHelperClass {

  // Example 1) very simple expr. However this already depends on
  //            impure input "current time" provided by the computer compiling
  //            this code
  macro static public function example_1_compilation_time():Expr {
    var now_str = Date.now().toString();
    // an "ExprDef" is just a piece of a syntax tree. Something the compiler
    // creates itself while parsing an a .hx file
    return {expr: EConst(CString(now_str)) , pos : Context.currentPos()};
  }

  // Example 2) Introducing reification.
  //            This means: make haxe create most of the expr, and inject only
  //            the piece depending on some variable input (such as time,
  //            filesysteem, database, ...)
  macro static public function example_2_read_license_file():Expr {
    // I don't expect you to have a license file, so let's even create it if it
    // does not exist yet:
    if (!sys.FileSystem.exists('license.txt'))
      sys.io.File.saveContent("license.txt", "LICENSE: Whatever license haxe.org manual has");

    var now_str = sys.io.File.getContent("license.txt");

    // var result = Context.makeExpr(now_str, Context.currentPos());
    // shorter writing:
    var result = macro $v{now_str}; // haxe 3.0: $v(now_str);

    // Example 3) how to debug expressions
    // trace(result); // have a look at the syntax tree haxe has created using the macro keyword
    // sometimes trace fails, throw seems to work always
    // tinkerbell even provides a 'expr to haxe code' feature:
    // tink.macro.tools.Printer.print(result);
    return result;
  }


  // Example 4) All ways to use reification:
  macro static public function example_4_all_reifications():Expr {
    var s:String = "a string";
    var string_expr: Expr = {expr: EConst(CString("contents of a string")) , pos : Context.currentPos()};

    var var_name: String = "a_var";

    var field_name = "str";

    // sometimes just  parsing an expression is most simple:
    var parsed_expr: Expr = Context.parse("3 * 4 -8", Context.currentPos());

    var list_of_expressions = [macro 1, macro 2];
    // alternative:
    // var value_1 = 1;
    // var value_2 = 2;
    // list_of_expressions = [ ${value_1}, ${value_2} ];

    return macro {
      // the following lines are turned into an abstract syntax tree,
      // then compiled by haxe. the resulting code will be run when the
      // application is run. Thus the following trace will not show anything
      // when compiling. This is because everything is in a block behind the
      // macro keyword.
      var $var_name = { 
        str: $v{s}, // turn value into an expr, (same as Context.makeExpr)
        str2: ${string_expr}, // inject an expr
        parsed_expr: ${parsed_expr},
        a_list: $a{list_of_expressions}
      }
      
      // if you read the tracing lines when running the code, pay attention to
      // the code lacation, which is not where the code gets injected (main func),
      // but here (where the expr is parsed!
      trace("tracing a_var "+a_var);
      trace("tarcing a_var.str: "+$i{var_name}.$field_name);

      // this is the result of this block (without return. I don't feel Haxe
      // language is consistent here)
      a_var;

      // haxe 3.0 notes:
      // The manual also has an example about 
      //   macro { $field_name: value }, which doesn't work in haxe 3.1?

      // ${} was $()
      // $v{} was $e()
      // $p{path} ?
    }
  }

}

class Macro {

  static function main() {
    var header = function(s){ neko.Lib.print('\n===> ${s}\n'); };

    header("starting");

    header("Example 1");
    // this "example_1_compilation_time()" look like a usual method call.
    // However because the method was annotated by @:macro or macro it will be
    // run at compilation time as soon as haxe sees it
    trace(MacroHelperClass.example_1_compilation_time());

    header("Example 2/3");
    // this embeds the license text as string in the source code.
    trace("license: " + MacroHelperClass.example_2_read_license_file());

    header("Example 4) all ways to use reification");
    trace("all reifications" + MacroHelperClass.example_4_all_reifications());

    header("done");
  }

}
