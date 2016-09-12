import SimpleOpenNI.*;
import processing.serial.*; 
SimpleOpenNI context;

int homeX = 80;
int homeY = 135;
int xpos = homeX; 
int ypos = homeY; 
float frame = PI;
Serial port; // The serial port we will be using

PShape square, center;
boolean skeleton = false;

color[] userColor = new color[]{ 
  color(255,0,0),
  color(0,255,0),
  color(0,0,255),
  color(255,255,0),
  color(255,0,255),
  color(0,255,255)
};

void setup(){
  //size(1260, 960, P2D);
  size(640, 480, P2D);
  
  context = new SimpleOpenNI(this);
  if(context.isInit() == false){
     println("Can't initialize SimpleOpenNI, camera not connected properly."); 
     exit();
     return;  
  }
  
  context.enableDepth();
  context.enableUser();
  context.setMirror(true);
 
  stroke(0,0,255);
  strokeWeight(3);
  smooth();  
  port = new Serial(this, Serial.list()[4], 19200);
  updateServo(homeX, homeY);
}

void updateServo(int x, int y)
{
  xpos = x;
  ypos = y;
  port.write(x + "x");
  port.write(y + "y");
}

void onNewUser(SimpleOpenNI curContext, int userId){
  println("onNewUser - userId: " + userId);
  if(skeleton){
    curContext.startTrackingSkeleton(userId);
  }
  
}

void onLostUser(SimpleOpenNI curContext, int userId){
  println("onLostUser - userId: " + userId);
}

//void onVisibleUser(SimpleOpenNI curContext, int userId){
//  println("onVisibleUser - userId: " + userId);
//}


int offsetX = 15;
int offsetY = 0;
void drawBoundingBox(int userId) {
  PVector bbMin = new PVector();
  PVector bbMax = new PVector();
  context.getBoundingBox(userId, bbMin, bbMax);
  
  if(bbMin.x < 2000 && bbMin.x >= 0) {
    float boxWidth = bbMax.x - bbMin.x;
    float boxHeight = bbMax.y - bbMin.y;
    square = createShape(RECT, bbMin.x - 20, bbMin.y - 20, boxWidth, boxHeight);
    float centerX = (bbMin.x - 20) + boxWidth/2;
    float centerY = (bbMin.y - 20) + boxHeight/2;
    center = createShape(RECT, centerX, centerY, 5, 5);
    
    center.setFill(false);
    center.setStroke(color(255)); 
    shape(center, 25, 25); 
    square.setFill(false);
    square.setStroke(color(255));  
    shape(square, 25, 25);
    
    float X = 640 - centerX; 
    float degreesPerPixel = .092;
    float startingViewAngle = 70 - offsetX;
    int servoX = int(X * degreesPerPixel + startingViewAngle);
    
    float Y = centerY;
    degreesPerPixel = .089;
    startingViewAngle = 113.5 + offsetY;
    int servoY = int(Y * degreesPerPixel + startingViewAngle);
    
    println("centerX: " + centerX + " OFFSETX: " + offsetX);
    println("X: " + X + " x*D: " + X * degreesPerPixel + " servoX: " + servoX);
    
    if(servoX < 90){
      servoX -= int((90 - servoX) / 4);
    } 
    if (75 < servoX && servoX < 120) {
      servoX -= 5;
    }
    
    updateServo(servoX, servoY);
  }
}

void drawTarget(int userId) {
  PVector head = new PVector();
  context.getJointPositionSkeleton(userId,  SimpleOpenNI.SKEL_HEAD, head);
  line(head.x - 10, head.y - 10, head.x + 10, head.y + 10);
  line(head.x + 10, head.y + 10, head.x - 10, head.y - 10);
  println("X: " + head.x + ", Y: " + head.y + ", Z: " + head.z);
}

void drawSkeleton(int userId){  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  
  PVector head = new PVector();
  context.getJointPositionSkeleton(userId,  SimpleOpenNI.SKEL_HEAD, head);
  println("X: " + head.x + ", Y: " + head.y + ", Z: " + head.z);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);

  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT);  
}


int frameX = 80;
int frameY = 135;
boolean ascend = true;

void draw(){
  context.update();
  image(context.userImage(),0,0);
  int[] userList = context.getUsers();
  
  if (userList.length == 0) {
    float rate = .02;
    frame += rate;
    if(frame > 1024) {
      frame = PI;
    }
    frameX = 80 + int(70 * (cos(frame) / (1 + pow(sin(frame), 2))));
    frameY = 135 + int(45 * (sin(frame)*cos(frame) / (1 + pow(sin(frame), 2))));
    
    updateServo(frameX, frameY);
  }
  
  for(int i=0;i<userList.length;i++){
    drawBoundingBox(userList[i]);
//    if(context.isTrackingSkeleton(userList[i]) && skeleton){
//      stroke(userColor[ (userList[i] - 1) % userColor.length ]);
//      //background(0);
//      //drawTarget(userList[i]);
//      drawSkeleton(userList[i]);
//    }
  }    
}

void keyPressed() {
  if (key == 'q') {
    skeleton = true;
  } else if (key == 'e') {
    skeleton = false;
  } else if (key == 's') {
    updateServo(xpos, ypos + 5);
    println("XPOS: " + xpos + " YPOS: " + ypos);
  } else if (key == 'w') {
    updateServo(xpos, ypos - 5);
    println("XPOS: " + xpos + " YPOS: " + ypos);
  } else if (key == 'a') {
    updateServo(xpos + 5, ypos);
    println("XPOS: " + xpos + " YPOS: " + ypos);
  } else if (key == 'd') {
    updateServo(xpos - 5, ypos);
    println("XPOS: " + xpos + " YPOS: " + ypos);
  } else if (key == 'h') {
    updateServo(homeX, homeY);
  } else if (key == 'v') {
    offsetY -= 5;
  } else if (key == 'b') {
    offsetX += 5;
  }
  
}
