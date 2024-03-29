package lib.ha.aggx.vectorial.generators;
//=======================================================================================================
import flash.Vector;
import lib.ha.aggx.vectorial.IDistanceProvider;
import lib.ha.aggx.vectorial.IVertexSource;
import lib.ha.aggx.vectorial.PathCommands;
import lib.ha.aggx.vectorial.PathUtils;
import lib.ha.aggx.vectorial.VertexDistance;
import lib.ha.aggx.vectorial.VertexSequence;
import lib.ha.core.memory.Ref;
import lib.ha.core.math.Calc;
//=======================================================================================================
class VcgenDash implements ICurveGenerator, implements IVertexSource //Vertex Curve Generator
{
	private static var MAX_DASHES:UInt = 32;
	//---------------------------------------------------------------------------------------------------
	private static inline var INITIAL = 0;
	private static inline var READY = 1;
	private static inline var POLYLINE = 2;
	private static inline var STOP = 3;
	//---------------------------------------------------------------------------------------------------
	private var _dashes:Vector<Float>;
	private var _totalDashLength:Float;
	private var _numDashes:UInt;
	private var _dashStart:Float;
	private var _shorten:Float;
	private var _currentDashStart:Float;
	private var _currentDashIndex:UInt;
	private var _currentRest:Float;
	private var _v1:IDistanceProvider;
	private var _v2:IDistanceProvider;
	private var _srcVertices:VertexSequence;
	private var _isClosed:Int;
	private var _status:Int;
	private var _srcVertexIndex:UInt;
	//---------------------------------------------------------------------------------------------------
	public function new() 
	{
		_totalDashLength = 0.;
		_numDashes = 0;
		_dashStart = 0.;
		_shorten = 0.;
		_currentDashStart = 0.;
		_currentDashIndex = 0;
		_srcVertices = new VertexSequence();
		_isClosed = 0;
		_status = INITIAL;
		_srcVertexIndex = 0;
		_dashes = new Vector(MAX_DASHES);
	}
	//---------------------------------------------------------------------------------------------------
	public function removeAllDashes():Void
	{
		_totalDashLength = 0.0;
		_numDashes = 0;
		_currentDashStart = 0.0;
		_currentDashIndex = 0;
	}
	//---------------------------------------------------------------------------------------------------
	public function addDash(dashLen:Float, gapLen:Float):Void
	{
		if(_numDashes < MAX_DASHES)
		{
			_totalDashLength += dashLen + gapLen;
			_dashes[_numDashes++] = dashLen;
			_dashes[_numDashes++] = gapLen;
		}
	}
	//---------------------------------------------------------------------------------------------------
	private inline function set_dashStart(value:Float):Float
	{
		_dashStart = value;
		calcDashStart(Calc.fabs(value));
		return value;
	}
	public inline var dashStart(null, set_dashStart):Float;	
	//---------------------------------------------------------------------------------------------------
	private inline function get_shorten():Float { return _shorten; }
	private inline function set_shorten(value:Float):Float { return _shorten = value; }
	public inline var shorten(get_shorten, set_shorten):Float;
	//---------------------------------------------------------------------------------------------------
	private function calcDashStart(ds:Float):Void
	{
		_currentDashIndex = 0;
		_currentDashStart = 0.0;
		while(ds > 0.0)
		{
			if(ds > _dashes[_currentDashIndex])
			{
				ds -= _dashes[_currentDashIndex];
				++_currentDashIndex;
				_currentDashStart = 0.0;
				if(_currentDashIndex >= _numDashes) _currentDashIndex = 0;
			}
			else
			{
				_currentDashStart = ds;
				ds = 0.0;
			}
		}
	}
	//---------------------------------------------------------------------------------------------------
	public function removeAll():Void
	{
		_status = INITIAL;
		_srcVertices.removeAll();
		_isClosed = 0;
	}
	//---------------------------------------------------------------------------------------------------
	public function addVertex(x:Float, y:Float, cmd:UInt):Void
	{
		_status = INITIAL;
		if(PathUtils.isMoveTo(cmd))
		{
			_srcVertices.modifyLast(new VertexDistance(x, y));
		}
		else
		{
			if(PathUtils.isVertex(cmd))
			{
				_srcVertices.add(new VertexDistance(x, y));
			}
			else
			{
				_isClosed = PathUtils.getCloseFlag(cmd);
			}
		}
	}
	//---------------------------------------------------------------------------------------------------
	public function rewind(pathId:UInt):Void
	{
		if(_status == INITIAL)
		{
			_srcVertices.close(_isClosed != 0);
			PathUtils.shortenPath(_srcVertices, _shorten, _isClosed);
		}
		_status = READY;
		_srcVertexIndex = 0;
	}
	//---------------------------------------------------------------------------------------------------
	public function getVertex(x:FloatRef, y:FloatRef):UInt
	{
		var cmd = PathCommands.MOVE_TO;
		while(!PathUtils.isStop(cmd))
		{
			switch(_status)
			{
			case INITIAL:
				rewind(0);
				_status = READY;

			case READY:
				if(_numDashes < 2 || _srcVertices.size < 2)
				{
					cmd = PathCommands.STOP;
				}
				else 
				{
					_status = POLYLINE;
					_srcVertexIndex = 1;
					_v1 = _srcVertices.get(0);
					_v2 = _srcVertices.get(1);
					_currentRest = _v1.dist;
					x.value = _v1.x;
					y.value = _v1.y;
					if(_dashStart >= 0.0) calcDashStart(_dashStart);
					return PathCommands.MOVE_TO;
				}

			case POLYLINE:
				{
					var dash_rest = _dashes[_currentDashIndex] - _currentDashStart;
					var r = (_currentDashIndex & 1);
					
					cmd = ((_currentDashIndex & 1) == 1) ? PathCommands.MOVE_TO : PathCommands.LINE_TO;

					if(_currentRest > dash_rest)
					{
						_currentRest -= dash_rest;
						++_currentDashIndex;
						if(_currentDashIndex >= _numDashes) _currentDashIndex = 0;
						_currentDashStart = 0.0;
						x.value = _v2.x - (_v2.x - _v1.x) * _currentRest / _v1.dist;
						y.value = _v2.y - (_v2.y - _v1.y) * _currentRest / _v1.dist;
					}
					else
					{
						_currentDashStart += _currentRest;
						x.value = _v2.x;
						y.value = _v2.y;
						++_srcVertexIndex;
						_v1 = _v2;
						_currentRest = _v1.dist;
						if(_isClosed != 0)
						{
							if(_srcVertexIndex > _srcVertices.size)
							{
								_status = STOP;
							}
							else
							{
								_v2 = _srcVertices.get((_srcVertexIndex >= _srcVertices.size) ? 0 : _srcVertexIndex);
							}
						}
						else
						{
							if(_srcVertexIndex >= _srcVertices.size)
							{
								_status = STOP;
							}
							else
							{
								_v2 = _srcVertices.get(_srcVertexIndex);
							}
						}
					}
					return cmd;
				}

			case STOP:
				cmd = PathCommands.STOP;
			}
		}
		return PathCommands.STOP;
	}
}