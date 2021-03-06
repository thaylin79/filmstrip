package com.animoto.filmstrip.output
{
	import com.animoto.filmstrip.FilmStrip;
	import com.animoto.filmstrip.FilmStripEvent;
	import com.animoto.filmstrip.PulseControl;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	/**
	 * You have to add this module to the stage at a high level to see the playback,
	 * which starts after render.
	 * 
	 * @author moses gunesch
	 */
	public class PlaybackFromRAM extends Bitmap
	{
		public var filmStrip: FilmStrip;
		public var loop:Boolean;
		public var autoAddTo: DisplayObjectContainer; // if set, does addChild(this) when done
		public var autoPlay: Boolean; // True by default: play when filmstrip completes (must be added to stage first)
		public var datas: Array = new Array();
		public var timer: Timer;
		public var currentFrame: int = -1;
		public var playing:Boolean = false;
		public var pausedTF: TextField = new TextField();
		
		protected var lastFrameTime: Number;
		protected var beginTime: Number;
		
		public function PlaybackFromRAM(filmStrip:FilmStrip, loop:Boolean=true, autoAddTo:DisplayObjectContainer=null, autoPlay:Boolean=true) {
			super();
			this.smoothing = true;
			this.filmStrip = filmStrip;
			this.loop = loop;
			this.autoAddTo = autoAddTo;
			this.autoPlay = autoPlay;
			filmStrip.addEventListener(FilmStripEvent.FRAME_RENDERED, handleRenderEvents);
			filmStrip.addEventListener(FilmStripEvent.RENDER_STOPPED, handleRenderEvents);
			timer = new Timer(filmStrip.frameDuration, 0);
			timer.addEventListener(TimerEvent.TIMER, nextFrame);
		}
		
		public function handleRenderEvents(e:FilmStripEvent):void {
			switch (e.type) {
				case FilmStripEvent.FRAME_RENDERED: 
					this.bitmapData = e.data;
					datas.push(e.data);
					return;
					
				case FilmStripEvent.RENDER_STOPPED: 
					filmStrip.removeEventListener(FilmStripEvent.FRAME_RENDERED, handleRenderEvents);
					filmStrip.removeEventListener(FilmStripEvent.RENDER_STOPPED, handleRenderEvents);
					if (autoAddTo!=null && parent==null) {
						autoAddTo.addChild(this);
					}
					if (autoPlay && stage!=null) {
						playVideo();
					}
					return;
			}
		}
		
		public function reverse():void {
			datas.reverse();
		}
		
		public function playVideo():void {
			if (datas.length==0)
				return;
			reset();
			if (stage!=null) {
				this.stage.addEventListener(MouseEvent.MOUSE_DOWN, togglePlay);
				this.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);
			}
			beginTime = PulseControl.getCurrentTime();
			playing = true;
			nextFrame();
			timer.delay = filmStrip.frameDuration;
			timer.start();
		}
		
		public function togglePlay(e:MouseEvent=null):void {
			if (playing) {
				timer.stop();
				togglePausedTF(true);
			}
			else {
				timer.start();
				togglePausedTF(false);
			}
			playing = !playing;
		}
		
		public function nextFrame(e:TimerEvent=null):void {
			if (++currentFrame>=datas.length && playing) {
				dispatchEvent(new Event(Event.COMPLETE));
				if (loop)
					playVideo();
				else
					reset();
			}
			this.bitmapData = datas[currentFrame] as BitmapData;
			if (playing && !isNaN(lastFrameTime)) {
				timer.stop();
				var diff:Number = ((PulseControl.getCurrentTime() - lastFrameTime) - filmStrip.frameDuration);
				timer.delay = Math.min(filmStrip.frameDuration-5, Math.max(1, filmStrip.frameDuration - diff));
				timer.start();
			}
			lastFrameTime = PulseControl.getCurrentTime();
		}
		
		public function reset():void {
			if (!isNaN(beginTime)) {
				trace("playback took " + ((PulseControl.getCurrentTime()-beginTime)/1000).toFixed(1) + 's');
			}
			currentFrame = -1;
			lastFrameTime = beginTime = NaN;
			timer.reset();
			togglePausedTF(false);
			
			if (stage!=null) {
				this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, togglePlay);
				this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKeyPress);
			}
		}
		
		protected function togglePausedTF(show:Boolean):void {
			if (this.parent==null)
				return;
			
			if (this.parent.contains(pausedTF))
				this.parent.removeChild(pausedTF);
				
			if (show) {
				pausedTF.text = "PAUSED";
				pausedTF.background = true;
				pausedTF.backgroundColor = 0xFFFFFF;
				pausedTF.setTextFormat(new TextFormat("_sans", 24, 0x0, true));
				pausedTF.selectable = false;
				pausedTF.autoSize = TextFieldAutoSize.LEFT;
				pausedTF.x = pausedTF.y = 5;
				this.parent.addChild(pausedTF);
			}
		}
		
		protected function handleKeyPress(event:KeyboardEvent):void {
			if ( event.keyCode == Keyboard.SPACE ) {
				togglePlay();
				return;
			}
			if (event.keyCode == Keyboard.RIGHT ) {
				if (playing)
					togglePlay();
				if (currentFrame==datas.length-1)
					currentFrame = -1;
				nextFrame();
			}
			else if ( event.keyCode == Keyboard.LEFT ) {
				if (playing)
					togglePlay();
				if ( (currentFrame-=2) < 0 )
					currentFrame = datas.length-2;
				nextFrame();
			}
		}
	}
}