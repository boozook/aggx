package lib.ha.aggx.vectorial;
//=======================================================================================================
import lib.ha.core.memory.Ref;
//=======================================================================================================
class QuadCurve implements IVertexSource
{
	public static var CURVE_INC = 0;
	public static var CURVE_DIV = 1;
	//---------------------------------------------------------------------------------------------------
	private var _curveInc:QuadCurveFitterInc;
	private var _curveDiv:QuadCurveFitterDiv;
	private var _approximationMethod:Int;
	//---------------------------------------------------------------------------------------------------
	public function new(?x1:Float, ?y1:Float, ?x2:Float, ?y2:Float, ?x3:Float, ?y3:Float, am:Int = 1)
	{
		_approximationMethod = am;
		if (x1 != null && y1 != null && x2 != null && y2 != null && x3 != null && y3 != null)		
		{
			init(x1, y1, x2, y2, x3, y3);
		}
		_curveDiv = new QuadCurveFitterDiv();
		_curveInc = new QuadCurveFitterInc();
	}
	//---------------------------------------------------------------------------------------------------
	private inline function get_approximationScale():Float { return _curveInc.approximationScale; }
	private inline function set_approximationScale(value:Float):Float
	{
		_curveInc.approximationScale = value;
		_curveDiv.approximationScale = value;
		return value;
	}
	public inline var approximationScale(get_approximationScale, set_approximationScale):Float;	
	//---------------------------------------------------------------------------------------------------
	private inline function get_approximationMethod():Int { return _approximationMethod; }
	private inline function set_approximationMethod(value:Int):Int { return _approximationMethod = value; }
	public inline var approximationMethod(get_approximationMethod, set_approximationMethod):Int;
	//---------------------------------------------------------------------------------------------------	
	private inline function get_angleTolerance():Float { return _curveDiv.angleTolerance; }
	private inline function set_angleTolerance(value:Float):Float { return _curveDiv.angleTolerance = value; }
	public inline var angleTolerance(get_angleTolerance, set_angleTolerance):Float;
	//---------------------------------------------------------------------------------------------------
	private inline function get_cuspLimit():Float { return _curveDiv.cuspLimit; }
	private inline function set_cuspLimit(value:Float):Float { return _curveDiv.cuspLimit = value; }
	public inline var cuspLimit(get_cuspLimit, set_cuspLimit):Float;		
	//---------------------------------------------------------------------------------------------------
	public function reset():Void
	{ 
		_curveInc.reset();
		_curveDiv.reset();
	}		
	//---------------------------------------------------------------------------------------------------
	public function init(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float):Void
	{
		if(_approximationMethod == CURVE_INC)
		{
			_curveInc.init(x1, y1, x2, y2, x3, y3);
		}
		else
		{
			_curveDiv.init(x1, y1, x2, y2, x3, y3);
		}
	}	
	//---------------------------------------------------------------------------------------------------
	public function rewind(pathId:UInt)
	{
		if(_approximationMethod == CURVE_INC)
		{
			_curveInc.rewind(pathId);
		}
		else
		{
			_curveDiv.rewind(pathId);
		}
	}
	//---------------------------------------------------------------------------------------------------
	public function getVertex(x:FloatRef, y:FloatRef):UInt
	{
		if(_approximationMethod == CURVE_INC)
		{
			return _curveInc.getVertex(x, y);
		}
		return _curveDiv.getVertex(x, y);
	}
}