package flow;

enum FlowResult<T> {
  Some(data: T);
  Error(s: String);
}

class FlowTransformerStatefull<TSrc, TDst> {

  public function new() {}

  public function exec(s: TSrc): FlowResult<TDst> {
    return null;
  }
}

typedef FlowTransformerLambda<TSrc, TDst> = TSrc -> FlowResult<TDst>;

abstract FlowResultNow<T>(FlowResult<T>) from FlowResult<T> to FlowResult<T> {
  public inline function new(c:FlowResult<T>) {
    this = c;
  }

  @:op(A >= B)
  static public function executor<T, TDst>(O1: FlowResultNow<T>, O2: FlowTransformerStatefull<T, TDst>): FlowResultNow<TDst> {
    switch O1 {
      case Some(v): return new FlowResultNow(O2.exec(v));
      case Error(s): return new FlowResultNow(Error(s));
    }
  }

  @:op(A >= B)
  static public function execLambda<T, TDst>(O1: FlowResultNow<T>, O2: FlowTransformerLambda<T, TDst>): FlowResultNow<TDst> {
    switch O1 {
      case Some(v): return new FlowResultNow(O2(v));
      case Error(s): return new FlowResultNow(Error(s));
    }
  }
}

typedef FlowResultFunctor<T> = Void -> FlowResult<T>;

 abstract FlowResultLazy<TDst>(FlowResultFunctor<TDst>) from FlowResultFunctor<TDst> to FlowResultFunctor<TDst> {
   public inline function new(c: FlowResultFunctor<TDst>) {
     this = c;
   }

   @:op(A >= B)
   static public function executor<TDst, TAdd>(me: FlowResultLazy<TDst>, f: FlowTransformerLambda<TDst, TAdd>): FlowResultLazy<TAdd> {
     return new FlowResultLazy<TAdd>(
        function() {
          var mel: FlowResultFunctor<TDst> = me;
          var res = mel();
          switch res {
            case Some(v): return f(v);
            case Error(s): return Error(s);
          }
        }
     );
   }

   public function exec() {
     return this();
   }
 }

 class Flow {
   public static function lazy<T>(t: T): FlowResultLazy<T> {
     return new FlowResultLazy<T>(function() { return Some(t);});
   }

   public static function now<T>(t: T): FlowResultNow<T> {
     return new FlowResultNow<T>(Some(t));
   }

   public static function trace<T>(?desc: Dynamic): FlowTransformerLambda<T, T>{
     return function(t) {
       if(desc != null)
        trace(desc);
       trace(t);
       return Some(t);
     }
   }
 }
