package actionScripts.ui.marker
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.events.ResizeEvent;
	import mx.graphics.SolidColor;
	
	import spark.components.Group;
	import spark.components.TextArea;
	import spark.primitives.Rect;
	
	import actionScripts.events.GeneralEvent;
	
	import components.skins.TransparentTextAreaSkin;
	
	import flashx.textLayout.compose.StandardFlowComposer;
	import flashx.textLayout.compose.TextFlowLine;
	import flashx.textLayout.formats.TextLayoutFormat;
	
	[Event(name="VSCrollUpdate", type="actionScripts.events.GeneralEvent")]
	[Event(name="HSCrollUpdate", type="actionScripts.events.GeneralEvent")]
	public class MarkerTextArea extends Group
	{
		private static var LINE_HEIGHT:Number;
		
		private var textArea:TextArea;
		private var lineHighlightContainer:Group;
		private var search:String;
		private var lastLinesIndex:int;
		private var highlightDict:Dictionary = new Dictionary();
		private var contentInLineBreaks:Array;
		private var isAllLinesRendered:Boolean;
		
		private var _text:String;
		public function get text():String {	return _text;	}
		public function set text(value:String):void {
			_text = value;
			if (textArea) textArea.text = _text;
		};
		
		public function MarkerTextArea()
		{
			super();
			clipAndEnableScrolling = true;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			var bg:Rect = new Rect();
			bg.fill = new SolidColor(0xf5f5f5);
			bg.left = bg.right = bg.top = bg.bottom = 0;
			addElement(bg);
			
			lineHighlightContainer = new Group();
			lineHighlightContainer.percentWidth = lineHighlightContainer.percentHeight = 100;
			addElement(lineHighlightContainer);
			
			textArea = new TextArea();
			textArea.editable = false;
			textArea.percentWidth = textArea.percentHeight = 100;
			textArea.setStyle("lineBreak", "explicit");
			textArea.setStyle("skinClass", TransparentTextAreaSkin);
			addElement(textArea);
		}
		
		public function highlight(search:String):void
		{
			highlightDict = new Dictionary();
			isAllLinesRendered = false;
			lineHighlightContainer.graphics.clear();
			textArea.scroller.verticalScrollBar.value = 0;
			this.search = search.toLowerCase();
			textArea.setFormatOfRange(new TextLayoutFormat());
			
			if (!textArea.scroller.verticalScrollBar.hasEventListener(Event.CHANGE)) 
			{
				textArea.scroller.verticalScrollBar.addEventListener(Event.CHANGE, onVScrollUpdate);
				textArea.scroller.horizontalScrollBar.addEventListener(Event.CHANGE, onHScrollUpdate);
			}
			
			var positions:Array = getPositions(textArea.text.toLowerCase(), search);
			var len:uint = positions.length;
			
			for(var i:int = 0; i<len; i++)
			{
				var textLayoutFormat:TextLayoutFormat = new TextLayoutFormat();
				textLayoutFormat.backgroundColor = 0xFF00FF;
				textArea.setFormatOfRange(textLayoutFormat, positions[i].posStart, positions[i].posEnd);
			}
			
			// adding necessary listeners
			this.addEventListener(ResizeEvent.RESIZE, onStageResized);
			this.addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		public function getPositions(original:String, search:String):Array 
		{
			// @note
			// we can do the highlight generation in two ways -
			// looping through contentInLineBreaks or adding highlights on-demand
			// upon scroll event updates. If a line has 1000 lines it may would be
			// overkill to generate all the lines in one go looping through the
			// contentsInLineBreaks array. Many a time an user may do not checks
			// till bottom, thus it shoud be more efficient to add the
			// lines based on available TextFlowLine array on scroll event
			contentInLineBreaks = original.split("\n");
			
			var updateLastIndex:Boolean = true;
			var composer:StandardFlowComposer = textArea.textFlow.flowComposer as StandardFlowComposer;
			
			lineHighlightContainer.graphics.beginFill(0xffff00, .35); 
			lineHighlightContainer.graphics.lineStyle(1, 0xffff00, .65, true);
			
			for (var i:int; i < composer.lines.length; i++)
			{
				var tfl:TextFlowLine = composer.lines[i];
				
				if (i == 1) LINE_HEIGHT = tfl.y - composer.lines[0].y;
				if (tfl.paragraph && tfl.paragraph.mxmlChildren[0].text.toLowerCase().indexOf(search) != -1)
				{
					lineHighlightContainer.graphics.drawRect(0, tfl.y-1, width, tfl.height);
					highlightDict[i] = true;
				}
				
				if (!tfl.paragraph && updateLastIndex)
				{
					lastLinesIndex = i;
					updateLastIndex = false;
				}
				else if (updateLastIndex)
					lastLinesIndex = i;
			}
			
			lineHighlightContainer.graphics.endFill();
			
			var positions:Array = [];
			var startPosition:Number;
			var endPosition:Number = 0;
			
			while (startPosition != -1) {
				startPosition = original.indexOf(search, endPosition);
				endPosition = startPosition + search.length;
				if (startPosition > -1) positions.push({posStart:startPosition, posEnd:endPosition});
			}
			
			return positions;
		}
		
		public function updateVScrollByNeighbour(event:GeneralEvent):void
		{
			textArea.scroller.viewport.verticalScrollPosition = event.value as Number;
			onVScrollUpdate(null, false);
		}
		
		public function updateHScrollByNeighbour(event:GeneralEvent):void
		{
			textArea.scroller.viewport.horizontalScrollPosition = event.value as Number;
		}
		
		private function onVScrollUpdate(event:Event, isDispatchEvent:Boolean=true):void
		{
			if (!isAllLinesRendered)
			{
				var composer:StandardFlowComposer = textArea.textFlow.flowComposer as StandardFlowComposer;
				if (composer.lines.length == contentInLineBreaks.length - 1) isAllLinesRendered = true;

				if (composer.lines.length > lastLinesIndex)
				{
					var updateLastIndex:Boolean = true;
					lineHighlightContainer.graphics.beginFill(0xffff00, .35); 
					lineHighlightContainer.graphics.lineStyle(1, 0xffff00, .65, true);
					for (var i:int=lastLinesIndex; i < composer.lines.length; i++)
					{
						var tfl:TextFlowLine = composer.lines[i];
						if (highlightDict[i] == undefined && contentInLineBreaks[i].indexOf(search) != -1)
						{
							lineHighlightContainer.graphics.drawRect(0, (i * LINE_HEIGHT)+4, width, LINE_HEIGHT);
							highlightDict[i] = true;
						}
						
						if (!tfl.paragraph && updateLastIndex)
						{
							lastLinesIndex = i;
							updateLastIndex = false;
						}
						else if (updateLastIndex)
							lastLinesIndex = i;
					}
					
					lineHighlightContainer.graphics.endFill();
				}
			}
			
			lineHighlightContainer.y = -textArea.scroller.viewport.verticalScrollPosition;
			if (isDispatchEvent) dispatchEvent(new GeneralEvent("VSCrollUpdate", textArea.scroller.viewport.verticalScrollPosition));
		}
		
		private function onHScrollUpdate(event:Event):void
		{
			dispatchEvent(new GeneralEvent("HSCrollUpdate", textArea.scroller.viewport.horizontalScrollPosition));
		}
		
		private function onRemovedFromStage(event:Event):void
		{
			textArea.scroller.verticalScrollBar.removeEventListener(Event.CHANGE, onVScrollUpdate);
			textArea.scroller.horizontalScrollBar.removeEventListener(Event.CHANGE, onHScrollUpdate);
			this.removeEventListener(ResizeEvent.RESIZE, onStageResized);
			this.removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		private function onStageResized(event:ResizeEvent):void
		{
			trace("gandu2");
		}
	}
}