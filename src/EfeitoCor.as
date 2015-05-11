package 
{
	
	import flash.text.*;
    import flash.filters.*;
    import flash.geom.*;
    import flash.events.*;
    import flash.display.*;
	/**
	 * ...
	 * @author Erivan Franklin
	 */
	public class EfeitoCor extends Sprite 
	{
		
		public static const GRAVITY:Number = 0.05;
        public static const RANGE:Number = 20;
        public static const RANGE2:Number = RANGE * RANGE;
        public static const RANGEh:Number = RANGE / 2;
        public static const DENSITY:Number = 1;
        public static const PRESSURE:Number = 2;
        public static const PRESSUREh:Number = PRESSURE / 10;      
        public static const VISCOSITY:Number = 0.075;
		private var img:BitmapData;
        private var particles:Vector.<Particle>;
        private var numParticles:uint;
        private var color:ColorTransform;
        private var filter:BlurFilter;
        private var count:int;
        private var press:Boolean;
		private var imgBmp:Bitmap;
		
		public function EfeitoCor():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			
			color = new ColorTransform(1,1,1,0.99);
            filter = new BlurFilter(8, 8, 1);
            particles = new Vector.<Particle>();
            numParticles = 0;
            count = 0;
            img = new BitmapData(250, 350, false, 0);
			imgBmp = new Bitmap(img)
            addChild(imgBmp);
            addChild(new Bitmap(img));
            addEventListener(Event.ENTER_FRAME, frame);			
            stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void {press = true;});
            stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):void {press = false;});			
			//removeEventListener(Event.ADDED_TO_STAGE, init);
			
		}
		
		 private function frame(e:Event):void {			
            if(press)
				pour();
				
            move();
            img.lock();
            draw();            
            img.colorTransform(img.rect, color);
            img.applyFilter(img, img.rect, new Point(), filter);
            //draw();
            img.unlock();
        }
		
		private function draw():void {
            for (var i:int = 0; i < numParticles; i++) {				
                var p:Particle = particles[i];
                img.fillRect(new Rectangle(p.x - 1, p.y - 1, 2, 2), p.color);
                //img.setPixel(p.x, p.y, p.color);
            }
        }
		
        private function pour():void {			
			for (var i:int = -1; i <= 1; i++) {					
				 particles[numParticles++] = new Particle(380 + i * 8, 5 + 5);				
				 particles[numParticles - 1].vy = Math.random()*5+5;
				 if (Math.random()*100<2) particles[numParticles - 1].color = Math.random()*0xffffff;
			}
        }
		
		private function move():void {	
			
            count++;
            var i:int;
            var j:int;
            var wi:int;
            var dist:Number;
            var dist2:Number;
            var pi:Particle;
            var pj:Particle;
            var dx:Number;
            var dy:Number;
            var weight:Number;
            var pressureWeight:Number;
            var viscosityWeight:Number;
            var weightPERdens:Number;
            for(i = 0; i < numParticles; i++) {
                pi = particles[i];
                pi.numNeighbors = 0;
                for(j = 0; j < i; j++) {
                    pj = particles[j];
                    dx=pi.x-pj.x;
                    dy=pi.y-pj.y;                    
                    if(dx * dx + dy * dy < RANGE2) {
                        pi.neighbors[pi.numNeighbors++] = pj;
                        pj.neighbors[pj.numNeighbors++] = pi;                   
                    }
                }
            }
            for(i = 0; i < numParticles; i++) {
                pi = particles[i];
                pi.density = 0;
                pi.weight.length=0;
                pi.dist.length=0;                
                for(j = 0; j < pi.numNeighbors; j++) {
                    pj = pi.neighbors[j];
                    dx = pi.x - pj.x;
                    dy = pi.y - pj.y;
                    dist2 = dx * dx + dy * dy;
                    dist = Math.sqrt(dist2);
                    weight=1-dist/RANGE;
                    pi.dist.push(dist);
                    pi.weight.push(weight);
                    pi.density += 1 - dist/RANGEh + dist2/RANGE2;
                }
                if(pi.density < DENSITY)
                    pi.density = DENSITY;
                pi.pressure = pi.density - DENSITY;
            }
            for(i = 0; i < numParticles; i++) {
                pi = particles[i];
                pi.fx = 0;
                pi.fy = 0;
                for(j = 0; j < pi.numNeighbors; j++) {
                    pj = pi.neighbors[j];
                    dx = pi.x - pj.x;
                    dy = pi.y - pj.y;
                    dist=pi.dist[j];
                    weight=pi.weight[j];                    
                    weightPERdens = weight / pj.density;
                    pressureWeight = weightPERdens * (pi.pressure + pj.pressure) * PRESSUREh;
                    dist = 1 / dist;
                    dx *= dist;
                    dy *= dist;
                    pi.fx += dx * pressureWeight;
                    pi.fy += dy * pressureWeight;
                    viscosityWeight = weightPERdens * VISCOSITY;
                    dx = pi.vx - pj.vx;
                    dy = pi.vy - pj.vy;
                    pi.fx -= dx * viscosityWeight;
                    pi.fy -= dy * viscosityWeight;
                }
            }
            for(i = 0; i < numParticles; i++) {
                pi = particles[i];
                pi.move();
            }
        }
	}	
}


class Particle {
    public var x:Number;
    public var y:Number;
    public var vx:Number;
    public var vy:Number;
    public var fx:Number;
    public var fy:Number;
    public var density:Number;
    public var pressure:Number;
    public var neighbors:Vector.<Particle>;
    public var numNeighbors:int;
    public var color:int;
    public var weight:Vector.<Number>;
    public var dist:Vector.<Number>;    
    public function Particle(x:Number, y:Number) {
        this.x = x;
        this.y = y;
        vx = vy = fx = fy = 0;
        neighbors = new Vector.<Particle>();
        weight = new Vector.<Number>();
        dist = new Vector.<Number>();        
        color = 0x8888ff;
    }

    public function move():void {
        vy += EfeitoCor.GRAVITY;
        vx += fx;
        vy += fy;
        x += vx;
        y += vy;
        if(x < 5){  
            vx -= vx;
            x = 5-x;
        }
        if(y < 5){ 
            vy -= vy;
            y = 5-y;
        }    
        if(x > 250){ 
            vx -= vx;
            x = 250+250-x;
        }
        if(y > 350){ 
            vy -= vy;
            y = 350+350-y;
        }    
    }
}