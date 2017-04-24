// Header font JS Stick Letters from:
// http://patorjk.com/software/taag/#p=display&f=JS%20Stick%20Letters


import papaya.*;
import processing.pdf.*;

final float EPS = pow(10,-30);            // Small number
final boolean DIRECTION_RIGHT = true;     // Constant label for right direction
final boolean DIRECTION_LEFT = false;     // Constant label for left direction
final boolean FASTER = true;              // Constant label for faster
final boolean SLOWER = false;             // Constant label for slower

boolean dataSampFrame;
Window window;
PGraphicsPDF pdf;
boolean recordPDF;
int ct;

/*************************************************************
                               ___ ___       __   __   __  
    |\/|  /\  | |\ |     |\/| |__   |  |__| /  \ |  \ /__` 
    |  | /~~\ | | \|     |  | |___  |  |  | \__/ |__/ .__/ 
                                                        
*************************************************************/

void setup() {
  // size(this.x, this.y, P2D);
  size(1200, 800, P2D);
  pixelDensity(2);
  ct = 0;
  recordPDF = false;
  window = new Window();
}

void draw() {
  window.update();
  if (recordPDF) {
    beginRecord(PDF, "output/lamptrack-"+ct+".pdf");
    textMode(MODEL);
    textFont(createFont("LucidaGrande", 12), 14);
    window.display(); ct++;
    endRecord();
    recordPDF = false;
  } else {
    window.display();
  }
}

void keyPressed() {
  if (key == CODED) {
    switch (keyCode) {
      case RIGHT: window.car.steer(DIRECTION_RIGHT);  break;
      case LEFT:  window.car.steer(DIRECTION_LEFT);   break;
      case UP:    window.car.accelerate(FASTER);      break;
      case DOWN:  window.car.accelerate(SLOWER);      break;
    }
  } else {
    switch (key) {
      case 'l': window.showLamps = !window.showLamps;             break;
      case 'm': window.showMap = !window.showMap;                 break;
      case 'v': window.showCar = !window.showCar;                 break;
      case 'c': window.showCams = !window.showCams;               break;
      case 'o': window.showObs = !window.showObs;                 break;
      case 'r': window.buildLamps(window.lamps.length); 
                window.map.reset();                               break;
      case 'e': window.map.reset();                               break;
      case ']': window.buildLamps(min(window.lamps.length+1,30));
                window.map.reset();                               break;
      case '[': window.buildLamps(max(window.lamps.length-1,0));
                window.map.reset();                               break;
      case ',': window.decreaseFov();                             break;
      case '.': window.increaseFov();                             break;
      case '-': window.decreaseSampRate();                        break;
      case '=': window.increaseSampRate();                        break;
      case 'p': recordPDF = true;                                 break;
    }
  }
}

/*************************************************************
                 __   __           __             __   __  
    |  | | |\ | |  \ /  \ |  |    /  ` |     /\  /__` /__` 
    |/\| | | \| |__/ \__/ |/\|    \__, |___ /~~\ .__/ .__/ 
                                                           
*************************************************************/

class Window {
  
  // Window Specs
  int x;      // Interface width  [pixels]
  int y;      // Interface height [pixels]
  int off;    // Interface offset [pixels]
  int text;   // Default text font size
  int bg;     // Background color
  int frate;  // Frame rate
  int sampRate;
  boolean dataSampFrame;
  
  // Objects in window
  Car car;
  Camera[] cams;
  Lamp[] lamps; 
  Map map;
  
  // Object visibility booleans
  boolean showLamps = true;
  boolean showMap   = true;
  boolean showCar   = true;
  boolean showCams  = true;
  boolean showObs   = true;

  Window() {
    this(1200,800,10,12,0,60);
  }
  
  Window(int x, int y, int off, int text, int bg, int frate) {
    this.x = x;
    this.y = y;
    this.off = off;    
    this.text = text;
    this.bg = bg;
    this.frate = frate;
    sampRate = 4;
    buildWindow();
    buildCar();
    buildLamps(1);
    buildCams();
    buildMap();
  }

  void buildWindow() {
    background(this.bg);
    frameRate(this.frate);
    textSize(this.text);
  }
  
  void buildCar() {
    car = new Car(this);
  }
  
  void buildLamps(PVector[] l) {
    lamps = new Lamp[l.length];
    for (int i = 0; i < l.length; i++) {
      lamps[i] = new Lamp(l[i],this);
    }
  }
  
  void buildLamps(int n) {
    lamps = new Lamp[n];
    for (int i = 0; i < n; i++) {
      lamps[i] = new Lamp(random(x),random(y-20*off)+10*off,this);
    }
  }
  
  void buildCams() {
    cams = new Camera[2];
    cams[0] = new Camera(0,car.center, car.heading,this);
    cams[1] = new Camera(1,car.center, car.heading+PI,this);
  }
  
  void decreaseFov() {
    float fov = constrain(cams[0].fov-cams[0].fovStep,PI/18,PI*17/18);
    cams[0].fov = fov;
    cams[1].fov = fov;
  }
  
  void increaseFov() {
    float fov = constrain(cams[0].fov+cams[0].fovStep,PI/18,PI*17/18);
    cams[0].fov = fov;
    cams[1].fov = fov;
  }
  
  void decreaseSampRate() {
    sampRate = constrain(sampRate-1,1,20);
  }
  
  void increaseSampRate() {
    sampRate = constrain(sampRate+1,1,20);
  }
  
  void buildMap() {
    map = new Map(this);
  }
  
  void update() {
    dataSampFrame = (frameCount % sampRate) == 0;
    car.update();
    cams[0].update(car.center,car.heading);
    cams[1].update(car.center,car.heading+PI);
    map.update();
  }
  
  void display() {
    background(0);
    for (int i = 0; i < lamps.length; i++) {
      lamps[i].display();
    }
    cams[0].displayView();
    cams[1].displayView();
    car.display();
    displayFrame();
    cams[0].displayScreen();
    cams[1].displayScreen();
    map.display();
  }
  
  void displayFrame() {
    fill(0); stroke(255);
    rect(-off,-off,x+2*off,5*off);
    rect(-off,y-8*off,x+2*off,9*off);
    fill(255); noStroke();
    String s1 = "LAMPTRACK v7, JASON KU -- Move car with arrow keys"
             + " -- Toggle Visibility: "
             + "( V ) Vehicle, ( C ) Cameras, "
             + "( M ) Map, ( L ) Lamps, ( O ) Observations";
    String s2 = "# Lamp Obj: " + lamps.length;
    String s3 = "# Map Obj: " + map.lamps.length;
    String s4 = "Change Lamps: ( R ) Reset, ( [ ) Decrease #, ( ] ) Increase #";
    String s5 = "Field of View (degrees): "+((int)(cams[0].fov*180/PI/10))*10;
    String s6 = "Change Field of View: ( , ) Decrease, ( . ) Increase";
    String s7 = "Sampling Rate (num frames between observations): "+sampRate;
    String s8 = "Change Sampling Rate: ( - ) Decrease ( = )";
    text(s1,off,2*off);
    if(showLamps) {
      text(s2,window.off, window.y-6.2*window.off);
      text(s4,20*window.off, window.y-6.2*window.off);
    }
    if(showMap) {
      text(s3,window.off, window.y-4.8*window.off);
    }
    if(showCams) {
      text(s5,45*window.off, window.y-3*window.off);
      text(s6,45*window.off, window.y-1*window.off);
    }
    text(s7,85*window.off, window.y-6*window.off);
    text(s8,85*window.off, window.y-4*window.off);
  }
  
  void polygon(PVector[] p) {
    beginShape();
    for (int i = 0; i < p.length; i++) {
      if (p[i] != null) {
        vertex(p[i].x, p[i].y);
      }
    }
    endShape(CLOSE);
  }
}

/*************************************************************
         __        __      __             __   __  
        /  `  /\  |__)    /  ` |     /\  /__` /__` 
        \__, /~~\ |  \    \__, |___ /~~\ .__/ .__/ 
                                           
*************************************************************/

class Car {    

  // Vehicle Specs
  int w = 20;             // Width [pixels]
  int l = 40;             // Length [pixels]
  float accel = 0.2;      // Acceleration [pixels/frame/frame]
  int maxSpeed = 4;       // Max speed [pixels/frame]
  int maxSteer = 15;      // Max steer [discrete rotation]
  int turnScale = 2000;   // Steering coefficient
  float rollFric = 1;     // Coefficient of rolling friction
  float statFric = 0.05;  // Coefficient of static friction
  float headFric = 1;     // Heading friction factor
  float gpsVar = 5;// 5
  float imuVar = 0.05; // 0.05
  int markSize = 10;

  Window window;
  PVector[] form;
  PVector center, gpsCent;
  float speed, heading, imuHead;
  int steer;
  
  Car(Window w) {
    this(w.x/2,w.y/2,0,0,0,w);
  }
  
  Car(float x, float y, float h, float v, int s, Window w) {    
    heading = h;
    speed = v;
    steer = s;
    center = new PVector(x, y);
    window = w;
    buildForm();
    gpsCent = center;
    imuHead = heading;
  }

  void buildForm() {
    form = new PVector[5];
    form[0] = new PVector( w/2,  l/2);
    form[1] = new PVector(-w/2,  l/2);
    form[2] = new PVector(-w/2, -l/2);
    form[3] = new PVector(   0, -l  );
    form[4] = new PVector( w/2, -l/2);
  }
  
  void update() {
    if (speed != 0) {
      if (center.x + speed*sin(heading) < 0 ||
          center.x + speed*sin(heading) > window.x ||
          center.y - speed*cos(heading) < 4*window.off ||
          center.y - speed*cos(heading) > window.y-8*window.off) {
        speed = 0;
      } 
      else {
        center.x += speed*sin(heading);
        center.y -= speed*cos(heading);
        heading += speed*steer*PI/turnScale;
        speed *= rollFric;
        heading *= headFric;
        heading = normAng(heading);
        speed *= int(abs(speed) >= statFric);
      }
    }
    if (window.dataSampFrame) {
      PVector noise = new PVector(randomGaussian()*gpsVar,randomGaussian()*gpsVar);
      gpsCent = PVector.add(window.car.center,noise);
      imuHead = normAng(heading + randomGaussian()*imuVar);
    }
  }
  
  void display() {
    if (window.showCar) {
      pushMatrix();
      translate(center.x, center.y);
      rotate(heading);
      fill(255,0,0); noStroke();
      window.polygon(form);
      popMatrix();
    }
    if (window.showObs) {
      pushMatrix();
      translate(gpsCent.x, gpsCent.y);
      rotate(imuHead);
      fill(255,0,0,100); stroke(128,0,0);
      window.polygon(form);
      popMatrix();
    }
  }

  void steer(boolean direction) {
    if (direction == DIRECTION_RIGHT && steer + 1 <= maxSteer) {
      steer++;
    }
    if (direction == DIRECTION_LEFT && steer - 1 >= -maxSteer) {
      steer--;
    }
  }

  void accelerate(boolean change) {
    if (change == FASTER && speed + accel <= maxSpeed) {
      if (speed < 0 && speed + accel > 0) {
        speed = 0;
      } else {
        speed += accel;
      }
    }
    if (change == SLOWER && speed - accel >= -maxSpeed) {
      if (speed > 0 && speed - accel < 0) {
        speed = 0;
      } else {
        speed -= accel;
      }
    }
  }
}

/*************************************************************
    __             ___  __           __             __   __  
   /  `  /\  |\/| |__  |__)  /\     /  ` |     /\  /__` /__` 
   \__, /~~\ |  | |___ |  \ /~~\    \__, |___ /~~\ .__/ .__/ 
                                                           
*************************************************************/

class Camera {
  
  // Camera Specs
  int readHeight = 10;  // Reading height             [pixels] 
  int viewDepth = 160;  // Cam view depth             [pixels]
  int screenRange = 320;  // Cam view width @ max depth [pixels]
  float fov = PI/2;     // Cam field of view
  float fovStep = PI/18;
  float camVar = 0.05;
   
  Window window;
  int camIdx;
  PVector center;
  float heading;  
  PVector[] screen;
  float[] readings, eReadings;

  Camera(int camIdx, PVector center, float heading, Window w) {
    this.window = w;
    this.camIdx = camIdx;
    buildScreen();
    //buildView();
    eReadings = new float[0];
    update(center, heading);
  }

  void buildScreen() {
    screen = new PVector[4];
    screen[0] = new PVector(        0,           0);
    screen[1] = new PVector(        0, -readHeight);
    screen[2] = new PVector(screenRange, -readHeight);
    screen[3] = new PVector(screenRange,           0);
  }
  
//  void buildView() {
//    viewShape = new PVector[3];
//    viewShape[0] = new PVector(        0,            0);
//    viewShape[1] = new PVector(viewDepth,  viewRange/2);
//    viewShape[2] = new PVector(viewDepth, -viewRange/2);
//    view = new PVector[3];
//  }
  
  void displayScreen() {
    if (window.showCams) {
      pushMatrix();
      translate(window.off, window.y-(1+2*camIdx)*window.off);
      fill(255, 255, 255, 100); stroke(255);
      window.polygon(screen);
      translate(screenRange+window.off,0);
      fill(255); noStroke();
      text("Camera ["+camIdx+"]",0,0);
      popMatrix();
      for (int i = 0; i < readings.length; i++) {
        noFill(); stroke(0,0,255);
        pushMatrix();
        translate(window.off+screenRange/2, 
                  window.y-(1+2*camIdx)*window.off-readHeight);
        float l = screenRange/2*tan(normAng(readings[i]-heading))/tan(fov/2);
        line(l, 0, l, readHeight);
        popMatrix();
      }
      if(window.showObs) {
        for (int i = 0; i < eReadings.length; i++) {
          noFill(); stroke(0,255,0);
          pushMatrix();
          translate(window.off+screenRange/2, 
                    window.y-(1+2*camIdx)*window.off-readHeight);
          float l = screenRange/2*tan(normAng(eReadings[i]-heading))/tan(fov/2);
          line(l, 0, l, readHeight);
          popMatrix();
        }
      }
    }
  }

  void displayView() {
    if (window.showCams) {
      fill(255, 255, 255, 100); stroke(255);
      arc(center.x,center.y,
        2*viewDepth,
        2*viewDepth,
        -fov/2+heading,
        fov/2+heading,
        PIE);
      //window.polygon(view);
      for (int i = 0; i < readings.length; i++) {
        noFill(); stroke(0,0,255);
        //float l = viewDepth/cos(normAng(readings[i]-heading));
        line(                   center.x,                   center.y,
             viewDepth*cos(readings[i])+center.x,
             viewDepth*sin(readings[i])+center.y);
      }
    }
    if (window.showObs) {
      for (int i = 0; i < eReadings.length; i++) {
        noFill(); stroke(0,200,0);
        //float l = viewDepth/cos(normAng(eReadings[i]-window.car.imuHead+int(camIdx == 1)*PI));
        line(                    window.car.gpsCent.x,                    window.car.gpsCent.y,
             viewDepth*cos(eReadings[i])+window.car.gpsCent.x,
             viewDepth*sin(eReadings[i])+window.car.gpsCent.y);
      }
    }
  }

  void update(PVector c, float h) {
    center = c;
    heading = normAng(h);
//    for (int i = 0; i < 3; i++) {
//      view[i] = new PVector(viewShape[i].x,viewShape[i].y);
//      view[i].rotate(heading);
//      view[i].add(center);
//    }
    readings = new float[0];
    for (int i = 0; i < window.lamps.length; i++) {
      if (sees(window.lamps[i].center)) {
        addReading(window.lamps[i]);
      }
    }
    if (window.dataSampFrame) {
      eReadings = new float[readings.length];
      for (int i = 0; i < readings.length; i++) {
        eReadings[i] = normAng(readings[i]+randomGaussian()*camVar);;
      }
    }
  }
  
  boolean sees(PVector l) {
    boolean inside = false;
    if (l.dist(center) < viewDepth && 
        abs(normAng(normAng(PVector.sub(l,center).heading())-heading)) < fov/2) {
          inside = true;
        }
//    for (int i = 0; i < 3; i++) {
//      boolean right = (PVector.sub(view[i],view[(i+1) % 3])).cross(
//                       PVector.sub(l,view[i])).z > 0;
//      inside = inside && right;
//    }
    return inside;
  }
  
  void addReading(Lamp l) {
    float r = normAng((PVector.sub(l.center,center)).heading());
    readings = append(readings,r);
  }
}

/*************************************************************
                        __      __             __   __  
       |     /\   |\/| |__)    /  ` |     /\  /__` /__` 
       |___ /~~\  |  | |       \__, |___ /~~\ .__/ .__/ 
                                                 
*************************************************************/

class Lamp {
  
  // Lamp Specs
  int rad = 10;  // Radius

  Window window;
  PVector center;
  
  Lamp(PVector c, Window w) {
   center = c;
   window = w;
  } 
  
  Lamp(float x, float y, Window w) {
    this(new PVector(x,y), w);
  }
  
  void display() {
    if (window.showLamps) {
      fill(255,0,0,100); stroke(255,0,0);
      for (Camera c : window.cams) {
        if (c.sees(this.center)) {
          fill(0,255,0,100); stroke(0,255,0);
        }
      }
      ellipse(center.x,center.y,rad,rad);
    }
  }
}

/*************************************************************
                    __      __             __   __  
         |\/|  /\  |__)    /  ` |     /\  /__` /__` 
         |  | /~~\ |       \__, |___ /~~\ .__/ .__/ 
                                                    
*************************************************************/

class Map {
  
  float angThresh = 1;
  float ivarPrior = 0.01;
  float ivarSee = 0.001;
  float distPrior;
  float lim = 2;
  
  Window window;
  Gaussian[] lamps;
  
  Map(Window w) {
    lamps = new Gaussian[0];
    window = w;
    distPrior = w.cams[0].viewDepth*0.5;
    update();
  }
  
  void update() {
    if (window.dataSampFrame) { //  && window.car.speed != 0
      for (int camIdx = 0; camIdx < window.cams.length; camIdx++) {
        int[] visLamps = new int[0];
        for (int i = 0; i < lamps.length; i++) {
          if (window.cams[camIdx].sees(lamps[i].mean)) {
            visLamps = append(visLamps,i);
          }
        }
        int nP = min(visLamps.length,window.cams[camIdx].eReadings.length);
        int[][] pair = new int[nP][2];
        int[] posLamps = new int[visLamps.length];
        int[] posReads = new int[window.cams[camIdx].eReadings.length];
        //println("nP: "+nP+" #lamps: "+posLamps.length+" #reads: "+posReads.length);
        for (int i = 0; i < posLamps.length; i++) {
          posLamps[i] = visLamps[i];
        }
        for (int i = 0; i < posReads.length; i++) {
          posReads[i] = i;
        }
        for (int k = 0; k < nP; k++) {
          float err = PI;
          int iBest = 0;
          int jBest = 0;
          for (int i = 0; i < window.cams[camIdx].eReadings.length; i++) {
            for (int j = 0; j < visLamps.length; j++) {
              boolean valid = false;
              for (int l = 0; l < posReads.length; l++) {
                if (i == posReads[l]) {
                  valid = true;
                }
              }
              for (int l = 0; l < posLamps.length; l++) {
                if (visLamps[j] == posLamps[l]) {
                  valid = true;
                }
              }
              if (valid) {
                float errT = abs(normAng(PVector.sub(lamps[visLamps[j]].mean,
                                                     window.car.gpsCent).heading())-window.cams[camIdx].eReadings[i]);
                if (errT < err) {
                  err = errT;
                  iBest = i;
                  jBest = j;
                }
              }
            }
          }
          pair[k][0] = iBest;
          pair[k][1] = jBest;
          for (int i = iBest + 1; i < posReads.length; i++) {
            posReads[i-1] = posReads[i];
          }
          posReads = shorten(posReads);
          for (int j = jBest + 1; j < posLamps.length; j++) {
            posLamps[j-1] = posLamps[j];
          }
          posLamps = shorten(posLamps);
          
//          boolean inMap = false;
//          for (int j = 0; j < lamps.length; j++) {
//            PVector d = PVector.sub(lamps[j].mean,window.car.gpsCent);
//            if (window.cams[camIdx].sees(lamps[j].mean)) {
//              refineLamp(j,i,camIdx);
//              inMap = true;
//            }
//          }
//          if (!inMap) {
//            addLamp(i,camIdx);
//          }
        }
//        if (nP > 0) {
//          String s45 = "pair = [";
//          for (int i = 0; i < nP; i++) {
//            s45 = s45+"("+pair[i][0]+","+pair[i][1]+"),";
//          }
//          println(s45);
//        }
        for (int k = 0; k < nP; k++) {
          refineLamp(visLamps[pair[k][1]],pair[k][0],camIdx);
        }
        for (int i = 0; i < posLamps.length; i++) {
          if (Mat.det(lamps[posLamps[i]].icov) < 0.0001) {
            removeLamp(posLamps[i]);
          } else {
            penalizeLamp(posLamps[i]);
          }
        }
        for (int i = 0; i < posReads.length; i++) {
          addLamp(posReads[i],camIdx);
        }
      }
//      for (Camera c : window.cams) {
//        for (int j = 0; j < lamps.length; j++) {
//          if (c.sees(lamps[j].mean) && c.eReadings.length == 0 && Mat.det(lamps[j].icov) < 0.001) {
//            removeLamp(j);
//            break;
//          }
//        }
//      }
      boolean found = false;
      while(!found) {
        found = true;
        for (int i = 0; i < lamps.length; i++) {
          for (int j = i+1; j < lamps.length; j++) {
            if (lamps[i].mean.dist(lamps[j].mean) < 20) {
              if (Mat.det(lamps[i].icov) > Mat.det(lamps[j].icov)) {
                removeLamp(j);
              } else {
                removeLamp(i);
              }
              found = false;
              break;
            }
          }
          if (false) { break; }
        }
      }
    }
  }
  
  void addLamp(int readIdx, int camIdx) {
    Gaussian g = gaussFromRead(readIdx, camIdx,true);
    lamps = (Gaussian[]) append(lamps,g);
  }
  
  void removeLamp(int idx) {
    for (int i = idx+1; i < lamps.length; i++) {
      lamps[i-1] = lamps[i];
    }
    lamps = (Gaussian[]) shorten(lamps);
  }
  
  void penalizeLamp(int idx) {
    float[][] c = Mat.multiply(lamps[idx].icov,0.95);
    lamps[idx] = new Gaussian(lamps[idx].mean,c);
  }
  
  void refineLamp(int lampIdx, int readIdx, int camIdx) {
    if (!lamps[lampIdx].fixed) {
      Gaussian g = gaussFromRead(readIdx, camIdx,false);
      float[] gm = {g.mean.x,g.mean.y};
      float[] lm = {lamps[lampIdx].mean.x,lamps[lampIdx].mean.y};
      float[][] c = Mat.sum(lamps[lampIdx].icov,g.icov);
      float[] m = Mat.multiply(Mat.inverse(c),Mat.sum(Mat.multiply(g.icov,gm),
                                                      Mat.multiply(lamps[lampIdx].icov,lm)));
      PVector mv = new PVector(m[0],m[1]);
      if (!window.cams[camIdx].sees(mv)) {
        mv = PVector.sub(mv,window.car.gpsCent);
        float a = normAng(mv.heading());
        float l = window.cams[camIdx].viewDepth/cos(normAng(a-window.car.imuHead+int(camIdx == 1)*PI));
        mv = new PVector(l*cos(a)+window.car.gpsCent.x,l*sin(a)+window.car.gpsCent.y);
      }
      lamps[lampIdx] = new Gaussian(m,c);
      if (lamps[lampIdx].major < lim && lamps[lampIdx].minor < lim) {
        //lamps[lampIdx].fixed = true;
      }
    }
  }
  
  Gaussian gaussFromRead(int readIdx, int camIdx, boolean add) {
    float h = normAng(window.cams[camIdx].eReadings[readIdx]); 
    PVector m = new PVector(window.car.gpsCent.x+cos(h)*distPrior,
                            window.car.gpsCent.y+sin(h)*distPrior);
    float[][] c;
    if (add) {
      c = new float[][] {{ivarSee,0},{0,ivarPrior}};
    } else {
      c = new float[][] {{0,0},{0,ivarPrior}};
    }
    float[][] r = {{cos(h),-sin(h)},{sin(h),cos(h)}};
    c = Mat.multiply(Mat.multiply(r,c),Mat.transpose(r));
    return new Gaussian(m,c);
  }
  
  void display() {
    if (window.showMap) {
      for (Gaussian m : lamps) {
        m.display();
      }
    }
  }
  
  void reset() {
    lamps = new Gaussian[0];
  }
}

/*************************************************************
     __             __   __      __             __   __  
    / _`  /\  |  | /__` /__`    /  ` |     /\  /__` /__` 
    \__> /~~\ \__/ .__/ .__/    \__, |___ /~~\ .__/ .__/ 
                                                     
*************************************************************/

class Gaussian {
 
  PVector mean;
  float[][] icov;
  float major, minor, heading;
  float lim = 1;
  boolean fixed;

  Gaussian(float[] m, float[][] v) {
    this(new PVector(m[0],m[1]),v);
  }
  
  Gaussian(PVector m, float[][] v) {
    mean = m;
    icov = v;
    fixed = false;
    SVD svd = new SVD(v);
    double[] sv = svd.getSingularValues();
    major = 1/(float)sv[0];
    minor = 1/(float)sv[1];
    double[][] r = svd.getV();
    heading = atan2((float)r[0][1],(float)r[0][0]);
  }
  
  void display() {
    if (Mat.det(icov) > 0) {
      pushMatrix();
      translate(this.mean.x, this.mean.y);
      rotate(this.heading);
      fill(0,255,0,50); stroke(0,255,0);
      if (fixed) {
        fill(0,0,255,50); stroke(0,0,255);
      }
      ellipse(0,0,this.major*6,this.minor*6);
      ellipse(0,0,10,10);
      popMatrix();
    }
  }
}

/*************************************************************
                 ___          ___    ___  __  
            |  |  |  | |    |  |  | |__  /__` 
            \__/  |  | |___ |  |  | |___ .__/ 
                                              
*************************************************************/

float normAng(float a) {      // Normalizes ang to [-PI,PI]
  return a + 2*PI*pow(-1,int(a > 0))*int(abs(a) > PI);
}