package lib.ha.aggx.renderer;
//=======================================================================================================
import flash.Vector;
import lib.ha.aggx.color.ISpanAllocator;
import lib.ha.aggx.color.ISpanGenerator;
import lib.ha.aggx.rasterizer.IRasterizer;
import lib.ha.aggx.rasterizer.IScanline;
import lib.ha.aggx.rasterizer.ScanlineRasterizer;
import lib.ha.core.memory.MemoryReader;
using lib.ha.core.memory.MemoryReader;
//=======================================================================================================
class ScanlineRenderer implements IRenderer
{
	private var _ren:ClippingRenderer;
	private var _alloc:ISpanAllocator;
	private var _spanGen:ISpanGenerator;
	//---------------------------------------------------------------------------------------------------
	public function new(ren:ClippingRenderer, alloc:ISpanAllocator, gen:ISpanGenerator) 
	{
		_ren = ren;
		_alloc = alloc;
		_spanGen = gen;
	}
	//---------------------------------------------------------------------------------------------------
	public function attach(ren:ClippingRenderer, alloc:ISpanAllocator, gen:ISpanGenerator)
	{
		_ren = ren;
		_alloc = alloc;
		_spanGen = gen;
	}
	//---------------------------------------------------------------------------------------------------
	public function prepare():Void { _spanGen.prepare(); }
	//---------------------------------------------------------------------------------------------------
	public function render(sl:IScanline):Void
	{
		renderAAScanline(sl, _ren, _alloc, _spanGen);
	}
	//---------------------------------------------------------------------------------------------------
	public static function renderAAScanline(sl:IScanline, ren:ClippingRenderer, alloc:ISpanAllocator, spanGen:ISpanGenerator):Void
	{
		var y = sl.y;
		var numSpans = sl.spanCount;
		var spanIter = sl.spanIterator;

		while(true)
		{
			var span = spanIter.current;
			var x = span.x;
			var len = span.len;
			var covers = span.covers;

			if(len < 0) len = -len;
			var colors = alloc.allocate(len);
			spanGen.generate(colors, x, y, len);
			ren.blendColorHSpan(x, y, len, colors, (span.len < 0) ? 0 : covers, covers.getByte());

			if (--numSpans == 0) break;
			spanIter.next();
		}
	}
	//---------------------------------------------------------------------------------------------------
	public static function renderAAScanlines(ras:ScanlineRasterizer, sl:IScanline, ren:ClippingRenderer, alloc:ISpanAllocator, spanGen:ISpanGenerator):Void
	{
		if(ras.rewindScanlines())
		{
			sl.reset(ras.minX, ras.maxX);
			spanGen.prepare();
			while(ras.sweepScanline(sl))
			{
				renderAAScanline(sl, ren, alloc, spanGen);
			}
		}
	}	
	//---------------------------------------------------------------------------------------------------
	public static function renderScanlines(ras:IRasterizer, sl:IScanline, ren:IRenderer):Void
	{
		if(ras.rewindScanlines())
		{
			sl.reset(ras.minX, ras.maxX);
			ren.prepare();
			while(ras.sweepScanline(sl))
			{
				ren.render(sl);
			}
		}
	}
}